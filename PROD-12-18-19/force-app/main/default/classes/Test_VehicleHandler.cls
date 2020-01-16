@isTest(SeeAllData = false)
public class Test_VehicleHandler {
    @testSetup 
  	static void setup(){
       
      	Contact testContact = new Contact(FirstName='Test', LastName='TestlastName',Email='test@test.com',DX_Email__C='test1@test.com');
        insert testContact;
        Account acc = new Account(Name = 'testAcc') ;
        insert acc;
        Permission_Type__c pType = new Permission_Type__c(Name = 'test');
        insert pType;
            
  	}
    
    static testMethod void test_createPlatformEvents(){
        Investment_Vehicle__c testInvestmentVehicle = new Investment_Vehicle__c(Vehicle_Type__c = 'Co-Invest',Name='CoTest', DX_Integration__c ='Planned'); 
         Investment_Vehicle__c testInvestmentVehicle2 = new Investment_Vehicle__c(Vehicle_Type__c = 'Co-Invest',Name='CoTest', DX_Integration__c ='Active');
        Account accObj = [Select id,name from account limit 1];
        
        test.startTest();
        insert testInvestmentVehicle;
        insert testInvestmentVehicle2;
        Investment_Vehicle__c investment_vehicle_Obj = [select Id,DX_Integration__c,Name from Investment_Vehicle__c limit 1];   
          
        Contact contact_Obj =[Select id,Email,Dx_Email__c from Contact limit 1];        
        Permission_Type__c ptypeObj = [select id,name from Permission_Type__c limit 1];
        
        Account_Vehicle__c legalEntity = new Account_Vehicle__c(Name = 'test',Account__c = accObj.id );
        insert legalEntity;
        Account_Vehicle__c legalEntityObj = [Select id,name from Account_Vehicle__c limit 1];
             
        investment_vehicle_Obj.Name = 'Test22';
        update investment_vehicle_Obj;
        
        Finaccount__c testCommitment =  new Finaccount__c(Investment_Vehicle__c = investment_vehicle_Obj.id,Account__c =accObj.id,Account_Vehicle__c =legalEntityObj.id );
        insert testCommitment;
        Finaccount__c testCommitment2 =  new Finaccount__c(Investment_Vehicle__c = investment_vehicle_Obj.id,Account__c =accObj.id,Account_Vehicle__c =legalEntityObj.id );
        insert testCommitment2;
        Finaccount__c finaccount_Obj = [Select Id,Investment_Vehicle__r.id,Account_Vehicle__r.id From Finaccount__c limit 1 ];
        
        List<DX_FundIntegration__e> avEventlst = new List<DX_FundIntegration__e>();  
      	Permission__c permission_Objlst = new Permission__c(Account_Vehicle__c =legalEntityObj.Id, Permission_Type__c=ptypeObj.Id,Finaccount__c = finaccount_Obj.id, Contact__c = contact_Obj.id, Fund__c = investment_vehicle_Obj.id, Status__c = 'Active');
        insert permission_Objlst;
        investment_vehicle_Obj.DX_Integration__c ='Active';
        update investment_vehicle_Obj;
      /*  for(Finaccount__c c : [Select id,name,Investment_Vehicle__r.id,Account_Vehicle__r.id,Account_Vehicle__r.Name,Investment_Vehicle__r.DX_Integration__c,Investment_Vehicle__r.Name from Finaccount__c 
                               					where Account_Vehicle__r.id =:legalEntityObj.Id and Investment_Vehicle__r.DX_Integration__c IN: new List<String>{'Active','Planned'}])
        {              
        DX_FundIntegration__e av_event = new DX_FundIntegration__e(LegalEntity_Id__c 		= legalEntityObj.id,
                                                                       LegalEntity_Name__c 		= legalEntityObj.Name,
                                                                  Fund_Id__c = investment_vehicle_Obj.Id);
        avEventlst.add(av_event); 
        }
        
        Permission__c PermissionLst = [Select id,Permission_Type__c, Finaccount__c,Contact__c,Fund__c from Permission__c limit 1 ];*/
        
        delete legalEntityObj;
        test.stopTest();
        
        
    }
    

}