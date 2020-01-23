@isTest
private class TEST_Common_Schema {
    @isTest static void Test_GlobalDescribe(){
        Test.startTest();
        Common_Schema.getGlobalDescribeMap();
        Common_Schema.getAllObjects();
        Test.stopTest();
    }

    @isTest static void Test_Namespace(){
        Schema.SobjectType accountType = Common_Schema.getSObjectType('Account');

        Test.startTest();
        System.assertEquals('FakeObject__c',Common_Schema.getLocalName('Namespace__FakeObject__c'));
        System.assertEquals('FakeField__c',Common_Schema.removeNamespace('Namespace__FakeField__c'));
        Test.stopTest();
    }

    @isTest static void Test_CustomSettings(){
        Test.startTest();
        Map<String, String> settingLables = Common_Schema.getAllCustomSettings();
        System.assertNotEquals(0,settingLables.size());
        Test.stopTest();
    }

    @isTest static void Test_SobjectType(){
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;

        Test.startTest();
        Common_Schema.getSObjectType(testAccount.Id);
        system.assertEquals(Schema.getGlobalDescribe().get('Account'), Common_Schema.getSObjectType('Account'));
        Common_Schema.getDescribeObject('User');
        Common_Schema.getDescribe('User');

        try {
            system.assertNotEquals(null, Common_Schema.getDescribeObject('CT_GG__Account__c'));
            system.assert(false);
        } catch (exception e) {
            system.assert(true);
        }

        String userObjectName = Common_Schema.getObjectNameFromId(testAccount.Id);
        system.assertEquals('Account',userObjectName);

        userObjectName = Common_Schema.getObjectNameFromSObject(new User());
        system.assertEquals('User',userObjectName);
        Test.stopTest();
    }

    @isTest static void Test_SObjectField(){
        Test.startTest();
        Common_Schema.getDescribeFields(Contact.SObjectType);
        String contactNameField = Common_Schema.getNameField(Contact.SObjectType);
        System.assertEquals('Name',contactNameField);
        String printablePath = Common_Schema.getPrintableRelationshipPath('Contact', 'AccountId');
        System.assertEquals('Account.Name',printablePath);
        Common_Schema.getCreatableFields('Account');
        Common_Schema.getFieldsByType('Contact',Schema.DisplayType.REFERENCE);
        Common_Schema.getField('Contact','Name');
        Test.stopTest();
    }

    @isTest static void Test_SobjectFieldType(){
        Test.startTest();
        Schema.DisplayType accountNameFieldType = Common_Schema.getFieldDisplayType('Account', 'Name');
        System.assertEquals(Schema.DisplayType.STRING,accountNameFieldType);

        try {
            Common_Schema.getFieldDisplayType('Account', 'TestException');
            system.assert(false);
        } catch (exception e) {
            system.assert(true);
        }

        Common_Schema.getFieldType('Account','Name');
        Common_Schema.getFieldTypes('Account',new List<String>{'Name','Industry'});
        Test.stopTest();
    }

    @isTest static void Test_RecordTypes(){
        Test.startTest();
        Common_Schema.getRecordTypes('Account');
        List<Schema.RecordTypeInfo> rtInfo = Common_Schema.getAvailableRecordTypes(Account.SObjectType);
        System.assertNotEquals(0, rtInfo.size());
        Test.stopTest();
    }

    //This will be commented out during deployments, but is mainly used to check for performance drag when creating new schema methods
    //private static Map<String, Long> runTimes = new Map<String,Long>();
    //private static Long deltaTime = 0;

    //@isTest static void Test_Performance(){
    //	Schema.SobjectType accountType = Schema.getGlobalDescribe().get('Account');
    //	Account testAccount = new Account(Name='Test Account');
    //	insert testAccount;

    //	Test.startTest();
    //		//Test_GlobalDescribe
    //		setDeltaTime();
    //		Common_Schema.getGlobalDescribeMap();
    //		Common_Schema.getAllObjects();
    //		storeDeltaTime('Test_GlobalDescribe');

    //		//Test_Namespace
    //		setDeltaTime();
    //		Common_Schema.getLocalName('Namespace__FakeObject__c');
    //		Common_Schema.removeNamespace('Namespace__FakeField__c');
    //		storeDeltaTime('Test_Namespace');

    //		//Test_CustomSettings
    //		setDeltaTime();
    //		Common_Schema.getAllCustomSettings();
    //		storeDeltaTime('Test_CustomSettings');

    //		//Test_SObjectType
    //		setDeltaTime();
    //		Common_Schema.getSObjectType(testAccount.Id);
    //		Common_Schema.getSObjectType('User');
    //		Common_Schema.getDescribeObject('User');
    //		Common_Schema.getDescribe('User');
    //		Common_Schema.getObjectNameFromId(testAccount.Id);
    //		Common_Schema.getObjectNameFromSObject(new User());
    //		storeDeltaTime('Test_SObjectType');

    //		//Test_SObjectField
    //		setDeltaTime();
    //		Common_Schema.getDescribeFields(Contact.SObjectType);
    //		Common_Schema.getNameField(Contact.SObjectType);
    //		Common_Schema.getPrintableRelationshipPath('Contact', 'AccountId');
    //		Common_Schema.getCreatableFields('Account');
    //		Common_Schema.getFieldsByType('Contact',Schema.DisplayType.REFERENCE);
    //		Common_Schema.getField('Contact','Name');
    //		storeDeltaTime('Test_SObjectField');

    //		//Test_SObjectFieldType
    //		setDeltaTime();
    //		Common_Schema.getFieldDisplayType('Account', 'Name');
    //		Common_Schema.getFieldType('Account','Name');
    //		Common_Schema.getFieldTypes('Account',new List<String>{'Name','Industry'});
    //		storeDeltaTime('Test_SObjectFieldType');

    //		//Test_RecordTypes
    //		setDeltaTime();
    //		Common_Schema.getRecordTypes('Account');
    //		Common_Schema.getAvailableRecordTypes(Account.SObjectType);
    //		storeDeltaTime('Test_RecordTypes');

    //		//Test_DependentPicklists
    //		setDeltaTime();
    //		Common_Schema.getDependentOptions('Account', 'Industry', 'Type');
    //		storeDeltaTime('Test_DependentPicklists');
    //	Test.stopTest();

    //	system.debug(JSON.serialize(runTimes));
    //}

    //@isTest static void Test_PerformanceMulti(){
    //	Schema.SobjectType accountType = Schema.getGlobalDescribe().get('Account');
    //	Account testAccount = new Account(Name='Test Account');
    //	insert testAccount;

    //	Test.startTest();
    //		for(Integer i=0;i<3;i++){
    //			//Test_GlobalDescribe
    //			setDeltaTime();
    //			Common_Schema.getGlobalDescribeMap();
    //			Common_Schema.getAllObjects();
    //			storeDeltaTime('Test_GlobalDescribe');

    //			//Test_Namespace
    //			setDeltaTime();
    //			Common_Schema.getLocalName('Namespace__FakeObject__c');
    //			Common_Schema.removeNamespace('Namespace__FakeField__c');
    //			storeDeltaTime('Test_Namespace');

    //			//Test_CustomSettings
    //			setDeltaTime();
    //			Common_Schema.getAllCustomSettings();
    //			storeDeltaTime('Test_CustomSettings');

    //			//Test_SObjectType
    //			setDeltaTime();
    //			Common_Schema.getSObjectType(testAccount.Id);
    //			Common_Schema.getSObjectType('User');
    //			Common_Schema.getDescribeObject('User');
    //			Common_Schema.getDescribe('User');
    //			Common_Schema.getObjectNameFromId(testAccount.Id);
    //			Common_Schema.getObjectNameFromSObject(new User());
    //			storeDeltaTime('Test_SObjectType');

    //			//Test_SObjectField
    //			setDeltaTime();
    //			Common_Schema.getDescribeFields(Contact.SObjectType);
    //			Common_Schema.getNameField(Contact.SObjectType);
    //			Common_Schema.getPrintableRelationshipPath('Contact', 'AccountId');
    //			Common_Schema.getCreatableFields('Account');
    //			Common_Schema.getFieldsByType('Contact',Schema.DisplayType.REFERENCE);
    //			Common_Schema.getField('Contact','Name');
    //			storeDeltaTime('Test_SObjectField');

    //			//Test_SObjectFieldType
    //			setDeltaTime();
    //			Common_Schema.getFieldDisplayType('Account', 'Name');
    //			Common_Schema.getFieldType('Account','Name');
    //			Common_Schema.getFieldTypes('Account',new List<String>{'Name','Industry'});
    //			storeDeltaTime('Test_SObjectFieldType');

    //			//Test_RecordTypes
    //			setDeltaTime();
    //			Common_Schema.getRecordTypes('Account');
    //			Common_Schema.getAvailableRecordTypes(Account.SObjectType);
    //			storeDeltaTime('Test_RecordTypes');

    //			//Test_DependentPicklists
    //			setDeltaTime();
    //			Common_Schema.getDependentOptions('Account', 'Industry', 'Type');
    //			storeDeltaTime('Test_DependentPicklists');
    //		}
    //	Test.stopTest();

    //	system.debug(JSON.serialize(runTimes));
    //}

    //private static void setDeltaTime(){
    //	deltaTime = System.now().getTime();
    //}

    //private static void storeDeltaTime(String breakpointSectionName){
    //	if(runTimes.containsKey(breakpointSectionName)){
    //		runTimes.put(breakpointSectionName, (System.now().getTime() - deltaTime)+runTimes.get(breakpointSectionName));
    //	} else{
    //		runTimes.put(breakpointSectionName, System.now().getTime() - deltaTime);
    //	}

    //}
}