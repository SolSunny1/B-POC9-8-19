@isTest(SeeAllData=true)
private class Test_SicCodeTree{
  static testMethod void GenrateSicCodeTree(){     

    // Set up the Account record.
    Account a = TestFactory.buildTestAcc(1, UserInfo.getUserId());
    insert a;

    ApexPages.currentPage().getParameters().put('id', a.id);
    SicCodeTree obj = new SicCodeTree();
    obj.cancel();
    obj.UpdateSicCode();
    Account objAcc = new Account(Id=a.id);
    objAcc.SICCode__c ='10 METAL MINING\n';
    update objAcc;
    SicCodeTree objs = new SicCodeTree();
    objs.UpdateSicCode();
  }
}