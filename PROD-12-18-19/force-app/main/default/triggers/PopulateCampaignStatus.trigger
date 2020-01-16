/*
 This trigger prepopulate the status of Campaign members from custom setting and delete by default setting
 It also create sharing records for campaign based on opportunity Team members
 It also populate private field from opportunity

Modified By : Khoushik on 03/06/2014 for Automatically populating Campaign Member Status based on Record Type.
Modified by: Sunny Solanki on 06/06/2019 updated to incorporate new Campaign record types. (line # 99 and 170)  
*/

trigger PopulateCampaignStatus on Campaign (before insert,after insert) {
  list<Sharing_History__c> lstSharingHistory = new list<Sharing_History__c>();   
    
    Set<Id> removeCampaignIDs = new Set<ID>();
    Set<Id> setOppIDs = new Set<ID>();
    //loop to get Opportunity id and campaign Id
     for (Campaign cItem : trigger.new) 
    {         
        removeCampaignIDs.add(cItem.id);
        setOppIDs.add(cItem.Original_Deal_Opportunity__c);                
    }
    if(trigger.IsInsert && trigger.IsBefore)
    {
      map<id,boolean> mapOppIdAccess = new map<id,boolean>();
      //Get opportunity private value in a map
      for(Opportunity objOpportunity : [select id,Private__c from Opportunity where id in:setOppIDs])
      {
          mapOppIdAccess.put(objOpportunity.Id,objOpportunity.Private__c);
      }
      //sync Private value of campaign from Opportunity 
      for (Campaign cItem : trigger.new) 
      {
        if(mapOppIdAccess.containskey(cItem.Original_Deal_Opportunity__c))
        {
          cItem.Private__c = mapOppIdAccess.get(cItem.Original_Deal_Opportunity__c);
        }
        
        
      }
    }
    else if(trigger.Isafter)
    {
          list<CampaignShare> lstCampaignShare = new list<CampaignShare>();
          //get all opportunity Team members based on Opportunity
        for(OpportunityTeamMember objOppTeamMember: [select id, UserId,OpportunityId,TeamMemberRole,Opportunity.Ownerid, OpportunityAccessLevel from OpportunityTeamMember where OpportunityId in:setOppIDs] )
        {
          for(Campaign objCamp: trigger.new )
          {
            if(objCamp.Ownerid !=objOppTeamMember.UserId)
            {  
                //Crate sharing history to track sharing
                Sharing_History__c objShareHis = new Sharing_History__c();
                objShareHis.Access_Level__c = objOppTeamMember.OpportunityAccessLevel;
                objShareHis.Opportunity__c = objOppTeamMember.OpportunityId;
                objShareHis.User_or_Group__c = objOppTeamMember.UserId;
                objShareHis.Action__c = 'Created';
                objShareHis.Campaign__c = objCamp.Id;
                objShareHis.User_Role__c = objOppTeamMember.TeamMemberRole;
                //Create sharing records based on existing opportunity team members
                system.debug(objOppTeamMember.OpportunityAccessLevel+'-----objOppTeamMember.OpportunityAccessLevel---'+objCamp);
                CampaignShare obj = new CampaignShare();
                obj.UserOrGroupId = objOppTeamMember.UserId;
                obj.CampaignAccessLevel = objOppTeamMember.OpportunityAccessLevel;
                obj.CampaignId = objCamp.Id;
                
                lstSharingHistory.add(objShareHis);
                lstCampaignShare.add(obj);
            }
          }
        }
        Database.SaveResult[] result = Database.insert(lstCampaignShare, false);
    }
    //List to create new campaignmemberstatus record
    list<CampaignMemberStatus> newCMStatus = new list<CampaignMemberStatus>();
    //To delete exiting status record
    list<CampaignMemberStatus> delCMStatus = new list<CampaignMemberStatus>();
    
    map<id,list<CampaignMemberStatus>> mapCS = new map<id,list<CampaignMemberStatus>>();
     list<CampaignStatus__c> csList = new list<CampaignStatus__c>();
     
    //get data from custom setting
    csList = CampaignStatus__c.getAll().Values();
    
   //Added by Khoushik on 03/06/2015 
 
 
    list<CampaignStatus__c> csPFGList = new list<CampaignStatus__c>();
  	// added by Joe C
    list<CampaignStatus__c> csPSGList = new list<CampaignStatus__c>();
    list<CampaignStatus__c> csBFINList = new list<CampaignStatus__c>();
    list<CampaignStatus__c> csfinalList = new list<CampaignStatus__c>();
    // added by Joe C 
	list<CampaignStatus__c> csAlternative_FundsList = new list<CampaignStatus__c>(); 
    // added by Joe C Sept 9, 2019
	list<CampaignStatus__c> csTestList = new list<CampaignStatus__c>();
    // added by Joe C 
	list<CampaignStatus__c> csBRPList = new list<CampaignStatus__c>(); 
      
    for(CampaignStatus__c lst: csList)
    {
                //SS: 6/6/9- updated to incorporate new Campaign record types.
                if(lst.Campaign_Record_Type__c.contains('PFG'))
                {
                    csPFGList.add(lst); 
                    }
         		// added by Joe C
                if(lst.Campaign_Record_Type__c.contains(';PSG;'))
                {
                    csPSGList.add(lst); 
                    }
                 // added by Joe C
                if(lst.Campaign_Record_Type__c.contains(';Alternative'))
                {
                    csAlternative_FundsList.add(lst); 
                    }
                 // added by Joe C
                if(lst.Campaign_Record_Type__c.contains(';BRP;'))
                {
                    csBRPList.add(lst); 
                    }
                
                if(lst.Campaign_Record_Type__c.contains(';BFIN;') || lst.Campaign_Record_Type__c.contains(';BFIN_Traditional;'))
                {
                    csBFINList.add(lst);    
                }
        		// added by Joe C Sept 9, 2019
        		if(lst.Campaign_Record_Type__c.contains(';Test'))
                {
                    csBRPList.add(lst); 
                }
    }
    
    //Query for the Campaign record types
    List<RecordType> rtypes = [Select Name, Id From RecordType
                  where sObjectType='Campaign' and isActive=true];

   //Create a map between the Record Type Name and Id for easy retrieval
    Map<String,String> campaignRecordTypes = new Map<String,String>{};

    for(RecordType rt: rtypes)
         campaignRecordTypes.put(rt.Name,rt.Id);
    
   //End of Code change
    
    //Get all the campaign id to process                
    //get all existing status records from database associated with campaigns
    //Keep all status in a map associated with key as campaign id
    for(CampaignMemberStatus obj: [select cms.id,cms.label,cms.CampaignId
                    from CampaignMemberStatus cms
                    where cms.CampaignId in :removeCampaignIDs ] )
    {
      list<CampaignMemberStatus> lstCaS = new list<CampaignMemberStatus>();
      if(mapCS.containskey(obj.CampaignId))
      {
        lstCaS = mapCS.get(obj.CampaignId);
      }
      lstCaS.add(obj);
      mapCS.put(obj.CampaignId,lstCaS);
    }
    //Process all status record and check if the data existing are by default or data is coming from clone
    for(Id ids :mapCS.keyset())
    {
        
    //if there are only 2 record per campaign its mean these data are default and need to be removed
      if(mapCS.get(ids).size()==2)
      {
        for(CampaignMemberStatus objCampaignMemberStatus : mapCS.get(ids))
        {
          //Added by Khoushik - 03/06/2015
          //Get appropriate Campaign Status list based on Campaign Record Type. 
          // Check here next       
          Campaign campaign = [select recordtypeId from campaign where Id=:objCampaignMemberStatus.CampaignId];
          //SS: 6/6/9- updated to incorporate new Campaign record types.
          //SS: 9-9-19 Removed  "|| campaign.recordtypeId == campaignRecordTypes.get('PFG Events')"" 
          if(campaign.recordtypeId == campaignRecordTypes.get('PFG')|| campaign.recordtypeId == campaignRecordTypes.get('PFG Annual Investor Conference (BPFAIC)'))
          {
            csfinalList = csPFGList;
            
           // Joe: Sept 2019- updated to incorporate new Test Campaign record types.
           // SS: 9/9/19 removed "|| campaign.recordtypeId == campaignRecordTypes.get('Test')""
          if(campaign.recordtypeId == campaignRecordTypes.get('Test'))
          {
            csfinalList = csTestList;
			} 
          // SS: 9/9/19 commented out next else if statement since BRP Campaign is not longer used. Also, removed "|| campaign.recordtypeId == campaignRecordTypes.get('BRP')"
		  /*else if (campaign.recordtypeId == campaignRecordTypes.get('BRP') )
		  { 
			csfinalList = csBRPList; 
			} */
          // SS: 9/9/19 removed "|| campaign.recordtypeId == campaignRecordTypes.get('PSG')""
          else if (campaign.recordtypeId == campaignRecordTypes.get('PSG') ){
            csfinalList = csPSGList;
          }     
          // SS: 9/9/19 removed "|| campaign.recordtypeId == campaignRecordTypes.get('Alternative_Funds')"    
          else if (campaign.recordtypeId == campaignRecordTypes.get('Alternative_Funds')){
            csfinalList = csAlternative_FundsList;
          }
         // Added    
         else if (campaign.recordtypeId == campaignRecordTypes.get('BFIN') || campaign.recordtypeId == campaignRecordTypes.get('BFIN_Traditional')){
            csfinalList = csBFINList;
          }
            //End of Code change 
          for(CampaignStatus__c csItem : csfinalList)
          {
          		//Make sure the sort order does not match any existing sort order or a Duplicate error will occur
                newCMStatus.add (new CampaignMemberStatus(
                CampaignId = objCampaignMemberStatus.CampaignId,
                HasResponded = csItem.HasResponded__c,
                IsDefault = csItem.IsDefault__c,
                Label = csItem.name,
                SortOrder = integer.valueOf(csItem.SortOrder__c)));    
           }
           //list of delete status record
           delCMStatus.add(objCampaignMemberStatus);                    
        }     
      }     
    }
  
    try{
        if(lstSharingHistory.size()>0)
        {
          insert lstSharingHistory;
        }
        if(newCMStatus.size()>0)
        {
         insert newCMStatus;    
        }
        if(delCMStatus.size()>0)
        {
          delete delCMStatus;
        }
        }catch(exception ex)
        {
            for (Campaign cItem : trigger.new) 
            {         
                cItem.addError(ex.getmessage());        
            } 
        }
    
}}