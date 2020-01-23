@isTest

public class Test_UpdateCompanyBackground {
       
    public static testMethod void createNewAccount() {        
    Account TestAccount = new Account();
    TestAccount.Name = 'Test Account for Testing';
    TestAccount.Company_Background__c = 'Initial Company background';
    TestAccount.QI_Status_Notes__c = 'Initial QI Status Note';      
    insert TestAccount;
        
    Compliance__c TestCompliance = new Compliance__c();
    TestCompliance.Prospect_Name__c = TestAccount.Id;
    TestCompliance.Company_Background__c = '';    
    insert TestCompliance;
    
    TestAccount.Company_Background__c = 'Updated Company Background'; 
    TestAccount.QI_Status_Notes__c = 'Updated QI Status Note';
    update TestAccount; 
    }   
    }