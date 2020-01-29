trigger EventTrigger_copy_1-25-20 on Event_copy-1-25-20 (after insert,after update) {
    list<ObjectFieldMapping__c> lstObjectFieldMappingInfo=ActivityHelper.getObjectFieldMappingInfo('LastInPersonMeeting-Condition','Event');
    map<Id,Sobject> mapSobjectToUpdate=new map<Id,Sobject>();
    set<Id> setIds=new set<Id>();
    for(Event objEvent : trigger.new){
        if(objEvent.WhoId != null){
            setIds.add(objEvent.WhoId);
        }
    }
    map<Id,Contact> mapContact=new map<Id,Contact>([select id,Last_In_Person_Meeting__c from contact where id in :setIds]);
    map<Id,Lead> mapLead=new map<Id,Lead>([select id,Last_In_Person_Meeting__c from Lead where id in :setIds]);
    system.debug('****lstObjectFieldMappingInfo***'+lstObjectFieldMappingInfo);
    for(Event objEvent : trigger.new){
        if(objEvent.WhoId != null){
            integer counter=0;
            for(ObjectFieldMapping__c objMapping : lstObjectFieldMappingInfo){
                set<string> sValues=new set<string>();
                sValues.addall(objMapping.Field_Value__c.split(','));
                system.debug('*****'+sValues + '****'+objEvent.get(objMapping.Field_API_Name__c));
                if(sValues.contains((string)objEvent.get(objMapping.Field_API_Name__c))){
                    counter++;
                }
            }
            if(counter == lstObjectFieldMappingInfo.size()){
                Sobject objSobject=objEvent.WhoId.getSObjectType().newSObject();
                objSobject.put('Id',objEvent.WhoId);
                //SS: 11-15 updated if statements to record the activity date on contact record.  
                if(mapContact.containsKey(objEvent.WhoId) && objEvent.Stat_cd__c ==  'Complete' && 
                    ((mapContact.get(objEvent.WhoId).Last_In_Person_Meeting__c < objEvent.ActivityDate &&
                     mapContact.get(objEvent.WhoId).Last_In_Person_Meeting__c != null) ||
                    mapContact.get(objEvent.WhoId).Last_In_Person_Meeting__c == null )
                     //mapContact.get(objEvent.WhoId).Last_In_Person_Meeting__c != null &&
                     //mapContact.get(objEvent.WhoId).Last_In_Person_Meeting__c < system.today())
                     ){
                    objSobject.put('Last_In_Person_Meeting__c', objEvent.ActivityDate );
                }
                else if(mapLead.containsKey(objEvent.WhoId) &&  objEvent.Stat_cd__c == 'Complete' ){
                    objSobject.put('Last_In_Person_Meeting__c', objEvent.ActivityDate );
                }
                if(!mapSobjectToUpdate.containsKey(objEvent.WhoId))
                  mapSobjectToUpdate.put(objEvent.WhoId,objSobject);
            }  
        }
    }
    update mapSobjectToUpdate.values();
}