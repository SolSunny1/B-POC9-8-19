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
private class Test_CampaignMemberFollowUpTask {
        
    static testMethod void myUnitTest() {
        //Test cases
        //call test data creation class
        Test_CampaignMemberFollowUpTestData.createTestData();
        
        //get test_Campaign
        Campaign testCampaign = [select id, name, status, ownerId from campaign where name ='test_campaign' order by name desc limit 1];
        System.debug('+++++Campaign Id :'+testCampaign.id);
         ApexPages.currentPage().getParameters().put('id', testCampaign.id);
        test.startTest();
        //init page controller
        CampaignMemberFollowUpTaskController myController = new CampaignMemberFollowUpTaskController();
        
        
       map<string, boolean> mapPageCamp = new  map<string, boolean>();
       for(CampaignMember obj : [select Id from CampaignMember where campaign.name = 'test_campaign' limit 30])
       {
        
        mapPageCamp.put(obj.Id, true);
       }
        
        //select campaign section
        myController.SelectedCM = mapPageCamp;
        myController.getCMemberListNext();
        myController.getCMemberList_size();
       
        myController.getCampaign();
        myController.setCampaign(testCampaign.id);
        myController.renderFollowUpTrue();
       
        //follow up task section
        myController.loadCampaignMemberList(true);
        myController.loadCampaignMemberList(false);
         myController.SelectedCM = mapPageCamp;
        myController.generateTodos(); 
        myController.renderFollowUpTrue();
        myController.getOwnerTodo();
        
                
        //CMresults section
        myController.getCMemberList_size();
        myController.getSelectedCM();
        myController.getshowprev();
        myController.getshownext();
        myController.getCMemberListNext();
        myController.setCMemberListNext(myController.getCMemberListNext());
        myController.getallCheckboxes();
        myController.setallCheckboxes(true);
        myController.setallCheckboxes(false);
        myController.selectAllCMembers();
        myController.selectAllCMembers();
       
        //select one CM
        myController.changeSingleCheckbox();
        
        //select all in page CMs
        myController.changeCheckbox();
        
        //celect all in list CMs
        myController.selectAllCMembers();
        
        //paging
        myController.Next();
        myController.Prev();
        
        //V1.1
       
        myController.gofilter();
        
       
        
       
        // Both case
        myController.Title='test_contact';
      
        myController.gofilter();        
        
        //create task(s)
        myController.generateTodos(); 
        myController.getBadCMemberList();
         myController.renderFollowUpFalse();
        myController.renderCMresultsFalse();
        myController.generateTodos();
        myController.setOwnerTodo(myController.getOwnerTodo());
        test.stopTest();

    }
    

    
}