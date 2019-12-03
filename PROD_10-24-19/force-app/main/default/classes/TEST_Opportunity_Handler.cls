@isTest (SeeAllData=false)
private with sharing class TEST_Opportunity_Handler {
    @TestSetup
    private static void setup() {
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;

        Account testConsultant = new Account(Name='Test Consultant');
        insert testConsultant;

        Contact testContact = new Contact(FirstName='Test', LastName='Consultant');
        insert testContact;

        Investment_Vehicle__c testInvestmentVehicle = new Investment_Vehicle__c(Vehicle_Type__c = 'Co-Invest');
        insert testInvestmentVehicle;
    }

    private static testMethod void TEST_createConsultantRelationship() {
        Account testAccount = [select Id from Account where Name='Test Account' limit 1];
        Account testConsultant = [select Id from Account where Name='Test Consultant' limit 1];
        Investment_Vehicle__c testInvestmentVehicle = [select Id from Investment_Vehicle__c limit 1];
        RecordType rt = [select Id from RecordType where SobjectType='Opportunity' and DeveloperName like '%PSG%' limit 1];

        Opportunity o = new Opportunity(Name='Test Opportunity', AccountId=testAccount.Id, Consultant__c=testConsultant.Id, Investment_Vehicle__c=testInvestmentVehicle.Id, StageName='Test Stage Name', CloseDate=System.today(), RecordTypeId=rt.Id);
        insert o;

        system.assertEquals(1, [select Id from Consultant__c].size());

        update o;

        system.assertEquals(1, [select Id from Consultant__c].size());
    }

    private static testMethod void TEST_createFieldConsultantRelationship() {
        Account testAccount = [select Id from Account where Name='Test Account' limit 1];
        Contact testContact = [select Id from Contact limit 1];
        Investment_Vehicle__c testInvestmentVehicle = [select Id from Investment_Vehicle__c limit 1];
        RecordType rt = [select Id from RecordType where SobjectType='Opportunity' and DeveloperName like '%PSG%' limit 1];

        Opportunity o = new Opportunity(Name='Test Opportunity', AccountId=testAccount.Id, Field_Consultant__c=testContact.Id, Investment_Vehicle__c=testInvestmentVehicle.Id, StageName='Test Stage Name', CloseDate=System.today(), RecordTypeId=rt.Id);
        insert o;

        system.assertEquals(1, [select Id from Relationship__c].size());

        update o;

        system.assertEquals(1, [select Id from Relationship__c].size());
    }

    private static testMethod void TEST_createResearchConsultantRelationship() {
        Account testAccount = [select Id from Account where Name='Test Account' limit 1];
        Contact testContact = [select Id from Contact limit 1];
        Investment_Vehicle__c testInvestmentVehicle = [select Id from Investment_Vehicle__c limit 1];
        RecordType rt = [select Id from RecordType where SobjectType='Opportunity' and DeveloperName like '%PSG%' limit 1];

        Opportunity o = new Opportunity(Name='Test Opportunity', AccountId=testAccount.Id, Research_Consultant__c=testContact.Id, Investment_Vehicle__c=testInvestmentVehicle.Id, StageName='Test Stage Name', CloseDate=System.today(), RecordTypeId=rt.Id);
        insert o;

        system.assertEquals(1, [select Id from Relationship__c].size());

        update o;

        system.assertEquals(1, [select Id from Relationship__c].size());
    }

    private static testMethod void TEST_NewOpportunityName() {
        Account testAccount = [select Id from Account where Name='Test Account' limit 1];
        Contact testContact = [select Id from Contact limit 1];
        Investment_Vehicle__c testInvestmentVehicle = [select Id from Investment_Vehicle__c limit 1];
        RecordType rt = [select Id from RecordType where SobjectType='Opportunity' and Name like '%PFG%' limit 1];

        Office__c testOffice = new Office__c(Name='Test Office', Account__c=testAccount.Id);
        insert testOffice;

        Investment_Vehicle__c testInvestmentVehicle2 = new Investment_Vehicle__c(Vehicle_Type__c = 'Separate Accounts');
        insert testInvestmentVehicle2;

        Investment_Vehicle__c testInvestmentVehicle3 = new Investment_Vehicle__c();
        insert testInvestmentVehicle3;

        Opportunity o = new Opportunity(Name='Test Opportunity', AccountId=testAccount.Id, Research_Consultant__c=testContact.Id, Investment_Vehicle__c=testInvestmentVehicle.Id, Office__c=testOffice.Id, StageName='Closed Won', CloseDate=System.today(), RecordTypeId=rt.Id);
        Opportunity o2 = new Opportunity(Name='Test Opportunity 2' , AccountId=testAccount.Id, Research_Consultant__c=testContact.Id, Investment_Vehicle__c=testInvestmentVehicle2.Id, Office__c=testOffice.Id, StageName='Closed Won', CloseDate=System.today(), RecordTypeId=rt.Id);
        Opportunity o3 = new Opportunity(Name='Test Opportunity 3' , AccountId=testAccount.Id, Research_Consultant__c=testContact.Id, Investment_Vehicle__c=testInvestmentVehicle3.Id, StageName='Closed Won', CloseDate=System.today(), RecordTypeId=rt.Id);
        insert new List<Opportunity>{o,o2,o3};

        Account a = new Account(Name='Test Account 2');
        insert a;

        testOffice.Account__c = a.Id;
        update testOffice;

        o.AccountId=a.Id;
        update o;

        Test.startTest();
        Investment_Vehicle__c testInvestmentVehicle4 = new Investment_Vehicle__c(Fund_Series__c='AG');
        insert testInvestmentVehicle4;

        o3.Investment_Vehicle__c = testInvestmentVehicle2.Id;
        update o3;
        Test.stopTest();


    }
}