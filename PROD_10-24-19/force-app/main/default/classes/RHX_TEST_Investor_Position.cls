@isTest(SeeAllData=true)
public class RHX_TEST_Investor_Position {
 static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
                                    FROM Investor_Position__c 
                                    WHERE RecordTypeId = '0120b0000001Iwv'
                                    LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Investor_Position__c(
                        RecordTypeId = '0120b0000001Iwv'
                    )
            );
        }
     rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}