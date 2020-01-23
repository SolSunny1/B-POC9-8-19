/*
  Trigger to track the history of fields update controller by custom setting
  it also update other campaign member records associated with same account if any of the records get update fields controlled by CampaignMemberFieldList__c custom setting
 Feb - 20 Updated by Bhagat
 Des:   1.	Remove Primary contact sync code from Create update and delete action of trigger
		2.	Replace for loop of trigger old with map
		3.	Remove code to sync other contact 

*/
trigger CampaignMemberHistoryTracking on CampaignMember (before insert,after update) 
{
	// This section of code check if there is any primary contact from a company if not it pick first contact of a company as Primary asociated with Campaign
    if(trigger.IsInsert)
	{
	 
 		   list<Campaign_Member_History__c> lstCMHistory = new list<Campaign_Member_History__c>();
		   list<CampaignMemberFieldList__c> lstCMFList = CampaignMemberFieldList__c.getAll().values();
           //This loop will make primary contact check box true for the company which dont have any
		   for(CampaignMember camMeb : trigger.New)
		   {
			 //Custom setting store fields information
		 	 for(CampaignMemberFieldList__c objFieldApi :lstCMFList) {
		 	   //if record is set for tracking and value is not empty and it is not Status field  
		 	   if(objFieldApi.IsHistory_Track__c && camMeb.get(objFieldApi.Name) != null && objFieldApi.Name != 'Status')
		 	   {
		 	   	  //if custom setting is true for the field then create Campaign_Member_History__c record
		 	       Campaign_Member_History__c objHistory = new Campaign_Member_History__c();
		 	       objHistory.Campaign__c= camMeb.CampaignId;
		 	       objHistory.Campaign_Member_SFDC_Id__c = camMeb.Id;
		 	       objHistory.Contact__c = camMeb.contactId;
		 	       //Field label store in custom setting
		 	       objHistory.Field_Name__c = objFieldApi.Field_Label__c;
		 	       //new value from trigger new
		 	       objHistory.New_Value__c = string.valueof(camMeb.get(objFieldApi.Name));
		 	       objHistory.Record_Modified_by__c = UserInfo.getUserId();
		 	       lstCMHistory.add(objHistory);
	 	   	    }
		 	 }
		  }
		  
		  //create history records
		  if(lstCMHistory.size()>0) {
		  	insert lstCMHistory;
		  }
		  
	}
	else if(trigger.IsUpdate)
	{
		list<CampaignMemberFieldList__c> lstCMFList = CampaignMemberFieldList__c.getAll().values();
		list<Campaign_Member_History__c> lstCMHistory = new list<Campaign_Member_History__c>();
		map<string,list<CampaignMember>> mapAccIdCampMembers = new map<string,list<CampaignMember>>();
	    map<string,CampaignMember> mapChangeCampMembers = new map<string,CampaignMember>();
		//set<id> idsCampMember = new set<id>();
		//set<id> idsCampIds = new set<id>();
	    set<string> uniqueFields = new set<string>();
		//loop on old and new to check which field values has been changed
		for(CampaignMember objCampMemberNew : trigger.New)
		{
		 	  //Custom setting store fields information
			 	 for(CampaignMemberFieldList__c objFieldApi :lstCMFList)
			 	 {
			 	 	//if record is same and value are different
			 	   if( objCampMemberNew.get(objFieldApi.Name)!=Trigger.oldMap.get(objCampMemberNew.Id).get(objFieldApi.Name) && !uniqueFields.contains(objCampMemberNew.Id+objFieldApi.name) )
			 	   {
			 	   	  //if custom setting is true for the field then create Campaign_Member_History__c record
			 	   	  if(objFieldApi.IsHistory_Track__c)
			 	   	  {
			 	       Campaign_Member_History__c objHistory = new Campaign_Member_History__c();
			 	       objHistory.Campaign__c= objCampMemberNew.CampaignId;
			 	       objHistory.Campaign_Member_SFDC_Id__c = objCampMemberNew.Id;
			 	       objHistory.Contact__c = objCampMemberNew.contactId;
			 	       objHistory.Field_Name__c = objFieldApi.Field_Label__c;
			 	       //new value from trigger new
			 	       objHistory.New_Value__c = string.valueof(objCampMemberNew.get(objFieldApi.Name));
			 	       objHistory.Old_Value__c = string.valueof(Trigger.oldMap.get(objCampMemberNew.Id).get(objFieldApi.Name));
			 	       objHistory.Record_Modified_by__c = UserInfo.getUserId();
			 	       lstCMHistory.add(objHistory);
			 	       //Set which make sure unique records created for each field change
			 	       uniqueFields.add(objCampMemberNew.Id+objFieldApi.name);
			 	   	  }
			 	   }		 	     
		 
		 	 }
		 
		}
		
		try
		{    
			
			//create history records
			if(lstCMHistory.size()>0)
			insert lstCMHistory;
			
		}
		catch(exception ex)
		{
			//Error handling
		  for(CampaignMember CampMem: trigger.old)
	        {
	           CampMem.addError(ex.getmessage());        
	        }
		}
		
	}
	
}