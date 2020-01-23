global class SchedulePermissionHistoryWeekly implements Schedulable {
    global void execute(SchedulableContext sc) {
        final string DISPLAYNAME =  'displayName' ;
        PermissionHistoryReportEmailList__mdt disName = [Select Value__c from PermissionHistoryReportEmailList__mdt where MasterLabel =: DISPLAYNAME];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        string Url = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/displayPermissionHistoryWeekly';       
        final string TOLIST =  'WeeklyToList' ;
        List<PermissionHistoryReportEmailList__mdt> toAddresses = [Select Email_Ids__c from PermissionHistoryReportEmailList__mdt where MasterLabel =: TOLIST];
        string body = '<a href ="'+URL+'">SalesForce Permission History Weekly Export</a>';
       	String[] emailIds = toAddresses[0].Email_Ids__c.split(';');
		System.debug(emailIds);       
        mail.setToAddresses( emailIds); 
        mail.setSenderDisplayName(disName.Value__c);                 
        mail.setSubject('Permission History Weekly Report');
        mail.setHtmlBody(body);
        try{                  
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(exception e){
            apexpages.addmessage(new apexpages.message(apexpages.severity.error,e.getMessage()));
        } 
    }     
}