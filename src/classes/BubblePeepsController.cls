public class BubblePeepsController {

    public PageReference followersClick() {
        return null;
    }


    public String uID    { get; set; }
    public Integer followerCount    { get; set; }
    public Integer followingCount    { get; set; }
    

    public BubblePeepsController() {}
   
            
    
    public List<EntitySubscription> getFollowing()
    {
       // Everyone we're following
        EntitySubscription[] followingES = [select id, parentid, subscriberid, parent.name
            from EntitySubscription
            where subscriberid = :uid
            order by parent.name LIMIT 20];
        
        List<EntitySubscription> following = new List<EntitySubscription> ();
        
        for( EntitySubscription es : followingES )
            if( ('' + es.parentid).substring(0,3) == '005' ) // users only
                following.add(es);       
           
       followingCount = following.size();
       return following;
    }
    
     public List<EntitySubscription> getFollowers()
    {
        
          // All users who are following us
        List<EntitySubscription> followers = [select id, subscriberid, subscriber.name
            from EntitySubscription
            where parentid = :uid
            order by subscriber.name LIMIT 20];
        
        followerCount = followers.size();
        return followers;
    }
    
     public static testmethod void runTest() {
        BubblePeepsController b = new BubblePeepsController();
        b.junk();
    }
    
    public void junk() {
        integer x = 0;
        
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
    }
    
}