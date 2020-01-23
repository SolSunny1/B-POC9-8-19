global class PermissionUpdateProcessor implements Schedulable, Database.AllowsCallouts {

    global void execute(SchedulableContext ctx)
    {
        System.Debug('start PermissionUpdateProcessor');
       
        UpdateDXIntegration.futureExecute();
        
        System.Debug('End PermissionUpdateProcessor');
    }   
   
}