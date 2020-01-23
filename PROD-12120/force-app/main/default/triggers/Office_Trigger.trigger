trigger Office_Trigger on Office__c (after insert, before update, after update, after delete) {
    //=========================================================================
    // FEATURE SUPPORT
    //=========================================================================
    private static final string FEATURE_ALL = 'Office.Trigger';
    private static final string FEATURE_ROLLUP_RULE = 'Office.Trigger.RollupRule';
    private static final string FEATURE_ROLLUP_RULE_PARENT = 'Office.Trigger.RollupRuleParent';

    private static final string FEATURE_TRIGGER_AI = 'Office.Trigger.AI';
    private static final string FEATURE_TRIGGER_BU = 'Office.Trigger.BU';
    private static final string FEATURE_TRIGGER_AU = 'Office.Trigger.AU';
    private static final string FEATURE_TRIGGER_AD = 'Office.Trigger.AD';

    if (!Common_Feature.isEnabled(FEATURE_ALL))
        return;

    Trigger_Rollup_Handler rollupHandler = new Trigger_Rollup_Handler();

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
            if (Common_Feature.isEnabled(FEATURE_ROLLUP_RULE_PARENT)) {
                rollupHandler.forceParentRollup(trigger.oldMap, sObjectName);
            }
        }
    }
}