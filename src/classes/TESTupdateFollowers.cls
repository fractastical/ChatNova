@isTest
private class TESTupdateFollowers {  

   public static testMethod void doTest() 
   {
   
        Profile p = [select id from profile where name='Standard User'];

        User uat123 = new User(alias = 'AT123', email='test123@noemail.com',
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='at123@noemail.com');
        insert uat123;
        
        User umb123 = new User(alias = 'MB123', email='test123@noemail.com',
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='mb123@noemail.com');
        insert umb123;  
   
       ToDoItem__c tdi = new ToDoItem__c();
       tdi.name = 'Foo Task';
       tdi.assigned_to__c = umb123.id;
       tdi.managed_by__c = uat123.id;
       insert tdi;
       
       System.assertEquals(1, [SELECT id from EntitySubscription where subscriberid=:umb123.id and parentid=:tdi.id].size());
       System.assertEquals(1, [SELECT id from EntitySubscription where subscriberid=:uat123.id and parentid=:tdi.id].size());
       
       
       User uat321 = new User(alias = 'AT321', email='test321@noemail.com',
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='at3213@noemail.com');
        insert uat321;  
        
       
        User umb321 = new User(alias = 'MB321', email='test321@noemail.com',
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='mb321@noemail.com');
        insert umb321;
        
        tdi.assigned_to__c = uat321.id;
        tdi.managed_by__c = umb321.id;     
        update tdi;  
        
        System.assertEquals(0, [SELECT id from EntitySubscription where subscriberid=:umb123.id].size());
        System.assertEquals(0, [SELECT id from EntitySubscription where subscriberid=:uat123.id].size());
        System.assertEquals(1, [SELECT id from EntitySubscription where subscriberid=:umb321.id and parentid=:tdi.id].size());
        System.assertEquals(1, [SELECT id from EntitySubscription where subscriberid=:uat321.id and parentid=:tdi.id].size());  
   
   }

}