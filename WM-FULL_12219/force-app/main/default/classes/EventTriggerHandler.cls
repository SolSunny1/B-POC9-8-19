public with sharing class EventTriggerHandler {
    public EventTriggerHandler() {
        
    }

    public void onAfterInsert( List<Event> newEventList ){
        List<Id> eventsToUpdate = new List<Id> (); 
        for ( Event eve : newEventList ){
            if ( eve.EndDateTime < System.now() )
                eventsToUpdate.add( eve.Id );
        }

        if ( !eventsToUpdate.isEmpty() )
            updateObjects( eventsToUpdate );

    }

    public void onAfterUpdate( List<Event> newEvents, Map<Id, Event> oldEventMap ){
        List<Id> eventsToUpdate = new List<Id> ();
        for ( Event eve : newEvents ){
            if ( eve.EndDateTime < System.now())
                EventsToUpdate.add( eve.Id );
        }

        if ( !eventsToUpdate.isEmpty() )
            updateObjects( eventsToUpdate );
    }
    
    @future
    public static void UpdateObjects ( List<Id> newEventIds ){
        String queryStr = 'SELECT ' + GetFieldList('Event') +' FROM Event Where Id IN :newEventIds';
        List<Event> newEvents = (List<Event>)Database.query( queryStr );
        List<Event_Updates__c> eventList = [SELECT Event_Field__c, Event_Value__c,
                                                   Object_To_Update__c, Field_To_Update__c, 
                                                   Child_Object__c,Child_FIeld__c 
                                            FROM Event_Updates__c 
                                            WHERE Active__c = true  ] ;
        
        
        Set<String> sObjectType = new Set<String>();
        Map<String, string> sObjectList = buildObjectMap ();
        Set<String> updateAbleEvents = new Set<String>();
        //List<csProperties> propList = new List<csProperties>();
        Map<String , List<csProperties> > updateMap = new Map<String, List<csProperties>>();
        Map<String, String> lookupRelationship = new Map<String, String> ();
        Map<Id, Set<String>> eventToWhoIds = new Map<Id, Set<String>>();

        for( EventWhoRelation t : [SELECT RelationId,EventId FROM EventWhoRelation WHERE EventId IN :newEvents] ){

            if ( !eventToWhoIds.containsKey( t.EventId ) )
                eventToWhoIds.put( t.EventId, new Set<String>() );

            eventToWhoIds.get( t.EventId ).add( t.RelationId );
        }

        for (Event t : newEvents){
            if ( eventToWhoIds.containsKey( t.Id ) ){
                if ( t.AccountId != null )
                    eventToWhoIds.get( t.Id ).add( t.AccountId );

                for( String idString : eventToWhoIds.get( t.Id ) ){    
                    csProperties newProp; 
                    List<csProperties> tmpPropList = new List<csProperties>();
                    
                    for (Event_Updates__c tl : EventList){
                        if (t.get(tl.Event_Field__c) == tl.Event_Value__c ){
                            String prefix = String.valueOf( idString ).substring( 0, 3 );
                            newProp = new csProperties(idString, tl.Object_To_Update__c ,tl.Field_To_Update__c ,tl.Child_Object__c,tl.Child_FIeld__c);
                            tmpPropList.add(newProp);
                                            
                            prefix = String.valueOf(idString).substring(0,3);
                            sObjectType.add(sObjectList.get(prefix) );
                                
                            updateAbleEvents.add(t.id);
                        }
                        if (tmpPropList.size() >0)
                            updateMap.put(idString, tmpPropList);
                    }
                    
                }
            }
        }
        
            
        if ( updateAbleEvents.size() == 0 )
            return;
        
            
        Map<String, Map<String,sObject> > objectList = new Map<String, Map<String, sObject>>();
        //Query the sObjects 
        Set<String> keys = updateMap.keyset();
        for( String sObj : sObjectType ){
            List<sObject> recs = database.query('select ' + GetFieldList(sObj) + ' from ' + sObj + ' where id in  :keys');
            
            Map<string, sObject> tmpMap = new Map<string, sObject>();
            for (sObject o : recs)
                tmpMap.put(o.id, o);
                
            objectList.put(sObj , tmpMap);
        }
        
        //Look for Lookup Fields
        
        Map<String , List<csProperties>> updateMapLookup = new Map<string, List<csProperties>>();
        sObjectType.Clear();
        Set<String> removeList = new Set<String>();
        for ( String s : updateMap.keyset() ){
            List<csProperties> csList = updateMap.get(s) ;
            Map<String, sObject> currentSObjectList ;
            for ( csProperties cs : csList ){
                if (cs.isLookup == true  && sObjectList.get( cs.objId.substring( 0,3 ) ) == cs.ChildObject ){   
                    currentSObjectList = objectList.get( sObjectList.get(cs.objId.substring(0,3)) ) ;
                    //map<string, sObject> tmpMap = new map<string, sObject>();
                    sObject sObj = currentSObjectList.get(cs.objId);
                    
                    
                    string idString = String.ValueOf( sobj.get(cs.ChildLookup ) );
                    csProperties newProp = new csProperties ( idstring, cs.UpdateObject, cs.UpdateField );
                    //newProp.objId = idString;
                    
                    lookupRelationship.put( cs.ObjId,idString );
                    
                    if ( updateMap.containskey ( idstring ) ){
                        List<csProperties> csOld = updateMap.get(idString);
                        csOld.add(newProp);
                        updateMap.put(idString, csOld);
                        updateMapLookup.put(idString, csOld);       
                    }else{
                        List<csProperties> csNew  = new List<csProperties> ();
                        csNew.add( newProp );
                        updateMap.put( idString, csNew );
                        updateMapLookup.put( idString, csNew );
                    }
                                        
                    string prefix = String.valueOf( idString ).substring( 0, 3 );
                    sObjectType.add( sObjectList.get( prefix ) );
                    
                    removeList.add( cs.objId );
                    sObjectType.add(sObjectList.get( prefix ) );
                }
            }
        }
        
        for ( String s : removelist){
            String objName = sObjectList.get( s.substring( 0, 3 ) ) ;
            Map<String, sObject> removeSObjectList = objectList.get( objName ) ;
            if (removeSObjectList.size() == 1 )
                objectList.remove( objName );
            else{   
                removeSObjectList.remove( s );
                objectList.put( objName, removeSObjectList );
            }
        }
        
        System.Debug('****: ' + updateMapLookup);
        keys = updateMapLookup.keyset();
        for ( String sObj : sObjectType ){
            List<sObject> recs = database.query('select ' + GetFieldList(sObj) + ' from ' + sObj + ' where id in  :keys');
            
            Map<String, sObject> tmpMap = new Map<String, sObject>();
            for ( sObject o : recs )
                tmpMap.put(o.id, o);
                
            objectList.put(sObj , tmpMap);
        }
                
        List<sObject> updateList = new List<sObject>();
        Set<String> updateSet = new Set<String>();
        for (Event t : newEvents) {
            if ( eventToWhoIds.containsKey( t.Id ) ){
                for( String idString : eventToWhoIds.get( t.Id ) ){
                    
                    if (updateAbleEvents.contains(t.id) ){
                        string prefix = String.valueOf( idString ).substring( 0, 3 );
                        List<csProperties> fieldToUpdateList;
                        //What Object is the Event
                        if (lookupRelationship.ContainsKey(idString) )
                            idString = lookupRelationship.get(idString);
                        prefix = String.valueOf(idString).substring(0,3);
                        fieldToUpdateList = updateMap.get(idString) ;
                        map<string,sObject> tmpObjMap =  objectList.get(sObjectList.get(prefix)); 
                        
                        
                        if (!updateSet.contains(idString) ){
                            sObject sObj = tmpObjMap.get(idString);
                            for (csProperties fieldToUpdate : fieldToUpdateList ){
                                if (fieldToUpdate.UpdateObject ==  sObjectList.get(prefix)){
                                    Object currDate = sobj.get( fieldToUpdate.UpdateField );
                                    if ( t.ActivityDate > (Date)currDate )
                                        currDate = t.ActivityDate;

                                    sObj.put( fieldToUpdate.UpdateField , t.ActivityDate );
                                }
                            }
                            updateSet.add(idString);
                            updateList.add(sObj);
                        }
                    }
                }
            }
        } 
        
        if (updateList.size() > 0 ){
            updateList.sort();
            update updateList;      
        }
    }

    private static string getFieldList (string ObjectName){
        string retval = '';
        SObjectType objToken = Schema.getGlobalDescribe().get(ObjectName);
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap(); 
       
        Set<String> fieldSet = fields.keySet();
        for(String s:fieldSet)
        {
            system.debug(fields.get(s)+'fields.get(s)------->');
            SObjectField fieldToken = fields.get(s);
            DescribeFieldResult selectedField = fieldToken.getDescribe();
            retval += selectedField.getName() + ',' ;
        }
        
        return retval.substring(0, retval.length()-1);
    }
    
    private static map<string, string> buildObjectMap (){
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        map<string, string> mapObjectList = new map<string, string> ();
        for(Schema.SObjectType stype : gd.values())
        {
            Schema.DescribeSObjectResult r = stype.getDescribe();
            String prefix = r.getKeyPrefix();
            mapObjectList.put(prefix , String.ValueOf(r.getSObjectType()) );
            
        }
        return mapObjectList ;
    }

    class csProperties{
        public string objId {get;set;}
        public string UpdateObject {get;set;}
        public string UpdateField {get;set;}
        public boolean isLookup {get;set;}
        public string ChildObject {get;set;}
        public string ChildLookUp {get;set;}
        
        public csProperties (string id, string updObject, string updField, string childObj , string childField){
            objId = id;
             UpdateObject = updObject;
             UpdateField = updField;
             if (childObj != null && childField != null)
             {
                isLookup = true;
                ChildObject = childObj;
                ChildLookUp = childField;
             }
             else
                isLookup = false;
        }

        public csProperties (string id, string updObject, string updField){
            objId = id;
            UpdateObject = updObject;
            UpdateField = updField;
            isLookup = false;
        }
    }
}