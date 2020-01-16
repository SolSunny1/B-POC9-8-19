/**
 * This class contains unit tests for validating the behavior of Apex classe
 * OppDeepClone.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(SeeAllData=false)
private class Test_OppDeepClone{

    static testMethod void myUnitTest() {
    
        // create test data - test method will be run as curent runing user - no need to test sepaate users
        Account acc = new Account (Name='TestAccount');
        insert acc;
        Opportunity opp = new Opportunity(AccountId=acc.Id,Name='TestOpportunity',StageName='Pitch',CloseDate=System.Today().addDays(7),Office_Country__c='Canada', Office_City__c='Toronto');
        insert opp;
        
        Test.startTest();
        // test deep clone controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
        OppDeepClone oppContr = new OppDeepClone(stdController);
    	PageReference pRef = oppContr.FinishPage;

        // BF-9: Added for code coverage
        oppContr.getactID();
        system.assertEquals(oppContr.OppId, opp.Id);

        Test.stopTest();
    }
}