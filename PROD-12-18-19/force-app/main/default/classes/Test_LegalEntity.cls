@isTest(SeeAllData = false)
public class Test_LegalEntity {
    @testSetup 
  	static void setup(){
       
      	Contact testContact = new Contact(FirstName='Test', LastName='TestlastName',DX_Email__c='test@test.com');
        insert testContact;
        Account acc = new Account(Name = 'testAcc') ;
        insert acc;           
        Investment_Vehicle__c testInvestmentVehicle = new Investment_Vehicle__c(Vehicle_Type__c = 'Co-Invest',Name='CoTest', DX_Integration__c ='Active'); 
        insert testInvestmentVehicle;
        Permission_Type__c pType = new Permission_Type__c(Name = 'test');
        insert pType;
        
            
  	}
   static testMethod void test_insertLegalEntity(){
       List<Permission_Event__e> lstPermissionPlatformEvents = new List<Permission_Event__e>();
       Account accObj = [Select id,name from account limit 1]; 
       Contact contact_Obj =[Select id from Contact limit 1];     
       Permission_Type__c ptypeObj = [select id,name from Permission_Type__c limit 1];
       Account_Vehicle__c legalEntity = new Account_Vehicle__c(Name = 'test',Account__c = accObj.id );
       insert legalEntity;
       Account_Vehicle__c legalEntityObj = [Select id,name from Account_Vehicle__c limit 1];
       
       Investment_Vehicle__c investment_vehicle_Obj = [select Id,DX_Integration__c,Name from Investment_Vehicle__c limit 1];
       List<Investment_Vehicle__c> investmentVSet = [select Id,DX_Integration__c,Name from Investment_Vehicle__c];   
       Finaccount__c testCommitment =  new Finaccount__c(Investment_Vehicle__c = investment_vehicle_Obj.id,Account__c =accObj.id,Account_Vehicle__c =legalEntityObj.id );
       test.startTest();
       insert testCommitment;
       Finaccount__c finaccount_Obj= [Select id,name from Finaccount__c limit 1 ];
       List<Finaccount__c> commitment = [Select id,name,Investment_Vehicle__r.id,Account_Vehicle__r.id,Account_Vehicle__r.Name,Investment_Vehicle__r.DX_Integration__c,Investment_Vehicle__r.Name from Finaccount__c 
                               					where Account_Vehicle__r.id =:legalEntityObj.Id and Investment_Vehicle__r.DX_Integration__c IN: new List<String>{'Active','Planned'}];
       for(Finaccount__c c: commitment )
       {
           
       }
       Permission__c permission_Objlst = new Permission__c(Permission_Type__c=ptypeObj.Id,Finaccount__c = finaccount_Obj.id, Contact__c = contact_Obj.id, Fund__c = investment_vehicle_Obj.id, Status__c = 'Active');
       //Permission__c PermissionLst = [select Id, Contact__c, Contact__r.DX_Email__c, Fund__c, Permission_Type__c from Permission__c where Fund__c IN : investmentVSet];
       /*lstPermissionPlatformEvents.add(new Permission_Event__e(
                            Contact_Email__c = 'test@test.com',
                            Contact_Id__c = contact_Obj.id
                    ));
       if (lstPermissionPlatformEvents.size() > 0) {
           List<Database.SaveResult> results = EventBus.publish(lstPermissionPlatformEvents);
       }*/
       test.stopTest();
       
       
   }

}