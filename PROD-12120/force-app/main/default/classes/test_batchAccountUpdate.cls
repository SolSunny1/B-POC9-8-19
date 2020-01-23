/******************************************
Test Class Name - test_batchAccountUpdate
Created by - Samir Khan
Description - This test class is written for batch batchAccountUpdate
******************************************/

@isTest
class test_batchAccountUpdate{
    
    //query the account to process
    public static testMethod void accountTestMethod(){
    
        Profile p = [SELECT Id FROM Profile WHERE Name='BLP_NA'];
        User u = new User(Alias = 'test', Email='testtrigger@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testuser1fortrigger', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='testtrigger0@test.com');
        insert u;
        
        System.runas(u) {
            Account acct = new Account(Name = 'Apex Test');
            insert acct;
            
            Task tsk1 = new Task(WhatId = acct.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed',IDI_GazleyActivity__c = true ,Latest_Activity__c =true);
            Database.DMLOptions disableDupesdml = new Database.DMLOptions();
            disableDupesdml.DuplicateRuleHeader.allowSave = true;
            disableDupesdml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.insert(tsk1, disableDupesdml);
            
            Task tsk2 = new Task(WhatId = acct.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed',IDI_GazleyActivity__c = false,Latest_Activity__c =false);
            Database.insert(tsk2, disableDupesdml);
            
            Event E1 = new Event(Type = 'Email', Description = 'Event1',WhatId = acct.Id,Latest_Activity__c = false,DurationInMinutes = 35,ActivityDateTime  = Datetime.now(),IDI_GazleyActivity__c  = false);
            Database.insert(E1, disableDupesdml);
            
            Event E2 = new Event(Type = 'Email', Description = 'Event1',WhatId = acct.Id,Latest_Activity__c = true,DurationInMinutes = 35,ActivityDateTime  = Datetime.now(),IDI_GazleyActivity__c  = true);
            Database.insert(E2, disableDupesdml);
            
            Property__c objProperty = new Property__c(name = 'Apex Test');
            Database.insert(objProperty, disableDupesdml);
            
            Property_Relation__c objPropRelation = new Property_Relation__c(Property__c = objProperty.id , Account__c =acct.Id );
            Database.insert(objPropRelation, disableDupesdml);
            
            Task tsk3 = new Task(WhatId = objPropRelation.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed',IDI_GazleyActivity__c = true ,Latest_Activity__c =true);
            Database.insert(tsk3, disableDupesdml);
            
            Task tsk4 = new Task(WhatId = objPropRelation.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed',IDI_GazleyActivity__c = false,Latest_Activity__c =false);
            Database.insert(tsk4, disableDupesdml);
            
            Event E3 = new Event(Type = 'Email', Description = 'Event1',WhatId = objPropRelation.Id,Latest_Activity__c = false,DurationInMinutes = 35,ActivityDateTime  = Datetime.now(),IDI_GazleyActivity__c  = false);
            Database.insert(E3, disableDupesdml);
            
            Event E4 = new Event(Type = 'Email', Description = 'Event1',WhatId = objPropRelation.Id,Latest_Activity__c = true,DurationInMinutes = 35,ActivityDateTime  = Datetime.now(),IDI_GazleyActivity__c  = true);
            Database.insert(E4, disableDupesdml);
            
            batchAccountUpdate  accbatch = new batchAccountUpdate ();
            database.executeBatch(accbatch);
        }
    }
    
    //Negative test for empty event
    public static testMethod void accountTestMethod1(){
        Profile p = [SELECT Id FROM Profile WHERE Name='BLP_NA'];
        User u = new User(Alias = 'test', Email='testtrigger1@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testuser1fortrigger', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='testtrigger2+1@test.com');
        insert u;
        
        System.runas(u){
            Account acct = new Account(Name = 'Apex Test');
            insert acct;

            Database.DMLOptions disableDupesdml = new Database.DMLOptions();
            disableDupesdml.DuplicateRuleHeader.allowSave = true;
            disableDupesdml.DuplicateRuleHeader.runAsCurrentUser = true;
            
            Task tsk1 = new Task(WhatId = acct.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed',IDI_GazleyActivity__c = true ,Latest_Activity__c =true);
            Database.insert(tsk1, disableDupesdml);
            
            Task tsk2 = new Task(WhatId = acct.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed',IDI_GazleyActivity__c = false,Latest_Activity__c =false);
            Database.insert(tsk2, disableDupesdml);
            
            Property__c objProperty = new Property__c(name = 'Apex Test');
            Database.insert(objProperty, disableDupesdml);
            
            Property_Relation__c objPropRelation = new Property_Relation__c(Property__c = objProperty.id , Account__c =acct.Id );
            Database.insert(objPropRelation, disableDupesdml);
            
            Task tsk3 = new Task(WhatId = objPropRelation.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed',IDI_GazleyActivity__c = true ,Latest_Activity__c =true);
            Database.insert(tsk3, disableDupesdml);
            
            Task tsk4 = new Task(WhatId = objPropRelation.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed',IDI_GazleyActivity__c = false,Latest_Activity__c =false);
            Database.insert(tsk4, disableDupesdml);
            
            batchAccountUpdate  accbatch = new batchAccountUpdate ();
            database.executeBatch(accbatch);
        }
    }
    
    //Negative test for empty task
    public static testMethod void accountTestMethod2(){
        Profile p = [SELECT Id FROM Profile WHERE Name='BLP_NA'];
        User u = new User(Alias = 'test', Email='testtrigger3@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testuser1fortrigger', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='testtrigger4@test.com');
        insert u;
        
        System.runas(u) {
            Account acct = new Account(Name = 'Apex Test');
            insert acct;
            
            Event E1 = new Event(Type = 'Email', Description = 'Event1',WhatId = acct.Id,Latest_Activity__c = false,DurationInMinutes = 35,ActivityDateTime  = Datetime.now(),IDI_GazleyActivity__c  = false);
            insert E1;
            
            Event E2 = new Event(Type = 'Email', Description = 'Event1',WhatId = acct.Id,Latest_Activity__c = true,DurationInMinutes = 35,ActivityDateTime  = Datetime.now(),IDI_GazleyActivity__c  = true);
            insert E2;
            
            Property__c objProperty = new Property__c(name = 'Apex Test');
            insert objProperty;
            
            Property_Relation__c objPropRelation = new Property_Relation__c(Property__c = objProperty.id , Account__c =acct.Id );
            insert objPropRelation;
            
            Event E3 = new Event(Type = 'Email', Description = 'Event1',WhatId = objPropRelation.Id,Latest_Activity__c = false,DurationInMinutes = 35,ActivityDateTime  = Datetime.now(),IDI_GazleyActivity__c  = false);
            insert E3;
            
            Event E4 = new Event(Type = 'Email', Description = 'Event1',WhatId = objPropRelation.Id,Latest_Activity__c = true,DurationInMinutes = 35,ActivityDateTime  = Datetime.now(),IDI_GazleyActivity__c  = true);
            insert E4;
            
            batchAccountUpdate  accbatch = new batchAccountUpdate ();
            database.executeBatch(accbatch);
        }
    }

    /**
      * BF-1: Adding additional code coverage
      */
    public static testMethod void accountTaskAndEvents() {
        Profile p = [SELECT Id FROM Profile WHERE Name='BLP_NA'];
        User u = new User(Alias = 'test', Email='testtrigger3@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testuser1fortrigger', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='testtrigger42@test.com');
        insert u;
        
        System.runAs(u) {
            Account acct = new Account(Name = 'Apex Test');
            insert acct;

            Property__c objProperty = new Property__c(name = 'Apex Test');
            insert objProperty;
            
            Property_Relation__c objPropRelation = new Property_Relation__c(Property__c = objProperty.id , Account__c =acct.Id );
            insert objPropRelation;

            Task tsk1 = new Task(WhatId = acct.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed');
            //insert tsk1;
            
            Task tsk2 = new Task(WhatId = acct.Id, Subject = 'Task2', ActivityDate = date.today(), Status = 'Completed');
            //insert tsk2;

            Task tsk3 = new Task(WhatId = objPropRelation.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed');
            //insert tsk3;
            
            Task tsk4 = new Task(WhatId = objPropRelation.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed');
            //insert tsk4;

            List<Task> taskList = new List<Task>{tsk1, tsk2, tsk3, tsk4};
            Database.DMLOptions disableDupesdml = new Database.DMLOptions();
            disableDupesdml.DuplicateRuleHeader.allowSave = true;
            disableDupesdml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.insert(taskList, disableDupesdml);
            
            // Loop to ensure the events occur at a different time than the tasks
            Integer i = 1;
            while (i < 100000) {
                i++;
                system.debug('One more time ' + i);
            }

            Event E1 = new Event(Type = 'Email', Description = 'Event1',WhatId = acct.Id, DurationInMinutes = 35, ActivityDateTime = Datetime.now());
            Event E2 = new Event(Type = 'Email', Description = 'Event2',WhatId = acct.Id, DurationInMinutes = 35, ActivityDateTime = Datetime.now());
            Event E3 = new Event(Type = 'Email', Description = 'Event1',WhatId = objPropRelation.Id, Latest_Activity__c = false, DurationInMinutes = 35, ActivityDateTime  = Datetime.now());
            Event E4 = new Event(Type = 'Email', Description = 'Event1',WhatId = objPropRelation.Id, Latest_Activity__c = true, DurationInMinutes = 35, ActivityDateTime  = Datetime.now());
            
            List<Event> eventList = new List<Event>{E1, E2, E3, E4};
            Database.insert(eventList, disableDupesdml);
            
            batchAccountUpdate accBatch = new batchAccountUpdate();
            Database.executeBatch(accBatch);
        }
    }

    /**
      * BF-1: Adding additional code coverage
      */
    public static testMethod void accountEventsAndTasks() {
        Profile p = [SELECT Id FROM Profile WHERE Name='BLP_NA'];
        User u = new User(Alias = 'test', Email='testtrigger3@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testuser1fortrigger', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='testtrigger41@test.com');
        insert u;
        
        System.runAs(u) {
            Database.DMLOptions disableDupesdml = new Database.DMLOptions();
            disableDupesdml.DuplicateRuleHeader.allowSave = true;
            disableDupesdml.DuplicateRuleHeader.runAsCurrentUser = true;

            Account acct = new Account(Name = 'Apex Test');
            insert acct;

            Property__c objProperty = new Property__c(name = 'Apex Test');
            insert objProperty;
            
            Property_Relation__c objPropRelation = new Property_Relation__c(Property__c = objProperty.id , Account__c =acct.Id );
            insert objPropRelation;

            Event E1 = new Event(Type = 'Email', Description = 'Event1',WhatId = acct.Id, DurationInMinutes = 35, ActivityDateTime = Datetime.now());
            Event E2 = new Event(Type = 'Email', Description = 'Event2',WhatId = acct.Id, DurationInMinutes = 35, ActivityDateTime = Datetime.now());
            Event E3 = new Event(Type = 'Email', Description = 'Event1',WhatId = objPropRelation.Id, Latest_Activity__c = false, DurationInMinutes = 35, ActivityDateTime  = Datetime.now());
            Event E4 = new Event(Type = 'Email', Description = 'Event1',WhatId = objPropRelation.Id, Latest_Activity__c = true, DurationInMinutes = 35, ActivityDateTime  = Datetime.now());
            
            List<Event> eventList = new List<Event>{E1, E2, E3, E4};
            Database.insert(eventList, disableDupesdml);
                        
            // Loop to ensure the events occur at a different time than the tasks
            Integer i = 1;
            while (i < 100000) {
                i++;
                system.debug('One more time ' + i);
            }

            Task tsk1 = new Task(WhatId = acct.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed');
            Task tsk2 = new Task(WhatId = acct.Id, Subject = 'Task2', ActivityDate = date.today(), Status = 'Completed');
            Task tsk3 = new Task(WhatId = objPropRelation.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed');
            Task tsk4 = new Task(WhatId = objPropRelation.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed');
            
            List<Task> taskList = new List<Task>{tsk1, tsk2, tsk3, tsk4};
            Database.insert(taskList, disableDupesdml);
            
            batchAccountUpdate accBatch = new batchAccountUpdate();
            Database.executeBatch(accBatch);
        }
    }
}