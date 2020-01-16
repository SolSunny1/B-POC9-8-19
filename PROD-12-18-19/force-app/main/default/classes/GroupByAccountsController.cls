Public Class GroupByAccountsController {
     transient List<Account_Summary__c > lstKeyAccountsWithSummary = new List<Account_Summary__c >();
     // public List<Account> lstKeyAccounts = new List<Account>();
    public Map<String,list<Account_Summary__c>> objectMap {get; set;}
    
    public void loadKeyAccounts() {
        
        Date d = system.today().addDays(-31);
        
                          
        lstKeyAccountsWithSummary = [SELECT Id,Account_Summary__c,Account__r.Name,Country__c,Name,Property__c,Property__r.name,Status__c,lastModifiedDate,Location__c 
                                        FROM Account_Summary__c 
                                        WHERE LastModifiedDate > :d  order by  Status__c, Location__c , Property__r.name ];
                                        //WHERE Account__c IN :lstKeyAccounts  order by  Status__c, Location__c , Property__r.name ];
                                        
        objectMap  = new Map<String,list<Account_Summary__c>>();
        for(Account_Summary__c a : lstKeyAccountsWithSummary ){
           if(objectMap.keySet().contains(a.Account__r.Name) ){
               objectMap.get(a.Account__r.Name).add(a);
           }
           else{
               objectMap.put(a.Account__r.Name,new list<Account_Summary__c >());
               objectMap.get(a.Account__r.Name).add(a);
           } 
        }
        
        System.debug('++++++++++++++objectMap+++++++++++++ :'+objectMap);
    }
    
    public pageReference renderAsPdf(){
        PageReference pageRef = new PageReference('/apex/GroupByAccountReportPdf');
            pageRef .setRedirect(true);
            return pageRef;
    }
}