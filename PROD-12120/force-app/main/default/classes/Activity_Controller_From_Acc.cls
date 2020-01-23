public with sharing class Activity_Controller_From_Acc {  
      
        private Account Acct;
        public String currentAcc        {get;set;}
        private user currentuser         {get;set;}
        public Set<Id> idsForPlatformProfile {get;set;}
        public Set<Id> idsForOpps {get;set;}
        public Set<Id> idsForCons {get;set;}

        public class ActivityTable{
        public Id Aid                   {get;set;}
        public String Subject           {get;set;}
        //public String CreatedBy         {get;set;}
        public Date Activitydate        {get;set;}
        public String Status            {get;set;}
        Public String WhoName                {get;set;}
        //public String priority          {get;set;}  
        public Boolean isTask           {get;set;} 
        public Id AssignedTo          {get;set;}
        //public Id OwnerId               {get;set;}
        public String AssignedToName    {get;set;} 
        public String WhatName          {get;set;}
        public String WhatId            {get;set;} 
        Public Boolean showLink              {get;set;}     
        }        
        
        public List<ActivityTable> OpenListPFORM   {get;set;}
        public List<ActivityTable> HistoryListPFORM   {get;set;}
        
        public List<ActivityTable> OpenList   {get;set;}
        public List<ActivityTable> HistoryList   {get;set;}
        
        
        public Activity_Controller_From_Acc(ApexPages.StandardController controller) {
              
        // 1. Get the ID of the Account record
    
        Acct = (Account)controller.getRecord();
        Acct =[Select Id, Share_with_PFG_Platform__c from Account where Id=:Acct.id];
        
        // 2. Get the ID of the Current User
        
        currentuser=new User();
        currentuser=[Select Id, ProfileId from User where Id=:userinfo.getuserId()];          
        
        // 3. store the ids of users belonging to Platform Profile
       
        idsForPlatformProfile = new Set<ID>();
        
        for (User u :[Select Id, Name from User where profileid =: currentuser.ProfileId]) {
        idsForPlatformProfile.add(u.Id);               
        }
        System.debug('Constructor:: List of Id for Profile' + idsForPlatformProfile);
        
        // 4. store the ids of Opportunities related to the Account
       
        idsForOpps = new Set<ID>();
        
        for (Opportunity o :[Select Id, Name from Opportunity where AccountId =: Acct.Id]) {
        idsForOpps.add(o.Id);               
        }
        
        // 5. store the ids of Contacts related to the Account
       
        idsForCons = new Set<ID>();
        
        for (Contact c :[Select Id, Name from Contact where AccountId =: Acct.Id]) {
        idsForCons.add(c.Id);               
        }
        
        
                   
        // Call Methods
               
        HistoryListPFORM = MakeActivityHistoryPFORM();
        OpenListPFORM = MakeOpenActivityPFORM();  
        
        HistoryList = MakeActivityHistory();
        OpenList = MakeOpenActivity();             
        }    

//////////////////////////////////////////////////////////////////////////////////// ACTIVITY LIST FOR PFG_PLATFORM USERS ONLY //////////////////////////////////////////////////////////////////////////////        

        
        /////////////////////////////////////////////////////////////////////////////////       OPEN ACTIVITY         ///////////////////////////////////////////////////////////////////////////////////////
        
        Public List<ActivityTable> MakeOpenActivityPFORM()
        {
        OpenListPFORM = new List<ActivityTable>();
       
       
          
        OpenListPFORM.clear();  
          
        for(Task t : [SELECT Id, subject, activitydate, status, OwnerId, Owner.Name, Who.Name, What.Name, WhatId FROM Task WHERE Status != 'Completed' AND (WhatId=:Acct.id OR WhatId=:idsForOpps OR WhoId=:idsForCons) AND OwnerId=:idsForPlatformProfile]){
             ActivityTable OpenTasks = new ActivityTable();
             OpenTasks.aid = t.id;
             OpenTasks.Subject = t.Subject;
             OpenTasks.activitydate = t.activitydate;
             //OpenTasks.createdby = t.createdby.name;
             OpenTasks.status = t.status;
             //OpenTasks.priority = t.priority;
             OpenTasks.isTask = True;
             OpenTasks.AssignedTo = t.OwnerId; 
             OpenTasks.AssignedToName = t.Owner.Name;  
             OpenTasks.WhoName = t.Who.Name; 
             OpenTasks.WhatName = t.What.Name;
             OpenTasks.WhatId = t.WhatId;        
             OpenListPFORM.add(OpenTasks);
             }
        
        for(Event e : [SELECT Id, subject, activitydate, OwnerId, Owner.Name, Who.Name, What.Name, WhatId FROM Event WHERE activitydate >= today AND (WhatId=:Acct.id OR WhatId=:idsForOpps OR WhoId=:idsForCons) AND OwnerId=:idsForPlatformProfile]){
             ActivityTable OpenEvents = new ActivityTable();
             OpenEvents.aid = e.id;
             OpenEvents.Subject = e.Subject;
             OpenEvents.activitydate = e.activitydate;
             OpenEvents.status = '';
             OpenEvents.isTask = False;
             OpenEvents.AssignedTo = e.OwnerId; 
             OpenEvents.AssignedToName = e.Owner.Name;   
             OpenEvents.WhoName = e.Who.Name;
             OpenEvents.WhatName = e.What.Name;
             OpenEvents.WhatId = e.WhatId;
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
        HistoryListPFORM = new List<ActivityTable>();
        
        
        
        HistoryListPFORM.clear();  
        
        for(Task t : [SELECT Id, subject, activitydate, status, OwnerId, Owner.Name, Who.Name, What.Name, WhatId FROM Task WHERE Status = 'Completed' AND (WhatId=:Acct.id OR WhatId=:idsForOpps OR WhoId=:idsForCons) AND OwnerId=:idsForPlatformProfile]){
             ActivityTable OldTasks = new ActivityTable();
             OldTasks.aid = t.id;
             OldTasks.Subject = t.Subject;
             OldTasks.activitydate = t.activitydate;
             OldTasks.status = t.status;
             OldTasks.isTask = True;
             OldTasks.AssignedTo = t.OwnerId; 
             OldTasks.AssignedToName = t.Owner.Name;  
             OldTasks.WhoName = t.Who.Name;
             OldTasks.WhatName = t.What.Name;
             OldTasks.WhatId = t.WhatId;        
             HistoryListPFORM.add(OldTasks);
             }
        
        for(Event e : [SELECT Id, subject, activitydate, OwnerId, Owner.Name, Who.Name, What.Name, WhatId FROM Event WHERE activitydate < today AND (WhatId=:Acct.id OR WhatId=:idsForOpps OR WhoId=:idsForCons) AND OwnerId=:idsForPlatformProfile]){
             ActivityTable OldEvents = new ActivityTable();
             OldEvents.aid = e.id;
             OldEvents.Subject = e.Subject;
             OldEvents.activitydate = e.activitydate;
             OldEvents.status = '';
             OldEvents.isTask = False;
             OldEvents.AssignedTo = e.OwnerId; 
             OldEvents.AssignedToName = e.Owner.Name;  
             OldEvents.WhoName = e.Who.Name;
             OldEvents.WhatName = e.What.Name;
             OldEvents.WhatId = e.WhatId;
             HistoryListPFORM.add(OldEvents);            
             }    
             
        return HistoryListPFORM;        
        }
        
        Public List<ActivityTable> getHistoryListPFORM()
        {
        return MakeActivityHistoryPFORM();
        }        
        
//////////////////////////////////////////////////////////////////////////////////// ACTIVITY LIST FOR ALL USERS ////////////// //////////////////////////////////////////////////////////////////////        
        
/////////////////////////////////////////////////////////////////////////////////       OPEN ACTIVITY         ///////////////////////////////////////////////////////////////////////////////////////
        
        Public List<ActivityTable> MakeOpenActivity()
        {
        OpenList = new List<ActivityTable>();
        
        
          
        for(Task t : [SELECT Id, subject, activitydate, status, OwnerId, Owner.Name, Who.Name, What.Name, WhatId FROM Task WHERE Status != 'Completed' AND (WhatId=:Acct.id OR WhatId=:idsForOpps OR WhoId=:idsForCons)]){
             ActivityTable OpenTasks = new ActivityTable();
             OpenTasks.aid = t.id;
             OpenTasks.Subject = t.Subject;
             OpenTasks.activitydate = t.activitydate;
             OpenTasks.status = t.status;
             OpenTasks.isTask = True;
             OpenTasks.AssignedTo = t.OwnerId; 
             OpenTasks.AssignedToName = t.Owner.Name; 
             OpenTasks.WhoName = t.Who.Name;
             OpenTasks.WhatName = t.What.Name;
             OpenTasks.WhatId = t.WhatId;      
             if (idsForPlatformProfile.contains(t.OwnerId)) {
             OpenTasks.showLink = True;
             } else { OpenTasks.showLink = False; }   
                   
             OpenList.add(OpenTasks);
             }
        
        for(Event e : [SELECT Id, subject, activitydate, OwnerId, Owner.Name, Who.Name, What.Name, WhatId FROM Event WHERE activitydate >= today AND (WhatId=:Acct.id OR WhatId=:idsForOpps OR WhoId=:idsForCons)]){
             ActivityTable OpenEvents = new ActivityTable();
             OpenEvents.aid = e.id;
             OpenEvents.Subject = e.Subject;
             OpenEvents.activitydate = e.activitydate;
             OpenEvents.status = '';
             OpenEvents.isTask = False;
             OpenEvents.AssignedTo = e.OwnerId; 
             OpenEvents.AssignedToName = e.Owner.Name;
             OpenEvents.WhoName = e.Who.Name;
             OpenEvents.WhatName = e.What.Name;
             OpenEvents.WhatId = e.WhatId;  
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
        HistoryList = new List<ActivityTable>();
        
        
        
        for(Task t : [SELECT Id, subject, activitydate, status, OwnerId, Owner.Name, Who.Name, What.Name, WhatId FROM Task WHERE Status = 'Completed' AND (WhatId=:Acct.id OR WhatId=:idsForOpps OR WhoId=:idsForCons)]){
             ActivityTable OldTasks = new ActivityTable();
             OldTasks.aid = t.id;
             OldTasks.Subject = t.Subject;
             OldTasks.activitydate = t.activitydate;
             OldTasks.status = t.status;
             OldTasks.isTask = True;
             OldTasks.AssignedTo = t.OwnerId; 
             OldTasks.AssignedToName = t.Owner.Name;    
             OldTasks.WhoName = t.Who.Name;
             OldTasks.WhatName = t.What.Name;
             OldTasks.WhatId = t.WhatId;  
             OldTasks.showLink = True;
             if (idsForPlatformProfile.contains(t.OwnerId)) {
             OldTasks.showLink = True;
             } else { OldTasks.showLink = False; }       
             HistoryList.add(OldTasks);       

             }
        
        for(Event e : [SELECT Id, subject, activitydate, OwnerId, Owner.Name, Who.Name, What.Name, WhatId FROM Event WHERE activitydate < today AND (WhatId=:Acct.id OR WhatId=:idsForOpps OR WhoId=:idsForCons)]){
             ActivityTable OldEvents = new ActivityTable();
             OldEvents.aid = e.id;
             OldEvents.Subject = e.Subject;
             OldEvents.activitydate = e.activitydate;
             OldEvents.status = '';
             OldEvents.isTask = False;
             OldEvents.AssignedTo = e.OwnerId; 
             OldEvents.AssignedToName = e.Owner.Name;
             OldEvents.WhoName = e.Who.Name;
             OldEvents.WhatName = e.What.Name;
             OldEvents.WhatId = e.WhatId;
             OldEvents.showLink = True;
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