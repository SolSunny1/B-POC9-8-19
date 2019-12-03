@isTest
Private class BatchBlankUpdateComplianceTest {
    @testSetup
    Static void setup(){
        Account acc = new Account (name = 'Test Account'); 
        insert acc;
        
        Id RecordTypeIdCompliance = Schema.SObjectType.Compliance__c.getRecordTypeInfosByName().get('PSG').getRecordTypeId();
      
        // find the account just inserted. add compliance for the account
        List<Compliance__c> Compliance = new List<Compliance__c>();
        //insert 10 compliances 
        for (Integer i=0;i<10;i++) {
            Compliance.add(new Compliance__c (Prospect_Name__c=acc.Id,recordtypeid=RecordTypeIdCompliance)); 
            
        }
        insert Compliance;
    }

    static testmethod void test() { 
        Test.startTest();
        BatchBlankUpdateCompliance bupComp = new BatchBlankUpdateCompliance ();
        Id batchId = Database.executeBatch(bupComp);
        
        Test.stopTest();
        System.assertEquals(10,[select count() from Compliance__c]);
    }
}