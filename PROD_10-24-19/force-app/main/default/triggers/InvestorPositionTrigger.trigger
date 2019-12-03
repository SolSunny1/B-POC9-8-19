trigger InvestorPositionTrigger on Investor_Position__c (after insert, after update, after delete) {

Set<Id> numofhistinvestors = new Set<Id>(); 
Set<Id> numofcurrentinvestors = new Set<Id>(); 
Set<Id> InvestmentVehicleIds = new Set<Id>(); 

List<Investment_Vehicle__c> lstUpdateInvVehicle = new List<Investment_Vehicle__c>();

if(trigger.isafter)
{
    //if(RecursiveHandler.flag)
    //{
       // RecursiveHandler.flag = false;
        if(trigger.isinsert || trigger.isupdate)
        {
            
                for(Investor_Position__c inv : Trigger.New)
                {
                    InvestmentVehicleIds.add(inv.Investment_Vehicle__c);
                }    
        }   
        if(trigger.isdelete)
        {
            
                for(Investor_Position__c inv : Trigger.old)
                {
                    InvestmentVehicleIds.add(inv.Investment_Vehicle__c);
                }    
        }       
       
       /*************************************************************************************
       *  Begaining of SOQL 101 issue fix code  
       ************************************************************************************/
        Map<String,Integer> numofcurrentinvestorsMap = new Map<String,Integer>();
        Map<String,Integer> numofhistinvestorsMap = new Map<String,Integer>();

        for( Investor_Position__c obj : [Select Id,Investor_Position_Account__c,Is_Active__c, Current_Commitments_Functional__c, Source_of_Capital__c,
                                        Investment_Vehicle__r.Id, Investment_Vehicle__r.Number_of_Current_Investors__c, Investment_Vehicle__r.Number_of_Historical_Investors__c
                                        from Investor_Position__c where Investment_Vehicle__r.Id IN:InvestmentVehicleIds])
        {
            
            if(obj.Is_Active__c == TRUE && obj.Source_of_Capital__c != null)
            {                       
            
                if(obj.Current_Commitments_Functional__c > 0 && (obj.Source_of_Capital__c.contains('Limited Partners') || obj.Source_of_Capital__c.contains('Operating Partner')))
                {
                    if(numofcurrentinvestorsMap!=null && numofcurrentinvestorsMap.containsKey(obj.Investment_Vehicle__r.Id)){
                        numofcurrentinvestorsMap.put(obj.Investment_Vehicle__r.Id,numofcurrentinvestorsMap.get(obj.Investment_Vehicle__r.Id)+1);
                    }else{
                        numofcurrentinvestorsMap.put(obj.Investment_Vehicle__r.Id,1);
                    }
                    //numofcurrentinvestors.add(obj.Investor_Position_Account__c);  
                }
                if(obj.Source_of_Capital__c.contains('Limited Partners') || obj.Source_of_Capital__c.contains('Operating Partner'))
                {
                    if(numofhistinvestorsMap!=null && numofhistinvestorsMap.containsKey(obj.Investment_Vehicle__r.Id)){
                        numofhistinvestorsMap.put(obj.Investment_Vehicle__r.Id,numofhistinvestorsMap.get(obj.Investment_Vehicle__r.Id)+1);
                    }else{
                        numofhistinvestorsMap.put(obj.Investment_Vehicle__r.Id,1);
                    }
                    //numofhistinvestors.add(obj.Investor_Position_Account__c); 
                }
            }                   
        }
        System.debug('Map numofcurrentinvestorsMap: ' + numofcurrentinvestorsMap.size());
        System.debug('Map numofhistinvestorsMap: ' + numofhistinvestorsMap.size());
        System.debug('Map numofcurrentinvestorsMap: ' + numofcurrentinvestorsMap);
        System.debug('Map numofhistinvestorsMap: ' + numofhistinvestorsMap);            
        for(Id id : InvestmentVehicleIds)
        {    
            Investment_Vehicle__c invveh = new Investment_Vehicle__c();
            invveh.Id = id;
            if(numofhistinvestorsMap.containsKey(id)){
                invveh.Number_of_Historical_Investors__c = numofhistinvestorsMap.get(id);
                 System.debug('invveh.Number_of_Historical_Investors__c: ' + invveh.Number_of_Historical_Investors__c);
            } else {
                invveh.Number_of_Historical_Investors__c = 0;
            }
            
            if(numofcurrentinvestorsMap.containsKey(id)){
                invveh.Number_of_Current_Investors__c = numofcurrentinvestorsMap.get(id);
                 System.debug('invveh.Number_of_Current_Investors__c: ' + invveh.Number_of_Current_Investors__c);
            }else {
                invveh.Number_of_Current_Investors__c = 0;
            }
            
            lstUpdateInvVehicle.add(invveh);
             System.debug('invveh.Number_of_Historical_Investors__c: ' + invveh);
            //numofcurrentinvestors.clear();
            //numofhistinvestors.clear();
        }  
        System.debug('lstUpdateInvVehicle : ' + lstUpdateInvVehicle.size());
       
       /*************************************************************************************
       *  SS: 7/18/18 - End of SOQL 101 issue fix code  
       ************************************************************************************/
        try
        {
            if(lstUpdateInvVehicle.size() > 0)
            {
                update lstUpdateInvVehicle; 
            }
                
        }
        catch(exception ex)
        {
            for (Investor_Position__c obj : trigger.new) 
            {         
                obj.addError(ex.getmessage());        
            } 
        }      
    //}   
    
}

    if(Trigger.isInsert){
        ConfigurableRollup.rollup(trigger.new);
    }
    if(Trigger.isUpdate){
        system.debug('when is update------');
        ConfigurableRollup.rollup(trigger.new, Trigger.OldMap);
    }
    if(Trigger.isDelete){
        ConfigurableRollup.rollup(trigger.old);
    }
}