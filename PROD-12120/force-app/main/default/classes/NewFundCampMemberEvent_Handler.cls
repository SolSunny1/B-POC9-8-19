public class NewFundCampMemberEvent_Handler {  
    final string COMMUNITYNAME = 'FundraisingCommunityName';
       
    public void deleteCampaignMemberFromDX(List<Fundraising_Campaign_Member_Event__e> campMemberEventLst) {
        Set<id> campaignMemberIds = new Set<id>();
        Set<id> campaignIds = new Set<id>(); 
        Set<id> fundIds = new Set<id>();
    	Set<id> contactIds = new Set<id>();
        Map<string,string> contactCampaign = new Map<string,string>();
        Set<id> accountIds = new Set<id>();
    	Set<id> sleeveIds = new Set<id>();
      
        List<PermissionUpdate__c> fundUpdates = new List<PermissionUpdate__c>();
         //Calling to get data from MetaData Setup -SOQL does not count under Governance Limit 
     	CommunityName__mdt commNameMapping = [Select Name__c from CommunityName__mdt where MasterLabel =: COMMUNITYNAME];
        
        for (Fundraising_Campaign_Member_Event__e event : campMemberEventLst)
        {
            System.Debug('Contact  Id ' + event.Contact_Id__c +'-----'+event.Campaign_Member_Id__c); 
            campaignMemberIds.add(event.Campaign_Member_Id__c);
            contactCampaign.put(event.Contact_Id__c,event.Campaign_Id__c);
            contactIds.add(event.Contact_Id__c);
            campaignIds.add(event.Campaign_Id__c);            
        }
        Map<id, Campaign> campaigns = new Map<id, Campaign>([select Id, Name, Investment_Vehicle__r.Id, Investment_Vehicle__r.Name, Investment_Vehicle__r.Platform__c, status, Room_Type__c, Sleeve__c, Account__c  from Campaign where Id in:campaignIds]);
       
    	Map<id, Contact> contacts = new Map<id, Contact>([select id, name, DX_Email__c, Email, FirstName, LastName from Contact where id in:contactIds]);
      	for (Campaign c:campaigns.values())
   		 {
            if (c.Room_type__c == 'Prospect Specific')
            {
                accountIds.add(c.Account__c);
            }
            else if (c.Room_type__c == 'Sleeve')
            {
                sleeveIds.add(c.Sleeve__c);
            }
             fundIds.add(c.Investment_Vehicle__r.id);
   		 }
    
        Map<id, Account> accounts = new Map<id, Account>([select Id, Name from Account where Id in:accountIds]);
        Map<id, Fund_Vehicle__c> sleeves = new Map<id, Fund_Vehicle__c>([select Id, Name from Fund_Vehicle__c where Id in:sleeveIds]);
        List< CampaignMember> campaignsWithFunds = [select Id, Name,CampaignId,campaign.Room_type__c,campaign.Investment_Vehicle__r.Id  from CampaignMember where campaign.Investment_Vehicle__r.Id in:fundIds and ContactId in: contactIds];
    	system.debug('campaignsWithFunds-----' + campaignsWithFunds);
        List<Contact> contactToUpdate = new List<Contact>();
        for(string contactId : contactCampaign.keySet())
        {        
        	System.debug(contactId);
    		System.debug(contactCampaign.get(contactId));
            Contact currContact = contacts.get(contactId);
            Campaign currCampaign = campaigns.get(contactCampaign.get(contactId));
            
            PermissionUpdate__c pu = new PermissionUpdate__c();
            pu.ContactActive__c = true;
            pu.ContactFirstName__c =	currContact.FirstName;
            pu.ContactLastName__c = 	currContact.LastName;
            if(currContact.DX_Email__c != null && currContact.DX_Email__c !='')
            {
                pu.ContactEmail__c = currContact.DX_Email__c;
            }
            else
            {
                 pu.ContactEmail__c =currContact.Email;
                
                currContact.DX_Email__c = currContact.Email;
                contactToUpdate.add(currContact);
                    
            }
            pu.ContactExternalId__c = 	currContact.Id;
            pu.FundName__c = 			currCampaign.Investment_Vehicle__r.Name;
            //TODO, map properly as per Joshy's email
            pu.FundAssetClass__c = 		currCampaign.Investment_Vehicle__r.Platform__c;
            pu.FundExternalId__c = 		currCampaign.Investment_Vehicle__r.Id;
            //Todo based on campaign type
            if (currCampaign.Room_type__c == 'Prospect Specific'){
                Account a = accounts.get(currCampaign.Account__c);
                pu.InvestorName__c = a.Name;
                pu.InvestorExternalId__c = a.Id;
            }
            else if (currCampaign.Room_type__c == 'Sleeve') {
                Fund_Vehicle__c sleeve = sleeves.get(currCampaign.Sleeve__c);
                pu.InvestorName__c = sleeve.Name;
                pu.InvestorExternalId__c = sleeve.Id;
            }
            else {
                pu.InvestorName__c = '';
                pu.InvestorExternalId__c = '';
            }
            pu.Community__c = commNameMapping.Name__c;        
            pu.GroupName__c = 'All Documents';
            
            pu.GroupAccess__c = false;// So that NO access need to be provided.            
            pu.GroupNotification__c = false;          
            pu.GroupStartDate__c = null;
            pu.GroupEndDate__c = null;
            
            fundUpdates.add(pu);
            System.Debug('fundUpdates ---' + fundUpdates); 
        }
        try{
         insert fundUpdates;
        if(contactToUpdate.size() >0){
                 System.debug('Updating Contact---' + contactToUpdate);
                 update contactToUpdate;
             }
        }
        catch (exception e) {
                
                system.debug('#### Exception caught: ' + e.getMessage());                
            }
        
    }   
}