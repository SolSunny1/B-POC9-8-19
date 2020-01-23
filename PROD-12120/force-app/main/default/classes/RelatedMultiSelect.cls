global with sharing class RelatedMultiSelect {
    @AuraEnabled
    public static List<SObjectWrapper> queryRecordsFromWidget(String widget, Id parentId, Id childId, Boolean securityEnabled, List<String> securityGroups){
        system.debug('Passed id for related list: '+parentId);
        if(parentId == null){
            throw new AuraHandledException('Configuration problem. Record Id not passing from the button on the record');
        }
        String sObjectName = Common_Schema.getObjectNameFromId(parentId);
        system.debug('Invoked from object: '+sObjectName);
        if(sObjectName == null){
            throw new AuraHandledException('Error: sObjectName is empty, from the page button invoked from');
        }
        system.debug('Originating Record Id: '+parentId);
        SmartWidget__c smartWidget = (SmartWidget__c)JSON.deserialize(widget, SmartWidget__c.class);
        if(smartWidget == null){
            throw new AuraHandledException('Configuration not loading in related multi select list');
        }
        system.debug('Widget Id: '+smartWidget.Id);
        system.debug('Widget Name: '+smartWidget.Name);

        if(smartWidget.AutoComplete_Search_Object__c == null){
            throw new AuraHandledException('Configuration problem. AutoComplete_Search_Object__c must be populated on the SmartWidget');
        }

        if(smartWidget.AutoComplete_Target_Field__c == null){
            throw new AuraHandledException('Configuration problem. AutoComplete_Target_Field__c must be populated on the SmartWidget');
        }

        String objName = smartWidget.AutoComplete_Search_Object__c;

        Set<String> displayFieldSet = new Set<String>();
        displayFieldSet.addAll(Common_Type.convertDelimitedStringToTrimmedSet(smartWidget.AutoComplete_Target_Field__c,','));

        if(!String.isBlank(smartWidget.Autocomplete_Related_Field__c)){
            displayFieldSet.addAll(Common_Type.convertDelimitedStringToTrimmedSet(smartWidget.Autocomplete_Related_Field__c,','));
        }


        displayFieldSet.add(Common_Schema.getNameField(smartWidget.AutoComplete_Search_Object__c));

        String search_fields = smartWidget.AutoComplete_Search_Fields__c == null? '' : smartWidget.AutoComplete_Search_Fields__c;

        String extraWhereClause = '';
        if (String.isNotBlank(smartWidget.Filter__c)) {
            extraWhereClause = smartWidget.Filter__c;
            if (smartWidget.Filter__c.containsIgnoreCase('securityGroups')) {
                if (securityEnabled) {
                    extraWhereClause = extraWhereClause.replace('securityGroups', String.join(securityGroups, '\',\''));
                } else {
                    List<String> whereTokens = extraWhereClause.split('\\s+');
                    Integer securityGroupIndex = whereTokens.indexOf('(\'securityGroups\')');
                    if (securityGroupIndex > 1) {
                        whereTokens.remove(securityGroupIndex);
                        whereTokens.remove(securityGroupIndex-1);
                        whereTokens.remove(securityGroupIndex-2);
                        if (securityGroupIndex - 3 >= 0 && whereTokens[securityGroupIndex-3].equalsIgnoreCase('AND')) {
                            whereTokens.remove(securityGroupIndex-3);
                        }
                    }
                    if (whereTokens.isEmpty()) {
                        extraWhereClause = '';
                    } else {
                        extraWhereClause = String.join(whereTokens, ' ');
                    }
                }
            }
            extraWhereClause = extraWhereClause.replace('parentId',parentId).replace('childId',childId);
        }

        Common_QueryBuilder queryBuilder = new Common_QueryBuilder(objName);
        queryBuilder.addQueryFields(new List<String>(displayFieldSet));

        if(!String.isBlank(extraWhereClause)){
            queryBuilder.addWhereFilter(extraWhereClause);
        }
        queryBuilder.addOrderField(new List<String>(displayFieldSet)[0]);

        if (smartWidget.Query_Limit__c==null){
            queryBuilder.setRowLimit(150);
        } else {
            queryBuilder.setRowLimit(Integer.valueOf(smartWidget.Query_Limit__c));
        }

        String query = queryBuilder.toString();
        system.debug(query);
        return wrapSObjects(Database.query(query),objName);
        //List<sObject> records = Database.query();

        //return wrapSObjects(SmartWidget_Controller.getObjectsForAutocomplete(objName, '', display_fields, search_fields, '', extraWhereClause),objName);
    }

    @AuraEnabled
    public static List<SObjectWrapper> search(String widget, String searchText, Boolean securityEnabled, List<String> securityGroups) {
        SmartWidget__c smartWidget = (SmartWidget__c)JSON.deserialize(widget, SmartWidget__c.class);
        String objName = smartWidget.AutoComplete_Search_Object__c;

        Set<String> displayFieldSet = new Set<String>();
        displayFieldSet.addAll(Common_Type.convertDelimitedStringToTrimmedSet(smartWidget.AutoComplete_Target_Field__c,','));

        if(!String.isBlank(smartWidget.Autocomplete_Related_Field__c)){
            displayFieldSet.addAll(Common_Type.convertDelimitedStringToTrimmedSet(smartWidget.Autocomplete_Related_Field__c,','));
        }
        displayFieldSet.add(Common_Schema.getNameField(smartWidget.AutoComplete_Search_Object__c));

        Set<String> searchFields;
        if(!String.isBlank(smartWidget.AutoComplete_Search_Fields__c)){
            searchFields = Common_Type.convertDelimitedStringToTrimmedSet(smartWidget.AutoComplete_Search_Fields__c,',');
        } else {
            searchFields = new Set<String>{'Name'};
        }


        String extraWhereClause = '';
        if (String.isNotBlank(smartWidget.AutoComplete_Search_Filter__c)) {
            extraWhereClause = smartWidget.AutoComplete_Search_Filter__c;
            if (smartWidget.AutoComplete_Search_Filter__c.containsIgnoreCase('securityGroups')) {
                if (securityEnabled) {
                    extraWhereClause = extraWhereClause.replace('securityGroups', String.join(securityGroups, '\',\''));
                } else {
                    List<String> whereTokens = extraWhereClause.split('\\s+');
                    Integer securityGroupIndex = whereTokens.indexOf('(\'securityGroups\')');
                    if (securityGroupIndex > 1) {
                        whereTokens.remove(securityGroupIndex);
                        whereTokens.remove(securityGroupIndex-1);
                        whereTokens.remove(securityGroupIndex-2);
                        if (securityGroupIndex - 3 >= 0 && whereTokens[securityGroupIndex-3].equalsIgnoreCase('AND')) {
                            whereTokens.remove(securityGroupIndex-3);
                        }
                    }
                    if (whereTokens.isEmpty()) {
                        extraWhereClause = '';
                    } else {
                        extraWhereClause = String.join(whereTokens, ' ');
                    }
                }
            }
        }

        Common_QueryBuilder queryBuilder = new Common_QueryBuilder(objName);
        queryBuilder.addQueryFields(new List<String>(displayFieldSet));

        if(!String.isBlank(extraWhereClause)){
            queryBuilder.addWhereFilter(extraWhereClause);
        }

        queryBuilder.addOrderField(new List<String>(displayFieldSet)[0]);

        Common_QueryBuilder.LogicalGrouping searchFilter = new Common_QueryBuilder.LogicalGrouping('OR');
        for(String searchField:searchFields){
            searchFilter.filterElements.add(
                    new Common_QueryBuilder.FilterElement(
                            searchField,
                            new List<Object>{'%'+searchText+'%'},
                            'LIKE'
                    )
            );
        }
        queryBuilder.addWhereFilterSeries(searchFilter);

        if (smartWidget.Query_Limit__c==null){
            queryBuilder.setRowLimit(50);
        } else {
            queryBuilder.setRowLimit(Integer.valueOf(smartWidget.Query_Limit__c));
        }

        String query = queryBuilder.toString();
        system.debug(query);
        return wrapSObjects(Database.query(query),objName);
    }

    public static List<RelatedMultiSelect.SObjectWrapper> wrapSObjects(List<SObject> sObjects,String objName){
        List<SObjectWrapper> wrappers = new List<SObjectWrapper>();
        system.debug(objName + ' Records: '+sObjects);

        for(SObject sob:sObjects){
            SObjectWrapper wrapper = new SObjectWrapper();

            wrapper.Name = (String)sob.get('Name');
            wrapper.Id = (String)sob.get('Id');
            wrapper.objectName = objName;
            wrapper.record = sob;
            wrapper.selected = false;

            wrappers.add(wrapper);
        }
        return wrappers;
    }

    public class SObjectWrapper{
        @AuraEnabled
        public String Name {get;set;}
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String objectName {get;set;}
        @AuraEnabled
        public SObject record {get;set;}
        @AuraEnabled
        public Boolean selected {get;set;}
    }
}