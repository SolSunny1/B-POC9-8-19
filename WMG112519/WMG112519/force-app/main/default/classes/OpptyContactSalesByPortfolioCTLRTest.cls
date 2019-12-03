@isTest
private class OpptyContactSalesByPortfolioCTLRTest {
    static testmethod void methodOpptyContactSalesByPortfolioCTLRTest () {
        Account objAccount = new Account();
        objAccount.Name = 'Test Account';
        insert objAccount;
        Contact objContact=new Contact(Lastname='Test Contact',accountid=objAccount.Id);
        insert objContact;
        opportunity objOppty=new opportunity();
        objOppty.accountid=objAccount.Id;
        objOppty.CloseDate=system.today();
        objOppty.Name='Test Oppty';
        objOppty.StageName='In Progress';
        objOppty.Amount=200;
        objOppty.Probability=20;
        objOppty.Type='New Business';
        objOppty.Contact__c=objContact.id;
        objOppty.Start_Date__c=system.today();
        insert objOppty;
        SalesConnect__Contact_Portfolio_Breakdown__c objSalesConnect=new SalesConnect__Contact_Portfolio_Breakdown__c();
        objSalesConnect.SalesConnect__Contact__c=objContact.id;
        objSalesConnect.Name='test';
        insert objSalesConnect;
        ApexPages.StandardController objController=new ApexPages.StandardController(objOppty);
        OpportunityContactRole objOpportunityContactRole=new OpportunityContactRole(ContactId=objContact.id,OpportunityId=objOppty.id);
        objOpportunityContactRole.role='Business User';
        objOpportunityContactRole.IsPrimary=true;
        insert objOpportunityContactRole;
        
        OpptyContactSalesByPortfolioController objOpptyContactSalesByPortfolioController=new OpptyContactSalesByPortfolioController(objController);
        objOpptyContactSalesByPortfolioController.submit();
        apexpages.currentpage().getparameters().put('selected',objSalesConnect.Id);
        objOpptyContactSalesByPortfolioController.submit();
        
        objOpptyContactSalesByPortfolioController.cancel();
    }
}