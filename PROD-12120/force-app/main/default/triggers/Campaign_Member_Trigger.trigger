trigger Campaign_Member_Trigger on CampaignMember (after insert, after update,after delete) {
    System.debug('Starting Campaign_Member_Trigger');
	List<Fundraising_Campaign_Member_Event__e> fcmel = new List<Fundraising_Campaign_Member_Event__e>();
    if(Trigger.isInsert || Trigger.isUpdate ){
        Set<id> campaignIds = new Set<id>();
        
        for (CampaignMember cm : Trigger.New)
        {
            campaignIds.add(cm.CampaignId);
            
        }
        
        Map<id, Campaign> campaigns = new Map<id, Campaign>([SELECT Id, Name, recordtypeid, Status, IsActive FROM Campaign WHERE Id in:campaignIds]);
        
        for (CampaignMember cm : Trigger.New)
        {
            Campaign c = campaigns.get(cm.CampaignId);
            
            if (Schema.SObjectType.Campaign.getRecordTypeInfosById().get(c.recordtypeid).getname().equals('Brookfield Diligence Portal')
                && (c.Status == 'Active')) 
            {
                System.debug('Raising Fundraising_Campaign_Member_Event__e for ' + cm.Id + ' ' + cm.Name);
                Fundraising_Campaign_Member_Event__e ce = new Fundraising_Campaign_Member_Event__e(Campaign_Member_Id__c = cm.Id,
                                                                                    Campaign_Member_Name__c = cm.Name);
                fcmel.add(ce);
            }
        }
        
        if (fcmel.size() > 0)
        {
            List<Database.SaveResult> results = EventBus.publish(fcmel);
    
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                    }
                }
            }
        }    
	}
     if(Trigger.isDelete)
     {
         system.debug('Its Delete');
         Campaign_Member_Handler CMHandler = new Campaign_Member_Handler();
         CMHandler.deleteCMIntegration(Trigger.Old);
         
     } 
}