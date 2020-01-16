/****************************************
*  SS:6/6/19 -  Added "order by lastmodifieddate desc" at line #10 to isolate deployement issue in the PROD. 
*
****************************************/
@isTest(SeeAllData=true)
public class RHX_TEST_Opportunity {
    static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
            FROM Opportunity order by lastmodifieddate desc LIMIT 1 ]; //SS: 6/6/19 Added order by clause to isolate deployment issue. 
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Opportunity()
            );
        }
        rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}