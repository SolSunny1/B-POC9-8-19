global with sharing class Common_Database {
    
    global enum Operation {DO_INSERT, DO_UPSERT, DO_UPDATE, DO_DELETE}
    private static final string FEATURE_NULLIFY_STATE_COUNTRY = 'Common.Database.NullifyStateCountry';
    private static final string FEATURE_CHECK_CRUD = 'Common.Database.CheckCRUD';
    
    private static Set<String> systemFields = new Set<String> { 'attributes', 'Id','IsDeleted','CreatedDate','SystemModStamp','LastModifiedById','CreatedById','LastModifiedDate'};
    
    private static List<String> accountCountryFieldList = new List<String>{'BillingCountry','ShippingCountry'};
    private static List<String> accountStateFieldList = new List<String>{'BillingState','ShippingState'};
    private static List<String> contactCountryFieldList = new List<String>{'MailingCountry','OtherCountry'};
    private static List<String> contactStateFieldList = new List<String>{'MailingState','OtherState'};

    private static Set<String> countryCodeValues;
    private static Set<String> stateCodeValues;

    private static String objectName;
    public static integer  MAX_SOBJECT_CHUNK_SIZE          = 8;
    public static integer  MAX_SOBJECT_CHUNKED_LIST_SIZE   = 800;

    
    //=================================================================================================================
    // EXCEPTIONS
    //=================================================================================================================

    global virtual class SecureDMLException extends Exception {
        public sObjectType objType { get; private set; }
        public Operation op { get; private set; }
    }
    global class CRUDException extends SecureDMLException {
        public CRUDException(sObjectType objType, Operation op ) {
            this('Insufficient permissions to perform ' + getOperationName(op).toLowercase() + ' on ' + objType.getDescribe().getLabel() );

            this.op = op;
            this.objType = objType;
        }
    }
    global class FLSException extends SecureDMLException {
        //public sObjectField field {get; private set;}
        public string FieldName {get; private set;}     
        public FLSEXception(SObjectType objType, string sFieldName, Operation op) {
            this('Insufficient permissions to perform ' + getOperationName(op).toLowercase() + ' on ' + objType.getDescribe().getLabel() + ' for field ' + sFieldName);
            this.objType = objType;
            this.op = op;
            this.FieldName = sFieldName;
        }
    }
    
    //=================================================================================================================
    // SECURE DML 2 - LIST
    //=================================================================================================================

    //===== INSERT =====
    global static Database.SaveResult[] secureInsert2(sObject[] recordsToInsert, Boolean opt_allOrNone){
        if(recordsToInsert.size() == 0){
            return new List<Database.SaveResult>();
        }
        
        checkCRUDAndFLS(recordsToInsert, Operation.DO_INSERT);

        if (Common_Feature.isEnabled(FEATURE_NULLIFY_STATE_COUNTRY, false)) {
            return Database.insert(nullifyBadStateCountry(recordsToInsert), opt_allOrNone);
        } else {
            return Database.insert(recordsToInsert, opt_allOrNone);
        }
    }   

    //===== UPDATE =====
    global static Database.SaveResult[] secureUpdate2(sObject[] recordsToUpdate, Boolean opt_allOrNone){
        if (recordsToUpdate.size() == 0)
            return new List<Database.SaveResult>();
        
        checkCRUDAndFLS(recordsToUpdate, Operation.DO_UPDATE);

        if (Common_Feature.isEnabled(FEATURE_NULLIFY_STATE_COUNTRY, false)) {
            return Database.update(nullifyBadStateCountry(recordsToUpdate), opt_allOrNone);
        } else {
            return Database.update(recordsToUpdate, opt_allOrNone);
        }
    }   
    
    //===== UPSERT =====
    // Can't support this: https://success.salesforce.com/ideaView?id=08730000000aNhVAAU
    /* global static Database.UpsertResult[] secureUpsert2(sObject[] recordsToUpsert, Boolean opt_allOrNone){} */ 

    //===== DELETE =====
    global static Database.DeleteResult[] secureDelete2(sObject[] recordsToDelete, Boolean opt_allOrNone){
        if (recordsToDelete.size() == 0)
            return new List<Database.DeleteResult>();

        checkCRUD(recordsToDelete.get(0), Operation.DO_DELETE);
        return Database.delete(recordsToDelete, opt_allOrNone);
    }    
    
    global static Database.DeleteResult[] secureDelete2(List<sObject[]> recordsToDelete, Boolean opt_allOrNone) {
        List<Database.DeleteResult> deleteResult = new List<Database.DeleteResult>();
        if (recordsToDelete.isEmpty() || recordsToDelete.size() == 0)
            return deleteResult;        
        
        for(sObject[] currentList: recordsToDelete){
            deleteResult.addAll(secureDelete2(currentList, opt_allOrNone));
        }
        return deleteResult;
    }  

    //===== OVERRIDES FOR OPTIONAL ALL OR NOTHING =====

    global static Database.SaveResult[] secureInsert2(sObject[] recordsToInsert) {
        return secureInsert2(recordsToInsert, true);
    }

    global static Database.SaveResult[] secureUpdate2(sObject[] recordsToUpdate) {
        return secureUpdate2(recordsToUpdate, true);
    }

    // Can't support this: https://success.salesforce.com/ideaView?id=08730000000aNhVAAU
    /* global static Database.UpsertResult[] secureUpsert2(sObject[] recordsToUpsert){} */
    
    global static Database.DeleteResult[] secureDelete2(sObject[] recordsToDelete) {
        return secureDelete2(recordsToDelete, true);
    }
    
    global static Database.DeleteResult[] secureDelete2(List<sObject[]> recordsToDelete) {
        return secureDelete2(recordsToDelete, true);
    }

    //=================================================================================================================
    // SECURE DML 2 - SINGLE OBJECT
    //=================================================================================================================

    global static Database.SaveResult secureInsert2(sObject recordToInsert) {
        checkCRUDAndFLS(recordToInsert, Operation.DO_INSERT);

        if (Common_Feature.isEnabled(FEATURE_NULLIFY_STATE_COUNTRY, false)) {
            return Database.insert(nullifyBadStateCountry(recordToInsert));
        } else {
            return Database.insert(recordToInsert);    
        }
    }

    global static Database.SaveResult secureUpdate2(sObject recordToUpdate) {
        checkCRUDAndFLS(recordToUpdate, Operation.DO_UPDATE);

        if (Common_Feature.isEnabled(FEATURE_NULLIFY_STATE_COUNTRY, false)) {
            return Database.update(nullifyBadStateCountry(recordToUpdate));
        } else {
            return Database.update(recordToUpdate);    
        }
    }

    global static Database.UpsertResult secureUpsert2(sObject recordToUpsert) {
        checkCRUDAndFLS(recordToUpsert, Operation.DO_UPSERT);

        if (Common_Feature.isEnabled(FEATURE_NULLIFY_STATE_COUNTRY, false)) {
            return Database.upsert(nullifyBadStateCountry(recordToUpsert));
        } else {
            return Database.upsert(recordToUpsert);  
        }
    }
    
    global static Database.DeleteResult secureDelete2(sObject recordToDelete) {
        checkCRUDAndFLS(recordToDelete, Operation.DO_DELETE);
        return Database.delete(recordToDelete);
    }

    //=================================================================================================================
    // CRUD
    //=================================================================================================================
    global static void checkCRUD(sObject sObj, Operation op) {
        if (Common_Feature.isEnabled(FEATURE_CHECK_CRUD)) {
            try {
                sObjectType objType = sObj.getSObjectType();
                DescribeSObjectResult describeObj = objType.getDescribe();
        
                if ( op == Operation.DO_INSERT && !describeObj.isCreateable() ) {
                    throw new CRUDException(objType, op);
                }
                if ( op == Operation.DO_UPSERT && ( !describeObj.isCreateable() || !describeObj.isUpdateable() ) ) {
                    throw new CRUDException(objType, op);
                }
                if ( op == Operation.DO_UPDATE && !describeObj.isUpdateable() ) {
                    throw new CRUDException(objType, op);
                }
                if ( op == Operation.DO_DELETE && !describeObj.isDeletable() ) {
                    throw new CRUDException(objType, op);
                }
            } catch (Exception ex) {          
                ex.setMessage(ex.getMessage());
                throw ex;
            }       
        }
    }
    
    //=================================================================================================================
    // FLS
    //=================================================================================================================
    global static void checkFLS(sObject sObj, Operation op, Map<String, DescribeFieldResult> mapDescribeFields) {
        if (sObj == null){
            throw new Common_Exceptions.ApplicationException('Object cannot be null');
        }

        try {
            if(op==Operation.DO_DELETE){
                return;
            }

            //===== serialize =====
            system.debug('***** serialize *****');
            
            String serialized = JSON.serialize(sObj);
            system.debug('serialized ' + serialized);
            
            Map<String, Object> objectFieldMap = (Map<String, Object>) JSON.deserializeUntyped(serialized);
            if (objectFieldMap == null)
                throw new Common_Exceptions.ApplicationException('objectFieldMap cannot be null');
                            
            system.debug('objectFieldMap: ' + objectFieldMap);

            //===== check each field =====
            system.debug('***** check each field *****');

            for (String sFieldName : objectFieldMap.keyset()) {
                // ignore system fields
                if (systemFields.contains(sFieldName) == true) {
                    system.debug('system field: ' + sFieldName);
                } else {
                    DescribeFieldResult describeField = mapDescribeFields.get(sFieldName);
                    if (describeField == null) {
                        system.debug('describeField is null [' + sFieldName + ']');
                    }
                    else {
                
                        if (describeField.isCalculated() == true) {
                            system.debug('formula: ' + sFieldName);
                        }
                        else if (describeField.isPermissionable() == false) {
                            system.debug('non-permissionable: ' + sFieldName);
                        }
                        else {
                            system.debug('matched: ' + sFieldName);
                        
                            // check fls
                            if ( op == Operation.DO_INSERT && !describeField.isCreateable() ) {
                                throw new FLSException(sObj.getsObjectType(), describeField.getLabel(), op);
                            }
                            if ( op == Operation.DO_UPSERT && ( !describeField.isCreateable() || !describeField.isUpdateable() ) ) {
                                throw new FLSException(sObj.getsObjectType(), describeField.getLabel(), op);
                            }
                            if ( op == Operation.DO_UPDATE && !describeField.isUpdateable() ) {
                                throw new FLSException(sObj.getsObjectType(), describeField.getLabel(), op);
                            }
                        }
                    }
                }
            }
    
    
            //===== finish and log =====
            system.debug('***** finish and log *****');
        } catch (Exception ex) {          
            ex.setMessage(ex.getMessage());
            throw ex;
        }
    }

    //===== overrides ======
    global static void checkFLS(sObject sObj, Operation op) {
        Map<String, DescribeFieldResult> mapDescribeFields = Common_Schema.getDescribeFields(sObj.getsObjectType());  
        checkFLS(sObj, op, mapDescribeFields);
    }

    //=================================================================================================================
    // CRUD + FLS
    //=================================================================================================================
    global static void checkCRUDAndFLS(sObject[] records, Operation operation) {
        if (Common_Feature.isEnabled(FEATURE_CHECK_CRUD)) {
            if (records.size() == 0 ) return;
            
            checkCRUD(records.get(0), operation);

            if (records.get(0).getsObjectType().getDescribe().isCustomSetting() == true) {
                System.debug('Skip custom settings for fls');
            }
            else {
                Map<String, DescribeFieldResult> mapDescribeFields = Common_Schema.getDescribeFields(records.get(0).getsObjectType());    
                for (sObject obj : records) {
                    checkFLS(obj, operation, mapDescribeFields);
                }           
            }
        }
    }

    //===== OVERRIDES =====
    global static void checkCRUDAndFLS(sObject sObj, Operation op) {
        if (Common_Feature.isEnabled(FEATURE_CHECK_CRUD)) {
            checkCRUDAndFLS(new List<sObject>{sObj}, op);
        }
    }

    //=================================================================================================================
    // HELPER
    //=================================================================================================================
    public static String getOperationName(Operation op) {
        if (op == Operation.DO_INSERT)
            return 'Insert';
        else if (op == Operation.DO_UPSERT)
            return 'Upsert';
        else if (op == Operation.DO_UPDATE)
            return 'Update';
        else if (op == Operation.DO_DELETE)
            return 'Delete';
        else
            return 'Undefined Operation';
    }

    private static SObject nullifyBadStateCountry(SObject sObj){
        objectName = sObj.getSObjectType().getDescribe().getName();
        if (objectName == 'Account' || objectName == 'Contact') {
            // Check if CountryState Picklists are enabled
            if (Account.getSobjectType().getDescribe().fields.getMap().get('BillingCountryCode') != null) {
                SObject tempSObj;
                if (sObj.Id != null) {
                    List<SObject> tempList = new List<SObject>();
                    tempList.add(sObj);
                    tempSObj = returnAllFields(tempList).get(0);
                } else {
                    tempSObj = sObj;
                }

                if (objectName == 'Account') {
                    compareAddressFields(tempSObj, accountCountryFieldList, accountStateFieldList);
                } else if (objectName == 'Contact') {
                    compareAddressFields(tempSObj, contactCountryFieldList, contactStateFieldList);
                }
                return tempSObj;
            }
        }
        return sObj;
    }

    private static List<SObject> nullifyBadStateCountry(List<SObject> lstSObject) {
        objectName = lstSObject.get(0).getSObjectType().getDescribe().getName();
        if (objectName == 'Account' || objectName == 'Contact') {
            // Check if CountryState Picklists are enabled
            if (Account.getSobjectType().getDescribe().fields.getMap().get('BillingCountryCode') != null) {
                List<SObject> tempListSObject;
                if (lstSObject.get(0).Id != null) {
                    tempListSObject = returnAllFields(lstSObject);
                } else {
                    tempListSObject = lstSObject;
                }

                for(SObject obj : tempListSObject) {
                    if (objectName == 'Account') {
                        compareAddressFields(obj, accountCountryFieldList, accountStateFieldList);
                    } else if (objectName == 'Contact') {
                        compareAddressFields(obj, contactCountryFieldList, contactStateFieldList);
                    }
                }
                return tempListSObject;
            }
        }
        return lstSObject;
    }

    public static List<SObject> returnAllFields(List<SObject> sObj) {
        objectName = sObj.get(0).getSObjectType().getDescribe().getName();
        List<Id> sObjIds = new List<Id>();
        for (SObject sO : sObj) {
            sObjIds.add(sO.Id);
        }
        Map<String, Object> queriedFieldValues = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sObj.get(0)));
        String sQuery = 'SELECT ';
        List<String> queryFields = new List<String>();
        Set<String> duplicateSet = new Set<String>();
        if (objectName == 'Account') {
            queryFields.addAll(accountCountryFieldList);
            queryFields.addAll(accountStateFieldList);
            duplicateSet.addAll(accountCountryFieldList);
            duplicateSet.addAll(accountStateFieldList);
        } else if (objectName == 'Contact') {
            queryFields.addAll(contactCountryFieldList);
            queryFields.addAll(contactStateFieldList);
            duplicateSet.addAll(contactCountryFieldList);
            duplicateSet.addAll(contactStateFieldList);
        }
        for (String s : queriedFieldValues.keySet()) {
            if (s != 'attributes') {
                if (!duplicateSet.contains(s)) {
                    queryFields.add(s);
                    duplicateSet.add(s);
                }
            }
        }
        sQuery += String.join(queryFields, ',') + ' FROM ' + objectName + ' WHERE Id IN :sObjIds';

        Map<Id, SObject> oldSObjects = new Map<Id, SObject>(Database.query(sQuery));
        List<SObject> newSObjects = new List<SObject>();
        for (SObject s : sObj) {
            SObject newS = oldSObjects.get(s.Id);
            for (String fieldKey : queriedFieldValues.keySet()) {
                if (fieldKey != 'attributes') {
                    newS.put(fieldKey, s.get(fieldKey));
                }
            }
            newSObjects.add(newS);
        }

        return newSObjects;
    }

    private static void compareAddressFields(SOBject sObj, List<String> countryList, List<String> stateList) {
        for (String countryField : countryList) {
            system.debug('sObj.get(' + countryField + ') = ' + sObj.get(countryField));
            if (sObj.get(countryField) != null) {
                if (countryCodeValues == null)
                    loadCodeValues();
                if (!countryCodeValues.contains((String)sObj.get(countryField))) { //if not in picklist
                    sObj.put(countryField, null);
                }
            }
        }
        for (String stateField : stateList) {
            if (sObj.get(stateField) != null) {
                if (stateCodeValues == null)
                    loadCodeValues();
                if (!stateCodeValues.contains((String)sObj.get(stateField))) { //if not in picklist
                    sObj.put(stateField, null);
                }
            }
        }
    }

    private static void loadCodeValues() {
        // Creates a Map of Fields to Fields Picklist Values
        countryCodeValues = new Set<String>();
        stateCodeValues = new Set<String>();
        Map<String, Schema.SObjectField> accountMap = Account.getSobjectType().getDescribe().fields.getMap();
        for (PicklistEntry ple : accountMap.get(accountCountryFieldList.get(0)).getDescribe().getPicklistValues()) {
            countryCodeValues.add(ple.getLabel());
        }
        for (PicklistEntry ple : accountMap.get(accountStateFieldList.get(0)).getDescribe().getPicklistValues()) {
            stateCodeValues.add(ple.getLabel());
        }
    }

    //=================================================================================================================
    // DEPRECATED - HELPER
    //=================================================================================================================

    // @deprecated
    global static string removeNamespace(string sFieldName) {return null;}
    
    //=================================================================================================================
    // DEPRECATED - SECURE DML
    //=================================================================================================================

    // @deprecated
    global static void secureInsert(sObject sObj, boolean ignoreFLS){}

    // @deprecated
    global static void secureInsert(List<SObject> sObjs, boolean ignoreFLS){}

    // @deprecated
    global static void secureInsert(sObject sObj){}

    // @deprecated
    global static void secureInsert(List<SObject> sObjs){}

    // @deprecated
    global static void secureUpdate(sObject sObj, boolean ignoreFLS){}

    // @deprecated
    global static void secureUpdate(List<SObject> sObjs, boolean ignoreFLS){}

    // @deprecated
    global static void secureUpdate(sObject sObj){}

    // @deprecated
    global static void secureUpdate(List<SObject> sObjs){}

    // @deprecated
    global static void secureUpsert(sObject sObj, boolean ignoreFLS){}

    // @deprecated
    global static void secureUpsert(List<SObject> sObjs, boolean ignoreFLS){}

    // overrides
    // @deprecated
    global static void secureUpsert(sObject sObj){}
    // @deprecated
    global static void secureUpsert(List<SObject> sObjs){}

    // @deprecated
    global static void secureDelete(sObject sObj){}
    // @deprecated
    global static void secureDelete(List<SObject> sObjs){}
    
     /***************************************************************************************
     * Divide Data being updated into chunks :: Starts
     * As We Cannot have more than 10 chunks in a single operation. System.TypeException
     * The method accepts SObject[] having all data with different SObject Types, The method would 
     * break the data and sobjects to chunks if the limit is exceeded. The method return a List of 
     * SObject[]
     * ************************************************************************************/
    
    public static List<SObject[]> chunkBySObjectType(SObject [] sObjs){
        SObjectType objectType;
        List<SObject[]> sObjectChunks = new List<SObject[]>();
        SObject [] thisChunk = new SObject[]{};
        integer distinctTypes = 0;
        
        // Sorting The SObjects. This Would Also Group The Same Object Types
        sObjs.sort();
        
        // The loop below break down SObject[] into chunks if specified limit is exceeded.
        for(SObject sObjectChunk : sObjs){
       
            // Check To Validate Object Switching
            if(objectType != sObjectChunk.getSObjectType()){
                distinctTypes++; 
            }
           
            thisChunk.add(sObjectChunk);
            
            if(thisChunk.size() > MAX_SOBJECT_CHUNKED_LIST_SIZE){
                sObjectChunks.add(thisChunk);
                thisChunk = new sObject[]{};
                    distinctTypes = 0;
            }

            if(distinctTypes > MAX_SOBJECT_CHUNK_SIZE){
                sObjectChunks.add(thisChunk);
                thisChunk = new sObject[]{};
                    distinctTypes = 0; 
            } 

            // Assigning The Object Type 
            objectType = sObjectChunk.getSObjectType();
        }
        
        if(!thisChunk.isEmpty())
           sObjectChunks.add(thisChunk);
         
        System.debug('sObjectChunks Looks Like : ' + sObjectChunks);
        return sObjectChunks;
    }
   
    /***************************************************************************************
     * Divide Data being updated into chunks :: Ends
     * ************************************************************************************/

    public static void UntypedUpsert(SObject o, Schema.SObjectField externalIdField){
        Id conflictingId;
        Boolean shouldExtractIdFromMsg = Common_Feature.isEnabled('ExtractConflictingUpsertIdFromErrorMsg');
        
        if( !externalIdField.getDescribe().isUnique() ){
            throw new Common_Exceptions.SchemaException('The field "' +o.getSObjectType().getDescribe().getName() + '.' + externalIdField + '" must be marked as unique - it is currently not. Cannot upsert against a non-unique external identifier field.', 'DB', 'UntypedUpsert');
        }
        
        try{
            if(o.get('Id')!=null){
                System.debug('o before Looks Like : ' + o);
                update o;
                System.debug('o after Looks Like : ' + o);
            } else {
                insert o;
            }
        } catch(System.DmlException e){
            if(e.getDmlType(0)==System.StatusCode.DUPLICATE_VALUE){
                // if DUPLICATE_VALUE exception, extract ID from error message
                if(shouldExtractIdFromMsg){
                    String errorStr = e.getDmlMessage(0);
                    system.debug(errorStr);
                    List<String> errorMsgParts = errorStr.split(' ');
                    
                    try{
                        conflictingId = Id.valueOf( errorMsgParts.get( errorMsgParts.size()-1 ) );
                    } catch(System.Exception ide){

                    }
                } 
                
                // if we failed to extract ID from the error message, then we have to use a soql query to get it :(
                if(conflictingId==null) {
                    Schema.SObjectType typeToQuery = o.getSObjectType();
                    conflictingId = (Id) Common_Query.ExecuteQuerySingleRecord('select id from ' + typeToQuery + ' where ' + externalIdField + '=' + Common_Query.ToString(o.get(externalIdField), true)).get('Id');
                }
                
                o.put('Id', conflictingId);
                update o;
            } 
            // If the error isn't related to DUPLICATE_VALUE, then just re-throw
            else {
                throw e;
            }
        }
    }
}