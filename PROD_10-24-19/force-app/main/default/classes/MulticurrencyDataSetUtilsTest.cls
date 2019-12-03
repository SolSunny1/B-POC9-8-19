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
* Tests MulticurrencyDataSetUtils
*
* @author       ericszulc
* @date         02/07/2016
*
*/
@isTest
private class MulticurrencyDataSetUtilsTest {
	

	/**
    * Tests that query is constructed correctly
    *
    * @author       ericszulc
    * @date         02/07/2016
    * @return       void
    *
    */
	@isTest
	static void itShouldGetCorrectQuery() {
		
		// 	Given
		//	When
		//		* getQuery is called

		Test.startTest();

			String query = MulticurrencyDataSetUtils.getQuery(
				Opportunity.SObjectType.getDescribe(),
				Opportunity.CloseDate.getDescribe(),
				Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency
			);

			String queryNoDate = MulticurrencyDataSetUtils.getQuery(
				Opportunity.SObjectType.getDescribe(),
				null,
				Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency
			);

		Test.stopTest();

		// 	Then
		//		* query string will contain field set memebers
		//		* query string will be against opportunity
		//		* query string will order by closedate

		for(Schema.FieldSetMember f : Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency.getFields() ){
			
			System.assertEquals(
				query.contains( f.fieldPath ),
				true
			);
		}

		System.assertEquals(
			query.contains( 'FROM '+Opportunity.SObjectType.getDescribe().getName() ),
			true
		);

		System.assertNotEquals(
			queryNoDate.contains( 'ORDER BY '),
			true
		);

	}


	/**
    * Tests that types/params are returned correctly
    *
    * @author       ericszulc
    * @date         02/07/2016
    * @return       void
    *
    */
	@isTest
	static void itShouldGetCorrectType() {

		// 	Given
		//	When
		//		* getType is called with different display types
		//			DATE, DATETIME, CURRENCY, DOUBLE, INTEGER

		Test.startTest();

			String dateType 		= MulticurrencyDataSetUtils.getType( Schema.DisplayType.DATE );
			String dateTimeType 	= MulticurrencyDataSetUtils.getType( Schema.DisplayType.DATETIME );
			String currencyType 	= MulticurrencyDataSetUtils.getType( Schema.DisplayType.CURRENCY );
			String doubleType 		= MulticurrencyDataSetUtils.getType( Schema.DisplayType.DOUBLE );
			String integerType 		= MulticurrencyDataSetUtils.getType( Schema.DisplayType.INTEGER );
			String otherType 		= MulticurrencyDataSetUtils.getType( Schema.DisplayType.STRING );

			String dateTypeParam 		= MulticurrencyDataSetUtils.getTypeParameters( Schema.DisplayType.DATE );
			String dateTimeTypeParam 	= MulticurrencyDataSetUtils.getTypeParameters( Schema.DisplayType.DATETIME );
			String currencyTypeParam 	= MulticurrencyDataSetUtils.getTypeParameters( Schema.DisplayType.CURRENCY );
			String doubleTypeParam 		= MulticurrencyDataSetUtils.getTypeParameters( Schema.DisplayType.DOUBLE );
			String integerTypeParam 	= MulticurrencyDataSetUtils.getTypeParameters( Schema.DisplayType.INTEGER );
			String otherTypeParam 		= MulticurrencyDataSetUtils.getTypeParameters( Schema.DisplayType.STRING );

		Test.stopTest();


		// 	Then
		//		* We should get the following results based on type
		//			* DATE 		=> Date
		//			* DATETIME 	=> Date
		//			* CURRENCY 	=> Numeric
		//			* DOUBLE 	=> Numeric
		//			* INTEGER 	=> Numeric
		//			* Else 		=> Text

		System.assertEquals(
			dateType,
			'Date'
		);

		System.assertEquals(
			dateTimeType,
			'Date'
		);

		System.assertEquals(
			currencyType,
			'Numeric'
		);

		System.assertEquals(
			doubleType,
			'Numeric'
		);

		System.assertEquals(
			integerType,
			'Numeric'
		);

		System.assertEquals(
			otherType,
			'Text'
		);


		System.assertEquals(
			dateTypeParam,
			',"format": "yyyy-MM-dd HH:mm:ss"'
		);

		System.assertEquals(
			dateTimeTypeParam,
			',"format": "yyyy-MM-dd HH:mm:ss"'
		);

		System.assertEquals(
			currencyTypeParam,
			',"precision":18,"defaultValue":"0","scale":2'
		);

		System.assertEquals(
			doubleTypeParam,
			',"precision":18,"defaultValue":"0","scale":2'
		);

		System.assertEquals(
			integerTypeParam,
			',"precision":18,"defaultValue":"0","scale":2'
		);

		System.assertEquals(
			otherTypeParam,
			''
		);
	}


	/**
    * Tests that creates insights external data correcly
    *
    * @author       ericszulc
    * @date         02/07/2016
    * @return       void
    *
    */
	@isTest
	static void itShouldCreateAnInsightsExternalData() {

		// 	Given
		//	When
		//		* getInsightsExternalData is called with a name and field set

		Test.startTest();

			InsightsExternalData ied = MulticurrencyDataSetUtils.getInsightsExternalData(
				'edgemartAlias',
				Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency
			);

		Test.stopTest();


		//	Then
		//		* the edgemart name will be set
		// 		* a json object will be set for each fieldsetmemeber

		System.assertEquals(
			ied.EdgemartAlias,
			'edgemartAlias'
		);

		String metadataJson = ied.MetadataJson.toString();

		for(Schema.FieldSetMember f : Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency.getFields() ){
			
			String fieldPath = f.fieldPath.replace('__','_');

			System.assertEquals(
				metadataJson.contains('{"fullyQualifiedName":"'+fieldPath+'","name":"'+fieldPath+'","type":'),
				true
			);
		}
	}


	/**
    * Tests that currency types are returned as expected
    *
    * @author       ericszulc
    * @date         02/07/2016
    * @return       void
    *
    */
	@isTest
	static void itShouldGetActiveCurrenciesInOrg() {

		// 	Given
		// 		* sobjects exist to instantiate MulticurrencyDataSetUtils
		
		List<Opportunity> opportunityList = new List<Opportunity>();

        // BF-33: Added an account and investmeent to the opportunities to resolve issues with process builders (PFG Erisa Update) and NewOppName Trigger
        Account a = createTestAccount();
        Investment_Vehicle__c iv = createInvestmentVehicle();

		for( Integer i=0; i<10; i++ ){

			opportunityList.add(
				new Opportunity(
                    AccountId   = a.Id,
                    Investment_Vehicle__c = iv.id,
					Name 		= 'Name',
					StageName 	= 'Open',
					CloseDate 	= Date.today().addDays(1)
				)
			);
		}

		Database.insert( opportunityList );


		//	When
		// 		* MulticurrencyDataSetUtils is instantiated

		Test.startTest();

			MulticurrencyDataSetUtils m = new MulticurrencyDataSetUtils(
				(List<SObject>) opportunityList,
	        	'CloseDate',
	        	Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency.getFields()
			);

		Test.stopTest();


		//	Then
		//		* currencyTypeList will contain same number of elements as in org
		//		* all iso codes are contained in currencyTypeByIsoCode

		List<CurrencyType> currencyTypeList = new List<CurrencyType>( [SELECT Id,IsoCode FROM CurrencyType WHERE IsActive=true] );
		Set<String> currencyTypeByIsoCode = new Set<String>();

		for( CurrencyType c_i : currencyTypeList ){

			currencyTypeByIsoCode.add( c_i.IsoCode );
		}

		System.assertEquals(
			m.currencyTypeList.size(),
			currencyTypeList.size()
		);

		for( String k_i : m.currencyTypeByIsoCode.keySet() ){

			System.assertEquals(
				currencyTypeByIsoCode.contains( k_i ),
				true
			);
		}
	}


	/**
    * Tests that dated conversion rates are returned as expected
    *
    * @author       ericszulc
    * @date         02/07/2016
    * @return       void
    *
    */
	@isTest
	static void itShouldGetDatedConversionRates() {

		// 	Given
		// 		* sobjects exist to instantiate MulticurrencyDataSetUtils
		
		List<Opportunity> opportunityList = new List<Opportunity>();

        // BF-33: Added an account and investmeent to the opportunities to resolve issues with process builders (PFG Erisa Update) and NewOppName Trigger
        Account a = createTestAccount();
        Investment_Vehicle__c iv = createInvestmentVehicle();

		for( Integer i=0; i<10; i++ ){

			opportunityList.add(
				new Opportunity(
                    AccountId = a.Id,
                    Investment_Vehicle__c = iv.Id,
					Name 		= 'Name',
					StageName 	= 'Open',
					CloseDate 	= Date.today().addDays(1)
				)
			);
		}

		Database.insert( opportunityList );

		MulticurrencyDataSetUtils m = new MulticurrencyDataSetUtils(
			(List<SObject>) opportunityList,
        	'CloseDate',
        	Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency.getFields()
		);

		Date closeDate = Date.today().addDays(1);

		//	When
		// 		* datedConversionRateMap,datedConversionRatesByIsoCode is called

		Test.startTest();

			Map<Id,DatedConversionRate> 			datedConversionRateMap 			= m.datedConversionRateMap;
			Map<String,List<DatedConversionRate>> 	datedConversionRatesByIsoCode	= m.datedConversionRatesByIsoCode;

		Test.stopTest();


		// 	Then
		//		* Dated Conversion retrieved will only be the ones valid for the close date range
		//		* The iso codes in datedConversionRatesByIsoCode will only be the ISO codes in datedConversionRateMap

		Map<Id,DatedConversionRate> currentDatedConversionRateMap = new Map<Id,DatedConversionRate>(
			[ 
				SELECT
					Id,
					IsoCode
               	FROM
                	DatedConversionRate
                WHERE
                	NextStartDate 	>= :closeDate AND
                	StartDate 		<= :closeDate
            ]
     	);


     	Set<String> isoCodeSet = new Set<String>();

     	for( DatedConversionRate dcr_i : currentDatedConversionRateMap.values() ){

     		isoCodeSet.add( dcr_i.IsoCode );
     	}


		System.assertEquals(
			datedConversionRateMap.values().size(),
			currentDatedConversionRateMap.values().size()
		);

		for( String iso_i : datedConversionRatesByIsoCode.keySet() ){

			System.assertEquals(
				isoCodeSet.contains( iso_i ),
				true
			);
		}
	}


	/**
    * Tests that conversion rate is returned as expected
    *
    * @author       ericszulc
    * @date         02/07/2016
    * @return       void
    *
    */
	@isTest
	static void itShouldGetTheCorrectConversionRate() {

		// 	Given
		// 		* sobjects exist to instantiate MulticurrencyDataSetUtils
		
		List<Opportunity> opportunityList = new List<Opportunity>();

        // BF-33: Added an account and investmeent to the opportunities to resolve issues with process builders (PFG Erisa Update) and NewOppName Trigger
        Account a = createTestAccount();
        Investment_Vehicle__c iv = createInvestmentVehicle();

		for( Integer i=0; i<10; i++ ){

			opportunityList.add(
				new Opportunity(
                    AccountId   = a.Id,  
                    Investment_Vehicle__c = iv.id, 
					Name 		= 'Name',
					StageName 	= 'Open',
					CloseDate 	= Date.today().addDays(1)
				)
			);
		}

		Database.insert( opportunityList );

		MulticurrencyDataSetUtils m = new MulticurrencyDataSetUtils(
			(List<SObject>) opportunityList,
        	'CloseDate',
        	Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency.getFields()
		);

		String isoCode;
		Date closeDate = Date.today().addDays(1);

		if( m.currencyTypeByIsoCode.values().size() > 0 ){


			for( String s_i : m.currencyTypeByIsoCode.keySet() ){

				isoCode = s_i;
				break;
			}

			List<DatedConversionRate> datedConversionRateList = new List<DatedConversionRate>();
			datedConversionRateList = m.datedConversionRatesByIsoCode.get( isoCode );

			DatedConversionRate datedConversionRate;

			for( DatedConversionRate dcr_i  : datedConversionRateList ){

				if( 
						dcr_i.StartDate 	<= 	closeDate
					&&	dcr_i.NextStartDate > 	closeDate
				){
					datedConversionRate = dcr_i;
				}
	     	}


			// 	When
			//		* GetCurrencyRate is called

			Test.startTest();

				Double conversionRate = m.getConversionRate(
					isoCode,
					closeDate
				);

			Test.stopTest();


			// 	Then
			//		* ConversionRate will be the correct rate from dated conversion rate if there are any
			//		* or will be correct conversionrate from currency type if no dated conversion rates exist

			if( datedConversionRate != null ){

				System.assertEquals(
					conversionRate,
					datedConversionRate.ConversionRate
				);

			}else{

				System.assertEquals(
					conversionRate,
					m.currencyTypeByIsoCode.values()[0].ConversionRate
				);
			}
		}
	}

    /**
      * BF-33: Added a helper method to create an account that can be passed to the opportunities created in this
      *        test case
      */
    private static Account createTestAccount() {
        User pfgUser = TestFactory.buildTestUser(1, 'PFG_CRM');
        insert pfgUser;

        Account acct = TestFactory.buildTestAcc(1, pfgUser.Id);
        insert acct;
        return acct;
    }

    /**
      * BF-33: Added a helper method to add an investment vehicle to avoid errors with the new opp name trigger
      */
    private static Investment_Vehicle__c createInvestmentVehicle() {
        Investment_Vehicle__c iv = TestFactory.buildInvestmentVehicle('test');
        insert iv;
        return iv;
    }


	/**
    * Tests that csv is generated as expected
    *
    * @author       ericszulc
    * @date         02/07/2016
    * @return       void
    *
    */
	/*@isTest
	static void itShouldGenerateCSVCorrectly() {

		// 	Given
		// 		* sobjects exist to instantiate MulticurrencyDataSetUtils
		
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

		//	When
		//		* generate csv in called

		Test.startTest();

			String csv = m.generateDatasetCSV( true );

		Test.stopTest();


		//	Then
		//		* the values in opportunity will be contained in the csv

		for( Opportunity o_i : opportunityList ){

			System.assertEquals(
				csv.contains( o_i.Id ),
				true
			);

			System.assertEquals(
				csv.contains( 'Id' ),
				true
			);

			for(  Schema.FieldSetMember f  : Schema.SObjectType.Opportunity.fieldSets.WaveMultiCurrency.getFields() ){

				SObject so = (SObject)o_i;
				String fieldPath = f.fieldPath.replace('__','_');

				System.assertEquals(
					csv.contains( fieldPath ),
					true
				);

				if( so.get(f.fieldPath) != null ){

					System.assertEquals(
						csv.contains( 
							String.valueOf( 
								so.get(f.fieldPath) 
							)
						),
						true
					);
				}
			}
		}
	}*/
}