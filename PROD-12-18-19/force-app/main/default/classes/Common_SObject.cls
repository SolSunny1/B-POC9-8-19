global class Common_SObject {

    /************************** Consider multi-layer cross-object reference ******************/
    public static FieldDetailWrapper getFieldDetails(Object o, String field) {

        if (o == null || field == null || field == '') {
            return null;
        }

        if (!field.contains('.')) {
            if (o instanceOf sObject) {
                return new FieldDetailWrapper((sObject)o, field);
            }
            else if (o instanceOf String) {
                return new FieldDetailWrapper((String)o, field);
            }
        }
        else {
            if (o instanceOf sObject) {
                sObject sObjCopy = (sObject)o;
                return getFieldDetails( sObjCopy.getSObject(field.substringBefore('.')), field.substringAfter('.') );
            }
            else if (o instanceOf String) {
                return getFieldDetails( getReferenceObjectName((String) o, field.substringBefore('.')), field.substringAfter('.') );
            }
        }
        
        return null;
    }

    global static Object getSObjectFieldValue(sObject o, String field){
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

    public static String getSobjectNameValue(sObject o){
        String objectNameField = Common_Schema.getNameField(o.getSObjectType());
        return (String) o.get(objectNameField);
    }

    // Worth noting: if the object/field combination in question has multiple lookup types, we're gonna run into problems
    public static String getReferenceObjectName(String parentObjectName, String field) {

        Map<String, DescribeFieldResult> parentObjectFields = Common_Schema.getDescribeFields(Common_Schema.getDescribeObject(parentObjectName));

        if (parentObjectFields.containsKey(field.replace('__r','__c'))) {
            return parentObjectFields.get(field.replace('__r','__c')).getReferenceTo()[0].getDescribe().getName();
        }
        else if (parentObjectFields.containsKey(field.substringBefore('__r'))) {
            return parentObjectFields.get(field.substringBefore('__r')).getReferenceTo()[0].getDescribe().getName();
        }
        else if (parentObjectFields.containsKey(field + 'Id')) {
            return parentObjectFields.get(field + 'Id').getReferenceTo()[0].getDescribe().getName();
        }
        else {
            throw new Common_Exceptions.FatalApplicationException('Common_SObject', 'getReferenceObjectName', 'sObject ' + parentObjectName + ' does not have field ' + field);
        }
    }

    public class FieldDetailWrapper {

        public sObject parentObject;
        public String fieldName;
        public String parentObjectName;
        public Map<String, DescribeFieldResult> parentObjectFields;

        public FieldDetailWrapper(sObject o, String field) {

            parentObject = o;
            fieldName = field;
            parentObjectName = o.getSObjectType().getDescribe().getName();
            parentObjectFields = Common_Schema.getDescribeFields(Common_Schema.getDescribeObject(parentObjectName));

            if (!parentObjectFields.containsKey(field)) {
                throw new Common_Exceptions.FatalApplicationException('Common_SObject', 'FieldDetailWrapper', 'sObject ' + parentObjectName + ' does not have field ' + field);
            }

        }

        public FieldDetailWrapper(String parentObjectName, String field) {

            this.parentObjectName = parentObjectName;
            fieldName = field;
            parentObjectFields = Common_Schema.getDescribeFields(Common_Schema.getDescribeObject(parentObjectName));

            if (!parentObjectFields.containsKey(field)) {
                throw new Common_Exceptions.FatalApplicationException('sObject ' + parentObjectName + ' does not have field ' + field, 'Common_SObject', 'FieldDetailWrapper');
            }

        }

        public Object getValue() {
            if (parentObject == null) {
                return null;
            }
            else {
                return parentObject.get(fieldName);
            }
        }

        public DescribeFieldResult getDescribeFieldResult() {
            return parentObjectFields.get(fieldName);
        }

        public Schema.DisplayType getDisplayType() {
            return Common_Schema.getFieldDisplayType(parentObjectName, fieldName);
        }
    }


    public class DupeChecker{
        public List<String> keyFields;
        public String objectKeyField;
        public String objectName;
        public DupeChecker(String objectName, List<String> keyFields, String objectKeyField){
            this.objectName = objectName;
            this.keyFields = keyFields;
            this.objectKeyField = objectKeyField;
        }

        public List<SObject> removeDupesFromList(List<SObject> recordsToCheck){
            Map<String, sObject> keyMap = new Map<String, sObject>();
            for(Sobject record:recordsToCheck){
                List<String> keyValues = new List<String>();
                for(String keyField:keyFields){
                    if(record.get(keyField) != null){
                        keyValues.add(String.valueOf(record.get(keyField)));
                    } else {
                        keyValues.add('');
                    }
                }

                keyMap.put(String.join(keyValues,'|'),record);
            }

            system.debug(keyMap.keyset());

            Common_QueryBuilder queryBuilder = new Common_QueryBuilder(objectName);
            queryBuilder.addQueryFields(keyFields);
            queryBuilder.addQueryField(objectKeyField);
            queryBuilder.addWhereFilter(objectKeyField, new List<String>(keyMap.keyset()));

            for(sObject record:Database.query(queryBuilder.toString())){
                system.debug(record);
                if(record.get(objectKeyField) != null){
                    String recordKeyValue = String.valueOf(record.get(objectKeyField));
                    system.debug(recordKeyValue);
                    if(keyMap.containsKey(recordKeyValue)){
                        keyMap.remove(recordKeyValue);
                    }
                }
            }

            return keyMap.values();
        }
    }

    private static Map<String, sObject> currencyConversionRates;
    private static String orgDefaultCurrency;


    global static Decimal convertCurrency(Decimal value, String ISOCode){
        if(value == null){
            return null;
        }

        if(!UserInfo.isMultiCurrencyOrganization() || value == 0){
            return value;
        }

        loadCurrencyConversionRates();

        if(ISOCode != orgDefaultCurrency) {
            sObject ct = currencyConversionRates.get(ISOCode);
            Decimal convertedValue = value * (Decimal) ct.get('ConversionRate');
            convertedValue = convertedValue.divide(1, Integer.valueOf(ct.get('DecimalPlaces')), System.RoundingMode.FLOOR);
            return convertedValue;
        } else {
            return value;
        }
    }

    /*
        Everything here is intentionally soft coded, we don't want a hard dependency on multi-currency
     */
    private static void loadCurrencyConversionRates() {
        if (currencyConversionRates == null) {
            currencyConversionRates = new Map<String, sObject>();

            String currencyTypeQuery = 'select ISOCode, ConversionRate, IsCorporate, DecimalPlaces from CurrencyType where IsActive=true';
            for (sObject ct : Database.query(currencyTypeQuery)) {
                currencyConversionRates.put((String) ct.get('ISOCode'), ct);
                if (Boolean.valueOf(ct.get('IsCorporate'))) {
                    orgDefaultCurrency = (String) ct.get('ISOCode');
                }
            }
        }
    }
}