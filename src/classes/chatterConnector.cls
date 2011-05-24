// Jonathan Hersh & Helder Rocha -- jhersh & hrocha at salesforce.com - 3/23/2010 
public with sharing class chatterConnector {
	public followUser[] userList{ get; set; }
    
    public integer first		{ get; set; }
    public string maxUsers      { get; set; }
    public integer maxUsersInt	{ get; set; }
    public string whichList     { get; set; }
    public string whichUsers    { get; set; }
    public string whichOrder	{ get; set; }
    
    public boolean showAbout	{ get; set; }
    
    private boolean isTest = false;
    
    public chatterConnector() {
    	if( ApexPages.currentpage().getparameters().get('about') == '1' ) {
    		showAbout = true;
    		return;
    	}
    	
        maxUsers = '25';
        first = 0;
        
        whichList = 'team';
        whichUsers = 'all';
        
        buildUserList();
    }
    
    public SelectOption[] getUserLimits() {
        SelectOption[] so = new SelectOption[] {};
        
        for( string s : new string[] { '10', '25', '50', '100' } )
            so.add( new SelectOption( s, s ) );
            
        return so;
    }
    
    public SelectOption[] getUserLists() {
        SelectOption[] so = new SelectOption[] {};
        
        so.add( new SelectOption( 'team', 'my team' ) );
        so.add( new SelectOption( 'hierarchy', 'my reporting hierarchy' ) );
        so.add( new SelectOption( 'reports', 'my direct reports' ) );
        so.add( new SelectOption( 'reports2', 'my second-degree reports' ) );
        so.add( new SelectOption( 'department', 'my department' ) );
        so.add( new SelectOption( 'role', 'my role' ) );
        so.add( new SelectOption( 'profile', 'my profile' ) );
        so.add( new SelectOption( 'state', 'my state' ) );
        so.add( new SelectOption( 'country', 'my country' ) );
        
        return so;
    }
    
    public SelectOption[] getUserTypes() {
        SelectOption[] so = new SelectOption[] {};
        
        so.add( new SelectOption( 'all', 'everyone' ) );
        so.add( new SelectOption( 'dontfollow', 'only people I don\'t follow' ) );
        so.add( new SelectOption( 'dofollow', 'only people I follow' ) );
        so.add( new SelectOption( 'followsme', 'only people following me' ) );

        return so;
    }
    
    public SelectOption[] getUserOrders() {
        SelectOption[] so = new SelectOption[] {};
        
        so.add( new SelectOption( 'atoz', 'alphabetically' ) );
        so.add( new SelectOption( 'ztoa', 'reverse alphabetically' ) );
        so.add( new SelectOption( 'newest', 'newest people first' ) );
        so.add( new SelectOption( 'oldest', 'oldest people first' ) );
        
        return so;
    }

    public pageReference buildUserList() {
        User us = [select id, name, userroleid, profileid, department, state, country,
            managerid, manager.name, manager.managerid, manager.manager.managerid, manager.manager.manager.managerid, manager.manager.manager.manager.managerid
            from User
            where id = :Userinfo.getUserId()];
            
        userList = new followUser[] {};
        
        maxUsersInt = integer.valueof( maxUsers );
        first = 0;
            
        string query = 'select id, name, managerid, title, city, state, department, createddate '+
            'from User '+
            'where isactive = true and usertype = \'Standard\' and id <> \''+ UserInfo.getUserId() +'\' ';
            
        // Determine the query to run
        if( whichList == 'team' && us.managerid != null )
            query += 'and ( managerid = \''+ us.managerid +'\' or id = \''+ us.managerid +'\' ) ';
        else if( whichList == 'reports' )
        	query += 'and managerid = \''+ UserInfo.getUserId() +'\' ';
        else if( whichList == 'reports2' )
        	query += 'and manager.managerid = \''+ UserInfo.getUserId() +'\' ';
        else if( whichList == 'hierarchy' && us.managerid != null ) {
            query += 'and ( id = \''+ us.managerid +'\'';
            
            if( us.manager.managerid != null )
                query += ' or id = \''+ us.manager.managerid +'\' ';
                
            if( us.manager.manager.managerid != null )
                query += ' or id = \''+ us.manager.manager.managerid +'\' ';
                
            if( us.manager.manager.manager.managerid != null )
                query += ' or id = \''+ us.manager.manager.manager.managerid +'\' ';
                
            if( us.manager.manager.manager.manager.managerid != null )
                query += ' or id = \''+ us.manager.manager.manager.manager.managerid +'\' ';
                
            query += ' ) ';
        } else if( whichList == 'department' && us.department != null )
            query += 'and department = \''+ us.department +'\' ';
        else if( whichList == 'role' && us.userroleid != null )
            query += 'and userroleid = \''+ us.userroleid +'\' ';
        else if( whichList == 'profile' )
            query += 'and profileid = \''+ us.profileid +'\' ';
        else if( whichList == 'state' && us.state != null )
        	query += 'and state LIKE \'%'+ us.state +'%\' ';
        else if( whichList == 'country' && us.country != null )
            query += 'and country LIKE \'%'+ us.country +'%\' ';
        
        if( whichOrder == 'atoz' )
            query += 'order by lastname asc, firstname asc ';
        else if( whichOrder == 'ztoa' )
            query += 'order by lastname desc, firstname desc ';
        else if( whichOrder == 'newest' )
            query += 'order by createddate desc ';
        else if( whichOrder == 'oldest' )
            query += 'order by createddate asc ';
        
        query += (isTest ? ' limit 5' : ' limit 150' );
        
        // Execute the query, get our list of user results
        User[] uList = Database.query( query );
        
        // Compile follower/following data about these users with respect to the running user
        // Users following us
        EntitySubscription[] followsUsAll;
        
        if( limitPercent() < 90 ) 
        	followsUsAll = [select id, subscriberid
            from EntitySubscription
            where subscriberid IN :uList
            and parentid = :UserInfo.getUserId()
            limit 150];
        else
        	followsUsAll = new EntitySubscription[] {};
            
        Set<ID> followsUs = new Set<ID> ();
        
        for( EntitySubscription es : followsUsAll )
            followsUs.add( es.subscriberid );
        
        // Users we are following
        EntitySubscription[] weFollowAll;
        
        if( limitPercent() < 90 ) 
        	weFollowAll = [select id, parentid
            from EntitySubscription
            where subscriberid = :UserInfo.getUserId()
            and parentid IN :uList
            limit 150];
        else
        	weFollowAll = new EntitySubscription[] {};
            
        Set<ID> weFollow = new Set<ID> ();
        
        for( EntitySubscription es : weFollowAll )
            weFollow.add( es.parentid );
            
        // Following counts for the table
        AggregateResult[] followingCounts;
        
        if( limitPercent() < 10 ) 
        	followingCounts = [select subscriberid, count(id)
            from EntitySubscription
            where subscriberid IN :uList
            group by subscriberid
            order by count(id) desc
            limit 150];
        else
        	followingCounts = new AggregateResult[] {};
            
        Map<string,Integer> followingMap = new Map<string,Integer> ();
        
        for( AggregateResult ar : followingCounts )
            followingMap.put( string.valueof(ar.get('subscriberid')), integer.valueof(ar.get('expr0')) );
            
        // Follower counts for the table
        AggregateResult[] followerCounts;
        
        if( limitPercent() < 10 ) 
        	followerCounts = [select parentid, count(id)
            from EntitySubscription
            where parentid IN :uList
            group by parentid
            order by count(id) desc
            limit 150];
        else
        	followerCounts = new AggregateResult[] {};
            
        Map<string,Integer> followerMap = new Map<string,Integer> ();
        
        for( AggregateResult ar : followerCounts )
            followerMap.put( string.valueof(ar.get('parentid')), integer.valueof(ar.get('expr0')) );
        
        for( User u : uList ) {
            if( whichUsers == 'dofollow' && !weFollow.contains( u.id ) )
                continue;
            
            if( whichUsers == 'dontFollow' && weFollow.contains( u.id ) )
                continue;
                
            if( whichUsers == 'followsme' && !followsUs.contains( u.id ) )
                continue;
                
            userList.add( new followUser( u, weFollow.contains( u.id ), followsUs.contains( u.id ), followerMap.get( u.id ), followingMap.get( u.id ) ) );
        }
        
        return null;
    }
    
    public pageReference massFollow() {
        ID[] uList = new ID[] {};
        
        for( followUser fu : userList ) {
            if( !fu.checked )
                continue;
                
            if( !fu.weFollow )
                uList.add( fu.u.id );
        }
        
        if( uList.isEmpty() )
            return null;
        
        EntitySubscription[] ess = new EntitySubscription[] {};
            
        for( ID uid : uList )
            ess.add( new EntitySubscription( subscriberid = UserInfo.getUserId(), parentid = uid ) );
                
        insert ess;
        
        buildUserList();
        
        return null;
    }
    
    public pageReference massUnfollow() {
        ID[] uList = new ID[] {};
        
        for( followUser fu : userList ) {
            if( !fu.checked )
                continue;
                
            if( fu.weFollow )
                uList.add( fu.u.id );
        }
        
        if( uList.isEmpty() )
            return null;
        
        EntitySubscription[] ess = [select id
            from EntitySubscription
            where subscriberid = :UserInfo.getUserId()
            and parentid IN :uList];
                
        delete ess;
        
        buildUserList();
        
        return null;
    }
    
    // This is really wonky, but going over the limit is unacceptable.
    public integer limitPercent() {
    	return ( Limits.getQueryRows() * 100 ) / Limits.getLimitQueryRows();
    }
    
    public pageReference nextPeople() {
        if( first + maxUsersInt > userList.size() )
            return null;
            
        first += maxUsersInt;
        
        return null;
    }
    
    public string getNextLink() {
       integer remaining = userList.size() - ( first + maxUsersInt );
       
       return ( remaining > maxUsersInt ? 'Next '+ maxUsersInt : 'Last '+ remaining );
    }
    
    public pageReference prevPeople() {
        first -= maxUsersInt;
        
        if( first < 0 )
            first = 0;
            
        return null;            
    }
    
    public string getPrevLink() {
        integer remaining = first - maxUsersInt;
        
        if( remaining == 0 )
            remaining = - maxUsersInt;
        
        return ( remaining > 0 ? 'Prev '+ maxUsersInt : 'First '+ -remaining );
    }
    
    public class followUser {
        public User u           { get; set; }
        public boolean checked  { get; set; }
        
        public boolean weFollow { get; set; }
        public boolean followsUs{ get; set; }
        
        public integer followers{ get; set; }
        public integer following{ get; set; }
        
        public followUser( User u2, boolean wefollow2, boolean followsus2, integer followers2, integer following2 ) {
            u = u2;
            checked = false;
            
            weFollow = wefollow2;
            followsUs = followsus2;
            
            followers = followers2 != null ? followers2 : 0;
            following = following2 != null ? following2 : 0;
        }
    }
    
    public static testmethod void main() {
        chatterConnector cc = new chatterConnector();
        
        cc.isTest = true;
        
        cc.getUserLimits();
        cc.massFollow();
        cc.massUnfollow();
        cc.getPrevLink();
        cc.getNextLink();
        cc.prevPeople();
        cc.nextPeople();
        cc.getUserOrders();
        cc.getUserTypes();
        cc.getUserLists();
        
        //for( SelectOption so : cc.getUserLists() ) {
        	cc.whichList = 'hierarchy';
        	cc.buildUserList();
        //}
    }
}