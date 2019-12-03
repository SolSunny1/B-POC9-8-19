/*
  This trigger create update and delete campaign share records based on OpportunityTeam members

*/

trigger AddRemoveApexSharing on OpportunityTeamMember (after insert,after update, before delete) 
{
    set<Id> setIds= new set<Id>();
    list<OpportunityTeamMember> lstTempOppTeamMember = new list<OpportunityTeamMember>();    
   
  //Create campaign share records if campaign records already exist based on Opportunity Team member
   if(trigger.IsInsert)
   { 
        CommonUtility.processSharing(trigger.newmap.keyset());
        
   }
   //Update campaign share records if campaign records already exist based on Opportunity Team member
   else if(trigger.isupdate)
   {
      CommonUtility.UpdateprocessSharing(trigger.newmap.keyset());
   }
   //Delete campaign share records if campaign records already exist based on deleted Opportunity Team member
   
   else if(trigger.Isdelete)
   {
      try{
      	   list<Sharing_History__c> lstSharingHistory = new list<Sharing_History__c>();
           map<Id,list<OpportunityTeamMember>> mapOpplistTeam = new map<Id,list<OpportunityTeamMember>>();
           list<CampaignShare> lstDelCampaignShare = new list<CampaignShare >();
           //Create map of Opportunity as key and opportunity team members as values list
            map<id,list<OpportunityTeamMember>>  mapOppwithNoCampaignlistTeam = new  map<id,list<OpportunityTeamMember>>();
           
            for(OpportunityTeamMember objOppTeamMember: trigger.old)
            { 
               list<OpportunityTeamMember> lstTempTeam = new list<OpportunityTeamMember>(); 
               if(mapOpplistTeam.containskey(objOppTeamMember.OpportunityId))
               {
                 lstTempTeam  = mapOpplistTeam.get(objOppTeamMember.OpportunityId);
               }      
               lstTempTeam.add(objOppTeamMember);
               mapOpplistTeam.put(objOppTeamMember.OpportunityId, lstTempTeam);
            }  
             map<id,list<OpportunityShare>> mapOppwithPartId = new map<id,list<OpportunityShare>>();
	        // list<OpportunityShare> listOppShareUpdate = new list<OpportunityShare>();
	     
	     //update Deal team
	       list<Opportunity> lstOppDealTeam = [Select Id,(Select User.Alias, Name From OpportunityTeamMembers where Id Not In:trigger.oldmap.keyset() ) From Opportunity where id In: mapOpplistTeam.keySet()];
	        for(Opportunity objOpportunity :lstOppDealTeam)
	        {
	        	//Populate all Opportunity Team member name on Opportunity Deal team
	        	string usrName = '';
	        	for(OpportunityTeamMember objOpportunityTeamMember: objOpportunity.OpportunityTeamMembers)
	        	{
	        	 usrName = usrName+ objOpportunityTeamMember.User.Alias +', ';
	        	}
	        	if(usrName.contains(','))
	        	usrName = usrName.removeEnd(', ');
	        	objOpportunity.Deal_Team__c = usrName;	        
	        }
	       
            mapOppwithNoCampaignlistTeam = mapOpplistTeam.clone();
            //Get all the shares records and Campaign associated with Oportunity id
            for(Campaign objCamp: [select id,Original_Deal_Opportunity__c,  (Select Id, CampaignId, UserOrGroupId From Shares) from Campaign where Original_Deal_Opportunity__c In:mapOpplistTeam.keyset()])
            {
              if(mapOppwithNoCampaignlistTeam.containskey(objCamp.Original_Deal_Opportunity__c))
        	  mapOppwithNoCampaignlistTeam.remove(objCamp.Original_Deal_Opportunity__c);

              system.debug('AddRemoveApexSharing :: trigger.isDelete :: objCamp.Shares=' + objCamp.Shares);
              for(CampaignShare objShare : objCamp.Shares)
              {
              	//Get Opportunity team member
               if(mapOpplistTeam.containsKey(objCamp.Original_Deal_Opportunity__c))
               
                system.debug('AddRemoveApexSharing :: trigger.isDelete :: mapOpplistTeam.get(objCamp.Original_Deal_Opportunity__c)=' + mapOpplistTeam.get(objCamp.Original_Deal_Opportunity__c));
                for(OpportunityTeamMember objTeam : mapOpplistTeam.get(objCamp.Original_Deal_Opportunity__c))
                {
                	//compare based on userid to delete share record
                   if(objShare.UserOrGroupId == objTeam.UserId)
                   {
                   	   //object to create share history records which track sharing chnages on records
	                   	Sharing_History__c objShareHis = new Sharing_History__c();
		            	objShareHis.Access_Level__c = 'None';
		            	objShareHis.Opportunity__c = objCamp.Original_Deal_Opportunity__c;
		            	objShareHis.User_or_Group__c = objShare.UserOrGroupId;
		            	objShareHis.Action__c = 'Deleted';
		            	objShareHis.Campaign__c = objCamp.Id;
		            	objShareHis.User_Role__c = objTeam.TeamMemberRole;            	
		            	//add to sharing list to create 
		            	lstSharingHistory.add(objShareHis);
		            	//add to delete list
                      lstDelCampaignShare.add(objShare);
                   }
                }
              
              }
            }
	      
             if(mapOppwithNoCampaignlistTeam.size()>0)
             {
            
	          for(Id OppId : mapOppwithNoCampaignlistTeam.keyset())
              {
	            for(OpportunityTeamMember objTeam : mapOppwithNoCampaignlistTeam.get(OppId))
	            {
	                Sharing_History__c objShareHis = new Sharing_History__c();
	            	objShareHis.Access_Level__c = objTeam.OpportunityAccessLevel;
	            	objShareHis.Opportunity__c = objTeam.OpportunityId;
	            	objShareHis.User_or_Group__c = objTeam.UserId;
	            	objShareHis.Action__c = 'Deleted';	            	
	            	objShareHis.User_Role__c = objTeam.TeamMemberRole;            	
	            	lstSharingHistory.add(objShareHis);
	            }
            }
            
            }
            if(lstOppDealTeam.size()>0)
            update lstOppDealTeam;
            if(lstSharingHistory.size()>0)
             insert lstSharingHistory;
           delete lstDelCampaignShare;
      }catch(exception ex)
      {
      	//add error message for any exception
        for(OpportunityTeamMember objOppTeamMember: trigger.old)
        {
           objOppTeamMember.addError(ex.getmessage());        
        }
     }
   }
   
}