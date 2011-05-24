// Jonathan Hersh - jhersh@salesforce.com - 2/23/2010

public with sharing class chatterTooltip {
    public string uID   { get; set; }
    
    public User u       { get; set; }
    
    public integer followers    { get; set; }
    public integer following    { get; set; }
    
    public boolean followingme  { get; set; }
    
    public string lastUpdate    { get; set; }
    public string timestr       { get; set; }
    
    public chatterTooltip() {}
    
    public string getUserName() {
        if( uID == null )
            return null;
            
        if( u != null )
            return u.name;
            
        User[] us = [select id, name 
            from User
            where id = :uID];
            
        if( us.isEmpty() )
            return '';
            
        u = us[0];
            
        loadData();
            
        return u.name;
    }
    
    public void loadData() {
        EntitySubscription[] ess = [select id, parentid
            from EntitySubscription
            where parentid = :uID
            or subscriberid = :uID];
            
        followers = 0;
        
        for( EntitySubscription es : ess )
            if( es.parentid == uID )
                followers++;
                
        following = ess.size() - followers;
        
        if( UserInfo.getUserId() != uID ) {
            EntitySubscription[] ess2 = [select id
                from EntitySubscription
                where parentid = :UserInfo.getUserId()
                and subscriberid = :uID];
                
            followingme = ess2.size() > 0;
        } else
            followingme = false;
            
        UserFeed[] ufs = [select id, FeedPost.body, createddate
            from UserFeed
            where parentid = :uID
            order by createddate desc limit 1];
            
        if( ufs.isEmpty() )
            return;
            
        lastUpdate = ufs[0].FeedPost.body;
        
        if( lastUpdate == null )
            return;
        
        if( lastUpdate.length() > 70 )
            lastUpdate = lastUpdate.substring( 0, 70 ) + '...';
            
        timestr = relativeTime( ufs[0].createddate );
    }
    
    public string relativeTime( Datetime dt ) {
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
    
    public static testmethod void runTest() {
        chatterTooltip ct = new chatterTooltip();
        ct.uid = UserInfo.getUserId();
        ct.getUserName();
        ct.loadData();
    }
}