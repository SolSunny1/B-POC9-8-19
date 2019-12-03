@isTest
private class TEST_Contact_OwnerAssignment{
     static testmethod void contactOwnerAssignment() {
         Account a = new Account(Name = 'test Account');
         insert a;
         
         Contact c = new Contact(LastName = 'Goel');
         c.MailingState = 'PA';
         insert c;
         
         Contact c2 = new Contact(LastName = 'Goel');
         c2.MailingState = 'PA';
         c2.MailingPostalCode = '10001';
         insert c2;
     }
}