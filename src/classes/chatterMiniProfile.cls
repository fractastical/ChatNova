// Jonathan Hersh - jhersh@salesforce.com - 3/1/2010
public with sharing class chatterMiniProfile {
	public integer followers	{ get; set; }
	public integer following	{ get; set; }
	public integer updates		{ get; set; }
	
	public chatterMiniProfile() {
		AggregateResult[] followersAR = [select count(id)
			from EntitySubscription
			where parentid = :UserInfo.getUserId()];
			
		AggregateResult[] followingAR = [select count(id)
			from EntitySubscription
			where subscriberid = :UserInfo.getUserId()];
			
		AggregateResult[] updatesAR = [select count(id)
			from UserFeed
			where createdbyid = :UserInfo.getUserId()];
			
		followers = integer.valueof(followersAR[0].get('expr0'));
		following = integer.valueof(followingAR[0].get('expr0'));	
		updates = integer.valueof(updatesAR[0].get('expr0'));	
	}
	
	public static testmethod void runTest() {
		chatterMiniProfile cmp = new chatterMiniProfile();
	}
}