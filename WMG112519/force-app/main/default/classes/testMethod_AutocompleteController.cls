@isTest(SeeAllData=False)
private  class testMethod_AutocompleteController {
  
  static testMethod void AutocompleteController_Test () 
  {
    Account acct = new Account();
    acct.Name = 'testMethod';
    insert acct;
    test.startTest();
    list<sObject> objList = AutocompleteController.searchObject('Account', 'test', '5', 'false' , '', '');
    System.assertEquals(1, objList.size() );
    test.stopTest();
  }
  static testMethod void AutocompleteController_TestFilter () 
  {
    Account acct = new Account();
    acct.Name = 'testMethod';
    insert acct;
    test.startTest();
    list<sObject> objList = AutocompleteController.searchObject('Account', 'test', '5', 'false' , 'Name', 'testMethod');
    System.assertEquals(1, objList.size() );
    test.stopTest();
  }
  static testMethod void AutocompleteController_TestError1 () 
  {
    Account acct = new Account();
    acct.Name = 'testMethod';
    insert acct;
    test.startTest();
    list<sObject> objList = AutocompleteController.searchObject('Acccount', 'test', '5', 'false' , 'Name', 'testMethod');
    System.assertEquals(null, objList );
    test.stopTest();
  }
  static testMethod void AutocompleteController_TestError2 () 
  {
    Account acct = new Account();
    acct.Name = 'testMethod';
    insert acct;
    test.startTest();
    list<sObject> objList = AutocompleteController.searchObject('Account', 'test', '5', 'false' , 'Name1', 'testMethod');
    
    test.stopTest();
  }
}