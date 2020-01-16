@isTest
private class testMethod_ManageTaskUpdateExtension 
{

    static testMethod void test_ManageTaskUpdateExtension_Test() 
    {
        Task_Updates__c tu = new Task_Updates__c();
        tu.Name = 'TEST';
        tu.Task_Field__c = 'Type';
         tu.Task_Value__c = 'Call';
         tu.Object_To_Update__c = 'Account';
         tu.Field_To_Update__c = 'testField';
        
      test.startTest();
      ApexPages.StandardController sc =  new ApexPages.StandardController(tu) ;
      ManageTaskUpdateExtension myCon = new ManageTaskUpdateExtension(sc);
      myCon.getTaskFields() ;
      myCon.getTasksPickListValues();
      myCon.getObjectList();
      myCon.getObjectFieldList();
      myCon.OverRideSave () ;
    
      List<Apexpages.Message> msgs = ApexPages.getMessages();
      System.assertEquals(0, msgs.size() );
      myCon.CloneRec();
      
      test.stopTest();
      
    }
    static testMethod void test_ManageTaskUpdateExtension_Test_Validation() 
    {
        Task_Updates__c tu = new Task_Updates__c();
        tu.Name = 'TEST';
           
      test.startTest();
      ApexPages.StandardController sc =  new ApexPages.StandardController(tu) ;
      ManageTaskUpdateExtension myCon = new ManageTaskUpdateExtension(sc);
      
      myCon.OverRideSave () ;
      List<Apexpages.Message> msgs = ApexPages.getMessages();
      System.assertNotEquals(0, msgs.size() );
      myCon.ResetChildValues () ;
    }
     static testMethod void test_ManageTaskUpdateExtension_Test_WithChild() 
    {
        Task_Updates__c tu = new Task_Updates__c();
        tu.Name = 'TEST';
        tu.Task_Field__c = 'Type';
         tu.Task_Value__c = 'Call';
         tu.Object_To_Update__c = 'Account';
         tu.Field_To_Update__c = 'testField';
         tu.Child_Object__c = 'Contact';
         tu.Child_Field__c = 'AccountID';
        
      test.startTest();
      ApexPages.StandardController sc =  new ApexPages.StandardController(tu) ;
      ManageTaskUpdateExtension myCon = new ManageTaskUpdateExtension(sc);
      myCon.getTaskFields() ;
      myCon.getTasksPickListValues();
      myCon.getObjectList();
      myCon.getObjectFieldList();
      myCon.getRelationshipObjects();
      myCon.getRelationshipfields();
      myCon.OverRideSave () ;
    
      List<Apexpages.Message> msgs = ApexPages.getMessages();
      System.assertEquals(0, msgs.size() );
      myCon.CloneRec();
      
      test.stopTest();
      
    }
}