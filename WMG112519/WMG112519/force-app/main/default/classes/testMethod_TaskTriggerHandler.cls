@isTest
private  class testMethod_TaskTriggerHandler 
{
   @isTest(SeeAllData=true)
  static void TaskTriggerHandler_NoChild_Test () 
  {
    //Create Test Data 
    Task_Updates__c tu = new Task_Updates__c();
    tu.name = 'test CS';
    tu.Task_Field__c = 'Type';
    tu.Task_Value__c = 'Portfolio Review';
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
    
      List<Task> tskList = new List<Task>();
      
    Task tsk = new Task();
    tsk.Subject = 'Test Task';
    tsk.WhatId = acct.id;
    tsk.WhoId = ct.Id;
    tsk.Type = 'Portfolio Review';
    tskList.add(tsk);
        
    Task tsk1 = new Task();
    tsk1.Subject = 'Test Task1';
    tsk1.WhatId = acct.id;
    tsk1.WhoId = ct.Id;
    tsk1.Type = 'Portfolio Review';
    tskList.add(tsk1);
    insert tskList;
    List<Task> tskList1 = new List<Task>();  
    tsk.Status = 'Completed';
     tskList1.add(tsk);
     tsk1.Status='Deffered';
    tskList1.add(tsk1);
    update tskList1;
    test.stopTest();
    
    
  }
    @isTest(SeeAllData=true)
  static void TaskTriggerHandler_WithChild_Test () 
  {
    //Create Test Data 
    Task_Updates__c tu = new Task_Updates__c();
    tu.name = 'test CS';
    tu.Task_Field__c = 'Type';
    tu.Task_Value__c = 'Portfolio Review';
    tu.Object_To_Update__c = 'Contact';
    tu.Field_To_Update__c = 'Last_In_Person_Meeting__c';
    tu.Child_Object__c = 'Contact';
    tu.Child_Field__c = 'AccountId';
    tu.Active__c = true;
    insert tu;
      
     // Task_Field__c, Task_Value__c ,Object_To_Update__c ,Field_To_Update__c ,Child_Object__c,Child_FIeld__c
    
    Account acct = new Account ();
    acct.Name = 'Test Account';
    insert acct;
    
    Contact ct = new Contact ();
    ct.FirstName = 'firstN';
    ct.LastName = 'lastN';
    ct.AccountId = acct.id;
    insert ct;
    
      Task tsk = new Task();
      List<Task> tskList = new List<Task>();  
      List<Task> tskList1 = new List<Task>();
    tsk.Subject = 'Test Task';
    tsk.Type = 'Portfolio Review';
    tsk.Status='In Progress';
    tsk.WhatId = acct.Id;
    tsk.WhoId = ct.Id;
    tsk.Priority='Normal';
    //tsk.ActivityDate=Date.newInstance(2016, 2, 29);
    tskList.add(tsk);
    insert tskList;
      
    test.startTest(); 
      
    Task tsk1 = new Task();
    tsk1.id=tsk.id;
    tsk1.WhatId = acct.Id;
    tsk1.WhoId = ct.Id;
    tsk1.Status = 'Completed';
    tsk1.Priority='Low'; 
    tskList1.add(tsk1);
    
    tskList1.sort();
    update tskList1;
    test.stopTest();
    
    
  }
  

}