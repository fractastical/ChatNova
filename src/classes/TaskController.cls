/* Joel Dietz
   jdietz@gmail.com
   03/26/2010
*/

public class TaskController {
	
	private List <toDoItem__c> myToDoList;
	private List <toDoItem__c> myToReviewList;	
	public toDoItem__c newTask 			{ get; set; } 
	public String note 					{ get; set; } 
	public String currid 				{ get; set; }
	public List <User> activeUsers 		{ get; set; }
	public String tdid 					{ get; set; }
	public String fiid 					{ get; set; }
	public Integer queryItemLimit 		{ get; set; } // primarily for testing         
    
    private List <toDoItem__c> assignedTasks;
	private static Integer postLimitPerPage = 3;   
	private Integer posts;  
	private Boolean isGuest;    
	
	// All for pagination
	public TaskPage activePage              { get; set; }
	public List<TaskPage> pages             { get; set; }
	public List<TaskPage> activePages       { get; set; }
	public Integer activePagesStartPNumber  { get; set; }
	public Integer activePagesEndPNumber    { get; set; }
	public Boolean hasMorePagesAfter        { get; set; }
	public Boolean hasMorePagesBefore       { get; set; }
	public Integer pnum                     { get; set; }
	public Integer tasksPerPage         	{ get; set; } 
 
    private static Integer pagesPerSetofActivePages = 10; 

	public TaskController() {
		
		currid = UserInfo.getUserID();
		System.debug('My id:' + currid); 
  	
		if (currid == '005A0000000RnqyIAC' )  // Sites guest user
			isGuest = true;  
		else   
			isGuest = false;
			  
		newTask = new toDoItem__c();
		activeUsers = getActiveUsers();
		tasksPerPage = 10;		
		posts = 0;      
		note = '';
		queryItemLimit = 1000;
		
	}
		
	public void loadAssignedTasks() {
		
		assignedTasks = null;  
		updateAssignedTasks();  
		                
        if (assignedTasks.size() > 0)
		{
		    pages = populatePages(assignedTasks, tasksPerPage);
	    	pnum = 1;
	        activePage = pages[0];
	        pages[0].isActive = true;
	    	updateActivePages();         	
        }
        else
        {
        	activePage = new taskPage(new List<ToDoItem__c>(),1);
        	activePage.first = true;    
        	activePage.last = true;  
        }  
	}
	
	//Used for testing only
	public List<ToDoItem__c> getAssignedTasks() {
		return assignedTasks;		
	}
	
	
	public List <User> getActiveUsers()
	{
		//Potentially should limit some better way
		return [SELECT id, name, alias from User limit 100];
	}
	
	public List <ToDoItem__c> getMyToReviewList()
	{
		return [SELECT id, name, description__c, completed__c, reviewed__c, assigned_to__r.name from toDoItem__c where managed_by__c = :currid and reviewed__c = false order by createdDate DESC limit 15];
	}  
	
	public List <ToDoItem__c> getMyToDoList() 
	{
		return [SELECT id, name, description__c, managed_by__r.name, completed__c from toDoItem__c where assigned_to__c = :currid and reviewed__c = false order by createdDate DESC limit :queryItemLimit];
	}
	
	public void updateAssignedTasks() 
	{   
		if (assignedTasks == null)
		{
			assignedTasks = [SELECT id, name, description__c, completed__c, reviewed__c, assigned_to__r.name, managed_by__r.name from toDoItem__c where name != 'Test Task' order by createdDate DESC limit :queryItemLimit];  
		}
	}
	
		
	public Boolean overPostLimit()
	{
		posts++;
		if (isGuest && posts > postLimitPerPage)  
		{ 
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have exceeded your ' + postLimitPerPage + ' posts per page limit.'));
			return true;    
		}
		else
			return false;
	}  
	
	 public List<NewsFeed> getTaskFeed()
     {
                 List<NewsFeed> taskFeed = [SELECT Id, Type, 
                                CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CreatedDate,
                                ParentId, Parent.Name, 
                                FeedPostId, FeedPost.Body, FeedPost.Title, FeedPost.CreatedById,
                                (SELECT Id, FieldName, OldValue, NewValue 
                                        FROM FeedTrackedChanges ORDER BY Id DESC), 
                                (SELECT Id, CommentBody, CreatedDate,
                                        CreatedById, CreatedBy.FirstName, CreatedBy.LastName
                                        FROM FeedComments ORDER BY CreatedDate, ID DESC LIMIT 10)
                                FROM NewsFeed    
                                WHERE ParentId = :tdid    
                               //WHERE FeedPost.Body != ''
                                ORDER BY CreatedDate DESC, ID DESC
                                LIMIT 100];
                                
                                
                 return taskFeed;
    }
    
    public List<TaskWrapper> getTaskItemFeed()
     {   
     			
 			 List<TaskWrapper> tfiws = new List<TaskWrapper>();
     		 TaskWrapper tfiw;	 
             for (NewsFeed tfi : [SELECT Id, Type, 
                            CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CreatedDate,
                            ParentId, Parent.Name, 
                            FeedPostId, FeedPost.Body, FeedPost.Title, FeedPost.CreatedById,
                            (SELECT Id, FieldName, OldValue, NewValue 
                                    FROM FeedTrackedChanges ORDER BY Id DESC), 
                            (SELECT Id, CommentBody, CreatedDate,
                                    CreatedById, CreatedBy.FirstName, CreatedBy.LastName
                                    FROM FeedComments ORDER BY CreatedDate, ID DESC LIMIT 10)
                            FROM NewsFeed    
                            WHERE ParentId = :tdid    
                            ORDER BY CreatedDate DESC, ID DESC  
                            LIMIT 100])
                            {
                            	System.debug('arg');
                            	  
                            	if (tfi != null) 
                            	{ 
	                            	System.debug('tfi' + tfi.id);  
	                            	tfiw = new TaskWrapper();                            	
	                            	if (tfiw.successfulInitialize(tfi,tdid))  
	                            		tfiws.add(tfiw);  
                            	}             
                            }    
                                
                 return tfiws;     
    }
    
    
    
    public PageReference submitComment() 
    {
        FeedComment fcomment = new FeedComment();
        fcomment.FeedItemId = fiid;
        fcomment.CommentBody = note;
        insert fcomment;
        note = '';    
        return null;   
    }
    	
	
	public PageReference markComplete() {
	
	   //String tdid = ApexPages.currentPage().getParameters().get('tdid');
	   //System.debug(tdid);    
	   
	   if(!overPostLimit())
	   {
	       toDoItem__c toMarkComplete = [SELECT id, name, completed__c from toDoItem__c where id = :tdid limit 1];	
		   toMarkComplete.completed__c = true;
		   update toMarkComplete;
		   
		   if(note.length() > 1)
		   {
			   FeedPost compNote = new FeedPost();
			   compNote.ParentID = toMarkComplete.id;
			   compNote.Body = note; 
			   insert compNote;  
			   
			   note = '';      
		   }
		   if(!isGuest)
		   {
		   	User user = [SELECT id, CurrentStatus from USer where id = :UserInfo.getUserId()];
			user.CurrentStatus = 'just completed task \'' + toMarkComplete.name + '\' ';
			update user;	  
		   } 		   
	   }
	         
	   return null;
	
	}
	
   public void grabToDoItemID() {
   	
   		   String tdid = ApexPages.currentPage().getParameters().get('tdid');
   	
   }
	
   public PageReference negativeReview() {
	
		if(!overPostLimit())
	   {
		   toDoItem__c toReviewNegative = [SELECT id, completed__c from toDoItem__c where id = :tdid limit 1];	
		   toReviewNegative.completed__c = false;
		   update toReviewNegative;
		   
		   FeedPost negNote = new FeedPost();
		   negNote.ParentID = toReviewNegative.id;
		   negNote.Body = 'This task was just reviewed and marked incomplete';
		   if (note != null && note.length() > 1)
		      negNote.Body += ' with the following note: ' + note; 
		   insert negNote;  
		   
		   note = '';
	   }
	   
	   return null;
	
	}

   public PageReference positiveReview() {
	
	   if(!overPostLimit())
	   {
		
		   toDoItem__c toReviewPositive = [SELECT id, reviewed__c from toDoItem__c where id = :tdid limit 1];	
		   toReviewPositive.reviewed__c = true;
		   update toReviewPositive;
			
		   FeedPost posNote = new FeedPost();
		   posNote.ParentID = toReviewPositive.id;
		   posNote.Body = 'This task was just reviewed and marked finished';
		   if (note != null && note.length() > 1)
		      posNote.Body += ' with the following note: ' + note; 
		   insert posNote;  
		   
		   note = '';
	   }
	   
		return null;

	}
	
	 public PageReference sendReminder() {
	
	   if(!overPostLimit())
	   {
		   toDoItem__c toSendReminderAbout = [SELECT id, name from toDoItem__c where id = :tdid limit 1];	
		   User user = [SELECT id, name from USer where id = :UserInfo.getUserId()];
		
			
		   FeedPost remNote = new FeedPost();
		   remNote.ParentID = toSendReminderAbout.id;
		   remNote.Body = user.name + ' wants to know the status of this task';
		   if (note != null && note.length() > 1)
		      remNote.Body += ' with the note: ' + note; 
		   insert remNote;    
		   
		   note = '';
	   }
	   return null;
	
	}
	
	public PageReference addNewTask() 
	{
	   if(!overPostLimit())
	   {
		newTask.managed_by__c = currid;
		insert newTask;
		newTask = new toDoItem__c();
		loadAssignedTasks();
	   }
	   
	   return null;
	}

	public List<SelectOption> getActiveUsersSO() {
		  
		List <SelectOption> activeUsersSO = new List<SelectOption>();
		for (Integer i=0;i<activeUsers.size();i++)
			activeUsersSO.add(new SelectOption(activeUsers[i].id,activeUsers[i].name));
		return activeUsersSO;  
		
	}
	
	
    public List<TaskPage> populatePages(List<ToDoItem__c> tasks, Integer ItemsPerPage) 
    {
        List<TaskPage> newPages = new List<TaskPage>();
        Integer tasksAdded = 0;
        Integer pagenumber = 0;
    
        // Adds tasks to TaskPages until either all tasks are added or the page limit is reached
        while(tasksAdded < tasks.size())       
        { 
            pagenumber++;
            List<ToDoItem__c> tasksToAdd = new List<ToDoItem__c>();
        
            for(Integer i=0; i < ItemsPerPage; i++) {
                
                if(tasksAdded == tasks.size())
                    break;
                    
                tasksToAdd.add(tasks[tasksAdded]);
                tasksAdded++;
                    
                }
                
            newPages.add(new TaskPage(tasksToAdd,pagenumber));
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
        activePages = new List<TaskPage>();
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
        List<TaskPage> tempActivePages = new List<TaskPage>();
        activePages = new List<TaskPage>();

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
    
    public PageReference updatetasksPerPage() 
    {
        pnum = 1;
        pages = populatePages(assignedTasks, tasksPerPage);
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
            
    public List<SelectOption> gettasksPerPageSO()
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
    
    
    class TaskPage 
    {  
  
        public Boolean first 			{get; set;}
        public Boolean last 			{get; set;}
        public List <ToDoItem__c> pageTasks {get; set;}
        public Integer pageNumber 		{get; set;}
        public Boolean isActive 		{get; set;}

        public TaskPage(List <ToDoItem__c> mi, Integer pn)
        {
            pageTasks = mi;   
            pageNumber = pn;
            isActive = false;
            first = false;
            last = false;
        }  
        
    }
    
    static testMethod void testTaskPages()
	{
			User tu = TestUtility.createTestUser();
			System.runAs(tu) 
			{
				TaskController tc = new TaskController();
				List<ToDoItem__c> testTasks = new List<ToDoItem__c>();
				ToDoItem__c sampleTask;
				String descr = 'D' + math.rint(math.random() * 10000);
				for(Integer i=0; i < 41; i++) 
				{
					sampleTask = new ToDoItem__c();
					sampleTask.name = 'Test Task ' + i;
					sampleTask.description__c = descr;
					sampleTask.assigned_to__c = tu.id;
					sampleTask.managed_by__c = tu.id;
					testTasks.add(sampleTask);
				}
				insert testTasks;
				tc.queryItemLimit = 41;
				tc.loadAssignedTasks();
				System.assertEquals(41, tc.getAssignedTasks().size());
				System.assertEquals(5, tc.ActivePages.size());
				System.assert(tc.ActivePage.first);
				System.assertEquals(false, tc.ActivePage.last);
				System.assertEquals(false, tc.hasMorePagesAfter);
				System.assertEquals(false, tc.hasMorePagesBefore);
				tc.tasksPerPage = 2;
				tc.updatetasksPerPage();
				System.assertEquals(21, tc.pages.size());
				tc.pnum = 15;
				tc.updateActivePage();
				System.assert(tc.hasMorePagesBefore);
				System.assertEquals(false,tc.hasMorePagesAfter);
				System.assertEquals(false, tc.ActivePage.last);
				System.assertEquals(false, tc.ActivePage.first);
				tc.pnum = 21;
				tc.updateActivePage();
				System.assert(tc.hasMorePagesBefore);
				System.assert(tc.ActivePage.last);
				System.assertEquals(false,tc.hasMorePagesAfter);
				System.assertEquals(false, tc.ActivePage.first);
		}
	}
				
    	
}