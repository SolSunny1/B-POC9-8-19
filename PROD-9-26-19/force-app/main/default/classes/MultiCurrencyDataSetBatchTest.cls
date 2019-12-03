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
* Tests MultiCurrencyDataSetBatch
*
* @author       ericszulc
* @date         02/07/2016
*
*/
@isTest
private class MultiCurrencyDataSetBatchTest {


	/**
    * Tests that insights external data is created as expected
    *
    * @author       ericszulc
    * @date         02/07/2016
    * @return       void
    *
    */
	/*@isTest
	static void itShouldProcessRecordsIntoInsightsExternalData() {
		

		// 	Given
		// 		* sobjects exist to instantiate MulticurrencyDataSetUtils

		User currentUser = [SELECT Id FROM User WHERE Id =:UserInfo.getUserId() ];

		System.runAs( currentUser ){
		
			List<Opportunity> opportunityList = new List<Opportunity>();

			for( Integer i=0; i<10; i++ ){

				opportunityList.add(
					new Opportunity(
						Name 		= 'Name',
						StageName 	= 'Open',
						CloseDate 	= Date.today().addDays(1),
						Amount 		= Math.random() * 100
					)
				);
			}

			Database.insert( opportunityList );

			MulticurrencyDataSetUtils m = new MulticurrencyDataSetUtils(
				(List<SObject>) Database.query( 
					MulticurrencyDataSetUtils.getQuery(
						Opportunity.SObjectType.getDescribe(),
						Opportunity.CloseDate.getDescribe(),
						Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency
					) 
				),
	        	'CloseDate',
	        	Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency.getFields()
			);
		}


		// 	When
		//		* A batch process executes for MulticurrencyDataSetBatch

		Test.startTest();

			System.runAs( currentUser ){

				Database.executeBatch( 
					new MulticurrencyDataSetBatch(
						Opportunity.SObjectType.getDescribe(),
	        			Opportunity.CloseDate.getDescribe(),
	        			Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency,
	        			'edgeMart',
	        			null
					),
					200
				);
			}

		Test.stopTest();


		// 	Then
		//		* An InsightsExternalData with name passed in and action = process
		//		* A related data part exists

		List<InsightsExternalData> insightsExternalDataList = new List<InsightsExternalData>(
			[SELECT Id,Action FROM InsightsExternalData WHERE EdgemartAlias = 'edgeMart' ]
		);

		System.assertEquals(
			insightsExternalDataList.size(),
			1
		);

		System.assertEquals(
			insightsExternalDataList[0].Action,
			'Process'
		);

		List<InsightsExternalDataPart> insightsExternalDataPartList = new List<InsightsExternalDataPart>(
			[SELECT Id FROM InsightsExternalDataPart WHERE InsightsExternalDataId = :insightsExternalDataList[0].Id ]
		);

		System.assertEquals(
			insightsExternalDataPartList.size(),
			1
		);
	}*/
}