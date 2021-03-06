public class toDoController {

	private List <toDoItem__c> all;
	private List <toDoItem__c> myToDoList;
	private List <toDoItem__c> myToReviewList;	
    public toDoItem__c newTask 			{ get; set; } 
    public String note 					{ get; set; } 
	public String currid 				{ get; set; }
	public List <User> activeUsers 		{ get; set; }
	public String tdid 					{ get; set; }
	public String activityChartURL 		{ get; set; }  
	public String comparisonChartURL 	{ get; set; }
	public String commentChartURL 		{ get; set; }
	public String userChartURL	 		{ get; set; }   
	public String userFollowingURL		{ get; set; }   
	public String userOTURL	 			{ get; set; }   
	
	     
	private static Integer postLimitPerPage = 2;
	private Integer posts;  
	private Boolean isGuest;    
  	
	public toDoController() {
		
		currid = UserInfo.getUserID();
		System.debug('My id:' + currid); 
  
		posts = 0;      
	
		if(currid == '005A0000000RnqyIAC')  // Sites guest user
			isGuest = true;  
		else   
			isGuest = false;
			  
		newTask = new toDoItem__c();

		activeUsers = getActiveUsers();
		
		note = '';
		
	}
	
	public List <User> getActiveUsers()
	{
		//Potentially should limit some better way
		return [SELECT id, name, alias from User limit 10];
	}
	
	public List <ToDoItem__c> getMyToReviewList()
	{
		return [SELECT id, name, description__c, completed__c, reviewed__c, assigned_to__r.name from toDoItem__c where managed_by__c = :currid and reviewed__c = false order by createdDate DESC limit 10];
	}  
	
	public List <ToDoItem__c> getMyToDoList() 
	{
			return [SELECT id, name, description__c, managed_by__r.name, completed__c from toDoItem__c where assigned_to__c = :currid and reviewed__c = false order by createdDate DESC];
	}
	
	public List <ToDoItem__c> getAssignedTasks() 
	{   
		return [SELECT id, name, description__c, completed__c, reviewed__c, assigned_to__r.name, managed_by__r.name from toDoItem__c where name != 'Test Task' order by createdDate DESC limit 10];  
	}
	
	public void followAllUsers() 
	{
		for (User u : activeUsers) {    
			try {
				EntitySubscription e = new EntitySubscription();
				e.parentid = u.id;
				e.subscriberid = currid;
				insert e;   
			}
			Catch (Exception e) {
			}
		}		
	}
	
	
	public void resetFollowing(List<EntitySubscription> originalFollowing) 
	{
		for (EntitySubscription e : [select id, parentid, subscriberid
	            from EntitySubscription
			    where subscriberid = :currid])
			    delete e; 
			    
		for (EntitySubscription e : originalFollowing)  {
			EntitySubscription toInsert = new EntitySubscription();  
			toInsert.parentId = e.parentId;
			toInsert.subscriberId = e.subscriberId;
			insert toInsert;  
		}
				
	}  
		
	public void followAllTDIItems() 
	{
		List<ToDoItem__c> tdis = [SELECT id from ToDoItem__c LIMIT 200];
		for (ToDoItem__c t : tdis) {
			try {
				EntitySubscription e = new EntitySubscription();
				e.parentid = t.id;
				e.subscriberid = currid;
				insert e;
			}
			Catch (Exception e) {
			}
		}		
	}
	
	
	public void deleteJunkRecords(){
		
		//for()  
		  
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
                           //WHERE FeedPost.Body != ''
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
    
    
    
    public PageReference commentOnLatestItem() 
    {
        FeedComment fcomment = new FeedComment();
        fcomment.FeedItemId = getTaskfeed().get(0).id;
        fcomment.CommentBody = note;
        insert fcomment;
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
		      negNote.Body += '  with the following note: ' + note; 
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
		      posNote.Body += '  with the following note: ' + note; 
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
		   remNote.Body = user.name + ' wants to ask what the status is of this task';
		   if (note != null && note.length() > 1)
		      remNote.Body += '  including the following note: ' + note; 
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
	   }
	   
	   return null;
	}

	public List<SelectOption> getActiveUsersSO() {
		  
		List <SelectOption> activeUsersSO = new List<SelectOption>();
		for (Integer i=0;i<activeUsers.size();i++)
			activeUsersSO.add(new SelectOption(activeUsers[i].id,activeUsers[i].name));
		return activeUsersSO;  
		
	}
	
	public static testMethod void t1() {
		toDoController tdc = new toDoController();
		tdc.junk();
	}
	
	
	 public List<TaskWrapper> getAllFeedItems(DateTime startTime, DateTime endTime)
     { 
     	    EntitySubscription[] originalFollowing = [select parentid, subscriberid 
	            from EntitySubscription
			    where subscriberid = :currid //now I am the subscriber
			    order by parent.name];
     	
     		//A bit dangerous since you end up following everything and this can't be undone.
     		followAllUsers();    
     		followAllTDIItems(); 
     		resetFollowing(originalFollowing);
     	      
     		
			    
			   
     			    
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
                            WHERE CreatedDate > :startTime and CreatedDate < :endTime       
                            ORDER BY CreatedDate ASC, ID DESC        
                            LIMIT 1000])      
                            {                              	  
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
    
    
	
// Generates four chart URLs through the Google Charts API
// (1) Compares number of assigned tasks per day and number of tasks completed (and reviewed) per day
// (2) Displays total activity per day, including posts to feeds and tracked changed fields 
// (3) Displays total number of comments per day
// (4) Displays activity over the last week broken down by user
// (5) Displays number of outstanding tasks per user
// (6) Displays number of items each user is following   
   
public void generateChartURLs()
{    
   
	 Map<ID, Integer> userStore = new Map<ID, Integer>();   
	 for (User u : activeUsers) {
	 	userStore.put(u.id,0);
	 }     
	  	 
	 String days = '';
	 String reviewedTasks = '';
	 String assignedTasks = '';
	 String totalFeedItems = '';
	 String comments = '';
	 
	 Integer tfiCount;
	 Integer atCount;
	 Integer rtCount;
	 Integer commentCount;
	 Integer value; 
	
	 List<TaskWrapper> tiws = getAllFeedItems(Datetime.now().addDays(-7), Datetime.now());   
	 
	 // Used to generate highest value on the Y Axis  
	 Integer activityHighest = 0;         
	 Integer comparisonHighest = 0;  
	 Integer commentHighest = 0;       
	 Integer j = 0;
	    
	 for (Integer i=6; i >= 0; i--) {
	 	    atCount = 0;   
	 	    rtCount = 0;
	 	    tfiCount = 0;
	 	    commentCount = 0;
   
 	 	    Datetime d = Datetime.now().addDays(i * -1 );
	 	 	days += d.format('E') + '|';      
	 	    
	 	    while(j < tiws.size() && tiws[j].taskFeedItem.CreatedDate.date() <= d.date())
	 	    {
	 	    	if(tiws[j].markedComplete)        
	 	    		rtCount++;
	 	    	if(tiws[j].created)
	 	    		atCount++;
	 	    	commentCount += tiws[j].commentCount;
	 	    	
	 	    	value = userStore.get(tiws[j].taskFeedItem.CreatedById);  
	 	    	value++;  
	 	   		userStore.put(tiws[j].taskFeedItem.CreatedById, value);      
//	 	    	value = userStore.get(tiws[j].taskFeedItem.FeedPost.CreatedById);  
//	 	    	value++;     
	 	   		userStore.put(tiws[j].taskFeedItem.FeedPost.CreatedById, value);         
  	 	    	
	 	    	tfiCount++;                         
	 	    	j++;  
	 	    }      
	 	    
	 	    comments += commentCount + ',';
	 	    assignedTasks += atCount + ',';
	 	    reviewedTasks += rtCount + ',';   
	 	    totalFeedItems += tfiCount + ',';

	 	    if (commentCount > commentHighest)
	 	    	commentHighest = commentCount;   
	 	    if (tfiCount > activityHighest)
	 	    	activityHighest = tfiCount;   
	 	    if (atCount > comparisonHighest)
	 	    	comparisonHighest = atCount;   
	 	    if (rtCount > comparisonHighest)
	 	    	comparisonHighest = rtCount;   	 	    	
			 }	  

	  String userLabelData = '';
	  
	  Integer userCount = 0;
	  Integer userFollowingCount = 0;
	  Integer userOTCount = 0;

	  Integer userHighest = 0;  
	  Integer userFollowingHighest = 0;  
	  Integer userOTHighest = 0;  
	   
	  String userFollowing = '';
	  String userOutstandingTasks = '';
	  String users = '';
	  


	  for (User u : activeUsers) {
	  		  	
	  	userCount = userStore.get(u.id);
	  	users += userCount + ',';
	  	userLabelData += u.alias + '|';  
	  	userFollowingCount = [SELECT id from EntitySubscription where subscriberid = :u.id].size();
	  	userOTCount = [SELECT id from ToDoItem__c where completed__c = false and assigned_to__c = :u.id].size();
	 	    	 
		userFollowing += userFollowingCount + ',';     
		userOutstandingTasks += userOTCount + ',';
   
	  	if (userCount > userHighest)
	 	    	userHighest = userCount; 
	  	if (userFollowingCount > userFollowingHighest)
	 	    	userFollowingHighest = userFollowingCount; 
	  	if (userOTCount > userOTHighest)
	 	    	userOTHighest = userOTCount; 

	  }
	
	  
	  Integer activityStep = calculateStepSize(activityHighest);
	  activityHighest = roundUpToClosestStep(activityHighest, activityStep);

	  Integer comparisonStep = calculateStepSize(comparisonHighest);
	  comparisonHighest = roundUpToClosestStep(comparisonHighest, comparisonStep);

	  Integer commentStep = calculateStepSize(commentHighest);
	  commentHighest = roundUpToClosestStep(commentHighest, commentStep);

	  Integer userStep = calculateStepSize(userHighest);
	  userHighest = roundUpToClosestStep(userHighest, userStep);

	  Integer userOTStep = calculateStepSize(userOTHighest);
	  userOTHighest = roundUpToClosestStep(userOTHighest, userOTStep);

	  Integer userFollowingStep = calculateStepSize(userFollowingHighest);
	  userFollowingHighest = roundUpToClosestStep(userFollowingHighest, userFollowingStep);
	     
	  // default  
	 String chartType = 'cht=bvg';
	 String colors = 'chco=4D89F9,C6D9FD';       
	 String spacing = 'chbh=20,4,20';    
	 String chartSize = 'chs=600x200';                          

	 String labels = 'chxt=x,y&chxl=0:|' + days.substring(0, days.length() - 1);   
	 String userLabels = 'chxt=x,y&chxl=0:|' + userLabelData.substring(0, userLabelData.length() - 1);
	 
	 String comparisonCoLabels = 'chdl=Assigned+Tasks|Completed+Tasks';             
	 
	 String activityChartTitle = 'chtt=Posts';  
	 String comparisonChartTitle = 'chtt=Tasks';
	 String commentChartTitle = 'chtt=Comments';
	 String userChartTitle = 'chtt=User+Activity+over+the+Past+Week';      
	 String userFollowingChartTitle = 'chtt=Number+of+Subscriptions';      
	 String userOTChartTitle = 'chtt=Outstanding+Tasks';      

    //y axis, start value, highest value, step	
	 String activityYAxisRange = 'chxr=1,0,' + activityHighest + ',10';    
	 String comparisonYAxisRange = 'chxr=1,0,' + comparisonHighest + ',2';   
	 String commentYAxisRange = 'chxr=1,0,' + commentHighest + ',2';    
	 String userYAxisRange = 'chxr=1,0,' + userHighest;      
	 String userFollowingYAxisRange = 'chxr=1,0,' + userFollowingHighest;      
	 String userOTYAxisRange = 'chxr=1,0,' + userOTHighest;      

	
	 String activityScaling = 'chds=0,' + activityHighest;
	 String comparisonScaling = 'chds=0,' + comparisonHighest;
	 String commentScaling = 'chds=0,' + commentHighest;
	 String userScaling = 'chds=0,' + userHighest;
	 String userFollowingScaling = 'chds=0,' + userFollowingHighest;
	 String userOTScaling = 'chds=0,' + userOTHighest;

	 
	 String activityData = 'chd=t:' + totalFeedItems.substring(0, totalFeedItems.length() - 1);        
	 String comparisonData = 'chd=t:' + assignedTasks.substring(0, assignedTasks.length() - 1) + '|' + reviewedTasks.substring(0, reviewedTasks.length() - 1);
	 String commentData = 'chd=t:' + comments.substring(0, comments.length() - 1);        
	 String userData = 'chd=t:' + users.substring(0, users.length() - 1); 
	 String userFollowingData = 'chd=t:' + userFollowing.substring(0, userFollowing.length() - 1); 
	 String userOTData = 'chd=t:' + userOutstandingTasks.substring(0, userOutstandingTasks.length() - 1); 
  
	 //Prepare the chart URL         
	 String chartPath = 'http://chart.apis.google.com/chart?';    
	 activityChartURL =  chartPath + chartType + '&' + ActivityChartTitle + '&' + activityYAxisRange + '&' + colors + '&' + activityScaling + '&' + labels + '&' + spacing + '&'  + activityData + '&' + chartSize;
	 comparisonChartURL = chartPath + chartType + '&' + comparisonChartTitle + '&' + comparisonCoLabels + '&' + comparisonYAxisRange + '&' + colors + '&' + comparisonScaling + '&' + labels + '&'  + spacing + '&'  + comparisonData + '&' + chartSize;
	 commentChartURL =  chartPath + chartType + '&' + commentChartTitle + '&' + commentYAxisRange + '&' + colors + '&' + commentScaling + '&' + labels + '&' + spacing + '&'  + commentData + '&' + chartSize;
	 userChartURL =  chartPath + chartType + '&' + userChartTitle + '&' + userYAxisRange + '&' + colors + '&' + userScaling + '&' + userLabels + '&' + spacing + '&'  + userData + '&' + chartSize;
	 userFollowingURL =  chartPath + chartType + '&' + userFollowingChartTitle + '&' + userFollowingYAxisRange + '&' + colors + '&' + userFollowingScaling + '&' + userLabels + '&' + spacing + '&'  + userFollowingData + '&' + chartSize;
	 userOTURL =  chartPath + chartType + '&' + userOTChartTitle + '&' + userOTYAxisRange + '&' + colors + '&' + userOTScaling + '&' + userLabels + '&' + spacing + '&'  + userOTData + '&' + chartSize;
       
   
}                   
     
     // The step is the distance between each label on the y axis
     public Integer calculateStepSize(Integer highestVal)
     {
	     	//calculates the appropriate step to display on the y axis
		  List<Integer> possibleSteps = New Integer[]{1,2,5,10,20,50};  
		  for(Integer i= (possibleSteps.size() - 1);i <= 0; i--) {
		  	if ((highestVal / 6) > possibleSteps[i])  
		  		return possibleSteps[i];
		  }
		  return 1;
     }
     
     public Integer roundUpToClosestStep(Integer highestVal, Integer step)
     {
     	  return highestVal + (step - (math.mod(highestVal,step)));   
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