@isTest(SeeAllData=false)
public with sharing class TEST_PlatformEvent {
    private static testMethod void Test_Permission() {
        Contact contact = new Contact(FirstName='FirstName', LastName='Test Contact');
        insert contact;

        Test.startTest();

        Permission__c permission = new Permission__c(Contact__c=contact.Id);
        insert permission;

        Test.getEventBus().deliver();

        update permission;

        Test.getEventBus().deliver();

        Test.stopTest();
    }
}