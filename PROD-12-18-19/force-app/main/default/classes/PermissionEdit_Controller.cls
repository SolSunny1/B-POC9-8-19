global with sharing class PermissionEdit_Controller {
    List<String> widgetNames = new List<String>();
    Map<String,SmartWidget__c> SearchWidgets; //By Name
    Map<String,SmartWidget__c> FieldWidgets;//By Name

    private static final string NAMESPACE = '';
    private static Integer permissionLimit = 1000;
    private static Common_QueryBuilder permissionQuery;
    private static String keyFieldName;
    private static List<String> pmsQueryOrderFields = new List<String>();
    private static List<String> pmsQueryOrderValues = new List<String>();

    /*******
    ADD MODE
    *******/
    @AuraEnabled
    public static Map<String,String> initializeComponent_AddMode(Map<String,String> params) {
        Map<String,String> response = new Map<String,String>();
        Set<String> urlDefaultedPermissions = new Set<String>();
        ID recordId = (ID) params.get('recordId');
        Permission_Configuration__mdt config = loadPermissionConfig(params.get('configurationName'));
        response.put('config', JSON.serialize(config));

        List<Permission_Type__c> permissionTypes = loadPermissionTypes(config.Permission_Type_Filter__c);
        response.put('permissionTypesJSON', JSON.serialize(permissionTypes));

        List<SmartWidget__c> widgets = loadSmartWidgets(config.Related_Object_Widgets__c);

        confirmObjectFieldAccess(config,widgets);

        response.put('widgets', JSON.serialize(widgets));
        Map<string,string> iconMap = getAllObjectIconMap();
        system.debug('Icon Map: '+iconMap);
        response.put('recordIcon',JSON.serialize(getRecordIcon(recordId,iconMap)));

        if(params.containsKey('defaultedPermissionTypes') && params.get('defaultedPermissionTypes') != null){
            urlDefaultedPermissions = new Set<String>(params.get('defaultedPermissionTypes').split(';'));
        }

        String parentRecordId = recordId;
        parentRecordId = getParentRecord(params.get('recordId'), config.Parent_Field__c, Common_Schema.getObjectNameFromId(recordId));
        response.put('parentRecordId', parentRecordId);

        if (String.isNotBlank(config.Admin_Profiles__c)) {
            Set<String> adminProfileIds = new Set<String>(Common_Type.convertDelimitedStringToTrimmedList(config.Admin_Profiles__c,';'));
            response.put('userIsAdminJSON', adminProfileIds.contains(UserInfo.getProfileId()) + '');
        }
        response.put('enableRowSecurityJSON', '' + (String.isNotBlank(config.Contact_Security_Field__c) && String.isNotBlank(config.Permission_Security_Field__c)));
        response.put('securityGroupsJSON', JSON.serialize(getUserSecurityAccess(config.Contact_Security_Field__c)));
        List<String> customPermissionNames = getUserCustomPermissions();
        response.put('customPmsAPINamesJSON', JSON.serialize(customPermissionNames));

        Boolean isReadOnly = false;
        if(!String.isBlank(config.Access_Custom_Permissions__c)){
            Set<String> accessibleCustomPermissions = Common_Type.convertDelimitedStringToTrimmedSet(config.Access_Custom_Permissions__c, ';');
            accessibleCustomPermissions.retainAll(customPermissionNames);
            if(accessibleCustomPermissions.isEmpty()){
                isReadOnly = true;
            }
        }
        response.put('readOnly', String.valueOf(isReadOnly));

        List<String> sObjectNames = new List<String>();
        List<String> pmsFieldNames = new List<String>();
        for (SmartWidget__c sw : widgets) {
            if (!sObjectNames.isEmpty() && (config.Primary_Junction_Object_Type__c.trim().equalsIgnoreCase(sw.Object__c) ||
                config.Primary_Junction_Object_Type__c.trim().equalsIgnoreCase(sw.AutoComplete_Search_Object__c))) {
                sObjectNames.add(0, config.Primary_Junction_Object_Type__c.trim());
                pmsFieldNames.add(0, sw.Field__c.trim());
            } else {
                if (String.isNotBlank(sw.AutoComplete_Search_Object__c)) {
                    sObjectNames.add(sw.AutoComplete_Search_Object__c.trim());
                } else {
                    sObjectNames.add(sw.Object__c.trim());
                }
                pmsFieldNames.add(sw.Field__c.trim());
            }
        }
        response.put('sObjectNamesJSON', JSON.serialize(sObjectNames));
        List<String> sObjectLabels = new List<String>();
        for (String sObjName : sObjectNames) {
            sObjectLabels.add(Common_Schema.getSObjectType(sObjName).getDescribe().getLabelPlural());
        }
        response.put('sObjectLabelsJSON', JSON.serialize(sObjectLabels));
        response.put('pmsFieldNamesJSON', JSON.serialize(pmsFieldNames));
        response.put('permissionLabel',JSON.serialize(Common_Schema.getSObjectType(NAMESPACE+'Permission__c').getDescribe().getLabelPlural()));

        List<PermissionWrapper> pmsWrappers = new List<PermissionWrapper>();
        Integer longestTypeSize = 1;
        for (Permission_Type__c pt : permissionTypes) {
            PermissionWrapper pw = new PermissionWrapper(pt,urlDefaultedPermissions.contains(pt.Id));
            pw.width = (100 / permissionTypes.size()) + '%';
            pmsWrappers.add(pw);

            if (pt.Name.length() > longestTypeSize) {
                longestTypeSize = pt.Name.length();
            }
        }

        List<PermissionWrapper> pmsCtrlWrappers = new List<PermissionWrapper>();
        for (Permission_Type__c pt : permissionTypes) {
            PermissionWrapper pw = new PermissionWrapper(pt.Id);
            pw.width = (100 / permissionTypes.size()) + '%';
            pmsCtrlWrappers.add(pw);
        }
        response.put('pmsCtrlWrappersJSON', JSON.serialize(pmsCtrlWrappers));

        Integer rowHeadersSize = config.Headers__c.split(';').size() - 1;
        RowObject rowObj = new RowObject();
        rowObj.pmsList = pmsWrappers;
        for (Integer i = 0; i < rowHeadersSize; i ++) {
            rowObj.subRecords.add(new ObjectWrapper());
        }
        response.put('rowObjectJSON', JSON.serialize(rowObj));

        KeyObject keyObj = new KeyObject();
        keyObj.pmsList = pmsCtrlWrappers;
        keyObj.rowLabelWidth = (100 / rowHeadersSize) + '%';
        response.put('keyObjectJSON', JSON.serialize(keyObj));


        response.put('isSandbox', String.valueOf([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox));

        return response;
    }

    @AuraEnabled
    public static Map<String,String> insertNewPermissions(Map<String,String> params) {
        Map<String,String> response = new Map<String,String>();
        Savepoint sp = Database.setSavepoint();
        try {
            List<String> pmsFieldNames = (List<String>)JSON.deserialize(params.get('pmsFieldNamesJSON'), List<String>.class);
            List<Permission__c> pmsList = (List<Permission__c>)JSON.deserialize(params.get('pmsListJSON'), List<Permission__c>.class);
            List<Set<String>> pmsFieldValues = new List<Set<String>>();
            for (Integer i = 0; i < pmsFieldNames.size(); i++) {
                pmsFieldValues.add(new Set<String>());
            }
            Set<String> pmsTypeIds = new Set<String>();
            Map<String, Permission__c> pmsMap = new Map<String, Permission__c>();
            for (Permission__c pms : pmsList) {
                String pmsKey = pms.Permission_Type__c;
                pmsTypeIds.add(pms.Permission_Type__c);
                for (Integer i = 0; i < pmsFieldNames.size(); i++) {
                    pmsFieldValues[i].add(String.valueOf(pms.get(pmsFieldNames[i])));
                    pmsKey += ' ' + String.valueOf(pms.get(pmsFieldNames[i]));
                }
                pmsMap.put(pmsKey, pms);
            }
            System.debug(pmsList.size());
            pmsList = null;

            String pmsObjName = NAMESPACE + 'Permission__c';
            Common_QueryBuilder query = new Common_QueryBuilder(pmsObjName);
            query.addQueryField('Id');
            query.addQueryField(NAMESPACE + 'Permission_Type__c');
            for (String fn : pmsFieldNames) {
                query.addQueryField(fn);
            }
            query.setWhereFilterPrimaryOperator('AND');
            query.addWhereFilter(NAMESPACE + 'Permission_Type__c', new List<String>(pmsTypeIds));
            for (Integer i = 0; i < pmsFieldNames.size(); i++) {
                if (pmsFieldValues[i] != null) {
                    pmsFieldValues[i].remove(null);
                    pmsFieldValues[i].remove('');
                    if (!pmsFieldValues[i].isEmpty()) {
                        query.addWhereFilter(pmsFieldNames[i], new List<String>(pmsFieldValues[i]));
                    }
                }
                System.debug(pmsFieldNames[i] + '(' + pmsFieldValues[i].size() + '): ' + pmsFieldValues[i]);
            }
            System.debug(query.toString());

            for (Permission__c existingPms : Database.query(query.toString())) {
                String pmsKey = existingPms.Permission_Type__c;
                for (Integer i = 0; i < pmsFieldNames.size(); i++) {
                    pmsKey += ' ' + String.valueOf(existingPms.get(pmsFieldNames[i]));
                }

                pmsMap.remove(pmsKey);
            }

            Integer successCount = 0;
            if (!pmsMap.isEmpty()) {
                Boolean hasSaveError = false;
                List<String> errorMessages = new List<String>();
                //List<Permission__c> failedRecords = new List<Permission__c>();
                List<String> failedResults = new List<String>();

                //for (Database.UpsertResult sr : Database.upsert(pmsMap.values(), false)) {
                for (Database.SaveResult sr : Common_Database.secureInsert2(pmsMap.values(), false)) {
                    if (sr.isSuccess()) {
                        successCount++;
                    } else {
                        hasSaveError = true;
                        failedResults.add(sr.getErrors()[0].getMessage());
                    }
                }

                if (!hasSaveError) {
                    response.put('successMsg', 'Save success!');
                    response.put('successCountJSON', successCount + '');
                } else {
                    response.put('errorMsg', JSON.serialize(errorMessages));
                    response.put('errorRecords', JSON.serialize(failedResults));
                }
            } else {
                response.put('successMsg', 'Save success!');
                response.put('successCountJSON', successCount + '');
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            response.put('errorMsg', e.getMessage() + ' ' + e.getStackTraceString());
        }
        //Database.rollback(sp);
        return response;
    }

    /*******
    EDIT MODE
    *******/
    @AuraEnabled
    public static Map<String,String> initializeComponent(Map<String,String> params) {
        Map<String,String> response = new Map<String,String>();
        Set<String> urlDefaultedPermissions = new Set<String>();
        ID recordId = (ID) params.get('recordId');
        Permission_Configuration__mdt config = loadPermissionConfig(params.get('configurationName'));
        response.put('config', JSON.serialize(config));

        List<Permission_Type__c> permissionTypes = loadPermissionTypes(config.Permission_Type_Filter__c);
        response.put('permissionTypesJSON', JSON.serialize(permissionTypes));

        List<SmartWidget__c> widgets = loadSmartWidgets(config.Related_Object_Widgets__c);

        confirmObjectFieldAccess(config,widgets);

        response.put('widgets', JSON.serialize(widgets));
        Map<string,string> iconMap = getAllObjectIconMap();
        system.debug('Icon Map: '+iconMap);
        response.put('recordIcon',JSON.serialize(getRecordIcon(recordId,iconMap)));

        if(params.containsKey('defaultedPermissionTypes') && params.get('defaultedPermissionTypes') != null){
            urlDefaultedPermissions = new Set<String>(params.get('defaultedPermissionTypes').split(';'));
        }

        String parentRecordId = recordId;
        parentRecordId = getParentRecord(params.get('recordId'), config.Parent_Field__c, Common_Schema.getObjectNameFromId(recordId));
        response.put('parentRecordId', parentRecordId);

        List<Permission__c> existingPermissions = loadPermissions(response, parentRecordId, recordId, widgets, config);
        response.put('relatedRecordDefaults', JSON.serialize(getExistingRelations(parentRecordId, recordId, widgets, config)));
        //Map<Id,Set<ID>> existingRecordsByWidget = extractExistingRelations(existingPermissions, widgets);
        //response.put('relatedRecordDefaults', JSON.serialize(existingRecordsByWidget));

        if (String.isNotBlank(config.Admin_Profiles__c)) {
            Set<String> adminProfileIds = new Set<String>(Common_Type.convertDelimitedStringToTrimmedList(config.Admin_Profiles__c,';'));
            response.put('userIsAdminJSON', adminProfileIds.contains(UserInfo.getProfileId()) + '');
        }
        response.put('enableRowSecurityJSON', '' + (String.isNotBlank(config.Contact_Security_Field__c) && String.isNotBlank(config.Permission_Security_Field__c)));
        response.put('securityGroupsJSON', JSON.serialize(getUserSecurityAccess(config.Contact_Security_Field__c)));
        List<String> customPermissionNames = getUserCustomPermissions();
        response.put('customPmsAPINamesJSON', JSON.serialize(customPermissionNames));

        Boolean isReadOnly = false;
        if(!String.isBlank(config.Access_Custom_Permissions__c)){
            Set<String> accessibleCustomPermissions = Common_Type.convertDelimitedStringToTrimmedSet(config.Access_Custom_Permissions__c, ';');
            accessibleCustomPermissions.retainAll(customPermissionNames);
            if(accessibleCustomPermissions.isEmpty()){
                isReadOnly = true;
            }
        }
        response.put('readOnly', String.valueOf(isReadOnly));

        List<String> sObjectNames = new List<String>();
        List<String> pmsFieldNames = new List<String>();
        for (SmartWidget__c sw : widgets) {
            if (!sObjectNames.isEmpty() && (config.Primary_Junction_Object_Type__c.trim().equalsIgnoreCase(sw.Object__c) ||
                config.Primary_Junction_Object_Type__c.trim().equalsIgnoreCase(sw.AutoComplete_Search_Object__c))) {
                sObjectNames.add(0, config.Primary_Junction_Object_Type__c.trim());
                pmsFieldNames.add(0, sw.Field__c.trim());
            } else {
                if (String.isNotBlank(sw.AutoComplete_Search_Object__c)) {
                    sObjectNames.add(sw.AutoComplete_Search_Object__c.trim());
                } else {
                    sObjectNames.add(sw.Object__c.trim());
                }
                pmsFieldNames.add(sw.Field__c.trim());
            }
        }
        response.put('sObjectNamesJSON', JSON.serialize(sObjectNames));
        List<String> sObjectLabels = new List<String>();
        for (String sObjName : sObjectNames) {
            sObjectLabels.add(Common_Schema.getSObjectType(sObjName).getDescribe().getLabelPlural());
        }
        response.put('sObjectLabelsJSON', JSON.serialize(sObjectLabels));
        response.put('pmsFieldNamesJSON', JSON.serialize(pmsFieldNames));
        response.put('permissionLabel',JSON.serialize(Common_Schema.getSObjectType(NAMESPACE+'Permission__c').getDescribe().getLabelPlural()));

        List<PermissionWrapper> pmsWrappers = new List<PermissionWrapper>();
        Integer longestTypeSize = 1;
        for (Permission_Type__c pt : permissionTypes) {
            PermissionWrapper pw = new PermissionWrapper(pt,urlDefaultedPermissions.contains(pt.Id));
            pw.width = (100 / permissionTypes.size()) + '%';
            pmsWrappers.add(pw);

            if (pt.Name.length() > longestTypeSize) {
                longestTypeSize = pt.Name.length();
            }
        }
        //response.put('permissionWrappersJSON', JSON.serialize(pmsWrappers));

        List<PermissionWrapper> pmsCtrlWrappers = new List<PermissionWrapper>();
        for (Permission_Type__c pt : permissionTypes) {
            PermissionWrapper pw = new PermissionWrapper(pt.Id);
            pw.width = (100 / permissionTypes.size()) + '%';
            pmsCtrlWrappers.add(pw);
        }
        response.put('pmsCtrlWrappersJSON', JSON.serialize(pmsCtrlWrappers));

        Integer rowHeadersSize = config.Headers__c.split(';').size() - 1;
        RowObject rowObj = new RowObject();
        rowObj.pmsList = pmsWrappers;
        for (Integer i = 0; i < rowHeadersSize; i ++) {
            rowObj.subRecords.add(new ObjectWrapper());
        }
        response.put('rowObjectJSON', JSON.serialize(rowObj));

        KeyObject keyObj = new KeyObject();
        keyObj.pmsList = pmsCtrlWrappers;
        keyObj.rowLabelWidth = (100 / rowHeadersSize) + '%';
        response.put('keyObjectJSON', JSON.serialize(keyObj));


        response.put('isSandbox', String.valueOf([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox));

        return response;
    }

    @AuraEnabled
    public static Map<String,String> loadAdditionalPermissions(Map<String,String> params) {
        Map<String,String> response = params;
        String parentRecordId = response.remove('parentRecordId');
        String childId = response.remove('childId');
        List<SmartWidget__c> widgets = (List<SmartWidget__c>)JSON.deserialize(response.remove('widgets'), List<SmartWidget__c>.class);
        Permission_Configuration__mdt config = (Permission_Configuration__mdt)JSON.deserialize(response.remove('config'), Permission_Configuration__mdt.class);
        Map<String,List<String>> selectedIdMap = null;
        if (String.isNotBlank(response.get('selectedIdMap'))) {
            selectedIdMap = (Map<String,List<String>>)JSON.deserialize(response.remove('selectedIdMap'), Map<String,List<String>>.class);
        }
        List<String> lowerBound = null;
        if (String.isNotBlank(response.get('lowerBound'))) {
            lowerBound = (List<String>)JSON.deserialize(response.remove('lowerBound'), List<String>.class);
        }

        if (config.Limit_Query__c != null) {
            permissionLimit = Integer.valueOf(config.Limit_Query__c);
        }

        Common_QueryBuilder query = getPmsQuery(parentRecordId, childId, widgets, config);
        if (lowerBound != null && !lowerBound.isEmpty()) {
            Common_QueryBuilder.LogicalGrouping lg = new Common_QueryBuilder.LogicalGrouping('OR');
            lg.subgroupings = new List<Common_QueryBuilder.LogicalGrouping>();
            lg.subgroupings.add(new Common_QueryBuilder.LogicalGrouping('AND'));
            for (Integer i = 0; i < pmsQueryOrderFields.size(); i++) {
                lg.subgroupings[0].filterElements.add(new Common_QueryBuilder.FilterElement(
                    pmsQueryOrderFields[i], new List<Object>{lowerBound[i]}, '>='
                ));
            }
            lg.filterElements.add(new Common_QueryBuilder.FilterElement(
                pmsQueryOrderFields[0], new List<Object>{lowerBound[0]}, '>'
            ));

            query.addWhereFilterSeries(lg);
        }
        if (selectedIdMap != null) {
            for (SmartWidget__c sw : widgets) {
                if (selectedIdMap.get(String.valueOf(sw.Id)) == null || selectedIdMap.get(String.valueOf(sw.Id)).isEmpty()) {
                    query.addWhereFilter(sw.Field__c + ' = NULL');
                } else {
                    query.addWhereFilter(sw.Field__c, selectedIdMap.get(String.valueOf(sw.Id)));
                }
            }
        }
        //System.debug(query.toString());
        //response.put('query', query.toString());

        List<Permission__c> existingPermissions = Database.query(query.toString());
        pmsQueryOrderValues = new List<String>();
        if (Test.isRunningTest()) {
            permissionLimit = existingPermissions.size() - 1;
        }
        if (existingPermissions.size() > permissionLimit) {
            //permissionLimit is equals to the last index
            SObject lastPms = existingPermissions.remove(permissionLimit);
            List<String> pmsWidgetValues = new List<String>();
            for (SmartWidget__c sw : widgets) {
                pmsWidgetValues.add(String.valueOf(lastPms.get(sw.Field__c)));
            }

            for (String orderField : pmsQueryOrderFields) {
                SObject tempPms = lastPms.clone(true, true);
                String keyFieldValue = '';
                List<String> fnList = orderField.split('\\.');
                for (Integer j = 0; j < fnList.size()-1; j++) {
                    tempPms = tempPms.getSObject(fnList[j]);
                }
                pmsQueryOrderValues.add(String.valueOf(tempPms.get(fnList[fnList.size()-1])));
            }

            Boolean removeLastPms = true;
            while (removeLastPms) {
                lastPms = existingPermissions[existingPermissions.size() - 1];
                for (Integer i = 0; i < widgets.size(); i++) {
                    removeLastPms = removeLastPms && (pmsWidgetValues[i].equals(String.valueOf(lastPms.get(widgets[i].Field__c))));
                }
                if (removeLastPms) {
                    existingPermissions.remove(existingPermissions.size() - 1);
                }
            }

            response.put('pmsQueryOrderValues', JSON.serialize(pmsQueryOrderValues));
        }

        response.put('existingData',JSON.serialize(existingPermissions));

        //Map<Id,Set<ID>> existingRecordsByWidget = extractExistingRelations(existingPermissions, widgets);
        //response.put('relatedRecordDefaults', JSON.serialize(existingRecordsByWidget));

        return response;
    }

    @AuraEnabled
    public static Map<String,String> savePermissionTable(Map<String,String> params) {
        Map<String,String> response = new Map<String,String>();
        try {
            List<Permission__c> updatePmsList = (List<Permission__c>)JSON.deserialize(params.remove('updatePmsList'), List<Permission__c>.class);
            List<Permission__c> insertPmsList = (List<Permission__c>)JSON.deserialize(params.remove('insertPmsList'), List<Permission__c>.class);

            Boolean hasSaveError = false;
            List<String> errorMessages = new List<String>();
            List<Permission__c> failedRecords = new List<Permission__c>();
            if (!updatePmsList.isEmpty()) {
                List<Database.SaveResult> srList = Common_Database.secureUpdate2(updatePmsList, false);
                for (Integer i = 0; i < srList.size(); i++) {
                    if (!srList[i].isSuccess()) {
                        hasSaveError = true;
                        errorMessages.add(srList[i].getErrors()[0].getMessage());
                        failedRecords.add(updatePmsList[i]);
                    }
                }
            }
            if (!insertPmsList.isEmpty()) {
                List<Database.SaveResult> srList = Common_Database.secureInsert2(insertPmsList, false);
                for (Integer i = 0; i < srList.size(); i++) {
                    if (srList[i].isSuccess()) {
                        System.debug('New Permission: ' + insertPmsList[i].Id);
                    } else {
                        hasSaveError = true;
                        errorMessages.add(srList[i].getErrors()[0].getMessage());
                        failedRecords.add(insertPmsList[i]);
                    }
                }
            }

            if (hasSaveError) {
                response.put('errorMsg', JSON.serialize(errorMessages));
                response.put('errorRecords', JSON.serialize(failedRecords));
            } else {
                response = loadAdditionalPermissions(params);
                response.put('successMsg', 'Save success!');
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            response.put('errorMsg', e.getMessage() + ' ' + e.getStackTraceString());
        }
        return response;
    }

    /********
    UTILITIES
    ********/
    private static Map<String,Set<String>> calcRelatedFields(Map<String,Set<String>> relatedObjectFieldMap, String parentObject, List<String> relatedFields){
        for(String relatedField:relatedFields){
            String parentFieldString;
            String childFieldString;

            if(relatedField.contains('.')) {
                parentFieldString = Common_Schema.getReferenceObjectName(parentObject,relatedField.substringBefore('.').trim().replace('__r','__c'));//Object from the relational field
                childFieldString = relatedField.substringAfter('.').trim();//"Field" from the relationship field; it may be another relationship!
            }else{
                parentFieldString = parentObject;//Base object name
                childFieldString = relatedField;//Field on the base object
            }
            Set<String> objectFieldsFromMap = relatedObjectFieldMap.get(parentFieldString);

            if(objectFieldsFromMap == null){
                objectFieldsFromMap = new Set<String>();
            }
            if(!childFieldString.contains('.')){
                objectFieldsFromMap.add(childFieldString);

                relatedObjectFieldMap.put(parentFieldString,objectFieldsFromMap);
            }else{
                relatedObjectFieldMap = calcRelatedFields(relatedObjectFieldMap,parentFieldString,childFieldString.split(','));
            }
        }

        return relatedObjectFieldMap;
    }

    private static Boolean confirmObjectAccess(Map<String,SObjectType> gd, String objectName,Set<String> fieldNames){
        DescribeSObjectResult sobType = gd.get(objectName).getDescribe();
        if(!fieldNames.isEmpty()){
            Map<String,SObjectField> fieldTypes = sobType.fields.getMap();
            for(String fieldName:fieldNames){
                if(
                    !fieldName.contains('.')
                        && fieldTypes.containsKey(fieldName)
                        && !fieldName.contains('__r')
                        && !fieldTypes.get(fieldName).getDescribe().isAccessible()
                    ){
                    return false;
                }
            }
        }

        return sobType.isAccessible();
    }

    private static void confirmObjectFieldAccess(Permission_Configuration__mdt config,List<SmartWidget__c> widgets){
        Map<String,SObjectType> gd = Schema.getGlobalDescribe();
        Set<String> fields = new Set<String>();
        List<String> columnFields = new List<String>();
        Map<String,Set<String>> relatedObjectFieldMap = new Map<String, Set<String>>();

        for(String columnField:config.Columns__c.split(';')){
            if(columnField.contains('.')){
                columnField = columnField.substringBefore('.').replace('__r','__c');
            }
            columnFields.add(columnField.trim());
        }
        fields.addAll(columnFields);

        if(!confirmObjectAccess(gd,NAMESPACE+'Permission__c',fields)){
            throw new SecurityException('Invalid access: You are missing access to required objects/fields for this view. Please contact your administrator.');
        }

        for(SmartWidget__c widget:widgets){
            system.debug(widget.Name+' '+widget.Id);
            Set<String> searchFields = new Set<String>();//E.x.: Contact fields
            if(widget.AutoComplete_Target_Field__c != null){
                searchFields.addAll(widget.AutoComplete_Target_Field__c.replace(' ','').split(','));//E.x: Name,Email
            }
            system.debug(widget.AutoComplete_Related_Field__c);
            if(widget.AutoComplete_Related_Field__c != null){//E.x.: Account__
                relatedObjectFieldMap = calcRelatedFields(relatedObjectFieldMap,widget.AutoComplete_Search_Object__c,widget.AutoComplete_Related_Field__c.split(','));
            }
            if(widget.AutoComplete_Target_Parent_Field__c != null){
                searchFields.add(widget.AutoComplete_Target_Parent_Field__c);//E.x.: AccountId
            }

            Set<String> targetFields = new Set<String>();//E.x.: Permission__c fields
            if(widget.Field__c != null){
                targetFields.add(widget.Field__c);//E.x.: Contact__c
            }
            if(widget.AutoComplete_Search_Fields__c != null) {
                relatedObjectFieldMap = calcRelatedFields(relatedObjectFieldMap,widget.AutoComplete_Search_Object__c,widget.AutoComplete_Search_Fields__c.split(','));
            }

            if(!confirmObjectAccess(gd,widget.AutoComplete_Search_Object__c,searchFields)){
                system.debug(widget.AutoComplete_Search_Object__c);
                throw new SecurityException('Invalid access: You are missing access to required objects/fields for this view. Please contact your administrator.');
            }
            if(!confirmObjectAccess(gd,widget.AutoComplete_Target_Object__c,targetFields)){
                system.debug(widget.AutoComplete_Target_Object__c);
                throw new SecurityException('Invalid access: You are missing access to required objects/fields for this view. Please contact your administrator.');
            }
        }
        system.debug('related object field map for verification: '+JSON.serialize(relatedObjectFieldMap));
        for(String objectName:relatedObjectFieldMap.keySet()){
            if(!confirmObjectAccess(gd,objectName,relatedObjectFieldMap.get(objectName))){
                system.debug('Object Name missing access: '+objectName);
                throw new SecurityException('Invalid access: You are missing access to required objects/fields for this view. Please contact your administrator.');
            }
        }
    }

    private static Map<String, Set<String>> getExistingRelations(String parentRecordId, String childId, List<SmartWidget__c> widgets, Permission_Configuration__mdt config) {
        String groupByField = 'group-by-field';
        String query = 'SELECT COUNT_DISTINCT(Id) recId, ' + groupByField + ' FROM ' + NAMESPACE + 'Permission__c WHERE '
            + 'GROUP BY ' + groupByField + ' LIMIT 500';
        String whereClause = '';
        if (String.isNotBlank(config.Permission_Filter__c)) {
            if (config.Permission_Filter__c.contains('parentId')) {
                config.Permission_Filter__c = config.Permission_Filter__c.replace('parentId', parentRecordId);
            }
            if (config.Permission_Filter__c.contains('childId')) {
                config.Permission_Filter__c = config.Permission_Filter__c.replace('childId', childId);
            }
            whereClause = 'WHERE ' + config.Permission_Filter__c;
        }
        query = query.replace('WHERE', whereClause);

        Map<String, Set<String>> relationsMap = new Map<String, Set<String>>();
        for (SmartWidget__c sw : widgets) {
            relationsMap.put(sw.Id, new Set<String>());
            String groupQuery = query.replaceAll(groupByField, sw.Field__c);
            System.debug(groupQuery);
            for (SObject obj : Database.query(groupQuery)) {
                relationsMap.get(sw.Id).add(String.valueOf(obj.get(sw.Field__c)));
            }
            relationsMap.get(sw.Id).remove(null);
            relationsMap.get(sw.Id).remove('');
        }

        return relationsMap;
    }

    public static Permission_Configuration__mdt loadPermissionConfig(String configurationName){
        List<Permission_Configuration__mdt> configRecords =
        [SELECT Id, DeveloperName, MasterLabel, Label, Parent_Field__c, API_Name__c, Related_Object_Widgets__c, Related_Data_Field_Mapping__c,
            Columns__c, Headers__c, Primary_Junction_Object_Type__c, Display_Alert_Icons__c, Contact_Security_Field__c, Permission_Security_Field__c,
            Admin_Profiles__c, Header_Angle__c, Permission_Type_Filter__c, Permission_Filter__c, Access_Custom_Permissions__c, Partial_Save_Message__c,
            Limit_Pagination__c, Limit_Query__c, Save_Mode__c
        FROM Permission_Configuration__mdt
        WHERE API_Name__c =: configurationName
        ];

        if(configRecords.isEmpty()){
            throw new AuraHandledException('Unable to location configuration for '+configurationName+'. The system cannot load.');
        } else {
            return configRecords[0];
        }
    }

    public static List<Permission__c> loadPermissions(Map<String,String> response, String parentRecordId, String childId, List<SmartWidget__c> widgets, Permission_Configuration__mdt config){
        if (config.Limit_Query__c != null) {
            permissionLimit = Integer.valueOf(config.Limit_Query__c);
        }
        Common_QueryBuilder query = getPmsQuery(parentRecordId, childId, widgets, config);
        //response.put('query', query.toString());
        List<Permission__c> existingPermissions = (List<Permission__c>) Database.query(query.toString());
        //query.setRowLimit(permissionLimit);

        //Integer cutOffIndex = 0;
        pmsQueryOrderValues = new List<String>();
        if (existingPermissions.size() > permissionLimit) {
            //permissionLimit is equals to the last index
            SObject lastPms = existingPermissions.remove(permissionLimit);
            List<String> pmsWidgetValues = new List<String>();
            for (SmartWidget__c sw : widgets) {
                pmsWidgetValues.add(String.valueOf(lastPms.get(sw.Field__c)));
            }

            for (String orderField : pmsQueryOrderFields) {
                SObject tempPms = lastPms.clone(true, true);
                String keyFieldValue = '';
                List<String> fnList = orderField.split('\\.');
                for (Integer j = 0; j < fnList.size()-1; j++) {
                    tempPms = tempPms.getSObject(fnList[j]);
                }
                pmsQueryOrderValues.add(String.valueOf(tempPms.get(fnList[fnList.size()-1])));
            }

            Boolean removeLastPms = true;
            while (removeLastPms) {
                lastPms = existingPermissions[existingPermissions.size() - 1];
                for (Integer i = 0; i < widgets.size(); i++) {
                    removeLastPms = removeLastPms && (pmsWidgetValues[i].equals(String.valueOf(lastPms.get(widgets[i].Field__c))));
                }
                if (removeLastPms) {
                    existingPermissions.remove(existingPermissions.size() - 1);
                }
            }
        }
        response.put('pmsQueryOrderValues', JSON.serialize(pmsQueryOrderValues));
        response.put('existingData',JSON.serialize(existingPermissions));
        return existingPermissions;
    }

    public static List<Permission_Type__c> loadPermissionTypes(String whereFilter){
        String query = 'SELECT Id,Name,';
        query += NAMESPACE+'Label_Color__c,';
        query += NAMESPACE+'Default_Active__c,';
        query += NAMESPACE+'Default_Alert__c,';
        query += NAMESPACE+'Document_Edit_Permissions__c,';
        query += NAMESPACE+'Notification_Edit_Permissions__c,';
        query += NAMESPACE+'Order__c';
        query += ' FROM '+NAMESPACE+'Permission_Type__c ';

        if(!String.isBlank(whereFilter)){
            query += ' where '+whereFilter;
        }

        query += ' ORDER BY '+NAMESPACE+'Order__c';

        system.debug(query);

        return (List<Permission_Type__c>)Database.query(query);
    }

    public static List<SmartWidget__c> loadSmartWidgets(String relatedWidgets){
        Set<String> widgetNames = new Set<String>();
        widgetNames.addAll(Common_Type.convertDelimitedStringToTrimmedList(relatedWidgets,';'));

        List<SmartWidget__c> widgets = new List<SmartWidget__c>();

        Map<String,SmartWidget__c> allWidgets = SmartWidget__c.getAll();

        for(String widgetName:widgetNames){
            if(allWidgets.containsKey(widgetName)){
                widgets.add(allWidgets.get(widgetName));
            } else {
                throw new AuraHandledException('Unable to locate SmartWidget configuration for related list: '+widgetName);
            }
        }

        return widgets;
    }

    public static Map<String,String> getAllObjectIconMap() {
        Map<String,String> iconMap = new Map<String,String>();

        for (Schema.DescribeTabSetResult tabset : Schema.describeTabs()) {
            for (Schema.DescribeTabResult tab : tabset.getTabs()) {
                String sObjName = tab.getSobjectName().toLowerCase();
                if (tabset.isSelected() || String.isBlank(iconMap.get(sObjName))) {
                    for (Schema.DescribeIconResult icon : tab.getIcons()) {
                        String urlString = icon.getUrl();
                        if (String.isNotBlank(urlString) && urlString.endsWith('.svg')) {
                            List<String> urlTokens = urlString.split('/');
                            Integer size = urlTokens.size();
                            iconMap.put(sObjName, urlTokens[size-2] + ':' + urlTokens[size-1].removeEnd('.svg'));
                            break;
                        }
                    }
                }
            }
        }

        return iconMap;
    }

    public static String getParentRecord(String sourceRecordId, String targetField, String sourceObjectType){
        String query = 'select '+ targetField+ ' from '+ sourceObjectType+' where Id = \''+sourceRecordId+'\'';
        system.debug(query);
        return String.valueOf(Database.query(query)[0].get(targetField));
    }

    private static Common_QueryBuilder getPmsQuery(String parentRecordId, String childId, List<SmartWidget__c> widgets, Permission_Configuration__mdt config) {
        String permissionObjectName = NAMESPACE + 'Permission__c';
        String primaryObjectType = config.Primary_Junction_Object_Type__c;
        String securityField = config.Permission_Security_Field__c;
        Common_QueryBuilder query = new Common_QueryBuilder(permissionObjectName);

        query.addQueryField(NAMESPACE+'Permission_Type__c');
        query.addQueryField(NAMESPACE+'Status__c');
        query.addQueryField(NAMESPACE+'Alert_Status__c');
        query.addQueryField('Id');

        if(!String.isBlank(securityField)) {
            for(String splitSecurityField : Common_Type.convertDelimitedStringToTrimmedList(securityField,';')){
                if (String.isNotBlank(splitSecurityField)) {
                    query.addQueryField(splitSecurityField);
                }
            }
        }

        pmsQueryOrderFields = new List<String>();
        if (String.isNotBlank(config.Columns__c)) {
            for (String fieldName : Common_Type.convertDelimitedStringToTrimmedList(config.Columns__c,';')) {
                if(String.isNotBlank(fieldName)){
                    query.addQueryField(fieldName);

                    if (!fieldName.endsWithIgnoreCase('.Name')) {
                        fieldName = fieldName.replace('__c', '__r') + '.Name';
                    }
                    pmsQueryOrderFields.add(fieldName);
                    query.addOrderField(fieldName);
                }
            }
        }

        if (String.isNotBlank(config.Permission_Filter__c)) {
            if (config.Permission_Filter__c.contains('parentId')) {
                config.Permission_Filter__c = config.Permission_Filter__c.replace('parentId', parentRecordId);
            }
            if (config.Permission_Filter__c.contains('childId')) {
                config.Permission_Filter__c = config.Permission_Filter__c.replace('childId', childId);
            }
            query.extendWhereFilter(config.Permission_Filter__c);
        }

        for (SmartWidget__c sw:widgets) {
            String widgetRelationshipField = Common_Schema.getPrintableRelationshipPath(permissionObjectName,sw.Field__c);
            query.addQueryField(widgetRelationshipField);
            query.addQueryField(sw.Field__c);
        }

        permissionQuery = query.clone();
        query.setRowLimit(permissionLimit + 1);
        system.debug(query.toString());
        return query;
    }

    public static String getRecordIcon(String recordID,Map<String,String> allIconMap){
        system.debug('RecordId for Icon: '+recordID);
        String objectName = Common_Schema.getObjectNameFromId(recordID);
        String iconString = allIconMap.get(objectName.toLowerCase());

        system.debug('Object Name: '+' Icon String: '+iconString);
        system.debug(allIconMap);

        if(iconString == null){
            iconString = 'standard:record';
        }
        return iconString;
    }

    private static List<String> getUserCustomPermissions() {
        Set<Id> permissionSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()]) {
            permissionSetIds.add(psa.PermissionSetId);
        }
        Set<String> customPermissionAPINames = new Set<String>();
        for (CustomPermission cp : [
            SELECT Id, DeveloperName, (SELECT Id FROM SetupEntityAccessItems
            WHERE (Parent.Profile.Id = :UserInfo.getProfileId())
            OR (ParentId IN :permissionSetIds))
            FROM CustomPermission
        ]) {
            if (cp.SetupEntityAccessItems != null && !cp.SetupEntityAccessItems.isEmpty()) {
                customPermissionAPINames.add(cp.DeveloperName);
            }
        }
        List<String> cpaNames = new List<String>();
        cpaNames.addAll(customPermissionAPINames);
        customPermissionAPINames = null;
        permissionSetIds = null;
        return cpaNames;
    }

    public static List<String> getUserSecurityAccess(String securityField) {
        List<String> securityKeys = new List<String>();
        if (String.isNotBlank(securityField)) {
            String query = 'select id, '+securityField+','+NAMESPACE+'Employee_User__r.ProfileId from Contact where '
                +NAMESPACE+'Employee_User__c =\''+UserInfo.getUserId()+'\' limit 1';
            system.debug(query);
            List<Contact> userContacts = (List<Contact>)Database.query(query);
            if (userContacts != null && !userContacts.isEmpty() && userContacts[0].get(securityField) != null) {
                for (String key : String.valueOf(userContacts[0].get(securityField)).split(';')) {
                    securityKeys.add(key.trim());
                }
            }
        }
        return securityKeys;
    }

    /*******
    WRAPPERS
    *******/
    public class KeyObject {
        @AuraEnabled public Boolean display {get; set;}
        @AuraEnabled public Boolean selected {get; set;}
        @AuraEnabled public ObjectWrapper record {get; set;}
        @AuraEnabled public List<PermissionWrapper> pmsList {get; set;}
        @AuraEnabled public List<RowObject> rows {get; set;}
        @AuraEnabled public String rowLabelWidth {get; set;}
        @AuraEnabled public PermissionWrapper pmsRowCtrl {get; set;}

        public KeyObject() {
            this.display = true;
            this.selected = true;
            this.record = new ObjectWrapper();
            this.pmsList = new List<PermissionWrapper>();
            this.rows = new List<RowObject>();
            this.pmsRowCtrl = new PermissionWrapper('');
        }
    }

    public class RowObject {
        @AuraEnabled public String rowId {get; set;}
        @AuraEnabled public List<ObjectWrapper> subRecords {get; set;}
        @AuraEnabled public List<PermissionWrapper> pmsList {get; set;}
        @AuraEnabled public PermissionWrapper pmsRowCtrl {get; set;}
        @AuraEnabled public Boolean display {get; set;}

        public RowObject() {
            this.rowId = '';
            this.subRecords = new List<ObjectWrapper>();
            this.pmsList = new List<PermissionWrapper>();
            this.pmsRowCtrl = new PermissionWrapper('');
            this.display = true;
        }
    }

    public class PermissionWrapper {
        @AuraEnabled public Permission__c permission {get; set;}
        @AuraEnabled public String width {get; set;}
        @AuraEnabled public String documentEditPermissions {get; set;}
        @AuraEnabled public String notificationEditPermissions {get; set;}
        @AuraEnabled public Boolean disableStatus {get; set;}
        @AuraEnabled public Boolean disableAlert {get; set;}
        @AuraEnabled public Boolean enableSecurityDocument {get; set;}
        @AuraEnabled public Boolean enableSecurityNotification {get; set;}

        public PermissionWrapper(String typeId) {
            this.permission = new Permission__c(
                Permission_Type__c = null,
                Status__c = 'Inactive',
                Alert_Status__c = 'Inactive'
            );
            if (String.isNotBlank(typeId)) {
                this.permission.Permission_Type__c = typeId;
            }
            this.width = '100%';
            this.documentEditPermissions = '';
            this.notificationEditPermissions = '';
            this.disableStatus = false;
            this.disableAlert = false;
            this.enableSecurityDocument = false;
            this.enableSecurityNotification = false;
        }

        public PermissionWrapper(Permission_Type__c pt, Boolean urlDefaulted) {
            this.permission = new Permission__c(
                Permission_Type__c = pt.Id,
                Status__c = (pt.Default_Active__c || urlDefaulted) ? 'Active' : 'Inactive',
                Alert_Status__c = pt.Default_Alert__c ? 'Active' : 'Inactive'
            );
            this.width = '100%';
            this.documentEditPermissions = String.isBlank(pt.Document_Edit_Permissions__c) ? '' : (pt.Document_Edit_Permissions__c + ';');
            this.notificationEditPermissions = String.isBlank(pt.Notification_Edit_Permissions__c) ? '' : (pt.Notification_Edit_Permissions__c + ';');
            this.disableStatus = false;
            this.disableAlert = false;
            this.enableSecurityDocument = !String.isBlank(pt.Document_Edit_Permissions__c);
            this.enableSecurityNotification = !String.isBlank(pt.Notification_Edit_Permissions__c);
        }
    }

    public class ObjectWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String recordId {get; set;}
        @AuraEnabled public String relatedRecordId {get; set;}
    }

}