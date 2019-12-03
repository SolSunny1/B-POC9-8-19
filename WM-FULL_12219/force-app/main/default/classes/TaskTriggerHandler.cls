public with sharing class TaskTriggerHandler 
{
  public static Boolean isRunning = false;
  public void onAfterInsert(List<Task> newTaskList)
  {
    List<Id> tasksToUpdate = new List<Id> ();
    for (Task tsk : newTaskList)
    {
      if (tsk.IsClosed == true )
        tasksToUpdate.add(tsk.Id);
    }

    if ( !tasksToUpdate.isEmpty() && !isRunning ){
      isRunning = true;
      UpdateObjects(tasksToUpdate);
    }
  }
  public void onAfterUpdate(List<Task> newTasks, Map<Id, Task> oldTaskMap) 
  {
    List<Id> tasksToUpdate = new List<Id> ();
        
    for (Task tsk : newTasks)
    {
      if (tsk.IsClosed == true)
        tasksToUpdate.add(tsk.Id);
    }

    if ( !tasksToUpdate.isEmpty() && !isRunning ){
      isRunning = true;
      UpdateObjects(tasksToUpdate);
    }
  }
  
    @future
  public static void UpdateObjects  (List<Id> newTaskIds)
  {  
        String queryStr = 'SELECT ' + GetFieldList('Task') +' FROM Task Where Id IN :newTaskIds';
        List<Task> newTasks = (List<Task>)Database.query( queryStr );
    List<task_Updates__c> taskList = [select Task_Field__c, Task_Value__c ,Object_To_Update__c ,Field_To_Update__c ,Child_Object__c,Child_FIeld__c from Task_Updates__c where Active__c = true  ] ;
    
    set<string> sObjectType = new set<string>();
    map<string, string> sObjectList = BuildObjectMap ();
    set<string> UpdateAbleTasks = new set<string>();
    //List<csProperties> propList = new List<csProperties>();
    map<string , List<csProperties> > updateMap = new map<string, List<csProperties>>();
    map<string, string> lookupRelationship = new map<string, string> ();
    Map<Id, Set<String>> taskToWhoIds = new Map<Id, Set<String>>();

    for( TaskWhoRelation  t : [SELECT RelationId,TaskId FROM TaskWhoRelation WHERE TaskId IN :newTasks] ){
      if ( !taskToWhoIds.containsKey( t.TaskId ) )
        taskToWhoIds.put( t.TaskId, new Set<String>() );

      taskToWhoIds.get( t.TaskId ).add( t.RelationId );
    }
    
        System.debug( '--->' + taskToWhoIds );
    for ( Task t : newTasks ){
      if ( taskToWhoIds.containsKey( t.Id ) ){
        if ( t.AccountId != null )
          taskToWhoIds.get( t.Id ).add( t.AccountId );

        for( String idString : taskToWhoIds.get( t.Id ) ){
          csProperties newProp; 
          List<csProperties> tmpPropList = new List<csProperties>();
      
          for ( Task_Updates__c tl : taskList ){
            
            if ( t.get( tl.Task_Field__c ) == tl.Task_Value__c ){
              string prefix = String.valueOf( idString ).substring( 0, 3 );
              //if()
              newProp = new csProperties( idString, tl.Object_To_Update__c, tl.Field_To_Update__c, tl.Child_Object__c, tl.Child_FIeld__c );
              tmpPropList.add( newProp );
              sObjectType.add( sObjectList.get( prefix ) );
              UpdateAbleTasks.add( t.id );
            }

            if ( tmpPropList.size() > 0 )
              updateMap.put( idString, tmpPropList );
          }
        }
      }
    }
    
      
    if (UpdateAbleTasks.size() == 0 )
      return;
    
    
    System.debug( '1--->' + updateMap );  
    map<string, map<string,sObject> > objectList = new map<string, map<string, sObject> >();
    //Query the sObjects 
    set<string> keys = updateMap.keyset();
    for (string sObj : sObjectType )
    {
      List<sObject> recs = database.query('select ' + GetFieldList(sObj) + ' from ' + sObj + ' where id in  :keys');
      
      map<string, sObject> tmpMap = new map<string, sObject>();
      for (sObject o : recs)
        tmpMap.put(o.id, o);
        
      objectList.put(sObj , tmpMap);
      
    }
    
    //Look for Lookup Fields
    
    map<string , List<csProperties> > updateMapLookup = new map<string, List<csProperties>>();
    sObjectType.Clear();
    set<string> RemoveList = new set<string>();
    for (string s : updateMap.keyset() )
    {
      List<csProperties> csList = updateMap.get(s) ;
      map<string, sObject> currentSObjectList ;
      for (csProperties cs : csList)
      {
        
        if (cs.isLookup == true  && sObjectList.get(cs.objId.substring(0,3)) == cs.ChildObject)
        {
          
          currentSObjectList = objectList.get( sObjectList.get(cs.objId.substring(0,3)) ) ;
          //map<string, sObject> tmpMap = new map<string, sObject>();
          sObject sObj = currentSObjectList.get(cs.objId);
          
          
          string idString = String.ValueOf(sobj.get(cs.ChildLookup));
          csProperties newProp = new csProperties (idstring, cs.UpdateObject, cs.UpdateField);
          //newProp.objId = idString;
          
          lookupRelationship.put(cs.ObjId,idString ) ;
          
          if (updateMap.containskey (idstring))
          {
            List<csProperties> csOld = updateMap.get(idString);
            csOld.add(newProp);
            updateMap.put(idString, csOld);
            updateMapLookup.put(idString, csOld);       
          }
          else
          {
            List<csProperties> csNew  = new List<csProperties> ();
            csNew.add(newProp);
            updateMap.put(idString, csNew);
            updateMapLookup.put(idString, csNew);       
          }
                    
          string prefix = String.valueOf(idString).substring(0,3);
          sObjectType.add(sObjectList.get(prefix) );
          
          RemoveList.add(cs.objId) ;
          /*
          if (currentSObjectList.size() == 1 )
            objectList.Remove(cs.ChildObject);
          else
          {   
            currentSObjectList.Remove(cs.objId);
            objectList.put(cs.ChildObject ,currentSObjectList);
            
          }
          */
          sObjectType.add(sObjectList.get(prefix) );
          
          
        }
      }
      
      //for (string s : RemoveList)
      //  ObjectList.Remove(s);
      
    }
    
    for (string s : Removelist)
    {
      string ObjName = sObjectList.get(s.substring(0,3)) ;
      map<string, sObject> removeSObjectList = objectList.get( objName ) ;
      if (removeSObjectList.size() == 1 )
        objectList.Remove(ObjName);
      else
      {   
        removeSObjectList.Remove(s);
        objectList.put(objName ,removeSObjectList);
        
      }
    }
    
    System.Debug('****: ' + updateMapLookup);
    keys = updateMapLookup.keyset();
    for (string sObj : sObjectType )
    {
      List<sObject> recs = database.query('select ' + GetFieldList(sObj) + ' from ' + sObj + ' where id in  :keys');
      
      map<string, sObject> tmpMap = new map<string, sObject>();
      for (sObject o : recs)
        tmpMap.put(o.id, o);
        
      objectList.put(sObj , tmpMap);
      
    }
        
    List<sObject> updateList = new List<sObject>();
    set<string> updateSet = new set<string> ();
    for (Task t : newTasks) {
      if ( taskToWhoIds.containsKey( t.Id ) ){
        for( String idString : taskToWhoIds.get( t.Id ) ){
          
          if ( UpdateAbleTasks.Contains( t.id ) ){
            string prefix = String.valueOf( idString ).substring( 0, 3 );
            List<csProperties> fieldToUpdateList;
            //What Object is the task
            if ( lookupRelationship.containsKey( idString ) )
              idString = lookupRelationship.get( idString );
                            System.debug('idString---->'+idString);
            fieldToUpdateList = updateMap.get( idString );
                        System.debug( '----> obj List ' + sObjectList.get( prefix )  );
                        System.debug( '----> obj List ' + objectList );
            Map<String,sObject> tmpObjMap =  objectList.get( sObjectList.get( prefix ) ); 
                        
            if ( !updateSet.contains( idString ) && tmpObjMap != null ){                            
              SObject sObj = tmpObjMap.get( idString );
              for ( csProperties fieldToUpdate : fieldToUpdateList ){
                if ( fieldToUpdate.UpdateObject ==  sObjectList.get( prefix ) ){

                  Object currDate = sobj.get( fieldToUpdate.UpdateField );
                                    system.debug(currDate+'currDate------>');
                  if ( t.ActivityDate > (Date)currDate )
                    currDate = t.ActivityDate;

                  sObj.put( fieldToUpdate.UpdateField , t.ActivityDate );
                }
              }

              updateSet.add( idString );
              updateList.add( sObj );
            }
          }
        }
      }
    } 
    
    System.debug( '2--->' + updateList );
    if (updateList.size() > 0 ){
      updateList.sort();
      update updateList;
    }
      
    
    
    /*
    
    List<account> acctList = database.query('select ' + GetFieldList('Account') + ' from account where id in  :keys');
    map<string,Account> acctMap = new map<string,Account> ( );
    for (Account a : acctList)
      acctMap.put(a.id, a);
    
    List<Account> updateAccts = new List<Account>();
    for (Task t : newTasks) 
    {
      if (acctMap.containskey(t.whatid))
      {
        Account a = acctMap.get(t.whatid);
        string[] fieldToUpdate = updateMap.get(t.whatid).split(':');
        a.put(fieldToUpdate[1] , t.ActivityDate);
        updateAccts.add(a);
      }
    } 
    
    update updateAccts;
    */
    
  }
  private static string GetFieldList (string ObjectName)
  {
    string retval = '';
    SObjectType objToken = Schema.getGlobalDescribe().get(ObjectName);
    DescribeSObjectResult objDef = objToken.getDescribe();
    Map<String, SObjectField> fields = objDef.fields.getMap(); 
     
    Set<String> fieldSet = fields.keySet();
    for(String s:fieldSet)
    {
      SObjectField fieldToken = fields.get(s);
      DescribeFieldResult selectedField = fieldToken.getDescribe();
      retval += selectedField.getName() + ',' ;
    }
    
    return retval.substring(0, retval.length()-1);
  }
  
  private static map<string, string>  BuildObjectMap ()
  {
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
  class csProperties 
  {
    public string objId {get;set;}
    public string UpdateObject {get;set;}
    public string UpdateField {get;set;}
    public boolean isLookup {get;set;}
    public string ChildObject {get;set;}
    public string ChildLookUp {get;set;}
    
    public csProperties (string id, string updObject, string updField, string childObj , string childField)
    {
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
    public csProperties (string id, string updObject, string updField)
    {
      objId = id;
      UpdateObject = updObject;
      UpdateField = updField;
      isLookup = false;
    }
  }
  
  
}