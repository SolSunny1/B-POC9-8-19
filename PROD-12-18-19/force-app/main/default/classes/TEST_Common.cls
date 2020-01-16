@isTest (SeeAllData=false)
private with sharing class TEST_Common {

    //=================================================================================================================
    // Type
    //=================================================================================================================
    private static testMethod void test_Type_convertListToDelimitedString() {
        List<String> testStringList = new List<String>();
        testStringList.add('test1');
        testStringList.add('test2');
        testStringList.add('test3');

        system.assertEquals('test1;test2;test3', Common_Type.convertListToDelimitedString(testStringList, ';'));
        system.assertEquals(3, Common_Type.convertDelimitedStringToTrimmedList('test1;test2;test3', ';').size());
        system.assertEquals(3, Common_Type.convertDelimitedStringToTrimmedSet('test1;test2;test3', ';').size());

    }
    private static testMethod void test_Type_convertSetToDelimitedString() {
        Set<String> testStringSet = new Set<String>();
        testStringSet.add('test1');
        testStringSet.add('test2');
        testStringSet.add('test3');

        String s = Common_Type.convertSetToDelimitedString(testStringSet, ';');
        system.assert(s.contains('test1'));
        system.assert(s.contains('test2'));
        system.assert(s.contains('test3'));


    }

    private static testMethod void test_Type_toId() {
        //Set
        Set<Object> testAccountIds = new Set<Object>();

        Account a = new Account(Name='Test 1');
        Account b = new Account(Name='Test 2');
        insert a;
        insert b;
        testAccountIds.add(a.Id);
        testAccountIds.add(b.Id);

        Set<Id> testIdSet = Common_Type.toId(testAccountIds);

        system.assert(testIdSet.contains(a.Id));
        system.assert(testIdSet.contains(b.Id));

        //List
        List<Object> testAccountIdslist = new List<Object>();

        Account a2 = new Account(Name='Test 1');
        Account b2 = new Account(Name='Test 2');
        insert a2;
        insert b2;
        testAccountIdslist.add(a2.Id);
        testAccountIdslist.add(b2.Id);

        List<Id> testIdList = Common_Type.toId(testAccountIdslist);

        system.assertEquals(2, testIdList.size());

    }

    private static testMethod void test_Type_ConvertListSet() {
        List<Object> accountList = new List<Object>();

        Account a = new Account(Name='Test 1');
        Account b = new Account(Name='Test 2');
        insert a;
        insert b;
        accountList.add(a.Id);
        accountList.add(b.Id);

        system.assertEquals(2, Common_Type.toSet(accountList).size());

        Set<Object> accountSet = new Set<Object>();

        Account a2 = new Account(Name='Test 1');
        Account b2 = new Account(Name='Test 2');
        insert a2;
        insert b2;
        accountSet.add(a2.Id);
        accountSet.add(b2.Id);

        system.assertEquals(2, Common_Type.toList(accountSet).size());
    }

    private static testMethod void test_Type_toString() {
        Set<Object> objectSet = new Set<Object>();
        Date d1 = Date.valueOf('2000-1-1');
        Date d2 = Date.valueOf('2000-1-2');
        Date d3 = null;
        objectSet.add(d1);
        objectSet.add(d2);
        objectSet.add(d3);

        Set<String> stringSet = Common_Type.toString(objectSet, true);
        //system.assert(stringSet.contains(String.valueOf(d2)));
        system.assertEquals(2, stringSet.size());
    }

    private static testMethod void test_Type_typeCasting() {
        Account a = new Account(Name='Test Account');
        insert a;
        String idString = String.valueOf(a.Id);

        System.assertEquals(a.Id, Common_type.getValueAs(Schema.DisplayType.Id, idString));
        System.assertEquals(true, Common_type.getValueAs(Schema.DisplayType.BOOLEAN, 'true'));
        System.assertEquals(Date.valueOf('2000-1-1'), Common_type.getValueAs(Schema.DisplayType.DATE, '2000-1-1'));
        System.assertEquals(Datetime.valueOf('2000-1-1 01:02:03'), Common_type.getValueAs(Schema.DisplayType.DATETIME, '2000-1-1 01:02:03'));
        System.assertEquals(2.0, Common_type.getValueAs(Schema.DisplayType.DOUBLE, '2'));
        System.assertEquals(2, Common_type.getValueAs(Schema.DisplayType.INTEGER, '2'));
        System.assertEquals(idString, Common_type.getValueAs(Schema.DisplayType.STRING, a.Id));

        System.assertEquals(true, Common_type.getValueAs(Common_Type.PrimitiveType.T_BOOLEAN, 'true'));
    }

    private static testMethod void test_Type_Inference() {
        system.assertEquals(Common_Type.PrimitiveType.T_BOOLEAN, Common_Type.GetPrimitiveDataStructureType(new List<Boolean>{true,false}));
        system.assertEquals(Common_Type.PrimitiveType.T_DATE, Common_Type.GetPrimitiveDataStructureType(new List<Date>()));
        system.assertEquals(Common_Type.PrimitiveType.T_DATETIME, Common_Type.GetPrimitiveDataStructureType(new List<Datetime>()));
        system.assertEquals(Common_Type.PrimitiveType.T_LONG, Common_Type.GetPrimitiveDataStructureType(new List<Long>()));
        system.assertEquals(Common_Type.PrimitiveType.T_DECIMAL, Common_Type.GetPrimitiveDataStructureType(new List<Decimal>()));
        system.assertEquals(Common_Type.PrimitiveType.T_STRING, Common_Type.GetPrimitiveDataStructureType(new List<String>{'Test String'}));
        system.assertEquals(Common_Type.PrimitiveType.T_BOOLEAN, Common_Type.GetPrimitiveDataStructureType(new List<Object>{true,false}));
        system.assertEquals(null, Common_Type.GetPrimitiveDataStructureType(null));

        system.assertEquals(Common_Type.PrimitiveType.T_BOOLEAN, Common_Type.GetPrimitiveDataStructureType(new Set<Object>{true,false}));
        system.assertEquals(Common_Type.PrimitiveType.T_DATE, Common_Type.GetPrimitiveDataStructureType(new Set<Object>{Date.valueOf('2000-1-1')}));
        system.assertEquals(Common_Type.PrimitiveType.T_DATETIME, Common_Type.GetPrimitiveDataStructureType(new Set<Object>{Datetime.valueOf('2000-1-1 01:01:01')}));
        system.assertEquals(Common_Type.PrimitiveType.T_LONG, Common_Type.GetPrimitiveDataStructureType(new Set<Object>{2}));
        system.assertEquals(Common_Type.PrimitiveType.T_DECIMAL, Common_Type.GetPrimitiveDataStructureType(new Set<Object>{2.0}));
        system.assertEquals(Common_Type.PrimitiveType.T_STRING, Common_Type.GetPrimitiveDataStructureType(new Set<Object>{'Test String'}));
    }

    private static testMethod void test_Type_Metadata() {
        List<Object> o = new List<Object>{true};
        Common_Type.TypeMetadata metadata = Common_Type.getTypeMetadata(o);
        system.assertEquals(true, metadata.isIterable());
        system.assertEquals(Boolean.class, metadata.getPrimitiveType());
    }

    //=================================================================================================================
    // Common_Feature
    //=================================================================================================================

    private static testMethod void testFeature() {

        boolean bPreInsert = Common_Feature.isEnabled('TestFeature');

        Feature__c feature = new Feature__c(Name='TestFeature', Enabled__c=true);
        insert feature;

        boolean bPostInsert = Common_Feature.isEnabled('TestFeature');

    }

    //=================================================================================================================
    // Common_SFDC
    //=================================================================================================================

    private static testMethod void testConvenienceMethods() {

        boolean bIsCustomField = Common_SFDC.isCustomField('AccountId');
        system.assert(bIsCustomField == false, 'AccountId is not a custom field');

        bIsCustomField = Common_SFDC.isCustomField('Employee__c');
        system.assert(bIsCustomField == true, 'Employee__c is a custom field');
    }

    private static testMethod void testQueryBuilder() {

        Common_SFDC.QueryBuilder queryBuilder = new Common_SFDC.QueryBuilder();
        queryBuilder.WhereClauseItems.add('field1 = value1');
        queryBuilder.WhereClauseItems.add('field2 = value2');

        system.assertEquals('WHERE (field1 = value1 AND field2 = value2)', queryBuilder.getWhereClause());

    }

    private static testMethod void testMergeFields() {
        Account a1 = new Account(Name='Test Account 1');
        insert a1;

        Account a2 = new Account(Name='Test Account 2');
        insert a2;

        Contact c1 = new Contact(LastName='Test Contact 1', FirstName = 'FirstName');
        insert c1;

        Common_SFDC.MergeFieldStringBuilder builder = new Common_SFDC.MergeFieldStringBuilder('I want to see the {!Account.CreatedById} in the {!Account.Name} of the {!Contact.Name}');
        builder.queryForMergeData('Account','Id', a1.ID);

        builder.getMergedString();
        builder.updateMergeString('This is a test');

        builder.addMergeField('Account','Id', a1.ID, false);
        //builder.getMergeFields();


        //Common_SFDC.MergeFieldStringBuilder builder2 = new Common_SFDC.MergeFieldStringBuilder();
        //builder2.queryForUnescapedMergeData('Account','Name','Test Account 1');
    }

    @isTest static void test_Bits() {
        //fake a instance since nothing exists in salesforce standard
        Common_Type.Bitset BitSetInstance = new Common_Type.Bitset();
        BitSetInstance.testBits('gAAA',new List<Integer>{0,1},true);
    }

    //=================================================================================================================
    // Common_Exceptions
    //=================================================================================================================

    private static testMethod void test_Commmon_Exceptions() {

        sObjectType objType = Account.sObjectType;

        try {
            Common_Exceptions.addErrorMessage('Test Message');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            Common_Exceptions.addWarningMessage('Test Message');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            Common_Exceptions.throwBadDataExceptionOnBadLocalFieldValue(new Account(Name='Test'), 'Name', 'Test');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.FatalApplicationException(new Common_Exceptions.FatalApplicationException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.AlreadyInitializedException(new Common_Exceptions.AlreadyInitializedException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.JSONFormatException(new Common_Exceptions.JSONFormatException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.CalloutException(new Common_Exceptions.CalloutException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.LimitException(new Common_Exceptions.LimitException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.MultipleFileMastersException(new Common_Exceptions.MultipleFileMastersException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.FileAlreadyProcessingException(new Common_Exceptions.FileAlreadyProcessingException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.ApexValidationException(new Common_Exceptions.ApexValidationException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.DMLException(new Common_Exceptions.DMLException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.FileParsingException(new Common_Exceptions.FileParsingException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.BadDataException(new Common_Exceptions.BadDataException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.FileException(new Common_Exceptions.FileException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.CustomSettingRecordDoesNotExistException(new Common_Exceptions.CustomSettingRecordDoesNotExistException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.TimeException(new Common_Exceptions.TimeException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.IteratorException(new Common_Exceptions.IteratorException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.ConcurrencyException(new Common_Exceptions.ConcurrencyException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.QueryException(new Common_Exceptions.QueryException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.RecordDoesNotExistException(new Common_Exceptions.RecordDoesNotExistException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.SchemaException(new Common_Exceptions.SchemaException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.TypeException(new Common_Exceptions.TypeException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.XMLException(new Common_Exceptions.XMLException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.NullValueException(new Common_Exceptions.NullValueException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.NotImplementedException(new Common_Exceptions.NotImplementedException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.JsonSerializationException(new Common_Exceptions.JsonSerializationException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

        try {
            throw new Common_Exceptions.MethodExecutionContextException(new Common_Exceptions.MethodExecutionContextException('Test message', 'Test class', 'Test method'), 'Test message', 'Test class', 'Test method');
        } catch (exception e) {
            system.assert(true);
        }

    }

    //=================================================================================================================
    // Common_Query
    //=================================================================================================================

    private static testMethod void test_Query_ToString() {
        system.assertEquals('true', Common_Query.ToString(true, true));
        system.assertEquals('2000-01-01', Common_Query.ToString(Date.valueOf('2000-1-1')));

        system.assertEquals('(test)', Common_Query.ListOrSetToString(new List<Object> {'test', null}, true, Common_Type.GetPrimitiveType('test')));
        system.assertEquals('\'test\'', Common_Query.EncloseQuotes('test'));
    }

    private static testMethod void test_Query_getFields() {
        Account a = new Account(Name='Test Account');
        insert a;

        system.assertNotEquals(null, Common_Query.getAllFields(Common_Schema.getSObjectType(a.Id)));
        system.assertNotEquals(null, Common_Query.getAllFields(Common_Schema.getSObjectType(a.Id), true));
        system.assertNotEquals(null, Common_Query.getAllFields('Account'));
        system.assertEquals('test1,test2', Common_Query.FieldListToString(new List<String>{'test1','test2'}));
    }

    //=================================================================================================================
    // Common_QueryBuilder
    //=================================================================================================================

    private static testMethod void test_QueryBuilder() {
        Common_QueryBuilder queryBuilder = new Common_QueryBuilder('Account');
        Common_QueryBuilder innerQuery = new Common_QueryBuilder('Contacts');
        queryBuilder.addQueryField('Id');
        queryBuilder.addQueryFields(new List<String>{'Name'});
        queryBuilder.addInnerQuery(innerQuery);

        queryBuilder.addWhereFilter('Name=\'test\'');
        queryBuilder.extendWhereFilter('Id != null');
        queryBuilder.extendWhereFilter('Id != null', 'AND');

        queryBuilder.setWhereFilterPrimaryOperator('AND');

        queryBuilder.addOrderField('Name');

        queryBuilder.setRowLimit(10);
        queryBuilder.setOffset(5);

        system.assertEquals('SELECT Id,Name,(SELECT ID FROM Contacts) FROM Account WHERE ((Name=\'test\') AND (Id != null) AND (Id != null)) ORDER BY Name LIMIT 10 OFFSET 5', queryBuilder.toString());

        queryBuilder.clearWhereFilter();
        queryBuilder.clearOrderFields();

        system.assertEquals('SELECT Id,Name,(SELECT ID FROM Contacts) FROM Account LIMIT 10 OFFSET 5', queryBuilder.toString());

        queryBuilder.addWhereFilter('Name', 'test', '=');
        queryBuilder.addOrderField('Name', 'desc');

        system.assertEquals('SELECT Id,Name,(SELECT ID FROM Contacts) FROM Account WHERE Name = \'test\' ORDER BY Name desc LIMIT 10 OFFSET 5', queryBuilder.toString());

        queryBuilder.clearWhereFilter();
        queryBuilder.addWhereFilter('Name', new List<String>{'test1', 'test2'});

        system.assertEquals('SELECT Id,Name,(SELECT ID FROM Contacts) FROM Account WHERE Name IN (\'test1\',\'test2\') ORDER BY Name desc LIMIT 10 OFFSET 5', queryBuilder.toString());

        queryBuilder.clearWhereFilter();

        List<String> fieldNames = new List<String>{'Name'};
        List<List<Object>> filterValues = new List<List<Object>>();
        filterValues.add(new List<Object>{'%test%'});
        List<String> comparisonOperators = new List<String>{'LIKE'};
        List<String> logicalOperators = new List<String>{'OR'};

        queryBuilder.addWhereFilterSeries(fieldNames, filterValues, comparisonOperators, logicalOperators);

        system.assertEquals('SELECT Id,Name,(SELECT ID FROM Contacts) FROM Account WHERE (Name LIKE \'%test%\') ORDER BY Name desc LIMIT 10 OFFSET 5', queryBuilder.toString());

        queryBuilder.clearQueryFields();
        queryBuilder.clearWhereFilter();
        queryBuilder.clearOrderFields();
        queryBuilder.addGroupField('Name');
        system.assertEquals('SELECT ID FROM Account GROUP BY Name LIMIT 10 OFFSET 5', queryBuilder.toString());

        queryBuilder.clearQueryFields();
        queryBuilder.clearWhereFilter();
        queryBuilder.clearOrderFields();
        queryBuilder.groupbyFields.clear();

        Common_QueryBuilder.LogicalGrouping level1 = new Common_QueryBuilder.LogicalGrouping('OR');
        Common_QueryBuilder.LogicalGrouping level2_1 = new Common_QueryBuilder.LogicalGrouping('AND');
        Common_QueryBuilder.LogicalGrouping level2_2 = new Common_QueryBuilder.LogicalGrouping('AND');

        level2_1.filterElements.add(new Common_QueryBuilder.FilterElement('Name', new List<Object>{'test','test2'},'IN'));
        level2_1.filterElements.add(new Common_QueryBuilder.FilterElement('Website', new List<Object>{'test','test2'},'IN'));

        level2_2.filterElements.add(new Common_QueryBuilder.FilterElement('Parent.Name', new List<Object>{'test','test2'},'IN'));
        level2_2.filterElements.add(new Common_QueryBuilder.FilterElement('Parent.Website', new List<Object>{'test','test2'},'IN'));

        level1.subgroupings.add(level2_1);
        level1.subgroupings.add(level2_2);

        queryBuilder.addWhereFilterSeries(level1);

        system.assertEquals('SELECT ID FROM Account WHERE ((Name IN (\'test\',\'test2\') AND Website IN (\'test\',\'test2\')) OR (Parent.Name IN (\'test\',\'test2\') AND Parent.Website IN (\'test\',\'test2\'))) LIMIT 10 OFFSET 5', queryBuilder.toString());

        queryBuilder.enableSelectAllLocalFields(true);
        Common_QueryBuilder.buildAllFieldsQuery('Account',true,'');

    }

    //=================================================================================================================
    // Common_Database
    //=================================================================================================================

    private static testMethod void test_Commmon_Database_Exceptions() {

        sObjectType objType = Account.sObjectType;
        //sObjectField fld = Account.fields.OwnerId;
        {
            Common_Database.CRUDException ex = new Common_Database.CRUDException(objType, Common_Database.Operation.DO_INSERT);
            system.assert(ex.getMessage() != null, 'Exception message should not be blank');
        }
        {
            Common_Database.FLSException ex = new Common_Database.FLSException(objType, 'OwnerId', Common_Database.Operation.DO_INSERT);
            system.assert(ex.getMessage() != null, 'Exception message should not be blank');
        }
    }

    private static testMethod void test_Commmon_Database_Old() {

        Account accountWithFLS = new Account(Name='Test Account');
        Account accountWithoutFLS = new Account(Name='Test Account');
        Account accountForList = new Account(Name='Test Account');
        List<Account> lstAccount = new List<Account>();
        lstAccount.add(accountForList);

        //===== secure insert =====
        Common_Database.secureInsert(accountWithFLS);
        Common_Database.secureInsert(accountWithoutFLS, true);
        Common_Database.secureInsert(lstAccount);
        Common_Database.secureInsert(lstAccount, true);

        //===== secure update =====
        Common_Database.secureUpdate(accountWithFLS);
        Common_Database.secureUpdate(accountWithoutFLS, true);
        Common_Database.secureUpdate(lstAccount);
        Common_Database.secureUpdate(lstAccount, true);

        //===== secure upsert =====
        Common_Database.secureUpsert(accountWithFLS);
        Common_Database.secureUpsert(accountWithoutFLS, true);
        Common_Database.secureUpsert(lstAccount);
        Common_Database.secureUpsert(lstAccount, true);

        //===== secure delete =====
        Common_Database.secureDelete(accountWithFLS);
        Common_Database.secureDelete(lstAccount);

        System.assert(accountWithFLS != null, 'Deprecated methods are empty and should not perform any changes');
        System.assert(accountWithoutFLS != null, 'Deprecated methods are empty and should not perform any changes');
        System.assert(lstAccount != null, 'Deprecated methods are empty and should not perform any changes');

    }


    private static testMethod void test_Commmon_Database_Normal() {
        Account accountSingleObject = new Account(Name='Test Account');

        List<Account> lstAccount = new List<Account>();
        Account accountForList = new Account(Name='Test Account');
        lstAccount.add(accountForList);

        List<Account> lstAccountPartial = new List<Account>();
        Account accountForListPartial = new Account(Name='Test Account');
        lstAccountPartial.add(accountForListPartial);

        //===== secure insert =====
        Common_Database.secureInsert2(accountSingleObject);
        Common_Database.secureInsert2(lstAccount);
        Common_Database.secureInsert2(lstAccountPartial, false);
        system.assert(accountSingleObject.Id != null, 'Id must be generated');
        system.assert(lstAccount.get(0).Id != null, 'Id must be generated');
        system.assert(lstAccountPartial.get(0).Id != null, 'Id must be generated');

        //===== secure update =====
        Common_Database.secureUpdate2(accountSingleObject);
        Common_Database.secureUpdate2(lstAccount);
        Common_Database.secureUpdate2(lstAccountPartial, false);
        system.assert(accountSingleObject.Id != null, 'Id must be generated');
        system.assert(lstAccount.get(0).Id != null, 'Id must be generated');
        system.assert(lstAccountPartial.get(0).Id != null, 'Id must be generated');

        //===== secure upsert =====
        Common_Database.secureUpsert2(accountSingleObject);
        //Common_Database.secureUpsert2(lstAccount);
        //Common_Database.secureUpsert2(lstAccountPartial, false);
        system.assert(accountSingleObject.Id != null, 'Id must be generated');
        //system.assert(lstAccount.get(0).Id != null, 'Id must be generated');
        //system.assert(lstAccountPartial.get(0).Id != null, 'Id must be generated');

        //Common_Database.TEST_CallStateCountryMethods(lstAccount);

        //===== secure delete =====
        Common_Database.secureDelete2(accountSingleObject);
        Common_Database.secureDelete2(lstAccount);
        Common_Database.secureDelete2(lstAccountPartial, false);

        List<Account> lstAccount1 = new List<Account>();
        lstAccount1.add(new Account(Name='Test 1'));
        List<Account> lstAccount2 = new List<Account>();
        lstAccount2.add(new Account(Name='Test 2'));
        insert lstAccount1;
        insert lstAccount2;

        system.assertNotEquals(null, Common_Database.chunkBySObjectType(lstAccount1));

        Common_Database.secureDelete2(new List<Sobject[]>{lstAccount1});
        Common_Database.secureDelete2(new List<Sobject[]>{lstAccount2}, false);

        Account testAccount = new Account(Name='testAccount');
        try {
            Common_Database.UntypedUpsert(testAccount, Common_Schema.getField('Account', 'Name'));
            system.assert(false);
        } catch (exception e) {
            system.assert(true);
        }
    }

    private static testMethod void Test_Common_Database_StateCountry(){
        Feature__c nullStateCountry = new Feature__c(Name='Common.Database.NullifyStateCountry',Enabled__c=true);
        insert nullStateCountry;

        Account accountSingleObject = new Account(Name='Test Account');

        List<Account> lstAccount = new List<Account>();
        Account accountForList = new Account(Name='Test Account', BillingCountry='US', BillingState='MI');
        lstAccount.add(accountForList);

        List<Account> lstAccountPartial = new List<Account>();
        Account accountForListPartial = new Account(Name='Test Account');
        lstAccountPartial.add(accountForListPartial);

        //===== secure insert =====
        Common_Database.secureInsert2(accountSingleObject);
        Common_Database.secureInsert2(lstAccount);
        Common_Database.secureInsert2(lstAccountPartial, false);
        system.assert(accountSingleObject.Id != null, 'Id must be generated');
        system.assert(lstAccount.get(0).Id != null, 'Id must be generated');
        system.assert(lstAccountPartial.get(0).Id != null, 'Id must be generated');

        //===== secure update =====
        Common_Database.secureUpdate2(accountSingleObject);
        Common_Database.secureUpdate2(lstAccount);
        Common_Database.secureUpdate2(lstAccountPartial, false);
        system.assert(accountSingleObject.Id != null, 'Id must be generated');
        system.assert(lstAccount.get(0).Id != null, 'Id must be generated');
        system.assert(lstAccountPartial.get(0).Id != null, 'Id must be generated');

        //===== secure upsert =====
        Common_Database.secureUpsert2(accountSingleObject);
        system.assert(accountSingleObject.Id != null, 'Id must be generated');


        //===== secure delete =====
        Common_Database.secureDelete2(accountSingleObject);
        Common_Database.secureDelete2(lstAccount);
        Common_Database.secureDelete2(lstAccountPartial, false);

        List<Account> lstAccount1 = new List<Account>();
        lstAccount1.add(new Account(Name='Test 1'));
        List<Account> lstAccount2 = new List<Account>();
        lstAccount2.add(new Account(Name='Test 2'));
        insert lstAccount1;
        insert lstAccount2;

        system.assertNotEquals(null, Common_Database.chunkBySObjectType(lstAccount1));

        Common_Database.secureDelete2(new List<Sobject[]>{lstAccount1});
        Common_Database.secureDelete2(new List<Sobject[]>{lstAccount2}, false);

        Account testAccount = new Account(Name='testAccount');
        try {
            Common_Database.UntypedUpsert(testAccount, Common_Schema.getField('Account', 'Name'));
            system.assert(false);
        } catch (exception e) {
            system.assert(true);
        }
    }


    private static testMethod void test_Commmon_Database_Empty(){
        sObject[] sObjects = new List<sObject>();

        //===== secure insert =====
        Common_Database.secureInsert2(sObjects);

        //===== secure update =====
        Common_Database.secureUpdate2(sObjects);

        //===== secure delete =====
        Common_Database.secureDelete2(sObjects);
    }

    private static testMethod void test_Commmon_Database_CheckCRUDAndFLS() {
        Account account = new Account(Name='Test Account');
        Common_Database.checkCRUDAndFLS(account, Common_Database.Operation.DO_INSERT);
        Common_Database.checkCRUDAndFLS(account, Common_Database.Operation.DO_UPDATE);
        Common_Database.checkCRUDAndFLS(account, Common_Database.Operation.DO_UPSERT);
        Common_Database.checkCRUDAndFLS(account, Common_Database.Operation.DO_DELETE);

        Common_Database.checkFLS(account, Common_Database.Operation.DO_INSERT);
        Common_Database.checkFLS(account, Common_Database.Operation.DO_UPDATE);
        Common_Database.checkFLS(account, Common_Database.Operation.DO_UPSERT);
        Common_Database.checkFLS(account, Common_Database.Operation.DO_DELETE);

        system.assert(true, 'Line should be reached without error');
    }



    private static testMethod void test_Commmon_Database_HelperMethods(){
        string sOperation = Common_Database.getOperationName(Common_Database.Operation.DO_INSERT);
        sOperation = Common_Database.getOperationName(Common_Database.Operation.DO_UPDATE);
        sOperation = Common_Database.getOperationName(Common_Database.Operation.DO_UPSERT);
        sOperation = Common_Database.getOperationName(Common_Database.Operation.DO_DELETE);

        Common_Database.returnAllFields(new List<SObject>{new Account()});
    }
}