@isTest(SeeAllData=false)
/**
  * BF-9: Code Coverage for Existing Code
  */
public class Test_Utilities {
	
	static testMethod void testUtilitiesController() {

		Test.startTest();

		UtilitiesController uc = new UtilitiesController();
		uc.runRollUpBatch();
		
		Test.stopTest();
	}

	static testMethod void testUtilitiesControllerIPBatch() {

		Test.startTest();

		UtilitiesController uc = new UtilitiesController();
		uc.runPopulateInvestorPositionAccountBatch();

		Test.stopTest();
	}

}