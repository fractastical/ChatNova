@isTest
private class TaskTestSuite {

/**
 * Test case coverage for Chatter Tasks
 * $Author: jdietz@gmail.com
 */
	static testMethod void testTasksWithSitesUser()
	{
		User gu = [select id,name from User where id='005A0000000RnqyIAC'];
		System.runAs(gu) 
		{
			
			TaskController taskcon = new TaskController();
			taskcon.newTask.assigned_to__c = '005A0000000RnqyIAC';
			String taskName = 'My Test Task #' + math.rint(math.random() * 10000);
			taskcon.newTask.name = taskName;
			taskcon.addNewTask();  
			String tdid;
			taskcon.loadAssignedTasks();
			
			Boolean testTaskFound = false;    
			for(ToDoItem__c tdi : taskcon.getAssignedTasks()) {
				if(tdi.name == taskName) 
				{	
					testTaskFound = true;
					break;
				}
			}
			System.assert(testTaskFound);
			
			testTaskFound = false;
			
			for(ToDoItem__c tdi : taskcon.getMyToDoList()) {
				if(tdi.name == taskName) 
				{	
					testTaskFound = true;
					tdid = tdi.id;
					taskCon.tdid = tdi.id;
					break;
				}
			}
			System.assert(testTaskFound);
			
			String compNote = 'Completed. Note #' + math.rint(math.random() * 10000);
			taskCon.note = compNote;  
			taskCon.markComplete();
   			
			testTaskFound = false;		
			for(ToDoItem__c tdi : taskcon.getMyToReviewList()) {
				if(tdi.name == taskName) 
				{	
					testTaskFound = true;
					break;
				}
			}
			System.assert(testTaskFound);

			Boolean testTaskFeedItemFound = false;		
			for(TaskWrapper tw : taskcon.getTaskItemFeed()) {
				
				if(tw.taskFeedItem.FeedPost.body == compNote) 
				{	
					testTaskFeedItemFound = true;
					break;
				}
			}
			System.assert(testTaskFeedItemFound);
			
			String negNote = 'Neg Review. Note #' + math.rint(math.random() * 10000);
			taskCon.note = negNote;
			taskCon.negativeReview();
                                                                      
            testTaskFound = false;
			for(ToDoItem__c tdi : taskcon.getMyToDoList()) {
				if(tdi.name == taskName) 
				{	
					testTaskFound = true;
					break;  
				}
			}
			System.assert(testTaskFound);
			      
		    testTaskFeedItemFound = false;		
		    negNote = 'This task was just reviewed and marked incomplete with the following note: ' + negNote;
			for(TaskWrapper tw : taskcon.getTaskItemFeed()) {
				
				//  BBBB BSystem.debug('FP Body' + tw.taskFeedItem.FeedPost.body);
				
				if(tw.taskFeedItem.FeedPost.body == negNote) 
				{	
					testTaskFeedItemFound = true;
					break;
				}
			}
			System.assert(testTaskFeedItemFound);
			
			String remNote = 'Reminder. Note #' + math.rint(math.random() * 10000);
			taskCon.note = remNote;
			taskCon.sendReminder();
			remNote = gu.name + ' wants to know the status of this task with the note: ' + remNote;
   			System.debug('REMNOTE: ' + remNote);

   			   
		    testTaskFeedItemFound = false;  		
			for(TaskWrapper tw : taskcon.getTaskItemFeed()) {
				
				//System.debug('FPB: ' + tw.taskFeedItem.FeedPost.body);
				
				if(tw.taskFeedItem.FeedPost.body == remNote) 
				{	
					testTaskFeedItemFound = true;
					break;
				}
			}
			//Site guest user is over allowable posts per page
			System.assert(taskcon.overPostLimit());
			System.assertEquals(false,testTaskFeedItemFound);

			taskCon = new TaskController();
			taskCon.tdid = tdid;  
			String remNote2 = 'Reminder. Note #' + math.rint(math.random() * 10000);
			taskCon.note = remNote2;
			remNote2 = gu.name + ' wants to know the status of this task with the note: ' + remNote2;
			taskCon.sendReminder();
			     
		    System.debug('REMNOTE2: ' + remNote2);
		
			testTaskFeedItemFound = false;		 
			for(TaskWrapper tw : taskcon.getTaskItemFeed()) {
				
				System.debug('FPB: ' + tw.taskFeedItem.FeedPost.body);
				
				if(tw.taskFeedItem.FeedPost.body == remNote2) 
				{	
					testTaskFeedItemFound = true;
					break;
				}
			}
			System.assert(testTaskFeedItemFound);
			  						
			taskCon.markComplete();    
			String posNote = 'Pos Review. Note #' + math.rint(math.random() * 10000);
			taskCon.note = posNote;
			taskCon.positiveReview();
			
			testTaskFound = false;		
			for(ToDoItem__c tdi : taskcon.getMyToReviewList()) {
				if(tdi.name == taskName) 
				{	
					testTaskFound = true;
					break;
				}
			}
			System.assertEquals(false, testTaskFound);
			
			posNote = 'This task was just reviewed and marked finished with the following note: ' + posNote;
			
			String fiid;
			
			testTaskFeedItemFound = false;		
			for(TaskWrapper tw : taskcon.getTaskItemFeed()) {
				
				if(tw.taskFeedItem.FeedPost.body == posNote) 
				{	
					fiid = tw.taskFeedItem.id;			
					testTaskFeedItemFound = true;
					break;    
				}
			}
			System.assert(testTaskFeedItemFound);
  			
			String comNote = 'Comment. Note #' + math.rint(math.random() * 10000);
			taskCon.note = comNote;
			taskCon.fiid = fiid;    
			taskCon.submitComment();

			Boolean commentFound = false;		
			
			for(TaskWrapper tw : taskcon.getTaskItemFeed()) 
			{
				for(FeedComment fc : tw.TaskFeedItem.FeedComments)
				{  
					if(fc.CommentBody == comNote) 
					{	
						commentFound = true;
						break;
					}
				}
			}
			
			System.assert(commentFound);
			
			//A few other assertions just to fill things out
			
			System.assertNotEquals(null, taskCon.gettasksPerPageSO());
			
		} // End run as 
	
	}
	
	static testMethod void testTasksAdminMini()
	{
			User tu = TestUtility.createTestUser();
			System.runAs(tu) 
			{
				TaskAdminMiniCon tamcon = new TaskAdminMiniCon();
				tamcon.generateChartURLs();
				System.AssertNotEquals(null, tamcon.comparisonChartURL);
				System.AssertNotEquals(null, tamcon.userTopActiveChartURL);
				
			}
			
		
	}
	
	
}