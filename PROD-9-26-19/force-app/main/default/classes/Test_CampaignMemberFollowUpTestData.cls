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
public class Test_CampaignMemberFollowUpTestData {

    public static testMethod void createTestData() {
            
        // Create Campaign, Account and Group Test Records
       
        Account testAccount = new Account(name='test_account', NumberOfEmployees=190);
        //Group testQueueName = new Group(name='test_queue', Type='Queue');
        
        insert testAccount;
        Opportunity  objOpp = new Opportunity (Name='Test Opp', private__c=false, AccountId=testAccount.Id,Office_Country__c='India',StageName='New', CloseDate=system.today());
        insert objOpp;
         Campaign testCampaign = new Campaign(name='test_campaign', Original_Deal_Opportunity__c=objOpp.id,Status ='Active',IsActive=true); 
         insert testCampaign;           
        // Define Lists for Contact Lead and Campaign Member Test Records
        Contact[] testContactList = new Contact[]{};
        
        CampaignMember[] testCampaignMemberList = new CampaignMember[]{};   
            
        // Query for newly created Test Campaign and Account
        testCampaign = [select id, name, status, ownerId from campaign where name = 'test_campaign' order by name desc limit 1];
        testAccount = [select id, name from account where name = 'test_account'];
        //testQueue = [Select SobjectType, QueueId, Id From QueueSobject where QueueId =:testQueueName.Id limit 1];
        
        // Create 30 Test Contacts
        for(Integer i = 0; i < 30; i++){
            testContactList.add(new Contact(FirstName='New',lastname='test_contact_' + i, Title='Chef', MailingPostalCode='806'+i, accountId = testAccount.Id));
        }
        insert testContactList;
            
        
       
         //  string  filterTitle ='  Contact.Name LIKE \'Title+%\'';
        // Query for newly created Test Contacts and Leads
        testContactList = [select id, name from contact where name like '%test_contact_%' order by name];
        
            
        // Assign Test Contacts to Test Campaign
        for(Integer x = 0; x < testContactList.size(); x++){
            testCampaignMemberList.add(new CampaignMember(
                campaignId = testCampaign.Id,
                contactId = testContactList[x].Id, 
                status = 'Prospect',
                Bid_Probability__c = 'Medium'));
        }
            
            
            
        // Insert List of Test Campaign Members
        insert testCampaignMemberList;
        testCampaignMemberList[0].Status = 'Passed';
        update testCampaignMemberList;
        testCampaignMemberList[1].Status = null;
        update testCampaignMemberList;
        
        delete testCampaignMemberList[0];
    }
}