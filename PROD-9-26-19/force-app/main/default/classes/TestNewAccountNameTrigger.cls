@isTest
public class TestNewAccountNameTrigger {
  static testMethod void testBulkInsert() {
        List<Opportunity> opps = new List<Opportunity>();
        integer iterations = 10;
        
        string accName = 'Test Account';
        List<Account> accs = new List<Account>();
        //User u  = [Select id, name from User]
        for (integer i = 0; i < iterations; i++)
        {
            Account acc = new Account(
                name = accName + ' ' + i,
                RecordTypeId = '0120b000000B0QUAA0',
                BillingCountry = 'United States',
                OwnerId = '0050b000005fjSN'
            );
            accs.add(acc);
        }
        
        insert accs;

        // BF-33: Added to fix code coverage
        accs = [SELECT Id
                FROM Account
                WHERE OwnerId = '0050b000005fjSN'
                AND Name LIKE 'Test Account%'
                AND RecordTypeId = '0120b000000B0QUAA0'
                AND CreatedDate = TODAY
                LIMIT 10];
        system.debug('TestNewAccountNameTrigger :: accs = ' + accs);
        
        string ivName = 'BIF II';
        Investment_Vehicle__c iv = new Investment_Vehicle__c(
            Name = ivName,
            RecordTypeId = '01233000000MIBHAA4',
            Vehicle_Type__c = 'Private Fund',
            Long_Name__c = 'BIF',
            Status__c = 'Marketing',
            Platform__c = 'Infrastructure'
        );
        
        insert iv;
        
        iv = [Select Id, Name from Investment_Vehicle__c where Name = :ivName];
        
        // BF-33: This was causing an index out of bound error
        // accs = [select Id, Name from Account where name = :accName];
        
        for (Integer i=0;i<iterations;i++) {

            Opportunity a = new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = accs[i].Id,
                Investment_Vehicle__c = iv.Id,
                RecordTypeId = '01240000000MHIDAA4',
                CloseDate = System.today().addMonths(1),
                CurrencyIsoCode = 'USD',
                StageName = '1: Prospect identified',
                ForecastCategoryName = 'Pipeline',
                Duplicate__c = true,
                Amount = 1000,
                OwnerId = '0050b000005fjSN'
                //,  ForecastCategory = 'Pipeline'
            );
            
            System.debug(a.AccountId);
            System.debug(a.Investment_Vehicle__c);
            opps.add(a);

        }
        
        Test.startTest();  

        insert opps;
        update opps;
        
        Test.stopTest();     

        // query for all accounts created and assert that the color was added correctly
        for (Opportunity opp : [Select Name from Opportunity])
            System.debug(opp.Name);
            
        for (Account acc : [Select Id,Name from Account])
            System.debug(acc.Id + ' ' + acc.Name);
        
        for (Investment_Vehicle__c inV : [Select Id,Name from Investment_Vehicle__c])
            System.debug(inV.Id + ' ' + inV.Name);
    }
}