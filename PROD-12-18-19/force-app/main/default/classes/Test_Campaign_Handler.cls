@isTest
private  class Test_Campaign_Handler {
  
  @testSetup
  static void setupTestData(){
      Contact testContact = new Contact(FirstName='Test', LastName='TestlastName',Email='test@test.com',DX_Email__c ='test@test21.com');
        insert testContact;    
      
      Investment_Vehicle__c testInvestmentVehicle = new Investment_Vehicle__c(Vehicle_Type__c = 'Co-Invest');
      insert testInvestmentVehicle;
      Account accobj = new Account(Name ='TestAccount' );
      insert accobj;
      Investment_Vehicle__c testInvestmentVehicleobj = [select id from Investment_Vehicle__c limit 1];
      Fund_Vehicle__c Sleeveobj = new Fund_Vehicle__c(Name='Test',Investment_Vehicle__c=testInvestmentVehicleobj.id);
      insert Sleeveobj;
     
  }
    
  	static testMethod void test_CreateFundraisingCampaignEvents(){
      Contact contact_Obj =[Select id from Contact limit 1];    
      Account acc = [select name from Account limit 1];
      RecordType rt = [select Id from RecordType where SobjectType='Campaign' and DeveloperName like '%Brookfield_Diligence_Portal%' limit 1];
      List<Campaign> campaign_Objlst = new List<Campaign>();   
      Fund_Vehicle__c objSleeve =  [select name from Fund_Vehicle__c limit 1];
      campaign_Objlst.add(new Campaign(Name = 'Test',Status='Deactivated',Room_Type__c ='Fund',RecordTypeId=rt.Id,Account__c = acc.Id)); 
      campaign_Objlst.add(new Campaign(Name = 'Test1',Status='Planned',Room_Type__c ='Prospect Specific',RecordTypeId=rt.Id,Account__c = acc.Id));     
      List<CampaignMember> campaignmember_Obj = new List<CampaignMember>();
      test.startTest();       
      insert campaign_Objlst;       
      List<Campaign> campaign_Obj1  =  [SELECT Name,RecordTypeId,Status,Room_Type__c from Campaign ];            
      System.assertEquals(true,campaign_Obj1.size()>0);
        for(Campaign c:campaign_Obj1)
        {
            campaignmember_Obj.add(new CampaignMember(CampaignId = c.id,ContactId =contact_Obj.id));
            c.Status = 'Active';
        }      	
      Insert campaignmember_Obj;       
      update campaign_Obj1;	
      test.stopTest();
    
  }
    //Test case to check functionality for duplicate entry for same Fund
    static testMethod void test_checkDuplicateCampaignForFund(){
        Investment_Vehicle__c testInvestmentVehicleobj = [select id from Investment_Vehicle__c limit 1];
        Account acc = [select name from Account limit 1];
        RecordType rt = [select Id from RecordType where SobjectType='Campaign' and DeveloperName like '%Brookfield_Diligence_Portal%' limit 1];
        Campaign campaign_Obj1 = new Campaign(Name = 'Test',Status='Active',Room_Type__c ='Fund',RecordTypeId=rt.Id,Account__c = acc.Id, Investment_Vehicle__c=testInvestmentVehicleobj.Id);
        insert campaign_Obj1;
        test.startTest();        
      	Campaign campaign_ObjDuplicate = new Campaign(Name = 'Test',Status='Active',Room_Type__c ='Fund',RecordTypeId=rt.Id,Account__c = acc.Id, Investment_Vehicle__c=testInvestmentVehicleobj.Id);
        try {
        insert campaign_ObjDuplicate;
        }
        catch(Exception duplicate){
            System.assert(duplicate.getMessage().contains('Duplicate Error:Campaign with Investment Vehilcle alredy exist'), duplicate.getMessage());        
        }         
        test.stopTest();
    }
    static testMethod void test_DeleteFundraisingCampaignEvents(){
      Contact contact_Obj =[Select id from Contact limit 1];    
      Account acc = [select name from Account limit 1];
      RecordType rt = [select Id from RecordType where SobjectType='Campaign' and DeveloperName like '%Brookfield_Diligence_Portal%' limit 1];
      List<Campaign> campaign_Objlst = new List<Campaign>();   
      Fund_Vehicle__c objSleeve =  [select name from Fund_Vehicle__c limit 1];
      campaign_Objlst.add(new Campaign(Name = 'Test',Status='Active',Room_Type__c ='Fund',RecordTypeId=rt.Id,Account__c = acc.Id)); 
      campaign_Objlst.add(new Campaign(Name = 'Test1',Status='Active',Room_Type__c ='Prospect Specific',RecordTypeId=rt.Id,Account__c = acc.Id));     
      List<CampaignMember> campaignmember_Obj = new List<CampaignMember>();
      test.startTest();       
      insert campaign_Objlst;       
      List<Campaign> campaign_Obj1  =  [SELECT Name,RecordTypeId,Status,Room_Type__c from Campaign limit 1]; 
        List<Campaign> cmLst = new List<Campaign>();
      System.assertEquals(true,campaign_Obj1.size()>0);
        for(Campaign c:campaign_Obj1)
        {
            campaignmember_Obj.add(new CampaignMember(CampaignId = c.id,ContactId =contact_Obj.id));
            //c.Status = 'Active';
            cmLst.add(c);
        }     
        
        update cmLst;
      Insert campaignmember_Obj;
       delete campaignmember_Obj;      
      test.stopTest();
    
  }
}