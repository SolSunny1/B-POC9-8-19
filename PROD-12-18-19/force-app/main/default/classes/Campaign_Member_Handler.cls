public with sharing class Campaign_Member_Handler {
public void deleteCMIntegration(List<CampaignMember> lstCampaignMember) {  
    List<Fundraising_Campaign_Member_Event__e> fcmel = new List<Fundraising_Campaign_Member_Event__e>();
    Set<id> campaignIds = new Set<id>();
    Set<id> contactIds = new Set<id>();
        
        for (CampaignMember cm : lstCampaignMember)
        {
            campaignIds.add(cm.CampaignId);             
        }
        
        Map<id, Campaign> campaigns = new Map<id, Campaign>([SELECT Id, Name,recordtypeid, Status, IsActive FROM Campaign WHERE Id in:campaignIds]);
        
        for (CampaignMember cm : lstCampaignMember)
        {
            Campaign c = campaigns.get(cm.CampaignId);
            
            if (Schema.SObjectType.Campaign.getRecordTypeInfosById().get(c.recordtypeid).getname().equals('Brookfield Diligence Portal')
                && (c.Status == 'Active' || c.Status == 'Planned')) 
            {
                System.debug('Raising Fundraising_Campaign_Member_Event__e for ' + cm.Id + ' ' + cm.Name);
                Fundraising_Campaign_Member_Event__e ce = new Fundraising_Campaign_Member_Event__e(Campaign_Member_Id__c = cm.Id,
                                            		 Campaign_Id__c = cm.CampaignId, Contact_Id__c = cm.ContactId, IsDelete__c = true);
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
}