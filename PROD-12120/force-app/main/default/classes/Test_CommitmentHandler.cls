@isTest(SeeAllData = false)
public class Test_CommitmentHandler {
@testSetup 
  	static void setup(){
       
      	Contact testContact = new Contact(FirstName='Test', LastName='TestlastName');
        insert testContact;
        Account acc = new Account(Name = 'testAcc') ;
        insert acc;           
        Investment_Vehicle__c testInvestmentVehicle = new Investment_Vehicle__c(Vehicle_Type__c = 'Co-Invest',Name='CoTest', DX_Integration__c ='Active'); 
        insert testInvestmentVehicle;
            
  	}
   static testMethod void test_insertInvestor(){
    Investment_Vehicle__c testInvestmentVehicle = new Investment_Vehicle__c(Vehicle_Type__c = 'Co-Invest',Name='CoTest', DX_Integration__c ='Active');  
    Account accObj = [Select id,name from account limit 1];   
    Investment_Vehicle__c investment_vehicle_Obj = [select Id,DX_Integration__c,Name from Investment_Vehicle__c limit 1];
    Account_Vehicle__c legalEntity = new Account_Vehicle__c(Name = 'test',Account__c = accObj.id,Legal_Entity_Legal_Name__c ='Test1' );
    insert legalEntity;
    Finaccount__c testCommitment =  new Finaccount__c(Investment_Vehicle__c = investment_vehicle_Obj.id,Account__c =accObj.id,Account_Vehicle__c = legalEntity.id );
    Account_Vehicle__c legalEntityObj = [Select id,name,Legal_Entity_Legal_Name__c from Account_Vehicle__c limit 1];
    test.startTest();
    insert testInvestmentVehicle;
    legalEntityObj.name = 'TestValue2';
    update legalEntityObj;
    insert testCommitment;
    delete   testCommitment;
    test.stopTest();
   }
    static testMethod void test_insertFund(){
    
    //Account accObj = [Select id,name from account limit 1];   
    //Investment_Vehicle__c investment_vehicle_Obj = [select Id,DX_Integration__c,Name from Investment_Vehicle__c limit 1];
    Investment_Vehicle__c testInvestmentVehicle = new Investment_Vehicle__c(Vehicle_Type__c = 'Co-Invest',Name='CoTest', DX_Integration__c ='Active');     
    
    test.startTest();
    insert testInvestmentVehicle;
    
    test.stopTest();
   }
}