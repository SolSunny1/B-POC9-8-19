global class CommonUtility
{
     public static set<Id> IsTriggerUpdate = null;

  // This method is used by trigger AddRemoveApexSharing on insert operation
  // This methods create sharing records for existing campaign records
  @future(callout=true)
  public static void processSharing(set<id> setids)
  {    
        OpportunityTeamMember obj2 = new OpportunityTeamMember(); 
        //This to track the changes on sharing object
        list<Sharing_History__c> lstSharingHistory = new list<Sharing_History__c>();
        //set for opportunity ids
        set<Id> setOppIds= new set<Id>();
        //get all required fields info of new Opportunity team member 
        map<id,list<OpportunityTeamMember>>  mapOppwithNoCampaignlistTeam = new  map<id,list<OpportunityTeamMember>>();
        map<id,list<Opportunity>>  mapOppwithPartId = new  map<id,list<Opportunity>>();
        list<OpportunityTeamMember>  lstAlTeam = [select id, UserId,OpportunityId,TeamMemberRole,Opportunity.Ownerid, OpportunityAccessLevel from OpportunityTeamMember where Id in:setids];
        for(OpportunityTeamMember objOppTeamMember: lstAlTeam)
        {  
           list<OpportunityTeamMember> lstTempTeam = new list<OpportunityTeamMember>(); 
           if(mapOppwithNoCampaignlistTeam.containskey(objOppTeamMember.OpportunityId))
           {
             lstTempTeam  = mapOppwithNoCampaignlistTeam.get(objOppTeamMember.OpportunityId);
           }      
           lstTempTeam.add(objOppTeamMember);
           mapOppwithNoCampaignlistTeam.put(objOppTeamMember.OpportunityId, lstTempTeam);         
           //To check if Opportunity owner not included in Opportunity Team members
       // if(objOppTeamMember.UserId != objOppTeamMember.Opportunity.Ownerid) - comented out - we need to track deal team for the owner too        
           setOppIds.add(objOppTeamMember.OpportunityId);
                      
        }
        
        list<Opportunity> lstOppDealTeam = [Select Id,(Select Id,ownerid,Name From Opportunities__r),(Select  Name,User.Alias From OpportunityTeamMembers) From Opportunity where id In: setOppIds];
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
            mapOppwithPartId.put(objOpportunity.Id,objOpportunity.Opportunities__r);
        
        }
        //Get all campaigns associated with opportunity Team member opportunity
        list<Campaign> lstCampaign = [select id,Original_Deal_Opportunity__c from Campaign where Original_Deal_Opportunity__c In:setOppIds];
        list<CampaignShare> lstCampaignShare = new list<CampaignShare>();
         
        // list<OpportunityShare> lstOpportunityShare = new list<OpportunityShare>();
        for(OpportunityTeamMember objOppTeamMember: lstAlTeam )
        {
               system.debug(objOppTeamMember+'----objOppTeamMember---');
               for(Campaign objCamp: lstCampaign )
               {
                if(mapOppwithNoCampaignlistTeam.containskey(objCamp.Original_Deal_Opportunity__c))
                  mapOppwithNoCampaignlistTeam.remove(objCamp.Original_Deal_Opportunity__c);
                    //Create object of sharing history to insert sharing details
                   
                    Sharing_History__c objShareHis = new Sharing_History__c();
                    objShareHis.Access_Level__c = objOppTeamMember.OpportunityAccessLevel;
                    objShareHis.Opportunity__c = objOppTeamMember.OpportunityId;
                    objShareHis.User_or_Group__c = objOppTeamMember.UserId;
                    objShareHis.Action__c = 'Created';
                    objShareHis.Campaign__c = objCamp.Id;
                    objShareHis.User_Role__c = objOppTeamMember.TeamMemberRole;             
                    lstSharingHistory.add(objShareHis);
                    
                   //New sharing records will be created for each campaign as per opportunity Team member   
                    system.debug(objOppTeamMember.OpportunityAccessLevel+'-----objOppTeamMember.OpportunityAccessLevel---'+objCamp);
                    CampaignShare obj = new CampaignShare();
                    obj.UserOrGroupId = objOppTeamMember.UserId;
                    obj.CampaignAccessLevel = objOppTeamMember.OpportunityAccessLevel;
                    obj.CampaignId = objCamp.Id;
                    lstCampaignShare.add(obj);
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
                    objShareHis.Action__c = 'Created';                  
                    objShareHis.User_Role__c = objTeam.TeamMemberRole;              
                    lstSharingHistory.add(objShareHis);
                }
        
            }
        }
         if(lstOppDealTeam.size()>0)
          update lstOppDealTeam;
         if(lstCampaignShare.size()>0)
          insert lstCampaignShare;
         if(lstSharingHistory.size()>0)
          insert lstSharingHistory;
  
  }
  // This method is used by trigger AddRemoveApexSharing on Update operation
  // This methods create sharing records for existing campaign records and exiting Oppotunity Team members which are being updated
   @future(callout=true)
   public static void UpdateprocessSharing(set<id> setids)
  {
       //This to track the changes on sharing object
        list<Sharing_History__c> lstSharingHistory = new list<Sharing_History__c>();
         //get all required fields info of updated Opportunity team member 
        list<OpportunityTeamMember>  lstAlTeam = [select id, UserId ,OpportunityId,TeamMemberRole, OpportunityAccessLevel from OpportunityTeamMember where Id in:setids];
        map<Id,list<OpportunityTeamMember>> mapOpplistTeam = new map<Id,list<OpportunityTeamMember>>();
        map<Id,list<OpportunityTeamMember>> mapOppwithNoCampaignlistTeam = new map<Id,list<OpportunityTeamMember>>();
        list<CampaignShare> lstUpdateCampaignShare = new list<CampaignShare >();
        
        //Create a map to associate all Opportunity Team member with key with Opportunity Id
        for(OpportunityTeamMember objOppTeamMember: lstAlTeam )
        {   
           list<OpportunityTeamMember> lstTempTeam = new list<OpportunityTeamMember>(); 
           if(mapOpplistTeam.containskey(objOppTeamMember.OpportunityId))
           {
             lstTempTeam  = mapOpplistTeam.get(objOppTeamMember.OpportunityId);
           }      
           lstTempTeam.add(objOppTeamMember);
           mapOpplistTeam.put(objOppTeamMember.OpportunityId, lstTempTeam);
        }  
        mapOppwithNoCampaignlistTeam = mapOpplistTeam;
        map<id,list<OpportunityShare>> mapOppwithPartId = new map<id,list<OpportunityShare>>();
         for(OpportunityShare objOpportunity :[Select o.UserOrGroupId, o.Opportunity.Parent_Opportunity__c, o.OpportunityId, o.OpportunityAccessLevel,  o.Id From OpportunityShare o where o.Opportunity.Parent_Opportunity__c In: mapOpplistTeam.keyset() and o.RowCause!='Rule'])
        {
            list<OpportunityShare> lstTemp = new list<OpportunityShare>();
            if(mapOppwithPartId.containskey(objOpportunity.Opportunity.Parent_Opportunity__c))
            {
             lstTemp = mapOppwithPartId.get(objOpportunity.Opportunity.Parent_Opportunity__c);
            }
            lstTemp.add(objOpportunity);
            mapOppwithPartId.put(objOpportunity.Opportunity.Parent_Opportunity__c,lstTemp);
        
        }
        system.debug(mapOppwithPartId+'---mapOppwithPartId--'+mapOppwithPartId.size());
        //Get all campaign share and Campaign associated with opportunity
        for(Campaign objCamp: [select id,Original_Deal_Opportunity__c,  (Select Id, CampaignId, UserOrGroupId From Shares) from Campaign where Original_Deal_Opportunity__c In:mapOpplistTeam.keyset()])
        {
            if(mapOppwithNoCampaignlistTeam.containskey(objCamp.Original_Deal_Opportunity__c))
              mapOppwithNoCampaignlistTeam.remove(objCamp.Original_Deal_Opportunity__c);
          //for loop on share records 
          for(CampaignShare objShare :objCamp.Shares)
          {
            if(mapOpplistTeam.containskey(objCamp.Original_Deal_Opportunity__c))
            //Get opporutnity Team member by opportunity ids
            for(OpportunityTeamMember objTeam : mapOpplistTeam.get(objCamp.Original_Deal_Opportunity__c))
            {
                
               //only update campaign share records which was created for given Opporunity Team member
               if(objShare.UserOrGroupId == objTeam.UserId)
               {
                    Sharing_History__c objShareHis = new Sharing_History__c();
                    objShareHis.Access_Level__c = objTeam.OpportunityAccessLevel;
                    objShareHis.Opportunity__c = objTeam.OpportunityId;
                    objShareHis.User_or_Group__c = objTeam.UserId;
                    objShareHis.Action__c = 'Updated';
                    objShareHis.Campaign__c = objCamp.Id;
                    objShareHis.User_Role__c = objTeam.TeamMemberRole;              
                    lstSharingHistory.add(objShareHis);
                    
                    objShare.CampaignAccessLevel = objTeam.OpportunityAccessLevel ;
                   lstUpdateCampaignShare.add(objShare);
               }
            }
          
          }
        }
       // list<OpportunityShare> listOppShareUpdate = new list<OpportunityShare>();
        if(mapOppwithNoCampaignlistTeam.size()>0)
        {
            for(Id OppId : mapOppwithNoCampaignlistTeam.keyset())
            {
                for(OpportunityTeamMember objTeam : mapOppwithNoCampaignlistTeam.get(OppId))
                {
                
                    Sharing_History__c objShareHis = new Sharing_History__c();
                    objShareHis.Access_Level__c = objTeam.OpportunityAccessLevel;
                    objShareHis.Opportunity__c = OppId;
                    objShareHis.User_or_Group__c = objTeam.UserId;
                    objShareHis.Action__c = 'Updated';                  
                    objShareHis.User_Role__c = objTeam.TeamMemberRole;              
                    lstSharingHistory.add(objShareHis);
                }
            }
          }        
           
      /*  for(OpportunityTeamMember objTeam : lstAlTeam)
        {
            if(mapOppwithPartId.containsKey(objTeam.OpportunityId))
            {
              list<OpportunityShare> listOppShare = mapOppwithPartId.get(objTeam.OpportunityId);
              system.debug(listOppShare.size()+'----listOppShare---'+listOppShare);
              for(OpportunityShare objOpportunityShare: listOppShare)
              {
                system.debug(objTeam.UserId+'-1---listOppShare---'+objOpportunityShare.UserOrGroupId);
                if(objTeam.UserId == objOpportunityShare.UserOrGroupId)
                {
                  objOpportunityShare.OpportunityAccessLevel  = objTeam.OpportunityAccessLevel;
                  listOppShareUpdate.add(objOpportunityShare);
                }
              }
            
            }                   
        }
            */
      //system.debug(listOppShareUpdate+'---listOppShareUpdate--'+listOppShareUpdate.size());
        
        //Update campaign share records
        if(lstUpdateCampaignShare.size()>0)
         update lstUpdateCampaignShare;
        if(lstSharingHistory.size()>0)
          insert lstSharingHistory;
  
        //if(listOppShareUpdate.size()>0)
       // update listOppShareUpdate;
     }
     //Its part of method to get role subordinate
      public  set<Id> getSubordinateRoles(Id roleId) {
        map<Id, set<Id>> parentAndChildren = new map<Id, set<Id>>();
        set<Id> children;
        for(UserRole ur : [select Id, ParentRoleId from UserRole]) {
            children = parentAndChildren.containsKey(ur.ParentRoleId) ? parentAndChildren.get(ur.ParentRoleId) : new set<Id>();
            children.add(ur.Id);
            parentAndChildren.put(ur.ParentRoleId, children);
        }
        return getSubordinateRoles(roleId, parentAndChildren);
      }
      
    
    //This method convert set into string for dynamic query
     public String quoteKeySet(Set<Id> KeySet)
     {
        String newSetStr = '' ;
        for(Id str : KeySet)
            newSetStr += '\'' + str + '\',';

        newSetStr = newSetStr.lastIndexOf(',') > 0 ? '(' + newSetStr.substring(0,newSetStr.lastIndexOf(',')) + ')' : newSetStr ;
       System.debug('quoteKeySet() :  newSetStr ============ ' + newSetStr);   

        return newSetStr;

     }
     //This method used to create a set of role subordinate  
      public  set<Id> getSubordinateRoles(Id roleId, map<Id, set<Id>> parentAndChildren) 
      {
            set<Id> subordinateRoles = new set<Id>();
            set<Id> remainingSubordinateRoles = new set<Id>();
           if(parentAndChildren.containsKey(roleId)) 
           {
              subordinateRoles.addAll(parentAndChildren.get(roleId));
                for(Id subRoleId : subordinateRoles) 
                {
                   remainingSubordinateRoles.addAll(getSubordinateRoles(subRoleId, parentAndChildren));
                }
             }
            subordinateRoles.addAll(remainingSubordinateRoles);
            return subordinateRoles;
       }
      
       //Get all the role
      public static List<SelectOption> Roles() 
      {
        List<SelectOption> lsrRole = new List<SelectOption>();
        lsrRole.add(new SelectOption('','All'));
        for(UserRole obj: [Select Id, Name from UserRole])       
        {
          lsrRole.add(new SelectOption(obj.Id,obj.Name));
        }
        return lsrRole;
     }
}