trigger TaskTrigger on Task (after insert,after update) {
  list<ObjectFieldMapping__c> lstObjectFieldMappingInfo=ActivityHelper.getObjectFieldMappingInfo('LastRelationshipType-Condition','Task');
    list<ObjectFieldMapping__c> lstObjectFieldMappingInfoFieldUpdate=ActivityHelper.getObjectFieldMappingInfo('LastRelationshipType-FieldUpdate','Task');
    map<Id,Sobject> mapSobjectToUpdate=new map<Id,Sobject>();
    List<ObjectFieldMapping__c> lstContactFieldUpdateInfo=new List<ObjectFieldMapping__c>();
    List<ObjectFieldMapping__c> lstLeadFieldUpdateInfo=new List<ObjectFieldMapping__c>();
    for(ObjectFieldMapping__c objObjectFieldMapping : lstObjectFieldMappingInfoFieldUpdate){
        if(objObjectFieldMapping.Target_Object_Name__c != null ){
            set<string> setObjectName=new set<string>();
      setObjectName.addall(objObjectFieldMapping.Target_Object_Name__c.split(','));
            if(setObjectName.contains('Contact')){
                lstContactFieldUpdateInfo.add(objObjectFieldMapping);
            }
            else if(setObjectName.contains('Lead')){
                lstLeadFieldUpdateInfo.add(objObjectFieldMapping);
            }
        }        
    }
    set<Id> setIds=new set<Id>();
    for(Task objTask : trigger.new){
        if(objTask.WhoId != null){
            setIds.add(objTask.WhoId);
        }
    }
    map<Id,Contact> mapContact=new map<Id,Contact>([select id,Last_Relationship_Call__c from contact where id in :setIds]);
    map<Id,Lead> mapLead=new map<Id,Lead>([select id,Last_Relationship_Call__c from Lead where id in :setIds]);
    system.debug('****lstObjectFieldMappingInfo***'+lstObjectFieldMappingInfo);
    for(Task objTask : trigger.new){
        if(objTask.WhoId != null){
            integer counter=0;
            boolean isSubjectEmail=false;
            for(ObjectFieldMapping__c objMapping : lstObjectFieldMappingInfo){
                set<string> sValues=new set<string>();
                sValues.addall(objMapping.Field_Value__c.split(','));
                system.debug('*****'+sValues + '****'+objTask.get(objMapping.Field_API_Name__c));
                if(sValues.contains((string)objTask.get(objMapping.Field_API_Name__c))){
                    counter++;
                }
            }
            if(objTask.subject != null && objTask.subject.startsWithIgnoreCase('email')){
                counter++;
                isSubjectEmail=true;
                
            }
            system.debug('***EMAIL: **'+isSubjectEmail);
            //SS: 11-15 added counter == lstObjectFieldMappingInfo.size() to execute below code when task is created or updated. 
            if( counter == lstObjectFieldMappingInfo.size() || counter > 0){
                Sobject objSobject=objTask.WhoId.getSObjectType().newSObject();
                objSobject.put('Id',objTask.WhoId);
                if(mapContact.containsKey(objTask.WhoId)){
                    if(objTask.subject == 'Note'){
                        objSobject.put('Last_Note_Date__c',objTask.ActivityDate);
                         //objSobject.put('Last_Note_Date__c',system.today());
                    }
                    else if(isSubjectEmail){
                      objSobject.put('Last_Email_Date__c',objTask.ActivityDate);
                        //objSobject.put('Last_Email_Date__c',system.today());
                    }
                    else if( !(isSubjectEmail) && mapContact.get(objTask.WhoId).Last_Relationship_Call__c == null || (mapContact.get(objTask.WhoId).Last_Relationship_Call__c != null && mapContact.get(objTask.WhoId).Last_Relationship_Call__c < objTask.ActivityDate)){
                            objSobject.put('Last_Relationship_Call__c',objTask.Account.LastActivityDate);
                            //objSobject.put('Last_Relationship_Call__c',system.today());
                    }
                    for(ObjectFieldMapping__c objObjectFieldMapping :  lstContactFieldUpdateInfo){
                        objSobject.put(objObjectFieldMapping.Target_Object_Field_Name__c,objObjectFieldMapping.Target_Object_Field_Value__c);
                    }
                }
                else if(mapLead.containsKey(objTask.WhoId)){
                    if(objTask.Call_Note_Type__c == 'Note'){
                        objSobject.put('Last_Note_Date__c',system.today());
                    }
                    else{
                        if( mapLead.get(objTask.WhoId).Last_Relationship_Call__c == null || (mapLead.get(objTask.WhoId).Last_Relationship_Call__c != null &&
                            mapLead.get(objTask.WhoId).Last_Relationship_Call__c < system.today())){
                            objSobject.put('Last_Relationship_Call__c',system.today());
                        }
                    }
                    for(ObjectFieldMapping__c objObjectFieldMapping :  lstLeadFieldUpdateInfo){
                        objSobject.put(objObjectFieldMapping.Target_Object_Field_Name__c,objObjectFieldMapping.Target_Object_Field_Value__c);
                    }
                }
                if(!mapSobjectToUpdate.containsKey(objTask.WhoId))
                  mapSobjectToUpdate.put(objTask.WhoId,objSobject);
            }  
        }
    }
    update mapSobjectToUpdate.values();
}