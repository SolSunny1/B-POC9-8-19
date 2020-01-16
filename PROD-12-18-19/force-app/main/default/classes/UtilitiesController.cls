public with sharing class UtilitiesController{
    
    public void runRollUpBatch(){
        Database.executeBatch(new UtilityBatch('rollupFields'), 10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Batch process scheduled to rollup.'));
    }
    public void runPopulateInvestorPositionAccountBatch(){
        Database.executeBatch(new UtilityBatch('populateInvestorPositionAccount'), 10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Batch process scheduled to populate Investor Position Account.'));
    }
    
}