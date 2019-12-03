/******************************************
Test Class Name - testForActivityTrigger
Created by - Samir Khan
Description - This test class is written for trigger populateAccount 
******************************************/
@isTest(SeeAllData=false)
Public class testForActivityTrigger{

    public static testMethod void testRunAs() {
        Profile p = [SELECT Id FROM Profile WHERE Name='BLP_NA'];
        
        User u = new User(Alias = 'test', Email='testtrigger@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testuser1fortrigger', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testtrigger11@test.com');
        insert u;

        System.runas(u){    
            Account acct = new Account(Name = 'Apex Test');
            acct.Name = acct.Name + (Math.random()*1000);
            insert acct;
    
            Task tsk1 = new Task(WhatId = acct.Id, Subject = 'Task1', ActivityDate = date.today(), Status = 'Completed');
            Database.DMLOptions disableDupesdml = new Database.DMLOptions();
            disableDupesdml.DuplicateRuleHeader.allowSave = true;
            disableDupesdml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.insert(tsk1, disableDupesdml);
            
            Event E1 = new Event(Type = 'Email', Description = 'Event1',WhatId = acct.Id,DurationInMinutes = 35,ActivityDateTime  = Datetime.now());
            Database.insert(E1, disableDupesdml);
            
            Event E2 = new Event(Type = 'Email', Description = 'Event1',WhatId = acct.Id,Latest_Activity__c = false,DurationInMinutes = 35,ActivityDateTime  = Datetime.now());
            Database.insert(E2, disableDupesdml);
            
            Event E3 = new Event(Type = 'Email', Description = 'Event1',WhatId = acct.Id,DurationInMinutes = 35,ActivityDateTime  = Datetime.now());
            Database.insert(E3, disableDupesdml);
            
            
            Property__c objProperty = new Property__c(name = 'Apex Test');
            insert objProperty;
            
            Property_Relation__c objPropRelation = new Property_Relation__c(Property__c = objProperty.id , Account__c =acct.Id );
            insert objPropRelation ;
            
            Task tsk2 = new Task(WhatId = objPropRelation .Id, Subject = 'Task2', ActivityDate = date.today(), Status = 'Completed');
            Database.insert(tsk2, disableDupesdml);
            
            Task tsk3 = new Task(WhatId = acct.Id, Subject = 'Task3', ActivityDate = date.today(), Status = 'Completed',Latest_Activity__c = false);
            Database.insert(tsk3, disableDupesdml);
            
            Task tsk4 = new Task(WhatId = acct.Id, Subject = 'Task4', ActivityDate = date.today(), Status = 'Completed',Latest_Activity__c = false);
            Database.insert(tsk4, disableDupesdml);
            
            Task tsk5 = new Task(WhatId = acct.Id, Subject = 'Task5', ActivityDate = date.today(), Status = 'In Progress',Latest_Activity__c = true);
            Database.insert(tsk5, disableDupesdml);
            
            tsk1.Subject = 'Email: apex testing';
            tsk1.Latest_Activity__c = false;
            //RecursiveHandler.flag = true;
            Database.update(tsk1, disableDupesdml);
            
            RecursiveHandler.flag = true;
            Event E4 = new Event(Type = 'Email', Description = 'Event1',WhatId = objPropRelation .Id,Latest_Activity__c = false,DurationInMinutes = 35,ActivityDateTime  = Datetime.now());
            Database.insert(E4, disableDupesdml);
            
            Event E5 = new Event(Type = 'Email', Description = 'Event1',WhatId = acct.Id,DurationInMinutes = 35,ActivityDateTime  = Datetime.now(),Latest_Activity__c = true);
            Database.insert(E5, disableDupesdml);
            
            delete tsk5;
            
            E1.Description = 'Test';
            Database.update(E1, disableDupesdml);
            
            //delete E5;
        }
    }
}