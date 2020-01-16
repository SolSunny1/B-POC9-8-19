@isTest(SeeAllData=false)
private with sharing class TEST_Trigger_RollUp {
    static testMethod void Test_Trigger_Rollup_MaxMin() {
        Trigger_Rollup_Rule__c customSetting = new Trigger_Rollup_Rule__c();
        customSetting.Name = 'Test Max Min Rollup';
        customSetting.Object__c = 'Account';
        customSetting.Child_Object__c = 'Opportunity';
        customSetting.Child_Field__c = 'Amount';
        customSetting.Child_Parent_Field__c = 'AccountId';
        customSetting.Field__c = 'Description';
        customSetting.Type__c = 'Max';
        customSetting.Child_Query_Group__c = 'Amount';
        customSetting.Child_Query_Where_Clause__c = 'StageName=\'test\'';
        insert customSetting;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Investment_Vehicle__c inv = new Investment_Vehicle__c(Name='Test Invesment Vehicle');
        insert inv;

        List<Opportunity> testProjects = new List<Opportunity>();
        testProjects.add(new Opportunity(Name = 'Project 1', Amount = 2000, AccountId = testAccount.Id, Investment_Vehicle__c=inv.Id, StageName='test', CloseDate=System.today()));
        testProjects.add(new Opportunity(Name = 'Project 2', Amount = 3000, AccountId = testAccount.Id, Investment_Vehicle__c=inv.Id, StageName='test', CloseDate=System.today()));

        Test.startTest();
        insert testProjects;
        testAccount.Description = 'Hello World';
        update testAccount;

        testAccount = [SELECT Id, Description FROM Account WHERE Id = :testAccount.Id];
        System.assertNotEquals(null, testAccount.Description);
        Test.stopTest();
    }

    static testMethod void Test_Trigger_Rollup_Lookup() {
        Trigger_Rollup_Rule__c customSetting = new Trigger_Rollup_Rule__c();
        customSetting.Name = 'Project TeamMember';
        customSetting.Object__c = 'Account';
        customSetting.Child_Object__c = 'Contact';
        customSetting.Child_Field__c = 'Account.Name';
        customSetting.Child_Parent_Field__c = 'AccountId';
        customSetting.Field__c = 'Description';
        customSetting.Field_RTF__c = 'SicDesc';
        customSetting.DelimitedList_Delimiter__c = 'testDelimiter';
        customSetting.Type__c = 'DelimitedList';

        insert customSetting;

        Account account1 = new Account();
        account1.Name = 'Test Account';
        insert account1;

        Contact contact1 = new Contact();
        contact1.FirstName = 'Test';
        contact1.LastName = 'Contact';
        contact1.AccountId = account1.Id;
        insert contact1;

        update account1;

        Account updatedAccount = [select Id, Description, SicDesc from Account where Id=:account1.Id limit 1];
        system.assertEquals('Test Account', updatedAccount.Description);
        system.debug('Log 1: ' + updatedAccount.Description);
        system.debug('Log 2: ' + updatedAccount.SicDesc);

        Contact contact2 = new Contact();
        contact2.FirstName = 'Test2';
        contact2.LastName = 'NewContact';
        contact2.AccountId = account1.Id;
        insert contact2;

        update account1;

        updatedAccount = [select Id, Description, SicDesc from Account where Id=:account1.Id limit 1];
        system.debug('Log 3: ' + updatedAccount.Description);
        system.debug('Log 4: ' + updatedAccount.SicDesc);
    }

    static testMethod void Test_Trigger_Rollup_NoLookup() {
        Trigger_Rollup_Rule__c customSetting = new Trigger_Rollup_Rule__c();
        customSetting.Name = 'Project TeamMember';
        customSetting.Object__c = 'Account';
        customSetting.Child_Object__c = 'Contact';
        customSetting.Child_Field__c = 'Id';
        customSetting.Child_Parent_Field__c = 'AccountId';
        customSetting.Field__c = 'Description';
        customSetting.Field_RTF__c = 'SicDesc';
        customSetting.DelimitedList_Delimiter__c = 'testDelimiter';
        customSetting.Type__c = 'DelimitedList';
        customSetting.Unique_Values__c = true;

        insert customSetting;

        Account account1 = new Account();
        account1.Name = 'Test Account';
        insert account1;

        Test.startTest();
        Contact contact1 = new Contact();
        contact1.FirstName = 'Test';
        contact1.LastName = 'Contact';
        contact1.AccountId = account1.Id;
        insert contact1;

        update account1;

        Account updatedAccount = [select Id, Description, SicDesc from Account where Id=:account1.Id limit 1];
        system.assertEquals(contact1.Id, updatedAccount.Description);
        system.debug('Log 1: ' + updatedAccount.Description);
        system.debug('Log 2: ' + updatedAccount.SicDesc);

        Contact contact2 = new Contact();
        contact2.FirstName = 'Test2';
        contact2.LastName = 'NewContact';
        contact2.AccountId = account1.Id;
        insert contact2;

        update account1;

        Test.stopTest();

        updatedAccount = [select Id, Description, SicDesc from Account where Id=:account1.Id limit 1];
        system.debug('Log 3: ' + updatedAccount.Description);
        system.debug('Log 4: ' + updatedAccount.SicDesc);
    }

    static testMethod void Test_Trigger_Rollup_NumberRollup() {
        Trigger_Rollup_Rule__c customSetting = new Trigger_Rollup_Rule__c();
        customSetting.Name = 'Account Vehicle - Total Finaccount Am';
        customSetting.Object__c = 'Account';
        customSetting.Child_Object__c = 'Investor_Position__c';
        customSetting.Child_Field__c = 'AUM_Number__c';
        customSetting.Child_Parent_Field__c = 'Investor_Position_Account__c';
        customSetting.Field__c = 'Asset_Lending__c';
        customSetting.Type__c = 'NumberRollup';
        customSetting.Number_Rollup_Type__c = 'SUM';

        insert customSetting;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Investment_Vehicle__c inv = new Investment_Vehicle__c(Name='Test Invesment Vehicle');
        insert inv;
        Opportunity o = new Opportunity(Name='Test Opp', StageName='test', CloseDate=system.today(), Investment_Vehicle__c=inv.Id, AccountId=testAccount.Id);
        insert o;

        List<Investor_Position__c> testProjects = new List<Investor_Position__c>();
        testProjects.add(new Investor_Position__c(Name = 'Project 1', AUM_Number__c = 2000, Investor_Position_Account__c = testAccount.Id, Investment_Vehicle__c=inv.Id, Current_Commitments_USD__c=10, Opportunity_Name__c=o.Id));
        testProjects.add(new Investor_Position__c(Name = 'Project 2', AUM_Number__c = 3000, Investor_Position_Account__c = testAccount.Id, Investment_Vehicle__c=inv.Id, Current_Commitments_USD__c=11, Opportunity_Name__c=o.Id));

        Test.startTest();
        insert testProjects;
        testAccount.Description = 'Hello World';
        update testAccount;

        testAccount = [SELECT Id, NumberOfEmployees FROM Account WHERE Id = :testAccount.Id];
        Test.stopTest();
    }
}