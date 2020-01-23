/*
  This class is used for custom add default Team on opportunity Team member
  It fetch Team member from User Opportunity Team member related list and add to opportunity records

*/

global class AddDefaultTeamButtonFunctionality {
    webService static boolean addDefaultTeam(Id oppId, Id ownerIds) {
    list<UserTeamMember> utmList = [select Id, userid,OwneriD , TeamMemberRole, OpportunityAccessLevel  from UserTeamMember where OwneriD =:ownerIds];
    //If no User Team members are assign
     if(utmList.size() == 0)
       return false;
       List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
       Map<Id, String> userToAccessMap = new Map<Id, String>();
       
       //Add tema member from User to Opporutnity Team member
       
       for(UserTeamMember utm : utmList)
       {
         OpportunityTeamMember otm = new OpportunityTeamMember(TeamMemberRole = utm.TeamMemberRole, OpportunityId = oppId, UserId = utm.UserId);
          otmList.add(otm);
          userToAccessMap.put(utm.UserId, utm.OpportunityAccessLevel);
       }
       //Insert OpportunityTeamMember
       insert otmList;
       
       List<OpportunityShare> oppShareList = [SELECT id, UserOrGroupId, OpportunityAccessLevel, RowCause FROM OpportunityShare
                                               WHERE OpportunityId = : oppId AND RowCause = 'Team' AND userOrGroupId IN : userToAccessMap.keySet()];
        /* 
         Setting OpportunityAccessLevel here. We need to use OpportunityShare object 
         because OpportunityTeamMember.OpportunityAccessLevel field is not writable
        */
       
       /*
          BF-25: Disabled due to sharing updates, the share is no longer writeable

          for(OpportunityShare oppShare : oppShareList)
          {
            // it is for setting opportunity access level
              oppShare.OpportunityAccessLevel = userToAccessMap.get(oppShare.UserOrGroupId);
          }
          //Update Opporutnity sharing for Access level
          update oppShareList;
       */

       return true;
    }
}