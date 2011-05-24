public with sharing class TestController {
	
	
		//public TestController(){
		//	
		//}	
		
		static testMethod void moreChatterRecipes()
		{

		// We want to insert but don't know if an EntitySub already exists
		
		//EntitySubscription es = new EntitySubscription();
		//es.parentId = 'objectId';
		//es.subscriberId = 'id of user';

		//This will not throw an Exception even if the insert is unsuccessful 
		
	   // Database.SaveResult sr = Database.insert(es,false);
	
		AggregateResult beforeCount = [select COUNT(id) ciid from UserFeed];
		
		//Add something which should go in the feed
		
		AggregateResult afterCount = [select COUNT(id) ciid from UserFeed];
		
		System.assertEquals( ( (Integer) beforeCount.get('ciid') + 1), (  (Integer) afterCount.get('ciid')));
//afterCount.get('ciid')
		List<AggregateResult> usersWithMostActivity = 	
		[ SELECT ParentId pid, Parent.Name pname, COUNT(id) fcount
			FROM UserFeed
			Where Type = 'UserStatus'
			And CreatedDate = THIS_WEEK
			GROUP BY Parent.Name, ParentID
			ORDER BY COUNT(id) DESC LIMIT 10 ];
			
		}
		


}