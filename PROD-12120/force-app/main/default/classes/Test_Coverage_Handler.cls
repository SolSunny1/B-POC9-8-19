@isTest
private class Test_Coverage_Handler {
@testSetup
     static void setupTestData(){
          Account accobj = new Account(Name ='TestAccount' );
      		insert accobj;
         Account acc = [select name from Account limit 1];
         Coverage__c testCov1 = new Coverage__c(Role__c='Primary', Business_Group__c='Real Asset / Infra',Relationship_Importance__c='Low (3)',Account__c = acc.Id);
        	insert testCov1; 
         Coverage__c testCov2 = new Coverage__c(Role__c='Primary', Business_Group__c='Private Equity',Relationship_Importance__c='Low (3)',Account__c = acc.Id);
        	insert testCov2; 
         Coverage__c testCov3 = new Coverage__c(Role__c='Primary', Business_Group__c='Real Estate',Relationship_Importance__c='Low (3)',Account__c = acc.Id);
        	insert testCov3; 
         
     }
    static testMethod void test_Coverage_Handler_UseCase(){
        List<Coverage__c> covToDel = new List<Coverage__c>(); 
        for(Coverage__c cov: [Select id,Role__c,Business_Group__c from Coverage__c])
        {
            covToDel.add(cov);
        }
        test.startTest(); 
        	delete covToDel;
        test.stopTest();
    }
}