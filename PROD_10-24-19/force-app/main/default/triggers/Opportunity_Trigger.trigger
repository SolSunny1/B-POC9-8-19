trigger Opportunity_Trigger on Opportunity (after insert, before update, after update, after delete) {
    //=========================================================================
    // FEATURE SUPPORT
    //=========================================================================
    private static final string FEATURE_ALL = 'Opportunity.Trigger';
    private static final string FEATURE_ROLLUP_RULE = 'Opportunity.Trigger.RollupRule';
    private static final string FEATURE_ROLLUP_RULE_PARENT = 'Opportunity.Trigger.RollupRuleParent';
    private static final string FEATURE_CONSULTANT_RELATIONSHIP = 'Opportunity.Trigger.ConsultantRel';
    private static final string FEATURE_FIELD_CONSULTANT_RELATIONSHIP = 'Opportunity.Trigger.FConsultantRel';
    private static final string FEATURE_RESEARCH_CONSULTANT_RELATIONSHIP = 'Opportunity.Trigger.RConsultantRel';

    private static final string FEATURE_TRIGGER_AI = 'Opportunity.Trigger.AI';
    private static final string FEATURE_TRIGGER_BU = 'Opportunity.Trigger.BU';
    private static final string FEATURE_TRIGGER_AU = 'Opportunity.Trigger.AU';
    private static final string FEATURE_TRIGGER_AD = 'Opportunity.Trigger.AD';

    if (!Common_Feature.isEnabled(FEATURE_ALL))
        return;

    Opportunity_Handler objHandler = new Opportunity_Handler();
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
            if (Common_Feature.isEnabled(FEATURE_CONSULTANT_RELATIONSHIP)){
                objHandler.createConsultantRelationship(trigger.new);
            }
            if (Common_Feature.isEnabled(FEATURE_FIELD_CONSULTANT_RELATIONSHIP)){
                objHandler.createFieldConsultantRelationship(trigger.new);
            }
            if (Common_Feature.isEnabled(FEATURE_RESEARCH_CONSULTANT_RELATIONSHIP)){
                objHandler.createResearchConsultantRelationship(trigger.new);
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
            if (Common_Feature.isEnabled(FEATURE_CONSULTANT_RELATIONSHIP)){
                objHandler.createConsultantRelationship(trigger.new);
            }
            if (Common_Feature.isEnabled(FEATURE_FIELD_CONSULTANT_RELATIONSHIP)){
                objHandler.createFieldConsultantRelationship(trigger.new);
            }
            if (Common_Feature.isEnabled(FEATURE_RESEARCH_CONSULTANT_RELATIONSHIP)){
                objHandler.createResearchConsultantRelationship(trigger.new);
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