public with sharing class TaskWrapper {
		   
		public Boolean markedComplete		{ get; set; }	
		public Boolean markedIncomplete		{ get; set; }
		public Boolean markedReviewed		{ get; set; }	
		public Boolean created				{ get; set; }
		public String assignedTo			{ get; set; }	
		//public Boolean markedReviewedIncomplete	{ get; set; }
		public NewsFeed taskFeedItem		{ get; set; }
		public Integer commentCount 		{ get; set; }
		
		public taskWrapper() {
			markedComplete = false;   
			markedIncomplete = false;
			markedReviewed = false;
			created = false;
			assignedTo = '';
			//taskFeedItem = new NewsFeed();
   			
		}
		
		public Boolean successfulInitialize (NewsFeed tf, String tdid)  
		{  
			Boolean success = true;    
			taskFeedItem = tf;
			commentCount = tf.FeedComments.size();     
			
			for(Integer i=0; i < tf.FeedTrackedChanges.size(); i++)
			{ 
				System.debug('Field name:' + tf.FeedTrackedChanges[i].FieldName + ' New Value ' + tf.FeedTrackedChanges[i].newValue);    
				if (tf.FeedTrackedChanges[i].FieldName == 'ToDoItem__c.Completed__c')
				{
					if(tf.FeedTrackedChanges[i].newValue == true) 
						markedComplete = true;
					if(tf.FeedTrackedChanges[i].newValue == false)
						markedIncomplete = true;      					
				} 
				else if (tf.FeedTrackedChanges[i].FieldName == 'ToDoItem__c.Reviewed__c')
				{  
					if(tf.FeedTrackedChanges[i].newValue == true) 
						markedReviewed = true;
				// This should never be changed due to our use cases       
				//	if(newValue == 'false')
				//		markedIncomplete;					
				} 
				else if (tf.FeedTrackedChanges[i].FieldName == 'created')
				{  
					created = true; 
					//System.debug('created by: ' + tf.CreatedBy.FirstName + ' ' + tf.CreatedBy.LastName);   
					try { 
						ToDoItem__c tdi = [SELECT assigned_to__r.name from ToDoItem__c where id = :tdid LIMIT 1];
						assignedTo = tdi.assigned_to__r.name;
					}
					catch (Exception e) {
						// Item may have been deleted
					}  					   
				}	
				else    
				{      			
					success = false;
				}        
    				
			}  
			return success;  
			
		}
		

}