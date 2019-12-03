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
* Batch process to generate CSV for Wave dataset
*
* @author       ericszulc
* @date         01/20/2015
*
*      Example execution
*
*      MulticurrencyDataSetBatch b = new MulticurrencyDataSetBatch(
*           Opportunity.SObjectType.getDescribe(),
*           Opportunity.CloseDate.getDescribe(),
*           Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency,
*           'MulticurrencyOpportunities',
*           null
*       );
*       Database.executeBatch( b, 100 );
*
*/
global class MulticurrencyDataSetBatch implements Database.Batchable<sObject>, Database.Stateful{
	
    global  final   String                          query;                  // the batch query
    global  final   String                          datedExchangeField;     // date field if dated exchange rates are used
    global  final   List<Schema.FieldSetMember>     fieldSetMemberList;     // list of field set members for csv columns
    global          InsightsExternalData            insightsExternalData;   // the insights external data
    global          Integer                         partNumber;             // each csv part number
    global          String                          csv;                    // the csv file that appended to across batches
    global          Boolean                         firstCSVPart;           // used to generate header on first csv part


    /**
    * MulticurrencyDataSetBatch constructor
    *
    * @author       ericszulc
    * @date         01/20/2015
    * @param        pDescribeSobjectResult: object to based dataset off of
    * @param        pDescribeDateFieldResult: date field to use if dated exhange rates are used
    * @param        pFieldSet: field set to use for columns
    * @param        pEdgeMartName: edgemart name
    *
    */
    global MulticurrencyDataSetBatch(
        Schema.DescribeSObjectResult	pDescribeSobjectResult,
        Schema.DescribeFieldResult 		pDescribeDateFieldResult,
        Schema.FieldSet 				pFieldSet,
        String                          pEdgeMartName,
        String                          pEdgeMartContainer
    ){

        firstCSVPart = true;

        // Store dated exchange field if any
        datedExchangeField = pDescribeDateFieldResult != null ? pDescribeDateFieldResult.getName() : null;
        
        // generate query from object, field set and dated exchange field
        query = MulticurrencyDataSetUtils.getQuery(
            pDescribeSobjectResult,
            pDescribeDateFieldResult,
            pFieldSet
       	);

        fieldSetMemberList = pFieldSet.getFields();

        // get Insights External Data
        insightsExternalData = MulticurrencyDataSetUtils.getInsightsExternalData( 
            pEdgeMartName,
            pFieldSet
        );

        insightsExternalData.EdgemartContainer = pEdgeMartContainer;

        // Insert Insights External Data
        Database.insert( insightsExternalData );

        // Set first part number
        partNumber = 1;
    }
    

    /**
    * Starts the batch process
    *
    * @author       ericszulc
    * @date         01/20/2015
    * @param        pBatchableContext: batchable context
    * @return       Database.QueryLocator
    *
    */
    global Database.QueryLocator start(
        Database.BatchableContext pBatchableContext
    ) {

        return Database.getQueryLocator( query );
    }
    

    /**
    * Executes a batch
    *
    * @author       ericszulc
    * @date         01/20/2015
    * @param        Database.BatchableContext pBatchableContext: batchable context
    * @param        List<sObject> pScope: list of records for batch
    * @return       void
    *
    */
	global void execute(
        Database.BatchableContext pBatchableContext,
        List<sObject> pScope
   	){
        
        // Instantiate multicurrency utils with scope, dated exchange field, and field set members
        MulticurrencyDataSetUtils m = new MulticurrencyDataSetUtils(
            pScope,
            datedExchangeField,
            fieldSetMemberList
        );

        // get the csv portion for this batch
        csv += m.generateDatasetCSV( firstCSVPart );

        // if we already genereated header, set firstCSVPart=false to generate anymore
        if( firstCSVPart ){

            firstCSVPart = !firstCSVPart;
        }


        // save insights external data part if heap size is getting large and reset csv
        // we want to minimize InsightsExternalDataParts because only 4000 parts can be created
        // so, we manage csv across batches with stateful
        if( Limits.getHeapSize() > (Limits.getLimitHeapSize() / 2) ){

            InsightsExternalDataPart iedp = new InsightsExternalDataPart(
                DataFile                = Blob.valueOf( csv ),
                InsightsExternalDataId  = insightsExternalData.Id,
                PartNumber              = partNumber
            );

            Database.insert( iedp );

            partNumber++;

            csv = '';
        }

    }
    
    /**
    * Finish a batch
    *
    * @author       ericszulc
    * @date         01/20/2015
    * @param        Database.BatchableContext pBatchableContext: batchable context
    * @return       void
    *
    */
    global void finish(
        Database.BatchableContext pBatchableContext
    ){

        // If any csv portion is left, save it
        // And start processing the insights external data
        if( csv != '' ){

            InsightsExternalDataPart iedp = new InsightsExternalDataPart(
                DataFile                = Blob.valueOf( csv ),
                InsightsExternalDataId  = insightsExternalData.Id,
                PartNumber              = partNumber
            );

            Database.insert( iedp );
        }


        insightsExternalData.Action = 'Process';

        Database.update( insightsExternalData );

    }
}