public class NewDX_FundIntegration_Handler {
    //This handler creates entry in FundUpdate and InvestorUpdate Objcets on the creation of Investment Vehicle and Leagal Entity respectively
    
    final string COMMUNITYNAME = 'INVESTORCOMMUNITYNAME';
    CommunityName__mdt commNameMapping = [Select Name__c from CommunityName__mdt where MasterLabel =: COMMUNITYNAME];
     public void CreateFundInvestorUpdate(List<DX_FundIntegration__e> lstIV) {        
        List<String> fundIds = new List<String>();  
        List<String> InvestorIds = new List<String>(); 
        for (DX_FundIntegration__e event : lstIV){
			System.Debug('Fund Id ' + event.Fund_Id__c);
            if(event.Fund_Id__c != Null){
        		fundIds.add(event.Fund_Id__c);
            }
            if(event.LegalEntity_Id__c != Null){
           	 	InvestorIds.add(event.LegalEntity_Id__c);
            }
		}
         System.debug('fundIds--- '+fundIds);
         System.debug('InvestorIds--- '+InvestorIds);
         //if(fundIds.Size() >0 && InvestorIds.Size() == 0) {
         if(fundIds.Size() >0) {
             CreateFundUpdate(fundIds);
         }            
         if(InvestorIds.Size() > 0 ){
                CreateInvestorUpdate(lstIV);
            }
     }
     //Create Funds 
    public void CreateFundUpdate(List<String> FundIds) {
        List<DxFundUpdate__c> fundUpdates = new List<DxFundUpdate__c>();
        List<Investment_Vehicle__c> funds = [Select id,Name,Platform__c from Investment_Vehicle__c where Id IN : fundIds];
        for(Investment_Vehicle__c iv : funds){
            DxFundUpdate__c dfu = new DxFundUpdate__c();
            
            dfu.FundName__c 	  = iv.Name;
            dfu.FundExternalId__c = iv.Id;
            dfu.FundAssetClass__c = iv.Platform__c;
            dfu.Community__c 	  = commNameMapping.Name__c;
            fundUpdates.add(dfu);
        }
        try{  
            system.debug('Value to insert-- '+fundUpdates);
            insert fundUpdates; 
        }
        catch (exception e) {                
            system.debug('#### Exception caught in fundUpdates: ' + e.getMessage());                
        }
    }
     //Create Investors   
    public void CreateInvestorUpdate(List<DX_FundIntegration__e> event) {
        List<DxInvestorUpdate__c> investorUpdates = new List<DxInvestorUpdate__c>();  
        for(DX_FundIntegration__e e : event){
            DxInvestorUpdate__c dIu = new DxInvestorUpdate__c();
            if(e.LegalEntity_Id__c != null || e.LegalEntity_Name__c != null  )
            {
                dIu.InvestorName__c 	  	= e.LegalEntity_Name__c;
                dIu.InvestorExternalId__c 	= e.LegalEntity_Id__c;           
                dIu.Community__c 	  	 	= commNameMapping.Name__c;
                dIu.Commitment__c		 	= e.Commitment_Id__c;
                dIu.Fund_Id__c				= e.Fund_Id__c;
                dIu.Fund_Name__c         	= e.Fund_Name__c;
                    
                investorUpdates.add(dIu);
            }
        }
        try{  
            system.debug('Value to insert-- '+investorUpdates);
            insert investorUpdates; 
        }
        catch (exception e) {                
            system.debug('#### Exception caught in investorUpdates: ' + e.getMessage());                
        }
    }    
    
}