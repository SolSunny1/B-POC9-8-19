@istest


public class Test_Activity_Controller_From_Opp {

    
    Private Static testmethod void Test_ActivityHistory_From_Opp (){    
            
        PageReference pageRef1 = new pagereference('/apex/Opp_ActivityHistory_Related_Lists');
        Test.setCurrentPage(pageRef1);
        // Setup Test User and Opportunity data
        
        User RunUser0 = TestFactory.buildTestUser(0, 'System Administrator');
        insert RunUser0; 
                
        User TestUser1 = TestFactory.buildTestUser(1, 'System Administrator');
        insert TestUser1;
        
        User TestUser2 = TestFactory.buildTestUser(2, 'System Administrator');
        insert TestUser2;
        
        Account TestAcc = TestFactory.BuildTestAcc(1, TestUser1.Id);
        insert TestAcc;
        
        Contact TestCon = TestFactory.BuildTestCon(1, Testuser1.Id, TestAcc);
        insert TestCon;
 
        Opportunity TestOpp_Shared = TestFactory.buildTestOpp(1, TestUser1.Id, 'PFG', TestAcc);
        TestOpp_Shared.Share_with_PFG_Platform__c = False;
        insert TestOpp_Shared;
       
        Task TestTask1 = TestFactory.BuildTestTasks(1, TestUser1.Id, Testopp_Shared.Id);   
        TestTask1.status = 'completed';   
        TestTask1.whoId = TestCon.Id;
        Database.DMLOptions disableDupesdml = new Database.DMLOptions();
        disableDupesdml.DuplicateRuleHeader.allowSave = true;
        disableDupesdml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.insert(TestTask1, disableDupesdml);
        
        Task TestTask2 = TestFactory.BuildTestTasks(2, TestUser2.Id, Testopp_Shared.Id);   
        TestTask2.status = 'completed';   
        TestTask2.whoId = TestCon.Id;
        Database.insert(TestTask2, disableDupesdml);
       
        Event TestEvent1 = TestFactory.BuildTestEvents(1, TestUser1.Id, Testopp_Shared.Id);
        TestEvent1.ActivityDate = date.today() - 5;
        TestEvent1.ActivityDateTime = date.today() - 5;
        TestEvent1.whoId = TestCon.Id;
        insert TestEvent1;
        
        system.runAs(RunUser0) {
            ApexPages.StandardController setCon1 = new ApexPages.StandardController(TestOpp_Shared);  
            Activity_Controller_From_Opp TestExt_Shared = new Activity_Controller_From_Opp(setCon1);     
            
            Test.startTest();   
            TestExt_Shared.getHistoryListPFORM();
            TestExt_Shared.getHistoryList();   
            Test.stopTest();        
            
            //System.assertEquals(3, TestExt_Shared.HistoryList.size()); 
            //System.assertEquals(3, TestExt_Shared.HistoryListPFORM.size());
        }
    }
         
    private Static testmethod void Test_OpenActivity_From_Opp (){    
            
        PageReference pageRef1 = new pagereference('/apex/Opp_OpenActivity_Related_Lists');
        Test.setCurrentPage(pageRef1);
        
        // Setup Test User and Opportunity data
        
        User RunUser5 = TestFactory.buildTestUser(5, 'System Administrator');
        insert RunUser5;
        
        User TestUser3 = TestFactory.buildTestUser(3, 'System Administrator');
        insert TestUser3;
        
        User TestUser4 = TestFactory.buildTestUser(4, 'System Administrator');
        insert TestUser4;        
        
        Account TestAcc = TestFactory.BuildTestAcc(0, TestUser3.Id);
        insert TestAcc;
        
        Contact TestCon = TestFactory.BuildTestCon(0, Testuser3.Id, TestAcc);
        insert TestCon;
        
        Opportunity TestOpp_Shared = TestFactory.buildTestOpp(0, TestUser3.Id, 'PFG', TestAcc);
        TestOpp_Shared.Share_with_PFG_Platform__c = False;
        insert TestOpp_Shared;
        
        Task TestTask1 = TestFactory.BuildTestTasks(0, TestUser3.Id, Testopp_Shared.Id);
        TestTask1.Status = 'In Progress';
        Database.DMLOptions disableDupesdml = new Database.DMLOptions();
        disableDupesdml.DuplicateRuleHeader.allowSave = true;
        disableDupesdml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.insert(TestTask1, disableDupesdml);
        
        Task TestTask2 = TestFactory.BuildTestTasks(0, TestUser4.Id, Testopp_Shared.Id);
        TestTask2.Status = 'In Progress';
        Database.insert(TestTask2, disableDupesdml);
        
        Event TestEvent_Shared = TestFactory.BuildTestEvents(0, TestUser3.Id, Testopp_Shared.Id);
        TestEvent_Shared.ActivityDate = date.today() + 5;
        TestEvent_Shared.ActivityDateTime = date.today() + 5;
        TestEvent_Shared.whoId = TestCon.Id;
        insert TestEvent_Shared;
        
        System.runAs(RunUser5) {       
            ApexPages.StandardController setCon1 = new ApexPages.StandardController(TestOpp_Shared);  
            Activity_Controller_From_Opp TestExt_Shared = new Activity_Controller_From_Opp(setCon1);     
            
            Test.startTest(); 
            TestExt_Shared.getOpenList(); 
            TestExt_Shared.getOpenListPFORM();   
            Test.stopTest();        
            
            //System.assertEquals(3, TestExt_Shared.OpenList.size());
            //System.assertEquals(3, TestExt_Shared.OpenListPFORM.size());
        }
    } 
 
}