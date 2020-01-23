//Trigger to autopopulate Custom account field on Task
trigger populateAccount on Task (before insert,before update,before delete) {
   Set<Id> AccountIds = new Set<Id>();
    List<Task> lstOwnerIds= new List<Task>();
    List<String> lstProfiles= new List<String>();
    List<Task> lstTaskUpdate= new List<Task>();
    List<Event> lstEventUpdate= new List<Event>();
    Set<String> setProfiles= new Set<String>();
    List<Task> lstTasks= new List<Task>();
    List<Event> lstEvents= new List<Event>();
    String profileName = '';
    User objUser= new User();
    String strTempId;
    String id;
    Boolean LatestActivity = False;
    String taskid;
    
    
    lstProfiles = System.Label.BLP_Profile.Split(',');
    
    if(lstProfiles != null && lstProfiles.Size() > 0){
        setProfiles.addAll(lstProfiles );
    }
    
    
    if(trigger.isInsert || trigger.isUpdate){
            //get Profile name of the user
            for(Task t : trigger.new){
                objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: t.OwnerId LIMIT 1];
                taskid = t.id;
            }
            if(objUser!= null){
                profileName =  objUser.profile.name;
            }
        //Check if the user has a BLP Profile
        if(setProfiles!= null && setProfiles.size() > 0 && profileName!= null && setProfiles.contains(profileName)){
            for(Task t : trigger.new){
                if(t.WhatId != null){
                strTempId = string.valueOf(t.WhatId);}
                System.debug('+++++strTempId +++++'+strTempId );
                //Checking if the what Id is Accoun
                //Populate the account Field on Activity of Account
                if( strTempId != null && strTempId.startsWith('001')){
                    if(t.WhatId != null){
                    t.Account__C = t.WhatId;}
                    t.IDI_GazleyActivity__c = true;
                }
                //Checking if the what Id is Property Relation
                
                else if(strTempId != null && strTempId.startsWith('a0p')){
                    if(t.WhatId != null){
                    AccountIds.add(t.WhatId);}
                }
            }
        }
        map<id,id> mapAccounts  = new map<Id,id>();
        if(AccountIds.size() > 0 && AccountIds!= null){
            for(Property_Relation__c objPropertyRelation:[select id,Account__c from Property_Relation__c where id in:AccountIds]){
                mapAccounts.put(objPropertyRelation.id,objPropertyRelation.Account__c);
            }
            //Populate the account Field on Activity of Property Realtion
            for(Task t : trigger.new){
                if(t.whatId != null){
                    t.Account__c = mapAccounts.get(t.whatId);
                }
                t.IDI_GazleyActivity__c = true;
            }
        }
        
    }
    
    if(trigger.isInsert ){
        if(RecursiveHandler.flag){
            RecursiveHandler.flag = false;
            //get Profile name of the user
                for(Task t : trigger.new){
                    objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: t.OwnerId LIMIT 1];
                    System.debug('+++++++Acocunt id++++++++'+t.accountId);
                }
                
                    if(objUser!= null){
                        profileName =  objUser.profile.name;
                    }
                //Check if the user has a BLP Profile
                //Determine the latest Activity
                if(setProfiles != null && setProfiles.size() > 0 && profileName!= null && setProfiles.contains(profileName)){
                    for(task t : trigger.new){
                    System.debug('++++++t.Account__c+++++++++++'+t.Account__c);
                    if(t.Account__c != null){
                        id = t.Account__c ;
                    }
                    }
                    
                    //Getting the older activities of the object
                    System.debug('++++++id+++++++++++'+id);
                    if(id != null && (id .startsWith('001') || id .startsWith('a0p'))){
                        lstTasks = [SELECT Id,LastModifiedDate ,Latest_Activity__c  FROM Task WHERE Account__c = : id AND IDI_GazleyActivity__c = TRUE AND Latest_Activity__c = TRUE ];
                        lstEvents = [SELECT Id,LastModifiedDate ,Latest_Activity__c  FROM Event WHERE Account__c = : id AND IDI_GazleyActivity__c = TRUE AND Latest_Activity__c = TRUE ];
                        System.debug('++++++lstTasks ++++++ :'+lstTasks );
                    }
                    
                    //Updating the Latest Activity checkbox to false on old tasks
                    for (Task t : lstTasks ){
                        if(t.Latest_Activity__c == True ){
                            t.Latest_Activity__c = false;
                             lstTaskUpdate.add(t);
                         }
                    }
                    
                    for (Event t : lstEvents ){
                        if(t.Latest_Activity__c == True ){
                            t.Latest_Activity__c = false;
                            lstEventUpdate.add(t);
                        }
                    }
                    
                    update lstTaskUpdate;
                    update lstEventUpdate;
                    
                    for(task t : trigger.new){
                            if(t.Account__c != null){
                            t.Latest_Activity__c = true;
                            
                            List<Account> acc = new List<Account>();
                            acc = [select Latest_Completed_Activity_Date__c from Account where id = : t.Account__c ];
                            acc[0].Latest_Completed_Activity_Date__c = datetime.now().date();
                            update acc;
                        }
                    }
                }
        }
      }
        if(trigger.isUpdate){
            for(Task t : trigger.new){
                if(t.Latest_Activity__c  == True){
                LatestActivity = true;
                }
            }
            
            if(!LatestActivity){
                if(RecursiveHandler.flag){
            RecursiveHandler.flag = false;
            //get Profile name of the user
                for(Task t : trigger.new){
                    objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: t.OwnerId LIMIT 1];
                }
                
                    if(objUser!= null){
                        profileName =  objUser.profile.name;
                    }
                //Check if the user has a BLP Profile
                //Determine the latest Activity
                if(setProfiles != null && setProfiles.size() > 0 && profileName!= null && setProfiles.contains(profileName)){
                    for(task t : trigger.new){
                        if(t.Account__c != null){
                        id = t.Account__c ;}
                    }
                    
                    //Getting the older activities of the object
                    if(id != null && (id .startsWith('001') || id .startsWith('a0p'))){
                        lstTasks = [SELECT Id,ActivityDate,Latest_Activity__c,LastModifiedDate,Account__c     FROM Task WHERE Account__c = : id AND IDI_GazleyActivity__c = TRUE AND Latest_Activity__c = TRUE ];
                        lstEvents = [SELECT Id,ActivityDate,Latest_Activity__c,LastModifiedDate,Account__c  FROM Event WHERE Account__c = : id AND IDI_GazleyActivity__c = TRUE AND Latest_Activity__c = TRUE ];
                        System.debug('++++++lstTasks ++++++ :'+lstTasks );
                    }
                    
                    //Updating the Latest Activity checkbox to false on old tasks
                    for (Task t : lstTasks ){
                        if(t.Latest_Activity__c == True ){
                            t.Latest_Activity__c = false;
                            if(T.id != taskid){
                                lstTaskUpdate.add(t);
                            }
                            //update t;
                        }
                        
                    }
                    
                    for (Event t : lstEvents ){
                        if(t.Latest_Activity__c = True){
                            t.Latest_Activity__c = false;
                            lstEventUpdate.add(t);
                        }
                        
                    }
                    
                    update lstTaskUpdate;
                    update lstEventUpdate;
                    
                    for(task t : trigger.new){
                        if(t.Account__c != null){
                        t.Latest_Activity__c = true;
                        
                        List<Account> acc = new List<Account>();
                        acc = [select Latest_Completed_Activity_Date__c from Account where id = : t.Account__c ];
                        acc[0].Latest_Completed_Activity_Date__c = datetime.now().date();
                        update acc;}
                    }
                }
            }
        }
            
    }
    
    if(trigger.isDelete){
        for(Task t : trigger.old){
                if(t.Latest_Activity__c  == True){
                LatestActivity = true;
                }
        }
        
        if(LatestActivity){
            //get Profile name of the user
            for(Task t : trigger.old){
                objUser= [SELECT ProfileId,name,profile.name FROM User WHERE Id =: t.OwnerId LIMIT 1];
            }
            
            if(objUser!= null){
                        profileName =  objUser.profile.name;
            }
            
            //Check if the user has a BLP Profile
            if(setProfiles != null && setProfiles.size() > 0 && profileName!= null && setProfiles.contains(profileName)){
                    for(task t : trigger.old){
                        
                        if(t.Account__c != null){id = t.Account__c ;}
                    }
                    //Getting the older activities of the object
                    if(id != null && (id .startsWith('001') || id .startsWith('a0p'))){
                        lstTasks = [SELECT Id,subject,LastModifiedDate ,Latest_Activity__c,Account__c   FROM Task WHERE Account__c = : id AND IDI_GazleyActivity__c = TRUE AND Latest_Activity__c = FALSE ORDER BY LastModifiedDate DESC LIMIT 1];
                        lstEvents = [SELECT Id,LastModifiedDate ,Latest_Activity__c,Account__c   FROM Event WHERE Account__c = : id AND IDI_GazleyActivity__c = TRUE AND Latest_Activity__c = FALSE ORDER BY LastModifiedDate DESC LIMIT 1];
                        System.debug('++++++lstTasks ++++++ :'+lstTasks );
                        System.debug('++++++lstTasks ++++++ :'+lstEvents );
                    }
                    if(lstTasks.size() > 0 && lstEvents.size() > 0){
                        if(DateTime.valueOf(lstTasks[0].LastModifiedDate) > DateTime.valueOf(lstEvents[0].LastModifiedDate)){
                            for (Task t : lstTasks ){
                                if(t.Latest_Activity__c == False){
                                    if(t.Account__c != null){
                                    t.Latest_Activity__c = True;
                                    lstTaskUpdate.add(t);
                                    
                                    System.debug('++++++IN TASK 1+++++++++++');
                                    List<Account> acc = new List<Account>();
                                    acc = [select Latest_Completed_Activity_Date__c from Account where id = : t.Account__c ];
                                    acc[0].Latest_Completed_Activity_Date__c = t.LastModifiedDate.date();
                                    update acc;}
                                }
                                
                            }
                            update lstTaskUpdate;
                        }
                    }
                    if(lstTasks.size() > 0 && lstEvents.size() > 0){
                        if(DateTime.valueOf(lstTasks[0].LastModifiedDate) < DateTime.valueOf(lstEvents[0].LastModifiedDate)){
                            for (Event t : lstEvents ){
                                if(t.Latest_Activity__c == False){
                                    if(t.Account__c != null){
                                    t.Latest_Activity__c = True;
                                    lstEventUpdate.add(t);
                                    
                                    System.debug('++++++IN Event 1+++++++++++');
                                   List<Account> acc = new List<Account>();
                                    acc = [select Latest_Completed_Activity_Date__c from Account where id = : t.Account__c ];
                                    acc[0].Latest_Completed_Activity_Date__c = t.LastModifiedDate.date();
                                    update acc;}
                                }
                                
                            }
                            update lstEventUpdate;
                        }
                    }
                    
                    if(lstTasks.size() > 0 && lstEvents.size() == 0){
                        for (Task t : lstTasks ){
                                if(t.Latest_Activity__c == False){
                                   if(t.Account__c != null){
                                    t.Latest_Activity__c = True;
                                    lstTaskUpdate.add(t);
                                     
                                    System.debug('++++++IN TASK 2+++++++++++');
                                    List<Account> acc = new List<Account>();
                                    acc = [select Latest_Completed_Activity_Date__c from Account where id = : t.Account__c ];
                                    acc[0].Latest_Completed_Activity_Date__c = t.LastModifiedDate.date();
                                    System.debug('++++++Date+++++ :'+t.LastModifiedDate.date());
                                    update acc;}
                                }
                                
                            }
                            update lstTaskUpdate;
                            System.debug('++++++lstTaskUpdate+++++++++++'+lstTaskUpdate);
                    }
                    
                    if(lstTasks.size() == 0 && lstEvents.size() > 0){
                        for (Event t : lstEvents ){
                                if(t.Latest_Activity__c == False){
                                    if(t.Account__c != null){
                                    t.Latest_Activity__c = True;
                                    lstEventUpdate.add(t);
                                    
                                    System.debug('++++++IN Event 2+++++++++++');
                                   List<Account> acc = new List<Account>();
                                    acc = [select Latest_Completed_Activity_Date__c from Account where id = : t.Account__c ];
                                    acc[0].Latest_Completed_Activity_Date__c = t.LastModifiedDate.date();
                                    update acc;}
                                }
                                
                            }
                            update lstEventUpdate;
                    
                    }
            }
        
        }
    }
  
}