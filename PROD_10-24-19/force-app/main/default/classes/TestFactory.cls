/*****************************************************************************************************************
ss: 6/11/19 Modified to update the account method to accomodate the City and Country exception/validation. (Appended line # 26)

*****************************************************************************************************************/
@isTest public class TestFactory {

    public static User buildTestUser(Integer i, String profilename) {
   
    User u = new User();
    u.Alias = 'TESTABS';
    u.Email='ABS@Brownfield.com';
    u.EmailEncodingKey='UTF-8';
    u.LastName='TestABS' + i;
    u.LanguageLocaleKey='en_US';
    u.LocaleSidKey='en_US';
    u.ProfileId = [SELECT Id FROM profile where name =:profilename].id; 
    u.TimeZoneSidKey='America/Los_Angeles';
    u.UserName='ABS@Brownfield.com' + i;
    return u;
    }

    public static Account buildTestAcc(Integer i, Id testUserId) {  
        Account TestAccount = new Account();
        TestAccount.Name = 'Test ' + Math.round(Math.random()*1000) + ' Account ' + Math.round(Math.random()*1000);
        TestAccount.BillingCity = Math.round(Math.random()*1000) + ' city ' + Math.round(Math.random()*1000);
        TestAccount.BillingCountry = 'United States'; 
        TestAccount.Company_Background__c = 'Initial Company background';
        TestAccount.Investor_Type__c = 'Consultant';
        TestAccount.QI_Status_Notes__c = 'Initial QI Status Note'; 
        TestAccount.ERISA__c = 'No'; 
        TestAccount.RecordTypeId = '0120b000000B0QU';
        if(null != testUserId) {
            Id userId = [SELECT Id FROM User where Id =:testUserId].id;
            TestAccount.PFG_CRM_Primary_lead__c = userId;
            TestAccount.BIM_Primary_Mktg_Rep__c = userId;
        }
    
        return TestAccount;
    }
    
    public static Contact buildTestCon(Integer i, Id testUserId, Account Acc) {
           
    Contact TestContact = new Contact();
    TestContact.FirstName = 'Test Contact FirstName';
    TestContact.LastName = 'Test Contact LastName' + i;
    TestContact.Account = Acc;
    TestContact.AccountId = Acc.Id;
    TestContact.PFG_CRM_Lead__c = [SELECT Id FROM User where Id =:testUserId].id;
   
    return TestContact;
    
    }

    public static Opportunity buildTestOpp(Integer i, Id testUserId, String RecordType, Account testAccId) {
    
    // Query for Opportunity record types
    List<RecordType> Opprtypes = [Select Name, Id From RecordType where sObjectType='Opportunity' and isActive=true];

    //Create a map between the Record Type Name and Id for easy retrieval
    Map<String,String> opportunityRecordTypes = new Map<String,String>{};
    for(RecordType rt: Opprtypes)
    opportunityRecordTypes.put(rt.Name,rt.Id);
       
    Opportunity TestOpp = new Opportunity();
    TestOpp.ownerId = testUserId;
    TestOpp.RecordTypeId = opportunityRecordTypes.get(RecordType);
    TestOpp.Name = 'testOpp' + i;
    TestOpp.StageName = '1 - Identified as Prospect';
    TestOpp.CloseDate = Date.today();
    TestOpp.Amount = 1;
    //Item added to increase coverage and avoid Process Builder failures on Created Opportunities.
    TestOpp.AccountID= testAccId.ID;

    Investment_Vehicle__c iv = TestFactory.buildInvestmentVehicle('test');
    insert iv;
    TestOpp.Investment_Vehicle__c = iv.id;
   
    return TestOpp;
    
    }
    
    public static Task buildTestTasks(Integer i, Id testUserId, Id RelatedId) {
       
    Task TestTask = new Task();
    TestTask.ownerId = testUserId;
    TestTask.whatId = RelatedId;
    TestTask.Subject = 'This is test task # ' + i;
    TestTask.ActivityDate = Date.today();
  
    return TestTask;
    
    }
    
    public static Event buildTestEvents(Integer i, Id testUserId, Id RelatedId) {
       
    Event TestEvent = new Event();
    TestEvent.ownerId = testUserId;
    TestEvent.whatId = RelatedId;
    TestEvent.Subject = 'This is test Event # ' + i;
    TestEvent.ActivityDate = Date.today();
    TestEvent.ActivityDateTime = Date.today();
    TestEvent.DurationInMinutes = 50;
   
    return TestEvent;
    
    }

    public static Campaign createCampaign(String campaignName, boolean isPSG) {
        Campaign c = new Campaign(Name = campaignName, IsActive = true);
        if(isPSG) {
            c.RecordTypeId = '0120b0000001IsF';
        }
        return c;
    }

    public static Account queryAccount(Id accountId) {
        return [SELECT Id
                FROM Account
                WHERE Id = :accountId];
    }

    public static Investment_Vehicle__c buildInvestmentVehicle(String invVehicleName) {
        return new Investment_Vehicle__c(Name = invVehicleName, Long_Name__c = invVehicleName, 
                                         Vehicle_Type__c = 'General Overview', Platform__c = 'Infrastructure');
    }

}