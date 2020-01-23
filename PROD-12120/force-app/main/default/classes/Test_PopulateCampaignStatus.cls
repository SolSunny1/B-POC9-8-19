@isTest(SeeAllData=true)
private class Test_PopulateCampaignStatus{
  static testMethod void CreateCampaign(){     

    // Set up the Account record.    

    Account objAcc = TestFactory.buildTestAcc(1, UserInfo.getUserId());
    insert objAcc;
    system.debug('----+Test objAcc ****' + objAcc);
    Opportunity  objOpp = new Opportunity (Name='Test Opp', private__c=false, AccountId=objAcc.Id,Office_Country__c='India',StageName='New', CloseDate=system.today());
    //SS: 9/9/19 inserted IV record as it is become required by NewOpportunityName class.(next 3 lines including sytem debug.)
    Investment_Vehicle__c iv = TestFactory.buildInvestmentVehicle('test');
    insert iv;
     system.debug('----+Test IV record %%%%%' + iv);
    objOpp.Investment_Vehicle__c = iv.id;
    system.debug('----+Test Opportunity ****' + objOpp);
    insert objOpp;
    
    list<user> lstUser= [select id from user where  Profile.Name like :'%BFIN%' and Id !=: userinfo.getuserid() and IsActive = true limit 2];
    
    list<OpportunityTeamMember> lstOpportunityTeamMember  = new list<OpportunityTeamMember>();
    
    OpportunityTeamMember otm = new OpportunityTeamMember(TeamMemberRole = 'Account Manager', OpportunityId = objOpp.Id, UserId = lstUser[0].id );
    lstOpportunityTeamMember.add(otm);
    OpportunityTeamMember otm1 = new OpportunityTeamMember(TeamMemberRole = 'Account Manager', OpportunityId = objOpp.Id, UserId = lstUser[1].id );
    lstOpportunityTeamMember.add(otm1);
    insert lstOpportunityTeamMember;
    //SS: 9/9/19 added debugline
    system.debug('----+Test lstOpportunityTeamMember *-*-*-*' + lstOpportunityTeamMember);
 
      /* BF-25: Share is no longer writeable due to sharing updates

      List<OpportunityShare> oppShareList = [SELECT id, UserOrGroupId, OpportunityAccessLevel, RowCause FROM OpportunityShare
                                              WHERE OpportunityId = : objOpp.id and RowCause =: 'Team'];
      for(OpportunityShare oppShare : oppShareList)
      {
          oppShare.OpportunityAccessLevel = 'Edit';
      }
      
      update oppShareList;
      system.debug('----+Test oppShareList---' + oppShareList); 
     */  
    list<Campaign> lstCampaign = new list<Campaign>();
    
    Campaign objcam = new Campaign(Name='Test Campaign',Original_Deal_Opportunity__c=objOpp.id,Status ='Active',IsActive=true);
    //--SS: 9/9/19 comented out due to isolate "cannot specify ID on insert exception  
    //Campaign objcam1 = new Campaign(Name='new Campaign',Original_Deal_Opportunity__c=objOpp.id,Status ='Active',IsActive=true);
    system.debug('----+Test Campaign1---' + objcam);
    
    lstCampaign.add(objcam);
   //-- SS: 9/9/19 comented out due to isolate "cannot specify ID on insert exception
   //lstCampaign.add(objcam1);
    insert lstCampaign;
    lstCampaign = new list<Campaign>();
    objcam.name = 'Campaign';
   //-- SS: 9/9/19 comented out due to isolate "cannot specify ID on insert exception
   //objcam1.name = 'campaign test';
    lstCampaign.add(objcam);
   //-- SS: 9/9/19 comented out due to isolate "cannot specify ID on insert exception
   //lstCampaign.add(objcam1);
    update lstCampaign;
    objOpp.private__c = true;
    update objOpp;    
   
  }
}