trigger Coverage_Trigger on Coverage__c (after insert, before update, after update, after delete) {
    //=========================================================================
    // FEATURE SUPPORT
    // Updated on 11/13/2019 for ticket #SF-969
    // Never Disable FEATURE_ALL in Custom metedata else it will not execute Code for Ticket #SF-969
    //=========================================================================
    private static final string FEATURE_ALL = 'Coverage.Trigger';
    private static final string FEATURE_ROLLUP_RULE = 'Coverage.Trigger.RollupRule';
    private static final string FEATURE_ROLLUP_RULE_PARENT = 'Coverage.Trigger.RollupRuleParent';
    private static final string FEATURE_COVERAGE_ACCOUNT = 'Coverage.Trigger.CoverageAccount';

    private static final string FEATURE_TRIGGER_AI = 'Coverage.Trigger.AI';
    private static final string FEATURE_TRIGGER_BU = 'Coverage.Trigger.BU';
    private static final string FEATURE_TRIGGER_AU = 'Coverage.Trigger.AU';
    private static final string FEATURE_TRIGGER_AD = 'Coverage.Trigger.AD';
    

    if (!Common_Feature.isEnabled(FEATURE_ALL))
        return;

    Trigger_Rollup_Handler rollupHandler = new Trigger_Rollup_Handler();
    //Changes Start- For ticket #SF-969
    Coverage_Handler coverageHandler =  new Coverage_Handler();
    //Changes End

    private String sObjectName;
    if (trigger.new != null)
        sObjectName = trigger.new.get(0).getSObjectType().getDescribe().getName();
    else
            sObjectName = trigger.old.get(0).getSObjectType().getDescribe().getName();

    //=========================================================================
    // INSERT
    //=========================================================================
    if(Trigger.isInsert){
        if (Trigger.isAfter && Common_Feature.isEnabled(FEATURE_TRIGGER_AI)){
            if (Common_Feature.isEnabled(FEATURE_ROLLUP_RULE_PARENT)){
                rollupHandler.forceParentRollup(trigger.newMap, sObjectName);
            }
        }
    }

    //=========================================================================
    // UPDATE
    //=========================================================================
    if(Trigger.isUpdate){
        if(Trigger.isBefore && Common_Feature.isEnabled(FEATURE_TRIGGER_BU)){
            if(Common_Feature.isEnabled(FEATURE_ROLLUP_RULE)){
                rollupHandler.rollup(trigger.newMap, sObjectName);
            }
        }

        if (Trigger.isAfter && Common_Feature.isEnabled(FEATURE_TRIGGER_AU)){
            if (Common_Feature.isEnabled(FEATURE_ROLLUP_RULE_PARENT)){
                rollupHandler.forceParentRollup(trigger.newMap, sObjectName);
            }
        }
    }

    //=========================================================================
    // DELETE
    //=========================================================================
   
    if(Trigger.isDelete){        
        
        if (Trigger.isAfter && Common_Feature.isEnabled(FEATURE_TRIGGER_AD)){
            //Changes Start- For ticket #SF-969
        	if (Common_Feature.isEnabled(FEATURE_COVERAGE_ACCOUNT)){
        		coverageHandler.updateCoverageOnAccount(Trigger.Old);   
        		}
        	//Changes End
            if (Common_Feature.isEnabled(FEATURE_ROLLUP_RULE_PARENT)) {
                rollupHandler.forceParentRollup(trigger.oldMap, sObjectName);
            }
        }
    }
}