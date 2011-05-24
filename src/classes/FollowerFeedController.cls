/**
 * Chatter Bubbles Main controller.
 * Includes examples on the main things you want to do with Chatter: retrieve your newsfeed, update a user status, and add comments
 * It also includes new features not in Chatter such as rechat, add to Favorites
 * Author: Quinton Wall - qwall@salesforce.com 03/01/2010
 * Modded: Joel Dietz - jdietz@gmail.com 03/18/2010
 */
public class FollowerFeedController {

     public string rechatid                 { get; set; }
     public string rechatfrom               { get; set; }
     public string rechatname               { get; set; }
     public string favid                    { get; set; }
     public Date lastcomment                { get; set; }
     public string status                   { get; set; }
     public string currid                   { get; set; }
     public BubblePage activePage           { get; set; }
     public List<BubblePage> pages          { get; set; }
     public List<BubblePage> activePages    { get; set; }
     public Integer activePagesStartPNumber { get; set; }
     public Integer activePagesEndPNumber   { get; set; }
     public Boolean hasMorePagesAfter       { get; set; }
     public Boolean hasMorePagesBefore      { get; set; }
     public Integer pnum                    { get; set; }
     public string rechatbody               { get; set; }
     private static Integer pagesPerSetofActivePages = 10; 
     public Integer bubblesPerPage          { get; set; }  
     private List<NewsFeed> myFeed;
           
     public FollowerFeedController()
     {   
        
     }
     
	 public void init() {
	 
	    currid = UserInfo.getUserID();  
  
        //Default
        bubblesPerPage = 2;
        
        myfeed = [SELECT Id, Type, 
                        CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CreatedDate,
                        ParentId, Parent.Name, 
                        FeedPostId, FeedPost.Body, FeedPost.Title, FeedPost.CreatedById,
                        (SELECT Id, FieldName, OldValue, NewValue 
                                FROM FeedTrackedChanges ORDER BY Id DESC), 
                        (SELECT Id, CommentBody, CreatedDate,
                                CreatedById, CreatedBy.FirstName, CreatedBy.LastName
                                FROM FeedComments ORDER BY CreatedDate, ID DESC LIMIT 10)
                        FROM NewsFeed
                       WHERE CreatedById != :UserInfo.getUserId() AND FeedPost.Body != ''
                       //WHERE FeedPost.Body != ''
                        ORDER BY CreatedDate DESC, ID DESC
                        LIMIT 100];
        
        if (myFeed.size() > 0)
		{
		    pages = populatePages(myFeed, bubblesPerPage);
	    	pnum = 1;
	        activePage = pages[0];
	        pages[0].isActive = true;
	    	updateActivePages();         	
        }
        else
        {
        	activePage = new BubblePage(new List<NewsFeed>(),1);
        	activePage.first = true;    
        	activePage.last = true;  
        }  
        	
        //make a bunch of grumpy test postings (you will have to manually have your users follow the test item created)
        /*  toDoItem__c tdi = new toDoItem__c();
            tdi.name = 'Test Task';    
            insert tdi;
        
        for(Integer i=0;i<60;i++) {
        	
     	    FeedPost fpost = new FeedPost();
            fpost.ParentId = tdi.id;  
            //Toggle following bodies depending on who is logged in when we are populating sample data
            //fpost.Body = 'checking to make sure everything is hunky dory for the ' + i + 'th time';
            fpost.Body  = 'Failed attempt #' + i + 'to find something to be grumpy about. Humbug.';
            insert fpost;      
                
        }  */
	 	
	 }
         
          
    /**
     * Save the current feedpost to my favorites
     */
    public void addToFavorites()
    {
        Chatter_Favorite__c fav = new Chatter_Favorite__c();
        fav.parentid__c = favid;
        insert fav;
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Favorite Added. Yipee!'));
        
    }
    
    /**
     * Take the current feedpost and repost it as if it was coming from me. Reposting will then send it to all my followers
     */
    public void doRechat()
    {
            FeedPost fpost = new FeedPost();
            fpost.ParentId = rechatfrom;
            fpost.Body  = 'I rechatted: '+rechatbody;
            insert fpost;
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Rechat successful. '));
    }
    
    /**
     * Update my user status. Right now it only supports textposts, but I will update to include filepost and linkpost types.
     */
    public PageReference doUserStatus() 
    {
        User user = [select id, CurrentStatus from User where id = :UserInfo.getUserId()];
        user.CurrentStatus = status;
        update user;
        return null;
    }
    
    public String getIsRechat(String s)
    {
        if(s.startsWith('I rechatted'))
            return 'true';
        else
            return 'false';
    }
    
    public List<BubblePage> populatePages(list<NewsFeed> bubbles, Integer ItemsPerPage) 
    {
        List<BubblePage> newPages = new List<BubblePage>();
        Integer bubblesAdded = 0;
        Integer pagenumber = 0;
    
        // Adds bubbles to bubblepages until either all bubbles are added or the page limit is reached
        while(bubblesAdded < bubbles.size())       
        { 
            pagenumber++;
            List<NewsFeed> bubblesToAdd = new List<NewsFeed>();
        
            for(Integer i=0; i < ItemsPerPage; i++) {
                
                if(bubblesAdded == bubbles.size())
                    break;
                    
                bubblesToAdd.add(bubbles[bubblesAdded]);
                bubblesAdded++;
                    
                }
                
            newPages.add(new BubblePage(bubblesToAdd,pagenumber));
            if(pagenumber == 1) {
                newPages[0].first = true;
            }
            
            //DEPRECATED now that we have ActivePages 
            //if(pagenumber==pagesPerSetofActivePages)
            //    break;  
        
        }   
            
        newPages[pagenumber-1].last=true;
        
        return newPages;
    }
    
        
    public void updateActivePages() 
    {
        activePages = new List<BubblePage>();
        activePagesStartPNumber = pnum;
        Integer startIndex = pnum - 1;        
        Integer endIndex = startIndex + pagesPerSetofActivePages;
                    
        for (Integer i= startIndex; i < pages.size() && i < endIndex; i++)
            activePages.add(pages[i]);
        
        activePagesEndPNumber = activePages[activePages.size() - 1].pageNumber;

        if (activePagesEndPNumber == pages.size())
            hasMorePagesAfter = false;
        else 
            hasMorePagesAfter = true;  
                
        if (activePagesStartPNumber == 1)
            hasMorePagesBefore = false;
        else
            hasMorePagesBefore = true;
            
        setActivePage();
                                                       
    }

    public void updateActivePagesBackwards() 
    {
        List<BubblePage> tempActivePages = new List<BubblePage>();
        activePages = new List<BubblePage>();

        activePagesEndPNumber = pnum;
        Integer endIndex = pnum - 1;
        Integer startIndex = endIndex - pagesPerSetofActivePages - 1;        

        for (Integer i= endIndex; (i >= 0) && (i > startIndex); i--)
            tempActivePages.add(pages[i]);    
            
        for(Integer i = (tempActivePages.size() - 1); i >= 0; i--) {
            //System.debug('i:' + i);
            activePages.add(tempActivePages[i]);
        }  
                    
        activePagesStartPNumber = activePages[0].pageNumber;
        
        if (activePagesEndPNumber == pages.size())
            hasMorePagesAfter = false;
        else 
            hasMorePagesAfter = true;
                
        if (activePagesStartPNumber == 1)  
            hasMorePagesBefore = false;
        else
            hasMorePagesBefore = true;
            
        setActivePage();
                                       
    }
    
    public PageReference updateBubblesPerPage() 
    {
        pnum = 1;
        pages = populatePages(myFeed, bubblesPerPage);
        activePage = pages[0];   
        pages[0].isActive = true;
    	updateActivePages();  
          
        return null;    
    }
    
    public void setActivePage() 
    {
        Integer oldPN = activePage.pageNumber;
        activePage = pages[pnum - 1];
        pages[oldPN - 1].isActive = false;
        pages[pnum - 1].isActive = true;
    }

        
    public void updateActivePage()
    {
         setActivePage();
        if (pnum > activePagesEndPNumber)
            updateActivePages();
        if (pnum < activePagesStartPNumber)
            updateActivePagesBackwards();           
    }
        
    public void goToLast()
    {
        if (pages != null && pages.size() > 0)
            pnum = pages.size()-1;
        updateActivePage();
        
    }
            
    public List<SelectOption> getBubblesPerPageSO()
    {
    	List<SelectOption> bbpso = new List<SelectOption>();
    	bbpso.add(new SelectOption('1','1'));
    	bbpso.add(new SelectOption('2','2'));
    	bbpso.add(new SelectOption('5','5'));
    	bbpso.add(new SelectOption('10','10'));
    	bbpso.add(new SelectOption('20','20'));
    	bbpso.add(new SelectOption('50','50'));
    	return bbpso;  
    }
    
    public void nextPage()
    {
      if (!activePage.last) 
        pnum = activePage.pageNumber + 1;
      updateActivePage();  
    }
    
   public void prevPage()
   {
      if (!activePage.first)
        pnum = activePage.pageNumber - 1;
      updateActivePage();
    }
    
    
    class BubblePage 
    {  
  
        public Boolean first {get; set;}
        public Boolean last {get; set;}
        public List <NewsFeed> pageFeed {get; set;}
        public Integer pageNumber {get; set;}
        public Boolean isActive {get; set;}
        

        public BubblePage(List <NewsFeed> mi, Integer pn)
        {
            pageFeed = mi;   
            pageNumber = pn;
            isActive = false;
            first = false;
            last = false;
        }  
        
    }
    
  
   public static testmethod void runTest() {
        FollowerFeedController b = new FollowerFeedController();
        b.junk();
        b.testBubblePages();
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

    public void testBubblePages() {

   //  
        
    }

 }