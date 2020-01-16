trigger ContactTrigger on Contact (after insert, before update, after update, after delete) {
	
    //=========================================================================
    // FEATURE SUPPORT
    //=========================================================================
    private static final String FEATURE_ALL = 'Contact.Trigger';
    private static final string FEATURE_ROLLUP_RULE = 'Contact.Trigger.RollupRule';
    private static final string FEATURE_ROLLUP_RULE_PARENT = 'Contact.Trigger.RollupRuleParent';
    
    private static final string FEATURE_TRIGGER_AI = 'Contact.Trigger.AI';
    private static final string FEATURE_TRIGGER_BU = 'Contact.Trigger.BU';
    private static final string FEATURE_TRIGGER_AU = 'Contact.Trigger.AU';
    private static final string FEATURE_TRIGGER_AD = 'Contact.Trigger.AD';
    
    if (!Common_Feature.isEnabled(FEATURE_ALL))
        return;
    
    Trigger_Rollup_Handler rollupHandler = new Trigger_Rollup_Handler();
    
    private String SObjectName;
    if(Trigger.new != null) {
        SObjectName = trigger.new.get(0).getSObjectType().getDescribe().getName();
    } else {
        SObjectName = trigger.old.get(0).getSObjectType().getDescribe().getName();
    }
    
    //=========================================================================
    // INSERT
    //=========================================================================
    if(Trigger.isInsert){
        if (Trigger.isAfter && Common_Feature.isEnabled(FEATURE_TRIGGER_AI)){
            if (Common_Feature.isEnabled(FEATURE_ROLLUP_RULE_PARENT)){
                rollupHandler.forceParentRollup(trigger.newMap, SObjectName);
            }
        }
    }

    //=========================================================================
    // UPDATE
    //=========================================================================
    if(Trigger.isUpdate){
        if(Trigger.isBefore && Common_Feature.isEnabled(FEATURE_TRIGGER_BU)){
            if(Common_Feature.isEnabled(FEATURE_ROLLUP_RULE)){
                rollupHandler.rollup(trigger.newMap, SObjectName);
            }
        }

        if (Trigger.isAfter && Common_Feature.isEnabled(FEATURE_TRIGGER_AU)){
            if (Common_Feature.isEnabled(FEATURE_ROLLUP_RULE_PARENT)){
                rollupHandler.forceParentRollup(trigger.newMap, SObjectName);
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