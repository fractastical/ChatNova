// Jonathan Hersh - jhersh@salesforce.com - 2/26/2010
public with sharing class chatterNotifications {
	public notification[] notes	{ get; set; }
	
	public boolean showTable	{ get; set; }
	
	public chatterNotifications() {
		showTable = ApexPages.currentpage().getparameters().get('t') == '1' ? true : false;
		
		doRefresh();
	}
	
	public pageReference doRefresh() {
		string uID = UserInfo.getUserId();
		string ptype;
		
		notes = new notification[] {};
		
		UserFeed[] ufs = [select createdbyid, createddate, createdby.name, type,
				(select createddate, createdbyid, parentid, createdby.name
					from FeedComments 
					where createdbyid <> :uID
					order by createddate desc limit 30)
			from UserFeed
			where parentid = :uID or createdbyid = :uID
			order by createddate desc limit 200];
		
		for( UserFeed uf : ufs ) {
			if( uf.type == 'LinkPost' )
				ptype = 'link';
			else if( uf.type == 'TextPost' )
				ptype = 'note';
			else if( uf.type == 'ContentPost' )
				ptype = 'file';
			else
				//ptype = 'unknown thing';
				continue;
			
			// We don't show our own wall posts...
			if( uf.createdbyid != uId )
				notes.add( new notification( (''+uf.createdbyid), uf.createdby.name, ' posted a '+ ptype +' on your <a href="/' + uID +'" target="_top">profile</a>.', uf.createddate ) );
			
			// ...but we do show comments from other people about them
			for( FeedComment fc : uf.feedcomments )
				notes.add( new notification( (''+fc.createdbyid), fc.createdby.name, 
					( uf.createdbyid == uID ? ' commented on your <a href="/'+ fc.parentid +'" target="_top">post</a>.' : ' commented on a post on your <a href="/'+ fc.parentid +'" target="_top">profile</a>.' ),
				fc.createddate ) );
		}
			
		// This will error if you haven't deployed the chatter messages objects, so we'll try to detect
		// ahead of time if it's been deployed
		// All messages and replies sent to us		
		if( Schema.SObjectType.Chatter_Message_Recipient__c.fields.chatter_message__c.isAccessible() ) {
			Chatter_Message_Recipient__c[] recips = [select chatter_message__c, chatter_message__r.ownerid, chatter_message__r.owner.name,
				chatter_message__r.parent__c, chatter_message__r.parent__r.ownerid, createddate, chatter_message__r.subject__c
				from Chatter_Message_Recipient__c
				where recipient__c = :UserInfo.getUserId()
				and chatter_message__r.ownerid <> :UserInfo.getUserId()
				order by createddate desc limit 200];
				
			for( Chatter_Message_Recipient__c cmr : recips ) {			
				if( cmr.chatter_message__r.parent__c != null && cmr.chatter_message__r.parent__r.ownerid == UserInfo.getUserId() )
					notes.add( new notification( ''+ cmr.chatter_message__r.ownerid, cmr.chatter_message__r.owner.name,
						' replied to your ',
						cmr.createddate, cmr.chatter_message__c, 'message', cmr.chatter_message__r.subject__c, '/apex/chatterMessages' ) );
				else if( cmr.chatter_message__r.parent__c != null )
					notes.add( new notification( ''+ cmr.chatter_message__r.ownerid, cmr.chatter_message__r.owner.name,
						' replied to a ',
						cmr.createddate, cmr.chatter_message__c, 'message', cmr.chatter_message__r.subject__c, '/apex/chatterMessages' ) );
				else
					notes.add( new notification( ''+ cmr.chatter_message__r.ownerid, cmr.chatter_message__r.owner.name,
						' sent you a ',
						cmr.createddate, cmr.chatter_message__c, 'message', cmr.chatter_message__r.subject__c, '/apex/chatterMessages' ) );
				
			}
		}
	
		// Sort in descending chronological order
		sortNotes( notes );
		
		return null;
	}
	
	public class notification {
		public string uid		{ get; set; }
		public string uname		{ get; set; }
		public string msg		{ get; set; }
		public string timestr	{ get; set; }
		
		public long timestamp	{ get; set; }
		
		// If specified, clicking a link will pop this URL open in an iFrame, with popTxt as the link text and popTitle as window title
		public string popURL	{ get; set; }
		public string popTxt	{ get; set; }
		public string popTitle	{ get; set; }
		public string popAltURL { get; set; }
		
		public notification( string uid2, string uname2, string msg2, Datetime dt ) {
			uid = uid2;
			uname = uname2;
			msg = msg2;
			timestr = relativeTime( dt );
			timestamp = dt.getTime() / 1000;
		}
		
		public notification( string uid2, string uname2, string msg2, Datetime dt, string popURL2, string poptxt2, string popTitle2, string popalturl2 ) {
			uid = uid2;
			uname = uname2;
			msg = msg2;
			timestr = relativeTime( dt );
			timestamp = dt.getTime() / 1000;
			popURL = popURL2;
			popTxt = poptxt2;
			poptitle = poptitle2;
			popalturl = popalturl2;
		}
		
		public string relativeTime( Datetime dt ) {
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
	}
	
	public static void sortNotes(List<notification> items){
        List<notification> resultList = new List<notification>();
            
        //Create a map that can be used for sorting 
        Map<long, List<notification>> noteMap = new Map<long, List<notification>>();
            
            for(notification ob : items){
                    if(noteMap.get(ob.timestamp) == null)
                        noteMap.put(ob.timestamp, new List<notification>()); 

                    noteMap.get(ob.timestamp).add(ob);
            }
        
            //Sort the keys
        
            List<long> keys = new List<long>(noteMap.keySet());
            keys.sort();       
            
            for(long key : keys)
            	resultList.addAll(noteMap.get(key));      
        
        //Apply the sorted values to the source list. descending order
        items.clear();
        
        for(integer i = resultList.size()-1; i >= 0; i--)
        	items.add(resultList[i]);   
    }
    
    public static testmethod void runTest() {
    	chatterNotifications cn = new chatterNotifications();
    }
}