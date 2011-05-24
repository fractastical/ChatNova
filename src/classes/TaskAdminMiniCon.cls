public with sharing class TaskAdminMiniCon {

	public String currid 					{ get; set; }
	public List <User> activeUsers 			{ get; set; }
	public String tdid 						{ get; set; }

	public String comparisonChartURL 		{ get; set; }
	public String userTopTaskComChartURL 	{ get; set; }   
	public String userTopActiveChartURL		{ get; set; }

  	   
	public TaskAdminMiniCon() {   
		
		currid = UserInfo.getUserID();
		
	}  
	
	public void generateChartURLs()
	{
		findTopActive();
		generateComparisonChart();
		
	}
		
	public void findTopActive() 
	{
		activeUsers = [SELECT id, name, alias from User limit 1000];
  		List<Integer> counterList = new List<Integer>(); 
  		Integer count;  
  		Map<String, String> userAlias = new Map<String,String>();
	  	Map<Integer,List <String>> counterMap = new Map<Integer,List <String>>();
  		
  		for (User user : activeUsers) 
  		{
  			System.debug('ALIAS:' + user.alias);
  			userAlias.put(user.id, user.alias);
  			//String ufq = 'SELECT count() from UserFeed where parentid = ' + user.id;
  			//String tdiq = 'SELECT id from ToDoItem__Feed where id = ' + user.id;
	  		//count = Database.countQuery(ufq);
	  		count = [SELECT id from UserFeed where parentid = :user.id].size();
	  		System.debug('Count:' + count);
	  		List<String> l = counterMap.get(count);
	  		if (l == null)   
	  			l = new List <String> ();  
	  		l.add(user.id);   
	  		counterMap.put(count, l);
	  		counterList.add(count);
	  		  		
	  		
  		}
  		
  		counterList.sort();
  		  
  		//System.debug('SIZE:' + counterList.size());
  		//System.debug('LAST ITEM:' + counterList[counterList.size() - 1]);
  		
  		List<String> mostActiveLabel = new List<String>();
  		List<Integer> mostActiveData = new List<Integer>(); 
  		String tempId;
  		Integer j = 1;
  		
  		for(Integer i = counterList.size() - 1; i >= 0 && j <= 10; i--) 
  		{
  			List<String> ids = counterMap.get(counterList[i]);
  			//System.debug('ID SIZE:' + ids.size());
  			
  			for (String id : ids) {
  				System.debug('MY ALIAS:' + userAlias.get(id));
  				mostActiveLabel.add(userAlias.get(id));
	  			mostActiveData.add(counterList[i]);
  				j++;
				System.debug('J:' + j);  
  				if (j>10)
  				 	break;
  			}
  			
  		}
  		userTopActiveChartURL = generateChartURL('Most Active Users', mostActiveData, mostActiveLabel, null);	    		
  			
	}
	
	  	
  
	public List<SelectOption> getActiveUsersSO() {
		  
		List <SelectOption> activeUsersSO = new List<SelectOption>();
		for (Integer i=0;i<activeUsers.size();i++)
			activeUsersSO.add(new SelectOption(activeUsers[i].id,activeUsers[i].name));
		return activeUsersSO;  
		
	}

	 public List<TaskWrapper> getAllFeedItems(DateTime startTime, DateTime endTime)
     { 
     	    EntitySubscription[] originalFollowing = [select parentid, subscriberid 
	            from EntitySubscription
			    where subscriberid = :currid //now I am the subscriber
			    order by parent.name];
     	
     		//A bit dangerous since you end up following everything and this can't be undone.
     		//followAllUsers();    
     		//followAllTDIItems(); 
     		//resetFollowing(originalFollowing);
     			       
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
    
    
	   
	public void generateComparisonChart()
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
		 	   		userStore.put(tiws[j].taskFeedItem.FeedPost.CreatedById, value);         
	  	 	    	
		 	    	tfiCount++;                         
		 	    	j++;  
		 	    }      
		 	    
		 	    comments += commentCount + ',';
		 	    assignedTasks += atCount + ',';
		 	    reviewedTasks += rtCount + ',';   
		 	    totalFeedItems += tfiCount + ',';
	
		 	    if (atCount > comparisonHighest)
		 	    	comparisonHighest = atCount;   
		 	    if (rtCount > comparisonHighest)
		 	    	comparisonHighest = rtCount;   	 	    	
				 }	  
	
		  Integer activityStep = calculateStepSize(activityHighest);
		  activityHighest = roundUpToClosestStep(activityHighest, activityStep);
	
		  Integer comparisonStep = calculateStepSize(comparisonHighest);
		  comparisonHighest = roundUpToClosestStep(comparisonHighest, comparisonStep);
		 // default  
		 String chartType = 'cht=bvg';
		 String colors = 'chco=4D89F9,C6D9FD';       
		 String spacing = 'chbh=20,4,20';    
		 String chartSize = 'chs=600x200';                          
		 String labels = 'chxt=x,y&chxl=0:|' + days.substring(0, days.length() - 1);   
		 String comparisonCoLabels = 'chdl=Assigned+Tasks|Completed+Tasks';             
		 String comparisonChartTitle = 'chtt=Tasks+You+Are+Following';
		 String comparisonYAxisRange = 'chxr=1,0,' + comparisonHighest + ',2';   
		 String comparisonScaling = 'chds=0,' + comparisonHighest;
		 String comparisonData = 'chd=t:' + assignedTasks.substring(0, assignedTasks.length() - 1) + '|' + reviewedTasks.substring(0, reviewedTasks.length() - 1);
		 //Prepare the chart URL         
		 String chartPath = 'http://chart.apis.google.com/chart?';    
		 comparisonChartURL = chartPath + chartType + '&' + comparisonChartTitle + '&' + comparisonCoLabels + '&' + comparisonYAxisRange + '&' + colors + '&' + comparisonScaling + '&' + labels + '&'  + spacing + '&'  + comparisonData + '&' + chartSize;       
   
	}                   
     
     // The step is the distance between each label on the y axis
     public Integer calculateStepSize(Integer highestVal)
     {
	     	//calculates the appropriate step to display on the y axis
		  List<Integer> possibleSteps = New Integer[]{1,2,5,10,20,50};  
		  for(Integer i= (possibleSteps.size() - 1);i >= 0; i--) {
		  	System.debug('HIGH DIV 6:' + (highestVAl / 6) + ' POSS STEP:' + possibleSteps[i]);  
		  	if ((highestVal / 6) > possibleSteps[i])  
		  		return possibleSteps[i];
		  }
		  return 1;            
     }
     
     public Integer roundUpToClosestStep(Integer highestVal, Integer step)
     {
     	  return highestVal + (step - (math.mod(highestVal,step)));   
     }	
     
     //The idea is that any parameter could be overwritten with a Map specifying a different value pair (hash)
    //Data integrity should also be insured (e.g. that the length of both the data and labels are the same)
    public String generateChartURL(String title, List<Integer> incomingData, List<String> incomingLabels, Map <String,String> valuePairs)
    {  
     	if (incomingData.size() == 0)
    		return '';
    	
    	String dataString = '';
    	Integer highest = 0;
    	for (Integer d : incomingData) {
    		if (d > highest)
    			highest = d;
    		dataString += d + ',';
    	}
    	 dataString = dataString.substring(0, dataString.length() - 1);
     
     	 Integer step = calculateStepSize(highest);
		 highest = roundUpToClosestStep(highest, step);
		//System.debug('STEP:' + step);  
		     
		 String chartType = 'cht=bvg'; //vertical bar chart
		 String colors = 'chco=4D89F9,C6D9FD';       
		 String spacing = 'chbh=20,4,20';    
		 String chartSize = 'chs=600x200';                          
		 
		 //y axis, start value, highest value, step	size
		 String YAxisRange = 'chxr=1,0,' + Highest + ',' + step;    
		 String scaling = 'chds=0,' + Highest;
		 String data = 'chd=t:' + dataString;        
		
		 String chartLabels = 'chxt=x,y&chxl=0:|';
		 
		 //System.debug('LABEL SIZE:' + incomingLabels.size());
		 for (String l: incomingLabels)
		 	chartLabels += l + '|';   
		 chartLabels = chartLabels.substring(0, chartLabels.length() - 1);
		 
		 //System.debug('CHART LABEL:'+chartlabels);
		 
		 String chartTitle = 'chtt=' + title.replaceAll(' ','+');  

	  
		 String chartPath = 'http://chart.apis.google.com/chart?';    
		 return  chartPath + chartType + '&' + ChartTitle + '&' + YAxisRange + '&' + colors + '&' + Scaling + '&' + chartLabels + '&' + spacing + '&'  + Data + '&' + chartSize;
    }
    
    
}