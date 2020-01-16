/******************************************
Test Class Name - Test_AccountSummaryReportController
Created by - Samir Khan
Description - This test class is written for AccountSummaryReportController 
******************************************/
@isTest(seeAllData = false)
public class Test_AccountSummaryReportController {

    public static testMethod void testRunAs() {
        
        Account acct = new Account(Name = 'Apex Test', Top_Account__c = true);
        insert acct;
        
        Property__c objProperty = new Property__c(name = 'Apex Test');
        insert objProperty;
    
        Account_Summary__c accSumm = new Account_Summary__c (Account_Summary__c = 'Testing', Country__c = 'IN', Property__c = objProperty.id, Account__c = acct.id);
        insert accSumm;
        
        AccountSummaryReportController test = new AccountSummaryReportController();
        test.loadKeyAccounts();
        test.renderAsPdf();
        
        AccountSummaryReportControllerByAccounts test1 = new AccountSummaryReportControllerByAccounts();
        test1.loadKeyAccounts();
        test1.renderAsPdf();
        
        GroupByAccountsController  test2 = new GroupByAccountsController ();
        test2.loadKeyAccounts();
        test2.renderAsPdf(); 
    }

    /**
      * BF-1: Improving Code Coverage
      */
    public static testMethod void AccountSummaryWithLocation() {
        Account acct = new Account(Name = 'Apex Test', Top_Account__c = true);
        insert acct;
        
        Property__c objProperty = new Property__c(name = 'Apex Test');
        Property__c objProperty2 = new Property__c(name = 'Apex Test2');
        List<Property__c> propertyList = new List<Property__c>{objProperty, objProperty2};
        insert propertyList;
    
        Account_Summary__c accSumm = new Account_Summary__c (Account_Summary__c = 'Testing', Country__c = 'IN', Property__c = objProperty.id, Account__c = acct.id);
        Account_Summary__c accSumm2 = new Account_Summary__c (Account_Summary__c = 'Testing2', Country__c = 'IN', Property__c = objProperty.id, Account__c = acct.id);
        Account_Summary__c accSumm3 = new Account_Summary__c (Account_Summary__c = 'Testing3', Country__c = 'IN', Property__c = objProperty2.id, Account__c = acct.id);
        List<Account_Summary__c> asList = new List<Account_Summary__c>{accSumm, accSumm2, accSumm3};
        insert asList;
        
        AccountSummaryReportController test = new AccountSummaryReportController();
        test.loadKeyAccounts();
        test.renderAsPdf();
    }
}