global class BatchBlankUpdateCompliance implements 
    Database.Batchable<sObject>, Database.Stateful {
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    //string BIM = label.PSG_Compliance_Record_Type;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID FROM Compliance__c ' + 
            'Where RecordTypeId = \''+ Label.PSG_Compliance_Record_Type+'\' '
        );
    }
   global void execute(Database.BatchableContext bc, List<Compliance__c> scope){
        // process each batch of records
        List<Compliance__c> compList = New List<Compliance__c>();
        for (Compliance__c comp : scope) {
            compList.add(comp);
            recordsProcessed = recordsProcessed + 1;
            }
        update compList;
    }    
   global void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + ' records processed. Shazam!');
        
   }
      
}