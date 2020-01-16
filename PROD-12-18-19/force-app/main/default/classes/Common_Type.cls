global with sharing class Common_Type {
    public static final String className = 'Common_Type';
    
     global static List<String> convertDelimitedStringToTrimmedList(string delimitedString, String delimiter) {
        List<string> lstTrimmedStrings = new List<string>();
        
        if (!String.isEmpty(delimitedString)) {        
            List<string> setRawStrings = delimitedString.split(delimiter);
            if (setRawStrings.size() > 0) {
                lstTrimmedStrings = new List<String>();
                for (string sRawString : setRawStrings){
                    lstTrimmedStrings.add(sRawString.trim());
                }
            }
        }

        return lstTrimmedStrings;
    }

    global static Set<String> convertDelimitedStringToTrimmedSet(string delimitedString, String delimiter) {
        Set<string> setTrimmedStrings = new set<string>();
        
        if (!String.isEmpty(delimitedString)) {    
            List<string> setRawStrings = delimitedString.split(delimiter);
            
            if (setRawStrings.size() > 0) {
                setTrimmedStrings = new Set<String>();
                for (string sRawString : setRawStrings) {
                    setTrimmedStrings.add(sRawString.trim());
                }
            }
        }

        return setTrimmedStrings;
    }
    
    global static String convertSetToDelimitedString(Set<String> setStrings, String delimiter) {
        String stringDelimitedString = null;
        if (setStrings != null && setStrings.size() > 0) {
            stringDelimitedString = '';
            for(String str : setStrings){
                if (!String.isEmpty(stringDelimitedString)){
                    stringDelimitedString += delimiter;
                }
                stringDelimitedString += str;
            }
        }
        
        return stringDelimitedString;
    }

    global static String convertListToDelimitedString(List<string> listStrings, String delimiter) {
        String stringDelimitedString = null;
        
        if (listStrings != null && listStrings.size() > 0) {
            stringDelimitedString = '';
            for(String str : listStrings){
                if (!String.isEmpty(stringDelimitedString)){
                    stringDelimitedString += delimiter;
                }
                stringDelimitedString += str;
            }
        }
        
        return stringDelimitedString;
    }

    public static Integer compareObjectTo(Object first, Object second){
        if(first instanceof Date){
            Date d1 = (Date) first;
            Date d2 = (Date) second;
            return d1.isSameDay(d2)?0:d1>d2?1:-1;
        } else if (first instanceof DateTime){
            DateTime dt1 = (DateTime) first;
            DateTime dt2 = (DateTime) second;
            return dt1.isSameDay(dt2)?0:dt1>dt2?1:-1;
        } else if(first instanceof Decimal){
            Decimal d1 = (Decimal) first;
            Decimal d2 = (Decimal) second;
            return d1 == d2?0:d1>d2?1:-1;
        } else if(first instanceof Integer){
            Integer i1 = (Integer) first;
            Integer i2 = (Integer) second;
            return i1 == i2?0:i1>i2?1:-1;
        } else if(first instanceof Double){
            Double d1 = (Double) first;
            Double d2 = (Double) second;
            return d1 == d2?0:d1>d2?1:-1;
        } else {
            String s1 = String.valueOf(first);
            String s2 = String.valueOf(second);
            return s1 == s2?0:s1>s2?1:-1;
        }
    }
    
    //=======================================================================================
    // Converting Set/List container types
    //=======================================================================================
    public static Set<Id> toId(Set<Object> objs){
        Set<Id> toReturn = new Set<Id>();
        for(Object thisId : objs){
            if(thisId!=null) toReturn.add((Id) thisId);
        }
        return toReturn;
    }
    
    public static List<Id> toId(List<Object> objs){
        List<Id> toReturn = new List<Id>();
        for(Object thisId : objs){
            if(thisId!=null) toReturn.add((Id) thisId);
        }
        return toReturn;
    }
    
    //=======================================================================================
    // Converting Lists/Sets
    //=======================================================================================
    public static List<Object> toList(Set<Object> objects){
        List<Object> toReturn = new List<Object>();
        toReturn.addAll(objects);
        return toReturn;
    }
    
    public static Set<Object> toSet(List<Object> objects){
        Set<Object> toReturn = new Set<Object>();
        toReturn.addAll(objects);
        return toReturn;
    }
    
    //=======================================================================================
    // To String
    //=======================================================================================
    public static Set<String> toString(Set<Object> objects, Boolean ignoreNulls){
        Set<String> toReturn = new Set<String>();
        for(Object obj : objects){
            if( !(ignoreNulls && obj==null) ) toReturn.add(String.valueOf(obj));
        }
        return toReturn;
    }    

    //=======================================================================================
    // Primitaive Type Conversion
    //
    // The reason I'm creating a new Enum type instead of using Schema.DisplayType:
    // Schema.DisplayType does not contain all primitive object types
    // (i.e. there is no Schema.DisplayType.DECIMAL or Schema.DisplayType.LONG)
    //=======================================================================================
    
    public enum PrimitiveType {
        T_ID, T_BOOLEAN, T_DATE, T_DATETIME, T_DECIMAL, T_DOUBLE, T_INTEGER, T_LONG, T_STRING
    }
    
    private static Map<String, PrimitiveType> stringValToPrimType {
        get {
            if(stringValToPrimType==null){
                stringValToPrimType = new Map<String, PrimitiveType>();
                for(PrimitiveType p : PrimitiveType.values()){
                    stringValToPrimType.put(p.name().toLowerCase(), p);
                }
            }
            return stringValToPrimType;
        }
        private set;
    }
   
    private static Map<Schema.DisplayType, Common_Type.PrimitiveType> displayTypeToPrimitiveType {
        get {
            if(displayTypeToPrimitiveType==null){
                displayTypeToPrimitiveType = new map<Schema.DisplayType, Common_Type.PrimitiveType>{
                    Schema.DisplayType.ID           => Common_Type.PrimitiveType.T_ID,
                    Schema.DisplayType.BOOLEAN      => Common_Type.PrimitiveType.T_BOOLEAN,
                    Schema.DisplayType.DATE         => Common_Type.PrimitiveType.T_DATE,
                    Schema.DisplayType.DATETIME     => Common_Type.PrimitiveType.T_DATETIME,
                    Schema.DisplayType.DOUBLE       => Common_Type.PrimitiveType.T_DOUBLE,
                    Schema.DisplayType.INTEGER      => Common_Type.PrimitiveType.T_INTEGER,
                    Schema.DisplayType.STRING       => Common_Type.PrimitiveType.T_STRING,
                    Schema.DisplayType.PICKLIST     => Common_Type.PrimitiveType.T_STRING,
                    Schema.DisplayType.MULTIPICKLIST => Common_Type.PrimitiveType.T_STRING
                };
            }
            return displayTypeToPrimitiveType;
        }
        private set;
    }
    
    private static Map<Common_Type.PrimitiveType, Caster> primitiveTypeToCaster {
        get {
            if(primitiveTypeToCaster==null){
                primitiveTypeToCaster = new Map<Common_Type.PrimitiveType, Caster>{
                    Common_Type.PrimitiveType.T_ID           => new Common_Type.IdCaster(),
                    Common_Type.PrimitiveType.T_BOOLEAN      => new Common_Type.BooleanCaster(),
                    Common_Type.PrimitiveType.T_DATE         => new Common_Type.DateCaster(),
                    Common_Type.PrimitiveType.T_DATETIME     => new Common_Type.DateTimeCaster(),
                    Common_Type.PrimitiveType.T_DECIMAL      => new Common_Type.DecimalCaster(),
                    Common_Type.PrimitiveType.T_DOUBLE       => new Common_Type.DoubleCaster(),
                    Common_Type.PrimitiveType.T_INTEGER      => new Common_Type.IntegerCaster(),
                    Common_Type.PrimitiveType.T_LONG         => new Common_Type.LongCaster(),
                    Common_Type.PrimitiveType.T_STRING       => new Common_Type.StringCaster()
                };
            }
            return primitiveTypeToCaster;
        }
        private set;
    }
    
    //=======================================================================================
    // Type Casting
    //=======================================================================================
    
    public static Object getValueAs(Schema.DisplayType dt, Object o){
        system.debug( 'dt is ' + dt );
        system.debug( 'o is ' + o);
        return primitiveTypeToCaster.get( displayTypeToPrimitiveType.get(dt) ).getCastedValue(o);
    }
    
    public static Object getValueAs(Common_Type.PrimitiveType t, Object o){
        return primitiveTypeToCaster.get(t).getCastedValue(o);
    }

    public abstract class Caster {
        public Object GetCastedValue(Object o){
            if(o==null || String.valueOf(o)==''){
                return null;
            }
            
            return CastSpecific(o);
        }
        
        abstract Object CastSpecific(Object o);
    }
    
    public class IdCaster extends Caster {
        public override Object CastSpecific(Object o){
            return Id.valueOf( String.valueOf(o) );
        }
    }

    public class BooleanCaster extends Caster {
        public override Object CastSpecific(Object o){
            return Boolean.valueOf( String.valueOf(o) );
        }
    }

    public class DateCaster extends Caster {
        public override Object CastSpecific(Object o){
            return Date.valueOf( String.valueOf(o) );
        }
    }

    public class DateTimeCaster extends Caster {
        public override Object CastSpecific(Object o){
            return Datetime.valueOf( String.valueOf(o) ); 
        }
    }

    public class DecimalCaster extends Caster {
        public override Object CastSpecific(Object o){
            return Decimal.valueOf( String.valueOf(o) );
        }
    }

    public class DoubleCaster extends Caster {
        public override Object CastSpecific(Object o){
            return Double.valueOf( String.valueOf(o) );
        }
    }

    public class LongCaster extends Caster {
        public override Object CastSpecific(Object o){
            return Long.valueOf( String.valueOf(o) );
        }
    }
    
    public class IntegerCaster extends Caster {
        public override Object CastSpecific(Object o){
            return Integer.valueOf( String.valueOf(o) );
        }
    }

    public class StringCaster extends Caster {
        public override Object CastSpecific(Object o){
            return String.valueOf(o);
        }
    }
    
    //========================================================================================
    // Type Inference
    //========================================================================================
    public static PrimitiveType GetPrimitiveType(String t){
        return stringValToPrimType.get(t.toLowerCase());
    }

    public static PrimitiveType GetPrimitiveDataStructureType(Object dataStructure){
        PrimitiveType tp = GetPrimitiveListType(dataStructure);
        if(tp==null) tp = GetPrimitiveSetType(dataStructure);
        
        return tp;
    }

    public static String getDelimiterFromString(String stringWithDelimiter){
        string delimiter = ';';
        if(stringWithDelimiter.contains(','))
            delimiter = ',';

        return delimiter;
    }
    
    public static PrimitiveType GetPrimitiveListType(Object dataStructure){
        Boolean isInstance;
        try{
            isInstance = dataStructure instanceOf List<Id>;
            if(isInstance==true) return PrimitiveType.T_ID;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf List<Boolean>;
            if(isInstance==true) return PrimitiveType.T_BOOLEAN;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf List<Date>;
            if(isInstance==true) return PrimitiveType.T_DATE;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf List<DateTime>;
            if(isInstance==true) return PrimitiveType.T_DATETIME;
        } catch(Exception e){}
        try{ //order matters here, as decimals over 7 characters get converted to scientific notation
            isInstance = dataStructure instanceOf List<Long>;
            if(isInstance==true) return PrimitiveType.T_LONG;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf List<Decimal>;
            if(isInstance==true) return PrimitiveType.T_DECIMAL;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf List<Double>;
            if(isInstance==true) return PrimitiveType.T_DOUBLE;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf List<Integer>;
            if(isInstance==true) return PrimitiveType.T_INTEGER;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf List<String>;
            if(isInstance==true) return PrimitiveType.T_STRING;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf List<Object>;
            if(isInstance==true) {
                List<Object> castedType = (List<Object>) dataStructure;
                if(castedType.size()==0){
                    throw new Common_Exceptions.TypeException('An empty data structure of type List<Object> was passed; cannot infer primitive type', 'Common_Type', 'GetPrimitiveSetType');
                }
                
                Object valToInferOn = null;
                
                for(Object o : castedType){
                    if(o!=null){
                        valToInferOn = o;
                        break;
                    }
                }
                
                if(valToInferOn==null){
                    throw new Common_Exceptions.TypeException('Input data structure contains only null values');
                }
                
                return GetPrimitiveType( valToInferOn );
            }
        }
        catch(Exception e){}
        
        return null;
    }
    
    public static PrimitiveType GetPrimitiveSetType(Object dataStructure){
        Boolean isInstance;
        try{
            isInstance = dataStructure instanceOf Set<Id>;
            if(isInstance==true) return PrimitiveType.T_ID;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf Set<Boolean>;
            if(isInstance==true) return PrimitiveType.T_BOOLEAN;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf Set<Date>;
            if(isInstance==true) return PrimitiveType.T_DATE;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf Set<DateTime>;
            if(isInstance==true) return PrimitiveType.T_DATETIME;
        } catch(Exception e){}
        try{ //order matters here, as decimals over 7 characters get converted to scientific notation
            isInstance = dataStructure instanceOf Set<Long>;
            if(isInstance==true) return PrimitiveType.T_LONG;
        } catch(Exception e){}        
        try{
            isInstance = dataStructure instanceOf Set<Decimal>;
            if(isInstance==true) return PrimitiveType.T_DECIMAL;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf Set<Double>;
            if(isInstance==true) return PrimitiveType.T_DOUBLE;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf Set<Integer>;
            if(isInstance==true) return PrimitiveType.T_INTEGER;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf Set<String>;
            if(isInstance==true) return PrimitiveType.T_STRING;
        } catch(Exception e){}
        try{
            isInstance = dataStructure instanceOf Set<Object>;
            if(isInstance==true) {
                Set<Object> castedType = (Set<Object>) dataStructure;
                if(castedType.size()==0){
                    throw new Common_Exceptions.TypeException('An empty data structure of type Set<Object> was passed; cannot infer primitive type', 'Common_Type', 'GetPrimitiveSetType');
                }
                
                Object valToInferOn = null;
                
                for(Object o : castedType){
                    if(o!=null){
                        valToInferOn = o;
                        break;
                    }
                }
                
                if(valToInferOn==null){
                    throw new Common_Exceptions.TypeException('Input data structure contains only null values');
                }
                
                return GetPrimitiveType( valToInferOn );
            }
        }
        catch(Exception e){}
        
        return null;
    }    
    
    public static PrimitiveType GetPrimitiveType(Object o){
        Boolean isInstance;
        try{
            isInstance = o instanceOf Id;
            if(isInstance==true) return PrimitiveType.T_ID;
        } catch(Exception e){}
        try{
            isInstance = o instanceOf Boolean;
            if(isInstance==true) return PrimitiveType.T_BOOLEAN;
        } catch(Exception e){}
        try{
            isInstance = o instanceOf Date;
            if(isInstance==true) return PrimitiveType.T_DATE;
        } catch(Exception e){}
        try{
            isInstance = o instanceOf DateTime;
            if(isInstance==true) return PrimitiveType.T_DATETIME;
        } catch(Exception e){}
        try{
            isInstance = o instanceOf Long;
            if(isInstance==true) return PrimitiveType.T_LONG;
        } catch(Exception e){}        
        try{
            isInstance = o instanceOf Decimal;
            if(isInstance==true) return PrimitiveType.T_DECIMAL;
        } catch(Exception e){}
        try{
            isInstance = o instanceOf Double;
            if(isInstance==true) return PrimitiveType.T_DOUBLE;
        } catch(Exception e){}
        try{
            isInstance = o instanceOf Integer;
            if(isInstance==true) return PrimitiveType.T_INTEGER;
        } catch(Exception e){}
        try{
            isInstance = o instanceOf String;
            if(isInstance==true) return PrimitiveType.T_STRING;
        } catch(Exception e){}
        
        return null;
    }
    
    public static TypeMetadata getTypeMetadata(Object o){
        return new TypeMetadata(o);
    }

    public class TypeMetadata {
        Object subject;
        Boolean isIterable;
        Type primitiveType;
        List<Object> iterableObj;

        private TypeMetadata(Object o){
            this.subject = o;
        }

        public Boolean isIterable(){
            if(isIterable==null){
                Boolean b = true;
                try {
                    iterableObj = getIterable();
                } catch (TypeException e){
                    b = false;
                }

                isIterable = b;
            }

            return isIterable;
        }

        // I ADMIT THIS IS WRONG. A class called TypeMetadata should only return *metadata*, not *data*,
        // but I'm on a huge time constraint and this is the easiest thing to do right now...
        // -- Josh
        public List<Object> getIterable(){
            if(iterableObj==null){
                Boolean success = false;
                List<Object> iter = new List<Object>();
                
                // The order here is incredibly important because there are a few caveats with salesforce json class:
                // - the list (1, 4, 4) of numbers will actually successfully deserialize as list<Date> for some god unknown reason, so we first explicitly try numbers;  if that fails, we then try date
                // try List<Double>
                try {
                    List<Double> objs = (List<Double>) JSON.deserializeStrict(json.serialize(subject), List<Double>.class);
                    for(Decimal obj : objs){
                        iter.add(obj);
                    }
                    success = true;
                } catch (JSONException e){}
                
                // try List<Date>
                if(!success){
                    try {
                        List<Date> objs = (List<Date>) JSON.deserializeStrict(json.serialize(subject), List<Date>.class);
                        for(Date obj : objs){
                            Object val = obj!=null ? Date.newInstance(obj.year(), obj.month(), obj.day()) : null;
                            iter.add(val);
                        }
                        success = true;
                    } catch (JSONException e){}
                }
                
                // try List<Object>
                if(!success){
                    iter = (List<Object>) JSON.deserializeUntyped(JSON.serialize(subject));
                    success = true;
                    system.debug('deserializing generic');
                }
                
                iterableObj = iter;
            }
            
            return iterableObj;
        }

        // If the passed in object is iterable, this returns the type of the object's first non-null element, else, return the type of the object
        public Type getPrimitiveType(){
            if(primitiveType==null){
                Object delegateObj = this.subject;
                
                if(isIterable()==true){
                    List<Object> temp = getIterable();
                    Object victim = null;
                    
                    for(Object o : temp){
                        if(o!=null){
                            victim = o;
                            break;
                        }
                    }
                    
                    delegateObj = victim;
                }

                primitiveType = getType(delegateObj);
            }

            return primitiveType;
        }

        private Type getType(Object delegateObj){
            Boolean isInstance;
            system.debug( 'delegateObj looks like \'' + delegateObj +'\'' );
            try{
                isInstance = delegateObj instanceOf Id;
                if(isInstance==true) return Id.class;
            } catch(Exception e){}
            try{
                isInstance = delegateObj instanceOf Boolean;
                if(isInstance==true) return Boolean.class;
            } catch(Exception e){}
            // order is important because date is an instance of datetime, but not vice versa
            try{
                isInstance = delegateObj instanceOf Date;
                if(isInstance==true) return Date.class;
            } catch(Exception e){}
            try{
                isInstance = delegateObj instanceOf DateTime;
                if(isInstance==true) return DateTime.class;
            } catch(Exception e){}
            try{
                isInstance = delegateObj instanceOf Integer;
                if(isInstance==true) return Integer.class;
            } catch(Exception e){}
            try{
                isInstance = delegateObj instanceOf Long;
                system.debug( 'delegateObj instanceOf Long returned ' + isInstance );
                if(isInstance==true) return Long.class;
            } catch(Exception e){}            
            try{
                isInstance = delegateObj instanceOf Decimal;                
                if(isInstance==true)
                {	//for some reason, the isinstance check above for int and long never passes, so it's time to be more explicit
                    Decimal converted = (decimal)delegateObj;
                    try
                    {
                        integer i = converted.intValue();
                        system.debug( 'integer cast of delegateObj looks like ' + i );
                        if( i == converted )
                            return Integer.class;                        
                    }
                    catch( exception e )
                    {
                        system.debug( 'cast to integer threw:' + e.getMessage() );
                    }
					try
                    {
                        long l = converted.longValue();
                        system.debug( 'long cast of delegateObj looks like ' + l );
                        if( l == converted )
                            return Long.class;                        
                    }
                    catch( exception e )
                    {
                        system.debug( 'cast to long threw:' + e.getMessage() );
                    }
                    return Decimal.class;
                }
            } catch(Exception e){}
            try{
                isInstance = delegateObj instanceOf Double;
                if(isInstance==true) return Double.class;
            } catch(Exception e){}
            try{
                isInstance = delegateObj instanceOf String;
                if(isInstance==true) return String.class;
            } catch(Exception e){}
            
            return Object.class;
        }
    }

    /*
        This class borrowed from:
        http://titancronus.com/blog/2014/05/01/salesforce-acquiring-dependent-picklists-in-apex/
        http://titancronus.com/blog/2014/07/03/acquiring-dependent-picklists-in-apex-contd/
    */
    public class Bitset{
        public Map<String,Integer> AlphaNumCharCodes {get;set;}
        public Map<String, Integer> Base64CharCodes { get; set; }
        public Bitset(){
            LoadCharCodes();
        }
        //Method loads the char codes
        private void LoadCharCodes(){
            AlphaNumCharCodes = new Map<String,Integer>{
                'A'=>65,'B'=>66,'C'=>67,'D'=>68,'E'=>69,'F'=>70,'G'=>71,'H'=>72,'I'=>73,'J'=>74,
                'K'=>75,'L'=>76,'M'=>77,'N'=>78,'O'=>79,'P'=>80,'Q'=>81,'R'=>82,'S'=>83,'T'=>84,
                'U'=>85,'V'=>86,'W'=>87,'X'=>88,'Y'=>89,'Z'=>90
            };
            Base64CharCodes = new Map<String, Integer>();
            //lower case
            Set<String> pUpperCase = AlphaNumCharCodes.keySet();
            for(String pKey : pUpperCase){
                //the difference between upper case and lower case is 32
                AlphaNumCharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey)+32);
                //Base 64 alpha starts from 0 (The ascii charcodes started from 65)
                Base64CharCodes.put(pKey,AlphaNumCharCodes.get(pKey) - 65);
                Base64CharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey) - (65) + 26);
            }
            //numerics
            for (Integer i=0; i<=9; i++){
                AlphaNumCharCodes.put(string.valueOf(i),i+48);
                //base 64 numeric starts from 52
                Base64CharCodes.put(string.valueOf(i), i + 52);
            }
            Base64CharCodes.put('/',63);
            Base64CharCodes.put('+',62);
        }
        /*
            Effect: Method takes a validFor String and tests it against a set of controlling indexes
            Postcondition: Returns a list of all controlling indexes for which the validFor String test True
        */
        public List<Integer> testBits(String pValidFor,List<Integer> nList, Boolean isCheckbox){
            system.debug(pValidFor);
            system.debug(nList);
            system.debug(isCheckbox);
            List<Integer> results = new List<Integer>();
            //the list of bytes (not derived from n)
            List<Integer> pBytes = new List<Integer>();
            //multiply by 6 since base 64 uses 6 bits (not derived form n)
            Integer bytesBeingUsed = (pValidFor.length() * 6)/8;
            //will be used to hold the full decimal value (not derived from n)
            Integer pFullValue = 0;
            //must be more than 1 byte
            if (bytesBeingUsed <= 1)
                return results;
            //get the base64bytes
            for(Integer i=0;i<pValidFor.length();i++){
                //get currenct character value
                pBytes.Add((Base64CharCodes.get((pValidFor.Substring(i, i+1)))));
            }   
            system.debug(pBytes);
            //calculate the full decimal value
            for (Integer i = 0; i < pBytes.size(); i++){
                Integer pShiftAmount = (pBytes.size()-(i+1))*6;//used to shift by a factor 6 bits to get the value
                pFullValue = pFullValue + (pBytes[i] << (pShiftAmount));
                system.debug(pFullValue);
            }

            //now we don't want to always be declaring memory, so let's set the initial 
            //variables
            Integer bit;
            Integer targetOctet;
            Integer shiftBits;
            Integer tBitVal;
            Integer n;
            Integer nListSize = nList.size();
            for(Integer i=0; i<nListSize; i++){
                n = nList[i];
                if(!isCheckbox){
                    //calculate the target bit for comparison
                    bit = 7 - (Math.mod(n,8)); 
                    //calculate the octet that has in the target bit
                    targetOctet = (bytesBeingUsed - 1) - (n >> bytesBeingUsed); 
                    //the number of bits to shift by until we find the bit to compare for true or false
                    shiftBits = (targetOctet * 8) + bit;
                    //& is to set the same set of bits for testing
                    //shift to the bit which will dictate true or false
                    //Math.Pow(2, shiftBits) == 2 << (shiftBits+1)
                    tBitVal = ((Integer)(2 << (shiftBits-1)) & pFullValue) >> shiftBits;
                    if (tBitVal==1)
                        results.add(n);
                } else {
                    //base64 is 6 bits, so to get it into ASCIIish form, we need to add two bits to the right
                    Integer byteToCheck = pBytes[0] << 2;
                    //boolean only uses the first two bits, controller false is first, controller true is second
                    if(i==0){
                        system.debug('For '+byteToCheck+' masking with 128 and 7x right shift');
                        //bitwise with 10000000 and shift right 7 to get a 1 or 0 out
                        tBitVal = (byteToCheck & 128) >> 7;
                    } else if(i==1){
                        system.debug('For '+byteToCheck+' masking with 64 and 6x right shift');
                        //bitwise with 01000000 and shift right 6 to get a 1 or 0 out
                        tBitVal = (byteToCheck & 64) >> 6;
                    }
                    system.debug(tBitVal);
                    if (tBitVal==1){
                        results.add(i);
                    }
                }
                
            }
            return results;
        }
    }
}