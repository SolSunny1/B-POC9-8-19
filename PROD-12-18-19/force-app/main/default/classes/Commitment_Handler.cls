public class Commitment_Handler {
    public void CreateCommitmentUpdate(List<FinAccount__c> lstCommitment) {
        List<DX_FundIntegration__e> avEventlst = new List<DX_FundIntegration__e>();      
        // Legal Entity and their corrosponding Funds from Commitment 
         System.debug('in Commitment trigger ' + lstCommitment );
        for(Finaccount__c c : [Select id,name,Investment_Vehicle__r.id,Account_Vehicle__r.id,Account_Vehicle__r.Name,Investment_Vehicle__r.DX_Integration__c,Investment_Vehicle__r.Name from Finaccount__c 
                               					where id IN : lstCommitment
                                             	and Investment_Vehicle__r.DX_Integration__c IN: new List<String>{'Active','Planned'}]){
           
            DX_FundIntegration__e av_event = new DX_FundIntegration__e(LegalEntity_Id__c 		= c.Account_Vehicle__r.id,
                                                                       LegalEntity_Name__c 		= c.Account_Vehicle__r.Name,
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
}