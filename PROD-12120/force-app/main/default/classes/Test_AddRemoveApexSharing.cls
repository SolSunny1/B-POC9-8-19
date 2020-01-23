@isTest(SeeAllData=true)
private class Test_AddRemoveApexSharing 
{
 static testMethod void apexSharing()
 {
    Test.startTest();

    Datetime dt = Datetime.now();
    Account objAcc = TestFactory.buildTestAcc(1, UserInfo.getUserId());
    insert objAcc;
    
    Opportunity  objOpp = new Opportunity (Name='Test Opp', private__c=false, AccountId=objAcc.Id,Office_Country__c='India',StageName='New', CloseDate=system.today(),RecordTypeId='01240000000MFYYAA4');
    insert objOpp;

    Opportunity  objOppNoCampaign = new Opportunity (Name='Test Opp - No Campaign', private__c=false, AccountId=objAcc.Id,Office_Country__c='India',StageName='New', CloseDate=system.today(),RecordTypeId='01240000000MFYYAA4');
    insert objOppNoCampaign;
    
     list<user> lstUser= [select id from user where  Profile.Name like :'%BFIN%' and Id !=: userinfo.getuserid() and IsActive = true limit 2];
    list<OpportunityTeamMember> lstOpportunityTeamMember  = new list<OpportunityTeamMember>();
    OpportunityTeamMember otm = new OpportunityTeamMember(TeamMemberRole = 'Account Manager', OpportunityId = objOpp.Id, UserId = lstUser[0].id );
    OpportunityTeamMember otmnc = new OpportunityTeamMember(TeamMemberRole = 'Account Manager', OpportunityId = objOppNoCampaign.Id, UserId = lstUser[0].id );
    lstOpportunityTeamMember.add(otm);
    lstOpportunityTeamMember.add(otmnc);
    
    insert lstOpportunityTeamMember;
     List<OpportunityShare> oppShareList = [SELECT id, UserOrGroupId, OpportunityAccessLevel, RowCause FROM OpportunityShare
                                               WHERE OpportunityId = : objOpp.id and RowCause =: 'Team'];
    /*
        BF-25: Share is no longer writeable due to sharing updates

        for(OpportunityShare oppShare : oppShareList) {
            oppShare.OpportunityAccessLevel = 'Edit';
        }       
        update oppShareList;
    */
       
       otm.TeamMemberRole = 'Contact Manager';
    update otm;
    list<Campaign> lstCampaign = new list<Campaign>();
    Campaign objcam = new Campaign(Name='Test Campaign',Original_Deal_Opportunity__c=objOpp.id,Status ='Active',IsActive=true,RecordTypeId='01240000000MFaUAAW');
    Campaign objcam1 = new Campaign(Name='new Campaign',Original_Deal_Opportunity__c=objOpp.id,Status ='Active',IsActive=true,RecordTypeId='01240000000MFaUAAW');
    lstCampaign.add(objcam);
 //   lstCampaign.add(objcam1);
    insert lstCampaign;
    lstOpportunityTeamMember = new list<OpportunityTeamMember>();
    OpportunityTeamMember otm1 = new OpportunityTeamMember(TeamMemberRole = 'Account Manager', OpportunityId = objOpp.Id, UserId = lstUser[0].id );
    OpportunityTeamMember otm1nc = new OpportunityTeamMember(TeamMemberRole = 'Account Manager', OpportunityId = objOppNoCampaign.Id, UserId = lstUser[0].id );
    lstOpportunityTeamMember.add(otm1);
    lstOpportunityTeamMember.add(otm1nc);
    
     Opportunity  objchildOpp = new Opportunity (Name='child Opp', Parent_Opportunity__c =objOpp.Id, AccountId=objAcc.Id,Office_Country__c='India',StageName='New', CloseDate=system.today());
    insert objchildOpp;
    insert lstOpportunityTeamMember;
    oppShareList = new List<OpportunityShare>();
    oppShareList  = [select id from OpportunityShare  WHERE OpportunityId = : objOpp.id and RowCause =: 'Team' and UserOrGroupId =:lstUser[0].id];

    
    /*
        BF-25: Share is no longer writeable due to sharing updates

        for(OpportunityShare oppShare : oppShareList ) {
            oppShare.OpportunityAccessLevel = 'Read';
        }       
        update oppShareList;
    */

    Test.stopTest();
       //otm.TeamMemberRole = 'Contact Manager';
       //update otm;
       try
       {
       delete lstOpportunityTeamMember;
       }catch(exception ex)
       {
        system.debug(ex);
       }
      // oppShareList = new List<OpportunityShare>();
     // oppShareList  = [select id from OpportunityShare  WHERE OpportunityId = : objOpp.id and RowCause =: 'Team' and UserOrGroupId =:lstUser[0].id];
     // for(OpportunityShare oppShare : oppShareList )
      // {
       //   oppShare.OpportunityAccessLevel = 'Read';
      // }       
      // update oppShareList;
      // delete otm1;
 }


}