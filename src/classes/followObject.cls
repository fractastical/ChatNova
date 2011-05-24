// Jonathan Hersh - jhersh@salesforce.com - 2/23/2010

public class followObject {
    public ID toFollow  { get; set; }
    
    public boolean doesFollow   { get; set; }
    public boolean followSet    { get; set; }
    
    public followObject() {
        followSet = false;
    }
    
    public boolean getFollow() {
        if( followSet )
            return doesFollow;
            
        followSet = true;
        
        EntitySubscription[] ess = [select parentid, subscriberid 
            from EntitySubscription
            where parentid = :toFollow
            and subscriberid = :UserInfo.getUserId()];
            
        doesFollow = ess.size() > 0;
            
        return doesFollow;
    }
    
    public pageReference toggleFollow() {
        EntitySubscription[] ess = [select parentid, subscriberid 
            from EntitySubscription
            where parentid = :toFollow
            and subscriberid = :UserInfo.getUserId()];
            
        if( ess.size() > 0 ) {
            doesFollow = false;
            delete ess;
        } else {
            EntitySubscription tmp = new EntitySubscription();
            tmp.parentid = toFollow;
            tmp.subscriberid = UserInfo.getUserId();
            
            insert tmp;
            doesFollow = true;
        }
        
        return null;
    }
    
    public static testmethod void runTest() {
        // Try to follow a random user?
        followObject fo = new followObject();
        
        Profile p = [select id from profile where name='Standard User']; 
        User u = new User(alias = 'standt', email='standarduser@kwutang.demo', 
                        emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US', 
                        localesidkey='en_US', profileid = p.Id, 
                        timezonesidkey='America/Los_Angeles', username='standarduser@kwutang.demo');        
        
        insert u;
        
        //ID uID = [select id from User where id <> :UserInfo.getUserId() and isactive = true and usertype = 'Standard' limit 1].id;
        
        fo.toFollow = u.ID;
        
        fo.getFollow();
        fo.toggleFollow();
        fo.toggleFollow();
    }
}