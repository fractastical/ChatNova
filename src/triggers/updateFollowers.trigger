trigger updateFollowers on ToDoItem__c (after insert, after update) {

    String oldAssignee;
    String oldManagedBy;
    String newAssignee;  
    String newManagedBy;  
    
    if(Trigger.isUpdate){
        
        for (ToDoItem__c  tdi : Trigger.new){
    
            oldAssignee = Trigger.oldMap.get(tdi.ID).assigned_to__c; 
            oldManagedBy = Trigger.oldMap.get(tdi.ID).managed_by__c;   
            newAssignee = Trigger.newMap.get(tdi.ID).assigned_to__c;
            newManagedBy = Trigger.newMap.get(tdi.ID).managed_by__c;
    
            if (newAssignee !=  oldAssignee) 
            {
                removeFollower(oldAssignee, tdi);
                addFollower(newAssignee, tdi);
            }
            if (newManagedBy !=  oldManagedBy) 
            {
                removeFollower(oldManagedBy, tdi);
                addFollower(newManagedBy, tdi);
            }            
    
            }
            
    }
        
    if(Trigger.isInsert){
    
        for (ToDoItem__c  tdi : Trigger.new){
    
            newAssignee = Trigger.newMap.get(tdi.ID).assigned_to__c;
            newManagedBy = Trigger.newMap.get(tdi.ID).managed_by__c;
            
     		if (newAssignee != null && newAssignee.length() > 0)
     			addFollower(newAssignee, tdi);
     		if (newManagedBy != null && newManagedBy.length() > 0)
	            addFollower(newManagedBy, tdi);
    
            }
    }

    public void addFollower(String userid, SObject objectToFollow) {
      
        //Creator of object is automatically subscribed
        
        List <EntitySubscription> existingSubs = [SELECT id from EntitySubscription where parentid=:objectToFollow.id and subscriberid=:userid];
        
        if (existingSubs.isEmpty())  
        {
            EntitySubscription e = new EntitySubscription(); 
            e.parentId = objectToFollow.id; 
            e.subscriberid = userid; 
            insert e;
        }
                
    } 

    public void removeFollower(String userid, SObject objectToStopFollowing) {
    
    try {
        EntitySubscription e = [SELECT id from EntitySubscription where parentid=:objectToStopFollowing.id and subscriberid=:userid limit 1];
        delete e;        
        }
    // Given that all subscriptions within this app are automated, there should always be subscriptions.  
    catch (ListException le) {
        System.debug(Logginglevel.WARN, 'No subscription was found for ToDoItem:' + objectToStopFollowing.id + ' and user: ' + userid); 
    }
    
    } 

}