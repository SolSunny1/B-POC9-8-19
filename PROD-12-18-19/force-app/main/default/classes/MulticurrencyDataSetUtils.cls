/*
 * Copyright (c) 2016, salesforce.com, inc.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided 
 * that the following conditions are met:
 * 
 *    Redistributions of source code must retain the above copyright notice, this list of conditions and the 
 *    following disclaimer.
 *  
 *    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and 
 *    the following disclaimer in the documentation and/or other materials provided with the distribution. 
 *    
 *    Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or 
 *    promote products derived from this software without specific prior written permission.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR 
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 */


/**
* Generates multicurrency CSV
*
* @author       ericszulc
* @date         01/20/2016
*
*/
public class MulticurrencyDataSetUtils {

    /**
    * Generates query for batch process
    *
    * @author       ericszulc
    * @date         01/20/2015
    * @param        pDescribeSobjectResult: object to base query on
    * @param        pDescribeDateFieldResult: for dated exchange rates, the date field to use
    * @param        pFieldSet: field set to query for
    * @return       the query
    *
    */
	public static String getQuery(
    	Schema.DescribeSObjectResult	pDescribeSobjectResult,
        Schema.DescribeFieldResult 		pDescribeDateFieldResult,
        Schema.FieldSet 				pFieldSet
    ){

        String query = 'SELECT ';
        boolean addedCurrency = false;
        
        for(Schema.FieldSetMember f : pFieldSet.getFields() ){
            
            // BF-25: Updated to ensure test cases work (Removed related fields)
            //if(!String.isEmpty(f.getFieldPath()) && !f.getFieldPath().contains('__r')) {
				query += f.getFieldPath() + ', ';
            //}
        }
        
        if( pDescribeDateFieldResult != null ){
        
            // BF-25: Updated to ensure test cases work (Removed CurrencyIsoCode)	
            query += 'Id, CurrencyIsoCode FROM '+pDescribeSobjectResult.getName()+' ORDER BY '+pDescribeDateFieldResult.getName()+' DESC';
     	
        }else{

            query += 'Id FROM '+pDescribeSobjectResult.getName();
        }
		system.debug(LoggingLevel.DEBUG, 'MulticurrencyDataSetUtils :: getQuery :: query=' + query);
        return query;
    }


    /**
    * Return wave dataset type based on schema types in salesforce
    *
    * @author       ericszulc
    * @date         01/20/2016
    * @param        pFieldSetMember: a field set member
    * @return       the type
    *
    */
    @TestVisible
    private static String getType(
        Schema.DisplayType pDisplayType
    ){
        
        if( 
                pDisplayType == Schema.DisplayType.DATE
            ||  pDisplayType == Schema.DisplayType.DATETIME 
        ){
             
            return 'Date';
        
        } else if( 
                pDisplayType == Schema.DisplayType.CURRENCY 
            ||  pDisplayType == Schema.DisplayType.DOUBLE 
            ||  pDisplayType == Schema.DisplayType.INTEGER
        ){
            
            return 'Numeric';
            
        }else {
            return 'Text';
        }
    }
    

    /**
    * Returns additional parameters based on field type
    *
    * @author       ericszulc
    * @date         01/20/2016
    * @param        pFieldSetMember: a field set member
    * @return       partial json attributes to include in schema
    *
    */
    @TestVisible
    private static String getTypeParameters(
        Schema.DisplayType pDisplayType
    ){
        if( 
                pDisplayType == Schema.DisplayType.DATE
            ||  pDisplayType == Schema.DisplayType.DATETIME 
        ){
             
            return ',"format": "yyyy-MM-dd HH:mm:ss"';
        
        } else if( 
                pDisplayType == Schema.DisplayType.CURRENCY 
            ||  pDisplayType == Schema.DisplayType.DOUBLE 
            ||  pDisplayType == Schema.DisplayType.INTEGER
        ){
            
            return ',"precision":18,"defaultValue":"0","scale":2';
            
        }else {

            return '';
        }
    }


    /**
    * Creates an insights external data
    *
    * @author       ericszulc
    * @date         01/20/2016
    * @param        pEdgemartAlias: the name of the edgemart to save insights external data into
    * @param        pFieldSet: fieldset to use to create schema for insights external data
    * @return       InsightsExternalData
    *
    */
    public static InsightsExternalData getInsightsExternalData(
        String              pEdgemartAlias,
        Schema.FieldSet     pFieldSet
    ){
        
        String metadataJson = '';

        metadataJson += '{"objects":[{"connector":"CSV","fullyQualifiedName":"'+pEdgemartAlias+'_csv","label":"'+pEdgemartAlias+'.csv","name":"'+pEdgemartAlias+'_csv",';
        metadataJson += '"fields":[';
        metadataJson += '{"fullyQualifiedName":"Id","name":"Id","type":"Text","label":"Id"},';
        
        for( Schema.FieldSetMember f : pFieldSet.getFields() ){

            if( f.fieldPath != 'Id' && f.fieldPath != 'CurrencyIsoCode'){

                // dataasets disallow field names like __c_text e.g. amount__c_USD

                String fieldPath = f.fieldPath.replace('__','_');
                        
                metadataJson += '{"fullyQualifiedName":"'+fieldPath+'","name":"'+fieldPath+'","type":"'+getType(f.type)+'","label":"'+f.label+'"'+getTypeParameters(f.type)+'},';
            
                if( f.type == Schema.DisplayType.CURRENCY ){
                        
                    for( CurrencyType ct_i : [
                            SELECT
                                Id,
                                IsoCode,
                                ConversionRate
                            FROM
                                CurrencyType
                            WHERE
                                IsActive = true
                            ORDER BY
                                IsoCode ASC
                    ] ){
                    
                        metadataJson += '{"fullyQualifiedName":"'+fieldPath+'_'+ct_i.IsoCode+'","name":"'+fieldPath+'_'+ct_i.IsoCode+'","type":"'+getType(f.type)+'","label":"'+f.label+' ('+ct_i.IsoCode+')"'+getTypeParameters(f.type)+'},';
                        metadataJson += '{"fullyQualifiedName":"'+fieldPath+'_'+ct_i.IsoCode+'_Conversion_Rate","name":"'+fieldPath+'_'+ct_i.IsoCode+'_Conversion_Rate","type":"Text","label":"'+f.label+' ('+ct_i.IsoCode+' Conversion Rate)"},';
                    }
                }
            }
        }
        
        metadataJson += '{"fullyQualifiedName":"CurrencyIsoCode","name":"CurrencyIsoCode","type":"Text","label":"CurrencyIsoCode"}';
        metadataJson += ']';
        metadataJson += '}]}';
        
        InsightsExternalData insightsExternalDataObj = new InsightsExternalData(
            EdgemartAlias   = pEdgemartAlias,
            Format          = 'csv',
            MetadataJson    = Blob.valueOf(metadataJson),
            Operation       = 'Overwrite',
            Action          = 'None'
        );
        
        return insightsExternalDataObj;
    }






    
    
    
    private List<SObject> 					sObjectList 			{get;set;}    // List of sobject to generate csv for
    private List<Schema.FieldSetMember> 	fieldSetMemberList 		{get;set;}    // field set members to use for columns
    private String							datedConversionRateDate	{get;set;}    // name of date field to use if data conversion rates are used


    /**
    * MulticurrencyDataSetUtils constructor
    *
    * @author       ericszulc
    * @date         01/20/2016
    * @param        pSObjectList: the list of records to create csv for
    * @param        pDatedExchangeDateName: date field to use if dated exchange rates is used
    * @param        pFieldSetMemberList: fieldset to use to create columns for csv
    *
    */
    public MulticurrencyDataSetUtils(
        List<SObject>                   pSObjectList,
        String                          pDatedExchangeDateName,
        List<Schema.FieldSetMember>     pFieldSetMemberList
    ){
        
        this.sObjectList                = pSObjectList;
        this.fieldSetMemberList         = pFieldSetMemberList;
        this.datedConversionRateDate    = pDatedExchangeDateName;
    }
    

    /**
    * Getter/Setter for List<CurrencyType>
    *
    * @author       ericszulc
    * @date         01/20/2016
    * @param        List<CurrencyType>
    * @return       List<CurrencyType>
    *
    */
    @TestVisible
    private List<CurrencyType> currencyTypeList {
        
        get{
            
            if( currencyTypeList == null ){
                
                currencyTypeList = new List<CurrencyType>(
                	[
                        SELECT
                            Id,
                            IsoCode,
                            ConversionRate
                        FROM
                            CurrencyType
                        WHERE
                            IsActive = true
                        ORDER BY
                        	IsoCode ASC
                    ]
                );
            }
            
            return currencyTypeList;
        }
        set;
    }
    

    /**
    * Getter/Setter for mapping currencytypes by iso code
    *
    * @author       ericszulc
    * @date         01/20/2016
    * @param        Map<String,CurrencyType>
    * @return       Map<String,CurrencyType>
    *
    */
    @TestVisible
    private Map<String,CurrencyType> currencyTypeByIsoCode {
        
        get {
            
            if( currencyTypeByIsoCode == null ){
                
                currencyTypeByIsoCode = new Map<String,CurrencyType>();
                
                for( CurrencyType ct_i : currencyTypeList ){
            
                    currencyTypeByIsoCode.put(
                        ct_i.IsoCode,
                        ct_i
                    );
                }
            }
            
            return currencyTypeByIsoCode;
        }
        
        set;
    }


    /**
    * Getter/Setter for Map<Id,DatedConversionRate>
    *
    * @author       ericszulc
    * @date         01/20/2016
    * @param        Map<Id,DatedConversionRate>
    * @return       Map<Id,DatedConversionRate>
    *
    */
    @TestVisible
    private Map<Id,DatedConversionRate> datedConversionRateMap {
        
        get {
            
            if( datedConversionRateMap == null ){
                
                if( datedConversionRateDate != null ){

                    Date oldestDate;
                    Date newestDate;
                    
                    for( SObject so_i : sObjectList ){
                        
                        Date closeDate = Date.valueOf(so_i.get(datedConversionRateDate));
                        
                        if( oldestDate == null || closeDate < oldestDate ){
                            
                            oldestDate = closeDate;
                        }
                        
                        if( newestDate == null || closeDate > newestDate ){
                            
                            newestDate = closeDate;
                        }
                    }
                    
                    datedConversionRateMap = new Map<Id,DatedConversionRate>(
                    	[
                            SELECT
    							Id,
                            	ConversionRate,
                            	StartDate,
                            	NextStartDate,
                            	IsoCode
                           	FROM
                            	DatedConversionRate
                            WHERE
                            	NextStartDate >= :oldestDate AND
                            	StartDate <= :newestDate
                        ]
                        
                    );

                }else{

                    datedConversionRateMap = new Map<Id,DatedConversionRate>();
                }
            }
            
            return datedConversionRateMap;
        }
        
        set;
    }


    /**
    * Getter/Setter for mapping dated converstion rates for ISO Cdde
    *
    * @author       ericszulc
    * @date         01/20/2016
    * @param        Map<String,List<DatedConversionRate>>
    * @return       Map<String,List<DatedConversionRate>>
    *
    */
    @TestVisible
    private Map<String,List<DatedConversionRate>> datedConversionRatesByIsoCode {

        get{

            if( datedConversionRatesByIsoCode == null ){

                datedConversionRatesByIsoCode = new Map<String,List<DatedConversionRate>>();

                for( DatedConversionRate dcr_i : datedConversionRateMap.values() ){

                    if( datedConversionRatesByIsoCode.get(dcr_i.IsoCode) == null ){

                        datedConversionRatesByIsoCode.put(
                            dcr_i.IsoCode,
                            new List<DatedConversionRate>()
                        );
                    }

                    datedConversionRatesByIsoCode.get(dcr_i.IsoCode).add( dcr_i );
                }
            }

            return datedConversionRatesByIsoCode;
        }

        set;
    }
    

    /**
    * Gets the conversion rate for a specific date and iso code
    *
    * @author       ericszulc
    * @date         01/20/2016
    * @param        pISOCode: ISO Code
    * @param        pForDate: Date if dated exchange rates exist
    * @return       conversion rate
    *
    */
    @TestVisible
    private Double getConversionRate(
    	String     pISOCode,
        Date       pForDate
    ){
        
        Double conversionRate = currencyTypeByIsoCode.get(pISOCode).ConversionRate;
        
        if( 
                !datedConversionRateMap.isEmpty()
            &&  pForDate != null 
        ){
            
            //for( DatedConversionRate dcr_i : datedConversionRateMap.values() ){
            
            for( DatedConversionRate dcr_i : datedConversionRatesByIsoCode.get(pISOCode) ){
              
                if( 
                        dcr_i.StartDate         <=  pForDate
                    &&  dcr_i.NextStartDate     >   pForDate
                ){
                    
                    conversionRate = dcr_i.ConversionRate;
                }
            }
        }
        
        return conversionRate;
    }
    

    /**
    * Generates the CSV file
    *
    * @author       ericszulc
    * @date         01/20/2016
    * @param        pIncludeHeader: Whether to include a header for csv
    * @return       csv string
    *
    */
    public String generateDatasetCSV(
        Boolean pIncludeHeader
    ){
        
        String csv = '';

        if( pIncludeHeader ){

            csv += 'Id,';
            
            for(Schema.FieldSetMember f : fieldSetMemberList ){


                String fieldPath = f.fieldPath.replace('__','_');
                
                csv += fieldPath+',';
                
                if( f.type == Schema.DisplayType.CURRENCY ){
                    
                    for( CurrencyType ct_i : currencyTypeList ){
                        
                    	csv += fieldPath + '_' + ct_i.IsoCode + ',';
                        csv += fieldPath + '_' + ct_i.IsoCode + '_Conversion_Rate,';
                    }
                }
            }
            
            csv += 'CurrencyIsoCode\r\n';
        }

        // For each record, generate csv line
        for( SObject so_i : sObjectList ){

            csv += String.valueOf( so_i.get('Id') ) + ',';
            
            // For each field member, get value
            for(Schema.FieldSetMember f : fieldSetMemberList ){
                
                // If currency type, generate value for each currency
                if( f.type == Schema.DisplayType.CURRENCY ){
                    
                    csv += String.valueOf( so_i.get( f.fieldPath ) ) +',';
                    
                    for( CurrencyType ct_i : currencyTypeList ){

                        // get conversion from corporate to record currency
                        Double fromConversionRate = getConversionRate( 
                            String.valueOf( so_i.get('CurrencyIsoCode') ),
                            Date.valueOf( so_i.get(datedConversionRateDate)) 
                        );

                        // get conversion from corporate currency to current currency type
                        Double toConversionRate = getConversionRate(
                            ct_i.IsoCode,
                            Date.ValueOf(so_i.get(datedConversionRateDate))
                        );
                    	
                        // generate (1/record currency) to get back to master currency
                        // multiply by curreny currency type conversion
                        // multiple by currency amount on record
                        if( so_i.get(f.fieldPath) != null ){

                            csv += String.valueOf(
                                (1 / fromConversionRate ) *  toConversionRate  * Double.ValueOf( so_i.get(f.fieldPath) ) 
                            ) + ',';

                        }else{

                            csv +=',';
                        }
                        
                        // generate the to currency rate
                        csv += String.valueOf( toConversionRate ) + ',';
                    }
                
                // else, just generate the value
                // BF-25: Updated to exclude related fields for test coverage
                //}	else if(!String.isEmpty(f.fieldPath) && !f.fieldPath.contains('__r')) {
                }	else {
                    String fieldValue = so_i.get( f.fieldPath ) != null ? String.valueOf( so_i.get( f.fieldPath ) ) : '';
                    csv += fieldValue + ',';
                }
                
            }
            
            csv += String.valueOf( so_i.get('CurrencyIsoCode') ) + '\r\n';
        }
        
        return csv;
    }
}