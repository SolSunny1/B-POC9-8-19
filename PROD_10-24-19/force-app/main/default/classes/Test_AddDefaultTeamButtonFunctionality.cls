@isTest(SeeAllData=true)
private class Test_AddDefaultTeamButtonFunctionality
{
 static testMethod void AddDefaultTeam()
 {
   
   
   Account objAcc = TestFactory.buildTestAcc(1, UserInfo.getUserId());
    insert objAcc;
    
    Opportunity  objOpp = new Opportunity (Name='Test Opp', private__c=false, AccountId=objAcc.Id,Office_Country__c='India',StageName='New', CloseDate=system.today());
    insert objOpp;
    user objUser = [select id from user where id!=:userInfo.getuserid() limit 1];
    AddDefaultTeamButtonFunctionality.addDefaultTeam(null, objUser.Id );
    
    AddDefaultTeamButtonFunctionality.addDefaultTeam(objOpp.Id, userInfo.getuserid());
  
 }


}