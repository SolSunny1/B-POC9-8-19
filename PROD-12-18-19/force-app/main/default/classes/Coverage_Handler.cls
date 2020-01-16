//This class is a helper class for Coverage Trigger
//It set the Coverage fields on Accounts to NUll on the deletaion of any Coverage data from Coverage form	
public class Coverage_Handler {
    public void updateCoverageOnAccount(List<Coverage__c> lstCoverage) {    
        Set<Id> infrastructurelst = new Set<Id>();
        Set<Id> realEstatelst = new Set<Id>();
        Set<Id> privateEquitylst = new Set<Id>();		
        Set<Id> accIdLst = new Set<Id>();
        for(Coverage__c c : lstCoverage)
        {
            accIdLst.add(c.Account__c);
            if(c.Business_Group__c == 'Real Asset / Infra'){
				infrastructurelst.Add(c.Account__c);                
            }
            if(c.Business_Group__c == 'Private Equity'){
                privateEquitylst.Add(c.Account__c);
            }  
            if(c.Business_Group__c == 'Real Estate'){            
				realEstatelst.Add(c.Account__c);  
            }
        }
       
        List<Account> accToUpdate = new List<Account>(); 
        for(Account acc : [Select PFG_CRM_Real_Asset_Lead__c,PFG_CRM_Primary_Lead__c,PFG_CRM_Secondary__c from Account where id In : accIdLst])
        {                    
            if(infrastructurelst.size() > 0 && infrastructurelst.contains(acc.id)){                
                acc.PFG_CRM_Real_Asset_Lead__c = null;                
            }
            if(privateEquitylst.size() > 0 && privateEquitylst.contains(acc.id)){
                acc.PFG_CRM_Secondary__c = null;                
            }
            if(realEstatelst.size() > 0 && realEstatelst.contains(acc.id)){
                acc.PFG_CRM_Primary_Lead__c = null;                
            }
            accToUpdate.add(acc);
        }
        try
        {
        	update accToUpdate;
        }
        catch(exception ex)
    	{     
       		system.debug('#### Exception caught: ' + ex.getMessage());
     	}
    }   
}