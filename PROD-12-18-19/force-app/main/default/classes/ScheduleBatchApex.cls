global with sharing class ScheduleBatchApex implements Schedulable {
    global void execute(SchedulableContext sc) {
        ID BatchId = Database.executeBatch(new batchAccountUpdate(), 200);
    }
 
    Public static void SchedulerMethod() {
        string timeinterval1 = '0 0 * * * ?';
        string timeinterval2 = '0 30 * * * ?';
        if(!test.isRunningTest()){
          System.schedule('BatchAccountUpdate1',timeinterval1 , new ScheduleBatchApex());
          System.schedule('BatchAccountUpdate2',timeinterval2, new ScheduleBatchApex());
        }
        }
    }

//We can use developer console to execute this method. Just execute below statement to call the method  
//ScheduleBatchApex.SchedulerMethod();