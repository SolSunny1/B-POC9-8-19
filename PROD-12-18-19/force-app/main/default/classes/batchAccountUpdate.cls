global class batchAccountUpdate implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //String id = '0018A000007echx';
        String query = 'SELECT id,name,(select id,lastmodifieddate,IDI_GazleyActivity__c,Account__c,accountId,Latest_Activity__c,OwnerId  from tasks ORDER BY LastModifiedDate DESC ),(select id,lastmodifieddate,IDI_GazleyActivity__c,Account__c,accountId,Latest_Activity__c,OwnerId  from events ORDER BY LastModifiedDate DESC ) from Account ';
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Account> scope) {
         System.debug('++++++++++++scope++++++++++++'+scope);
          List<Task> lstTaskUpdate= new List<Task>();
          List<Event> lstEventUpdate= new List<Event>();
          List<String> lstProfiles= new List<String>();
          Set<String> setProfiles= new Set<String>();
          String profileName = '';
          User objUser= new User();
          String EventprofileName = '';
          
          lstProfiles = System.Label.BLP_Profile.Split(',');
          
           if(lstProfiles != null && lstProfiles.Size() > 0){
                setProfiles.addAll(lstProfiles );
            }
          
         for(Account ac: scope)
        { 
            List<Task> Tasks= new List<Task>();
            Tasks= ac.getSObjects('Tasks');
            System.debug('++++++++++++Task++++++++++++'+Tasks);
            
            List<Event> Events= new List<Event>();
            Events= ac.getSObjects('Events');
            System.debug('++++++++++++Event++++++++++++'+Events);
            
            
            //Update latest activity on Tasks
            if(Tasks != null){
                for(task t : tasks){
                     objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: t.OwnerId LIMIT 1];
                     if(objUser!= null){
                        profileName =  objUser.profile.name;
                     }
                     
                      if(setProfiles!= null && setProfiles.size() > 0 && profileName!= null && setProfiles.contains(profileName)){
                          t.IDI_GazleyActivity__c = true;
                          //update t;
                      }
                    if(t.Latest_Activity__c == true){
                        t.Latest_Activity__c = False;
                        update t;
                    }
                }
            }
            
            //Update latest activity on Events
            if(Events!= null){
                for(Event t : Events){
                    objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: t.OwnerId LIMIT 1];
                     if(objUser!= null){
                        profileName =  objUser.profile.name;
                     }
                     
                      if(setProfiles!= null && setProfiles.size() > 0 && profileName!= null && setProfiles.contains(profileName)){
                          t.IDI_GazleyActivity__c = true;
                          //update t;
                      }
                    if(t.Latest_Activity__c == true){
                        t.Latest_Activity__c = False;
                        update t;
                    }
                }
            }
            
            //If both task and event is returned
            if(Tasks!= null && Events!= null){
                if(DateTime.valueOf(Tasks[0].LastModifiedDate) > DateTime.valueOf(Events[0].LastModifiedDate)){
                    Tasks[0].Latest_Activity__c = True;
                    Tasks[0].Account__c = Tasks[0].AccountId;
                    lstTaskUpdate.add(Tasks[0]);
                    System.debug('++++++IN TASK +++++++++++');
                    Ac.Latest_Completed_Activity_Date__c = Tasks[0].LastModifiedDate.date();
                    update ac;
                    update lstTaskUpdate;
                }
            }
            
            if(Tasks!= null && Events!= null){
                if(DateTime.valueOf(Tasks[0].LastModifiedDate) < DateTime.valueOf(Events[0].LastModifiedDate)){
                    Events[0].Latest_Activity__c = True;
                    Events[0].Account__c = Events[0].AccountId;
                    lstEventUpdate.add(Events[0]);
                    System.debug('++++++IN TASK +++++++++++');
                    Ac.Latest_Completed_Activity_Date__c = Events[0].LastModifiedDate.date();
                    update ac;
                    update lstEventUpdate;
                }
            }
            
            //Only Task is returned
            if(Tasks!= null && Events == null){
                Tasks[0].Latest_Activity__c = True;
                lstTaskUpdate.add(Tasks[0]);
                Tasks[0].Account__c = Tasks[0].AccountId;
                System.debug('++++++IN TASK +++++++++++');
                Ac.Latest_Completed_Activity_Date__c = Tasks[0].LastModifiedDate.date();
                update ac;
                update lstTaskUpdate;
            }
            
            //Only Event is returned
            if(Tasks == null && Events != null){
                Events[0].Latest_Activity__c = True;
                Events[0].Account__c = Events[0].AccountId;
                lstEventUpdate.add(Events[0]);
                System.debug('++++++IN TASK +++++++++++');
                Ac.Latest_Completed_Activity_Date__c = Events[0].LastModifiedDate.date();
                update ac;
                update lstTaskUpdate;
            }
            
        }
        update scope;
         
         List<Property_Relation__c>  propReln = new List<Property_Relation__c>();
        propReln = [SELECT id,name,(select id,lastmodifieddate,IDI_GazleyActivity__c,Account__c,accountId,Latest_Activity__c,whatId,OwnerId  from tasks ORDER BY LastModifiedDate DESC ),(select id,lastmodifieddate,IDI_GazleyActivity__c,Account__c,accountId,Latest_Activity__c,whatId,OwnerId  from events ORDER BY LastModifiedDate DESC ) from Property_Relation__c];
        
        for(Property_Relation__c ac: propReln){
                List<Task> Tasks= new List<Task>();
            Tasks= ac.getSObjects('Tasks');
            System.debug('++++++++++++Task++++++++++++'+Tasks);
            
            List<Event> Events= new List<Event>();
            Events= ac.getSObjects('Events');
            System.debug('++++++++++++Event++++++++++++'+Events);
            
            //Update latest activity on Tasks
            if(Tasks != null){
                for(task t : tasks){
                    objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: t.OwnerId LIMIT 1];
                     if(objUser!= null){
                        profileName =  objUser.profile.name;
                     }
                     
                      if(setProfiles!= null && setProfiles.size() > 0 && profileName!= null && setProfiles.contains(profileName)){
                          t.IDI_GazleyActivity__c = true;
                          //update t;
                      }
                    if(t.Latest_Activity__c == true){
                        t.Latest_Activity__c = False;
                        update t;
                    }
                }
            }
            
            //Update latest activity on Events
            if(Events!= null){
                for(Event t : Events){
                    objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: t.OwnerId LIMIT 1];
                     if(objUser!= null){
                        profileName =  objUser.profile.name;
                     }
                     
                      if(setProfiles!= null && setProfiles.size() > 0 && profileName!= null && setProfiles.contains(profileName)){
                          t.IDI_GazleyActivity__c = true;
                          //update t;
                      }
                    if(t.Latest_Activity__c == true){
                        t.Latest_Activity__c = False;
                        update t;
                    }
                }
            }
            
            //If both task and event is returned
            if(Tasks!= null && Events!= null){
                /*objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: Tasks[0].OwnerId LIMIT 1];
                     if(objUser!= null){
                        profileName =  objUser.profile.name;
                     }
                 objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: Tasks[0].OwnerId LIMIT 1];
                     if(objUser!= null){
                         EventprofileName =  objUser.profile.name;
                     }
                if(setProfiles!= null && setProfiles.size() > 0 && profileName!= null && setProfiles.contains(profileName) &&  setProfiles.contains(EventprofileName)){*/
                    if(DateTime.valueOf(Tasks[0].LastModifiedDate) > DateTime.valueOf(Events[0].LastModifiedDate)){
                        Tasks[0].Latest_Activity__c = True;
                        System.debug('++++++IN TASK +++++++++++');
                        List<Property_Relation__c> objPropertyRelation = new List<Property_Relation__c>();
                        objPropertyRelation = [select id,Account__c from Property_Relation__c where id = : Tasks[0].whatid];
                        
                        
                        List<Account> acc = new List<Account>();
                        acc = [select Latest_Completed_Activity_Date__c from Account where id = : objPropertyRelation[0].account__C ];
                        System.debug('++++++acc+++++++++++'+acc);
                        acc[0].Latest_Completed_Activity_Date__c = Tasks[0].LastModifiedDate.date();
                        update acc;
                        Tasks[0].Account__c = objPropertyRelation[0].account__C;
                        lstTaskUpdate.add(Tasks[0]);
                        update lstTaskUpdate;
                    }
               // }
            }
            
            if(Tasks!= null && Events!= null){
                /*objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: Tasks[0].OwnerId LIMIT 1];
                     if(objUser!= null){
                        profileName =  objUser.profile.name;
                     }
                 objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: Tasks[0].OwnerId LIMIT 1];
                     if(objUser!= null){
                         EventprofileName =  objUser.profile.name;
                     }
                if(setProfiles!= null && setProfiles.size() > 0 && profileName!= null && setProfiles.contains(profileName) && setProfiles.contains(EventprofileName)){*/
                    if(DateTime.valueOf(Tasks[0].LastModifiedDate) < DateTime.valueOf(Events[0].LastModifiedDate)){
                        Events[0].Latest_Activity__c = True;
                        System.debug('++++++IN TASK 1+++++++++++');
                        System.debug('++++++Task+++++++++++'+tasks[0].accountId);
                        List<Property_Relation__c> objPropertyRelation = new List<Property_Relation__c>();
                        objPropertyRelation = [select id,Account__c from Property_Relation__c where id = : Events[0].whatid];
                        
                        
                        List<Account> acc = new List<Account>();
                        acc = [select Latest_Completed_Activity_Date__c from Account where id = : objPropertyRelation[0].account__C ];
                        System.debug('++++++acc+++++++++++'+acc);
                        acc[0].Latest_Completed_Activity_Date__c = Events[0].LastModifiedDate.date();
                        update acc;
                        
                        Events[0].Account__c = objPropertyRelation[0].account__C;
                        lstEventUpdate.add(Events[0]);
                        
                        update lstEventUpdate;
                    }
              //  }
            }
            
            //Only Task is returned
            if(Tasks!= null && Events == null){
                objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: Tasks[0].OwnerId LIMIT 1];
                     if(objUser!= null){
                        profileName =  objUser.profile.name;
                     }
                Tasks[0].Latest_Activity__c = True;
                
                System.debug('++++++IN TASK +++++++++++');
                System.debug('++++++Task+++++++++++'+tasks[0].accountId);
                List<Property_Relation__c> objPropertyRelation = new List<Property_Relation__c>();
                    objPropertyRelation = [select id,Account__c from Property_Relation__c where id = : Tasks[0].whatid];
                    
                    
                    List<Account> acc = new List<Account>();
                    acc = [select Latest_Completed_Activity_Date__c from Account where id = : objPropertyRelation[0].account__C ];
                    System.debug('++++++acc+++++++++++'+acc);
                    acc[0].Latest_Completed_Activity_Date__c = Tasks[0].LastModifiedDate.date();
                    update acc;
                    Tasks[0].Account__c = objPropertyRelation[0].account__C;
                    lstTaskUpdate.add(Tasks[0]);
                update lstTaskUpdate;
            }
            
            //Only Event is returned
            if(Tasks == null && Events != null){
                Events[0].Latest_Activity__c = True;
                
                System.debug('++++++IN TASK +++++++++++');
                List<Property_Relation__c> objPropertyRelation = new List<Property_Relation__c>();
                    objPropertyRelation = [select id,Account__c from Property_Relation__c where id = : Events[0].whatid];
                    
                    
                    List<Account> acc = new List<Account>();
                    acc = [select Latest_Completed_Activity_Date__c from Account where id = : objPropertyRelation[0].account__C ];
                    System.debug('++++++acc+++++++++++'+acc);
                    acc[0].Latest_Completed_Activity_Date__c = Events[0].LastModifiedDate.date();
                    update acc;
                    Events[0].Account__c = objPropertyRelation[0].account__C;
                    lstEventUpdate.add(Events[0]);
                update lstEventUpdate;
            }
         
        }
        
        update propReln;
    }   
    
    global void finish(Database.BatchableContext BC) {
    }
}