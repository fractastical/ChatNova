// Jonathan Hersh - jhersh@salesforce.com - 3/10/2010
public class chatterMessageHelper {
    public integer mode                                 { get; set; }

    public static integer VIEWMESSAGE                   { get { return 1; } }
    public static integer NEWMESSAGE                    { get { return 2; } }
    public static integer MESSAGESENT                   { get { return 3; } }
    
    public chatterMessages.message message              { get; set; }
    public chatterMessages.message[] replies            { get; set; }
    
    public Chatter_Message__c newmsg                    { get; set; }
    public Chatter_Message_Recipient__c[] newrecipients { get; set; }
    
    public string toDel                                 { get; set; }
    public Map<string,id> recipientMap                  { get; set; }
    
    
    public chatterMessageHelper() {
        resetMessage();
        
        loadMsg('');
    }
    
    public pageReference loadMsg( string msgID ) {        
        if( msgID == '' )
            msgID = ApexPages.currentpage().getparameters().get('msgID');
            
        string isNew = ApexPages.currentpage().getparameters().get('newMsg');
        
        if( msgID != null && msgID != '' ) {
            mode = VIEWMESSAGE;
            replies = new chatterMessages.message[] {};
            
            // Load this message and all of its replies
            
            // Is this message a reply? load its parent instead
            Chatter_Message__c[] mess = [select id, parent__c 
                from Chatter_Message__c
                where id = :msgID];
                
            if( !mess.isEmpty() && mess[0].parent__c != null )
                msgID = mess[0].parent__c;
                
            Chatter_Message__c[] messages = [select id, createdbyid, createdby.name, subject__c, message__c, createddate, ownerid, owner.name,
                        (select id, recipient__c, unread__c, createddate, recipient__r.name, recipient__r.firstname, chatter_message__c, chatter_message__r.ownerid
                        from Chatter_Message_Recipients__r
                        order by createddate asc)
                    from Chatter_Message__c
                    where id = :msgID or parent__c = :msgID
                    order by createddate asc];
                    
            for( Chatter_Message__c m : messages )
                if( m.id == msgID )
                    message = new chatterMessages.message( m, m.chatter_message_recipients__r );
                else
                    replies.add( new chatterMessages.message( m ) );
                    
            // Something is messed up
            if( message == null )
                return null;
            
            // Prepare for a reply
            newmsg.parent__c = message.cm.id;
            newmsg.subject__c = 'Re: '+ message.cm.subject__c;
            
            // Reply to all            
            for( Chatter_Message_Recipient__c cmr : message.cmr )
                if( cmr.recipient__c != UserInfo.getUserId() )
                    recipientMap.put( cmr.recipient__r.name, cmr.recipient__c );
                
            // Don't forget the original sender
            if( message.cm.ownerid != UserInfo.getUserId() )
                recipientMap.put( message.cm.owner.name, message.cm.ownerid );
            
            system.debug('NEW MSG '+ newmsg);
        } else if( isNew == '1' )
            mode = NEWMESSAGE;
            
        return null;
    }
    
    public pageReference resetMessage() {
        newmsg = new Chatter_Message__c();   
        newrecipients = new Chatter_Message_Recipient__c[] {};      
        recipientMap = new Map<string,id> ();
        
        return null;
    }
    
    public pageReference addRecipient() {
        if( newmsg.ownerid == null )
            return null;
            
        if( newmsg.ownerid == UserInfo.getUserId() ) {
            newmsg.ownerid = null;
            return null;
        }
            
        string name = [select id, name from User where id=:newmsg.ownerid].name;
        
        recipientMap.put( name, newmsg.ownerid );
        toDel = name;
        
        newmsg.ownerid = null;
        
        return null;
    }
    
    public pageReference removeRecipient() {
        recipientMap.remove( toDel );       
        
        return null;
    }
    
    public SelectOption[] getRecipients() {
        SelectOption[] so = new SelectOption[] {};
        
        string[] names = new List<string> ();
        names.addAll(recipientMap.keySet());
            
        names.sort();
        
        for( string name : names )
            so.add( new SelectOption( name, name ) );
            
        return so;  
    }
    
    public pageReference sendMessage() {        
        if( recipientMap.isEmpty() ) {
            newmsg.ownerid.addError('Please add at least one recipient.');
            return null;            
        }
        
        if( newmsg.subject__c == null || newmsg.subject__c.trim() == '' ) {
            newmsg.subject__c.addError('Please enter a subject.');
            return null;
        }
        
        if( newmsg.message__c == null || newmsg.message__c.trim().length() < 2 ) {
            newmsg.message__c.addError('Please enter a message.');
            return null;
        }
        
        newmsg.message__c = newmsg.message__c.trim();
        newmsg.ownerid = UserInfo.getUserId();

        upsert newmsg;
        
        for( ID recipient : recipientMap.values() ) {
            Chatter_Message_Recipient__c cmr = new Chatter_Message_Recipient__c();
            cmr.recipient__c = recipient;
            cmr.chatter_message__c = newmsg.id;
            
            // Coming from us? Mark it as read
            cmr.Unread__c = cmr.recipient__c != UserInfo.getUserId();
            
            newrecipients.add( cmr );
        }
        
        upsert newrecipients;
        
        mode = MESSAGESENT;
        
        return null;
    }
    
    public static testmethod void runTest() {
        chatterMessageHelper cmh = new chatterMessageHelper();
        
        Chatter_Message__c cm = new Chatter_Message__c();
        cm.ownerid = userinfo.getuserid();
        cm.subject__c = 'test';
        cm.message__c = 'test';
        
        insert cm;
        
        cmh.loadMsg( cm.id );
        
        Profile p = [select id from profile where name='Standard User']; 
        User u = new User(alias = 'standt', email='standarduser@kwutang.demo', 
                        emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US', 
                        localesidkey='en_US', profileid = p.Id, 
                        timezonesidkey='America/Los_Angeles', username='standarduser@kwutang.demo');        
        
        insert u;
        
        cmh.newmsg.ownerid = u.id;
        cmh.newmsg.message__c = 'hello there!';
        cmh.addRecipient();
        cmh.getRecipients();
        cmh.sendMessage();
        
        delete cm;
    }
}