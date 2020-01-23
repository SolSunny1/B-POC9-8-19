trigger NewPermissionEvent on Permission_Event__e (after insert) {
	System.Debug('start NewPermissionEvent');
    final string COMMUNITYNAME = 'INVESTORCOMMUNITYNAME';
	//select Id, name, Contact__r.Name, Account_Vehicle__r.Name, fund__r.Name, Permission_Type__r.Name from Permission__c where Id = 'a3d4F000000DGBKQA4'
	Set<id> permissionIds = new Set<id>();
    for (Permission_Event__e event : Trigger.New)
    {
		System.Debug('Permission Id ' + event.Permission_Id__c);
        
        permissionIds.add(event.Permission_Id__c);
	}
    
	Map<id, Permission__c> permissions = new Map<id, Permission__c>([select Id, name, Contact__c, Contact__r.DX_Email__c,Contact__r.Email,Contact__r.FirstName, Contact__r.LastName, Account_vehicle__c, Account_Vehicle__r.Legal_Entity_Legal_Name__c, Fund__r.Id, Fund__r.Platform__c, fund__r.Name, fund__r.DX_Integration__c, Permission_Type__r.Name, Alert_Status__c, Status__c, Start_Date__c, End_Date__c from Permission__c where Id in:permissionIds and (Contact__r.DX_Email__c <> '' or Contact__r.Email <> '')]);
	//Map<id, Permission__c> permissions = new Map<id, Permission__c>([select Id, name, Contact__c, Contact__r.DX_Email__c,Contact__r.Email,Contact__r.FirstName, Contact__r.LastName, Account_vehicle__c, Account_Vehicle__r.Name, Fund__r.Id, Fund__r.Platform__c, fund__r.Name,Permission_Type__r.Name, Alert_Status__c, Status__c, Start_Date__c, End_Date__c,Fund__r.DX_Integration__c from Permission__c where Id in:permissionIds and (Contact__r.DX_Email__c <> '' or Contact__r.Email <> '')]);
    List<PermissionUpdate__c> toInsert = new List<PermissionUpdate__c>();
    System.debug('toInsert count ' + toInsert.size() +  ' permission count ' + permissions.size());
    CommunityName__mdt commNameMapping = [Select Name__c from CommunityName__mdt where MasterLabel =: COMMUNITYNAME];
    List<Id> contactToUpdate = new List<Id>();
	for (Permission__c perm : permissions.values())
    {
        System.debug('Contact first name ' + perm.contact__r.FirstName);
        
        PermissionUpdate__c pu = new PermissionUpdate__c();
        //TODO Cloud Theory to add flag to contact
        pu.ContactActive__c = true;
        pu.ContactFirstName__c = perm.Contact__r.FirstName;
        pu.ContactLastName__c = perm.Contact__r.LastName;
        if(perm.Contact__r.DX_Email__c != null && perm.Contact__r.DX_Email__c !='')
            {
            	pu.ContactEmail__c = perm.Contact__r.DX_Email__c;
            }
        else
            {
                pu.ContactEmail__c = perm.Contact__r.Email;
                contactToUpdate.add(perm.Contact__c);
            }           
        pu.ContactExternalId__c = perm.Contact__c;
        
        pu.FundName__c = perm.Fund__r.Name;
        //TODO, map properly as per Joshy's email
        pu.FundAssetClass__c = perm.Fund__r.Platform__c;
        pu.FundExternalId__c = perm.Fund__r.Id;        
        pu.InvestorName__c = perm.Account_Vehicle__r.Legal_Entity_Legal_Name__c;
        pu.InvestorExternalId__c = perm.Account_Vehicle__r.Id;        
        pu.Community__c = commNameMapping.Name__c;
        
        pu.GroupName__c = perm.Permission_Type__r.Name;
        pu.GroupAccess__c = perm.Status__c == 'Active';
        pu.GroupNotification__c = perm.Alert_Status__c == 'Active';
        pu.GroupStartDate__c = perm.Start_Date__c;
        pu.GroupEndDate__c = perm.End_Date__c;
         //Send DX_Integartoin Active when Investment Vehile is activated
        pu.SendInvitationEmail__c = perm.Fund__r.DX_Integration__c  =='Active';
        try {
            toInsert.add(pu);
        }
         catch (exception e) {                
                system.debug('#### Exception caught: ' + e.getMessage());                
            }
    }
    try
    {
    insert toInsert;
        //Update Contact
     if(contactToUpdate.size() >0)
     {
        List<Contact> Contacts = [Select Id,DX_Email__c,Email from Contact where ID IN : contactToUpdate ];
         List<Contact> cToUpdate = new List<Contact>();
         for(Contact c : Contacts){
             if(c.Email  != null && c.Email !='' )
             {
                 c.DX_Email__c = c.Email;
                 cToUpdate.add(c);
             }
         }
         System.debug('Updating Contact---' + contactToUpdate);
         update cToUpdate;
     }
    System.Debug('end NewPermissionEvent');
    }
     catch (exception e) {
                
                system.debug('#### Exception caught: ' + e.getMessage());                
            }
}