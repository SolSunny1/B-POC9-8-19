trigger Permission_Trigger on Permission__c (after insert, after update, before update, after delete) {
    //=========================================================================
    // FEATURE SUPPORT
    //=========================================================================
    private static final string FEATURE_ALL = 'Permission.Trigger';
    private static final string FEATURE_CREATE_PLATFORM_EVENTS = 'Permission.Trigger.PlatformEvent';
    private static final string FEATURE_ROLLUP_RULE = 'Permission.Trigger.RollupRule';
    private static final string FEATURE_ROLLUP_RULE_PARENT = 'Permission.Trigger.RollupRuleParent';
    
    private static final string FEATURE_TRIGGER_AI = 'Permission.Trigger.AI';
    private static final string FEATURE_TRIGGER_BU = 'Permission.Trigger.BU';
    private static final string FEATURE_TRIGGER_AU = 'Permission.Trigger.AU';
    private static final string FEATURE_TRIGGER_AD = 'Permission.Trigger.AD';

    if (!Common_Feature.isEnabled(FEATURE_ALL))
        return;

    Permission_Handler permissionHandler = new Permission_Handler();
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
    if (Trigger.isInsert) {
        if (Trigger.isAfter && Common_Feature.isEnabled(FEATURE_TRIGGER_AI)){
            if (Common_Feature.isEnabled(FEATURE_ROLLUP_RULE_PARENT)){
                rollupHandler.forceParentRollup(trigger.newMap, SObjectName);
            }
            if (Common_Feature.isEnabled(FEATURE_CREATE_PLATFORM_EVENTS)) {
                permissionHandler.createPlatformEvents(Trigger.new);
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
            if (Common_Feature.isEnabled(FEATURE_CREATE_PLATFORM_EVENTS)) {
                permissionHandler.createPlatformEvents(Trigger.new);
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