global with sharing class Common_Query {
    public static final String className = 'Common_Users';
    private static Set<Common_Type.PrimitiveType> quoteTypes {
        get{ 
            if(quoteTypes==null){
                quoteTypes = new Set<Common_Type.PrimitiveType>{
                    Common_Type.PrimitiveType.T_ID, Common_Type.PrimitiveType.T_STRING
                };
            }
            return quoteTypes;
        }
        private set;
    }
    
    /*public static List<System_Field__c> ignorableSystemFields {
        get {
            if(ignorableSystemFields==null){
                ignorableSystemFields = new List<System_Field__c>();
                for(System_Field__c f : System_Field__c.getAll().values()){
                    if(f.Ignorable__c){
                        ignorableSystemFields.add(f);
                    }
                }
            }
            return ignorableSystemFields;
        }
        private set;
    }   */ 
    
    /**
     * Ideally, we'd want to add a "GetQueryStringFormat()" method directly to the primitive data type classes
     * but we can't do that, so this will have to do.
     */
    public static String ToString(Object data, Boolean ignoreNulls){
        String retVal = String.valueOf(data);
        
        system.debug('passed in value is ' + retVal);
        
        //If a null value is passed...
        if(data==null) return retVal;
        
        //If this is a list, get the content type (i.e. List<Integer> content type is Integer, or PrimitiveType.T_INTEGER)
        Common_Type.PrimitiveType primitiveDataStructureType = Common_Type.GetPrimitiveDataStructureType(data);
        if(primitiveDataStructureType!=null){
            retVal = ListOrSetToString(data, ignoreNulls, primitiveDataStructureType);
            return retVal;
        }
        
        // If not a list or set...
        Common_Type.PrimitiveType primitiveType = Common_Type.GetPrimitiveType(data);
        
        if(primitiveType==null){
            throw new Common_Exceptions.TypeException('Cannot infer primitive type of passed data: ' + data, 'Common_Users', 'ToString');
        }
        
        if( quoteTypes.contains( primitiveType ) ){
            retVal = '\'' + String.escapeSingleQuotes(String.valueOf(data)) + '\'';
        }
        else if( primitiveType==Common_Type.PrimitiveType.T_DATE ){
            retVal = ToString((Date)data);
        }
        
        system.debug('returning value: ' + retVal);
        
        return retVal;
    }

    public static String ToString(Date d){
        String retVal = null;
        
        if(d==null) return retVal;
        
        String year = String.valueOf( d.year() );
        String month = '';
        if(d.month()<10) month += '0';
        month += String.valueOf( d.month() );
        String day = '';
        if(d.day()<10) day += '0';
        day += String.valueOf( d.day() );
        
        retVal = year + '-' + month + '-' + day;
        return retVal;
    }
    
    public static String ListOrSetToString(Object listOrSet, Boolean ignoreNulls, Common_Type.PrimitiveType primitiveListType){
        String retVal = null;
        
        //If a null value is passed...
        if(listOrSet==null) return null;
        
        //Attempt to convert Object to List<String>
        List<String> objects;
        try{
            objects = (List<String>) JSON.deserialize( JSON.serialize(listOrSet) , List<String>.class);
        }
        catch(System.JSONException je){
            system.debug('this is not a list or set');
            return null;
        }
        
        //If the input list/set was empty...
        if(objects.isEmpty()) return null;
        
        //Only certain types should be enclosed in quotes for a query. For example, ID or String, but not Double or Integer
        Boolean shouldEncloseQuotes = quoteTypes.contains(primitiveListType);
        
        List<String> toJoin = new List<String>();
        String nullValue = 'null';
        for(String s : objects){
            if(!(ignoreNulls && (s==null || s.equalsIgnoreCase(nullValue)))){
                //handle type specific ToString conversions
                String valToAdd = (shouldEncloseQuotes ? '\'' + s + '\'' : s); //just did this inline to avoid extra function call because salesforce logs suck
                if(primitiveListType==Common_Type.PrimitiveType.T_DATE) valToAdd = ToString( Date.valueOf(s) );
                
                toJoin.add(valToAdd);
            }
        }
        
        //If the input list/set contained nothing but null values, and we're choosing to ignore null values...
        if(objects.isEmpty()) return null;
        
        //Phew, we did it!
        retVal = '(' + String.join(toJoin, ',') + ')';
        return retVal;
    }
    
    public static String EncloseQuotes(Object obj){
        return '\''+obj+'\'';
    }
    
    global static String GetAllFields(Schema.SObjectType token){
        return String.join(new List<String>(token.getDescribe().fields.getMap().keySet()), ',');
    }
    
    global static String GetAllFields(Schema.SObjectType token, Boolean includeSystemFields){
        Set<String> fields = token.getDescribe().fields.getMap().keySet();
        
        /*if(includeSystemFields==false){
            for(System_Field__c f : ignorableSystemFields){
                fields.remove( f.Name );
            }   
        }*/
        
        return String.join(new List<String>(fields), ',');
    }
    
    global static String GetAllFields(String objName){
        return getAllFields( Schema.getGlobalDescribe().get( objName.toLowerCase() ));
    }
    
    public static String FieldListToString(List<String> fieldsToQuery){
        List<String> noNulls = new List<String>();
        for(String s : fieldsToQuery){
            if(s!=null && !String.isBlank(s)) noNulls.add(s);
        }
        return String.join(noNulls, ',');
    }

    // Brought in from CT_UI

    public static Boolean containsMergeFields(String query){
        return query.indexOf('{!') != -1;
    }

    public static String getQueryFormattedString(Object filterValue, Boolean escapeSingleQuotes){
        if(filterValue == null){
            return null;
        }

        String fieldType = 'string';
        if(filterValue instanceOf Date){
            fieldType = 'date';
        } else if(filterValue instanceOf DateTime){
            fieldType = 'datetime';
        } else if(filterValue instanceOf Integer){
            fieldType = 'integer';
        } else if(filterValue instanceOf Decimal){
            fieldType = 'decimal';
        } else if(filterValue instanceOf Double){
            fieldType = 'double';
        }

        if(fieldType == 'string' && escapeSingleQuotes){
            return '\''+String.escapeSingleQuotes(String.valueOf(filterValue))+'\'';
        } else if(fieldType == 'date'){
            return String.valueOf(filterValue).substringBefore('T');
        } else { //number values don't need quotes ever,so they're grouped here
            return String.valueOf(filterValue);
        }
    }
    
    //================================================================================================
    // Start synchronous, same-execution-context operations
    public static List<SObject> executeQuery(String query){
        system.debug(query);
        List<SObject> objects = Database.query(query);
        if(objects==null) {
            objects = new List<SObject>();
        }
        return objects;
    }
    
    public static Map<Id, SObject> executeQuery(Schema.SObjectType sobjectType, Set<Id> sobjectIds, Schema.FieldSet fieldSetToQuery){
        Set<String> fieldsToQuery = new Set<String>{'Id'};
        
        for(Schema.FieldSetMember m : fieldSetToQuery.getFields()){
            fieldsToQuery.add(m.getFieldPath());
        }
        
        String query = 
            ' SELECT ' + String.join(new List<String>(fieldsToQuery), ',') +
            ' FROM ' + sobjectType + 
            ' WHERE ID in ' + Common_Query.toString(sobjectIds, true)
            ;
        
        system.debug('EmailTemplate sobject query: ' + query);
        
        return new Map<Id, SObject>(Common_Query.ExecuteQuery(query));
    }
    
    public static SObject executeQuerySingleRecord(String query){
        system.debug('query is: ' + query);
        List<SObject> objects = Common_Query.executeQuery(query);
        if(objects.size()>1) {
            throw new Common_Exceptions.BadDataException('There should only be one record for the associated query: [' + query + '] but there are ' + objects.size());
        } 
        else if(objects.size()==1){
            return objects[0];
        }
        return null;
    }
    
    // End synchronous, same-execution-context operations
    //================================================================================================      
}