public with sharing class Permission_Handler {
    private static Set<Id> setFiredIds = new Set<Id>();

    public void createPlatformEvents(List<Permission__c> lstPermissions) {
        system.debug('setFiredIds: ' + setFiredIds);
        Set<Id> setPermissionIds = new Set<Id>();
        List<Permission_Event__e> lstPermissionPlatformEvents = new List<Permission_Event__e>();
        for (Permission__c permission : lstPermissions) {
            if (!setFiredIds.contains(permission.Id)) {
                setPermissionIds.add(permission.Id);
                setFiredIds.add(permission.Id);
            }
        }
        if (setPermissionIds.size() > 0) {
            for (Permission__c permission : [select Id, Contact__c, Contact__r.Email, Fund__c, Permission_Type__c,Fund__r.DX_Integration__c from Permission__c where Id in :setPermissionIds
                                            						and Fund__r.DX_Integration__c IN: new List<String>{'Active','Planned'}]) {
                lstPermissionPlatformEvents.add(new Permission_Event__e(
                        Contact_Email__c = permission.Contact__r.Email,
                        Contact_Id__c = permission.Contact__c,
                        Fund_Id__c = permission.Fund__c,
                        Investment_Account_Id__c = '',
                        Investment_Id__c = '',
                        Permission_Id__c = permission.Id,
                        Permission_Type__c = permission.Permission_Type__c
                ));
            }

            if (lstPermissionPlatformEvents.size() > 0) {
                // Call method to publish events
                List<Database.SaveResult> results = EventBus.publish(lstPermissionPlatformEvents);

                // Inspect publishing result for each event
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully published event.');
                    } else {
                        for (Database.Error err : sr.getErrors()) {
                            System.debug('Error returned: ' +
                                    err.getStatusCode() +
                                    ' - ' +
                                    err.getMessage());
                        }
                    }
                }
            }
        }
    }
}