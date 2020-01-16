trigger NewFundraisingCampaignEvent on Fundraising_Campaign_Event__e (after insert) {
    final string COMMUNITYNAME = 'FundraisingCommunityName';
    Set<id> campaignIds = new Set<id>();
    for (Fundraising_Campaign_Event__e event : Trigger.New)
    {
		System.Debug('Campaign Id ' + event.Campaign_Id__c);
        
        campaignIds.add(event.Campaign_Id__c);
	}
    
	List<Campaign> campaigns = [select Id, Name,Room_Type__c, Investment_Vehicle__r.Id,Sleeve__r.id,Sleeve__r.Name, Account__r.Name,Account__r.Id,Investment_Vehicle__r.Name, Investment_Vehicle__r.Platform__c, status from Campaign where Id in:campaignIds];
    //Calling to get data from MetaData Setup -SOQL does not count under Governance Limit 
    CommunityName__mdt commNameMapping = [Select Name__c from CommunityName__mdt where MasterLabel =: COMMUNITYNAME];
    List<DxFundUpdate__c> fundUpdates = new List<DxFundUpdate__c>();
    List<DxInvestorUpdate__c> investorUpdates = new List<DxInvestorUpdate__c>(); 
    DxInvestorUpdate__c dIu = new DxInvestorUpdate__c();
    for(Campaign c:campaigns)
    {
    	DxFundUpdate__c dfu = new DxFundUpdate__c();
        
        dfu.FundName__c = c.Investment_Vehicle__r.Name;
        dfu.FundExternalId__c = c.Investment_Vehicle__r.Id;
        dfu.FundAssetClass__c = c.Investment_Vehicle__r.Platform__c;
        
        fundUpdates.add(dfu);
        
        DxInvestorUpdate__c dIu = new DxInvestorUpdate__c();
        if(c.Room_Type__c == 'Prospect Specific' || c.Room_Type__c == 'Sleeve'  )
            {
               if(c.Room_type__c == 'Prospect Specific'){                
                 	dIu.InvestorName__c 	  	= c.Account__r.Name;
                	dIu.InvestorExternalId__c 	= c.Account__r.Id;  
                }
                else if (c.Room_type__c == 'Sleeve') {
                    dIu.InvestorName__c 	  	= c.Sleeve__r.Name;
                	dIu.InvestorExternalId__c 	= c.Sleeve__r.id; 
           		 } 
                else {
                    dIu.InvestorName__c 	  	= '';
                	dIu.InvestorExternalId__c 	= ''; 
           		 }
                dIu.Community__c 	  	 	= commNameMapping.Name__c;                
                dIu.Fund_Id__c				= c.Investment_Vehicle__r.Id;
                dIu.Fund_Name__c         	= c.Investment_Vehicle__r.Name;
                    
                investorUpdates.add(dIu);
            }
    }
    try{  
            system.debug('Value to insert in Fund event -- '+investorUpdates);
        	insert fundUpdates;
            insert investorUpdates; 
        }
        catch (exception e) {                
            system.debug('#### Exception caught in investorUpdates: ' + e.getMessage());                
        }
    
    
    
}