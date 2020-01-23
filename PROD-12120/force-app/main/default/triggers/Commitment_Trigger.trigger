trigger Commitment_Trigger on FinAccount__c (after insert, before update, after update, after delete) {
    //=========================================================================
    // FEATURE SUPPORT
    //=========================================================================
    private static final string FEATURE_ALL = 'Commitment.Trigger';
    private static final string FEATURE_ROLLUP_RULE = 'Commitment.Trigger.RollupRule';
    private static final string FEATURE_ROLLUP_RULE_PARENT = 'Commitment.Trigger.RollupRuleParent';
    private static final string FEATURE_DXIntegartion = 'Commitment.DXIntegartion';

    private static final string FEATURE_TRIGGER_AI = 'Commitment.Trigger.AI';
    private static final string FEATURE_TRIGGER_BU = 'Commitment.Trigger.BU';
    private static final string FEATURE_TRIGGER_AU = 'Commitment.Trigger.AU';
    private static final string FEATURE_TRIGGER_AD = 'Commitment.Trigger.AD';

    if (!Common_Feature.isEnabled(FEATURE_ALL))
        return;

    Trigger_Rollup_Handler rollupHandler = new Trigger_Rollup_Handler();
    Commitment_Handler commitmentHandler = new Commitment_Handler();

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
            //Added for DX Integartion
            if (Common_Feature.isEnabled(FEATURE_DXIntegartion)){
                commitmentHandler.CreateCommitmentUpdate(trigger.new);
            }
        }
    }

    //=========================================================================
    // DELETE
    //=========================================================================
    if(Trigger.isDelete){
        if (Trigger.isAfter && Common_Feature.isEnabled(FEATURE_TRIGGER_AD)){
            if (Common_Feature.isEnabled(FEATURE_ROLLUP_RULE_PARENT)) {
                rollupHandler.forceParentRollup(trigger.oldMap, sObjectName);
            }
        }
    }
}