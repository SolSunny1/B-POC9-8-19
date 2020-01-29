trigger EventTrigger on Event (after insert,after update) {
    list<ObjectFieldMapping__c> lstObjectFieldMappingInfo=ActivityHelper.getObjectFieldMappingInfo('LastInPersonMeeting-Condition','Event');
    map<Id,Sobject> mapSobjectToUpdate=new map<Id,Sobject>();
    set<Id> setIds=new set<Id>();
/*  for(Event objEvent : trigger.new){
        if(objEvent.WhoId != null){
            setIds.add(objEvent.WhoId);
        }
    }*/
    Set<Id> eventIds = trigger.newMap.keySet();
    List <Event> objEventList = [SELECT Id, Subject,ActivityDate,Stat_cd__c,Type,(SELECT RelationId, Type, EventId FROM EventWhoRelations) FROM Event WHERE Id IN :eventIds];
    for ( Event e :objEventList){
        for(EventWhoRelation evtWhoRelated :e.EventWhoRelations){
             System.debug('Print Task Contacts: ' + evtWhoRelated); 
            if (evtWhoRelated.RelationId != null ){  // checking if size is greater than 0 
                setIds.add(evtWhoRelated.RelationId); // then add in contactId list
            }  
        }
    }
    System.debug('Print Set of Task Contacts: ' + setIds);
    System.debug('Print SetSIZE of Task Contacts: ' + setIds.size());

    map<Id,Contact> mapContact=new map<Id,Contact>([select id,Last_In_Person_Meeting__c from contact where id in :setIds]);
    map<Id,Lead> mapLead=new map<Id,Lead>([select id,Last_In_Person_Meeting__c from Lead where id in :setIds]);
    system.debug('****lstObjectFieldMappingInfo***'+lstObjectFieldMappingInfo);
     for(Event objEvent :objEventList){
        for (EventWhoRelation Relation1 :objEvent.EventWhoRelations){
            if(Relation1.RelationId != null){
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
                    Sobject objSobject=Relation1.RelationId.getSObjectType().newSObject();
                    objSobject.put('Id',Relation1.RelationId);
                    //SS: 11-15 updated if statements to record the activity date on contact record.  
                    if(mapContact.containsKey(Relation1.RelationId) && objEvent.Stat_cd__c ==  'Complete' && 
                        ((mapContact.get(Relation1.RelationId).Last_In_Person_Meeting__c < objEvent.ActivityDate &&
                        mapContact.get(Relation1.RelationId).Last_In_Person_Meeting__c != null) ||
                        mapContact.get(Relation1.RelationId).Last_In_Person_Meeting__c == null )
                        //mapContact.get(objEvent.WhoId).Last_In_Person_Meeting__c != null &&
                        //mapContact.get(objEvent.WhoId).Last_In_Person_Meeting__c < system.today())
                        ){
                        objSobject.put('Last_In_Person_Meeting__c', objEvent.ActivityDate );
                    }
                    else if(mapLead.containsKey(Relation1.RelationId) &&  objEvent.Stat_cd__c == 'Complete' ){
                        objSobject.put('Last_In_Person_Meeting__c', objEvent.ActivityDate );
                    }
                    if(!mapSobjectToUpdate.containsKey(Relation1.RelationId))
                    mapSobjectToUpdate.put(Relation1.RelationId,objSobject);
                }  
            }
        }
    }
    update mapSobjectToUpdate.values();
}