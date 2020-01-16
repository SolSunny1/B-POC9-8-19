/******************************************
Class Name - AccountSummaryReportController
Created by - Samir Khan
Description - This class is written for generating Account Summary Report 
******************************************/

Public Class AccountSummaryReportController{

    //public List<Account> lstKeyAccounts = new List<Account>(); 
    transient  List<Account_Summary__c > lstKeyAccountsWithSummary = new List<Account_Summary__c >();
    public Map<String, Map<String, List<Account_Summary__c >>> objectMap {get; set;}
    
    public void loadKeyAccounts() {
        Date d = system.today().addDays(-31);
        
       // System.debug('+++++++lstKeyAccounts +++++++++ : '+lstKeyAccounts );                  
        lstKeyAccountsWithSummary = [SELECT Id,Account_Summary__c,Account__r.Name,Country__c,Name,Property__c,Property__r.name,Status__c,lastModifiedDate,Location__c
                                        FROM Account_Summary__c 
                                     WHERE LastModifiedDate > :d order by Status__c , Account__r.Name ];
        System.debug('+++++++lstKeyAccountsWithSummary +++++++++ : '+lstKeyAccountsWithSummary  );                                     
        
          
          objectMap  = new Map<String, Map<String, List<Account_Summary__c >>>();
          
          
          for(Account_Summary__c a : lstKeyAccountsWithSummary ){
              if(objectMap.keyset().contains(a.Location__c)){
                    if(objectMap.get(a.Location__c).keyset().contains(a.property__r.name)){
                        objectMap.get(a.Location__c).get(a.property__r.name).add(a);
                    }
                    else{
                        objectMap.get(a.Location__c).put(a.property__r.name,new List<Account_Summary__c>());
                        objectMap.get(a.Location__c).get(a.property__r.name).add(a);
                    
                    }
                    
              }
              else{
                
                objectMap.put(a.Location__c,new Map<String,List<Account_Summary__c>>());
                objectMap.get(a.Location__c).put(a.property__r.name,new List<Account_Summary__c >());
                objectMap.get(a.Location__c).get(a.property__r.name).add(a);
                
                
              }
          
          }
    }  
    
    public pageReference renderAsPdf(){
        PageReference pageRef = new PageReference('/apex/AccountSummaryReportPdf');
            pageRef .setRedirect(true);
            return pageRef;
    }  
    
}