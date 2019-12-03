/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(SeeAllData=true)
private class Test_SendNote {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
    Account objAcc = TestFactory.buildTestAcc(1, UserInfo.getUserId());
    insert objAcc;
    
    Opportunity  objOpp = new Opportunity (Name='Test Opp', private__c=false, AccountId=objAcc.Id,Office_Country__c='India',StageName='New', CloseDate=system.today());
    insert objOpp;
   
    Contact[] testContactList = new Contact[]{};    
    testContactList.add(new Contact(FirstName='New',lastname='test_contact', Title='Chef',  accountId = objAcc.Id));        
    insert testContactList;
      
     List<Task> tasks = new List<Task>();
    tasks.add(new Task(
    ActivityDate = Date.today().addDays(7),
    Subject='Sample Task',
    WhatId = objOpp.Id,
    whoid = testContactList[0].id,
    OwnerId = UserInfo.getUserId(),
    Status='In Progress'));
     insert tasks;
     
      ApexPages.CurrentPage().getparameters().put('Id', tasks[0].id);
      ApexPages.StandardController sc = new ApexPages.standardController(tasks[0]);
      SendNote sic = new SendNote(sc);
      list< SendNote.UsersRowItem> lstU = new  list<SendNote.UsersRowItem>();
      sic.getlistUsers();
      set<Id> usrId = new set<Id>();
      for(user u:[select id from user where  Profile.Name =:'System Administrator' limit 30])
      {
        SendNote.UsersRowItem obj = new SendNote.UsersRowItem(u,true);
        lstU.add(obj);
        usrId.add(u.Id);
      }
      sic.usersName ='New test_contact';
      sic.listUsers = lstU;
      //sic.selectDeselectRows();
      sic.selectedUserIds = usrId;
      sic.doSendEmail();
       sic.sendAttachment = true;
      sic.doSendEmail();
     // sic.selectDeselectRows();
      sic.getlistUsers();
      sic.searchUser();
      sic.strUseFullName = 'test';
      sic.searchUser();
      sic.doSelectItem();
      sic.getlistUsers();
      sic.doDeselectItem();
      sic.getSelectedCount();
      sic.doNext();
      sic.doPrevious();
      
      sic.getHasPrevious();
      sic.getHasNext();
      sic.getPageNumber();
      sic.doSendEmail();
     
      sic.getlistUsers();
      sic.getTotalPages();

      // BF-9: Added as a part of code coverage
      sic.getRoles();

      UserRole ur = [SELECT ID, Name FROM UserRole WHERE Name = 'SMP'];
      sic.IsAddSubordinate = true;
      sic.roleId = ur.Id;
      sic.searchUser();
    }
}