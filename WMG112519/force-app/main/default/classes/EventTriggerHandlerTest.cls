@isTest
private class EventTriggerHandlerTest {
  @isTest(SeeAllData=true)  
  static void EventTriggerHandler_NoChild_Test () {
    //Create Test Data 
    Event_Updates__c tu = new Event_Updates__c();
    tu.name = 'test CS';
    tu.Event_Field__c = 'Type';
    tu.Event_Value__c = 'Portfolio Review';
    tu.Object_To_Update__c = 'Account';
    tu.Field_To_Update__c = 'Last_Relationship_Call__c';
    tu.Active__c = true;
    insert tu;
    
    Account acct = new Account ();
    acct.Name = 'Test Account';
    insert acct;
      
    Contact ct = new Contact ();
    ct.FirstName = 'firstN';
    ct.LastName = 'lastN';
    ct.AccountId = acct.id;
    insert ct;
      
    test.startTest();
    Event tsk = new Event();
    tsk.Subject = 'Test Event';
    tsk.WhatId = acct.id;
    tsk.WhoId = ct.Id;
    tsk.Type = 'Portfolio Review';
    tsk.StartDateTime = System.now().addDays( -4 );
    tsk.EndDateTime = tsk.StartDateTime.addDays( 1 );
    insert tsk;
    tsk.StartDateTime = System.now().addDays( -2 );
    tsk.EndDateTime = tsk.StartDateTime.addDays( 1 );
    update tsk;
    test.stopTest();
    
    
  }
    @isTest(SeeAllData=true) 
  static void EventTriggerHandler_WithChild_Test () 
  {
 
    Event_Updates__c tu = new Event_Updates__c();
    tu.name = 'test CS';
    tu.Event_Field__c = 'Type';
    tu.Event_Value__c = 'Portfolio Review';
    tu.Object_To_Update__c = 'Account';
    tu.Field_To_Update__c = 'Last_In_Person_Meeting__c';
    tu.Child_Object__c = 'Contact';
    tu.Child_Field__c = 'AccountId';
    tu.Active__c = true;
    insert tu;
    
    Account acct = new Account ();
    acct.Name = 'Test Account';
    insert acct;
    
    Contact ct = new Contact ();
    ct.FirstName = 'firstN';
    ct.LastName = 'lastN';
    ct.AccountId = acct.id;
    insert ct;
    
    test.startTest();
    Event tsk = new Event();
    tsk.Subject = 'Test Event';
    tsk.WhoId = ct.id;
    tsk.Type = 'Portfolio Review';
   tsk.StartDateTime = System.now().addDays( -4 );
    tsk.EndDateTime = tsk.StartDateTime.addDays( 1 );
    insert tsk;
    tsk.StartDateTime = System.now().addDays( -2 );
    tsk.EndDateTime = tsk.StartDateTime.addDays( 1 );
    update tsk;
    test.stopTest();
    
    
  }
}