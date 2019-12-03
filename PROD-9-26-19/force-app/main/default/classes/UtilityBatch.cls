global class UtilityBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    
    private String batchToRun = '';
    
    
    
    global UtilityBatch(String batchToRun){
        this.batchToRun = batchToRun;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = '';
        
        if(batchToRun == 'rollupFields'){
        	query = 'Select Id, Investor_Position_Account__c from Investor_Position__c Where Investor_Position_Account__c != null';
        }else if(batchToRun == 'populateInvestorPositionAccount'){ 
        	query = 'Select Id, Investor_Position_Account__c, Investor__c from Investor_Position__c Where Investor__c != null';
        }
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> records) {
        try{
        	if(batchToRun == 'rollupFields'){
        		ConfigurableRollup.rollup((List<Investor_Position__c>) records);
        	}else if(batchToRun == 'populateInvestorPositionAccount'){
        		List<Investor_Position__c> investorPositionToUpdate  = new List<Investor_Position__c>();
        		for(Investor_Position__c investor: (List<Investor_Position__c>) records){
        			investor.Investor_Position_Account__c = investor.Investor__c;
        			investorPositionToUpdate.add(investor);
        		}
        		if(!investorPositionToUpdate.isEmpty()){
        			update investorPositionToUpdate;
        		}
        	}
                 
        }catch(Exception e){
            System.debug('-->Error in UtilityBatch, batchToRun : ' + batchToRun + e.getMessage());
        }
    }
     
    global void finish(Database.BatchableContext BC){
        
    }
}