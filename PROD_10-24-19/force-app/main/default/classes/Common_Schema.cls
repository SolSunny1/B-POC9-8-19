global with sharing class Common_Schema{
    //Cache variables
    private static Map<String, Schema.SObjectType> sObjectTypeMap;
    private static Map<String, Schema.DescribesObjectResult> sObjectDescribeMap;
    private static Map<Schema.SObjectType, Schema.DescribesObjectResult> typeDescribeMap;

    private static Map<String, Map<String, Schema.SObjectField>> objectFieldMap;
    private static Map<String, Map<String, Schema.DescribeFieldResult>> fieldDescribeMap;

    private static Map<String, Map<String, ID>> recordTypeMap;

    //Deprecated
    global enum CustomSettingType {
        TYPE_LIST, TYPE_HIERARCHY
    }

    //-------------------------------------------------------------------------
    //  GLOBAL DESCRIBE METHODS
    //-------------------------------------------------------------------------
    global static Map<String, Schema.SObjectType> getGlobalDescribeMap(){
        if(sObjectTypeMap == null){
            sObjectTypeMap = Schema.getGlobalDescribe();
        }
        return sObjectTypeMap;
    }

    global static Map<String, String> getAllObjects() {
        Map<String, String> labelNameMap = new Map<String, String>();
        
        Map<String, Schema.SObjectType> gd = getGlobalDescribeMap();
        for (String objectName:gd.keyset()){
            DescribesObjectResult objectDescribe = getDescribe(objectName);
            if(objectDescribe.isCreateable() && objectDescribe.isQueryable() && !objectDescribe.customSetting) {
                labelNameMap.put(objectDescribe.getName(), objectDescribe.getLabel());
            } 
        }

        return labelNameMap;
    }

    //-------------------------------------------------------------------------
    //  NAMESPACE METHODS
    //-------------------------------------------------------------------------
    public static String getLocalName(String schemaName){
        if(schemaName.replace('__c','').contains('__')){
            return schemaName.subStringAfter('__');
        } else {
            return schemaName;
        }
    }

    global static string removeNamespace(string sFieldName) {
        List<String> lstParts = sFieldName.split('__');
        if (lstParts.size() == 3) {
            return lstParts.get(1) + '__' + lstParts.get(2);
        }
        else
            return sFieldName;     
    }

    //-------------------------------------------------------------------------
    //  CUSTOM SETTING METHODS
    //-------------------------------------------------------------------------
    public static Map<String, String> getAllCustomSettings(){
        Map<String, String> labelNameMap = new Map<String, String>();
        
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        for (String objectName:gd.keyset())
        {
            SObjectType fieldToken = gd.get(objectName);
            DescribesObjectResult objectDescribe = fieldToken.getDescribe();

            if(objectDescribe.isCreateable() && objectDescribe.isQueryable() && objectDescribe.customSetting) {
                labelNameMap.put(objectDescribe.getName(), objectDescribe.getLabel());
            } 
        }
        return labelNameMap;
    }

    //-------------------------------------------------------------------------
    //  SOBJECTYPE METHODS
    //-------------------------------------------------------------------------
    global static Schema.SObjectType getDescribeObject(string sObjectName) {
        if(sObjectTypeMap == null){
            getGlobalDescribeMap();
        }

        sObjectName = sObjectName.toLowerCase();
        Schema.SObjectType sObjType = sObjectTypeMap.get(sObjectName);
        
        // fall back to removing the namespace
        if (sObjType == null && sObjectName.contains('__c')){
            sObjectName = removeNamespace(sObjectName);
            system.debug('sObjectName without prefix: ' + sObjectName);
            sObjType = sObjectTypeMap.get(sObjectName);
        }
        
        // if all else fails, error
        if(sObjType == null){
            throw new Common_Exceptions.FatalApplicationException( 'Could not find describe object ' + sObjectName);
        }
        
        return sObjType;           
    }

    global static Schema.SObjectType getSObjectType(Id sobjectId){
        return sobjectId.getSobjectType();
    }

    global static Schema.SObjectType getSObjectType(String sobjectType){
        if(sObjectTypeMap == null){
            getGlobalDescribeMap();
        }
        Schema.SObjectType sObjType = sObjectTypeMap.get(sobjectType);
        if (sObjType == null && sobjectType.contains('__c')){
            sobjectType = removeNamespace(sobjectType);
            system.debug('sObjectName without prefix: ' + sobjectType);
            sObjType = sObjectTypeMap.get(sobjectType);
        }
        
        if(sObjType==null){
            throw new Common_Exceptions.SchemaException('No SObject type found for "' + sobjectType + '"');
        }
        
        return sObjType;
    }

    global static Schema.DescribeSObjectResult getDescribe(String sObjName){
        if(sObjectDescribeMap != null && sObjectDescribeMap.containsKey(sObjName)){
            return sObjectDescribeMap.get(sObjName);
        } else {
            Schema.SObjectType objectType = getSObjectType(sObjName);
            return getDescribe(objectType);
        }
    }

    global static Schema.DescribeSObjectResult getDescribe(Schema.SobjectType objectType){
        if(typeDescribeMap != null && typeDescribeMap.containsKey(objectType)){
            return typeDescribeMap.get(objectType);
        } else {
            if(sObjectDescribeMap == null){
                sObjectDescribeMap = new Map<String, Schema.DescribesObjectResult>();
            }
            if(typeDescribeMap == null){
                typeDescribeMap = new Map<Schema.SobjectType, Schema.DescribesObjectResult>();
            }
            Schema.DescribeSObjectResult result = objectType.getDescribe();
            typeDescribeMap.put(objectType, result);
            sObjectDescribeMap.put(result.getName(),result);

            return result;
        }
    }

    global static Schema.DescribeSObjectResult getDescribe(ID recordId){
        Schema.SObjectType objectType = getSObjectType(recordId);
        return getDescribe(objectType);
    }

    global static String getObjectNameFromId(Id rId){
        Schema.sObjectType objectType = getSObjectType(rId);
        DescribeSObjectResult objectDescribe = getDescribe(rId);

        return objectDescribe.getName();
    }

    global static String getObjectNameFromSObject(SObject sObj) {
        return getDescribe(sObj.getSObjectType()).getName();
    }

    public static String getObjectNameFromObjectType(Schema.SobjectType objectType){
        return getDescribe(objectType).getName();
    }

    global static Map<String, Schema.FieldSet> getFieldSets(String objectName){
        return getFieldSets(getSObjectType(objectName));
    }

    global static Map<String, Schema.FieldSet> getFieldSets(Schema.SobjectType objectType){
        return objectType.getDescribe().FieldSets.getMap();
    }

    //-------------------------------------------------------------------------
    //  FIELD METHODS
    //-------------------------------------------------------------------------
    global static Schema.SObjectField getField(String objectName, String fieldName){
        fieldName = fieldName.toLowerCase().trim();
        
        Map<String, Schema.SObjectField> fMap = getSobjectFields(objectName);

        Schema.SobjectField field;
        field = fMap.get(fieldName.trim());
        if (field == null) {
            field = fMap.get(removeNamespace(fieldName.trim()));
        }
        
        // if all else fails, error
        Common_Exceptions.assertError(field == null, 'Could not find describe field ' + fieldName);

        return field;
    }

    global static Schema.DescribeFieldResult getDescribeField(String objectName, String fieldName){
        if(fieldDescribeMap != null && fieldDescribeMap.containsKey(objectName)){
            Map<String, Schema.DescribeFieldResult> objectFieldDescribeMap = fieldDescribeMap.get(objectName);
            if(objectFieldDescribeMap.containsKey(fieldName)){
                return objectFieldDescribeMap.get(fieldName);
            } else {
                Schema.SObjectField objectField= getSObjectFields(objectName).get(fieldName);
                Schema.DescribeFieldResult fieldDescribe = objectField.getDescribe();

                objectFieldDescribeMap.put(fieldName, fieldDescribe);
                fieldDescribeMap.put(objectName,objectFieldDescribeMap);
                return fieldDescribe;
            }
        } else {
            if(fieldDescribeMap == null){
                fieldDescribeMap = new Map<String, Map<String, Schema.DescribeFieldResult>>();
            }

            Schema.SObjectField objectField = getSObjectFields(objectName).get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = objectField.getDescribe();

            fieldDescribeMap.put(objectName,new Map<String,Schema.DescribeFieldResult>{fieldName => fieldDescribe});
            return fieldDescribe;
        }
    }

    global static Map<String, Schema.SobjectField> getSobjectFields(String objectName){
        if(objectFieldMap != null && objectFieldMap.containsKey(objectName)){
            return objectFieldMap.get(objectName);
        } else {
            if(objectFieldMap == null){
                objectFieldMap = new Map<String, Map<String, Schema.SobjectField>>();
            }

            Schema.DescribeSObjectResult result = getDescribe(objectName);
            Map<String, Schema.SobjectField> fieldMap = result.fields.getMap();
            objectFieldMap.put(objectName, fieldMap);
            return fieldMap;
        }
    }

    global static Map<String, Schema.DescribeFieldResult> getDescribeFields(sObjectType sObjType){
        String objectName = getObjectNameFromObjectType(sObjType);
        return getDescribeFields(objectName);
    }

    public static Map<String, Schema.DescribeFieldResult> getDescribeFields(String objectName){
        if(fieldDescribeMap == null){
            fieldDescribeMap = new Map<String, Map<String, Schema.DescribeFieldResult>>();
        }

        Map<String, DescribeFieldResult> mapDescribeFields;
        if(fieldDescribeMap.containsKey(objectName)){
            mapDescribeFields = fieldDescribeMap.get(objectName);
        } else {
            mapDescribeFields = new Map<String, Schema.DescribeFieldResult>();
        }

        try {
            Map<String, Schema.SObjectField> mapSchemaFields = getSobjectFields(objectName);

            for(String fieldName:mapSchemaFields.keySet()){
                if(!mapDescribeFields.containsKey(fieldName)){
                    Schema.DescribeFieldResult dfr = getDescribeField(objectName, fieldName);
                    mapDescribeFields.put(dfr.getName(), dfr);
                }
            }

            fieldDescribeMap.put(objectName, mapDescribeFields);
        } 
        catch (Exception ex) {          
            ex.setMessage('Custom getDescribeFields: ' + ex.getMessage() + ' [' + ex.getStackTraceString() + ']');
            throw ex;
        }

        return mapDescribeFields;
    }

    global static String getNameField(sObjectType objectType){
        Map<String, DescribeFieldResult> fieldMap = getDescribeFields(objectType);
        for(DescribeFieldResult dfr:fieldMap.values()){
            if(dfr.isNameField()){
                return dfr.getName();
            }
        }
        //as far as I know this case should never happen
        return null;
    }

    global static String getReferenceObjectName(String baseObjectName, String fieldName){
        Schema.DescribeFieldResult dfr = getDescribeField(baseObjectName,fieldName);
        if(dfr != null){
            if(!dfr.getReferenceTo().isEmpty()){
                return getDescribe(dfr.getReferenceTo()[0]).getName();
            } else {
                return null;
            }
        }

        return null;
    }

    global static String getPrintableRelationshipPath(String baseObjectName, String fieldPath){
        if(!fieldPath.contains('.')){
            Schema.DescribeFieldResult dfr = getDescribeField(baseObjectName,fieldPath);
            if(dfr.getType() == Schema.DisplayType.REFERENCE){
                String newPath = dfr.getRelationshipName()+'.'+getNameField(dfr.getReferenceTo()[0]);
                return newPath;
            } else {
                return fieldPath;
            }
        } else {
            List<String> splitFieldPath = fieldPath.split('\\.');
            String currentObjectName = baseObjectName;
            for(Integer i=0;i<splitFieldPath.size();i++){
                String fieldSubPath = splitFieldPath[i];
                system.debug('Looking for field '+fieldSubPath +' on '+currentObjectName);

                if(i == splitFieldPath.size()-1){
                    Schema.DescribeFieldResult dfr = getDescribeField(currentObjectName,fieldSubPath);
                    if(dfr.getType() == Schema.DisplayType.REFERENCE){
                        system.debug('returning '+fieldPath.subStringBeforeLast('.')+'.'+dfr.getRelationshipName()+'.'+getNameField(dfr.getReferenceTo()[0]));
                        return fieldPath.subStringBeforeLast('.')+'.'+dfr.getRelationshipName()+'.'+getNameField(dfr.getReferenceTo()[0]);
                    } else {
                        return fieldPath;
                    }
                } else {
                    if(fieldSubPath.endsWith('__r')){
                        fieldSubPath = fieldSubPath.replace('__r','__c');
                    } else {
                        fieldSubPath = fieldSubPath+'ID';
                    }

                    Schema.DescribeFieldResult dfr = getDescribeField(currentObjectName,fieldSubPath);
                    currentObjectName = getDescribe(dfr.getReferenceTo()[0]).getName();
                }
            }

            return fieldPath;
        }
    }

    global static Schema.DescribeFieldResult getRelationshipField(String baseObjectName, String fieldPath){
        if(!fieldPath.contains('.')){
            return getDescribeField(baseObjectName,fieldPath);
        } else {
            String currentObjectName = baseObjectName;
            String currentObjectField = fieldPath.subStringBefore('.');

            if(currentObjectField.endsWith('__r')){
                currentObjectField = currentObjectField.replace('__r','__c');
            } else {
                currentObjectField = currentObjectField+'ID';
            }

            Schema.DescribeFieldResult dfr = getDescribeField(currentObjectName,currentObjectField);
            if(dfr.getType() == Schema.DisplayType.REFERENCE){
                Schema.DescribeSObjectResult dsor = getDescribe(dfr.getReferenceTo()[0]);
                return getRelationshipField(dsor.getName(),fieldPath.subStringAfter('.'));
            } else {
                //technically this is an invalid case, but I don't want to return null here
                return dfr;
            }
        }
    }

    public static List<String> getCreatableFields(String objectName){
        List<String> fieldList = new List<String>();
        Schema.SobjectType objectType = getSObjectType(objectName);

        for(Schema.DescribeFieldResult dfr: getDescribeFields(objectType).values()){
            if(dfr.isCreateable()){
                fieldList.add(dfr.getName());
            }
        }

        return fieldList;
    }

    public static List<Schema.DescribeFieldResult> getFieldsByType(String objectName, Schema.DisplayType fieldType) {
        List<Schema.DescribeFieldResult> returnList = new List<Schema.DescribeFieldResult>();

        Schema.SobjectType objectType = getSObjectType(objectName);

        for(Schema.DescribeFieldResult dfr: getDescribeFields(objectType).values()){
            if(dfr.getType() == fieldType){
                returnList.add(dfr);
            }
        }

        return returnList;
    }

    //-------------------------------------------------------------------------
    //  FIELD TYPE METHODS
    //-------------------------------------------------------------------------
    global static Schema.DisplayType getFieldDisplayType(String sobjectName, String fieldName){
        Schema.DisplayType d;
        try {
            Schema.DescribeFieldResult dfr = getDescribeField(sobjectName,fieldName);

            //remove namespace from object
            if(dfr == null){
                sObjectName = removeNamespace(sObjectName);
                dfr = getDescribeField(sobjectName,fieldName);
            }

            if(dfr == null){
                fieldName = removeNamespace(fieldName);
                dfr = getDescribeField(sobjectName,fieldName);
            }

            d = dfr.getType();
        } catch (Exception e){
            throw new Common_Exceptions.SchemaException('SObject field "' + sobjectName + '.' + fieldName + '" does not exist');
        }
        
        return d; 
    }

    global static String getFieldType(String objectName, String fieldName) {
        try{
            return String.valueOf(getFieldDisplayType(objectName, fieldName));
        } catch(Exception e){
            return null;
        }
    }

    global static Map<String,String> getFieldTypes(String objectName, List<String> fieldNames){
        Map<String, Schema.DescribeFieldResult> describeFields = getDescribeFields(objectName);

        Map<String, String> fieldTypeMap = new Map<String, String>();
        for(String fieldName:fieldNames){
            Schema.DescribeFieldResult dfr = describeFields.get(fieldName.trim());
            fieldTypeMap.put(dfr.getName(), String.valueOf(dfr.getType()));
        }

        return fieldTypeMap;
    }
    
    //-------------------------------------------------------------------------
    //  RECORD TYPE METHODS
    //-------------------------------------------------------------------------
    global static Map<String, ID> getRecordTypes(String objectName){
        if(recordTypeMap == null){
            recordTypeMap = new Map<String, Map<String, ID>>();
            for(RecordType rt:[select id,DeveloperName,SObjectType from RecordType]){
                String rtObjectName = removeNamespace(rt.SObjectType);
                if(recordTypeMap.containsKey(rtObjectName)){
                    recordTypeMap.get(rtObjectName).put(rt.DeveloperName, rt.ID);
                } else {
                    recordTypeMap.put(rtObjectName, new Map<String, ID>{rt.DeveloperName=>rt.ID});
                }
            }
        }

        if(recordTypeMap.containsKey(objectName)){
            return recordTypeMap.get(objectName);
        } else if(recordTypeMap.containsKey(removeNamespace(objectName))){
            return recordTypeMap.get(removeNamespace(objectName));
        } else {
            return new Map<String, ID>();
        }
    }

    global static List<Schema.RecordTypeInfo> getAvailableRecordTypes(Schema.SobjectType objType) {
        List<Schema.RecordTypeInfo> infos = getDescribe(objType).getRecordTypeInfos();
        List<Schema.RecordTypeInfo> returnInfos = new List<Schema.RecordTypeInfo>();

        //Filter master if there are multiple record types
        if (infos.size() > 1) {
            for (Schema.RecordTypeInfo i : infos) {
               if (i.isAvailable() && !i.isMaster()){
                    returnInfos.add(i);
               }
            }
        }

        //single master type, or all record types disabled
        if(returnInfos.isEmpty() && !infos.isEmpty()){
            returnInfos.add(infos[0]);
        }
        
        return returnInfos;
    }
}