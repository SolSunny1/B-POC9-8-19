global with sharing class ManagePermission_Controller {
    List<String> widgetNames = new List<String>();
    Map<String,SmartWidget__c> SearchWidgets; //By Name
    Map<String,SmartWidget__c> FieldWidgets;//By Name

    private static final string NAMESPACE = '';
    private static Integer permissionLimit = 1000;
    private static Common_QueryBuilder permissionQuery;
    //private static List<String> keyFieldClause;
    private static String keyFieldName;
    private static List<Permission_Type__c> permissionTypes;

    @AuraEnabled
    public static Map<String,String> initializeComponent(Map<String,String> params) {
        Map<String,String> response = new Map<String,String>();
        Set<String> urlDefaultedPermissions = new Set<String>();
        ID recordId = (ID) params.get('recordId');
        Permission_Configuration__mdt config = loadPermissionConfig(params.get('configurationName'));
        response.put('config', JSON.serialize(config));

        permissionTypes = loadPermissionTypes(config.Permission_Type_Filter__c);
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

        String parentRecordId = getParentRecord(params.get('recordId'), config.Parent_Field__c, Common_Schema.getObjectNameFromId(recordId));
        response.put('parentRecordId', parentRecordId);

        List<Permission__c> existingPermissions = loadPermissions(response, parentRecordId, recordId, widgets, config);
        Map<Id,Set<ID>> existingRecordsByWidget = extractExistingRelations(existingPermissions, widgets);
        response.put('relatedRecordDefaults', JSON.serialize(existingRecordsByWidget));

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

    private static Map<String,Set<String>> calcRelatedFields(Map<String,Set<String>> relatedObjectFieldMap, String parentObject, List<String> relatedFields){
        for(String relatedField:relatedFields){
            String parentFieldString;
            String childFieldString;

            if(relatedField.contains('.')) {
                String referenceFieldName = relatedField.contains('__r')?relatedField.substringBefore('.').replace('__r','__c'):(relatedField.substringBefore('.')+'Id');
                parentFieldString = Common_Schema.getReferenceObjectName(parentObject,referenceFieldName);//Object from the relational field
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

    private static boolean confirmObjectAccess(Map<String,SObjectType> gd, String objectName,Set<String> fieldNames){
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

    public static Permission_Configuration__mdt loadPermissionConfig(String configurationName){
        List<Permission_Configuration__mdt> configRecords =
        [SELECT Id, DeveloperName, MasterLabel, Label, Parent_Field__c, API_Name__c, Related_Object_Widgets__c, Related_Data_Field_Mapping__c,
                Columns__c, Headers__c, Primary_Junction_Object_Type__c, Display_Alert_Icons__c, Contact_Security_Field__c, Permission_Security_Field__c,
                Admin_Profiles__c, Header_Angle__c, Permission_Type_Filter__c, Permission_Filter__c, Access_Custom_Permissions__c, Partial_Save_Message__c,
                Limit_Pagination__c, Limit_Query__c, Save_Mode__c, Filter_Based_On_Primary_Object__c, Data_Limit_Warning__c
        FROM Permission_Configuration__mdt
        WHERE API_Name__c =: configurationName
        ];

        if(configRecords.isEmpty()){
            throw new AuraHandledException('Unable to location configuration for '+configurationName+'. The system cannot load.');
        } else {
            return configRecords[0];
        }
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

    public static String getParentRecord(String sourceRecordId, String targetField, String sourceObjectType){
        String query = 'select '+ targetField+ ' from '+ sourceObjectType+' where Id = \''+sourceRecordId+'\'';
        system.debug(query);
        return String.valueOf(Database.query(query)[0].get(targetField));
    }

    private static Common_QueryBuilder getPmsQuery(String parentRecordId, String childId, List<SmartWidget__c> widgets, Permission_Configuration__mdt config) {
        String permissionObjectName = NAMESPACE + 'Permission__c';
        //config.Primary_Junction_Object_Type__c, config.Parent_Field__c, config.Permission_Security_Field__c
        String primaryObjectType = config.Primary_Junction_Object_Type__c;
        String primaryParentField = config.Parent_Field__c;
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
        if (String.isNotBlank(config.Columns__c)) {
            for (String fieldName : Common_Type.convertDelimitedStringToTrimmedList(config.Columns__c,';')) {
                if(String.isNotBlank(fieldName)){
                    query.addQueryField(fieldName);
                }
            }
        }

        for(SmartWidget__c sw:widgets){
            if(primaryObjectType.trim().equalsIgnoreCase(sw.Object__c.trim()) && config.Filter_Based_On_Primary_Object__c) {
                String primaryObjectField;
                if (sw.Field__c.endsWith('__c')) {
                    primaryObjectField = sw.Field__c.replace('__c', '__r') + '.' + sw.AutoComplete_Target_Parent_Field__c;
                } else {
                    primaryObjectField = sw.Field__c.substring(0, sw.Field__c.length() - 3) + '.' + sw.AutoComplete_Target_Parent_Field__c;
                }

                query.addWhereFilter(primaryObjectField,parentRecordId,'=');
            }

            String widgetRelationshipField = Common_Schema.getPrintableRelationshipPath(permissionObjectName,sw.Field__c);
            query.addQueryField(widgetRelationshipField);
            query.addQueryField(sw.Field__c);

            if (String.isNotBlank(sw.Field__c) && String.isNotBlank(sw.Object__c)) {
                String orderField = sw.Field__c.replace('__c','__r') + '.' + Common_Schema.getNameField(sw.Object__c);
                query.addOrderField(orderField);
                if (String.isBlank(keyFieldName)) {
                    keyFieldName = orderField;
                }
            }
        }

        if(!String.isBlank(config.Permission_Filter__c)){
            query.extendWhereFilter(config.Permission_Filter__c.replace('parentId',parentRecordId).replace('childId',childId));
        }

        permissionQuery = query.clone();

        query.setRowLimit(permissionLimit);
        system.debug(query.toString());
        return query;
    }

    public static List<Permission__c> loadPermissions(Map<String,String> response, String parentRecordId, String childId, List<SmartWidget__c> widgets, Permission_Configuration__mdt config){
        if (config.Limit_Query__c != null) {
            permissionLimit = Integer.valueOf(config.Limit_Query__c);
        }
        Common_QueryBuilder query = getPmsQuery(parentRecordId, childId, widgets, config);
        List<Permission__c> existingPermissions = (List<Permission__c>) Database.query(query.toString());

        Integer cutOffIndex = 0;
        if (existingPermissions.size() >= permissionLimit) {
            List<String> overloadKeyObjs = new List<String>();
            List<String> fnList = keyFieldName.split('\\.');

            SObject firstPermission = existingPermissions[0];
            SObject lastPermission = existingPermissions[existingPermissions.size()-1];
            for (Integer j = 0; j < fnList.size()-1; j++) {
                firstPermission = firstPermission.getSObject(fnList[j]);
                lastPermission = lastPermission.getSObject(fnList[j]);
            }

            Integer numberOfPermissionTypes = permissionTypes.size();
            Integer worstPermissionTypeIndex;
            for(cutoffIndex = existingPermissions.size()-1;cutoffIndex>=0;cutoffIndex--){
                Permission__c p = existingPermissions[cutOffIndex];
                if(permissionTypes[numberOfPermissionTypes-1].Id == p.Permission_Type__c){
                    //don't bother, we stopped at the end of a row
                    break;
                }

                //what we're doing is stepping backwards, trying to find the last complete row.
                //which is then used as the starting point for the next query. The extra data is dropped.
                Boolean recordIsLastInRow = false;
                for(Integer typeIndex=0;typeIndex<numberOfPermissionTypes;typeIndex++){
                    if(p.Permission_Type__c == permissionTypes[typeIndex].Id){
                        if(worstPermissionTypeIndex == null || worstPermissionTypeIndex>typeIndex){
                            worstPermissionTypeIndex = typeIndex;
                        } else if(worstPermissionTypeIndex <= typeIndex){
                            recordisLastInRow = true;
                        }
                    }
                }

                if(recordIsLastInRow){
                    break;
                }
            }

            //we couldn't locate a valid break point, so the valid break point is the last record.
            //This typically only happens when there's only one row of data
            if(cutoffIndex == 0){
                cutOffIndex = existingPermissions.size()-1;
            }


            Map<String, String> cutoffValues = new Map<String, String>();
            for(SmartWidget__c sw:widgets){
                String widgetSortField = sw.Field__c.replace('__c','__r') + '.' + Common_Schema.getNameField(sw.Object__c);
                String widgetFieldValue = String.valueOf(Common_SObject.getSObjectFieldValue(existingPermissions[cutOffIndex],widgetSortField));
                cutOffValues.put(sw.Name, widgetFieldValue);
            }



            String keyFieldValue = String.valueOf(lastPermission.get(fnList[fnList.size()-1]));
            Boolean pmsOverload = String.valueOf(firstPermission.get(fnList[fnList.size()-1])).equals(keyFieldValue);
            if (pmsOverload) {
                response.put('pmsOverload', 'true');
            } else {
                for (Integer i = permissionLimit-1; i > 0; i--) {
                    SObject keyFieldObj = existingPermissions[i];
                    for (Integer j = 0; j < fnList.size()-1; j++) {
                        keyFieldObj = keyFieldObj.getSObject(fnList[j]);
                    }
                    String tempKeyFieldValue = String.valueOf(keyFieldObj.get(fnList[fnList.size()-1]));
                    if (String.isNotBlank(keyFieldValue) && !keyFieldValue.equals(tempKeyFieldValue)) {
                        keyFieldValue = tempKeyFieldValue;
                        break;
                    } else {
                        keyFieldValue = tempKeyFieldValue;
                    }
                }
                System.debug('cut off index: ' + cutOffIndex);
                if (cutOffIndex > 0) {
                    for (Integer i = existingPermissions.size() - 1; i > cutOffIndex; i--) {
                        existingPermissions.remove(i);
                    }
                }
            }

            response.put('keyFieldName', keyFieldName);
            response.put('keyFieldValue', keyFieldValue);
            response.put('cutOffValues', JSON.serialize(cutOffValues));
        }

        response.put('existingData',JSON.serialize(existingPermissions));
        return existingPermissions;
    }

    @AuraEnabled
    public static Map<String,String> loadAdditionalPermissions(Map<String,String> params) {
        Map<String,String> response = params;
        Map<String,String> cutOffValues = (Map<String, String>) JSON.deserialize(params.get('cutOffValues'),Map<String, String>.class);
        permissionTypes = (List<Permission_Type__c>) JSON.deserialize(params.get('permissionTypesJSON'),List<Permission_Type__c>.class);
        String parentRecordId = params.get('parentRecordId');
        String childId = params.get('childId');
        List<SmartWidget__c> widgets = (List<SmartWidget__c>)JSON.deserialize(params.get('widgets'), List<SmartWidget__c>.class);
        Permission_Configuration__mdt config = (Permission_Configuration__mdt)JSON.deserialize(params.get('config'), Permission_Configuration__mdt.class);

        if (config.Limit_Query__c != null) {
            permissionLimit = Integer.valueOf(config.Limit_Query__c);
        }

        Common_QueryBuilder query = getPmsQuery(parentRecordId, childId, widgets, config);

        Common_QueryBuilder.LogicalGrouping masterCutOffFilter = new Common_QueryBuilder.LogicalGrouping('OR');
        String buildingFilter = '';
        for(SmartWidget__c sw:widgets){
            String cutOffValue = cutOffValues.get(sw.Name);
            String filterField = sw.Field__c.replace('__c','__r') + '.' + Common_Schema.getNameField(sw.Object__c);
            String filterString = buildingFilter + filterField + '>';
            if(cutOffValue == 'null'){
                filterString += 'null';
            } else {
                filterString += '\''+cutOffValue+'\'';
            }

            Common_QueryBuilder.FilterElement fe = new Common_QueryBuilder.FilterElement('('+filterString+')');
            masterCutOffFilter.filterElements.add(fe);

            buildingFilter = filterString.replace('>','=')+ ' AND ';
        }
        query.addWhereFilterSeries(masterCutOffFilter);

        System.debug(query.toString());

        List<Permission__c> existingPermissions = Database.query(query.toString());

        Integer cutOffIndex = 0;
        if (existingPermissions.size() >= permissionLimit) {
            List<String> overloadKeyObjs = new List<String>();
            String keyFieldValue = '';
            List<String> fnList = keyFieldName.split('\\.');

            Integer numberOfPermissionTypes = permissionTypes.size();
            Integer worstPermissionTypeIndex;
            for(cutoffIndex = existingPermissions.size()-1;cutoffIndex>=0;cutoffIndex--){
                Permission__c p = existingPermissions[cutOffIndex];
                if(permissionTypes[numberOfPermissionTypes-1].Id == p.Permission_Type__c){
                    //don't bother, we stopped at the end of a row
                    break;
                }

                //what we're doing is stepping backwards, trying to find the last complete row.
                //which is then used as the starting point for the next query. The extra data is dropped.
                Boolean recordIsLastInRow = false;
                for(Integer typeIndex=0;typeIndex<numberOfPermissionTypes;typeIndex++){
                    if(p.Permission_Type__c == permissionTypes[typeIndex].Id){
                        if(worstPermissionTypeIndex == null || worstPermissionTypeIndex>typeIndex){
                            worstPermissionTypeIndex = typeIndex;
                        } else if(worstPermissionTypeIndex <= typeIndex){
                            recordisLastInRow = true;
                        }
                    }
                }

                if(recordIsLastInRow){
                    break;
                }
            }

            //we couldn't locate a valid break point, so the valid break point is the last record.
            //This typically only happens when there's only one row of data
            if(cutoffIndex == 0){
                cutOffIndex = existingPermissions.size()-1;
            }


            cutoffValues = new Map<String, String>();
            for(SmartWidget__c sw:widgets){
                String widgetSortField = sw.Field__c.replace('__c','__r') + '.' + Common_Schema.getNameField(sw.Object__c);
                String widgetFieldValue = String.valueOf(Common_SObject.getSObjectFieldValue(existingPermissions[cutOffIndex],widgetSortField));
                cutOffValues.put(sw.Name, widgetFieldValue);
            }

            Boolean pmsOverload = true;
            //while (pmsOverload) {
            SObject firstPermission = existingPermissions[0];
            SObject lastPermission = existingPermissions[existingPermissions.size()-1];
            for (Integer j = 0; j < fnList.size()-1; j++) {
                firstPermission = firstPermission.getSObject(fnList[j]);
                lastPermission = lastPermission.getSObject(fnList[j]);
            }
            keyFieldValue = String.valueOf(lastPermission.get(fnList[fnList.size()-1]));
            pmsOverload = String.valueOf(firstPermission.get(fnList[fnList.size()-1])).equals(keyFieldValue);
            if (pmsOverload) {
                /*overloadKeyObjs.add(keyFieldValue);
                query = permissionQuery.clone();
                query.addWhereFilter(keyFieldName, keyFieldValue, '>');
                query.setRowLimit(permissionLimit);

                existingPermissions = (List<Permission__c>) Database.query(query.toString());*/
                response.put('pmsOverload', 'true');
                //config.Limit_Query__c = existingPermissions.size() + 10;
                //config.Limit_Pagination__c = existingPermissions.size() + 10;
                //response.put('config', JSON.serialize(config));
            } else {
                for (Integer i = permissionLimit-1; i > 0; i--) {
                    SObject keyFieldObj = existingPermissions[i];
                    for (Integer j = 0; j < fnList.size()-1; j++) {
                        keyFieldObj = keyFieldObj.getSObject(fnList[j]);
                    }
                    String tempKeyFieldValue = String.valueOf(keyFieldObj.get(fnList[fnList.size()-1]));
                    if (String.isNotBlank(keyFieldValue) && !keyFieldValue.equals(tempKeyFieldValue)) {
                        keyFieldValue = tempKeyFieldValue;
                        break;
                    } else {
                        keyFieldValue = tempKeyFieldValue;
                    }
                }
                System.debug('cut off index: ' + cutOffIndex);
                if (cutOffIndex > 0) {
                    for (Integer i = existingPermissions.size() - 1; i > cutOffIndex; i--) {
                        existingPermissions.remove(i);
                    }
                }
            }
            response.put('keyFieldName', keyFieldName);
            response.put('keyFieldValue', keyFieldValue);
            response.put('cutOffValues', JSON.serialize(cutOffValues));
        } else {
            response.remove('keyFieldName');
            response.remove('keyFieldValue');
        }

        response.put('existingData',JSON.serialize(existingPermissions));

        Map<Id,Set<ID>> existingRecordsByWidget = extractExistingRelations(existingPermissions, widgets);
        response.put('relatedRecordDefaults', JSON.serialize(existingRecordsByWidget));

        return response;
    }

    public static Map<Id, Set<Id>> extractExistingRelations(List<Permission__c> permissions, List<SmartWidget__c> widgets){
        Map<Id, Set<Id>> relatedRecordsByWidget = new Map<Id,Set<Id>>();
        for(SmartWidget__c sw:widgets){
            relatedRecordsByWidget.put(sw.Id, new Set<ID>());
            for(Permission__c p:permissions){
                if(p.get(sw.Field__c) != null){
                    relatedRecordsByWidget.get(sw.Id).add(String.valueOf(p.get(sw.Field__c)));
                }
            }
        }

        return relatedRecordsByWidget;
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

    @AuraEnabled
    public static Map<String,String> savePermissionTable(Map<String,String> params) {
        Map<String,String> response = new Map<String,String>();
        try {
            List<Permission__c> pmsList = (List<Permission__c>)JSON.deserialize(params.get('pmsListJSON'), List<Permission__c>.class);

            System.debug('PM LIST: ' + pmsList.size());

            if(!pmsList.isEmpty()){
                List<Database.UpsertResult> results = Database.upsert(pmsList,false);

                Boolean hasSaveError = false;
                List<String> errorMessages = new List<String>();
                List<Permission__c> failedRecords = new List<Permission__c>();
                for(Integer i=0;i<results.size();i++){
                    Database.UpsertResult result = results[i];
                    Permission__c resultRecord = pmsList[i];
                    if(!result.isSuccess()){
                        system.debug(JSON.serialize(resultRecord));
                        system.debug(result.getErrors()[0].getMessage());

                        hasSaveError = true;
                        errorMessages.add(result.getErrors()[0].getMessage());
                        failedRecords.add(resultRecord);
                    }
                }

                if(!hasSaveError){
                    List<String> idList = new List<String>();
                    for(Permission__c p : pmsList) {
                        if (String.isNotBlank(p.Id)) {
                            idList.add(p.Id);
                        }
                    }
                    List<Permission__c> savedPermissions = new List<Permission__c>();
                    if (!idList.isEmpty()) {
                        Permission_Configuration__mdt config = (Permission_Configuration__mdt)JSON.deserialize(params.get('configJSON'), Permission_Configuration__mdt.class);
                        List<SmartWidget__c> widgets = (List<SmartWidget__c>)JSON.deserialize(params.get('widgetsJSON'), List<SmartWidget__c>.class);
                        savedPermissions = getPermissionsById(widgets, config, idList);
                    }
                    response.put('successMsg', 'Save success!');
                    response.put('savedPermissionsJSON', JSON.serialize(savedPermissions));
                } else {
                    response.put('errorMsg', JSON.serialize(errorMessages));
                    response.put('errorRecords', JSON.serialize(failedRecords));
                }
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            response.put('errorMsg', e.getMessage() + ' ' + e.getStackTraceString());
        }
        return response;
    }

    private static List<Permission__c> getPermissionsById(List<SmartWidget__c> widgets, Permission_Configuration__mdt config, List<String> idList) {
        String permissionObjectName = NAMESPACE + 'Permission__c';
        //config.Primary_Junction_Object_Type__c, config.Parent_Field__c, config.Permission_Security_Field__c
        String primaryObjectType = config.Primary_Junction_Object_Type__c;
        String primaryParentField = config.Parent_Field__c;
        String securityField = config.Permission_Security_Field__c;
        Common_QueryBuilder query = new Common_QueryBuilder(permissionObjectName);

        query.addQueryField(NAMESPACE+'Permission_Type__c');
        query.addQueryField(NAMESPACE+'Status__c');
        query.addQueryField(NAMESPACE+'Alert_Status__c');
        query.addQueryField('Id');

        if(!String.isBlank(securityField)) {
            for(String splitSecurityField : securityField.split(';')){
                if (String.isNotBlank(splitSecurityField)) {
                    query.addQueryField(splitSecurityField);
                }
            }

        }
        if (String.isNotBlank(config.Columns__c)) {
            for (String fieldName : config.Columns__c.split(';')) {
                if(String.isNotBlank(fieldName)){
                    query.addQueryField(fieldName);
                }
            }
        }

        for(SmartWidget__c sw:widgets){
            String widgetRelationshipField = Common_Schema.getPrintableRelationshipPath(permissionObjectName,sw.Field__c);
            query.addQueryField(widgetRelationshipField);
            query.addQueryField(sw.Field__c);

            if (String.isNotBlank(sw.Field__c) && String.isNotBlank(sw.Object__c)) {
                query.addOrderField(sw.Field__c.replace('__c','__r') + '.' + Common_Schema.getNameField(sw.Object__c));
            }
        }

        query.addWhereFilter('Id', idList);

        system.debug(query.toString());

        return (List<Permission__c>) Database.query(query.toString());
    }

    public class KeyObject {
        @AuraEnabled public Boolean selected {get; set;}
        @AuraEnabled public ObjectWrapper record {get; set;}
        @AuraEnabled public List<PermissionWrapper> pmsList {get; set;}
        @AuraEnabled public List<RowObject> rows {get; set;}
        @AuraEnabled public String rowLabelWidth {get; set;}
        @AuraEnabled public PermissionWrapper pmsRowCtrl {get; set;}

        public KeyObject() {
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
        @AuraEnabled public Boolean disabled {get; set;}

        public RowObject() {
            this.rowId = '';
            this.subRecords = new List<ObjectWrapper>();
            this.pmsList = new List<PermissionWrapper>();
            this.pmsRowCtrl = new PermissionWrapper('');
            this.disabled = false;
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