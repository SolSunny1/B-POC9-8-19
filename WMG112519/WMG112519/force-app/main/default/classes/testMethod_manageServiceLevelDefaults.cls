@isTest(SeeAllData=False)
private class testMethod_manageServiceLevelDefaults {
    
    static testMethod void manageServiceLevelDefaults_Test () 
    {
        CreateData (false);
        Test.StartTest();
        manageServiceLevelDefaultsExtension myCon = new manageServiceLevelDefaultsExtension ();
        
        myCon.Tier_A_In_Person_Meetings_Year = 2;
        myCon.OverrideSave();
        myCon.Cancel() ;
        test.stopTest();
    }
    static testMethod void manageServiceLevelDefaults_NoRecord_Test () 
    {
        CreateData (true);
        PageReference pageRef = Page.manageServiceLevelDefaults;
        Test.setCurrentPageReference(pageref);
        ApexPages.currentPage().getParameters().put('retUrl','1234');
        
        Test.StartTest();
        manageServiceLevelDefaultsExtension myCon = new manageServiceLevelDefaultsExtension ();
        myCon.Tier_A_In_Person_Meetings_Year = 2;
        myCon.OverrideSave();
        myCon.Cancel() ;
        test.stopTest();
    }
    private static void CreateData (boolean CreateOrg)
    {
        ConfigSettings__c config = new ConfigSettings__c ();
        config.Name = 'DefaultSvcConfigEmail' ;
        config.Value__c = 'test@test.com';
        insert config ;
        
        Service_Level_Defaults__c sfd = Service_Level_Defaults__c.getInstance ();
        if (CreateOrg)
            sfd.SetupOwnerId = UserInfo.getOrganizationId();
        sfd.Tier_A_In_Person_Meetings_Year__c = 1;
        sfd.Tier_B_In_Person_Meetings_Year__c = 1;
        sfd.Tier_C_In_Person_Meetings_Year__c = 1;
        sfd.Tier_D_In_Person_Meetings_Year__c = 1;
        sfd.Tier_E_In_Person_Meetings_Year__c = 1;
        sfd.Tier_A_Relationship_Calls_Year__c =1;
        sfd.Tier_B_Relationship_Calls_Year__c =1;
        sfd.Tier_C_Relationship_Calls_Year__c =1;
        sfd.Tier_D_Relationship_Calls_Year__c =1;
        sfd.Tier_E_Relationship_Calls_Year__c =1;
        sfd.Num_Days_Ahead_On_Target__c = 30;
        insert sfd;
        System.Debug('****: ' + Service_Level_Defaults__c.getInstance () ) ;
        
    }
    
}