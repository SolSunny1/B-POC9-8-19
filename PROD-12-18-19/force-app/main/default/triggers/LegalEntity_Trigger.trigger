trigger LegalEntity_Trigger on Account_Vehicle__c (after insert,after update) {
     Vehicle_Handler vHandler = new Vehicle_Handler();
     if (Trigger.isInsert ) {
        if (Trigger.isAfter ) { 
            System.debug('LegalEntity_Trigger insert--- ');
            vHandler.CreateDX_FundIntegrationEventsForInvestor(Trigger.NewMap);            
        }
     }
    if(Trigger.isUpdate){
        if (Trigger.isAfter ) { 
             vHandler.CreateDX_FundIntegrationEventsForInvestor(Trigger.NewMap);
            
            //IVHandler.UpdateDX_FundIntegrationEvents(Trigger.new);
        }        
    }
}