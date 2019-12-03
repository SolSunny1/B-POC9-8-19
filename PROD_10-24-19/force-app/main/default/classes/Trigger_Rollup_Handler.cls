public with sharing class Trigger_Rollup_Handler{
    private static final String HTML_ANCHOR_START_LEFT = '<a href="/';
    private static final String HTML_ANCHOR_START_RIGHT = '" target="_self">';
    private static final String HTML_ANCHOR_END = '</a>';
    private static final String TYPE_DELIMITED = 'DelimitedList';
    private static final String TYPE_NUMBER = 'NumberRollup';
    private static final String TYPE_MAX = 'Max';
    private static final String TYPE_MIN = 'Min';

    private static List<Trigger_Rollup_Rule__c> lstRollup;
    private static Map<String, Decimal> currencyConversionRates;

    private static Map<String, Set<Id>> processedRecords;

    public void rollup(Map<Id, sObject> sObjectMap, String objectName) {

        // Get Groups to prevent overlap
        GroupSettings groupSettings = new GroupSettings();
        groupSettings.load(objectName);

        system.debug('groupSettings.groupSettings.keySet(): ' + groupSettings.groupSettings.keySet());

        // Loop by group
        for (String settingGroup : groupSettings.groupSettings.keySet()) {
            system.debug('settingGroup: ' + settingGroup);
            system.debug('groupSettings.getType(settingGroup): ' + groupSettings.getType(settingGroup));

            if (groupSettings.getType(settingGroup) == TYPE_DELIMITED) {
                try {
                    rollupDelimitedList(sObjectMap, groupSettings.groupSettings.get(settingGroup));
                } catch (Exception e) {
                    sObjectMap.values()[0].addError('Error processing setting group: ' + settingGroup + '. Exception occurred:' + e.getMessage() + e.getStackTraceString());
                }
            } else if (groupSettings.getType(settingGroup) == TYPE_NUMBER) {
                try {
                    rollupNumber(sObjectMap, groupSettings.groupSettings.get(settingGroup));
                } catch (Exception e) {
                    sObjectMap.values()[0].addError('Error processing setting group: ' + settingGroup + '. Exception occurred:' + e.getMessage() + e.getStackTraceString());
                }
            } else if (groupSettings.getType(settingGroup) == TYPE_MAX || groupSettings.getType(settingGroup) == TYPE_MIN) {
                try {
                    rollupMaxMin(sObjectMap, groupSettings.groupSettings.get(settingGroup));
                } catch (Exception e) {
                    sObjectMap.values()[0].addError('Error processing setting group: ' + settingGroup + '. Exception occurred:' + e.getMessage() + e.getStackTraceString());
                }
            }
        }
    }

    private void rollupMaxMin(Map<Id, sObject> sObjectMap, GroupSetting groupSetting) {
        System.debug('********** START ROLLUP MAX/MIN LIST **********');
        List<Id> parentIds = new List<Id>(sObjectMap.keySet());
        String parentObjectName = groupSetting.rollupSettings[0].Object__c;
        Boolean checkForCurrencyConversion = UserInfo.isMultiCurrencyOrganization();
        Set<ID> currencyRollupSettings = new Set<ID>();

        Map<String, List<Trigger_Rollup_Rule__c>> childObjectGroupMap = new Map<String, List<Trigger_Rollup_Rule__c>>();
        for (Trigger_Rollup_Rule__c rollupSetting : groupSetting.rollupSettings){
            if(childObjectGroupMap.containsKey(rollupSetting.Child_Object__c)){
                childObjectGroupMap.get(rollupSetting.Child_Object__c).add(rollupSetting);
            } else {
                childObjectGroupMap.put(rollupSetting.Child_Object__c, new List<Trigger_Rollup_Rule__c>{rollupSetting});
            }
            if(checkForCurrencyConversion){
                Schema.DisplayType fieldType = getFieldDisplayType(rollupSetting.Child_Object__c, rollupSetting.Child_Field__c);
                if(fieldType == Schema.DisplayType.CURRENCY){
                    currencyRollupSettings.add(rollupSetting.Id);
                }
            }
        }

        Map<String, Common_QueryBuilder> queryMap = new Map<String, Common_QueryBuilder>();
        Set<String> parentFieldsToClear = new Set<String>();
        for(String childObjectName: childObjectGroupMap.keySet()){
            String childParentField;
            Common_QueryBuilder queryBuilder = new Common_QueryBuilder(childObjectName);
            for(Trigger_Rollup_Rule__c rollupSetting:childObjectGroupMap.get(childObjectName)){
                if(rollupSetting.Child_Max_Size__c != null){
                    queryBuilder.setRowLimit(Integer.valueOf(rollupSetting.Child_Max_Size__c));
                }

                parentFieldsToClear.add(rollupSetting.Field__c);
                if(!String.isBlank(rollupSetting.Field_RTF__c)){
                    parentFieldsToClear.add(rollupSetting.Field_RTF__c);
                }

                queryBuilder.addQueryField(rollupSetting.Type__c + '('+rollupSetting.Child_Field__c + ')' + rollupSetting.Id);
                queryBuilder.addQueryField(rollupSetting.Child_Parent_Field__c);
                if(String.isBlank(childParentField)){
                    childParentField = rollupSetting.Child_Parent_Field__c;
                }
                if(!String.isBlank(rollupSetting.Child_Parent_ID_Field__c)){
                    queryBuilder.addQueryField(rollupSetting.Child_Parent_ID_Field__c);
                }

                if(!String.isBlank(rollupSetting.Child_Query_Where_Clause__c)){
                    queryBuilder.extendWhereFilter(rollupSetting.Child_Query_Where_Clause__c, 'OR');
                }
            }
            queryBuilder.addWhereFilter(childParentField,parentIds,'IN');
            queryBuilder.addGroupField(childParentField);
            queryMap.put(childObjectName, queryBuilder);
        }


        for(String fieldName:parentFieldsToClear){
            Schema.DisplayType fieldType = getFieldDisplayType(parentObjectName, fieldName);
            for(sObject sObj:sObjectMap.values()){
                if (fieldType == Schema.DisplayType.INTEGER ||
                        fieldType == Schema.DisplayType.CURRENCY ||
                        fieldType == Schema.DisplayType.DOUBLE){
                    sObj.put(fieldName, 0);
                } else {
                    sObj.put(fieldName, null);
                }
            }
        }

        //everything in here has to be soft coded, as non of these fields/types exist in single currency orgs
        if(!currencyRollupSettings.isEmpty() && currencyConversionRates == null){
            currencyConversionRates = new Map<String, Decimal>();
            String currencyTypeQuery = 'select ISOCode, ConversionRate from CurrencyType where IsActive=true';
            for(sObject ct:Database.query(currencyTypeQuery)){
                currencyConversionRates.put((String)ct.get('ISOCode'), (Decimal)ct.get('ConversionRate'));
            }
        }

        for(String childObjectName:queryMap.keySet()){
            String query = queryMap.get(childObjectName).toString();
            system.debug('query: ' + query);
            for(sObject childRecord:Database.query(query)){
                for(Trigger_Rollup_Rule__c rollupSetting: childObjectGroupMap.get(childObjectName)){
                    String parentId = String.valueOf(childRecord.get(rollupSetting.Child_Parent_Field__c));
                    sObject parentRecord = sObjectMap.get(parentId);
                    Object aggregateValue = childRecord.get(rollupSetting.Id);


                    if(currencyRollupSettings.contains(rollupSetting.Id)){
                        aggregateValue = (Decimal)aggregateValue * currencyConversionRates.get(String.valueOf(parentRecord.get('CurrencyISOCode')));
                    }

                    Schema.DisplayType fieldType = getFieldDisplayType(rollupSetting.Object__c, rollupSetting.Field__c);

                    if (fieldType == Schema.DisplayType.INTEGER ||
                            fieldType == Schema.DisplayType.CURRENCY ||
                            fieldType == Schema.DisplayType.DOUBLE ||
                            fieldType == Schema.DisplayType.Date ||
                            fieldType == Schema.DisplayType.DateTime
                            ){
                        parentRecord.put(rollupSetting.Field__c, aggregateValue);
                    } else {
                        parentRecord.put(rollupSetting.Field__c, String.valueOf(aggregateValue));
                    }
                }
            }
        }
    }

    private void rollupNumber(Map<Id, sObject> sObjectMap, GroupSetting groupSetting) {
        System.debug('********** START ROLLUP NUMBER LIST **********');
        List<Id> parentIds = new List<Id>(sObjectMap.keySet());
        String parentObjectName = groupSetting.rollupSettings[0].Object__c;
        Boolean checkForCurrencyConversion = UserInfo.isMultiCurrencyOrganization();
        Set<ID> currencyRollupSettings = new Set<ID>();

        Map<String, List<Trigger_Rollup_Rule__c>> childObjectGroupMap = new Map<String, List<Trigger_Rollup_Rule__c>>();
        for (Trigger_Rollup_Rule__c rollupSetting : groupSetting.rollupSettings){
            if(childObjectGroupMap.containsKey(rollupSetting.Child_Object__c)){
                childObjectGroupMap.get(rollupSetting.Child_Object__c).add(rollupSetting);
            } else {
                childObjectGroupMap.put(rollupSetting.Child_Object__c, new List<Trigger_Rollup_Rule__c>{rollupSetting});
            }
            if(checkForCurrencyConversion){
                Schema.DisplayType fieldType = getFieldDisplayType(rollupSetting.Child_Object__c, rollupSetting.Child_Field__c);
                if(fieldType == Schema.DisplayType.CURRENCY){
                    currencyRollupSettings.add(rollupSetting.Id);
                }
            }
        }

        Map<String, Common_QueryBuilder> queryMap = new Map<String, Common_QueryBuilder>();
        Set<String> parentFieldsToClear = new Set<String>();
        for(String childObjectName: childObjectGroupMap.keySet()){
            String childParentField;
            Common_QueryBuilder queryBuilder = new Common_QueryBuilder(childObjectName);
            for(Trigger_Rollup_Rule__c rollupSetting:childObjectGroupMap.get(childObjectName)){
                if(rollupSetting.Child_Max_Size__c != null){
                    queryBuilder.setRowLimit(Integer.valueOf(rollupSetting.Child_Max_Size__c));
                }

                parentFieldsToClear.add(rollupSetting.Field__c);
                if(!String.isBlank(rollupSetting.Field_RTF__c)){
                    parentFieldsToClear.add(rollupSetting.Field_RTF__c);
                }

                queryBuilder.addQueryField(rollupSetting.Number_Rollup_Type__c + '('+rollupSetting.Child_Field__c + ')' + rollupSetting.Id);
                queryBuilder.addQueryField(rollupSetting.Child_Parent_Field__c);
                if(String.isBlank(childParentField)){
                    childParentField = rollupSetting.Child_Parent_Field__c;
                }
                if(!String.isBlank(rollupSetting.Child_Parent_ID_Field__c)){
                    queryBuilder.addQueryField(rollupSetting.Child_Parent_ID_Field__c);
                }

                if(!String.isBlank(rollupSetting.Child_Query_Where_Clause__c)){
                    queryBuilder.extendWhereFilter(rollupSetting.Child_Query_Where_Clause__c, 'OR');
                }
            }
            queryBuilder.addWhereFilter(childParentField,parentIds,'IN');
            queryBuilder.addGroupField(childParentField);
            queryMap.put(childObjectName, queryBuilder);
        }


        for(String fieldName:parentFieldsToClear){
            Schema.DisplayType fieldType = getFieldDisplayType(parentObjectName, fieldName);
            for(sObject sObj:sObjectMap.values()){
                if (fieldType == Schema.DisplayType.INTEGER ||
                        fieldType == Schema.DisplayType.CURRENCY ||
                        fieldType == Schema.DisplayType.DOUBLE){
                    sObj.put(fieldName, 0);
                } else {
                    sObj.put(fieldName, null);
                }
            }
        }

        //everything in here has to be soft coded, as non of these fields/types exist in single currency orgs
        if(!currencyRollupSettings.isEmpty() && currencyConversionRates == null){
            currencyConversionRates = new Map<String, Decimal>();
            String currencyTypeQuery = 'select ISOCode, ConversionRate from CurrencyType where IsActive=true';
            for(sObject ct:Database.query(currencyTypeQuery)){
                currencyConversionRates.put((String)ct.get('ISOCode'), (Decimal)ct.get('ConversionRate'));
            }
        }

        for(String childObjectName:queryMap.keySet()){
            String query = queryMap.get(childObjectName).toString();
            for(sObject childRecord:Database.query(query)){
                for(Trigger_Rollup_Rule__c rollupSetting: childObjectGroupMap.get(childObjectName)){
                    String parentId = String.valueOf(childRecord.get(rollupSetting.Child_Parent_Field__c));
                    sObject parentRecord = sObjectMap.get(parentId);
                    Object aggregateValue = childRecord.get(rollupSetting.Id);

                    if(aggregateValue != null && currencyRollupSettings.contains(rollupSetting.Id)){
                        aggregateValue = (Decimal)aggregateValue * currencyConversionRates.get(String.valueOf(parentRecord.get('CurrencyISOCode')));
                    }

                    parentRecord.put(rollupSetting.Field__c, aggregateValue);
                }
            }
        }
    }

    private void rollupDelimitedList(Map<Id, sObject> sObjectMap, GroupSetting groupSetting) {
        System.debug('********** START ROLLUP DELIMINATED LIST **********');
        List<Id> parentIds = new List<Id>(sObjectMap.keySet());

        Map<String, List<Trigger_Rollup_Rule__c>> childObjectGroupMap = new Map<String, List<Trigger_Rollup_Rule__c>>();
        for (Trigger_Rollup_Rule__c rollupSetting : groupSetting.rollupSettings){
            if(childObjectGroupMap.containsKey(rollupSetting.Child_Object__c)){
                childObjectGroupMap.get(rollupSetting.Child_Object__c).add(rollupSetting);
            } else {
                childObjectGroupMap.put(rollupSetting.Child_Object__c, new List<Trigger_Rollup_Rule__c>{rollupSetting});
            }
        }

        Map<String, Common_QueryBuilder> queryMap = new Map<String, Common_QueryBuilder>();
        Set<String> parentFieldsToClear = new Set<String>();
        for(String childObjectName: childObjectGroupMap.keySet()){
            String childParentField;
            Common_QueryBuilder queryBuilder = new Common_QueryBuilder(childObjectName);
            for(Trigger_Rollup_Rule__c rollupSetting:childObjectGroupMap.get(childObjectName)){
                if(String.isNotBlank(rollupSetting.Order_By__c)){
                    queryBuilder.addOrderField(rollupSetting.Order_By__c);
                }

                if(rollupSetting.Child_Max_Size__c != null){
                    queryBuilder.setRowLimit(Integer.valueOf(rollupSetting.Child_Max_Size__c));
                }

                parentFieldsToClear.add(rollupSetting.Field__c);
                if(!String.isBlank(rollupSetting.Field_RTF__c)){
                    parentFieldsToClear.add(rollupSetting.Field_RTF__c);
                }

                queryBuilder.addQueryField(rollupSetting.Child_Field__c);
                queryBuilder.addQueryField(rollupSetting.Child_Parent_Field__c);
                if(String.isBlank(childParentField)){
                    childParentField = rollupSetting.Child_Parent_Field__c;
                }
                if(!String.isBlank(rollupSetting.Child_Parent_ID_Field__c)){
                    queryBuilder.addQueryField(rollupSetting.Child_Parent_ID_Field__c);
                }

                if(!String.isBlank(rollupSetting.Child_Query_Where_Clause__c)){
                    queryBuilder.extendWhereFilter(rollupSetting.Child_Query_Where_Clause__c, 'OR');
                }
            }
            queryBuilder.addWhereFilter(childParentField,parentIds,'IN');
            queryMap.put(childObjectName, queryBuilder);
        }

        for(sObject sObj:sObjectMap.values()){
            for(String fieldName:parentFieldsToClear){
                sObj.put(fieldName,'');
            }
        }

        Map<String, Set<String>> uniqueValuesMap = new Map<String, Set<String>>();
        for(String childObjectName:queryMap.keySet()){
            String query = queryMap.get(childObjectName).toString();
            system.debug('query: ' + query);
            for(sObject childRecord:Database.query(query)){
                for(Trigger_Rollup_Rule__c rollupSetting: childObjectGroupMap.get(childObjectName)){
                    String parentId = String.valueOf(childRecord.get(rollupSetting.Child_Parent_Field__c));
                    String childFieldValue = String.valueOf(getSObjectFieldValue(childRecord,rollupSetting.Child_Field__c));

                    if(rollupSetting.Exclude_Nulls__c && String.isBlank(childFieldValue)){
                        continue;
                    }
                    if(rollupSetting.Unique_Values__c){
                        if(uniqueValuesMap.containsKey(parentId+rollupSetting.Child_Parent_Field__c)){
                            if(uniqueValuesMap.get(parentId+rollupSetting.Child_Parent_Field__c).contains(childFieldValue)){
                                continue;
                            }
                            uniqueValuesMap.get(parentId+rollupSetting.Child_Parent_Field__c).add(childFieldValue);
                        } else {
                            uniqueValuesMap.put(parentId+rollupSetting.Child_Parent_Field__c, new Set<String>{childFieldValue});
                        }
                    }

                    buildDelimitedString(
                            sObjectMap,
                            parentId,
                            rollupSetting.Field__c,
                            childFieldValue,
                            rollupSetting.DelimitedList_Delimiter__c
                    );

                    if(!String.isBlank(rollupSetting.Field_RTF__c)){
                        String childIDValue;
                        if(!String.isBlank(rollupSetting.Child_Parent_ID_Field__c)){
                            childIdValue = String.valueOf(getSObjectFieldValue(childRecord,rollupSetting.Child_Parent_ID_Field__c));
                        } else if(rollupSetting.Child_Field__c.contains('.')){
                            String idPath = getIdPathFromRelationalField(rollupSetting.Child_Field__c);
                            childIdValue = String.valueOf(getSObjectFieldValue(childRecord,idPath));
                        } else {
                            childIdValue = childFieldValue;
                        }

                        String htmlString =
                                HTML_ANCHOR_START_LEFT+
                                        childIdValue+
                                        HTML_ANCHOR_START_RIGHT+
                                        childFieldValue+
                                        HTML_ANCHOR_END;

                        buildDelimitedString(
                                sObjectMap,
                                parentId,
                                rollupSetting.Field_RTF__c,
                                htmlString,
                                rollupSetting.DelimitedList_Delimiter__c);
                    }
                }
            }
        }
    }

    public void forceParentRollup(Map<Id, sObject> sObjectMap, String objectName) {
        if(processedRecords == null){
            processedRecords = new Map<String, Set<ID>>();
        }

        List<Trigger_Rollup_Rule__c> rollupSettings = new List<Trigger_Rollup_Rule__c>();
        for (Trigger_Rollup_Rule__c setting : Trigger_Rollup_Rule__c.getAll().values()) {
            if (setting.Child_Object__c.equalsIgnoreCase(objectName)) {
                rollupSettings.add(setting);
            }
        }

        if (rollupSettings.size() > 0) {
            Map<String, Set<Id>> mapObject_Ids = new Map<String, Set<Id>>();
            for (Trigger_Rollup_Rule__c rollupSetting : rollupSettings) {
                system.debug('Rollup Setting: ' + rollupSetting.Name);

                if (mapObject_Ids.get(rollupSetting.Object__c) == null)
                    mapObject_Ids.put(rollupSetting.Object__c, new Set<Id>());

                for (sObject sObj : sObjectMap.values()) {
                    if (String.isNotBlank(rollupSetting.Child_Parent_Field__c) && sObj.get(rollupSetting.Child_Parent_Field__c) != null &&
                            getObjectNameFromId(String.valueOf(sObj.get(rollupSetting.Child_Parent_Field__c))) == rollupSetting.Object__c){
                        mapObject_Ids.get(rollupSetting.Object__c).add(String.valueOf(sObj.get(rollupSetting.Child_Parent_Field__c)));

                        if(rollupSetting.Child_Field__c.contains('.')) {
                            if(processedRecords.containsKey(rollupSetting.Name)){
                                processedRecords.get(rollupSetting.Name).add(sObj.Id);
                            } else {
                                processedRecords.put(rollupSetting.Name, new Set<ID>{sObj.Id});
                            }
                        }
                    }

                }
            }

            for (String parentObject : mapObject_Ids.keySet()) {

                List<Id> idsToUpdate = new List<Id>();
                idsToUpdate.addAll(mapObject_Ids.get(parentObject));

                if (idsToUpdate.size() > 0) {
                    List<sObject> sObjectsToUpdate = new List<sObject>();
                    for (Id updateId : idsToUpdate) {
                        SObject updateObj = Schema.getGlobalDescribe().get(parentObject).newSobject();
                        updateObj.put('Id', updateId);
                        sObjectsToUpdate.add(updateObj);
                    }

                    system.debug('UPDATING ' + sObjectsToUpdate);
                    try {
                        update sObjectsToUpdate;
                    } catch (exception e) {
                        sObjectMap.values()[0].addError('Error updating one or more parents for '+objectName+'. Exception occurred: '+e.getMessage());
                    }
                }
            }
        }
    }

    public static List<Trigger_Rollup_Rule__c> rollupFromObject(String objectName) {
        if (lstRollup == null || lstRollup.isEmpty() || (!lstRollup.isEmpty() && lstRollup.get(0).Object__c.trim() != objectName.trim())) {
            lstRollup = new List<Trigger_Rollup_Rule__c>();
            for (Trigger_Rollup_Rule__c rule : Trigger_Rollup_Rule__c.getAll().values()) {
                if (rule.Object__c.equalsIgnoreCase(objectName) && rule.Disabled__c == false) {
                    lstRollup.add(rule);
                }
            }
        }

        return lstRollup;
    }

    //========================================================================= 
    // HELPER CLASSES
    //=========================================================================

    class GroupSettings {
        public Map<String, GroupSetting> groupSettings;

        public GroupSettings() {
            groupSettings = new Map<String, GroupSetting>();
        }

        public void load(String objectName) {
            List<Trigger_Rollup_Rule__c> rollupSettings = Trigger_Rollup_Handler.rollupFromObject(objectName);

            for (Trigger_Rollup_Rule__c rollupSetting : rollupSettings) {
                if (rollupSetting.Child_Query_Group__c == null) {
                    GroupSetting groupSetting = new GroupSetting();
                    groupSetting.rollupSettings.add(rollupSetting);

                    groupSettings.put(rollupSetting.Name, groupSetting);

                } else {

                    GroupSetting groupSetting = groupSettings.get(rollupSetting.Child_Query_Group__c);
                    if (groupSetting == null) {
                        groupSetting = new GroupSetting();
                        groupSettings.put(rollupSetting.Child_Query_Group__c, groupSetting);
                    }

                    groupSetting.rollupSettings.add(rollupSetting);
                }

            }


            validateGroups();
        }

        public List<Trigger_Rollup_Rule__c> getRollupSettings(String groupName) {
            return groupSettings.get(groupName).rollupSettings;
        }

        public String getType(String groupName) {
            return getRollupSettings(groupName).get(0).Type__c;
        }

        private boolean validateGroups() {
            // loop through groups and make sure that all rolluptypes within each group are of the same type and the whereclause is the same
            // otherwise assertError
            for (String key : groupSettings.keySet()) {
                String keyType = groupSettings.get(key).rollupSettings.get(0).Child_Query_Group__c;
                for (Trigger_Rollup_Rule__c rollupSetting : groupSettings.get(key).rollupSettings) {
                    assertError((keyType != rollupSetting.Child_Query_Group__c), 'Group not matching properly: ' + key + ', ' + rollupSetting.Child_Query_Group__c);
                }
            }
            return false;

        }
    }

    class GroupSetting {
        public List<Trigger_Rollup_Rule__c> rollupSettings = new List<Trigger_Rollup_Rule__c>();
    }

    //=========================================================================
    // HELPER METHODS
    //=========================================================================
    private void buildDelimitedString(map<Id, SObject> mapXList, String currentObjectId, String fieldName, String value, String delimiter) {
        if (value == null){
            value = 'null';
        }

        if(String.isBlank(delimiter)){
            delimiter = ', ';
        } else if(delimiter.startsWith('\'') && delimiter.endsWith('\'')){
            delimiter = delimiter.substringBetween('\'');
        }

        String objectName = getObjectNameFromId(currentObjectId);
        Schema.DescribeFieldResult dfr = getDescribeField(objectName, fieldName);
        Schema.SObjectField fieldInfo = dfr.getSobjectField();

        Object currentValue;
        if(mapXList.containsKey(currentObjectId)){
            currentValue = mapXList.get(currentObjectId).get(fieldInfo);
        }

        Integer maximumLengthOfField = dfr.getLength();
        Integer currentLengthOfField;

        if(currentValue != null && !String.isBlank(String.valueOf(currentValue))){
            currentLengthOfField = String.valueOf(currentValue).length()+delimiter.length();
        } else {
            currentLengthOfField = 0;
        }

        //can we add the truncated version
        if(maximumLengthOfField < currentLengthOfField + Math.min(4,value.length())){
            system.debug('skip add due to length.');
            return;
        } else if(maximumLengthOfField < currentLengthOfField + value.length()){
            value = value.abbreviate(maximumLengthOfField-currentLengthOfField-1);
        }

        system.debug('write data to:'+dfr.getName());
        system.debug('current value:'+currentValue);
        system.debug('new value:'+value);

        if(currentValue != null && !String.isBlank(String.valueOf(currentValue))) {
            String newFieldValue = String.valueOf(currentValue)+delimiter+value;
            mapXList.get(currentObjectId).put(dfr.getSObjectField(), newFieldValue);
        } else {
            mapXList.get(currentObjectId).put(dfr.getSObjectField(), value);
        }

        system.debug('mapXList.get(currentObjectId) = ' + mapXList.get(currentObjectId));
    }


    //=========================================================================
    // COMMON_EXCEPTIONS
    //=========================================================================
    public static void assertError(boolean condition, string message) {
        if (condition){
            system.debug(message);
            throw new ApplicationException(message);
        }
    }

    public class ApplicationException extends Exception {}

    //=========================================================================
    // COMMON_SCHEMA
    //=========================================================================
    private static Schema.DisplayType getFieldDisplayType(String sobjectName, String fieldName){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objectSchema = schemaMap.get(sobjectName);
        Map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();

        return fieldMap.get(fieldName).getDescribe().getType();
    }

    private static Schema.SObjectType getSObjectType(String sobjectType){
        return Schema.getGlobalDescribe().get(sobjectType);
    }

    private static Schema.SObjectType getSObjectType(Id sobjectId){
        return sobjectId.getSobjectType();
    }

    private static Schema.DescribeSObjectResult getDescribe(String sObjName){
        Schema.SObjectType objectType = getSObjectType(sObjName);
        return objectType.getDescribe();
    }

    private static Schema.DescribeSObjectResult getDescribe(Schema.SobjectType objectType){
        return objectType.getDescribe();
    }

    private static Schema.DescribeSObjectResult getDescribe(ID recordId){
        Schema.SObjectType objectType = getSObjectType(recordId);
        return getDescribe(objectType);
    }

    private static Map<String, Schema.SobjectField> getSobjectFields(String objectName){
        Schema.DescribeSObjectResult result = getDescribe(objectName);
        return result.fields.getMap();
    }

    private static Schema.DescribeFieldResult getDescribeField(String objectName, String fieldName){

            Schema.SObjectField objectField = getSObjectFields(objectName).get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = objectField.getDescribe();

            return fieldDescribe;
    }

    private static String getObjectNameFromId(Id rId){
        Schema.SObjectType objectType = getSObjectType(rId);
        DescribeSObjectResult objectDescribe = getDescribe(objectType);

        return objectDescribe.getName();
    }

    //=========================================================================
    // COMMON_SOBJECT
    //=========================================================================
    public static Object getSObjectFieldValue(sObject o, String field){
        system.debug(o);
        if (!field.contains('.')) {
            return o.get(field);
        } else {
            sObject relationalRecord = o.getSObject(field.substringBefore('.'));
            if(relationalRecord != null){
                return getSObjectFieldValue(relationalRecord,field.substringAfter('.'));
            } else {
                return null;
            }
        }
    }

    //=========================================================================
    // COMMON_STRING
    //=========================================================================
    public static String getIdPathFromRelationalField(String fieldPath){
        String idPath = fieldPath.subStringBeforeLast('.').trim();
        if(idPath.endsWith('__r')){
            idPath = idPath.removeEndIgnoreCase('__r')+'__c';
        } else {
            idPath = idPath+'Id';
        }

        return idPath;
    }

    //=========================================================================
    // COMMON_QUERYBUILDER
    //=========================================================================

    public class Common_QueryBuilder {
        public Set<String> queryFields;
        public List<Common_QueryBuilder> innerQueries;
        public String objectAPIName;

        public LogicalGrouping whereFilter;
        public String whereClause;

        public List<String> orderbyFields;

        public List<String> groupbyFields;
        public Integer rowLimit;
        public Integer offSet;

        public Common_QueryBuilder(String objectName){
            objectAPIName = objectName;
            queryFields = new Set<String>();
            groupbyFields = new List<String>();
            orderbyFields = new List<String>();
            whereFilter = new LogicalGrouping('AND');
            innerQueries = new List<Common_QueryBuilder>();
        }

        public void addQueryField(String field){
            queryFields.add(field);
        }

        public void addWhereFilter(String formattedFilter){
            whereClause = '('+formattedFilter+')';
        }

        public void extendWhereFilter(String formattedFilter, String logicalOperator){
            if(whereClause != null){
                whereClause += ' '+logicalOperator+' ('+formattedFilter+')';
            } else {
                addWhereFilter(formattedFilter);
            }
        }

        public void addWhereFilter(String fieldName, List<Object> values, String operator){
            whereFilter.filterElements.add(new FilterElement(fieldName, values, operator));
        }

        public void addOrderField(String field){
            String orderEntry = field;

            Set<String> checkForDupes = new Set<String>(orderbyFields);
            if(!checkForDupes.contains(orderEntry)){
                orderbyFields.add(orderEntry);
            }
        }

        public void setRowLimit(Integer maxRows){
            if(maxRows == null || maxRows<1){
                rowLimit = null;
            } else {
                rowLimit = maxRows;
            }
        }

        public void addGroupField(String field){
            groupbyFields.add(field);
        }

        public override String toString(){
            String query = 'SELECT ';
            List<String> fullFieldList = new List<String>();
            if(!queryFields.isEmpty()){
                fullFieldList.addAll(queryFields);
            } else {
                fullFieldList.add('ID');
            }

            if(!innerQueries.isEmpty()){
                for(Common_QueryBuilder qb:innerQueries){
                    fullFieldList.add('('+qb.toString()+')');
                }
            }
            query += String.join(fullFieldList,',');

            system.debug('objectAPIName = ' + objectAPIName);
            query+= ' FROM '+objectAPIName;

            String builtWhereClause = '';
            if(!String.isBlank(whereClause)){
                builtWhereClause += ' WHERE ('+ whereClause +')';
            }
            if(whereFilter!= null){
                system.debug('whereFilter = ' + whereFilter);
                String compiledFilters = whereFilter.toString();
                system.debug('compiledFilters = ' + compiledFilters);
                if(!String.isBlank(compiledFilters)){
                    if(String.isBlank(builtWhereClause)){
                        builtWhereClause += ' WHERE '+whereFilter.toString();
                    } else {
                        Boolean isOperatorMismatch = !whereFilter.logicalOperator.equalsIgnoreCase('AND');
                        builtWhereClause += ' AND ';
                        if(isOperatorMismatch){
                            builtWhereClause += '(';
                        }
                        builtWhereClause += whereFilter.toString();
                        if(isOperatorMismatch){
                            builtWhereClause += ')';
                        }
                    }
                }
                system.debug('builtWhereClause: ' + builtWhereClause);
            }
            query += builtWhereClause;

            if(!groupbyFields.isEmpty()){
                query += ' GROUP BY '+String.join(groupbyFields,',');
            }

            if(!orderbyFields.isEmpty()){
                query += ' ORDER BY '+String.join(orderbyFields,',');
            }

            if(rowLimit != null){
                query += ' LIMIT '+String.valueOf(rowLimit);
            }

            if(offSet != null){
                query += ' OFFSET '+String.valueOf(offSet);
            }

            System.debug(query);
            return query;
        }
    }


    public class LogicalGrouping{
        public String logicalOperator;
        public List<LogicalGrouping> subgroupings;
        public List<FilterElement> filterElements;

        public LogicalGrouping(String logicalOperator){
            this.logicalOperator = logicalOperator;
            subgroupings = new List<LogicalGrouping>();
            filterElements = new List<FilterElement>();
        }

        public override String toString(){
            if((filterElements == null || filterElements.isEmpty()) && (subgroupings == null || subgroupings.isEmpty())){
                return '';
            }

            String whereClause = '';


            if(filterElements != null && !filterElements.isEmpty()){
                List<String> filterStrings = new List<String>();
                for(FilterElement fe:filterElements){
                    filterStrings.add(fe.toString());
                }

                whereClause += String.join(filterStrings,' '+logicalOperator+' ');
            }

            if(subgroupings != null && !subgroupings.isEmpty()){
                if(whereClause != '(' && whereClause != ''){
                    whereClause += ' '+logicalOperator+' ';
                }
                List<String> subgroupStrings = new List<String>();
                for(LogicalGrouping lg:subgroupings){
                    String filterString = lg.toString();
                    if(lg.logicalOperator != this.logicalOperator){
                        filterString = '('+filterString+')';
                    }
                    subgroupStrings.add(filterString);
                }
                whereClause += String.join(subgroupStrings,' '+logicalOperator+' ');
            }

            return whereClause;
        }
    }


    public class FilterElement{
        public String fieldName;
        public String operator;
        public List<Object> filterValues;
        public String precompiledFilter;

        public FilterElement(String field, List<Object> values, String operator){
            fieldName = field;
            filterValues = values;
            this.operator = operator;
        }

        public override String toString(){
            if(fieldName == null){
                return precompiledFilter;
            } else {
                String filterString = fieldName+' '+operator+' ';

                if(filterValues != null && !filterValues.isEmpty()){
                    List<String> processingValues = new List<String>();
                    //Todo: look into replacing this with the logic from Common_Reflection
                    String fieldType = 'string';
                    if(filterValues[0] == null){
                        fieldType = 'null';
                    } else if(filterValues[0] instanceOf Date){
                        fieldType = 'date';
                    } else if(filterValues[0] instanceOf DateTime){
                        fieldType = 'datetime';
                    } else if(filterValues[0] instanceOf Integer){
                        fieldType = 'integer';
                    } else if(filterValues[0] instanceOf Decimal){
                        fieldType = 'decimal';
                    } else if(filterValues[0] instanceOf Double){
                        fieldType = 'double';
                    } else if(filterValues[0] instanceOf Boolean){
                        fieldType = 'boolean';
                    }

                    for(Object filterValue:filterValues){
                        if(fieldType == 'string'){
                            processingValues.add('\''+String.escapeSingleQuotes(String.valueOf(filterValue))+'\'');
                        } else if(fieldType == 'date'){
                            String sValue = String.valueOf(filterValue).substringBefore('T');
                            processingValues.add(sValue);
                        } else if(fieldType == 'null'){
                            processingValues.add(null);
                        } else {
                            processingValues.add(String.valueOf(filterValue));
                        }
                    }

                    if(processingValues.size() == 1 && !operator.equalsIgnoreCase('includes') && !operator.equalsIgnoreCase('in') && !operator.equalsIgnoreCase('excludes')){
                        filterString += processingValues[0];
                    } else if(operator.equalsIgnoreCase('in') || operator.equalsIgnoreCase('includes') || operator.equalsIgnoreCase('excludes')){
                        filterString += '(' + String.join(processingValues,',') +')';
                    } else {
                        filterString += String.join(processingValues,',');
                    }
                } else {
                    filterString += 'null';
                }

                return filterString;
            }
        }
    }
}