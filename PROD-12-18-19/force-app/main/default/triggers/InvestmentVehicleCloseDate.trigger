trigger InvestmentVehicleCloseDate on Investment_Vehicle_Close_Date__c (before delete, after update)  {

    if(Trigger.isBefore && Trigger.isDelete) {
        CSL_Handler_InvestmentVehicle.validateDeletion(Trigger.old);
    }   else if(Trigger.isAfter && Trigger.isUpdate) {
        CSL_Handler_InvestmentVehicle.updateCloseDates(Trigger.new, Trigger.oldMap);
    }


}