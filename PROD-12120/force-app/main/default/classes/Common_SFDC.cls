global with sharing class Common_SFDC {
    global class ApplicationException extends Exception {}
        
    //=================================================================================================================
    // Convenience Methods
    //=================================================================================================================
    global static boolean isCustomField(string fieldName) {
        
        return fieldName.contains('__c');                               
                                    
    }

    global static Boolean isSF1() {
        if(String.isNotBlank(ApexPages.currentPage().getParameters().get('sfdcIFrameHost')) ||
            String.isNotBlank(ApexPages.currentPage().getParameters().get('sfdcIFrameOrigin')) ||
            ApexPages.currentPage().getParameters().get('isdtp') == 'p1' ||
            (ApexPages.currentPage().getParameters().get('retURL') != null && ApexPages.currentPage().getParameters().get('retURL').contains('projectone') )
        ) {
            return true;
        } else {
            return false;
        }
    }

    global static String mergeDataFromSObject(SObject sObj, String sString) {
        String returnString = sString;
            while (returnString.indexOf('{!') != -1) {
                String mergeField = returnString;
                mergeField = mergeField.subString(mergeField.indexOf('{!') + 2);
                mergeField = mergeField.substring(0, mergeField.indexOf('}'));

                returnString = returnString.replace('{!' + mergeField + '}', String.valueOf(sObj.get(mergeField)));
                system.debug('returnString: ' + returnString);
            }

            return returnString;
    }

    //=================================================================================================================
    // Query Builder
    //=================================================================================================================

    // ONLY WORKS FOR ANDS BETWEEN CLAUSE ITEMS.  IF YOU NEED TO USE OR, COMBINE INTO A SINGLE CLAUSE ITEM

    global class QueryBuilder {
        
        global List<String> WhereClauseItems { get; set; }
        
        global QueryBuilder() {
            WhereClauseItems = new List<string>();
            
        }
           
        global string getWhereClause() {
            
            string sClause = '';        
            
            if (WhereClauseItems.size() > 0) {
                sClause = 'WHERE (' + String.join(WhereClauseItems, ' AND ') + ')';
                
            }   
            return sClause;
            
        }
    }

    //=================================================================================================================
    // Merge Field String Builder
    //=================================================================================================================

    global class MergeFieldStringBuilder {
        private String initialString;
        private String mergedString;
        private Boolean hasModifiedMergeValues;
        private Map<String, MergeObject> mergeObjects;
        private Map<String, MergeObject> tokenMap;

        private final String PARSE_EXPRESSION = '(?<=\\{!)(.*)(?=\\})';

        global MergeFieldStringBuilder(String stringToMerge){
            initialString = stringToMerge;
            mergeObjects = new Map<String, MergeObject>();
            hasModifiedMergeValues = true;
        }

        global MergeFieldStringBuilder(){
            mergeObjects = new Map<String, MergeObject>();
            hasModifiedMergeValues = true;
        }

        global String getMergedString(){
            if(mergedString != null && !hasModifiedMergeValues){
                return mergedString;
            }

            if (String.isBlank(initialString) || initialString.indexOf('{!') == -1){
                return initialString;
            }

            getMergeTokens();
            system.debug(tokenMap);
            populateMergeValues();
            mergeFields();

            hasModifiedMergeValues = false;
            return mergedString;
        }

        global void updateMergeString(String updatedMergeTarget){
            initialString = updatedMergeTarget;
            hasModifiedMergeValues = true;
            tokenMap = null;
        }

        public Map<String, MergeObject> getMergeTokens(){
            if(tokenMap == null){
                tokenMap = new Map<String, MergeObject>();
            } else {
                return tokenMap;
            }

            Pattern parsePattren = Pattern.compile(PARSE_EXPRESSION);

            for (String tokenChunk: initialString.split('\\}')){
                if(tokenChunk.indexOf('{!') != -1){
                    Matcher tokenFinder = parsePattren.matcher(tokenChunk+'}');
                    if(tokenFinder.find()){
                        String token = tokenFinder.group(1);
                        Common_Exceptions.assertError(!token.contains('.'), 'Merge field must be in the format: {!Object.Field}');

                        String objectName = token.substringBefore('.');
                        String objectField = token.substringAfter('.');

                        if(tokenMap.containsKey(objectName)){
                            tokenmap.get(objectName).addMergeField(objectField, null);
                        } else {
                            MergeObject tokenObject = new MergeObject(objectName);
                            tokenObject.addMergeField(objectField,null);
                            tokenMap.put(objectName, tokenObject);
                        }
                    }
                }
            }

            return tokenMap;
        }

        public List<MergeField> getMergeFields(){
            List<MergeField> mergeFields = new List<MergeField>();
            for(MergeObject tokenObject:tokenMap.values()){
                mergeFields.addAll(tokenObject.getFields().values());
            }
            return mergeFields;
        }

        private void populateMergeValues(){
            system.debug(mergeObjects);
            for(MergeObject tokenObject:tokenMap.values()){
                system.debug('Moving values for: '+tokenObject.objectName);
                for(MergeField tokenField:tokenObject.getFields().values()){
                    Object fieldValue;
                    Boolean escapeField;
                    try{
                        fieldValue = mergeObjects.get(tokenObject.objectName).getFieldValue(tokenField.fieldName);
                        escapeField = mergeObjects.get(tokenObject.objectName).getFieldEscapeValue(tokenField.fieldName);
                    } catch(Exception e){
                        system.debug(''+e.getMessage()+e.getLineNumber()+e.getStackTraceString());
                    }
                    //Common_Exceptions.assertError(fieldValue == null, 'A value for merge field '+tokenObject.objectName+'.'+tokenField.fieldName+' could not be found.');
                    tokenField.fieldValue = fieldValue;
                    tokenField.escapeSingleQuotes = escapeField;
                }
                system.debug(mergeObjects.get(tokenObject.objectName));
            }
        }

        private void mergeFields(){
            mergedString = initialString;
            for(MergeObject tokenObject:tokenMap.values()){
                for(MergeField tokenField:tokenObject.getFields().values()){
                    String token = '\\{!'+tokenObject.objectName+'.'+tokenField.fieldName+'\\}';
                    system.debug(token);
                    system.debug(mergedString);
                    system.debug(mergedString.contains(token));
                    String replacementValue = Common_Query.getQueryFormattedString(tokenField.fieldValue, tokenField.escapeSingleQuotes);
                    if(String.isBlank(replacementValue)){
                        replacementValue = 'null';
                    }
                    mergedString = mergedString.replaceAll(token, replacementValue);
                    system.debug(mergedString);
                }
            }
        }

        public void addMergeField(String objectName, String fieldName, Object value){
            addMergeField(objectName, fieldName, value, true);
        }

        global void addMergeField(String objectName, String fieldName, Object value, Boolean escapeSingleQuotes){
            hasModifiedMergeValues = true;
            if(mergeObjects.containsKey(objectName)){
                mergeObjects.get(objectName).addMergeField(fieldName, value, escapeSingleQuotes);
            } else {
                MergeObject objectWrapper = new MergeObject(objectName);
                objectWrapper.addMergeField(fieldName, value, escapeSingleQuotes);
                mergeObjects.put(objectName, objectWrapper);
            }
        }

        public void queryForMergeData(String objectName, String filterFieldName, Object filterValue){
            hasModifiedMergeValues = true;
            if(tokenMap == null){
                getMergeTokens();
                system.debug(tokenMap);
            }

            if(tokenMap.containsKey(objectName)){
                String query = 'select '+ String.join(new List<String>(tokenMap.get(objectName).getFields().keySet()),',');
                query += ' from '+objectName+' where '+filterFieldName+'='+Common_Query.getQueryFormattedString(filterValue, true);

                Sobject mergeData = Database.query(query)[0];
                MergeObject objectWrapper = new MergeObject(objectName);
                objectWrapper.setObjectRecord(mergeData);
                mergeObjects.put(objectName, objectWrapper);
            }
        }

        //For backward compatability with v1
        public void setMergeDataFromQuery(String objectName, String filterFieldName, Object filterValue){
            queryForMergeData(objectName,filterFieldName,filterValue);
        }

        public void queryForUnescapedMergeData(String objectName, String filterFieldName, Object filterValue){
            hasModifiedMergeValues = true;
            if(tokenMap == null){
                getMergeTokens();
                system.debug(tokenMap);
            }
            String fieldSet;
            if(tokenMap.containsKey(objectName)){
                fieldSet = String.join(new List<String>(tokenMap.get(objectName).getFields().keySet()),',');
            } else {
                fieldSet = 'ID';
            }

            String query = 'select '+fieldSet;
            query += ' from '+objectName+' where '+filterFieldName+'='+Common_Query.getQueryFormattedString(filterValue, true);

            List<Sobject> dataList = Database.query(query);
            Sobject mergeData;
            if(dataList.size()>0){
                mergeData = dataList[0];
            }
            MergeObject objectWrapper = new MergeObject(objectName);
            objectWrapper.setObjectRecord(mergeData, false);
            mergeObjects.put(objectName, objectWrapper);
        }
    }

    public class MergeObject{
        public String objectName;
        private Sobject objectValue;
        private Boolean escapeSingleQuotes;
        private Map<String, MergeField> fields;

        public MergeObject(String objectName){
            this.objectName = objectName;
            fields = new Map<String, MergeField>();
        }

        public void setObjectRecord(SObject record){
            setObjectRecord(record, true);
        }

        public void setObjectRecord(SObject record, Boolean escapeSingleQuotes){
            objectValue = record;
            this.escapeSingleQuotes = escapeSingleQuotes;
        }

        public void addMergeField(String fieldName, Object fieldValue){
            this.fields.put(fieldName, new MergeField(fieldName,fieldValue));
        }

        public void addMergeField(String fieldName, Object fieldValue, Boolean escapeSingleQuotes){
            this.fields.put(fieldName, new MergeField(fieldName, fieldValue, escapeSingleQuotes));
        }

        public Map<String, MergeField> getFields(){
            return fields;
        }

        public Object getFieldValue(String fieldName){
            if(objectValue != null){
                return objectValue.get(fieldName);
            } else if(fields.containsKey(fieldName)){
                return fields.get(fieldName).fieldValue;
            } else {
                return null;
            }
        }

        public Boolean getFieldEscapeValue(String fieldName){
            if(objectValue != null){
                return escapeSingleQuotes;
            } else {
                return fields.get(fieldName).escapeSingleQuotes;
            }
        }
    }

    public class MergeField{
        public String fieldName;
        public Object fieldValue;
        public Boolean escapeSingleQuotes;

        public MergeField(String fieldName){
            this(fieldName, null, true);
        }

        public MergeField(String fieldName, Object fieldValue){
            this(fieldName, fieldValue, true);
        }

        public MergeField(String fieldName, Object fieldValue, Boolean escapeSingleQuotes){
            this.fieldName = fieldName;
            this.fieldValue = fieldValue;
            this.escapeSingleQuotes = escapeSingleQuotes;
        }
    }

}