// Jonathan Hersh - jhersh@salesforce.com - 3/04/2010
public with sharing class chatterSearch {
    private Boolean isTest = false;  //tford

    public static integer ROWS_PER_PAGE { get { return 20; } }

    public searchSettings settings  { get; set; }
    public searchResults results    { get; set; }

    public boolean searched         { get; set; }

    public chartData[] roleGraph    { get; set; }
    public string[] roleNames       { get; set; }

    public chartData[] profileGraph { get; set; }
    public string[] profileNames    { get; set; }

    public boolean showAbout        { get; set; }

    public chatterSearch() {
        showAbout = ApexPages.currentpage().getparameters().get('about') == '1' ? true : false;

        doReset();
    }

    public pageReference doReset() {
        settings = new searchSettings();
        results = null;
        searched = false;

        return null;
    }

    public pageReference doSearch() {
        if( settings.startDT.activitydatetime == null ) {
            settings.startDT.activitydatetime.addError('Please select a start date.');
            return null;
        }

        if( settings.endDT.activitydatetime == null ) {
            settings.endDT.activitydatetime.addError('Please select an end date.');
            return null;
        }

        // Make sure the proper checkboxes are checked for the search
        if( settings.attachExt != '-- Select --' || nNull( settings.attachName ) )
            settings.hasAttached = true;

        if( nNull( settings.linkURL ) || nNull( settings.linkName ) )
            settings.hasLink = true;

        results = new searchResults();
        rolegraph = new chartData[] {};
        roleNames = new string[] {};
        profilegraph = new chartData[] {};
        profileNames = new string[] {};

        Map<id, User> userMap = null;
        if (this.isTest) {  //tford
            userMap = new Map<id, User> ([select id, name, userroleid, userrole.name, profileid, profile.name 
                                            from User
                                           where isactive = true
                                             and CompanyName = :UserInfo.getOrganizationName()
                                             and usertype = 'Standard' LIMIT 5]);
        }
        else {
            // !!! tford: this query returns 5002 rows (of available 10000)  in 62 org !!!
            userMap = new Map<id, User> ([select id, name, userroleid, userrole.name, profileid, profile.name 
                                            from User 
                                           where isactive = true
                                             and CompanyName = :UserInfo.getOrganizationName()
                                             and usertype = 'Standard']);
        }

System.debug('##### tford: 1 Limits.getQueryRows() --> ' + Limits.getQueryRows());

        Set<ID> userIDs = userMap.keySet();
        Set<string> uniqueUsers = new Set<string> ();

        // tford: limit subquery for ftest and regular contexts
        String subQuery = '(select id, createddate, createdbyid, parentid, createdby.name '+
                           'from FeedComments '+
                           'order by createddate desc';
        if (this.isTest) {
            subQuery += ' LIMIT 5';
        }
        else {
            subQuery += ' LIMIT 1000';          
        }
        subQuery += ')';

        string query = 'select id, createdbyid, createddate, createdby.name, type, FeedPost.body, FeedPost.title, parentid, parent.name, '+
                       'FeedPost.contenttype, FeedPost.linkURL, FeedPost.id, '+
                        subQuery +
                        'from UserFeed '+
                        'where FeedPost.body <> null '+
                        'and createdbyid IN :userIDs ';

        if( nNull( settings.searchStr ) )
            query += 'and FeedPost.body LIKE \'%' + scrub( settings.searchStr ) + '%\' ';

        if( settings.hasLink && settings.hasAttached )
            query += 'and ( FeedPost.type = \'LinkPost\' or FeedPost.type = \'ContentPost\' ) ';
        else if( settings.hasLink )
            query += 'and FeedPost.type = \'LinkPost\' ';
        else if( settings.hasAttached )
            query += 'and FeedPost.type = \'ContentPost\' ';

        if( nNull( settings.attachName ) )
            query += 'and FeedPost.title LIKE \'%'+ scrub( settings.attachName ) +'%\' ';

        if( nNull( settings.linkName ) )
            query += 'and FeedPost.title LIKE \'%'+ scrub( settings.linkName ) +'%\' ';

        if( nNull( settings.linkURL ) )
            query += 'and FeedPost.linkURL LIKE \'%'+ scrub( settings.linkURL ) +'%\' ';

        // Time range on updates

        // Make sure our datetimes are in order
        if( settings.startDT.activitydatetime > settings.endDT.activitydatetime ) {
            Datetime tmp = settings.startDT.activitydatetime;
            settings.startDT.activitydatetime = settings.endDT.activitydatetime;
            settings.endDT.activitydatetime = tmp;          
        }

        // Dynamic SOQL doesn't play well with datetimes inside sobjects inside inner classes
        Datetime startDT = settings.startDT.activitydatetime;
        Datetime endDT = settings.endDT.activitydatetime;

        query += 'and createddate >= :startDT and createddate <= :endDT ';

        // tford: limit for ftest context
        if (this.isTest) {
            query += 'order by createddate desc limit 5';
        }
        else {
            query += 'order by createddate desc limit 1000';
        }

        // Load up the updates matching this search
        UserFeed[] allResults2 = Database.query( query );
        UserFeed[] allResults = new UserFeed[] {};

System.debug('##### tford: 2 Limits.getQueryRows() --> ' + Limits.getQueryRows());

        // Some things can't be filtered for in a SOQL query, so we do those manually here
        for( UserFeed uf : allResults2 ) {
            if( nNull( settings.attachExt ) && 
                settings.attachExt != '-- Select --' && 
                ( uf.FeedPost.contenttype != 'binary/file' && // we cannot detect filetypes if SFDC stores them as binaries
                    !uf.FeedPost.contenttype.contains( scrub( settings.attachExt ) ) )
            )
                continue;

            if( settings.showReplies == false && 
                uf.parentid != uf.createdbyid )
                continue;

            if( uf.FeedComments.size() < integer.valueof( settings.minComments ) )
                continue;

            allResults.add( uf );
        }

        Map<string,roleProfile> roles = new Map<string,roleProfile> ();
        Map<string,roleProfile> profiles = new Map<string,roleProfile> ();

        Map<long,integer> timeMap = new Map<long,integer>();

        // Loop through all the results, put them into role and profile buckets    
        for( UserFeed uf : allResults ) {
            uniqueUsers.add( uf.createdbyid );

            // Track Role-based penetration of statuses
            string rolename = userMap.get( uf.createdbyid ).userrole.name;

            if( !roles.containsKey( rolename ) )
                roles.put( rolename, new roleProfile( rolename ) );

            roles.get( rolename ).statuses++;
            roles.get( rolename ).members.add( uf.createdbyid );

            // Track Profile-based penetration of statuses
            string pname = userMap.get( uf.createdbyid ).profile.name;

            if( !profiles.containsKey( pname ) )
                profiles.put( pname, new roleProfile( pname ) );

            profiles.get( pname ).statuses++;
            profiles.get( pname ).members.add( uf.createdbyid );

            // Add the status to our status array        
                statusMsg sm = new statusMsg();

                sm.uid = uf.createdbyid;
                sm.uname = userMap.get( sm.uid ).name;
                sm.pid = uf.parentid;

                if( userMap.containsKey( sm.pid ) )
                    sm.pname = userMap.get( sm.pid ).name;
                else
                    sm.pname = '';

                sm.msg = uf.FeedPost.body;
                sm.reltime = relativeTime( uf.createddate );

                sm.numcomments = uf.FeedComments.size();

                if( uf.FeedPost.linkurl != null ) {
                    sm.hasLink = true;
                    sm.attURL = uf.FeedPost.linkurl;
                    sm.attName = uf.FeedPost.title;
                } else if( uf.FeedPost.title != null ) {
                    sm.hasAtt = true;
                    sm.attName = uf.FeedPost.title;
                    sm.attURL = '#'; //'/sfc/#version?selectedDocumentId='+ uf.FeedPost.id;
                }

                results.statuses.add( sm );
        }   

        results.statusCount = allResults.size();
        results.uniqueuserCount = uniqueUsers.size();
        results.allUserCount = userMap.keySet().size();
        results.termPenetration = ( uniqueUsers.size() * 100 ) / results.allUserCount;
        
        searched = true;

        // Are we showing graphs? If not, we're done here.
        if( !settings.showGraphs )
            return null;

        // Assemble profile and role arrays into chart-friendly data 
        // First, we need to know how many people are in each profile and role
        Map<string,integer> allRoleMap = new Map<string,integer> ();
        for( User u : userMap.values() ) {
            Integer roleCount = (Integer)allRoleMap.get(u.UserRole.Name);
            if (roleCount == null) {
                roleCount = 0;
            }
            allRoleMap.put(u.UserRole.Name, roleCount + 1);
        }

        roleNames.addAll( allRoleMap.keySet() );
        roleNames.sort();

        Map<string,integer> allProfileMap = new Map<string,integer> ();
        for( User u : userMap.values() ) {
            Integer profileCount = (Integer)allRoleMap.get(u.Profile.Name);
            if (profileCount == null) {
                profileCount = 0;
            }
            allProfileMap.put(u.Profile.Name, profileCount + 1);
        }

        profileNames.addAll( allProfileMap.keySet() );
        profileNames.sort();

        // Create two graphs. one for user roles, one for user profiles.    
        // graph series: total updates, total users, users with statuses (unique users)
        chartData roleTUpdates, roleTUsers, roleUUsers;
        chartData profileTUpdates, profileTUsers, profileUUsers;

        roleTUpdates = new chartData();
        roleTUsers = new chartData();
        roleUUsers = new chartData();
        profileTUpdates = new chartData();
        profileTUsers = new chartData();
        profileUUsers = new chartData();

        roleTUpdates.key = 'Update Count';
        profileTUpdates.key = 'Update Count';
        roleTUsers.key = 'Total Users';
        profileTUsers.key = 'Total Users';
        roleUUsers.key = 'Unique Users';
        profileUUsers.key = 'Unique Users';

        for( string name : roleNames ) {
            roleTUsers.values.add( allRoleMap.containsKey( name ) ? allRoleMap.get( name ) : 0 );

            if( roles.containsKey( name ) ) {
                roleTUpdates.values.add( roles.get( name ).statuses );
                roleUUsers.values.add( roles.get( name ).members.size() );
            } else {
                roleTUpdates.values.add( 0 );
                roleUUsers.values.add( 0 );
            }
        }

        for( string name : profileNames ) {
            profileTUsers.values.add( allProfileMap.get( name ) );

            if( profiles.containsKey( name ) ) {
                profileTUpdates.values.add( profiles.get( name ).statuses );
                profileUUsers.values.add( profiles.get( name ).members.size() );        
            } else {
                profileTUpdates.values.add( 0 );
                profileUUsers.values.add( 0 );
            }
        }

        roleGraph.addAll( new List<chartData> { roleTUpdates, roleTUsers, roleUUsers } );
        profileGraph.addAll( new List<chartData> { profileTUpdates, profileTUsers, profileUUsers } );

        return null;
    }

    public static string scrub( string str ) {
        if( str == null || str == '' )
            return '';

        return String.escapeSingleQuotes( str.toLowerCase().trim() );
    }

    public static boolean nNull( string str ) {
        return str != null && scrub( str ) != '';
    }

    public static string relativeTime( Datetime dt ) {
            long diff =  ( Datetime.now().getTime() - dt.getTime() ) / 1000;
            string unit;

            if( diff < 60 )
                unit = 'second';
            else if( diff < 60 * 60 ) {
                diff /= 60;
                unit = 'minute';
            } else if( diff < 60 * 60 * 24 ) {
                diff = diff / 60 / 60;
                unit = 'hour';
            } else {
                diff = diff / 60 / 60 / 24;
                unit = 'day';
            }

            if( diff > 1 )
                unit += 's';
                
            return diff + ' ' + unit + ' ago';
    }

    public pageReference nextUpdates() {
        if( results.first + ROWS_PER_PAGE > results.statuses.size() )
            return null;

        results.first += ROWS_PER_PAGE;

        return null;
    }

    public string getNextLink() {
       integer remaining = results.statuses.size() - ( results.first + ROWS_PER_PAGE );
       
       return ( remaining > ROWS_PER_PAGE ? 'Next '+ ROWS_PER_PAGE : 'Last '+ remaining );
    }

    public pageReference prevUpdates() {
        results.first -= ROWS_PER_PAGE;
        
        if( results.first < 0 )
            results.first = 0;

        return null;            
    }

    public string getPrevLink() {
        integer remaining = results.first - ROWS_PER_PAGE;

        if( remaining == 0 )
            remaining = - ROWS_PER_PAGE;
        
        return ( remaining > 0 ? 'Prev '+ ROWS_PER_PAGE : 'First '+ -remaining );
    }
    
    public SelectOption[] getMinComments() {
        SelectOption[] so = new SelectOption[] {};
        
        for( integer x = 0; x <= 10; x++ )
            so.add( new SelectOption( ''+x, ''+x ) );
            
        return so;      
    }
    
    public SelectOption[] getfileExtensions() {
        SelectOption[] so = new SelectOption[] {};
        
        so.add( new SelectOption( '-- Select --', '-- Select --' ) );
        so.add( new SelectOption( 'doc', 'DOC' ) );
        so.add( new SelectOption( 'image', 'Image' ) );
        so.add( new SelectOption( 'pdf', 'PDF' ) );
        so.add( new SelectOption( 'ppt', 'PPT' ) );
        so.add( new SelectOption( 'xls', 'XLS' ) );
        so.add( new SelectOption( 'zip', 'ZIP' ) );
        
        return so;
    }
    
    public class searchSettings {
        public boolean hasAttached  { get; set; }
        public string attachExt     { get; set; }
        public string attachName    { get; set; }

        public boolean hasLink      { get; set; }
        public string linkURL       { get; set; }
        public string linkName      { get; set; }

        public string searchStr     { get; set; }

        public boolean showReplies  { get; set; }

        public integer minComments  { get; set; }

        // using events so that we can have inputfields with date pickers
        public Event startDT        { get; set; }
        public Event endDT      { get; set; }

        public boolean showGraphs    { get; set; }

        public searchSettings() {
            hasAttached = false;
            attachExt = '-- Select --';
            attachName = '';
            
            hasLink = false;
            linkURL = '';
            linkName = '';
            
            searchStr = '';
            minComments = 0;
            showReplies = true;
            
            showGraphs = false;
            
            startDT = new Event( activitydatetime = datetime.now().addMonths(-1) );
            endDT = new Event( activitydatetime = datetime.now() );
        }
    }
    
    // Stores all statistics and data about search results, including the statuses themselves
    public class searchResults {
        public statusMsg[] statuses     { get; set; }
        
        public integer first            { get; set; }
        
        public integer termPenetration  { get; set; }
        
        public integer statusCount      { get; set; }
        public integer uniqueuserCount  { get; set; }
        public integer allUserCount     { get; set; }
        
        public searchResults() {
            statuses = new statusMsg[] {};
            first = 0;
        }
    }
    
    // Stores data about an individual status message in our search results
    public class statusMsg {
        public string uid   { get; set; }
        public string uname { get; set; }
        
        public string pid   { get; set; }
        public string pname { get; set; }
        
        public string msg   { get; set; }
        public string reltime   { get; set; }
        
        public integer numcomments  { get; set; }
        
        public string attName   { get; set; }
        public string attURL    { get; set; }
        
        public boolean hasLink  { get; set; }
        public boolean hasAtt   { get; set; }
        
        public statusMsg() {}
    }
    
    // Helper class for the Highcharts graphs
    public class roleProfile {
        public string name      { get; set; }
        public Set<ID> members  { get; set; }
        public integer statuses { get; set; }
        
        public roleProfile( string mname ) {
            name = mname;
            members = new Set<ID> ();
            statuses = 0;
        }
    }
    
    // Another Highcharts helper class
    public class chartData {
        public string key       { get; set; }
        public integer[] values { get; set; }
        public integer value    { get; set; }
        
        public chartData() {
            key = '';
            values = new integer[] {};
            value = 0;
        }
    }

    public static testmethod void runTest() {
        chatterSearch cs = new chatterSearch();
        cs.settings.showGraphs = true;
        cs.isTest = true;
        cs.doSearch();
    }
}