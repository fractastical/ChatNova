// Jonathan Hersh - jhersh@salesforce.com - 3/10/2010

// I am using owner, not createdby, to determine who SENT a Chatter Message
// This is so that you can use apex to create and send messages from arbitrary users,
// without having to worry about who the running user is or who created the record.

// To send a new message:
// 1. Insert a new chatter_message__c. ownerid, not createdbyid, is used to determine who sent it.
// 2. Insert new chatter_message_recipient__c records, one for each recipient, and relate them to the message. 
// PLEASE do not insert one for the sender.

public class chatterMessages {
    public message[] inbox      { get; set; }
    public message[] sent       { get; set; }
    
    public integer unreadCount  { get; set; }
    
    public string whichBox      { get; set; }
    public string whichMark     { get; set; }
    
    public string markRead      { get; set; }
    
    public static integer ROWS_PER_PAGE { get { return 20; } }
    public integer inboxfirst   { get; set; }
    public integer sentfirst    { get; set; }
    
    public chatterMessages() {
        inboxfirst = 0;
        sentfirst = 0;
        
        refreshInbox();
    }
    
    public pageReference refreshInbox() {
        unreadCount = 0;
        
        inbox = new message[] {};
        sent = new message[] {};
        
        // Show all top-level (i.e. not threaded replies) received messages            
        Map<ID,Chatter_Message_Recipient__c[]> cmrMap = new Map<ID,Chatter_Message_Recipient__c[]> ();
        
        for( Chatter_Message_Recipient__c cmr : [select id, recipient__c, unread__c, createddate, recipient__r.name, recipient__r.firstname, chatter_message__c, chatter_message__r.ownerid
            from Chatter_Message_Recipient__c
            where recipient__c = :UserInfo.getUserId() and chatter_message__r.parent__c = null]) {
                if( !cmrMap.containsKey( cmr.chatter_message__c ) )
                    cmrMap.put( cmr.chatter_message__c, new Chatter_Message_Recipient__c[] {} );
                    
                cmrMap.get( cmr.chatter_message__c ).add( cmr );
                
                if( cmr.unread__c )
                    unreadCount++;
            }
            
        Chatter_Message__c[] myinbox = [select id, ownerid, owner.name, subject__c, message__c, createddate,
                (select id, unread__c, recipient__c, createddate, recipient__r.name, recipient__r.firstname, chatter_message__c, chatter_message__r.ownerid
                from Chatter_Message_Recipients__r
                order by createddate desc)
            from Chatter_Message__c
            where id IN :cmrMap.keySet()
            order by createddate desc];
            
        for( Chatter_Message__c cm : myinbox ) 
            inbox.add( new message( cm, cm.chatter_message_recipients__r ) );
        
        // Show all sent messages
        Chatter_Message__c[] mysent = [select id, subject__c, message__c, createddate,
            (select id, unread__c, recipient__c, createddate, recipient__r.name, recipient__r.firstname, chatter_message__c, chatter_message__r.ownerid
                from Chatter_Message_Recipients__r
                order by createddate desc)
            from Chatter_Message__c
            where ownerid = :UserInfo.getUserId()
            order by createddate desc];
            
        for( Chatter_Message__c cm : mysent )
            if( cm.message__c != null )      
                sent.add( new message( cm ) );
            
        return null;
    }
    
    // Mark the selected messages, and all of their replies, as read or unread
    public pageReference setViewStatus() {
        Chatter_Message_Recipient__c[] toUpdate = new Chatter_Message_Recipient__c[] {};
        
        if( whichbox == null || whichbox == '' || whichmark == null || whichmark == '' )
            return null;
            
        message[] box = whichbox == 'inbox' ? inbox : sent;
        
        for( message m : box )
            if( m.selected || m.cm.id == markRead )
                toUpdate.addAll( m.cmr );
                
        for( Chatter_Message_Recipient__c cmr : toUpdate )
            cmr.unread__c = whichmark == 'unread'; 
        
        update toUpdate;
        
        refreshInbox();
        
        return null;
    }
    
    // Given a list of chatter message recipient sobjects, this returns a clickable
    // list of names
    public static string nameList( Chatter_Message_Recipient__c[] cmr, boolean includeYou ) {
        string ret = '';
        integer rsize = cmr.size();
        
        for( integer x = 0; x < cmr.size(); x++ ) {     
            if( x > 0 && cmr.size() > 2 && x < cmr.size() - 1 )
                ret += ', ';
            else if( cmr.size() > 1 && x == cmr.size() - 1 )
                ret += ' and ';
            
            if( includeYou && cmr[x].recipient__c == UserInfo.getUserId() ) {
                ret += 'you';
                continue;
            }

            ret += '<a href=\"/'+ cmr[x].recipient__c +'\" target=\"top\" class=\"nameLink\" style=\"color: rgb(1, 91, 167);\" title=\"'+ cmr[x].recipient__r.name +'\">';
            ret += cmr[x].recipient__r.name;
            ret += '</a>';
        }
            
        return ret;
    }
    
    public static string relativeTime( Datetime dt ) {
            long diff =  ( Datetime.now().getTime() - dt.getTime() ) / 1000;
            string unit;
            
            if( diff < 60 )
                unit = 'second';
            else if( diff < 60 * 60 ) {
                diff /= 60;
                unit = 'minute';
            } else if( diff < 60 * 60 * 24 ) {
                diff = diff / 60 / 60;
                unit = 'hour';
            } else {
                diff = diff / 60 / 60 / 24;
                unit = 'day';
            }
            
            if( diff > 1 )
                unit += 's';
                
            return diff + ' ' + unit + ' ago';
    }
    
    public pageReference nextMails() {
        integer first = whichBox == 'inbox' ? inboxfirst : sentfirst;
        integer msize = whichBox == 'inbox' ? inbox.size() : sent.size();
        
        if( first + ROWS_PER_PAGE > msize )
            return null;
        
        if( whichBox == 'inbox' )
            inboxfirst += ROWS_PER_PAGE;
        else
            sentfirst += ROWS_PER_PAGE;
        
        return null;
    }
    
    public string getNextLink() {
        integer first = whichBox == 'inbox' ? inboxfirst : sentfirst;
        integer msize = whichBox == 'inbox' ? inbox.size() : sent.size();
        
        integer remaining = msize - ( first + ROWS_PER_PAGE );
       
        return ( remaining > ROWS_PER_PAGE ? 'Next '+ ROWS_PER_PAGE : 'Last '+ remaining );
    }
    
    public pageReference prevMails() {
        if( whichBox == 'inbox' ) {
            inboxfirst -= ROWS_PER_PAGE;
            
            if( inboxfirst < 0 )
                inboxfirst = 0;
        } else {
            sentfirst -= ROWS_PER_PAGE;
            
            if( sentfirst < 0 )
                sentfirst = 0;
        }
            
        return null;            
    }
    
    public string getPrevLink() {
        integer first = whichBox == 'inbox' ? inboxfirst : sentfirst;
        
        integer remaining = first - ROWS_PER_PAGE;
        
        if( remaining == 0 )
            remaining = - ROWS_PER_PAGE;
        
        return ( remaining > 0 ? 'Prev '+ ROWS_PER_PAGE : 'First '+ -remaining );
    }

    public class message {
        public Chatter_Message__c cm    { get; set; }
        public Chatter_Message_Recipient__c[]   cmr { get; set; }
        public boolean unread           { get; set; }
        
        public string msgPreview        { get; set; }
        public string relTime           { get; set; }
        
        public string nameList          { get; set; }
        
        public boolean selected         { get; set; }
        
        public message( Chatter_Message__c m ) {
            cm = m;
            cmr = m.Chatter_Message_Recipients__r;
            
            unread = cmr.isEmpty() ? false : cmr[0].unread__c;
            selected = false;
            
            nameList = nameList( cmr, false );
            
            relTime = relativeTime( m.createddate );
            
            if( cm.message__c == null || cm.message__c.trim() == '' )
                msgPreview = '';
            else {
                // No HTML in the message preview
                msgPreview = cm.message__c.replaceAll('\\<.*?\\>', '').replace('  ', ' ').trim();
                
                if( msgPreview.length() > 140 )
                    msgPreview = msgPreview.substring( 0, 140 ) + '...';
            }
        }
        
        public message( Chatter_Message__c m, Chatter_Message_Recipient__c[] mr ) {
            cm = m;
            cmr = mr;
            
            unread = cmr.isEmpty() ? false : cmr[0].unread__c;
            selected = false;
            
            nameList = nameList( cmr, true );
            
            // No HTML in the message preview
            msgPreview = cm.message__c.replaceAll('\\<.*?\\>', '').replace('  ', ' ').trim();
            
            if( msgPreview.length() > 140 )
                msgPreview = msgPreview.substring( 0, 140 ) + '...';
            
            relTime = relativeTime( m.createddate );
        }
    }
    
    public static testmethod void runTest() {
        Chatter_message__c cmm = new chatter_message__c();
        cmm.ownerid = UserInfo.getUserId();
        cmm.subject__c = 'subject';
        cmm.message__c = 'msg';
        
        insert cmm;
        
        chatterMessages cm = new chatterMessages();
        cm.nextMails();
        cm.getNextLink();
        cm.prevMails();
        cm.getPrevLink();       
        relativeTime( Datetime.now().addHours(-1));
    }
}