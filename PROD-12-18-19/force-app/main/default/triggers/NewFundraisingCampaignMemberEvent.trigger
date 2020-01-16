trigger NewFundraisingCampaignMemberEvent on Fundraising_Campaign_Member_Event__e (after insert) {
    
    //=========================================================================
    // FEATURE SUPPORT
    //=========================================================================
    
    private static final string FEATURE_ALL = 'Fundraising_Campaign_Member_Event.Trigger';
    private static final string FEATURE_DELETE_CAMPAIGN_MEMBER = 'Fundraising_Campaign_Member_Event.Trigger.DeleteCampaignMember';
	   
    if (!Common_Feature.isEnabled(FEATURE_ALL))
        return;
	final string COMMUNITYNAME = 'FundraisingCommunityName';
    List<Fundraising_Campaign_Member_Event__e> lstToDelete = new List<Fundraising_Campaign_Member_Event__e>();
    NewFundCampMemberEvent_Handler eventhandler = new NewFundCampMemberEvent_Handler();
    Set<id> campaignMemberIds = new Set<id>();
    for (Fundraising_Campaign_Member_Event__e event : Trigger.New)    {
        	campaignMemberIds.add(event.Campaign_Member_Id__c);
            //List of Members getting deleted
            if(event.IsDelete__c == true){
                lstToDelete.add(event);
            }
    }
    if(lstToDelete.size()>0 && Common_Feature.isEnabled(FEATURE_DELETE_CAMPAIGN_MEMBER))    {
		eventhandler.deleteCampaignMemberFromDX(lstToDelete);    	
    }
    //Missing permission and alert
    List<CampaignMember> campaignMembers = [select Id, Name, contactId, CampaignId, Status,campaign.Investment_Vehicle__r.id,campaign.Room_Type__c from CampaignMember where Id in:campaignMemberIds];
    set<id> campaignIds = new Set<id>();
    set<id> contactIds = new Set<id>();   
    List<CampaignMember> membToDelete = new List<CampaignMember>();
    for (CampaignMember cm : campaignMembers) {
        campaignIds.add(cm.CampaignId);
        contactIds.add(cm.ContactId);        
    }
     
    Map<id, Campaign> campaigns = new Map<id, Campaign>([select Id, Name, Investment_Vehicle__r.Id, Investment_Vehicle__r.Name, Investment_Vehicle__r.Platform__c, status, Room_Type__c, Sleeve__c, Account__c  from Campaign where Id in:campaignIds]);
    Map<id, Contact> contacts = new Map<id, Contact>([select id, name, DX_Email__c, Email, FirstName, LastName from Contact where id in:contactIds]);
       
    Set<id> accountIds = new Set<id>();
    Set<id> sleeveIds = new Set<id>();
    
    for (Campaign c:campaigns.values()){
        if (c.Room_type__c == 'Prospect Specific') {
            accountIds.add(c.Account__c);
        }
        else if (c.Room_type__c == 'Sleeve'){
            sleeveIds.add(c.Sleeve__c);
        }
    }
    
    Map<id, Account> accounts = new Map<id, Account>([select Id, Name from Account where Id in:accountIds]);
    Map<id, Fund_Vehicle__c> sleeves = new Map<id, Fund_Vehicle__c>([select Id, Name from Fund_Vehicle__c where Id in:sleeveIds]);
    
    List<PermissionUpdate__c> fundUpdates = new List<PermissionUpdate__c>();
    //Calling to get data from MetaData Setup -SOQL does not count under Governance Limit 
    CommunityName__mdt commNameMapping = [Select Name__c from CommunityName__mdt where MasterLabel =: COMMUNITYNAME];
    System.debug('toInsert count ' + campaignMembers.size());
	List<Contact> contactToUpdate = new List<Contact>();
    for (CampaignMember cm : campaignMembers) {
        System.debug('ContactMember name ' + cm.Name);
        Contact c = contacts.get(cm.ContactId);
        Campaign camp = campaigns.get(cm.CampaignId);
        
        PermissionUpdate__c pu = new PermissionUpdate__c();
        System.debug('Contact Email ' + c.Email);
        System.debug('Contact DXEmail ' + c.DX_Email__c);
        //Todo de-activation is done on the contact record. Need the flag created
        pu.ContactActive__c = true;//Contact will always go as Active as we have to ignore the Status of contacts
        pu.ContactFirstName__c = c.FirstName;
        pu.ContactLastName__c = c.LastName;
        if(c.DX_Email__c != null && c.DX_Email__c !='')
        {
       		pu.ContactEmail__c = c.DX_Email__c;
        }
        else
        {
         	pu.ContactEmail__c =c.Email;
            c.DX_Email__c = c.Email;
            contactToUpdate.add(c);
        }
        
        pu.ContactExternalId__c = c.Id;
        pu.FundName__c = camp.Investment_Vehicle__r.Name;
        //TODO, map properly as per Joshy's email
        pu.FundAssetClass__c = camp.Investment_Vehicle__r.Platform__c;
        pu.FundExternalId__c = camp.Investment_Vehicle__r.Id;
        
        //Todo based on campaign type
        if (camp.Room_type__c == 'Prospect Specific'){
            Account a = accounts.get(camp.Account__c);
            pu.InvestorName__c = a.Name;
            pu.InvestorExternalId__c = a.Id;
        }
        else if (camp.Room_type__c == 'Sleeve'){
            Fund_Vehicle__c sleeve = sleeves.get(camp.Sleeve__c);
            pu.InvestorName__c = sleeve.Name;
            pu.InvestorExternalId__c = sleeve.Id;
        }
        else {
            pu.InvestorName__c = '';
            pu.InvestorExternalId__c = '';
        }
        pu.Community__c = commNameMapping.Name__c;
        
        pu.GroupName__c = 'All Documents';
        pu.GroupAccess__c = camp.Status == 'Active' && cm.Status == 'Invited';// To get access, the campaign must be active and the member status must be Invited
        //TODO Cloud Theory to add flag to contact
        pu.GroupNotification__c = camp.Status == 'Active' && cm.Status == 'Invited'; 
        //Todo - did Elsie agree to add end date?
        pu.GroupStartDate__c = null;
        pu.GroupEndDate__c = null;
        
        fundUpdates.add(pu);       
    }
    try{        
    	insert fundUpdates;
    	if(contactToUpdate.size() >0)
         {
             System.debug('Updating Contact---' + contactToUpdate);
             update contactToUpdate;
         }      
    
    }
    catch (exception e) {                
                system.debug('#### Exception caught: ' + e.getMessage());                
            }
}