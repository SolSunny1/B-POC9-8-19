@isTest
private class ConfigurableRollupTest {
    
    static testMethod void rollupTestBAMUnitsSharesRUFilterInsertUpdate() {
        test.startTest();
        Configurable_RollUp_Setting__c crs = new Configurable_RollUp_Setting__c(name = 'configurableRollUpSetting',Relationship_Field_API_Name__c = 'Investor_Position_Account__c',Source_Field__c = 'BAM_Units_Shares_RU_Filter__c',Source_Object_Name__c = 'Investor_Position__c',Sum__c = true,Target_Field__c = 'BAM_Units_Shares__c');
        insert crs;
        
        Account ac = new Account(Name = 'TestAccount');
        insert ac;
        
        String recType = [Select Id from RecordType where Name = 'Listed Issuers' And SobjectType ='Investor_Position__c' limit 1].id; 
        
        Investment_Vehicle__c iv = new Investment_Vehicle__c(Name = 'InvestmentVehicleName'); 
        insert iv;
        

        //SS: 7/18/18 added following line of code for code coverage
        Opportunity opt = new Opportunity(Name = 'NewTestOpportunity', StageName ='2 - Initiated General Contact', CloseDate = system.today() , Investment_Vehicle__c = iv.id, AccountId = ac.id,  Consultant__c = ac.id  );
        insert opt; 

        //SS: 7/18/18 updated following line of code for code coverage
        Investor_Position__c ip = new Investor_Position__c(Is_Active__c = true,Ticker__c = 'BAM',RecordTypeId = recType,Investment_Vehicle__c = iv.id ,Investor__c = ac.id,Investor_Position_Account__c = ac.id, Opportunity_Name__c = opt.id);
        insert ip;
        
        Account account = [select Id, Name , BAM_Units_Shares__c from account where id =:ac.id];
        system.assertEquals(0.0,account.BAM_Units_Shares__c);
        
        //SS: 7/18/18 updated following line of code for code coverage
        Investor_Position__c ip1 = new Investor_Position__c(id = ip.id, Is_Active__c = false,Ticker__c = 'BAM',RecordTypeId = recType,Investment_Vehicle__c = iv.id ,Investor__c = ac.id,Investor_Position_Account__c = ac.id, Opportunity_Name__c = opt.id);
        update ip1;
        
        Account account1 = [select Id, Name , BAM_Units_Shares__c from account where id =:ac.id];
        system.assertEquals(0.0,account1.BAM_Units_Shares__c);
        
        test.stopTest(); 
    }
    
    static testMethod void rollupTestBEPUnitsSharesRUFilter() {
        test.startTest();
        Configurable_RollUp_Setting__c crs = new Configurable_RollUp_Setting__c(name = 'configurableRollUpSetting1',Relationship_Field_API_Name__c = 'Investor_Position_Account__c',Source_Field__c = 'BEP_Units_Shares_RU_Filter__c',Source_Object_Name__c = 'Investor_Position__c',Sum__c = true,Target_Field__c = 'BEP_Units_Shares__c');
        insert crs;
        
        Account ac = new Account(Name = 'TestAccount');
        insert ac;
        
        String recType = [Select Id from RecordType where Name = 'Listed Issuers' And SobjectType ='Investor_Position__c' limit 1].id; 
        
        Investment_Vehicle__c iv = new Investment_Vehicle__c(Name = 'InvestmentVehicleName'); 
        insert iv;
        
        //SS: 7/18/18 added following line of code for code coverage
        Opportunity opt = new Opportunity(Name = 'NewTestOpportunity', StageName ='2 - Initiated General Contact', CloseDate = system.today() , Investment_Vehicle__c = iv.id, AccountId = ac.id,  Consultant__c = ac.id  );
        insert opt; 

        //SS: 7/18/18 updated following line of code for code coverage
        Investor_Position__c ip = new Investor_Position__c(Is_Active__c = true,Ticker__c = 'BEP',RecordTypeId = recType,Investment_Vehicle__c = iv.id ,Investor__c = ac.id,Investor_Position_Account__c = ac.id, Opportunity_Name__c = opt.id);
        insert ip;
        
        Account account = [select Id, Name , BEP_Units_Shares__c from account where id =:ac.id];
        
        test.stopTest();
        system.assertEquals(0.0,account.BEP_Units_Shares__c);
    }

    static testMethod void rollupTestBIMTotalAUMRUFilter(){
        test.startTest();
        Configurable_RollUp_Setting__c crs = new Configurable_RollUp_Setting__c(name = 'configurableRollUpSetting2',Relationship_Field_API_Name__c = 'Investor_Position_Account__c',Source_Field__c = 'BIM_Total_AUM_RU_Filter__c',Source_Object_Name__c = 'Investor_Position__c',Sum__c = true,Target_Field__c = 'BIM_Total_AUM__c');
        insert crs;
        
        Account ac = new Account(Name = 'TestAccount');
        insert ac;
        
        String recType = [Select Id from RecordType where DeveloperName = 'Public_Securities' And SobjectType ='Investor_Position__c' limit 1].id; 
        
        Investment_Vehicle__c iv = new Investment_Vehicle__c(Name = 'InvestmentVehicleName'); 
        insert iv;
        
        //SS: 7/18/18 added following line of code for code coverage
        Opportunity opt = new Opportunity(Name = 'NewTestOpportunity', StageName ='2 - Initiated General Contact (PSG)', CloseDate = system.today() , Investment_Vehicle__c = iv.id, AccountId = ac.id,  Consultant__c = ac.id  );
        insert opt; 

        //SS: 7/18/18 updated following line of code for code coverage
        Investor_Position__c ip = new Investor_Position__c(Is_Active__c = true,RecordTypeId = recType,Investment_Vehicle__c = iv.id ,Investor__c = ac.id,Investor_Position_Account__c = ac.id, Opportunity_Name__c = opt.id);
        insert ip;
        
        Account account = [select Id, Name , BIM_Total_AUM__c from account where id =:ac.id];
        
        test.stopTest();
        system.assertEquals(0.0,account.BIM_Total_AUM__c);
    }

    static testMethod void rollupTestBIPUnitsSharesRUFilter(){
        test.startTest();
        Configurable_RollUp_Setting__c crs = new Configurable_RollUp_Setting__c(name = 'configurableRollUpSetting3',Relationship_Field_API_Name__c = 'Investor_Position_Account__c',Source_Field__c = 'BIP_Units_Shares_RU_Filter__c',Source_Object_Name__c = 'Investor_Position__c',Sum__c = true,Target_Field__c = 'BIP_Units_Shares__c');
        insert crs;
        
        Account ac = new Account(Name = 'TestAccount');
        insert ac;
        
        String recType = [Select Id from RecordType where Name = 'Listed Issuers' And SobjectType ='Investor_Position__c' limit 1].id; 
        
        Investment_Vehicle__c iv = new Investment_Vehicle__c(Name = 'InvestmentVehicleName'); 
        insert iv;
        
        //SS: 7/18/18 added following line of code for code coverage
        Opportunity opt = new Opportunity(Name = 'NewTestOpportunity', StageName ='2 - Initiated General Contact', CloseDate = system.today() , Investment_Vehicle__c = iv.id, AccountId = ac.id,  Consultant__c = ac.id  );
        insert opt; 

        //SS: 7/18/18 updated following line of code for code coverage
        Investor_Position__c ip = new Investor_Position__c(Is_Active__c = true, Ticker__c = 'BIP',RecordTypeId = recType,Investment_Vehicle__c = iv.id ,Investor__c = ac.id,Investor_Position_Account__c = ac.id, Opportunity_Name__c = opt.id);
        insert ip;
        
        Account account = [select Id, Name , BIP_Units_Shares__c from account where id =:ac.id];
        
        test.stopTest();
        system.assertEquals(0.0,account.BIP_Units_Shares__c);
    }
}