public with sharing class userUpdateCon {
	
public string status {get; set;}

public PageReference doUserStatus() {
	User user = [SELECT id, CurrentStatus from USer where id = :UserInfo.getUserId()];
	user.CurrentStatus = status;
	update user;
	return null;     
	}    

}