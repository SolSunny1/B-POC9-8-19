@isTest(SeeAllData=false)
private with sharing class TEST_PermissionEdit_Controller {
    private static final String NAMESPACE = '';

    @testSetup
    static void setupTest(){


        List<SmartWidget__c> smartWidgets = new List<SmartWidget__c>();
        smartWidgets.add(new SmartWidget__c(
            Name = 'Template_PT_Fund',
            AutoComplete_Search_Object__c = 'Fund__c',
            AutoComplete_Search_Fields__c = 'Name',
            AutoComplete_Related_Field__c = 'Name',
            AutoComplete_Target_Field__c = 'Name',
            AutoComplete_Target_Object__c = 'Permission__c',
            AutoComplete_Target_Parent_Field__c = 'Account__c',
            Field__c = 'Fund__c',
            Filter__c = 'Id IN (SELECT Fund__c FROM Finaccount__c WHERE Account__c = \'parentId\')',
            Label__c = 'Fund',
            Object__c = 'Fund__c',
            Type__c = 'Multipicklist'
        ));
        smartWidgets.add(new SmartWidget__c(
            Name = 'Template_PT_AccountVehicle',
            AutoComplete_Search_Object__c = 'Account_Vehicle__c',
            AutoComplete_Search_Fields__c = 'Name',
            AutoComplete_Related_Field__c = 'Name',
            AutoComplete_Target_Field__c = 'Name',
            AutoComplete_Target_Object__c = 'Permission__c',
            AutoComplete_Target_Parent_Field__c = 'Account__c',
            Field__c = 'Account_Vehicle__c',
            Filter__c = 'Account__c = \'parentId\'',
            Label__c = 'Account Vehicle',
            Object__c = 'Account_Vehicle__c',
            Type__c = 'Multipicklist'
        ));
        smartWidgets.add(new SmartWidget__c(
            Name = 'Permission_RelatedContacts',
            AutoComplete_Search_Object__c = 'Contact',
            AutoComplete_Search_Fields__c = 'Name',
            AutoComplete_Related_Field__c = 'Name',
            AutoComplete_Target_Field__c = 'Name',
            AutoComplete_Target_Object__c = 'Permission__c',
            AutoComplete_Target_Parent_Field__c = 'AccountId',
            Field__c = 'Contact__c',
            Filter__c = 'Id = \'childId\'',
            Label__c = 'Contact',
            Object__c = 'Contact',
            Type__c = 'Multipicklist'
        ));
        smartWidgets.add(new SmartWidget__c(
            Name = 'Permission_RelatedCommitment',
            AutoComplete_Search_Object__c = 'Finaccount__c',
            AutoComplete_Search_Fields__c = 'Name',
            AutoComplete_Related_Field__c = 'Name',
            AutoComplete_Target_Field__c = 'Name',
            AutoComplete_Target_Object__c = 'Permission__c',
            AutoComplete_Target_Parent_Field__c = 'Account__c',
            Field__c = 'Finaccount__c',
            Filter__c = 'Account__c = \'parentId\'',
            Label__c = 'Investment',
            Object__c = 'Finaccount__c',
            Type__c = 'Multipicklist'
        ));
        insert smartWidgets;

        List<Permission_Type__c> ptList = new List<Permission_Type__c>();
        for (Integer i = 0; i < 5; i++) {
            ptList.add(new Permission_Type__c(
                Name = 'Permission Type ' + i,
                Default_Active__c = true,
                Default_Alert__c = true,
                Order__c = (i + 1)
            ));
        }
        insert ptList;

        //Create account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            testContacts.add(new Contact(
                FirstName = 'TestFN' + i, LastName = 'TestLN' + i,
                AccountId = testAccount.Id
            ));
        }
        insert testContacts;

        List<Account_Vehicle__c> testAccountVehicles = new List<Account_Vehicle__c>();
        for (Integer i = 0; i < 10; i++) {
            testAccountVehicles.add(new Account_Vehicle__c(
                Name = 'Test Account Vehicle ' + i,
                Account__c = testAccount.Id
            ));
        }
        insert testAccountVehicles;

        List<Investment_Vehicle__c> testFunds = new List<Investment_Vehicle__c>();
        for (Integer i = 0; i < testContacts.size(); i++) {
            testFunds.add(new Investment_Vehicle__c(
                Name = 'Test Fund ' + i
            ));
        }
        insert testFunds;

        List<Finaccount__c> testFinaccounts = new List<Finaccount__c>();
        for (Integer i = 0; i < testFunds.size(); i++) {
            testFinaccounts.add(new Finaccount__c(
                Investment_Vehicle__c = testFunds[i].Id,
                Account__c = testAccount.Id,
                Account_Vehicle__c = testAccountVehicles[i].Id
            ));
        }
        insert testFinaccounts;
    }

    @isTest
    static void initializeComponent() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Map<String,String> params = new Map<String, String>();
        params.put('configurationName', 'PermissionManager_Account_Alerts');
        params.put('recordId', testAccount.Id);

        Test.startTest();
        Map<String,String> response = PermissionEdit_Controller.initializeComponent_EditMode(params);
        params.put('config', response.get('config'));
        params.put('widgets', response.get('widgets'));
        params.put('parentRecordId', response.get('parentRecordId'));
        response = PermissionEdit_Controller.initializeComponent_RelatedRecords(params);
        Test.stopTest();
    }

    @isTest
    static void initializeComponent_AddMode() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Map<String,String> params = new Map<String, String>();
        params.put('configurationName', 'PermissionManager_Account_Alerts');
        params.put('recordId', testAccount.Id);

        Test.startTest();
        Map<String,String> response = PermissionEdit_Controller.initializeComponent_EditMode(params);
        params.put('config', response.get('config'));
        params.put('widgets', response.get('widgets'));
        params.put('parentRecordId', response.get('parentRecordId'));
        response = PermissionEdit_Controller.initializeComponent_RelatedRecords(params);
        Test.stopTest();
    }

    @isTest
    static void insertNewPermissions() {
        Map<String,String> params = new Map<String, String>();
        List<String> pmsFieldNames = new List<String>();
        pmsFieldNames.add('Contact__c');
        pmsFieldNames.add('Investment__c');
        pmsFieldNames.add('Account_Vehicle__c');
        pmsFieldNames.add('Fund__c');
        params.put('pmsFieldNamesJSON', JSON.serialize(pmsFieldNames));

        List<Permission_Type__c> testTypes = [SELECT Id FROM Permission_Type__c];
        List<Contact> testContacts = [SELECT Id FROM Contact LIMIT 10];
        List<Investment_Vehicle__c> testFunds = [SELECT Id FROM Investment_Vehicle__c LIMIT 10];
        List<Account_Vehicle__c> testAccountVehicles = [SELECT Id FROM Account_Vehicle__c LIMIT 10];
        List<Finaccount__c> testFinaccounts = [SELECT Id FROM Finaccount__c LIMIT 10];

        List<Permission__c> testPermissions = new List<Permission__c>();
        for (Integer i = 0; i < 10; i++) {
            for (Integer j = 0; j < testTypes.size(); j++) {
                testPermissions.add(new Permission__c(
                    Contact__c = testContacts[i].Id,
                    //Investment__c = testFinaccounts[i].Id,
                    Account_Vehicle__c = testAccountVehicles[i].Id,
                    Fund__c = testFunds[i].Id,
                    Permission_Type__c = testTypes[j].Id
                ));
            }
        }
        params.put('pmsListJSON', JSON.serialize(testPermissions));

        List<Permission__c> existingPermissions = new List<Permission__c>();
        for (Integer i = 0; i < testPermissions.size()/2; i++) {
            existingPermissions.add(testPermissions[i]);
        }
        insert existingPermissions;

        Test.startTest();
        Map<String,String> response = PermissionEdit_Controller.insertNewPermissions(params);
        Test.stopTest();
    }

    @isTest
    static void savePermissionTable() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Map<String,String> params = new Map<String, String>();
        params.put('configurationName', 'PermissionManager_Account_Alerts');
        params.put('recordId', testAccount.Id);
        Map<String,String> response = PermissionEdit_Controller.initializeComponent_EditMode(params);

        params = new Map<String, String>();
        params.put('config', response.get('config'));
        params.put('widgets', response.get('widgets'));
        params.put('parentRecordId', response.get('parentRecordId'));
        params.put('childId', testAccount.Id);

        Map<String,List<String>> selectedIdMap = new Map<String,List<String>>();
        List<SmartWidget__c> widgets = (List<SmartWidget__c>)JSON.deserialize(response.get('widgets'), List<SmartWidget__c>.class);
        for (Integer i = 0; i < widgets.size(); i++) {
            selectedIdMap.put(widgets[i].Id, new List<String>());
        }

        List<Permission_Type__c> testTypes = [SELECT Id FROM Permission_Type__c];
        List<Contact> testContacts = [SELECT Id, Name FROM Contact LIMIT 10];
        List<Investment_Vehicle__c> testFunds = [SELECT Id, Name FROM Investment_Vehicle__c LIMIT 10];
        List<Account_Vehicle__c> testAccountVehicles = [SELECT Id, Name FROM Account_Vehicle__c LIMIT 10];
        List<Finaccount__c> testFinaccounts = [SELECT Id, Name FROM Finaccount__c LIMIT 10];

        List<Permission__c> insertPermissions = new List<Permission__c>();
        for (Integer i = 0; i < 5; i++) {
            for (Integer j = 0; j < testTypes.size(); j++) {
                insertPermissions.add(new Permission__c(
                    Contact__c = testContacts[i].Id,
                    //Investment__c = testFinaccounts[i].Id,
                    Account_Vehicle__c = testAccountVehicles[i].Id,
                    Fund__c = testFunds[i].Id,
                    Permission_Type__c = testTypes[j].Id
                ));
            }
            selectedIdMap.get(widgets[0].Id).add(testContacts[i].Id);
            selectedIdMap.get(widgets[1].Id).add(testFinaccounts[i].Id);
        }
        params.put('insertPmsList', JSON.serialize(insertPermissions));

        List<Permission__c> updatePermissions = new List<Permission__c>();
        for (Integer i = 5; i < 10; i++) {
            for (Integer j = 0; j < testTypes.size(); j++) {
                updatePermissions.add(new Permission__c(
                    Contact__c = testContacts[i].Id,
                    //Investment__c = testFinaccounts[i].Id,
                    Account_Vehicle__c = testAccountVehicles[i].Id,
                    Fund__c = testFunds[i].Id,
                    Permission_Type__c = testTypes[j].Id
                ));
            }
            selectedIdMap.get(widgets[0].Id).add(testContacts[i].Id);
            selectedIdMap.get(widgets[1].Id).add(testFinaccounts[i].Id);
        }
        insert updatePermissions;
        params.put('updatePmsList', JSON.serialize(updatePermissions));

        params.put('selectedIdMap', JSON.serialize(selectedIdMap));
        List<String> lowerBound = new List<String>();
        lowerBound.add(testContacts[0].Name);
        lowerBound.add(testFinaccounts[0].Name);
        lowerBound.add(testAccountVehicles[0].Name);
        lowerBound.add(testFunds[0].Name);
        params.put('lowerBound', JSON.serialize(lowerBound));

        Test.startTest();
        response = PermissionEdit_Controller.savePermissionTable(params);
        Test.stopTest();
    }
}