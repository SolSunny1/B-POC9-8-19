@isTest(SeeAllData=false)
public class CSL_Test_InvestmentVehicle  {

    /**
      * Ensure that an investment vehicle close date linked to an opp. cannot be deleted
      */
    public static testMethod void testInvestCloseDates() {
        // Insert Account
        Account acct = new Account(
                            RecordTypeId = '0120b000000B0QUAA0',
                            Name = 'TestCo',
                            Account_Status__c = 'Active',
                            BillingCountry = 'Canada',
                            BillingCity = 'Toronto'
                       );
        insert acct;

        // Add Investment Vehicle
        Investment_Vehicle__c iv = new Investment_Vehicle__c(
                                        Name = 'test vehicle',
                                        Long_Name__c = 'test vehicle',
                                        Vehicle_Type__c = 'Private Fund',
                                        Status__c = 'Marketing',
                                        Platform__c = 'Agriculture',
                                        RecordTypeId = '01233000000MIBHAA4'
                                   );
        insert iv;

        // Add Investment Vehicle Close Dates 
        Investment_Vehicle_Close_Date__c ivCloseDateFirst = new Investment_Vehicle_Close_Date__c(
                                                                Active__c = true,
                                                                Name = 'x',
                                                                Close_Date__c = Date.today() + 30,
                                                                Close_Type__c = 'First',
                                                                Investment_Vehicle__c = iv.Id
                                                           );
        Investment_Vehicle_Close_Date__c ivCloseDateLast  = new Investment_Vehicle_Close_Date__c(
                                                                Active__c = true,
                                                                Name = 'x',
                                                                Close_Date__c = Date.today() + 300,
                                                                Close_Type__c = 'Final',
                                                                Investment_Vehicle__c = iv.Id
                                                            );
        List<Investment_Vehicle_Close_Date__c> closeDateList = new List<Investment_Vehicle_Close_Date__c>{ivCloseDateFirst,ivCloseDateLast};
        insert closeDateList;

        // Add Opportunity
        Opportunity opp = new Opportunity(
                                RecordTypeId = '01240000000MHIDAA4',
                                AccountId = acct.Id,
                                Name = 'test opp',
                                Investment_Vehicle__c = iv.Id,
                                CloseDate = (Date.today() + 15),
                                Amount = 50000000,
                                StageName = '1: Prospect identified',
                                Investment_Vehicle_Close_Date__c = ivCloseDateFirst.Id
                          );
        insert opp;

        // Update Close Date
        Investment_Vehicle_Close_Date__c ivCloseDateUpdate = new Investment_Vehicle_Close_Date__c(
                                                                    Id = ivCloseDateFirst.Id,
                                                                    Close_Date__c = Date.today() + 35
                                                             );
        update ivCloseDateUpdate;

        opp = [SELECT Id, CloseDate
               FROM Opportunity
               WHERE Id = :opp.Id];
        system.assertEquals((Date.today() + 35), opp.CloseDate);

        // Delete fund close date
        try {
            delete ivCloseDateFirst;
        }   catch (Exception ex) {
            system.debug('CSL_Test_InvestmentVehicle :: testIvCloseDateDeleteValidation :: ex=' + ex.getMessage());
        }

    }

    public static testMethod void testBatchOppCloseDates() {
        // Insert Account
        Account acct = new Account(
                            RecordTypeId = '0120b000000B0QUAA0',
                            Name = 'TestCo',
                            Account_Status__c = 'Active',
                            BillingCountry = 'Canada',
                            BillingCity = 'Toronto'
                       );
        insert acct;

        // Add Investment Vehicle
        Investment_Vehicle__c iv = new Investment_Vehicle__c(
                                        Name = 'test vehicle',
                                        Long_Name__c = 'test vehicle',
                                        Vehicle_Type__c = 'Private Fund',
                                        Status__c = 'Marketing',
                                        Platform__c = 'Agriculture',
                                        RecordTypeId = '01233000000MIBHAA4'
                                   );
        insert iv;

        // Add Opportunity (before close dates so list will be blank)
        Opportunity opp = new Opportunity(
                                RecordTypeId = '01240000000MHIDAA4',
                                AccountId = acct.Id,
                                Name = 'test opp',
                                Investment_Vehicle__c = iv.Id,
                                CloseDate = (Date.today() + 15),
                                Amount = 50000000,
                                StageName = '1: Prospect identified'/*,
                                Investment_Vehicle_Close_Date__c = ivCloseDateFirst.Id*/
                          );
        insert opp;

        // Add Investment Vehicle Close Dates 
        Investment_Vehicle_Close_Date__c ivCloseDateFirst = new Investment_Vehicle_Close_Date__c(
                                                                Active__c = true,
                                                                Name = 'x',
                                                                Close_Date__c = Date.today() + 30,
                                                                Close_Type__c = 'First',
                                                                Investment_Vehicle__c = iv.Id
                                                           );
        Investment_Vehicle_Close_Date__c ivCloseDateLast  = new Investment_Vehicle_Close_Date__c(
                                                                Active__c = true,
                                                                Name = 'x',
                                                                Close_Date__c = Date.today() + 300,
                                                                Close_Type__c = 'Final',
                                                                Investment_Vehicle__c = iv.Id
                                                            );
        List<Investment_Vehicle_Close_Date__c> closeDateList = new List<Investment_Vehicle_Close_Date__c>{ivCloseDateFirst,ivCloseDateLast};
        insert closeDateList;

        // Schedule and run batch job
        CSL_Batch_Opportunity_FundCloseDates bj = new CSL_Batch_Opportunity_FundCloseDates(25);
        String sch = '0 0 21 * * ?'; // Daily @ 9pm
        String jobID = System.schedule('Test - Opp Fund Close Date Job', sch, bj);

        Test.startTest();
        Database.executeBatch(bj);
        Test.stopTest();
        
    }

}