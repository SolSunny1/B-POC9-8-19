/******************************************
Test Class Name - Test_ScheduleBatchApex
Created by - Samir Khan
Description - This test class is written for Schedular ScheduleBatchApex
******************************************/

@isTest
class Test_ScheduleBatchApex{
    public static testMethod void testSchedule(){
        ScheduleBatchApex testsche = new ScheduleBatchApex();
        string timeinterval = '0 0 23 * * ?';
        System.schedule('BatchAccountUpdate-Every15mins - Test',timeinterval, testsche );
        System.Schedule('scheduledApexBatchableCompliance - Test', timeinterval, new scheduledBatchableCompliance() );
        
        ScheduleBatchApex.SchedulerMethod();
    }
}