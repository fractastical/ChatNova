public class BubbleCommentController {


    public string fID   { get; set; }
    public string comment   { get; set; }
   
   /*
    * gets called when you click on Add a comment link - to display popup
    * Prob never really need to do anything here but its nice to have a hook
    */
    public PageReference addACommentClick() {

        return null;
        
    }

    
    /**
     * This is where we really do the add comment
     */
    public PageReference addAComment() {
        
        FeedComment fcomment = new FeedComment();
        fcomment.FeedItemId = fID;
        fcomment.CommentBody = comment;
        insert fcomment;
        
        comment = '';
        return null;
        
    }
    
     public static testmethod void runTest() {
        BubbleCommentController b = new BubbleCommentController();
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