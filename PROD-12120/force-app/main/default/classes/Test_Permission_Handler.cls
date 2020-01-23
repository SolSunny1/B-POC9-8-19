@isTest (SeeAllData=false)
private with sharing class Test_Permission_Handler {   
    @testSetup 
  	static void setup(){
       
      	Contact testContact = new Contact(FirstName='Test', LastName='TestlastName',Email='test@test.com');
        insert testContact;
        Investment_Vehicle__c testInvestmentVehicle = new Investment_Vehicle__c(Vehicle_Type__c = 'Co-Invest');
        insert testInvestmentVehicle;
        Investment_Vehicle__c investment_vehicle_Obj = [select Id from Investment_Vehicle__c limit 1];   
        Finaccount__c testCommitment =  new Finaccount__c(Investment_Vehicle__c = investment_vehicle_Obj.id);
        insert testCommitment;        
  	}
    
    
 	static testMethod void test_createPlatformEvents(){
        Contact contact_Obj =[Select id,FirstName,Email from Contact limit 1];
        Finaccount__c finaccount_Obj = [Select Id From Finaccount__c limit 1 ];
        Investment_Vehicle__c investment_vehicle_Obj = [select Id from Investment_Vehicle__c limit 1];
      	Permission__c permission_Obj = new Permission__c(Finaccount__c = finaccount_Obj.id, Contact__c = contact_Obj.id, Fund__c = investment_vehicle_Obj.id, Status__c = 'Active');
              
        test.startTest();        
       	Insert permission_Obj;
        List<PermissionUpdate__c> permissionupdate_ObjtoUpdate = new List<PermissionUpdate__c>();
        Permission__c permission_Obj1  =  [SELECT Name,Finaccount__c,Contact__c,Fund__c,Status__c from Permission__c limit 1];        
        for(Permission__c p : [SELECT Name,Finaccount__c,Contact__c,Fund__c,Fund__r.Id,Status__c,Contact__r.FirstName,Contact__r.Email from Permission__c where Contact__r.Email <> '']){
        	PermissionUpdate__c pu = new PermissionUpdate__c(); 
            pu.ContactActive__c = true;
            pu.ContactExternalId__c = p.Contact__c;  
            pu.ContactFirstName__c = p.Contact__r.FirstName;
            permissionupdate_ObjtoUpdate.add(pu);            
        }
       
        System.assertEquals(true,permissionupdate_ObjtoUpdate.size()>0);
        insert permissionupdate_ObjtoUpdate;
        permission_Obj1.status__c = 'Inactive';
        update permission_Obj1;       
        test.stopTest();
          
  }   
    
}