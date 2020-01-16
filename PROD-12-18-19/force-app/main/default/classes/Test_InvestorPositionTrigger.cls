/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
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
private class Test_InvestorPositionTrigger {
        
    static testMethod void myUnitTest() {
    	
    	
      
       		Account account = new Account(Name='Test' );
    		insert account;
    		Account account1 = new Account(Name='Test1' );
    		insert account1;
    		Investment_Vehicle__c invvehicle = new Investment_Vehicle__c(Name='TestInvestmentVehicle');
    		insert invvehicle;
        //SS: 7/18/18 added following line of code for code coverage
        Opportunity opt = new Opportunity(Name = 'NewTestOpportunity', StageName ='2 - Initiated General Contact', CloseDate = system.today() , Investment_Vehicle__c = invvehicle.id, AccountId = account.id,  Consultant__c = account.id  );
        insert opt;
        //Opportunity opt1 = new Opportunity(Name = 'NewTestOpportunity1', StageName ='2 - Initiated General Contact', CloseDate = system.today() , Investment_Vehicle__c = invvehicle.id, AccountId = account.id,  Consultant__c = account.id  );
        //insert opt1;
    		Investor_Position__c invposition = new Investor_Position__c(As_of__c= System.Today() - 89 , Current_Commitments_Functional__c = 100000, Investor_Position_Account__c = account.Id, Investment_Vehicle__c = invvehicle.Id, Name='TestInvestorPosition', Source_of_Capital__c = 'Operating Partner', Is_Active__c=true, Opportunity_Name__c = opt.id, Current_Commitments_USD__c = 0);
    		insert invposition;
    		Investor_Position__c invposition1 = new Investor_Position__c(As_of__c= System.Today() -89 , Investor_Position_Account__c = account1.Id, Investment_Vehicle__c = invvehicle.Id, Name='TestInvestorPosition', Source_of_Capital__c = 'Operating Partner', Is_Active__c=true, Opportunity_Name__c = opt.id, Current_Commitments_USD__c = 0);
    		insert invposition1;
        //SS: 7/18/18 end of the change.
        test.startTest();
        
        //SS: 7/18/18 updated following line of code : From: As_of_Last_quater_text__c TO: As_of_Is_last_quater__c
        List<Investor_Position__c> InvPositionlst = [Select Id,As_of_Is_last_quater__c,As_of__c from Investor_Position__c where Investment_Vehicle__c =: invvehicle.Id];
        for(Investor_Position__c inv : InvPositionlst)
        {
        	 System.debug( 'test2323' + inv.As_of_Is_last_quater__c);
        	 System.debug('test2323' + inv.As_of__c);
       }
       system.debug('Test Investment Positions: ' + InvPositionlst.size());
        // SS: 7/18/18 end of change. 
        System.assertequals(InvPositionlst.size(),2);
      
       List<Investment_Vehicle__c> TestInvestmentVehicle = [Select Number_of_Historical_Investors__c, Number_of_Current_Investors__c from Investment_Vehicle__c where Id =: invvehicle.Id];
      System.assertequals(TestInvestmentVehicle.size(),1);
      //
      System.debug('....Historical Investor -1 .......'+TestInvestmentVehicle[0].Number_of_Historical_Investors__c);
      System.debug('....Current Investor -1 .......'+TestInvestmentVehicle[0].Number_of_Current_Investors__c);
       //
     	System.assertequals(TestInvestmentVehicle[0].Number_of_Historical_Investors__c,2);
       System.assertequals(TestInvestmentVehicle[0].Number_of_Current_Investors__c,1); 
       
       delete invposition;
       
         List<Investment_Vehicle__c> TestInvestmentVehicle1 = [Select Number_of_Historical_Investors__c, Number_of_Current_Investors__c from Investment_Vehicle__c where Id =: invvehicle.Id];
      System.assertequals(TestInvestmentVehicle1.size(),1);
      System.debug('....Historical Investor -2 .......'+TestInvestmentVehicle1[0].Number_of_Historical_Investors__c);
      System.debug('....Current Investor -2 .......'+TestInvestmentVehicle1[0].Number_of_Current_Investors__c);
     	System.assertequals(TestInvestmentVehicle1[0].Number_of_Historical_Investors__c,1);
      System.assertequals(TestInvestmentVehicle1[0].Number_of_Current_Investors__c,0);
       
       
        
        test.stopTest();

    }
   
    
}