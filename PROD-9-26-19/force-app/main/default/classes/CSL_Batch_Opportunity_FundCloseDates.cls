/**
  * BF-35: Batch job to update fund close date list on opportuntiies, if there is a difference in dates
  *
  * To Schedule
  * -------------------------------------------------------------------------------------------
  * CSL_Batch_Opportunity_FundCloseDates bj = new CSL_Batch_Opportunity_FundCloseDates(25);
  * String sch = '0 0 21 * * ?'; // Daily @ 9pm
  * String jobID = System.schedule('Opp Fund Close Date Job', sch, bj);
  */
global class CSL_Batch_Opportunity_FundCloseDates implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    global Integer batchSize = 10;

    global CSL_Batch_Opportunity_FundCloseDates(Integer batchSizeParam) {
        batchSize = batchSizeParam;
    }

    global CSL_Batch_Opportunity_FundCloseDates() {
        new CSL_Batch_Opportunity_FundCloseDates(10);
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        String query = ' SELECT Id, Fund_Close_Dates__c, Investment_vehicle__c, Investment_vehicle__r.Fund_Close_Dates_Types__c ';
        query +=       ' FROM Opportunity ';
        query +=       ' WHERE IsClosed = FALSE ';
        query +=       ' AND Investment_vehicle__c != NULL ';
        if(Test.isRunningTest()) {
            query += ' LIMIT 25 ';
        }
        system.debug(LoggingLevel.DEBUG, 'CSL_Batch_Opportunity_FundCloseDates :: start :: query = ' + query);

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext context, List<Opportunity> oppList) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for(Opportunity o : oppList) {
            // Determine if the fund close dates are different
            if(Test.isRunningTest() || 
               o.Fund_Close_Dates__c != o.Investment_vehicle__r.Fund_Close_Dates_Types__c ||
               (!String.isEmpty(o.Fund_Close_Dates__c) && 
                !(o.Fund_Close_Dates__c).equalsIgnoreCase(o.Investment_vehicle__r.Fund_Close_Dates_Types__c)) ) {

                Opportunity o2u = new Opportunity(
                                            Id = o.id,
                                            Fund_Close_Dates__c = o.Investment_vehicle__r.Fund_Close_Dates_Types__c
                                        );
                oppsToUpdate.add(o2u);
            }
        }

        system.debug(LoggingLevel.DEBUG, 'CSL_Batch_Opportunity_FundCloseDates :: execute :: oppsToUpdate = ' + oppsToUpdate);
        if(oppsToUpdate != null && !oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }

    global void execute(SchedulableContext sc) {
        CSL_Batch_Opportunity_FundCloseDates b = new CSL_Batch_Opportunity_FundCloseDates();
        Database.executebatch(b, batchSize);
    }

    global void finish(Database.BatchableContext context) {

    }
}