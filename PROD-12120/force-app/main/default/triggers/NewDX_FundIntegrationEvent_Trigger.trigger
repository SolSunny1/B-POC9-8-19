trigger NewDX_FundIntegrationEvent_Trigger on DX_FundIntegration__e (after insert) {
    NewDX_FundIntegration_Handler fundEventHandler = new NewDX_FundIntegration_Handler();
     if (Trigger.isInsert) {
        if (Trigger.isAfter) { 
            System.debug('NewDX_FundIntegration_Trigger ---- ');            
               fundEventHandler.CreateFundInvestorUpdate(Trigger.new);            
        }
     }
    
}