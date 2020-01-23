public with sharing class Activity_Controller_From_Opp {  
      
        private Opportunity Oppt;
        Public String currentOpp             {get;set;}
        Public user currentuser              {get;set;}
        Public Id ProfileId                  {get;set;}
        public Set<Id> idsForPlatformProfile {get;set;}

        Public class ActivityTable{
        Public Id Aid                        {get;set;}
        Public String Subject                {get;set;}
        Public Id AssignedTo                 {get;set;}
        Public String WhoName                {get;set;}
        Public Date Activitydate             {get;set;}
        Public String Status                 {get;set;} 
        Public Boolean isTask                {get;set;} 
        Public Boolean showLink              {get;set;}   
        Public String AssignedToName         {get;set;} 
        }        
        
        Public List<ActivityTable> OpenListPFORM      {get;set;}
        Public List<ActivityTable> HistoryListPFORM   {get;set;}
        
        Public List<ActivityTable> OpenList           {get;set;}
        Public List<ActivityTable> HistoryList        {get;set;}
        
        
        Public Activity_Controller_From_Opp(ApexPages.StandardController controller) {
              
        // 1. Get the ID of the Opportunity record
    
        Oppt = (Opportunity)controller.getRecord();
        Oppt =[Select Id, Share_with_PFG_Platform__c from Opportunity where Id=:Oppt.id];
        
        // 2. Get the ID of the Current User
        
        currentuser=new User();
        currentuser=[Select Id, ProfileId from User where Id=:userinfo.getuserId()];      
        
        // To store the ids of users belonging to Platform Profile
       
        idsForPlatformProfile = new Set<ID>();
        
        for (User u :[Select Id, Name from User where profileid =: currentuser.ProfileId]) {
        idsForPlatformProfile.add(u.Id);               
        }
        //System.debug('Constructor:: List of Id for Profile' + idsForPlatformProfile);
                    
        HistoryListPFORM = MakeActivityHistoryPFORM();
        OpenListPFORM = MakeOpenActivityPFORM();  
        
        HistoryList = MakeActivityHistory();
        OpenList = MakeOpenActivity();             
        }    

//////////////////////////////////////////////////////////////////////////////////// ACTIVITY LIST FOR PFG_PLATFORM USERS ONLY //////////////////////////////////////////////////////////////////////////////        

        
        /////////////////////////////////////////////////////////////////////////////////       OPEN ACTIVITY         ///////////////////////////////////////////////////////////////////////////////////////
        
        Public List<ActivityTable> MakeOpenActivityPFORM()
        {
        //System.debug('Entry MakeOpenActivityPFORM');
        //System.debug('List of Ids for Platform Profile' + idsForPlatformProfile);
        //System.debug('Opportunity Id' + Oppt.id);
        OpenListPFORM = new List<ActivityTable>();
        
        OpenListPFORM.clear();
        
        for(Task t : [SELECT Id, subject, activitydate, status, priority, OwnerId, Owner.Name, Who.Name FROM Task WHERE Status != 'Completed' AND WhatId=:Oppt.id AND OwnerId=:idsForPlatformProfile]){
        ActivityTable OpenTasks = new ActivityTable();
             OpenTasks.aid = t.id;
             OpenTasks.Subject = t.Subject;
             OpenTasks.activitydate = t.activitydate;
             OpenTasks.status = t.status;
             OpenTasks.isTask = True;
             OpenTasks.AssignedTo = t.OwnerId; 
             OpenTasks.AssignedToName = t.Owner.Name; 
             OpenTasks.WhoName = t.Who.Name;
             //system.debug('Checking For OpenTasks ' + OpenTasks);           
             OpenListPFORM.add(OpenTasks);
             }
        
        for(Event e : [SELECT Id, subject, activitydate, OwnerId, Owner.Name, Who.Name FROM Event WHERE activitydate >= today AND WhatId=:Oppt.id AND OwnerId=:idsForPlatformProfile]){
        ActivityTable OpenEvents = new ActivityTable();
             OpenEvents.aid = e.id;
             OpenEvents.Subject = e.Subject;
             OpenEvents.activitydate = e.activitydate;
             OpenEvents.status = '';
             OpenEvents.isTask = False;
             OpenEvents.AssignedTo = e.OwnerId; 
             OpenEvents.AssignedToName = e.Owner.Name;   
             OpenEvents.WhoName = e.Who.Name;
             OpenListPFORM.add(OpenEvents);            
             }       
             
        return OpenListPFORM;        
        }
        
        Public List<ActivityTable> getOpenListPFORM()
        {
        return MakeOpenActivityPFORM();
        }        
        
        
        /////////////////////////////////////////////////////////////////////////////////      ACTIVITY HISTORY       ///////////////////////////////////////////////////////////////////////////////////////
        
        Public List<ActivityTable> MakeActivityHistoryPFORM()
        {
        //System.debug('Entry MakeActivityHistoryPFORM');
        HistoryListPFORM = new List<ActivityTable>();       
        
        HistoryListPFORM.clear();
        
        for(Task t : [SELECT Id, subject, activitydate, status, priority, OwnerId, Owner.Name, Who.Name FROM Task WHERE Status = 'Completed' AND WhatId=:Oppt.id AND OwnerId=:idsForPlatformProfile]){
             ActivityTable OldTasks = new ActivityTable();
             OldTasks.aid = t.id;
             OldTasks.Subject = t.Subject;
             OldTasks.activitydate = t.activitydate;
             OldTasks.status = t.status;
             OldTasks.isTask = True;
             OldTasks.AssignedTo = t.OwnerId; 
             OldTasks.AssignedToName = t.Owner.Name;  
             OldTasks.WhoName = t.Who.Name;
             HistoryListPFORM.add(OldTasks);
             }
        
        for(Event e : [SELECT Id, subject, activitydate, OwnerId, Owner.Name, Who.Name FROM Event WHERE activitydate < today AND WhatId=:Oppt.id AND OwnerId=:idsForPlatformProfile]){
             ActivityTable OldEvents = new ActivityTable();             
             OldEvents.aid = e.id;
             OldEvents.Subject = e.Subject;
             OldEvents.activitydate = e.activitydate;
             OldEvents.status = '';
             OldEvents.isTask = False;
             OldEvents.AssignedTo = e.OwnerId; 
             OldEvents.AssignedToName = e.Owner.Name;  
             OldEvents.WhoName = e.Who.Name;
             HistoryListPFORM.add(OldEvents);            
             }    
             
        return HistoryListPFORM;        
        }
        
        Public List<ActivityTable> getHistoryListPFORM()
        {
        return MakeActivityHistoryPFORM();
        }        
        
//////////////////////////////////////////////////////////////////////////////////// ACTIVITY LIST FOR ALL OTHER USERS EXCEPT PFG_PLATFORM //////////////////////////////////////////////////////////////////////        
        
/////////////////////////////////////////////////////////////////////////////////       OPEN ACTIVITY         ///////////////////////////////////////////////////////////////////////////////////////

        Public List<ActivityTable> MakeOpenActivity()
        {
        //System.debug('Entry MakeOpenActivity');
        OpenList = new List<ActivityTable>();
        
       
        
        OpenList.clear();
          
        for(Task t : [SELECT Id, subject, activitydate, status, priority, OwnerId, Owner.Name, Who.Name FROM Task WHERE Status != 'Completed' AND WhatId=:Oppt.id]){
             ActivityTable OpenTasks = new ActivityTable();
             OpenTasks.aid = t.id;
             OpenTasks.Subject = t.Subject;
             OpenTasks.activitydate = t.activitydate;
             OpenTasks.status = t.status;
             OpenTasks.isTask = True;
             OpenTasks.AssignedTo = t.OwnerId; 
             OpenTasks.AssignedToName = t.Owner.Name; 
             OpenTasks.WhoName = t.Who.Name;     
             if (idsForPlatformProfile.contains(t.OwnerId)) {
             OpenTasks.showLink = True;
             } else { OpenTasks.showLink = False; }
             OpenList.add(OpenTasks);
             }
        
        for(Event e : [SELECT Id, subject, activitydate, OwnerId, Owner.Name, Who.Name FROM Event WHERE activitydate >= today AND WhatId=:Oppt.id]){
             ActivityTable OpenEvents = new ActivityTable();
             OpenEvents.aid = e.id;
             OpenEvents.Subject = e.Subject;
             OpenEvents.activitydate = e.activitydate;
             OpenEvents.status = '';
             OpenEvents.isTask = False;
             OpenEvents.AssignedTo = e.OwnerId; 
             OpenEvents.AssignedToName = e.Owner.Name;
             OpenEvents.WhoName = e.Who.Name;  
             if (idsForPlatformProfile.contains(e.OwnerId)) {
             OpenEvents.showLink = True;
             } else { OpenEvents.showLink = False; }
             OpenList.add(OpenEvents);            
             }       
             
        return OpenList;        
        }
        
        Public List<ActivityTable> getOpenList()
        {
        return MakeOpenActivity();
        }        
        
        
        /////////////////////////////////////////////////////////////////////////////////      ACTIVITY HISTORY       ///////////////////////////////////////////////////////////////////////////////////////
        
        Public List<ActivityTable> MakeActivityHistory()
        {
        //System.debug('Entry MakeActivityHistory');
        HistoryList = new List<ActivityTable>();
        
        
        
        HistoryList.clear();
        
        for(Task t : [SELECT Id, subject, activitydate, status, priority, OwnerId, Owner.Name, Who.Name FROM Task WHERE Status = 'Completed' AND WhatId=:Oppt.id]){
             ActivityTable OldTasks = new ActivityTable();
             OldTasks.aid = t.id;
             OldTasks.Subject = t.Subject;
             OldTasks.activitydate = t.activitydate;
             OldTasks.status = t.status;
             OldTasks.isTask = True;
             OldTasks.AssignedTo = t.OwnerId; 
             OldTasks.AssignedToName = t.Owner.Name;    
             OldTasks.WhoName = t.Who.Name;
             if (idsForPlatformProfile.contains(t.OwnerId)) {
             OldTasks.showLink = True;
             } else { OldTasks.showLink = False; }
             HistoryList.add(OldTasks);
             }
        
        for(Event e : [SELECT Id, subject, activitydate, OwnerId, Owner.Name, Who.Name FROM Event WHERE activitydate < today AND WhatId=:Oppt.id]){
             ActivityTable OldEvents = new ActivityTable();
             OldEvents.aid = e.id;
             OldEvents.Subject = e.Subject;
             OldEvents.activitydate = e.activitydate;
             OldEvents.status = '';
             OldEvents.isTask = False;
             OldEvents.AssignedTo = e.OwnerId; 
             OldEvents.AssignedToName = e.Owner.Name;
             OldEvents.WhoName = e.Who.Name;  
             if (idsForPlatformProfile.contains(e.OwnerId)) {
             OldEvents.showLink = True;
             } else { OldEvents.showLink = False; }
             HistoryList.add(OldEvents);            
             }    
             
        return HistoryList;        
        }
        
        Public List<ActivityTable> getHistoryList()
        {
        return MakeActivityHistory();
        }                

        
}