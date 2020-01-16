@isTest(SeeAllData=false)
public with sharing class TEST_ManagePermission_Controller {
    private static final String NAMESPACE = '';

    @testSetup
    static void setupTest(){
        //Create PermissionConfig
        //Create SmartWidgets
        List<SmartWidget__c> smartWidgets = new List<SmartWidget__c>();

        SmartWidget__c relatedContacts = new SmartWidget__c();
        relatedContacts.Name = 'Permission_RelatedContacts_Contact';
        relatedContacts.AutoComplete_Target_Field__c = 'Name,Email';
        relatedContacts.AutoComplete_Target_Object__c = NAMESPACE+'Permission__c';
        relatedContacts.AutoComplete_Search_Object__c = 'Contact';
        relatedContacts.AutoComplete_Target_Parent_Field__c = 'AccountId';
        relatedContacts.Field__c = NAMESPACE+'Contact__c';
        relatedContacts.Filter__c = 'AccountId = \'parentId\'';
        relatedContacts.Label__c = 'Contacts';
        relatedContacts.Object__c = 'Contact';
        relatedContacts.Type__c = 'Multipicklist';
        smartWidgets.add(relatedContacts);
        insert relatedContacts;
        SmartWidget__c relatedInvestments = new SmartWidget__c();
        relatedInvestments.Name = 'Permission_RelatedCommitment';
        relatedInvestments.AutoComplete_Search_Object__c = NAMESPACE+'Finaccount__c';
        //relatedInvestments.AutoComplete_Related_Field__c = NAMESPACE+'Account_Vehicle__r.Name,'+NAMESPACE+'Fund__r.Name';
        relatedInvestments.AutoComplete_Target_Object__c = NAMESPACE+'Permission__c';
        relatedInvestments.AutoComplete_Target_Parent_Field__c = NAMESPACE+'Account__c';
        relatedInvestments.Field__c = NAMESPACE+'Finaccount__c';
        relatedInvestments.Filter__c = NAMESPACE+'Account__c = \'parentId\'';
        relatedInvestments.Label__c = 'Investment';
        relatedInvestments.Object__c = NAMESPACE+'Finaccount__c';
        relatedInvestments.Type__c = 'Multipicklist';
        smartWidgets.add(relatedInvestments);
        insert relatedInvestments;

        //Create permission types
        List<Permission_Type__c> permissionTypes = new List<Permission_Type__c>();
        Permission_Type__c dist = new Permission_Type__c();
        dist.Name = 'Distribution';
        dist.Default_Active__c = true;
        dist.Default_Alert__c = false;
        permissionTypes.add(dist);

        Permission_Type__c legal = new Permission_Type__c();
        legal.Name = 'Legal';
        legal.Default_Active__c = false;
        legal.Default_Alert__c = false;
        permissionTypes.add(legal);

        Permission_Type__c dm = new Permission_Type__c();
        dm.name = 'DM';
        DM.Default_Active__c = false;
        DM.Default_Alert__c = false;
        permissionTypes.add(dm);

        Permission_Type__c cp = new Permission_Type__c();
        cp.Name = 'CP';
        cp.Default_Active__c = true;
        cp.Default_Alert__c = true;
        permissionTypes.add(cp);

        Permission_Type__c so = new Permission_Type__c();
        so.Name = 'SO';
        so.Default_Active__c = false;
        so.Default_Alert__c = false;
        permissionTypes.add(so);

        insert permissionTypes;
        //Create account
        List<Account> accounts = new List<Account>();

        Account acme = new Account();
        acme.Name = 'Acme';
        Accounts.add(acme);

        insert Accounts;

        //Create Contact
        List<Contact> contacts = new List<Contact>();
        Contact Bob = new Contact();
        Bob.FirstName = 'Bob';
        Bob.LastName = 'TestingPermissionInit';
        Bob.AccountId = acme.Id;
        contacts.add(bob);
        insert contacts;
        //Create Fund
//        List<Investment_Vehicle__c> funds = new List<Investment_Vehicle__c>();
        Investment_Vehicle__c fun = new Investment_Vehicle__c();
        fun.Name = 'Test FUN';
        insert fun;
//        insert funds;
        //Create Investment
        Finaccount__c fin = new Finaccount__c();
        fin.Account__c = acme.Id;
        fin.Investment_Vehicle__c = fun.Id;
        insert fin;

    }

    @isTest
    static void testInit(){
//        setupTest();
        Map<String,String> params = new Map<String, String>();
        params.put('configurationName','PermissionManager_Contact_Alerts');

        Contact contactRecord = [SELECT Id FROM Contact WHERE LastName='TestingPermissionInit' LIMIT 1];
        Id recordId = contactRecord.Id;
        params.put('recordId',recordId);

        Map<String,String> initResponse = ManagePermission_Controller.initializeComponent(params);
        system.debug('Init Response: '+initResponse);
    }
    @isTest
    static void testSave(){
        Map<String,String> params = new Map<String, String>();
        params.put('configurationName','PermissionManager_Contact_Alerts');

        Contact contactRecord = [SELECT Id FROM Contact WHERE LastName='TestingPermissionInit' LIMIT 1];
        Id recordId = contactRecord.Id;
        params.put('recordId',recordId);
        //params.put('defaultedPermissionTypes',);

        Map<String,String> initResponse = ManagePermission_Controller.initializeComponent(params);


        params = new Map<String,String>();
        List<Permission__c> permissions = new List<Permission__c>();

        String permissionJSON;
        Permission__c p = new Permission__c();
        p.Contact__c = [SELECT Id FROM Contact WHERE LastName='TestingPermissionInit' LIMIT 1].Id;
        p.Status__c = 'Active';
        p.Permission_Type__c = [SELECT Id FROM Permission_Type__c WHERE Name = 'Legal' LIMIT 1].Id;
        p.Fund__c = [SELECT Id FROM Investment_Vehicle__c LIMIT 1].Id;
        permissions.add(p);

        permissionJSON = JSON.serialize(permissions);


        params.put('pmsListJSON',permissionJSON);
        params.put('configJSON', initResponse.get('config'));
        params.put('widgetsJSON', initResponse.get('widgets'));
        Map<String,String> saveResponse = ManagePermission_Controller.savePermissionTable(params);
        system.debug('Save Response: '+saveResponse);
    }
    @isTest
    static void testRestrictedUser(){

    }
}