@isTest
private class TaskTriggerTest {
    static testmethod void methodTaskTriggerTest () {
        list<ObjectFieldMapping__c> lstObjectFieldMappingInfo=new list<ObjectFieldMapping__c>();
        lstObjectFieldMappingInfo.add(new ObjectFieldMapping__c(Field_API_Name__c='Stat_cd__c',Field_Value__c='Complete,C',Functionality_Type__c='LastInPersonMeeting-Condition',Object_API_Name__c='Event',name='Event-Meeting Disposition'));
        lstObjectFieldMappingInfo.add(new ObjectFieldMapping__c(Field_API_Name__c='Status',Field_Value__c='Completed',Functionality_Type__c='LastRelationshipType-Condition',Object_API_Name__c='Task',name='Task-Status'));
        lstObjectFieldMappingInfo.add(new ObjectFieldMapping__c(Field_API_Name__c='Call_Note_Type__c',Field_Value__c='Task',Functionality_Type__c='LastRelationshipType-FieldUpdate',Object_API_Name__c='Task',name='Task-Call/Note Type',Target_Object_Field_Name__c='SalesConnect__Rep_Type__c',Target_Object_Name__c='Contact',Target_Object_Field_Value__c='Test'));
        insert lstObjectFieldMappingInfo;
        
        Account acct = new Account ();
        acct.Name = 'Test Account';
        insert acct;
      
        Contact ct = new Contact ();
        ct.FirstName = 'firstN';
        ct.LastName = 'lastN';
        ct.AccountId = acct.id;
        insert ct;
        
        Lead objLead=new Lead(firstname ='test',lastname='test',company='test',status='Open');
        
        insert objLead;
        
        Test.startTest();
        List<Task> tskList = new List<Task>();
      
        Task tsk = new Task();
        tsk.Subject = 'Email: Test';
        tsk.WhatId = acct.id;
        tsk.WhoId = ct.Id;
        tsk.Type = 'Portfolio Review';
        tsk.Call_Note_Type__c = 'Note';
        tskList.add(tsk);
        Task tsk1 = new Task();
        tsk1.Subject = 'Email: Test';
        tsk1.WhatId = acct.id;
        tsk1.WhoId = ct.Id;
        tsk1.Type = 'Portfolio Review';
        tsk1.Call_Note_Type__c = 'Task';
        tskList.add(tsk1);
        Task tsk2 = new Task();
        tsk2.Subject = 'Email: Test';
        tsk2.WhoId = objLead.Id;
        tsk2.Type = 'Portfolio Review';
        tsk2.Call_Note_Type__c = 'Note';
        tskList.add(tsk2);
        insert tskList;
        
        list<Event> lstEvent=new list<Event>();
        Event objEvent=new Event();
        objEvent.WhoId = ct.Id;
        objEvent.StartDateTime=system.now();
        objEvent.EndDateTime=system.now().adddays(2);
        objEvent.Subject='Meeting';
        objEvent.Products__c='Note';
        objEvent.Meeting_Type__c='Branch Meeting';
        objEvent.Stat_cd__c='Complete';
        lstEvent.add(objEvent);
        
        Event objEvent1=new Event();
        objEvent1.WhoId = objLead.Id;
        objEvent1.StartDateTime=system.now();
        objEvent1.EndDateTime=system.now().adddays(2);
        objEvent1.Subject='Meeting';
        objEvent1.Products__c='Note';
        objEvent1.Meeting_Type__c='Branch Meeting';
        objEvent1.Stat_cd__c='Complete';
        lstEvent.add(objEvent1);
        
        insert objEvent;
        Test.stopTest();
    }
}