public class Vehicle_Handler {
    public void CreateDX_FundIntegrationEventsForFunds(List<Investment_Vehicle__c> lstIV) {
        List<DX_FundIntegration__e> ivEventlst = new List<DX_FundIntegration__e>();
        for(Investment_Vehicle__c iv : lstIV){
            System.debug('Iv in insert  ' + iv);
        	if (iv.DX_Integration__c == 'Active' || iv.DX_Integration__c =='Planned'){
           		DX_FundIntegration__e iv_event = new DX_FundIntegration__e(Fund_Id__c = iv.Id,
                                                                          Fund_Name__c = iv.Name,
                                                                          DX_IntegrationStatus__c = iv.DX_Integration__c);
             	ivEventlst.add(iv_event);
            }
             
            System.debug('publishing ' + ivEventlst.size() + ' fund events');
            if (ivEventlst.size() > 0){
                List<Database.SaveResult> results = EventBus.publish(ivEventlst);

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
    
    public void CreateDX_FundIntegrationEventsForInvestor(Map<id,Account_Vehicle__c> mapAV) {
        List<DX_FundIntegration__e> avEventlst = new List<DX_FundIntegration__e>();      
        // Legal Entity and their corrosponding Funds from Commitment 
         System.debug('in legal entity trigger ' + mapAV.size() );
        for(Finaccount__c c : [Select id,name,Investment_Vehicle__r.id,Account_Vehicle__r.id,Account_Vehicle__r.Legal_Entity_Legal_Name__c,Investment_Vehicle__r.DX_Integration__c,Investment_Vehicle__r.Name from Finaccount__c 
                               					where Account_Vehicle__r.id IN : mapAV.keyset() 
                                             	and Investment_Vehicle__r.DX_Integration__c IN: new List<String>{'Active','Planned'}]){
           
            DX_FundIntegration__e av_event = new DX_FundIntegration__e(LegalEntity_Id__c 		= c.Account_Vehicle__r.id,
                                                                       LegalEntity_Name__c 		= c.Account_Vehicle__r.Legal_Entity_Legal_Name__c,
                                                                       Fund_Id__c 				= c.Investment_Vehicle__r.id,
                                                                       Fund_Name__c 			= c.Investment_Vehicle__r.Name,
                                                                       DX_IntegrationStatus__c 	= c.Investment_Vehicle__r.DX_Integration__c,
                                                                       Commitment_Id__c = c.Id);
                    avEventlst.add(av_event);                                        
            }
            System.debug('publishing ' + avEventlst.size() + ' Investor events');
            if (avEventlst.size() > 0){
                List<Database.SaveResult> results = EventBus.publish(avEventlst);

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

    
    
    public void UpdateFunds(List<Investment_Vehicle__c> lstIV) { 
        Set<Investment_Vehicle__c> IVSet = new Set<Investment_Vehicle__c>();
        Set<Investment_Vehicle__c> IV_CommitmentSet = new Set<Investment_Vehicle__c>();
        List<DX_FundIntegration__e> avEventlst = new List<DX_FundIntegration__e>();
        List<Permission_Event__e> lstPermissionPlatformEvents = new List<Permission_Event__e>();
        for(Investment_Vehicle__c iv : lstIV){
            System.debug('IV in update campaign ' + iv);
            Investment_Vehicle__c oldIV = (Investment_Vehicle__c)Trigger.OldMap.get(IV.Id);
             System.debug('oldIV--- ' + oldIV +'New Value --'+ iv.DX_Integration__c);
            if (oldIV != null && oldIV.DX_Integration__c != iv.DX_Integration__c)
            {
           		 if(iv.DX_Integration__c == 'Active' || iv.DX_Integration__c == 'Planned')
                 {
                    if(iv.DX_Integration__c == 'Active'){
                        IVSet.add(iv) ;
                     }
                    IV_CommitmentSet.add(iv);
                 }
            }
        }
         System.debug('IVSet----'+ IVSet);
        
        //Send commitments to FISDX when IV DX_Integration__c changes to Planned or Active
        if(IV_CommitmentSet.size() > 0) {
            for(Finaccount__c c : [Select id,name,Investment_Vehicle__r.id,Account_Vehicle__r.id,Account_Vehicle__r.Name,Investment_Vehicle__r.DX_Integration__c,Investment_Vehicle__r.Name from Finaccount__c 
                               					where Investment_Vehicle__r.id IN : IV_CommitmentSet 
                                             	and Investment_Vehicle__r.DX_Integration__c IN: new List<String>{'Active','Planned'}]){
           
            DX_FundIntegration__e av_event = new DX_FundIntegration__e(LegalEntity_Id__c 		= c.Account_Vehicle__r.id,
                                                                       LegalEntity_Name__c 		= c.Account_Vehicle__r.Name,
                                                                       Fund_Id__c 				= c.Investment_Vehicle__r.id,
                                                                       Fund_Name__c 			= c.Investment_Vehicle__r.Name,
                                                                       DX_IntegrationStatus__c 	= c.Investment_Vehicle__r.DX_Integration__c,
                                                                       Commitment_Id__c = c.Id);
                    avEventlst.add(av_event);                                        
            }
            System.debug('publishing ' + avEventlst.size() + ' Commitments detials from IV');
            if (avEventlst.size() > 0){
                List<Database.SaveResult> results = EventBus.publish(avEventlst);

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
        
        //Send permissions to FISDX when IV DX_Integration__c changes to Active 
        if(IVSet.size() >0)
        {
            for (Permission__c permission : [select Id, Contact__c, Contact__r.Email,Contact__r.DX_Email__c, Fund__c, Permission_Type__c from Permission__c where Fund__c IN : IVSet]) {
                    lstPermissionPlatformEvents.add(new Permission_Event__e(
                            Contact_Email__c = permission.Contact__r.DX_Email__c,
                            Contact_Id__c = permission.Contact__c,
                            Fund_Id__c = permission.Fund__c,
                            Investment_Account_Id__c = '',
                            Investment_Id__c = '',
                            Permission_Id__c = permission.Id,
                            Permission_Type__c = permission.Permission_Type__c
                    ));
            }
            System.debug('lstPermissionPlatformEvents-----  ' + lstPermissionPlatformEvents);
             if (lstPermissionPlatformEvents.size() > 0) {
                    // Call method to publish events
                    List<Database.SaveResult> results = EventBus.publish(lstPermissionPlatformEvents);
                    // Inspect publishing result for each event
                    for (Database.SaveResult sr : results) {
                        if (sr.isSuccess()) {
                            System.debug('Successfully published event lstPermissionPlatformEvents.');
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
}