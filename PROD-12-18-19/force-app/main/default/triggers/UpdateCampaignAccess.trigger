/* 
This trigger sync private field from opportunity to Campaign which is used for sharing rule
and If New Child Opportunity is created it create Team member from Parent to child

*/

trigger UpdateCampaignAccess on Opportunity(after insert, after update) {


   map<id,boolean> mapCampIdAccess = new map<id,boolean>();
   map<id,list<Campaign>> mapLstCamp = new map<id,list<Campaign>>();
  // map<id,Id> mapParentOppOpp = new map<id,Id>();
   list<Campaign> lstCampaign = new list<Campaign>();
    map<id,list<Opportunity>> mapOpptoChildOpp = new map<id,list<Opportunity>>();
   
   //Get all opportunity
   if(trigger.Isupdate)
   {
   for(Campaign cItem : [select Id,Private__c,Original_Deal_Opportunity__c  from Campaign where Original_Deal_Opportunity__c IN :Trigger.newMap.keySet()]) 
    {  
    	
       list<Campaign> lstTempCamp = new list<Campaign>();
       if(mapLstCamp.containskey(cItem.Original_Deal_Opportunity__c))
       {
         lstTempCamp = mapLstCamp.get(cItem.Original_Deal_Opportunity__c);
       }  
       lstTempCamp.add(cItem);  
       //Create a map of Opportunity as key and values as campaign list
       mapLstCamp.put(cItem.Original_Deal_Opportunity__c,lstTempCamp);  
     }
   }
     //Sync Private field on opportunity and campaign
    for(Opportunity objOpp: trigger.new) 
    {   
      //to check if Opportunity is child or parent
      if(trigger.Isinsert && objOpp.Parent_Opportunity__c!=null)
      {
    	 list<Opportunity> tempList = new list<Opportunity>();
    	 //Create a map of Parent Opp id as key and list of child opp as value 
    	 if(mapOpptoChildOpp.Containskey(objOpp.Parent_Opportunity__c))
    	 {
    	     tempList = mapOpptoChildOpp.get(objOpp.Parent_Opportunity__c);
    	 }
    	 tempList.add(objOpp);
    	 mapOpptoChildOpp.put(objOpp.Parent_Opportunity__c,tempList);
    	 // mapOppOwnerid.put(objOpp.Parent_Opportunity__c,objOpp.Ownerid);
      }
      else if(trigger.Isupdate)
      {
      	  //Sync campaign 
	      if(mapLstCamp.containskey(objOpp.id))  
	      {   
	        for(Campaign cItem : mapLstCamp.get(objOpp.Id)) 
	         {
	          cItem.Private__c = objOpp.private__c;
	          lstCampaign.add(cItem);
	         }  
	       } 
      }
     }
    
    try
    {
    	//Opportunity Team member transfer
    	if(trigger.Isinsert)
        {
          map<Id,list<OpportunityTeamMember>> mapOppTeamChild = new  map<Id,list<OpportunityTeamMember>>();
	      list<OpportunityTeamMember> lstTeamShare  = new list<OpportunityTeamMember>();
	      //Get parent Opp with All its Child opp and its team member
	      for(Opportunity objOppTeamMember: [Select (Select UserId, TeamMemberRole, OpportunityAccessLevel From OpportunityTeamMembers), (Select Id From Opportunities__r) From Opportunity o where  Id in:mapOpptoChildOpp.keyset()] )
	      {
	         list<OpportunityTeamMember> lstTempTeam = new list<OpportunityTeamMember>();
	      	//Loop to pull out one by one team mber
	      	for(OpportunityTeamMember objTem : objOppTeamMember.OpportunityTeamMembers)
	      	{
	      		//Releated child opp
	      	  for(Opportunity objOpp : objOppTeamMember.Opportunities__r)
	      	  {
	      	  	//each Child opp will have all team meber which parent opp have
	      	    OpportunityTeamMember otm = new OpportunityTeamMember(TeamMemberRole = objTem.TeamMemberRole, OpportunityId = objOpp.Id, UserId = objTem.UserId);
		        lstTeamShare.add(otm);
		        if(mapOppTeamChild.containskey(objOpp.Id))
		        {
		           lstTempTeam = mapOppTeamChild.get(objOpp.Id);
		        
		        }
	      	    lstTempTeam.add(objTem);
	      	    //Map of Child Opp Id and list of Team member for child opp
	      	    mapOppTeamChild.put(objOpp.id,lstTempTeam);
	      	  }
	      	
	      	}
	      	
	      }
	      if(lstTeamShare.size()>0)
	       insert lstTeamShare;
	       //Get all child opp sharing records
	       List<OpportunityShare> oppShareList = [SELECT id,OpportunityId, UserOrGroupId, OpportunityAccessLevel, RowCause FROM OpportunityShare
                                               WHERE OpportunityId = : trigger.newmap.keySet() AND RowCause = 'Team' ];
             /* 
	         Setting OpportunityAccessLevel here. We need to use OpportunityShare object 
	         because OpportunityTeamMember.OpportunityAccessLevel field is not writable
	        */
	       
				 /** BF-25: Opportuntiy Share is no longer writeable most likely due to udpated sharing rules

				 for(OpportunityShare oppShare : oppShareList)
	       {
	       	 for(OpportunityTeamMember objTeam : mapOppTeamChild.get(oppShare.OpportunityId))
	       	 {
						if(objTeam.UserId == oppShare.UserOrGroupId && Schema.sObjectType.OpportunityShare.fields.OpportunityAccessLevel.isUpdateable())
	       	// it is for setting opportunity access level
	          oppShare.OpportunityAccessLevel = objTeam.OpportunityAccessLevel;
	       	 }
	       }
	       //Update Opporutnity sharing for Access level
	       update oppShareList;
				 **/
				 
     }else
     {
    	//Update Campaign records
      if(lstCampaign.size()>0)
        update lstCampaign;
     }
    }
    catch(exception ex)
    {
     //Catch the error
     for(Opportunity objOpp: trigger.new) 
     {
       objOpp.adderror(ex.getmessage());
     } 
    }
}