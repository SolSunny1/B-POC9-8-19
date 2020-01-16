@isTest(SeeAllData=false)
private with sharing class TEST_RelatedMultiSelect_V2_Controller {
    private static final String NAMESPACE = '';

    @testSetup
    static void setupTest(){
        //Create PermissionConfig
        //Create SmartWidgets
        List<SmartWidget__c> smartWidgets = new List<SmartWidget__c>();

        SmartWidget__c relatedContacts = new SmartWidget__c();
        relatedContacts.Name = 'PermissionExample_RelatedContacts';
        relatedContacts.AutoComplete_Target_Field__c = 'Name,Email';
        relatedContacts.AutoComplete_Target_Object__c = NAMESPACE+'Permission__c';
        relatedContacts.AutoComplete_Search_Object__c = 'Contact';
        relatedContacts.AutoComplete_Target_Parent_Field__c = 'AccountId';
        relatedContacts.Field__c = NAMESPACE+'Contact__c';
        relatedContacts.Filter__c = 'AccountId = \'parentId\' AND Account.NAME IN (\'securityGroups\')';
        relatedContacts.AutoComplete_Search_Filter__c = 'Account.NAME IN (\'securityGroups\')';
        relatedContacts.Label__c = 'Contacts';
        relatedContacts.Object__c = 'Contact';
        relatedContacts.Type__c = 'Multipicklist';
        smartWidgets.add(relatedContacts);
        insert relatedContacts;
        SmartWidget__c relatedInvestments = new SmartWidget__c();
        relatedInvestments.Name = 'PermissionExample_RelatedInvestment';
        relatedInvestments.AutoComplete_Search_Object__c = NAMESPACE+'Finaccount__c';
        relatedInvestments.AutoComplete_Related_Field__c = NAMESPACE+'Account_Vehicle__r.Name,'+NAMESPACE+'Fund__r.Name,'+NAMESPACE+'Fund__r.Migration_Source__c';
        relatedInvestments.AutoComplete_Target_Object__c = NAMESPACE+'Permission__c';
        relatedInvestments.AutoComplete_Target_Parent_Field__c = NAMESPACE+'Account__c';
        relatedInvestments.Field__c = NAMESPACE+'Investment__c';
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
        Bob.LastName = 'TestingRelatedSelect';
        Bob.AccountId = acme.Id;
        contacts.add(bob);
        insert contacts;
        //Create Fund
//        List<Investment_Vehicle__c> funds = new List<Investment_Vehicle__c>();
        Investment_Vehicle__c f = new Investment_Vehicle__c();
        f.Name = 'Test FUN';
        insert f;
//        insert funds;
        //Create Investment
        Finaccount__c fin = new Finaccount__c();
        fin.Account__c = acme.Id;
        fin.Investment_Vehicle__c = f.Id;
        insert fin;
    }

    @IsTest
    static void testQuery(){
        SmartWidget__c widget = [SELECT Id,
            AutoComplete_Target_Field__c,
            AutoComplete_Target_Object__c,
            AutoComplete_Search_Object__c,
            AutoComplete_Target_Parent_Field__c,
            Field__c,
            Filter__c,
            Label__c,
            Object__c,
            Type__c
        FROM SmartWidget__c
        WHERE Name='PermissionExample_RelatedContacts' LIMIT 1];
        String parentID = [SELECT Id FROM Account WHERE Name='Acme'].Id;
        String childId = [select id from Contact where Name='Bob TestingRelatedSelect'].Id;

        List<String> secValues = new List<String>();
        secValues.add('Acme');
        RelatedMultiSelect_V2_Controller.queryRecordsFromWidget(JSON.serialize(widget),parentId,childId, false, secValues, new List<String>(), 'add');
    }
    @IsTest
    static void testSearch(){
        SmartWidget__c widget = [SELECT Id,
            AutoComplete_Target_Field__c,
            AutoComplete_Target_Object__c,
            AutoComplete_Search_Object__c,
            AutoComplete_Target_Parent_Field__c,
            AutoComplete_Search_Filter__c,
            Field__c,
            Filter__c,
            Label__c,
            Object__c,
            Type__c
        FROM SmartWidget__c
        WHERE Name='PermissionExample_RelatedContacts' LIMIT 1];

        String searchText = 'Bob';
        List<String> secValues = new List<String>();
        secValues.add('Acme');
        RelatedMultiSelect_V2_Controller.search(JSON.serialize(widget),searchText,false, secValues);
    }
}