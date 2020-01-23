@isTest(SeeAllData = false)
public class Test_PermissionUpdateProcessor {  
    
  public testmethod static void RunSchedule() {
       Test.StartTest();
      	PermissionUpdateProcessor Contractobj = new PermissionUpdateProcessor();
		String sch = '20 30 8 10 2 ?';
		String jobID = system.schedule('Test PermissionJOB', sch, Contractobj);
       Test.StopTest();      
      
  }
  static testmethod void testFunc(){
      
      	PermissionUpdate__c permissionupdate_Obj = new PermissionUpdate__c(Community__c = 'Commu946', ContactActive__c = false, ContactEmail__c = 'Email17@test.com', ContactExternalId__c = 'Conta651', ContactFirstName__c = 'Conta914', ContactLastName__c = 'Conta667',FundAssetClass__c = 'Property', FundExternalId__c = 'FundE182', FundName__c = 'FundN358', GroupAccess__c = false, GroupEndDate__c = Date.today(), GroupName__c = 'Group128', GroupNotification__c = false, GroupStartDate__c = Date.today(), InvestorName__c = 'Inves927');
    	 
    	DxFundUpdate__c dxfundupdate_Obj = new DxFundUpdate__c(FundAssetClass__c = 'FundA696', FundName__c = 'FundN373');
    	string jsonS = '';
        //IntegrationRequestSetup__mdt dxRequest = new IntegrationRequestSetup__mdt(Username__c = 'test' ,SecurityToken__c='133333',EndpointServer__c='tsgazusinvwa01d', MasterLabel = 'DXSetup');
      	//insert dxRequest;
       
  		Test.StartTest(); 
      	Insert permissionupdate_Obj;
      	Insert dxfundupdate_Obj; 
      	List<PermissionUpdate__c> permissionupdate_Obj1  =  [SELECT Community__c,ContactActive__c,ContactEmail__c,ContactExternalId__c,ContactFirstName__c,ContactLastName__c,FundAssetClass__c,FundExternalId__c,FundName__c,GroupAccess__c,GroupEndDate__c,GroupName__c,GroupStartDate__c,InvestorName__c from PermissionUpdate__c ];
		List<PermissionUpdate__c> permissionupdate_Obj2 = new List<PermissionUpdate__c>();
        IntegrationRequestSetup__mdt dxRequestobj = [Select Username__c,SecurityToken__c,EndpointServer__c from IntegrationRequestSetup__mdt where MasterLabel =: 'DXSetup'];
      	string assetClass;
      	for (PermissionUpdate__c p:permissionupdate_Obj1 )
        {                       
            if(p.FundAssetClass__c == 'Property')
            {	
                assetClass = 'Real Estate'; 
            }            
        }
      DxFundUpdate__c dxfundupdate_Obj1  =  [SELECT FundAssetClass__c,FundName__c from DxFundUpdate__c limit 1];
        Test.setMock(HttpCalloutMock.class, new Test_MockRequestPermission());
        UpdateDXIntegration.futureExecute();
      	UpdateDXIntegration.UpdatePermissions(permissionupdate_Obj1);
      	UpdateDXIntegration.UpdateFunds(dxfundupdate_Obj1); 
        Test.StopTest(); 
  
	}
    static testmethod void testInvestor(){
        DxInvestorUpdate__c investorLst = new DxInvestorUpdate__c(InvestorName__c= 'TestI',InvestorExternalId__c='234355',Fund_Id__c='545666',Fund_Name__c='TestF',Community__c='Brookfield');
        Test.StartTest(); 
      	Insert investorLst;
        Map<id,DxInvestorUpdate__c> lstInvestor =new Map<Id,DxInvestorUpdate__c>([Select id, InvestorName__c,InvestorExternalId__c,Fund_Id__c,Fund_Name__c,Community__c from DxInvestorUpdate__c]);
        Test.setMock(HttpCalloutMock.class, new Test_MockRequestPermission());
        UpdateDXIntegration.UpdateInvestorCommitment(lstInvestor);
        Test.StopTest();
        
    }
}