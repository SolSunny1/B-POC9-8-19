public class CSL_Handler_InvestmentVehicle {

    /**
      * BF-27: Update the close date field on any opportunities that are related to an investment vehicle close date where the date has changed
      */
    public static void updateCloseDates(List<Investment_Vehicle_Close_Date__c> invCloseDateList, Map<Id, Investment_Vehicle_Close_Date__c> oldMap) {
        // Build a unique set of invoice close date ids where the close date has changed
        Map<Id, Investment_Vehicle_Close_Date__c> invCloseDateUpdateMap = new Map<Id, Investment_Vehicle_Close_Date__c>();
        for(Investment_Vehicle_Close_Date__c invCloseDate : invCloseDateList) {
            // Ensure the close date is not blank and it has changed
            if(oldMap != null && oldMap.containsKey(invCloseDate.Id) &&
               null != invCloseDate.Close_Date__c &&
               oldMap.get(invCloseDate.Id).Close_Date__c != invCloseDate.Close_Date__c) {
               invCloseDateUpdateMap.put(invCloseDate.Id, invCloseDate);
            }
        }
        system.debug(LoggingLevel.DEBUG, 'CSL_Handler_InvestmentVehicle :: updateCloseDate :: invCloseDateUpdateMap= ' + invCloseDateUpdateMap);

        if(invCloseDateUpdateMap.size() > 0) {
            try {
                // Query opportunitiy for any oppty's linked to close dates
                List<Opportunity> oppList = [SELECT Id, Investment_Vehicle_Close_Date__c
                                             FROM Opportunity
                                             WHERE Investment_Vehicle_Close_Date__c IN :invCloseDateUpdateMap.keySet()];
                system.debug(LoggingLevel.DEBUG, 'CSL_Handler_InvestmentVehicle :: updateCloseDate :: oppList= ' + oppList);

                // Iterate through the opportunities and update the close dates
                for(Opportunity opp : oppList) {
                    Investment_Vehicle_Close_Date__c closeDate = invCloseDateUpdateMap.get(opp.Investment_Vehicle_Close_Date__c);
                    opp.CloseDate = closeDate.Close_Date__c;
                }

                update oppList;
            }   catch (Exception e) {
                system.debug(LoggingLevel.ERROR, 'CSL_Handler_InvestmentVehicle :: updateCloseDate :: invCloseDateUpdateMap.keySet() = ' + invCloseDateUpdateMap.keySet());
                system.debug(LoggingLevel.ERROR, 'CSL_Handler_InvestmentVehicle :: updateCloseDate :: e.getMessage() ' + e.getMessage());
            }
        }

    }

    /**
      * BF-27: Ensure there are no related opportunities before a deletion is allowed to occur
      */
    public static void validateDeletion(List<Investment_Vehicle_Close_Date__c> invCloseDateList) {
        // Build a unique set of invoice close date ids
        Set<Id> invCloseDateIds = new Set<Id>();
        for(Investment_Vehicle_Close_Date__c invCloseDate : invCloseDateList) {
            invCloseDateIds.add(invCloseDate.Id);
        }
        system.debug(LoggingLevel.DEBUG, 'CSL_Handler_InvestmentVehicle :: validateDeletion :: invCloseDateIds= ' + invCloseDateIds);

        try {
            // Query opportunitiy for any oppty's linked to close dates
            List<Opportunity> oppList = [SELECT Id, Investment_Vehicle_Close_Date__c
                                         FROM Opportunity
                                         WHERE Investment_Vehicle_Close_Date__c IN :invCloseDateIds];
            system.debug(LoggingLevel.DEBUG, 'CSL_Handler_InvestmentVehicle :: validateDeletion :: oppList= ' + oppList);

            // For the dates that had related opportunities add an error
            List<Investment_Vehicle_Close_Date__c> preventDeletes = new List<Investment_Vehicle_Close_Date__c>();
            for(Investment_Vehicle_Close_Date__c invCloseDate : invCloseDateList) {
                for(Opportunity opp : oppList) {
                    if(opp.Investment_Vehicle_Close_Date__c != null &&
                       opp.Investment_Vehicle_Close_Date__c == invCloseDate.Id) {
                       invCloseDate.addError(Label.Investment_Close_Date_Delete_Validation);
                       break;
                    }
                }
            }

        }   catch (Exception ex) {
            system.debug(LoggingLevel.ERROR, 'CSL_Handler_InvestmentVehicle :: validateDeletion :: No related opportunities found for these close dates: ' + invCloseDateIds);
            system.debug(LoggingLevel.ERROR, 'CSL_Handler_InvestmentVehicle :: validateDeletion :: ex.getMessage() ' + ex.getMessage());
        }
    }

}