public class ChatController {

    //TODO:Captcha after certain number of posts

	private List<Chat_Session__Feed> oldChatPosts 	{ get; private set; } 
    public List<ChatPostWrapper> chatPosts			{ get; private set; }
    public List<Chat_User__c> chatUsers 			{ get; private set; }
    public List<Private_Message__c> privateMessages { get; private set; }
	public List<Chat_Session__Feed> rawChatPosts    { get; private set; } 
	public List<ChatPostWrapper> prevPosts			{ get; private set; }
	
    public List <String> notificationMessages { get; private set; }
    
    public Chat_Session__c session      { get; private set; }
    public Boolean userVerified         { get; private set; }
    public String activeUserId          { get; private set; }  
    public String currUserId            { get; private set; }
    
    private Map<String, Schema.SObjectType> gd;
    private List<SelectOption> SObjectList;
    private List<SelectOption> activeSObjects;
    private List<SelectOption> SObjectFeed;
    private DateTime oldestChatPostTime;
    
    //messages
    private static String invalidHandleErrorMsg = 'This handle has already been registered. Please pick another one.';
    private static String tooShortHandleErrorMsg = 'Minimum length is 4 characters. Please pick another handle.';
    private static String invalidAccessCodeErrorMsg = 'This access code is invalid. Please try again.';    
    private static String privateMessageSuccessMsg = 'Your private message was successfully submitted';
    
    
  	Integer debugIterator = 0;
  	
    //Params
    public String userInputedAccessCode 	 { get; set; }
    public String postBody              	 { get; set; }
    public Private_Message__c privateMessage { get; set; }
    public String pmid              		 { get; set; }
    public String activeUserHandle      	 { get; set; }
    
	//Merge feed 
    public String newActiveSObjectType      	 { get; set; } 

    public String activeSObjectType		{ get; set; }
    public String activeSObject 		{ get; set; }
    public List<String> activeSObjectFeedItems { get; set; }

    public ChatController()
    {
    	privateMessage = new Private_Message__c(); 
        notificationMessages = new String[1];     
        privateMessages = new List <Private_Message__c>();    
    }
    
    public PageReference roomsInit() {
			    
        currUserId = UserInfo.getUserID();
        if(UserInfo.getUserType() != 'Guest')
        {
            User au = [select id, alias from User where id =: currUserId];
            activeUserHandle = au.alias;
        }
        
        return null;               
    }
    
    
    public PageReference init() {

		/*Integer i = 0;
		List<FeedPost> fps = new List<FeedPost>();
		for (Lead a: [Select id from Lead limit 50])
		{
            FeedPost p = new FeedPost();
            p.parentId = a.id;
            Integer mod = Math.mod(i,3);
            if (mod == 0)
	            p.Body = 'Great';
	        else if (mod == 1)
	        	p.Body = 'Awesome';
	        else if (mod == 2)
	        	p.Body = 'Cool';
            p.Body += ' Lead';
            fps.add(p);
            i++;
		}
		insert fps;*/


		oldChatPosts = new List<Chat_Session__Feed>();
        Boolean preLoad = false;
        
        String idParam = ApexPages.currentPage().getParameters().get('id');
        if(idParam != null && idParam != '')
        {
        	try {
	            session = [SELECT id, name, requires_verification__c, access_code__c, session_id__c, start_time__c from Chat_Session__c where session_id__c =: idParam limit 1 ];
        	}
        	catch(QueryException qe)
        	{
        		PageReference newPage = new PageReference('chatRooms');
				return newPage.setRedirect(true);
        	}        
        }
		if(session == null)
        	{
        		PageReference newPage = new PageReference('chatRooms');
				return newPage.setRedirect(true);
        	}
			    
        currUserId = UserInfo.getUserID();
        if(currUserId != null && UserInfo.getUserType() != 'Guest')
        {
            List<Chat_User__c> cus = [SELECT id, name from Chat_User__c where Chat_Session__c =: session.id and User__c =: currUserId limit 1];
            System.debug('ARG NO CHAT USERS s:' + session.id + ' curr' + currUserId);
            if (cus.size() != 0)
            {            	
                activeUserHandle = cus[0].name;
            	System.debug('found a chat user, auh:' + activeUserHandle);
                activeUserId = cus[0].id;
                userVerified = true;
                preload = true;
                notificationMessages.set(0,'Welcome back ' + activeUserHandle);
            }
            else
            {
            	System.debug('not a guest but no chat user found');
                User au = [select id, alias from User where id =: currUserId];
                activeUserHandle = au.alias;
                userVerified = false;
            }
        }
        
        if (session.requires_verification__c == false)
            preload = true;

        if(preload)
        {
            updateAll();
        }
        
        return null;               
    }
    
    public void updateAll()
    {
	        updateChatPosts();
	        updateChatUsers();
	        //updatePrivateMessages();
    }
    
    //Used for testing only
    public List<Chat_Session__Feed> getAllChatPosts()
    {
	        return [SELECT id, FeedPost.Body, createdDate,
        				                          		  (SELECT Id, CommentBody, CreatedDate,
                                    						CreatedById, CreatedBy.FirstName, CreatedBy.LastName
                                    						FROM FeedComments ORDER BY CreatedDate, ID DESC LIMIT 10)
        										from Chat_Session__Feed where FeedPost.Body != '' and parentid=:session.id ORDER BY CreatedDate desc limit 500]; 
		
    }
    
    /*public void updatePrevChatPosts()
    {
	   List <Chat_Session__Feed> rawPrevPosts = [SELECT id, FeedPost.Body, createdDate,
				                          		  (SELECT Id, CommentBody, CreatedDate,
                            						CreatedById, CreatedBy.FirstName, CreatedBy.LastName
                            						FROM FeedComments ORDER BY CreatedDate, ID DESC LIMIT 10)
                            				from Chat_Session__Feed where FeedPost.Body != '' and parentid=:session.id and createdDate <: oldestChatPostTime ORDER BY CreatedDate desc limit 10]; 
                            						
	    rawPrevPosts = reverse(rawPrevPosts);
		if(rawPrevPosts.size() > 0)
		{
		   oldestChatPostTime = rawPrevPosts.get(0).createdDate;
	  	   oldChatPosts = merg(rawPrevPosts, oldChatPosts);
		}
		
		prevPosts = new List <ChatPostWrapper>();
		for(Chat_Session__Feed p : rawPrevPosts)
			prevPosts.add(new ChatPostWrapper(p));  
    	
    } 
    
static List<SObject> merg(List<SObject> list1, List<SObject> list2) {
        if(list1 != null && list2 != null && (list1.size()+list2.size()) > 9999){
            //throw new IllegalArgumentException('Lists cannot be merged because new list would be greater than maximum number of elements in a list: ' + 9999);
        }
        if(isEmpty(list1) && isEmpty(list2)){
            return null;
        }
        List<SObject> returnList = new List<SObject> ();
        if(list1 != null){
            for(SObject elmt : list1){
                returnList.add(elmt);
            }
        }
        if(list2 != null){
            for(SObject elmt : list2){
                returnList.add(elmt);
            }
        }
        return returnList;
    }
    
    static Boolean isEmpty(SObject[] objectArray){
        if(objectArray == null){
            return true;
        }
        return objectArray.size() == 0;
    }    
    
     static Boolean isNotEmpty(SObject[] objectArray){
        return !isEmpty(objectArray);
    } */   
        
    public void updateChatPosts()
    {
	    	System.debug('udating Chat posts');
	        rawChatPosts = [SELECT id, FeedPost.Body, createdDate,
        				                          		  (SELECT Id, CommentBody, CreatedDate,
                                    						CreatedById, CreatedBy.FirstName, CreatedBy.LastName
                                    						FROM FeedComments ORDER BY CreatedDate, ID DESC LIMIT 10)
        										from Chat_Session__Feed where FeedPost.Body != '' and parentid=:session.id ORDER BY CreatedDate desc limit 10]; 
		
		
		
		
			rawChatPosts = reverse(rawChatPosts);
		
			if(chatPosts != null) 
			{
				System.debug('chat posts not null');
				
		        chatPosts = new List <ChatPostWrapper>();       
		        for(Chat_Session__Feed rcp : rawChatPosts)
		        {
		            ChatPostWrapper cpw = new ChatPostWrapper(rcp, oldChatPosts);
		            if(cpw.newPost)
		            {
						System.debug('NEW POST');
		            	chatPosts.add(cpw);
		            	oldChatPosts.add(cpw.post); 
		            	if(oldChatPosts.size() == 500)
		            		oldChatPosts = new List<Chat_Session__Feed>();
		            }
		        }
			}
			else
			{
				System.debug('chat posts is null');
		        chatPosts = new List <ChatPostWrapper>();       
		        for(Chat_Session__Feed rcp : rawChatPosts)
			       	chatPosts.add(new ChatPostWrapper(rcp));
			    
			    oldChatPosts = rawChatPosts;
			    if(oldChatPosts.size() > 0)
		       		oldestChatPostTime = oldChatPosts.get(0).createdDate;
		       		
			}
			
     	//debugIterator++;
		//System.debug('Iteration ' + debugIterator + ' rawChat: ' + rawChatPosts.size() + ' chatPosts: ' + chatPosts.size() + ' oldChatPosts: ' + oldChatPosts.size() );
            
        
    }
    
    public void updateChatUsers()
    {
		/*
		Active Chat Users
		List<Chat_Session__Feed> postsInLastHour = [SELECT id, createdBy.Id from Chat_Session__Feed where parentId =: chatRoom.id and createdDate < :d limit 1000 ];
		Set<Id> uniqueUsers = New Set<Id>();
		for(Chat_Session__Feed p : postsInLastHour)
			uniqueUsers.add(p.createdBy.Id);
		*/ 
    	//Datetime n = Datetime.now();
    	//n.addHours(-2);
        //chatUsers = [SELECT id, name from Chat_User__c where Chat_Session__c =: session.id and lastPostTime__c > :n limit 100];
        chatUsers = [SELECT id, name from Chat_User__c where Chat_Session__c =: session.id order by name limit 100];
        
    }

    public void updatePrivateMessages()
    {
 	     privateMessages = [SELECT id, text__c, read__c, from__c from Private_Message__c where To__c =: activeUserId limit 1000];
        
    }

    public List<ChatRoomWrapper> getChatRooms()
    {
        List<Chat_Session__c> chatrooms =  [SELECT id, name, session_id__c from Chat_Session__c where persistent__c = true limit 10];
    	List<ChatRoomWrapper> crs = new List<ChatRoomWrapper>();
    	for(Chat_Session__c cs : chatrooms) 
    		crs.add(new ChatRoomWrapper(cs));
    	return crs;
    }
    
    public List<ChatRoomWrapper> getChatRoomsThatAllowGuests()
    {
        List<Chat_Session__c> chatrooms =  [SELECT id, name, session_id__c from Chat_Session__c where persistent__c = true and allows_guests__c = true limit 10];
    	List<ChatRoomWrapper> crs = new List<ChatRoomWrapper>();
    	for(Chat_Session__c cs : chatrooms) 
    		crs.add(new ChatRoomWrapper(cs));
    	return crs;
    }
    
    
    
    
    public Boolean verifyCode()
    {
        if (userInputedAccessCode == session.access_code__c)
        {
            return true;
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, invalidAccessCodeErrorMsg));
            return false;
        }   
    }
    
        
    public void register() {
        
        Boolean correctCode = false;
        if(session.requires_verification__c)
                correctCode = verifyCode();
        else
            correctCode = true;
        if(correctCode)
        {
            Boolean handleReg = registerUserHandle();
            if(handleReg)
            {
                userVerified = true;
                updateAll();
                notificationMessages.set(0,'Your handle was successfully registered');
            }
                
        }   
    }
    public Boolean registerUserHandle(){
        
        Boolean success = false;
        //TODO: add in connect
        if (activeUserHandle != null && activeUserHandle.length() > 3)
        {
            AggregateResult aur = [SELECT COUNT(id) c from Chat_User__c where Chat_Session__c =: session.id and name =: activeUserHandle];
        
            if (aur.get('c') == 0 )
            {
                Chat_User__c cu = new Chat_User__c();
                cu.name = activeUserHandle;
                cu.Chat_Session__c = session.id;
                if(currUserId != null)
                    cu.User__c = currUserId;
                insert cu;
                activeUserId = cu.id;
                FeedPost newPost = new FeedPost();
                newPost.ParentID = session.id;
	            newPost.Body = '@System: ' +  '@' + activeUserHandle + ' has entered the room.';
                insert newPost;  
                userVerified =  true; 
                success = true;
                
            }
            else
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, invalidHandleErrorMsg));
        }
        else
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, tooShortHandleErrorMsg));
            
        return success;
                
    }
    
    public void insertPost() {
           if (userVerified)
           {

               FeedPost newPost = new FeedPost();
               newPost.ParentID = session.id;
               
               newPost.Body = '@' + activeUserHandle + ': ' + postBody;
               insert newPost;  
           		postBody = '';
               //Chat_User__c c = [select id, lastPostTime__c from Chat_User__c where name =: activeUserHandle];
               //c.lastPostTime__c = Datetime.now();
               //update c;
               
               //updateChatPosts();
               
               notificationMessages.set(0, 'Your post was successfully submitted');
           }
        
    }
    
    
    
    public void readPrivateMessage() {
    	try {
	    	privateMessage = [SELECT id, read__c from Private_Message__c where id =: pmid limit 1];
	    	privateMessage.read__c = true;
	    	update privateMessage;
    	}
    	catch(Exception e)
    	{
    		System.debug('Error saving private message' + e);
    	}
    	privateMessage = new Private_Message__c();
    	
    }
    
    public void sendPrivateMessage() {
           if (userVerified)
           {
               privateMessage.from__c = activeUserId;
               insert privateMessage;
               privateMessage = new Private_Message__c(); 
               notificationMessages.set(0,privateMessageSuccessMsg);
           }
        
    }

    public List<SelectOption> getSObjectList() {
   		
   		if(SObjectList == null)
   		{
	   		gd = Schema.getGlobalDescribe(); 
	        List<SObjectType> tokens = gd.values();
	        SObjectlist = new List<SelectOption>();
			SelectOption so1 = new SelectOption('','--SELECT--');
			SObjectList.add(so1);
	        
	         for(SObjectType s:gd.values()) {
	            System.debug(' **************************** ' + s.getDescribe().getName() + ' ** ' + s.getDescribe().getLabel());
		       if(acceptedObject(s)) 
		       {
		            SelectOption so = new SelectOption(s.getDescribe().getName(), s.getDescribe().getLabel());
		            SObjectList.add(so);
		       }
		    }
   		}
    	
    	return SObjectList;
    }
    
    
    //MOD from CMSForce   
    //method used to clean out all the internal objects we don't want the users to create
    public Boolean acceptedObject(SObjectType s) {
        DescribeSObjectResult r = s.getDescribe();
        if(r.isCustom() && r.getName() == 'ChatterTasks__ToDoItem__c' )
        	return true;
        
        String acceptedobjects = 'Account Lead Opportunity User';
        
        //String acceptedobjects = 'Case Lead Opportunity Account Contact CampaignMember';
        if(acceptedobjects.contains(r.getName())) 
        	return true;        
        return false;
    }
    
    //mirror of above
    public Boolean acceptedObject(String SObjectType) {
    	System.debug('acceptedObject string:' + SObjectType);
        if(SObjectType == 'ChatterTasks__ToDoItem__c')
        	return true;
        
        String acceptedobjects = 'Account Lead Opportunity User';  
        
        //String acceptedobjects = 'Case Lead Opportunity Account Contact CampaignMember';
        if(acceptedobjects.contains(SObjectType)) 
        	return true;        
        return false;
    }
    
    
    public void updateSObjects() {
		//activeSObjectType = ;
		System.debug('UPDATESOBJECTS' + activeSObjectType + 'oc1' + ApexPages.currentPage().getParameters().get('oc1') + 'new' + newActiveSObjectType );
		
		if(activeSObjectType == '' || activeSObjectType == null)
			return;
			
        System.debug('ActiveSObjectType:' + activeSObjectType);
        List<SObject> sobjects = Database.query('select id, name from ' + activeSObjectType + ' order by createdDate desc limit 100 ');
        System.debug('SObjectsFound:' + sobjects.size());

        activeSObjects = new List<SelectOption>();
        //activeSObjects.add(new SelectOption( 'hello', activeSObjectType));
        
        for(SObject so : sobjects)
        	activeSObjects.add(new SelectOption( (String) so.get('id'), (String) so.get('name')));
    }
	 
	//get SObjects by name where feed was recently modified
    public List<SelectOption> getSObjects() {
    	return activeSObjects;
    	
    }

	private String feedObjectName(String SObjectType) {
		String feedObjectName = SObjectType;
    	try {
    			String extension = SObjectType.substring(SObjectType.length()-3, SObjectType.length());     	
	        	System.debug('UpdateSObjectFeed extension:' + extension);

    	        if (extension == '__c')  
    	        	feedObjectName = feedObjectName.substring(0,SObjectType.length()-1);
    	     }
    	catch(Exception e)
    	{
        	System.debug('UpdateSObjectFeed feedObjectName:' + feedObjectName);
    	}  
    	        
    	feedObjectName += 'Feed';
    	return feedObjectName;
		
	}

    public void updateSObjectFeed() {

		System.debug('updateSObjectFeed ASOT' + activeSObjectType + 'ASOB' + activeSObject + 'oc1' + ApexPages.currentPage().getParameters().get('oc1') + 'new' + newActiveSObjectType );
    	String feedObjectName = feedObjectName(activeSObjectType);    	
        //System.debug('updateSObjectFeed: ' + feedObjectName);
        //activeSObject = ApexPages.currentPage().getParameters().get('ActiveSObjectId');
		//System.debug('updateSObjectFeed' + activeSObject);
       
 		//if (acceptedObject(activeSObjectType) )
 		if(true)
 		{
 			//System.debug('UpdateSObjectFeed Query ASO:' + activeSObject);
 			
	       	if (feedObjectName == 'ChatterTasks__ToDoItem__Feed')
	       	   	{
	       	   		List<ToDoItem__Feed> tdiFeed = [select id, FeedPost.Body from ToDoItem__Feed where parentId =: activeSObject order by createdDate desc limit 100 ];
			        SObjectFeed = new List<SelectOption>(); 
			        for(ToDoItem__Feed tdi : tdiFeed)
			        {
				        String body = tdi.FeedPost.Body;
				        try {
					         body = body.substring(0, 40);
				        }
				        catch (Exception e)  
				        {
				        	
				        }
				        if (body != null)
				        	SObjectFeed.add(new SelectOption(tdi.id,  body));
			        }
					
					if(SObjectFeed.size() == 0)
							SObjectFeed.add(new SelectOption('', 'No Chatter Posts on this item'));       	   
			}
	       	else if (feedObjectName == 'AccountFeed') {
	       	   		List<AccountFeed> aFeed = [select id, FeedPost.Body from AccountFeed where parentId =: activeSObject order by createdDate desc limit 100 ];
			        SObjectFeed = new List<SelectOption>(); 
			        for(AccountFeed tdi : aFeed)
			        {
				        String body = tdi.FeedPost.Body;
				        try {
					         body = body.substring(0, 40);
				        }
				        catch (Exception e)  
				        {
				        	
				        }
				        if (body != null)
				        	SObjectFeed.add(new SelectOption(tdi.id,  body));
			        }
					
					if(SObjectFeed.size() == 0)
							SObjectFeed.add(new SelectOption('', 'No Chatter Posts on this item'));       	   
	       		
	       	}
	       	else if (feedObjectName == 'UserFeed') {
	       	   		List<UserFeed> aFeed = [select id, FeedPost.Body from UserFeed where parentId =: activeSObject order by createdDate desc limit 100 ];
			        SObjectFeed = new List<SelectOption>(); 
			        for(UserFeed tdi : aFeed)
			        {
				        String body = tdi.FeedPost.Body;
				        try {
					         body = body.substring(0, 40);
				        }
				        catch (Exception e)  
				        {
				        	
				        }
				        if (body != null)
				        	SObjectFeed.add(new SelectOption(tdi.id,  body));
			        }
					
					if(SObjectFeed.size() == 0)
							SObjectFeed.add(new SelectOption('', 'No Chatter Posts on this item'));       	   
	       		
	       	}
	       	
	       	else if (feedObjectName == 'OpportunityFeed') {
	       	   		List<OpportunityFeed> aFeed = [select id, FeedPost.Body from OpportunityFeed where parentId =: activeSObject order by createdDate desc limit 100 ];
			        SObjectFeed = new List<SelectOption>(); 
			        for(OpportunityFeed tdi : aFeed)
			        {
				        String body = tdi.FeedPost.Body;
				        try {
					         body = body.substring(0, 40);
				        }
				        catch (Exception e)  
				        {
				        	
				        }
				        if (body != null)
				        	SObjectFeed.add(new SelectOption(tdi.id,  body));
			        }
					
					if(SObjectFeed.size() == 0)
							SObjectFeed.add(new SelectOption('', 'No Chatter Posts on this item'));       	   
	       		
	       	}
	       	/*else if (feedObjectName == 'CaseFeed') {
	       	   		List<CaseFeed> cFeed = [select id, FeedPost.Body from CaseFeed where parentId =: activeSObject order by createdDate desc limit 100 ];
			        SObjectFeed = new List<SelectOption>(); 
			        for(CaseFeed tdi : cFeed)
			        {
				        String body = tdi.FeedPost.Body;
				        try {
					         body = body.substring(0, 40);
				        }
				        catch (Exception e)  
				        {
				        	
				        }
				        if (body != null)
				        	SObjectFeed.add(new SelectOption(tdi.id,  body));
			        }
					
					if(SObjectFeed.size() == 0)
							SObjectFeed.add(new SelectOption('', 'No Chatter Posts on this item'));       	   
	       		
	       	}*/
	       	else if (feedObjectName == 'LeadFeed') {
	       	   		List<LeadFeed> lFeed = [select id, FeedPost.Body from LeadFeed where parentId =: activeSObject order by createdDate desc limit 100 ];
			        SObjectFeed = new List<SelectOption>(); 
			        for(LeadFeed tdi : lFeed)
			        {
				        String body = tdi.FeedPost.Body;
				        try {
					         body = body.substring(0, 40);
				        }
				        catch (Exception e)  
				        {
				        	
				        }
				        if (body != null)
				        	SObjectFeed.add(new SelectOption(tdi.id,  body));
			        }
					
					if(SObjectFeed.size() == 0)
							SObjectFeed.add(new SelectOption('', 'No Chatter Posts on this item'));       	   
	       		
	       	}

	       	
	       	
 		}
 		//else 
 		//{
       	//	SObjectFeed = new List<SelectOption>();
       	//	SObjectFeed.add(new SelectOption(' ', 'This object has not yet been Chatter enabled')); 			
 		//}
        
        // We can't get FeedPost.Body  :(   so.get('FeedPost.Body'))
        
        //String queryString = 'select id, FeedPost.Body from ' + feedObjectName + ' where parentid = \'' + activeSObject + '\' limit 100 ';
        //System.debug('UpdateSObjectFeed QueryString:' + queryString);
        //List<SObject> SObjectFeedItems = Database.query(queryString);
       
        //SObjectFeed = new List<SelectOption>();
        //for(SObject so : SObjectFeedItems)
        //	SObjectFeed.add(new SelectOption( (String) so.get('id'),  (String) so.get('FeedPost.Body')));''
    }
	 
	//get SObjects by name where feed was recently modified
    public List<SelectOption> getSObjectFeed() {
    	return SObjectFeed;
    	
    }

    public void getEnabledFeeds() {
    	
    	//List<SObject> 
    	
    }
    
    
    public void mergeFeed()
    {
    	//System.debug('MERGEFEED' + activeSObjectFeedItems.size());
    	if (userVerified)
           {

               	   	String feedObjectName = feedObjectName(activeSObjectType);   
               	   	if (acceptedObject(activeSObjectType) )
               	   	{
               	   		String name = '';
               	   		String queryString = '';
               	   		try {
	               	   		queryString = 'Select id, name from ' + activeSObjectType + ' where id =\'' + activeSObject + '\'';
	               	   		List<SObject> sos = Database.query(queryString);
	               	   		name = (String) sos[0].get('name');
               	   		}
               	   		catch (Exception e) {
               	   			System.debug('Failed to get name in mergeFeed with querystring:' + queryString);
               	   		}
               	   		
               	   		
	               	   	if (feedObjectName == 'ChatterTasks__ToDoItem__Feed')
	               	   	{
				               FeedPost newPost = new FeedPost();
				               newPost.ParentID = session.id;
				               newPost.Body = '@' + activeUserHandle + ': Merging Feed from Task ' + name;
				               insert newPost;  
				               Chat_Session__Feed csf = [select id, FeedPost.FeedItemId from Chat_Session__Feed where FeedPost.id =: newPost.id limit 1];
							   String newPostFeedItemId = csf.FeedPost.FeedItemId;
							   System.debug('newPost FeedItemId:' + newPostFeedItemId + ' Id:' + NewPost.Id);
	
				               for(String tid : activeSObjectFeedItems) 
				               {
				               		try {  
					               	   		ToDoItem__Feed tdiFeed = [select id, FeedPost.Body, FeedPost.FeedItemId, createdDate from ToDoItem__Feed where id =: tid limit 1 ];
											FeedComment fcomment = new FeedComment();
									        fcomment.FeedItemId = newPostFeedItemId;
											fcomment.CommentBody = tdiFeed.FeedPost.Body;
											insert fcomment;  
					               	   		   
					               	   	}
			               	   		     catch(Exception e) {
			               	   		     	
		               						System.debug('MergeFeed: ' + e);
		               					}
			               	   	
		               			}
	               	   	}
	               	   	else if (feedObjectName == 'AccountFeed')
		               	{
					               FeedPost newPost = new FeedPost();
					               newPost.ParentID = session.id;
					              
					               newPost.Body = '@' + activeUserHandle + ': Merging Feed from Account ' + name;
					               insert newPost;  
					               Chat_Session__Feed csf = [select id, FeedPost.FeedItemId from Chat_Session__Feed where FeedPost.id =: newPost.id limit 1];
								   String newPostFeedItemId = csf.FeedPost.FeedItemId;
									System.debug('newPost FeedItemId:' + newPostFeedItemId + ' Id:' + NewPost.Id);
		
					               for(String tid : activeSObjectFeedItems) 
					               {
					               		try {  
						               	   		AccountFeed aFeed = [select id, FeedPost.Body, FeedPost.FeedItemId, createdDate from AccountFeed where id =: tid limit 1 ];
												FeedComment fcomment = new FeedComment();
										        fcomment.FeedItemId = newPostFeedItemId;
												fcomment.CommentBody = aFeed.FeedPost.Body;
												insert fcomment;  
						               	   		   
						               	   	}
				               	   		     catch(Exception e) {
				               	   		     	
			               						System.debug('MergeFeed: ' + e);
			               					}
				               	   	
			               			}
		               	   	}
		             	else if (feedObjectName == 'UserFeed')
		               	{
					               FeedPost newPost = new FeedPost();
					               newPost.ParentID = session.id;
					              
					               newPost.Body = '@' + activeUserHandle + ': Merging Feed from User ' + name;
					               insert newPost;  
					               Chat_Session__Feed csf = [select id, FeedPost.FeedItemId from Chat_Session__Feed where FeedPost.id =: newPost.id limit 1];
								   String newPostFeedItemId = csf.FeedPost.FeedItemId;
									System.debug('newPost FeedItemId:' + newPostFeedItemId + ' Id:' + NewPost.Id);
		
					               for(String tid : activeSObjectFeedItems) 
					               {
					               		try {  
						               	   		UserFeed aFeed = [select id, FeedPost.Body, FeedPost.FeedItemId, createdDate from UserFeed where id =: tid limit 1 ];
												FeedComment fcomment = new FeedComment();
										        fcomment.FeedItemId = newPostFeedItemId;
												fcomment.CommentBody = aFeed.FeedPost.Body;
												insert fcomment;  
						               	   		   
						               	   	}
				               	   		     catch(Exception e) {
				               	   		     	
			               						System.debug('MergeFeed: ' + e);
			               					}
				               	   	
			               			}
		               	   	}
		               	   	
		               	   	
	               	   	/*else if (feedObjectName == 'CaseFeed')
		               	{
					               FeedPost newPost = new FeedPost();
					               newPost.ParentID = session.id;
					               newPost.Body = '@' + activeUserHandle + ': Merging Feed from Case ' + name;
					               insert newPost;  
					               Chat_Session__Feed csf = [select id, FeedPost.FeedItemId from Chat_Session__Feed where FeedPost.id =: newPost.id limit 1];
								   String newPostFeedItemId = csf.FeedPost.FeedItemId;
									System.debug('newPost FeedItemId:' + newPostFeedItemId + ' Id:' + NewPost.Id);
		
					               for(String tid : activeSObjectFeedItems) 
					               {
					               		try {  
						               	   		CaseFeed cFeed = [select id, FeedPost.Body, FeedPost.FeedItemId, createdDate from CaseFeed where id =: tid limit 1 ];
												FeedComment fcomment = new FeedComment();
										        fcomment.FeedItemId = newPostFeedItemId;
												fcomment.CommentBody = cFeed.FeedPost.Body;
												insert fcomment;  
						               	   		   
						               	   	}
				               	   		     catch(Exception e) {
				               	   		     	
			               						System.debug('MergeFeed: ' + e);
			               					}
				               	   	
			               			}
		               	} */
	               	   	else if (feedObjectName == 'OpportunityFeed')
		               	{
					               FeedPost newPost = new FeedPost();
					               newPost.ParentID = session.id;
					               newPost.Body = '@' + activeUserHandle + ': Merging Feed from Opportunity ' + name;
					               insert newPost;  
					               Chat_Session__Feed csf = [select id, FeedPost.FeedItemId from Chat_Session__Feed where FeedPost.id =: newPost.id limit 1];
								   String newPostFeedItemId = csf.FeedPost.FeedItemId;
									System.debug('newPost FeedItemId:' + newPostFeedItemId + ' Id:' + NewPost.Id);
		
					               for(String tid : activeSObjectFeedItems) 
					               {
					               		try {  
						               	   		OpportunityFeed cFeed = [select id, FeedPost.Body, FeedPost.FeedItemId, createdDate from OpportunityFeed where id =: tid limit 1 ];
												FeedComment fcomment = new FeedComment();
										        fcomment.FeedItemId = newPostFeedItemId;
												fcomment.CommentBody = cFeed.FeedPost.Body;
												insert fcomment;  
						               	   		   
						               	   	}
				               	   		     catch(Exception e) {
				               	   		     	
			               						System.debug('MergeFeed: ' + e);
			               					}
				               	   	
			               			}
		               	}

	               	   	else if (feedObjectName == 'LeadFeed')
		               	{
					               FeedPost newPost = new FeedPost();
					               newPost.ParentID = session.id;
					               newPost.Body = '@' + activeUserHandle + ': Merging Feed from Lead ' + name;
					               insert newPost;  
					               Chat_Session__Feed csf = [select id, FeedPost.FeedItemId from Chat_Session__Feed where FeedPost.id =: newPost.id limit 1];
								   String newPostFeedItemId = csf.FeedPost.FeedItemId;
									System.debug('newPost FeedItemId:' + newPostFeedItemId + ' Id:' + NewPost.Id);
		
					               for(String tid : activeSObjectFeedItems) 
					               {
					               		try {  
						               	   		LeadFeed lFeed = [select id, FeedPost.Body, FeedPost.FeedItemId, createdDate from LeadFeed where id =: tid limit 1 ];
												FeedComment fcomment = new FeedComment();
										        fcomment.FeedItemId = newPostFeedItemId;
												fcomment.CommentBody = lFeed.FeedPost.Body;
												insert fcomment;  
						               	   		   
						               	   	}
				               	   		     catch(Exception e) {
				               	   		     	
			               						System.debug('MergeFeed: ' + e);
			               					}
				               	   	
			               			}
		               	   	}

		               //updateChatPosts();
		               notificationMessages.set(0,'Merge successful!');
               	   	}
               	   	
           
   		            /* Doesn't work. No generic SObject__Feed as of yet
               		String queryString = 'SELECT id, FeedPost.Body from ' + feedObjectName + ' where id = \'' + id + '\' limit 1';
               		System.debug('MergeFeed: ' + queryString);
               		List<SObject> sos = Database.query(queryString);
			        FeedComment fcomment = new FeedComment();
			        fcomment.FeedItemId = (Id) sos[0].get('id');
					//SObject so = (SObject) sos[0].get('FeedPost').get('Body');      
					//fcomment.CommentBody = (String) so.;  
					*/
           
           }
    	
    }
    
    class chatRoomWrapper {
    	
    	public Chat_Session__c chatRoom 	{get; set;}  
    	public Integer activeUserCount 		{get; set;}
		//public List<ChatUser__c> chatUsers 	{get; set;}
    	
    	public chatRoomWrapper(Chat_Session__c chatRoom) {
    		this.chatRoom = chatRoom;
    		
    		//DateTime d = Datetime.now(); 
    		//d.addHours(-2);	
			// not working
			//List<Chat_Session__Feed> postsInLastHour = [SELECT id, createdBy.Id from Chat_Session__Feed where parentId =: chatRoom.id and createdDate > :d limit 1000 ];
			List<Chat_Session__Feed> postsInLastHour = [SELECT id, createdDate, FeedPost.Body from Chat_Session__Feed where parentId =: chatRoom.id and FeedPost.Body != '' and createdDate = LAST_N_DAYS:1 limit 1000 ];
    	    System.debug(chatRoom.id);
    	    //System.debug(createdDate);
    		System.debug(postsInLastHour.size());
    		Set<String> uniqueUsers = New Set<String>();   
    		for(Chat_Session__Feed p : postsInLastHour)  
    		{
    			String handle = (new ChatPostWrapper(p)).userHandle;
    			if (handle != 'System')
    				uniqueUsers.add(handle);
    		}
    		activeUserCount = uniqueUsers.size();  
    			
    		//activeUserCount = [SELECT id from Chat_User__c where Chat_Session__c =: chatRoom.id limit 1000].size();

    	}
    	
    	


    }
    
        
    static Chat_Session__Feed[] reverse(Chat_Session__Feed[] anArray) {
        if (anArray == null) {
            return null;
        }
        Integer i = 0;
        Integer j = anArray.size() - 1;
        Chat_Session__Feed tmp;
        while (j > i) {
            tmp = anArray[j];
            anArray[j] = anArray[i];
            anArray[i] = tmp;
            j--;
            i++;
        }
        return anArray;
    }
    
    class ChatPostWrapper {
        
        Chat_Session__Feed post;
        public String postBody      { get; set; }
        public String userHandle    { get; set; }
        public String createdDate   { get; set; }
        public Boolean newPost		{ get; set; }
        public Boolean systemMessage	{ get; private set; }
        
        public List<FeedComment> comments { get; set; }
        
        public ChatPostWrapper(Chat_Session__Feed post)
        {  
        	newPost = true; 
            this.post = post;
            createdDate = post.createdDate.format('d MMM yy HH:mm:ss Z');  
            if(post.FeedPost.Body.length() > 1)
                if(post.FeedPost.Body.substring(0,1) == '@')
                {
                	try {
	                    String[] s = post.FeedPost.Body.split(': ',2);
	                    userHandle = s[0];
	                    postBody = s[1];  
                		if(userHandle == '@System')
                			systemMessage = true;

                	}
                	catch (Exception e)
                	{
                		System.debug('ChatPostWrapperConstructor:' + e);
                		userHandle = 'Anonymous';
                		postBody = post.FeedPost.Body;
                	}
                }
                else
                {
                    postBody = post.FeedPost.Body;
                    userHandle = 'Anonymous';
                }
            //System.debug('ChatPostWrapper comment size:' + post.FeedComments.size());
            try {
            	comments = post.FeedComments;
            }
        	catch (Exception e)
        	{
        		
        	
        	}
        }
        
        public ChatPostWrapper(Chat_Session__Feed post, List<Chat_Session__Feed> oldPosts)
        {  
        	System.debug('ChatPostWrapper Constructor checking old posts... START');
            this.post = post;
            newPost = true;  
            if(oldPosts != null)
            {
        	System.debug('Old posts is not null');

	            for(Chat_Session__Feed op : oldPosts)
	            {  
        			System.debug('ChatPostWrapper Constructor checking old posts...' + op.id);
	            	if(op.id == post.id)
	            		newPost = false;
	            }	            
	            
            }
        	System.debug('New post? ' + newPost);
            
            createdDate = post.createdDate.format('d MMM yy HH:mm:ss Z');  
            if(post.FeedPost.Body.length() > 1)
                if(post.FeedPost.Body.substring(0,1) == '@')
                {
                	try {
	                    String[] s = post.FeedPost.Body.split(': ',2);
	                    userHandle = s[0];
	                    postBody = s[1];  
	                    if(userHandle == '@System')
                			systemMessage = true;
                	}
                	catch (Exception e)
                	{
                		System.debug('ChatPostWrapperConstructor:' + e);
                		userHandle = 'Anonymous';
                		postBody = post.FeedPost.Body;
                	}
                }
                else
                {
                    postBody = post.FeedPost.Body;
                    userHandle = 'Anonymous';
                }
            System.debug('ChatPostWrapper comment size:' + post.FeedComments.size());
            comments = post.FeedComments;
        }
        
        public Boolean getHasComments()
        {
        	if(comments.size() > 0)
        		return true;
        	else
        		return false;
        		
        }
        
    }
    
    
    static testMethod void testChat() {
        
        
        Chat_Session__c testCS = new Chat_Session__c();
        testCS.name = 'Test Chat';
        testCS.requires_verification__c = true;
        testCS.Session_Id__c = '1212';
        testCS.Access_Code__c = '2121'; 
        insert testCS;
        
        User tu = TestUtility.createTestUser();
        System.runAs(tu) 
        {
                
            ChatController conn = new ChatController();
            conn.init();
            System.assertEquals(null, conn.session);
                 
            conn = new ChatController();
            ApexPages.currentPage().getParameters().put('id', testCS.session_id__c);
            conn.init();
            System.assert(conn.session.name == testCS.name);
            conn.activeUserHandle = 'fooUser';
            conn.userInputedAccessCode = '3333';
            conn.register();
            System.assertEquals(invalidAccessCodeErrorMsg, ApexPages.getMessages().get(0).getSummary());
            System.assertEquals(null, conn.chatPosts);
            
            conn = new ChatController();
              
            Test.setCurrentPage(Page.chatroom);
            ApexPages.currentPage().getParameters().put('id', testCS.session_id__c);
            conn.init();
            
           // TODO: Can't seem to reset page messages
           // System.assertEquals(0, ApexPages.getMessages().size());
            conn.activeUserHandle = 'fooUser';
            conn.userInputedAccessCode = '2121';
            conn.register();
            //System.assertEquals(' ', ApexPages.getMessages().get(1).getSummary());
            //System.assertEquals(0, ApexPages.getMessages().size());
            
            
            System.assert(conn.UserVerified);
            conn.postBody = 'testPost';
            conn.insertPost();
            System.assert(conn.getAllChatPosts().size() > 0);
        }
        
        User tu2 = TestUtility.createTestUser();

		String tu2CUId;
		
        System.runAs(tu2) 
        {
            
            ChatController conn2 = new ChatController();
            Test.setCurrentPage(Page.chatroom);
            ApexPages.currentPage().getParameters().put('id', testCS.session_id__c);
            conn2.init();   
            System.assert(conn2.session.name == testCS.name);

            conn2.activeUserHandle = 'foo';
            conn2.userInputedAccessCode = '2121';
            conn2.register();
			System.assertEquals(tooShortHandleErrorMsg, ApexPages.getMessages().get(1).getSummary());
//            System.assertEquals(tooShortHandleErrorMsg, ApexPages.getMessages().get(0).getSummary());
            System.assert(conn2.chatPosts == null);
           
			Test.setCurrentPage(Page.chatroom);
            
            
            conn2.activeUserHandle = 'fooUser';
            conn2.userInputedAccessCode = '2121';
            conn2.register();
            System.assertEquals(invalidHandleErrorMsg, ApexPages.getMessages().get(2).getSummary());
            System.assert(conn2.chatPosts == null);
    
            conn2.activeUserHandle = 'fooUser2';
            conn2.register();
            System.assert(conn2.UserVerified);
            System.assert(conn2.getAllChatPosts().size() > 0);
            System.assertNotEquals(null, conn2.activeUserId);
            tu2CUId = conn2.activeUserId;
            
              
            Account a = new Account();
            a.name = 'Bob\'s Burgers';
            insert a;
            FeedPost p = new FeedPost();
            p.parentId = a.id;
            p.Body = 'Burgers R good';
            insert p;
            AccountFeed af = [select id from AccountFeed where FeedPostId =: p.id];
            
            
            //p = [select ] FeedPostId

			Integer beforeCount = conn2.getAllChatPosts().size();
            
            conn2.getSObjectList();
            
            conn2.activeSObjectType = 'Account';  
                      
            conn2.updateSObjects();
            
            System.assertEquals(a.id,conn2.getSObjects().get(0).getValue());            
    		conn2.activeSObject = conn2.activeSObjects.get(0).getValue();
			conn2.updateSObjectFeed();
			conn2.getSObjectFeed();

			  
    		conn2.activeSObjectFeedItems = new List<String>();
    		conn2.activeSObjectFeedItems.add(af.id);
    		
    		conn2.mergeFeed();
    		conn2.updateChatPosts();

    		System.assert(conn2.chatPosts.get(0).getHasComments());
    		
			System.assertEquals(beforeCount + 1, conn2.getAllChatPosts().size());            

            Lead l = new Lead();
            //l.name = 'Bob\'s Burgers';
            l.LastNAme = 'Baker';
            l.Company = 'Burger King';
            insert l;
            p = new FeedPost();
            p.parentId = l.id;
            p.Body = 'Burgers R good';
            insert p;
            LeadFeed lf = [select id from LeadFeed where FeedPostId =: p.id];
            
            
            //p = [select ] FeedPostId

			beforeCount = conn2.getAllChatPosts().size();
            
            conn2.activeSObjectType = 'Lead';
            conn2.updateSObjects();
    		conn2.activeSObject = conn2.activeSObjects.get(0).getValue();
    		//System.assertEquals(l.id, conn2.activeSObject);
			conn2.updateSObjectFeed();
    		//System.assertEquals(l.id, SObjectFeed);
			  
    		conn2.activeSObjectFeedItems = new List<String>();
    		conn2.activeSObjectFeedItems.add(lf.id);
    		conn2.mergeFeed();
    		
			System.assertEquals(beforeCount + 1, conn2.getAllChatPosts().size());            

            p = new FeedPost();
            p.parentId = UserInfo.getUserID();  
            p.Body = 'Burgers R good';
            insert p;
            UserFeed uf = [select id from UserFeed where FeedPostId =: p.id];
            
            
            //p = [select ] FeedPostId

			beforeCount = conn2.getAllChatPosts().size();
            
            conn2.activeSObjectType = 'User';
            conn2.updateSObjects();
    		conn2.activeSObject = conn2.activeSObjects.get(0).getValue();
    		//System.assertEquals(u.id, conn2.activeSObject);
			conn2.updateSObjectFeed();
    		//System.assertEquals(u.id, SObjectFeed);
			  
    		conn2.activeSObjectFeedItems = new List<String>();
    		conn2.activeSObjectFeedItems.add(uf.id);
    		conn2.mergeFeed();
    		
			System.assertEquals(beforeCount + 1, conn2.getAllChatPosts().size());            



           Case c = new Case();
            //c.name = 'Bob\'s Burgers';
            insert c;
            p = new FeedPost();
            p.parentId = c.id;
            p.Body = 'Burgers R good';
            insert p;
            CaseFeed cf = [select id from CaseFeed where FeedPostId =: p.id];
            
            
            //p = [select ] FeedPostId

			beforeCount = conn2.getAllChatPosts().size();
            /*
            conn2.activeSObjectType = 'Case';
            conn2.updateSObjects();
    		conn2.activeSObject = conn2.activeSObjects.get(0).getValue();
    		//System.assertEquals(c.id, conn2.activeSObject);
			conn2.updateSObjectFeed();
    		//System.assertEquals(c.id, SObjectFeed);
			  
    		conn2.activeSObjectFeedItems = new List<String>();
    		conn2.activeSObjectFeedItems.add(cf.id);
    		conn2.mergeFeed();
    		
			System.assertEquals(beforeCount + 1, conn2.getAllChatPosts().size()); */           

           Opportunity o = new Opportunity();
            o.name = 'Bob\'s Burgers';
            o.StageName = 'o';
            o.CloseDate = Date.today();
            
            insert o;
            p = new FeedPost();
            p.parentId = o.id;
            p.Body = 'Burgers R good';
            insert p;
            OpportunityFeed opf = [select id from OpportunityFeed where FeedPostId =: p.id];
            
            
            //p = [select ] FeedPostId

			beforeCount = conn2.getAllChatPosts().size();
            
            conn2.activeSObjectType = 'Opportunity';
            conn2.updateSObjects();
    		conn2.activeSObject = conn2.activeSObjects.get(0).getValue();
    		//System.assertEquals(o.id, conn2.activeSObject);
			conn2.updateSObjectFeed();
    		//System.assertEquals(o.id, SObjectFeed);
			  
    		conn2.activeSObjectFeedItems = new List<String>();
    		conn2.activeSObjectFeedItems.add(opf.id);
    		conn2.mergeFeed();
    		
			System.assertEquals(beforeCount + 1, conn2.getAllChatPosts().size());            



           ToDoItem__c tdi = new ToDoItem__c();
            tdi.name = 'Bob\'s Burgers';
            tdi.assigned_to__c = tu.id;
            tdi.managed_by__c = tu.id;
            
            insert tdi;
            p = new FeedPost();
            p.parentId = tdi.id;
            p.Body = 'Burgers R good';
            insert p;
            ToDoItem__Feed tdif = [select id from ToDoItem__Feed where FeedPostId =: p.id];
            
            beforeCount = conn2.getAllChatPosts().size();
            
            conn2.activeSObjectType = 'ChatterTasks__ToDoItem__c';
            conn2.updateSObjects();
    		conn2.activeSObject = conn2.activeSObjects.get(0).getValue();
    		System.assertEquals(tdi.id, conn2.activeSObject);
			conn2.updateSObjectFeed();
			  
    		conn2.activeSObjectFeedItems = new List<String>();
    		conn2.activeSObjectFeedItems.add(tdif.id);
    		conn2.mergeFeed();
    		
    		//TODO: fix so works
			System.assertEquals(beforeCount + 1, conn2.getAllChatPosts().size());            

  

			
        }

        System.runAs(TestUtility.createTestUser())
        {
            ChatController conn3 = new ChatController();
            Test.setCurrentPage(Page.chatroom);
            ApexPages.currentPage().getParameters().put('id', testCS.session_id__c);
            conn3.init();   
            System.assert(conn3.session.name == testCS.name);
            conn3.activeUserHandle = 'fooUser3';
            conn3.userInputedAccessCode = '2121';
            conn3.register();
            System.assert(conn3.UserVerified);
			conn3.updateAll();
			
			conn3.PrivateMessage.Text__c = 'my Message';
			conn3.PrivateMessage.To__c = tu2CUId;
			
			conn3.sendPrivateMessage();
			System.assertEquals(privateMessageSuccessMsg, conn3.notificationMessages[0]);
			  
        }
        
        System.runAs(tu2)
        {
            ChatController conn4 = new ChatController();
            Test.setCurrentPage(Page.chatroom);
            ApexPages.currentPage().getParameters().put('id', testCS.session_id__c);
            conn4.init();   
            System.assert(conn4.session.name == testCS.name);
            conn4.activeUserHandle = 'fooUser3';
            conn4.userInputedAccessCode = '2121';
            conn4.register();
            System.assert(conn4.UserVerified);
			conn4.updatePrivateMessages();
            System.assertEquals(1, conn4.privateMessages.size());
            
            conn4.pmid = conn4.privateMessages.get(0).id;
            conn4.readPrivateMessage();

        
        }
        
                
    }
    
        
    
    static testMethod void testChatRoomBulk() {
        
        
        Chat_Session__c testChatRoom = new Chat_Session__c();
        testChatRoom.name = 'Test Chat';
        testChatRoom.Session_Id__c = '8779879';
        testChatRoom.persistent__c = true;

        
        User tu = TestUtility.createTestUser();
        System.runAs(tu) 
        {

            ChatController conn = new ChatController();
            conn.init();
            Integer currChatRoomCount = conn.getChatRooms().size();
            Integer ChatRoomAGCount = conn.getChatRoomsThatAllowGuests().size();
       		insert testChatRoom;
   
            System.assert(conn.session == null);
            System.assertEquals(currChatRoomCount + 1, conn.getChatRooms().size());
            System.assertEquals(ChatRoomAGCount, conn.getChatRoomsThatAllowGuests().size());
            conn.roomsInit();
            System.assertNotEquals(null, conn.activeUserHandle);
                 
            conn = new ChatController();
            ApexPages.currentPage().getParameters().put('id', testChatRoom.session_id__c);
            conn.init();
            System.assert(conn.session.name == testChatRoom.name);
            conn.activeUserHandle = 'fooUser';
            conn.register();
            System.assert(conn.UserVerified);
            
            conn = new ChatController();
            ApexPages.currentPage().getParameters().put('id', testChatRoom.session_id__c);
            conn.init();
			System.assertEquals('fooUser',conn.activeUserHandle);			
			System.assertEquals(1, conn.getAllChatPosts().size());
            
            Integer i;
            for(i = 0; i < 10; i++)
        	{
	            conn.postBody = 'testPost' + i;
	            System.debug(conn.postBody);
	            conn.insertPost(); 
	            System.debug(conn.getAllChatPosts().size());        		
        	}
            System.assertEquals(i + 1, conn.getAllChatPosts().size());
            
        }  
        ChatController bulkConn;
        for(Integer i = 0; i < 5; i++)
        {
	        User tui = TestUtility.createTestUser();
	        System.runAs(tui) 
        	{
	            bulkConn = new ChatController();
	            ApexPages.currentPage().getParameters().put('id', '');	            
	            bulkConn.init();
	            System.assertEquals(null, bulkConn.session);
	            bulkConn = new ChatController();
           		ApexPages.currentPage().getParameters().put('id', testChatRoom.session_id__c);
	            bulkConn.init();
	            bulkConn.activeUserHandle = 'fooUser' + i;
	            bulkConn.register();
	            System.assert(bulkConn.UserVerified);
	            for(Integer j = 0; j < 5; j++)
	        	{
		            bulkConn.postBody = ('testPost' + i ) + j;
		            bulkConn.insertPost();
	        	}
        	}
        }    
        System.assertEquals(41, bulkConn.getAllChatPosts().size());
        
    }
    
    
    
        

}