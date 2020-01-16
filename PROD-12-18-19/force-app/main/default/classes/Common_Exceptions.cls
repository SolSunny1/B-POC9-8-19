global with sharing class Common_Exceptions {
    // THIS IS CALLED Common_Exceptions because classes that do not extend cannot end with 'Exception'   

    global static void assertError(boolean condition, string message) {
        if (condition){
            system.debug(message);
            throw new ApplicationException(message);
        }
    }

    global static void addErrorMessage(String message){
        system.debug(message);
    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,message));
    }

    global static void addWarningMessage(String message){
        system.debug(message);
    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,message));
    }
    
   //public static String ToHtmlString(Exception e){
   //     String retVal;

   //     //build table headers
   //     List<String> tableHeaders = new List<String>{
   //         'Cause', 
   //         'Class Name', 
   //         'Method Name', 
   //         'Line Number', 
   //         'Message', 
   //         'Stack Trace (columns removed)', 
   //         'Type Name'
   //     };

   //     //attempt to extract className and methodName fields, if this is a custom exception
   //     Map<String, Object> m; 
   //     try {
   //         m = (Map<String, Object>) JSON.deserializeUntyped( JSON.serialize(e) );
   //     } 
   //     catch(Exception ignoreException){
   //         //ignore. this was a standard exception, not custom, so can't be serialized    
   //     }
        
   //     String exceptionClass = 'null (standard exception type)';
   //     String exceptionMethod = 'null (standard exception type)';
   //     if(m!=null){
   //         exceptionClass = String.valueOf(m.get('className'));
   //         exceptionMethod = String.valueOf(m.get('methodName'));
   //     }
        
   //     //built html table
   //     List<String> tableData = new List<String>{
   //         (e.getCause()!=null ? e.getCause().getMessage() : 'null'), 
   //         exceptionClass,
   //         exceptionMethod, 
   //         String.valueOf( e.getLineNumber() ), 
   //         e.getMessage(), 
   //         e.getStackTraceString().replaceAll('column [0-9]','<br>'), 
   //         e.getTypeName()
   //     };
   //     List<List<String>> dataSegments = new List<List<String>>{ tableHeaders, tableData };
            
   //     retVal = Common_HtmlBuilder.BuildTable(dataSegments, false);
        
   //     return retVal;
   // }
    
    public static void throwBadDataExceptionOnBadLocalFieldValue(SObject o, String localFieldName, Object badDataValue){        
        if(o.get(localFieldName)==badDataValue){
            Schema.DescribeSObjectResult sobjectDescribe = o.getSObjectType().getDescribe();
            Schema.DescribeFieldResult fieldDescribe = sobjectDescribe.fields.getMap().get(localFieldName).getDescribe();
            
            throw new BadDataException(
                'Field ' + fieldDescribe.getLabel() + ' on ' + sobjectDescribe.getLabel() + 
                (o.get('ID')==null ? '' : ' (' + o.get('ID') + ')') + 
                ' cannot be ' +
                (badDataValue==null ? 'blank' : String.valueOf(badDataValue))
            );
        }
    }
    
    /**
     * Base exception
     */ 
    global abstract class CustomException extends System.Exception {
        public string className, methodName, customMessage;
        
        global CustomException(System.exception baseException, string message, string className, string methodName){
            initCause(baseException);
            setMessage(message);
            
            this.customMessage = message;
            this.className  = className;
            this.methodName = methodName;
        }
        
        global CustomException(string message, string className, string methodName){
            this(null, message, className, methodName);
        }
        
        global String getCustomMessage(){
            return customMessage;
        }
    }

    /**
     * ApplicationException: Used basically as the default error type
     */
     /* 
    public class ApplicationException extends CustomException {        
        public ApplicationException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public ApplicationException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }*/
    global class ApplicationException extends Exception {}

    /**
     * ApplicationException: used for fatal exceptions
     */ 
    global class FatalApplicationException extends CustomException 
    {
        global FatalApplicationException(System.exception baseException, string message, string className, string methodName)
        {
            super(baseException, message, className, methodName);
        }//end constructor
        
        global FatalApplicationException(string message, string className, string methodName)
        {
            super(message, className, methodName);
        }//end constructor
    }
    
    /**
     * AlreadyInitializedException: used if a dynamic object (see DynamicObject abstract class, or iDynamicObject interface) is attempted to be initialized multiple times
     */ 
    public class AlreadyInitializedException extends CustomException {
        public AlreadyInitializedException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public AlreadyInitializedException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    /**
     * JSONFormatException: used if a JSON response from any external system is not in the expected format
     */ 
    public class JSONFormatException extends CustomException {
        public JSONFormatException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public JSONFormatException(string message, string className, string methodName){
            super(message, className, methodName);
        }
        
        public JSONFormatException buildAndSetStandardMessage(String jsonString, Type deserializationType){
            String errorMsg = 'There was a problem deserializing the input json string into the deserialization class type "' + deserializationType + '". The input json string was (without outermost double-quotes): "' + jsonString + '"';
            setMessage(errorMsg);
            return this;
        }
    }
    
    /**
     * CalloutException: System.CalloutException cannot be constructed, so use this to throw a custom CalloutException
     */ 
    public class CalloutException extends CustomException {
        public CalloutException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public CalloutException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    /**
     * CalloutException: System.CalloutException cannot be constructed, so use this to throw a custom CalloutException
     */ 
    public class LimitException extends CustomException {
        public LimitException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public LimitException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class MultipleFileMastersException extends CustomException {
        public MultipleFileMastersException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public MultipleFileMastersException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class FileAlreadyProcessingException extends CustomException {
        public FileAlreadyProcessingException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public FileAlreadyProcessingException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class ApexValidationException extends CustomException {
        public ApexValidationException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public ApexValidationException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class DMLException extends CustomException {
        public DMLException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public DMLException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class FileParsingException extends CustomException {
        public FileParsingException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public FileParsingException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class BadDataException extends CustomException {
        public BadDataException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public BadDataException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class FileException extends CustomException {
        public FileException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public FileException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class CustomSettingRecordDoesNotExistException extends CustomException {
        public CustomSettingRecordDoesNotExistException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public CustomSettingRecordDoesNotExistException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class TimeException extends CustomException {
        public TimeException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public TimeException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class IteratorException extends CustomException {
        public IteratorException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public IteratorException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class ConcurrencyException extends CustomException {
        public ConcurrencyException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public ConcurrencyException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class QueryException extends CustomException {
        public QueryException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public QueryException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class RecordDoesNotExistException extends CustomException {
        public RecordDoesNotExistException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public RecordDoesNotExistException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class SchemaException extends CustomException {
        public SchemaException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public SchemaException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class TypeException extends CustomException {
        public TypeException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public TypeException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class XMLException extends CustomException {
        public XMLException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public XMLException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }

    public class NullValueException extends CustomException {
        public NullValueException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public NullValueException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class NotImplementedException extends CustomException {
        public NotImplementedException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public NotImplementedException(string message, string className, string methodName){
            super(message, className, methodName);
        }
    }
    
    public class JsonSerializationException extends CustomException {
        public JsonSerializationException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public JsonSerializationException(string message, string className, string methodName){
            super(message, className, methodName);
        }
        
        public Exception buildStandardMessage(Object failedToSerialize){
            String errorMsg = 'Failed to serialize the following object: ' + failedToSerialize + '. Make sure all instance variables are serializable. Original error message was: ' + getMessage();
            setMessage(errorMsg);
            return this;
        }
    }
    
    public class MethodExecutionContextException extends CustomException {
        public MethodExecutionContextException(System.exception baseException, string message, string className, string methodName){
            super(baseException, message, className, methodName);
        }
        
        public MethodExecutionContextException(string message, string className, string methodName){
            super(message, className, methodName);
        }
        
        public Exception buildStandardMessage(String methodName, String executionContext){
            String errorMsg = 'Cannot execute method "' + methodName + '" in execution context "' + executionContext +'"';
            setMessage(errorMsg);
            return this;
        }
    }    
}