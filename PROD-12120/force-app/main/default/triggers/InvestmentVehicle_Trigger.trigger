trigger InvestmentVehicle_Trigger on Investment_Vehicle__c (after insert,after update) {
    //=========================================================================
    // FEATURE SUPPORT
    //=========================================================================
    private static final string FEATURE_ALL = 'InvestmentVehicle.Trigger';
    
    private static final string FEATURE_TRIGGER_AI = 'InvestmentVehicle.Trigger.AI';
    private static final string FEATURE_TRIGGER_AU = 'InvestmentVehicle.Trigger.AU';
    
    if (!Common_Feature.isEnabled(FEATURE_ALL))
        return;
    
    Vehicle_Handler IVHandler = new Vehicle_Handler();
     if (Trigger.isInsert ) {
        if (Trigger.isAfter && Common_Feature.isEnabled(FEATURE_TRIGGER_AI)) { 
            System.debug('InvestmentVehicle_Trigger insert--- ');
            IVHandler.CreateDX_FundIntegrationEventsForFunds(Trigger.new);            
        }
     }
    if(Trigger.isUpdate){
        if (Trigger.isAfter && Common_Feature.isEnabled(FEATURE_TRIGGER_AU) ) { 
             IVHandler.CreateDX_FundIntegrationEventsForFunds(Trigger.new);            
             IVHandler.UpdateFunds(Trigger.new);
        }        
    }
}