@isTest private class Test_OpportunityEvent {

public static testMethod void testRunAs() {
        // Test Run as a PFG User
        Profile p = [SELECT Id FROM Profile WHERE Name='PFG_General']; 
        User u = new User(Alias = 'TESTABS', Email='ABS@Brownfield.com', 
            EmailEncodingKey='UTF-8', LastName='TestABS', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='ABS@Brownfield.com');
            System.assertequals(u.UserName,'ABS@Brownfield.com');
        System.runAs(u) {
            // The following code runs as user 'u' 
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId()); 
            }
    }

    testMethod private static void testNewEventOpp() {

// Query for Event record types
List<RecordType> rtypes = [Select Name, Id From RecordType where sObjectType='Event' and isActive=true];

//Create a map between the Record Type Name and Id for easy retrieval
    Map<String,String> eventRecordTypes = new Map<String,String>{};
    for(RecordType rt: rtypes)
    eventRecordTypes.put(rt.Name,rt.Id);

    
// Query for Opportunity record types
List<RecordType> Opprtypes = [Select Name, Id From RecordType where sObjectType='Opportunity' and isActive=true];

//Create a map between the Record Type Name and Id for easy retrieval
    Map<String,String> opportunityRecordTypes = new Map<String,String>{};
    for(RecordType rt: Opprtypes)
    opportunityRecordTypes.put(rt.Name,rt.Id);
    
    List<Opportunity> Opps = new List<Opportunity>();
    List<Event> Ev = new List<Event>();

    // BF-9: Create a test account
    Account acct = TestFactory.buildTestAcc(1, UserInfo.getUserId());
    insert acct;

    // BF-33: Added an investment vehicles to opportunities
    Investment_Vehicle__c iv = TestFactory.buildInvestmentVehicle('test');
    insert iv;
    
    for (Integer i = 0; i < 5; i++) {
        Opportunity TestOpp = new Opportunity();
        TestOpp.ownerId = UserInfo.getUserId();
        TestOpp.RecordTypeId = opportunityRecordTypes.get('PFG');
        TestOpp.Name = i + 'test' + Math.round(Math.random()*1000);
        TestOpp.StageName = '1 - Identified as Prospect';
        TestOpp.CloseDate = Date.today().addDays(i);
        TestOpp.Amount = 1 + i;
        TestOpp.Duplicate__c = true;
        TestOpp.AccountId = acct.Id;
        TestOpp.Investment_Vehicle__c = iv.Id;
        Opps.add(TestOpp);
    }

    // BF-25: Updated to ignore duplicates
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    dml.DuplicateRuleHeader.runAsCurrentUser = true;
    Database.insert(Opps, dml);
    
    for (Opportunity o :    Opps) {
        Event TestEvent = new Event();
        TestEvent.ownerId = UserInfo.getUserId();
        //TestEvent.RecordTypeId = eventRecordTypes.get('BIM_PFG');
        TestEvent.whatId = o.Id;
        TestEvent.Subject = 'This is a test event';
        TestEvent.IsAllDayEvent = true;
        TestEvent.ActivityDate = Date.today();
        TestEvent.Interaction_Type__c = '';
        Ev.add(TestEvent);
    }
    insert Ev;
    
    }
}