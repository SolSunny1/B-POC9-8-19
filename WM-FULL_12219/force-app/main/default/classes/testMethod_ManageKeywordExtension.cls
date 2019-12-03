@isTest(SeeAllData=False)
private class testMethod_ManageKeywordExtension {
  static testMethod void ManageKeywordExtension_Test () 
    {
      Contact ct = new Contact();
      ct.FirstName = 'Test';
      ct.LastName = 'Method';
      insert ct;
      PageReference pageRef = Page.ManageKeywords;
    Test.setCurrentPageReference(pageref);
    ApexPages.currentPage().getParameters().put('id',ct.id);
    
      test.startTest();
      ManageKeywordExtension myCon = new ManageKeywordExtension();
      myCon.Init();
      myCon.keywordObj.Type__c = 'Text';
      myCon.keywordObj.Name = 'Test Me';
      myCon.contactKeyword.Value_Text__c= '1234';
      myCon.ClearData() ;
      myCon.keywordObj.Type__c = 'Currency';
      myCon.keywordObj.Name = 'Test Me';
      myCon.contactKeyword.Value_Currency__c = 111;
      myCon.OverrideSave();
      List<Contact_Keyword__c> ctKey = [select id, name from Contact_Keyword__c ];
      System.assertEquals(1, ctKey.size());
      //List<Apexpages.Message> msgs = ApexPages.getMessages();
      //System.assertNotEquals(0, msgs.size() );
      myCon.ClearValues();
      myCon.keywordObj.Type__c = 'Text';
      myCon.contactKeyword.Value_Text__c = 'aaaa';
      myCon.OverrideSave();
      ctKey = [select id, name from Contact_Keyword__c ];
      System.assertEquals(2, ctKey.size());
      //Get the Keyword List 
      List<Contact_Keyword__c > kwList = myCon.getContactKeywords () ;
      myCon.SelectedRec = ctKey[0].id;
      myCon.EditContactKeyWord();
      myCon.contactKeyword.Value_Text__c = '12345';
      myCon.OverrideSave();
      ctKey = [select id, name from Contact_Keyword__c ];
      System.assertEquals(2, ctKey.size());
      myCon.SelectedRec = ctKey[0].id;
      myCon.DeleteContactKeyWord();
      ctKey = [select id, name from Contact_Keyword__c ];
      System.assertEquals(1, ctKey.size());
      myCon.Cancel();
      test.stopTest();
    }
}