public with sharing class Campaign_Handler {   
    //This Handler is used to create Platform event on Campaign and Campaign Members for Fundraising.
    //Referenced trigger is : Campaign_Trigger 
    //Created to seperate the event pulish logic from trigger
    public void CreateFundraisingCampaignEvents(List<Campaign> lstCampaign) {
        List<Fundraising_Campaign_Event__e> fcel = new List<Fundraising_Campaign_Event__e>();
        List<Campaign> campProspectSpecificLst = new List<Campaign>();
        List<Campaign> campSleeveLst = new List<Campaign>();
        for(Campaign c : lstCampaign)
        {
            System.debug('Campaign in insert campaign ' + c);
        	if (Schema.SObjectType.Campaign.getRecordTypeInfosById().get(c.recordtypeid).getname().equals('Brookfield Diligence Portal')
            &&  (c.Status == 'Active' || c.Status == 'Planned')) {
            	Fundraising_Campaign_Event__e ce = new Fundraising_Campaign_Event__e(Campaign_Id__c = c.Id,
                                                                                Campaign_Name__c = c.Name);
            	fcel.add(ce);                
            }
             
            System.debug('publishing ' + fcel.size() + ' fund events');
            if (fcel.size() > 0) {
                List<Database.SaveResult> results = EventBus.publish(fcel);

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
    public void CreateFundraisingCampaignMemberEvents(List<Campaign> lstCampaign) {
        set<Id> campaignsIdsForMemberEvent = new set<id>();
        List<Campaign> campToUpdateLst = new List<Campaign>();
        for(Campaign c : lstCampaign)
        {
            System.debug('Campaign in update campaign ' + c);
            Campaign oldC = (Campaign)Trigger.OldMap.get(c.Id);
            system.debug('oldStatus ' + oldC.Status + ' new status ' + c.Status);
             
            if (oldC != null && oldC.Status != c.Status )
            {
                if(c.Status == 'Planned')
                {
                    campToUpdateLst.add(c);
                }
                if(c.Status == 'Active')
                {
                	campaignsIdsForMemberEvent.add(c.Id);
                    campToUpdateLst.add(c);
                }
            }
        }
        system.debug('campToUpdateLst fund and commitment : ' + campToUpdateLst.size());
        CreateFundraisingCampaignEvents(campToUpdateLst);
        List<Fundraising_Campaign_Member_Event__e> fcmel = new List<Fundraising_Campaign_Member_Event__e>();

        system.debug('Nb Funds that must publish member events: ' + campaignsIdsForMemberEvent.size());
        if (campaignsIdsForMemberEvent.size() > 0)
        {
            List<CampaignMember> cms = [select Id, Name from CampaignMember where CampaignId in:campaignsIdsForMemberEvent];
            
            system.debug('looping through ' + cms.size() + ' members to publish event');
            for (CampaignMember cm : cms)
            {
                System.debug('Raising Fundraising_Campaign_Member_Event__e for ' + cm.Id + ' ' + cm.Name);
                Fundraising_Campaign_Member_Event__e ce = new Fundraising_Campaign_Member_Event__e(Campaign_Member_Id__c = cm.Id,
                                                                                    Campaign_Member_Name__c = cm.Name);
                fcmel.add(ce);
            }
        }
        System.debug('publishing ' + fcmel.size() + ' permission events');
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
    
    
    
   /* public void checkDuplicateCampaignForFund(List<Campaign> lstCampaign) {   
        Set<String> CampaignFundLst =  new Set<String>();
        for(Campaign c : lstCampaign){
            if (Schema.SObjectType.Campaign.getRecordTypeInfosById().get(c.recordtypeid).getname().equals('Brookfield Diligence Portal')
            && c.Room_Type__c == 'Fund' && c.Type == 'Fundraising Permissions'){
                CampaignFundLst.add(c.Investment_Vehicle__c);
            }
        }        
        Map<string,string> CampIdMap = new Map<string,string>();
       	for(Campaign duplicateCamp : [Select id,Name,Room_Type__c,Investment_Vehicle__c from campaign where Investment_Vehicle__c IN: CampaignFundLst and Id Not IN :lstCampaign and Room_Type__c = 'Fund']){
                CampIdMap.put(duplicateCamp.id,duplicateCamp.Investment_Vehicle__c);                
           }        
        for(Campaign camp : lstCampaign){            
               if((CampIdMap.Size()>0)) {    
               camp.addError('Duplicate Error:Campaign with Investment Vehilcle alredy exist',false);
            }
        } 
}*/
}