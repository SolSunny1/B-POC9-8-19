@isTest(SeeAllData=true) // Set to true for custom settings
public with sharing class CSL_Test_Mass_Opportunities {
    
    /**
      * Test Coverage related to the mass opportunity module
      */
    static testMethod void testMassOppty() {
        // Create Test Data (Accounts, Contacts, Oppty's, PFG User)
        User pfgUser = TestFactory.buildTestUser(1, 'PFG_CRM');
        insert pfgUser;

        Account a1 = TestFactory.buildTestAcc(1, pfgUser.Id);
        Account a2 = TestFactory.buildTestAcc(2, pfgUser.Id);
        Account a3 = TestFactory.buildTestAcc(3, pfgUser.Id);
        Account a4 = TestFactory.buildTestAcc(4, pfgUser.Id);
        List<Account> newAcctList = new List<Account>{a1, a2, a3, a4};
        a1.PFG_Relationship_Importance__c = a2.PFG_Relationship_Importance__c = a3.PFG_Relationship_Importance__c = a4.PFG_Relationship_Importance__c = '1 - Strategic';
        a1.PFG_General_Investing_Interest__c = a2.PFG_General_Investing_Interest__c = a3.PFG_General_Investing_Interest__c = a4.PFG_General_Investing_Interest__c = 'Agriculture';
        insert newAcctList;

        // Query created accounts
        a1 = TestFactory.queryAccount(a1.Id);
        a2 = TestFactory.queryAccount(a2.Id);
        a3 = TestFactory.queryAccount(a3.Id);
        a4 = TestFactory.queryAccount(a4.Id);

        Contact c1 = TestFactory.buildTestCon(1, pfgUser.Id, a1);
        Contact c2 = TestFactory.buildTestCon(4, pfgUser.Id, a2);
        Contact c3 = TestFactory.buildTestCon(3, pfgUser.Id, a3);
        Contact c32 = TestFactory.buildTestCon(3, pfgUser.Id, a3);
        Contact c4 = TestFactory.buildTestCon(1, pfgUser.Id, a4);
        c1.PFG_Key_Contact__c = c2.PFG_Key_Contact__c = c3.PFG_Key_Contact__c = c4.PFG_Key_Contact__c = c32.PFG_Key_Contact__c = true;
        c1.PFG_Asset_Mix_Coverage__c = c2.PFG_Asset_Mix_Coverage__c = c3.PFG_Asset_Mix_Coverage__c = c4.PFG_Asset_Mix_Coverage__c = c32.PFG_Asset_Mix_Coverage__c = 'Agriculture';
        c4.Contact_Status__c = 'Retired / Inactive';
        List<Contact> newContactList = new List<Contact>{c1, c2, c3, c32, c4};
        system.debug('CSL_Test_Mass_Opportunities :: testMassOppty :: newContactList=' + newContactList);
        insert newContactList;

        Investment_Vehicle__c iv = null;
        Investment_Vehicle__c newIv = null;
        System.runAs(pfgUser) {
            iv = TestFactory.buildInvestmentVehicle('testIV');
            newIv = TestFactory.buildInvestmentVehicle('testNewIV');
            List<Investment_Vehicle__c> ivList = new List<Investment_Vehicle__c>{iv, newIv};
            insert ivList;
        }

        Opportunity o1 = TestFactory.buildTestOpp(1, pfgUser.Id, 'PFG', a1);
        o1.Legal_Name__c = 'o1';
        Opportunity o2 = TestFactory.buildTestOpp(2, pfgUser.Id, 'PFG', a2);
        o2.Legal_Name__c = 'o2';
        Opportunity o3 = TestFactory.buildTestOpp(3, pfgUser.Id, 'PFG', a3);
        o3.Legal_Name__c = 'o3';
        Opportunity o4 = TestFactory.buildTestOpp(4, pfgUser.Id, 'PFG', a4);
        o4.Legal_Name__c = 'o4';
        Opportunity o5 = TestFactory.buildTestOpp(5, pfgUser.Id, 'PFG', a3);
        o5.Legal_Name__c = 'o5';
        // Oppty's to test not matching the search criteria
        Opportunity o61 = TestFactory.buildTestOpp(61, pfgUser.Id, 'PFG', a3);
        o61.Probability = 75;
        o61.Legal_Name__c = 'o61';
        Opportunity o62 = TestFactory.buildTestOpp(62, pfgUser.Id, 'BAM', a3);
        o62.Legal_Name__c = 'o62';
        Opportunity o63 = TestFactory.buildTestOpp(63, pfgUser.Id, 'PFG', a3);
        o63.Legal_Name__c = 'o63';
        o63.OwnerId = UserInfo.getUserId();
        Opportunity o64 = TestFactory.buildTestOpp(64, pfgUser.Id, 'PFG', a3);
        o64.Legal_Name__c = 'o64';  
        // Set Oppty's to search oppty id
        o1.Investment_Vehicle__c = o2.Investment_Vehicle__c = o3.Investment_Vehicle__c = o4.Investment_Vehicle__c = iv.Id;
        o61.Investment_Vehicle__c = o62.Investment_Vehicle__c = o63.Investment_Vehicle__c = o64.Investment_Vehicle__c = iv.Id;
        o61.Duplicate__c = o62.Duplicate__c = o63.Duplicate__c = o64.Duplicate__c = true;
        // Set Oppty to new oppty id
        o5.Investment_Vehicle__c = newIv.Id;
        o5.Duplicate__c = true;
        List<Opportunity> newOppList = new List<Opportunity>{o1, o2, o3, o4, o5, o61, o62/*, o63, o64*/};
        insert newOppList;

        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=c1.Id, OpportunityId=o1.Id, Role='Influencer');
        OpportunityContactRole ocr2 = new OpportunityContactRole(ContactId=c2.Id, OpportunityId=o2.Id, Role='Influencer');
        OpportunityContactRole ocr3 = new OpportunityContactRole(ContactId=c3.Id, OpportunityId=o5.Id, Role='Influencer');
        OpportunityContactRole ocr32 = new OpportunityContactRole(ContactId=c32.Id, OpportunityId=o5.Id, Role='Influencer');
        OpportunityContactRole ocr4 = new OpportunityContactRole(ContactId=c4.Id, OpportunityId=o4.Id, Role='Influencer');
        OpportunityContactRole ocr61 = new OpportunityContactRole(ContactId=c3.Id, OpportunityId=o61.Id, Role='Influencer');
        OpportunityContactRole ocr62 = new OpportunityContactRole(ContactId=c3.Id, OpportunityId=o62.Id, Role='Influencer');
        //OpportunityContactRole ocr63 = new OpportunityContactRole(ContactId=c3.Id, OpportunityId=o63.Id, Role='Influencer');
        //OpportunityContactRole ocr64 = new OpportunityContactRole(ContactId=c3.Id, OpportunityId=o64.Id, Role='Influencer');
        List<OpportunityContactRole> newOcrList = new List<OpportunityContactRole>{ocr1, ocr2, ocr3, ocr32, ocr4, ocr61, ocr62/*, ocr63, ocr64*/};
        insert newOcrList;

        Test.startTest();

        PageReference pageRef = Page.Mass_Opportunity_Creator;
        Test.setCurrentPage(pageRef);

        // Run as a PFG User (Load Page)
        System.runAs(pfgUser) {
            CSL_VFC_Mass_Opp_Creator moc = new CSL_VFC_Mass_Opp_Creator();
            moc.inputOpportunity.Investment_Vehicle__c = iv.Id;
            moc.inputOpportunity.OwnerId = pfgUser.Id;
            moc.inputAccount.PFG_Relationship_Importance__c = '1 - Strategic';
            moc.inputAccount.PFG_CRM_Primary_Lead__c = pfgUser.Id;
            moc.inputCreateOpportunity.Investment_Vehicle__c = newIv.Id;
            moc.probabilityFrom = 0;
            moc.probabilityTo = 50;
            moc.selectedInvestmentInterests = 'Agriculture';

            // Search
            moc.search();
            List<CSL_VFC_Mass_Opp_Creator.ContactWrapper> results = moc.contactWrapperList;
            system.assert(results != null);
            //CSL
            //system.assert(results.isEmpty());

            // Try to create oppty's without selecting any results to test validation on selected records
            moc.createOpportunities();

            // Select results to create oppty's
            for(CSL_VFC_Mass_Opp_Creator.ContactWrapper cw : results) {
                cw.isSelected = true;
            }

            // Try to create oppty's without selecting any results to test validation on null create parameters
            moc.createOpportunities();

            // Select/Create Oppty
            moc.inputCreateOpportunity.StageName = newIv.Id;
            moc.inputCreateOpportunity.OwnerId = pfgUser.Id;
            moc.inputCreateOpportunity.CloseDate = Date.today().addDays(365);
            moc.createOpportunities();

            // Test of cancel navigation
            moc.cancel();
        }

        Test.stopTest();
        
    }

    /**
      * Test Coverage related to the mass opportunity module (Running without opp criteria specified)
      */
    static testMethod void testMassOpptyNoOppCriteria() {
        // Create Test Data (Accounts, Contacts, Oppty's, PFG User)
        User pfgUser = TestFactory.buildTestUser(1, 'PFG_CRM');
        insert pfgUser;

        Account a1 = TestFactory.buildTestAcc(1, pfgUser.Id);
        Account a2 = TestFactory.buildTestAcc(2, pfgUser.Id);
        Account a3 = TestFactory.buildTestAcc(3, pfgUser.Id);
        Account a4 = TestFactory.buildTestAcc(4, pfgUser.Id);
        List<Account> newAcctList = new List<Account>{a1, a2, a3, a4};
        a1.PFG_Relationship_Importance__c = a2.PFG_Relationship_Importance__c = a3.PFG_Relationship_Importance__c = a4.PFG_Relationship_Importance__c = '1 - Strategic';
        insert newAcctList;

        // Query created accounts
        a1 = TestFactory.queryAccount(a1.Id);
        a2 = TestFactory.queryAccount(a2.Id);
        a3 = TestFactory.queryAccount(a3.Id);
        a4 = TestFactory.queryAccount(a4.Id);

        Contact c1 = TestFactory.buildTestCon(1, pfgUser.Id, a1);
        Contact c2 = TestFactory.buildTestCon(4, pfgUser.Id, a2);
        Contact c3 = TestFactory.buildTestCon(3, pfgUser.Id, a3);
        Contact c32 = TestFactory.buildTestCon(3, pfgUser.Id, a3);
        Contact c4 = TestFactory.buildTestCon(1, pfgUser.Id, a4);
        c1.PFG_Key_Contact__c = c2.PFG_Key_Contact__c = c3.PFG_Key_Contact__c = c4.PFG_Key_Contact__c = c32.PFG_Key_Contact__c = true;
        c4.Contact_Status__c = 'Retired / Inactive';
        List<Contact> newContactList = new List<Contact>{c1, c2, c3, c32, c4};
        system.debug('CSL_Test_Mass_Opportunities :: testMassOppty :: newContactList=' + newContactList);
        insert newContactList;

        Investment_Vehicle__c iv = null;
        Investment_Vehicle__c newIv = null;
        System.runAs(pfgUser) {
            iv = TestFactory.buildInvestmentVehicle('testIV');
            newIv = TestFactory.buildInvestmentVehicle('testNewIV');
            List<Investment_Vehicle__c> ivList = new List<Investment_Vehicle__c>{iv, newIv};
            insert ivList;
        }

        Test.startTest();

        PageReference pageRef = Page.Mass_Opportunity_Creator;
        Test.setCurrentPage(pageRef);

        // Run as a PFG User (Load Page)
        System.runAs(pfgUser) {
            CSL_VFC_Mass_Opp_Creator moc = new CSL_VFC_Mass_Opp_Creator();
            moc.hasOpportunities = false;
            moc.inputAccount.PFG_Relationship_Importance__c = '1 - Strategic';
            moc.inputAccount.PFG_CRM_Primary_Lead__c = pfgUser.Id;
            moc.inputCreateOpportunity.Investment_Vehicle__c = newIv.Id;
            moc.probabilityFrom = 0;
            moc.probabilityTo = 100;

            // Search
            moc.search();
            List<CSL_VFC_Mass_Opp_Creator.ContactWrapper> results = moc.contactWrapperList;
            //CSL
            //system.assert(results != null);
            system.assert(results.isEmpty());

            // Select results to create oppty's
            for(CSL_VFC_Mass_Opp_Creator.ContactWrapper cw : results) {
                cw.isSelected = true;
            }

            // Select/Create Oppty
            moc.inputCreateOpportunity.StageName = newIv.Id;
            moc.inputCreateOpportunity.OwnerId = pfgUser.Id;
            moc.inputCreateOpportunity.CloseDate = Date.today().addDays(365);
            moc.createOpportunities();
        }

        Test.stopTest();
    }

    /**
      * Test Coverage related to the mass opportunity module validations
      */
    static testMethod void testMassOpptyValidations() {
        // Create Test Data (Accounts, Contacts, Oppty's, PFG User)
        User pfgUser = TestFactory.buildTestUser(1, 'PFG_CRM');
        insert pfgUser;

        Test.startTest();

        PageReference pageRef = Page.Mass_Opportunity_Creator;
        Test.setCurrentPage(pageRef);

        // Run as a PFG User (Load Page)
        System.runAs(pfgUser) {
            // Null Input investment vehicle check
            CSL_VFC_Mass_Opp_Creator moc = new CSL_VFC_Mass_Opp_Creator();
            moc.hasOpportunities = true;
            moc.search();
            List<CSL_VFC_Mass_Opp_Creator.ContactWrapper> results = moc.contactWrapperList;
            system.assert(results == null);

            // No stage or probabilities specified
            moc = new CSL_VFC_Mass_Opp_Creator();
            moc.hasOpportunities = true;
            moc.inputOpportunity.StageName = null;
            moc.probabilityFrom = 0;
            moc.probabilityTo = 0;
            moc.search();
            results = moc.contactWrapperList;
            system.assert(results == null);

            // From Probablity > Probability To
            moc = new CSL_VFC_Mass_Opp_Creator();
            moc.hasOpportunities = true;
            moc.probabilityFrom = 80;
            moc.probabilityTo = 30;
            moc.search();
            results = moc.contactWrapperList;
            system.assert(results == null);

            // Create opportunities without any results
            moc = new CSL_VFC_Mass_Opp_Creator();
            moc.createOpportunities();
        }

        Test.stopTest();
    }

    /**
      * Test Coverage related to the mass opportunity module
      */
    static testMethod void testMassOpptyPSG() {
        // Create Test Data (Accounts, Contacts, Oppty's, PFG User)
        User psgUser = TestFactory.buildTestUser(1, 'PSG_Support');
        psgUser.UserPermissionsMarketingUser = true;
        insert psgUser;

        Account a1 = TestFactory.buildTestAcc(1, psgUser.Id);
        Account a2 = TestFactory.buildTestAcc(2, psgUser.Id);
        Account a3 = TestFactory.buildTestAcc(3, psgUser.Id);
        Account a4 = TestFactory.buildTestAcc(4, psgUser.Id);
        List<Account> newAcctList = new List<Account>{a1, a2, a3, a4};
        insert newAcctList;

        // Query created accounts
        a1 = TestFactory.queryAccount(a1.Id);
        a2 = TestFactory.queryAccount(a2.Id);
        a3 = TestFactory.queryAccount(a3.Id);
        a4 = TestFactory.queryAccount(a4.Id);

        Contact c1 = TestFactory.buildTestCon(1, psgUser.Id, a1);
        Contact c2 = TestFactory.buildTestCon(4, psgUser.Id, a2);
        Contact c3 = TestFactory.buildTestCon(3, psgUser.Id, a3);
        Contact c32 = TestFactory.buildTestCon(3, psgUser.Id, a3);
        Contact c4 = TestFactory.buildTestCon(1, psgUser.Id, a4);
        List<Contact> newContactList = new List<Contact>{c1, c2, c3, c32, c4};
        system.debug('CSL_Test_Mass_Opportunities :: testMassOpptyPSG :: newContactList=' + newContactList);
        insert newContactList;
        
        Investment_Vehicle__c iv = null;
        Investment_Vehicle__c newIv = null;
        System.runAs(psgUser) {
            // Add Campaign Members
            Campaign c = TestFactory.createCampaign('PSG Test', true);
            Campaign mc = TestFactory.createCampaign('PSG Test2', true);
            List<Campaign> cList = new List<Campaign>{c, mc};
            insert cList;
            CampaignMember cm1 = new CampaignMember(CampaignId = c.Id, ContactId = c1.Id);
            CampaignMember cm1a = new CampaignMember(CampaignId = mc.Id, ContactId = c1.Id);
            CampaignMember cm2 = new CampaignMember(CampaignId = c.Id, ContactId = c2.Id);
            CampaignMember cm3 = new CampaignMember(CampaignId = c.Id, ContactId = c3.Id);
            CampaignMember cm4 = new CampaignMember(CampaignId = c.Id, ContactId = c4.Id);
            List<CampaignMember> cmList = new List<CampaignMember>{cm1, cm1a, cm2, cm3, cm4};
            //insert cmList;
            
            system.debug('****' + [SELECT Id, Name, IsActive FROM Campaign WHERE Id = :c.Id]);
            system.debug('****' + [SELECT Id, ContactId, Campaign.IsActive, Campaign.Name FROM CampaignMember WHERE CampaignId = :c.Id AND Campaign.Name LIKE '%PSG%' AND Campaign.IsActive = TRUE]);

            iv = TestFactory.buildInvestmentVehicle('testIV');
            newIv = TestFactory.buildInvestmentVehicle('testNewIV');
            List<Investment_Vehicle__c> ivList = new List<Investment_Vehicle__c>{iv, newIv};
            insert ivList;
        }

        Opportunity o1 = TestFactory.buildTestOpp(1, psgUser.Id, 'PSG', a1);
        o1.Legal_Name__c = 'o1';
        Opportunity o2 = TestFactory.buildTestOpp(2, psgUser.Id, 'PSG', a2);
        o2.Legal_Name__c = 'o2';
        Opportunity o3 = TestFactory.buildTestOpp(3, psgUser.Id, 'PSG', a3);
        o3.Legal_Name__c = 'o3';
        Opportunity o4 = TestFactory.buildTestOpp(4, psgUser.Id, 'PSG', a4);
        o4.Legal_Name__c = 'o4';
        Opportunity o5 = TestFactory.buildTestOpp(5, psgUser.Id, 'PSG', a3);
        o5.Legal_Name__c = 'o5';
        // Oppty's to test not matching the search criteria
        Opportunity o61 = TestFactory.buildTestOpp(61, psgUser.Id, 'PSG', a3);
        o61.Probability = 75;
        o61.Legal_Name__c = 'o61';
        Opportunity o62 = TestFactory.buildTestOpp(62, psgUser.Id, 'BAM', a3);
        o62.Legal_Name__c = 'o62';
        Opportunity o63 = TestFactory.buildTestOpp(63, psgUser.Id, 'PSG', a3);
        o63.Legal_Name__c = 'o63';
        o63.OwnerId = UserInfo.getUserId();
        Opportunity o64 = TestFactory.buildTestOpp(64, psgUser.Id, 'PSG', a3);
        o64.Legal_Name__c = 'o64';  
        
        // Set Oppty's to search oppty id
        o1.Investment_Vehicle__c = o2.Investment_Vehicle__c = o3.Investment_Vehicle__c = o4.Investment_Vehicle__c = iv.Id;
        o61.Investment_Vehicle__c = o62.Investment_Vehicle__c = o63.Investment_Vehicle__c = o64.Investment_Vehicle__c = iv.Id;
        o61.Duplicate__c = o62.Duplicate__c = o63.Duplicate__c = o64.Duplicate__c = true;
        // Set Oppty to new oppty id
        o5.Investment_Vehicle__c = newIv.Id;
        o5.Duplicate__c = true;
        List<Opportunity> newOppList = new List<Opportunity>{o1, o2, o3, o4, o5, o61, o62};
        insert newOppList;

        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=c1.Id, OpportunityId=o1.Id, Role='Influencer');
        OpportunityContactRole ocr2 = new OpportunityContactRole(ContactId=c2.Id, OpportunityId=o2.Id, Role='Influencer');
        OpportunityContactRole ocr3 = new OpportunityContactRole(ContactId=c3.Id, OpportunityId=o5.Id, Role='Influencer');
        OpportunityContactRole ocr32 = new OpportunityContactRole(ContactId=c32.Id, OpportunityId=o5.Id, Role='Influencer');
        OpportunityContactRole ocr4 = new OpportunityContactRole(ContactId=c4.Id, OpportunityId=o4.Id, Role='Influencer');
        OpportunityContactRole ocr61 = new OpportunityContactRole(ContactId=c3.Id, OpportunityId=o61.Id, Role='Influencer');
        OpportunityContactRole ocr62 = new OpportunityContactRole(ContactId=c3.Id, OpportunityId=o62.Id, Role='Influencer');
        List<OpportunityContactRole> newOcrList = new List<OpportunityContactRole>{ocr1, ocr2, ocr3, ocr32, ocr4, ocr61, ocr62};
        insert newOcrList;

        Test.startTest();

        PageReference pageRef = Page.PSG_Mass_Opportunity_Creator;
        Test.setCurrentPage(pageRef);

        // Run as a PSG User (Load Page)
        System.runAs(psgUser) {
            CSL_VFC_Mass_Opp_Creator moc = new CSL_VFC_Mass_Opp_Creator();
            moc.inputOpportunity.Investment_Vehicle__c = iv.Id;
            moc.inputOpportunity.OwnerId = psgUser.Id;
            moc.inputAccount.BIM_Primary_Mktg_Rep__c = psgUser.Id;
            moc.inputCreateOpportunity.Investment_Vehicle__c = newIv.Id;
            moc.hasActivePSGCampaigns = true;
            moc.probabilityFrom = 0;
            moc.probabilityTo = 50;
            moc.hideOpportunitiesCreated = true;

            moc.updateOpptyRecordType();

            // Search
            moc.search();
            List<CSL_VFC_Mass_Opp_Creator.ContactWrapper> results = moc.contactWrapperList;
            system.assert(results != null);
            //system.assert(!results.isEmpty());

            // Try to create oppty's without selecting any results to test validation on selected records
            moc.createOpportunities();

            // Select results to create oppty's
            for(CSL_VFC_Mass_Opp_Creator.ContactWrapper cw : results) {
                cw.isSelected = true;
            }

            // Try to create oppty's without selecting any results to test validation on null create parameters
            moc.createOpportunities();

            // Select/Create Oppty
            moc.inputCreateOpportunity.StageName = newIv.Id;
            moc.inputCreateOpportunity.OwnerId = psgUser.Id;
            moc.inputCreateOpportunity.CloseDate = Date.today().addDays(365);
            moc.createOpportunities();

            // Test of cancel navigation
            moc.cancel();
        }

        Test.stopTest();
        
    }
}