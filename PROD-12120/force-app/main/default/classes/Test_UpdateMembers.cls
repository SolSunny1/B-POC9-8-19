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
private class Test_UpdateMembers {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
         Test_CampaignMemberFollowUpTestData.createTestData();
         Campaign objCampaign = [select id from Campaign where name =:'test_campaign' limit 1];
          ApexPages.CurrentPage().getparameters().put('Id', objCampaign.id);
          ApexPages.StandardController sc = new ApexPages.standardController(objCampaign);
           UpdateMembers objUpdateMembers = new UpdateMembers(sc);
           objUpdateMembers.updateMassCampaignMembers();

           //objUpdateMembers.objSearchCampMember.Covering_Professional__c = System.UserInfo.getUserId();
           objUpdateMembers.searchbyName();
           objUpdateMembers.strName = 'test';
           objUpdateMembers.searchbyName();
           objUpdateMembers.last();
           objUpdateMembers.getCampaignMemberStatus();
           objUpdateMembers.previous();
           objUpdateMembers.next();
           objUpdateMembers.cancel();
           objUpdateMembers.first();
           objUpdateMembers.updateMassCampaignMembers();
           objUpdateMembers.lastPageNo = 1;
           objUpdateMembers.pageNo = 1;
           objUpdateMembers.buttonDisable();
           
           objUpdateMembers.lastPageNo = 5;
           objUpdateMembers.pageNo = 2;
           objUpdateMembers.buttonDisable();
           objUpdateMembers.lastPageNo = 2;
           objUpdateMembers.pageNo = 2;
           objUpdateMembers.buttonDisable();

           objUpdateMembers.allCheckboxes = true;
           objUpdateMembers.last();
           objUpdateMembers.previous();
           objUpdateMembers.next();
           objUpdateMembers.first();
           objUpdateMembers.isStatusUpdate = true;
           objUpdateMembers.isBidProbabilityUpdate = true;
           objUpdateMembers.isCoveringProfessional = true;
           objUpdateMembers.isDatePresentationCompleted = true;
           objUpdateMembers.isSiteTour = true;
           objUpdateMembers.isDataRoomAccessGranted = true;
           objUpdateMembers.isDateCASignedUpdate = true;
           objUpdateMembers.isDateCIMSentUpdate = true;
           objUpdateMembers.isDateFlyerSent = true;
           objUpdateMembers.UpdateTable();
           objUpdateMembers.contextItem = false;
           //objUpdateMembers.doDeselectItem();
           objUpdateMembers.contextItem = true;
           //objUpdateMembers.doDeselectItem();
           objUpdateMembers.UpdateTable();
    }
}