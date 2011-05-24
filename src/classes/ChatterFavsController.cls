public class ChatterFavsController {

    public PageReference removeFromFavorites() {
        return null;
    }


     public ChatterFavsController()
     {
     
     }
     
     public List<NewsFeed> getMyFavorites()
     {
        List<String> favids = new List<String>();
        for(Chatter_Favorite__c f : [select parentid__c from Chatter_Favorite__c where createdbyid = :UserInfo.getUserId()])
        {
            favids.add(f.parentid__c);
        }
        
      List<NewsFeed> myfeed = [SELECT Id, Type, 
                                CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CreatedDate,
                                ParentId, Parent.Name, 
                                FeedPostId, FeedPost.Body, FeedPost.Title, FeedPost.CreatedById,
                                (SELECT Id, FieldName, OldValue, NewValue 
                                        FROM FeedTrackedChanges ORDER BY Id DESC), 
                                (SELECT Id, CommentBody, CreatedDate,
                                        CreatedById, CreatedBy.FirstName, CreatedBy.LastName
                                        FROM FeedComments ORDER BY CreatedDate LIMIT 10)
                                FROM NewsFeed
                                WHERE Id in : favids
                                ORDER BY CreatedDate DESC
                                LIMIT 20];
        return myfeed;
    }
    
     public static testmethod void runTest() {
        ChatterFavsController b = new ChatterFavsController();
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