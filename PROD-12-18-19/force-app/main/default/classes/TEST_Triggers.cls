@isTest(SeeAllData=false)
private with sharing class TEST_Triggers {
    private static testMethod void Test_Account() {
        Account a = new Account(Name='Test Account');

        insert a;
        update a;
        delete a;
    }
    private static testMethod void Test_Office() {
        Account a = new Account(Name='Test Account');
        insert a;

        Office__c o = new Office__c(Name='Test Office', Account__c=a.Id);

        insert o;
        update o;
        delete o;
    }
    private static testMethod void Test_Commitment() {
        Investment_Vehicle__c iv = new Investment_Vehicle__c();
        insert iv;
        Finaccount__c c = new Finaccount__c();
        c.Investment_Vehicle__c = iv.Id;
        insert c;
        update c;
        delete c;
    }
    private static testMethod void Test_InvestorPosition() {
        Account a = new Account(Name='Test Account');
        insert a;

        Investment_Vehicle__c inv = new Investment_Vehicle__c(Name='Test Invesment Vehicle');
        insert inv;

        Opportunity o = new Opportunity(Name='Test Opp', StageName='test', CloseDate=system.today(), Investment_Vehicle__c=inv.Id, AccountId=a.Id);
        insert o;

        Investor_Position__c invPos = new Investor_Position__c(Name='Test Investor Position', Current_Commitments_USD__c=10, Investment_Vehicle__c=inv.Id, Investor_Position_Account__c=a.Id, Opportunity_Name__c=o.Id);

        insert invPos;
        update invPos;
        delete invPos;
    }
    private static testMethod void Test_Coverage() {
        Coverage__c c = new Coverage__c(Role__c='Primary', Business_Group__c='Real Estate', Relationship_Importance__c='Do Not Call');

        insert c;
        update c;
        delete c;
    }

    private static testMethod void Test_Opportunity() {
        Account a = new Account(Name='Test Account');
        insert a;

        Investment_Vehicle__c inv = new Investment_Vehicle__c(Name='Test Invesment Vehicle');
        insert inv;

        Opportunity o = new Opportunity(Name='Test Opp', StageName='test', CloseDate=system.today(), Investment_Vehicle__c=inv.Id, AccountId=a.Id);

        insert o;
        update o;
        delete o;
    }
}