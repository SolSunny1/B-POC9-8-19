public with sharing class ManageTaskUpdateExtension 
{
  private final Task_Updates__c TaskUpdateObj ;
  private final string theID;
  public string objID {get;set;}
  public string Test {get;set;} 
  public boolean ShowFieldToUpdate {get;set;}
  public boolean ShowRelationshipObj {get;set;}
  public boolean ShowRelationshipObjField {get;set;}
  
  private set<string> taskObjects; 
  
  public ManageTaskUpdateExtension (ApexPages.Standardcontroller controller)
  {
    TaskUpdateObj = (Task_Updates__c)Controller.getRecord();
    theId = Controller.getId();
    Test = TaskUpdateObj.Task_Field__c;
    ShowFieldToUpdate = true;
    ShowRelationshipObj = true;
    ShowRelationshipObjField = true;
    populateTaskObjectList () ;
  }
  public list<Task_Updates__c> getTaskUpdateList()
  {
    return [select id, Name, Active__c , Object_To_Update__c , Child_Field__c, Child_Object__c , Field_To_Update__c , Task_Field__c , Task_Value__c from Task_Updates__c ];
  }
  
  public PageReference OverRideSave ()
  {
    boolean isError = false;
    
    if (TaskUpdateObj.Task_Field__c == null || TaskUpdateObj.Task_Field__c == 'None')
    {
      isError = true;
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid value for Task Field to Match');
          ApexPages.addMessage(myMsg);
    }
    if (TaskUpdateObj.Task_Value__c == null || TaskUpdateObj.Task_Value__c == 'None')
    {
      isError = true;
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid value for Task Field Value');
          ApexPages.addMessage(myMsg);
    }
    if (TaskUpdateObj.Object_To_Update__c == null || TaskUpdateObj.Object_To_Update__c == 'None')
    {
      isError = true;
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid value for Object To Update');
          ApexPages.addMessage(myMsg);
    }
    if (TaskUpdateObj.Field_To_Update__c == null || TaskUpdateObj.Field_To_Update__c == 'None')
    {
      isError = true;
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid value for Field To Update');
          ApexPages.addMessage(myMsg);
    }
    
    if (isError)
      return null;
      
      
    if (TaskUpdateObj.Child_Object__c == 'None')
      TaskUpdateObj.Child_Object__c = null;
    if (TaskUpdateObj.Child_Field__c == 'None')
      TaskUpdateObj.Child_Field__c = null;
      
    if (TaskUpdateObj.id == null)
      insert TaskUpdateObj;
    else
      update TaskUpdateObj;
    return null;
  }
  public PageReference CloneRec ()
  {
    Task_Updates__c newObj = new Task_Updates__c(
      Name = 'New_' + TaskUpdateObj.Name,
      Active__c = TaskUpdateObj.Active__c, 
      Object_To_Update__c = TaskUpdateObj.Object_to_Update__c, 
      Child_Field__c = TaskUpdateObj.Child_Field__c, 
      Child_Object__c = TaskUpdateObj.Child_Object__c , 
      Field_To_Update__c = TaskUpdateObj.Field_To_Update__c , 
      Task_Field__c = TaskUpdateObj.Task_Field__c , 
      Task_Value__c = TaskUpdateObj.Task_Value__c);
    
    insert newObj;
    PageReference pageRef=  new PageReference('/apex/ManageTaskUpdates?id=' + newObj.id);
    pageRef.setRedirect(true);
    return pageRef ;
  }
  
  public List<SelectOption> getTasksPickListValues ()
    {
      string ObjName = 'Task';
      List<SelectOption> optionList = new List<SelectOption>();
       optionList.add(new SelectOption('None','- None -'));
       string objField = TaskUpdateObj.Task_Field__c;
       
       if (objField == null || objField == 'None')
         return optionList;
         
      
      
      Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Map <String, Schema.SObjectField> field_Map = schemaMap.get(objName).getDescribe().fields.getMap();
    List<Schema.PicklistEntry> ple = field_map.get(objField).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
       
       for (Schema.PicklistEntry pe : ple)
       {
         optionList.add(new SelectOption( pe.getValue() , pe.getValue()   ));
       }
       return optionList;
    }
    
    public void ResetChildValues () 
    {
      TaskUpdateObj.Field_To_Update__c = null;
      TaskUpdateObj.Child_Object__c = null;
      TaskUpdateObj.Child_Field__c = null;
    }
    public List<SelectOption> getObjectList ()
    {
      List<SelectOption> optionList = new List<SelectOption>();
    optionList.add(new SelectOption('None','- None -'));
      Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();  
      List<string> objList = new List<string>();
      for (string s : schemaMap.keyset())
      {
        Schema.SObjectType sObjType = schemaMap.get(s) ;
        if (taskObjects.contains(String.ValueOf(sObjType)))
          objList.add(String.ValueOf(sObjType)) ;
          
      }
      objList.sort();
      for (string s : objList )
        optionList.add(new SelectOption(s, s ));
      return optionList;
    }
    
    public List<SelectOption> getRelationshipObjects ()
    {
      List<SelectOption> optionList = new List<SelectOption>();
    optionList.add(new SelectOption('None','- None -'));
    
      string objToUpdate =  TaskUpdateObj.Object_To_Update__c ;
      this.ShowRelationshipObj = true;
      
      if (objToUpdate == null || objToUpdate == 'None')
        return optionList;
        
      Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.DescribeSObjectResult   describeresult = schemaMap.get(objToUpdate).getDescribe() ;
    System.Debug(describeresult) ;
    List<Schema.ChildRelationship>   lstchildrelationships = describeresult.getChildRelationships(); 
    
    integer counter = 0;
    
    for(Schema.ChildRelationship relname : lstchildrelationships)
    {
      if (String.ValueOf(relname.getChildSObject())  != TaskUpdateObj.Object_To_Update__c && taskObjects.contains(String.ValueOf(relname.getChildSObject())) )
      {
        optionList.add(new SelectOption(String.ValueOf(relname.getChildSObject()) , String.ValueOf(relname.getChildSObject()) ));
        counter++;
      }
    }
    if (counter > 0)
      this.ShowRelationshipObj = false;
      
    return optionList ;
    }
    public List<SelectOption> getObjectFieldList ()
    {
      List<SelectOption> optionList = new List<SelectOption>();
    optionList.add(new SelectOption('None','- None -'));
    string ObjName = TaskUpdateObj.Object_To_Update__c ;
    this.ShowFieldToUpdate = true;
    this.ShowRelationshipObj = true;
    this.ShowRelationshipObjField = true;
    
    if (ObjName == null || ObjName == 'None')
      return optionList;
      
      Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Map <String, Schema.SObjectField> field_Map = schemaMap.get(objName).getDescribe().fields.getMap();
    integer foundValues = 0;
    for (string fName : field_Map.keyset() )
    {
      Schema.SObjectField  obj = (field_Map .get(fName) ) ;
      if (obj.getDescribe().isUpdateable() && String.ValueOf(obj.getDescribe().getType()) == 'Date' )
      {
        optionList.add(new SelectOption( obj.getDescribe().getName() , obj.getDescribe().getLabel()  ));
        foundValues++;
      }
    }
    if (foundValues > 0)
    {
      this.ShowFieldToUpdate = false;
      this.ShowRelationshipObj = false;
      this.ShowRelationshipObjField = true;
    }
      
    return optionlist;
    
    }
    public List<SelectOption> getRelationshipfields ()
    {
      List<SelectOption> optionList = new List<SelectOption>();
    optionList.add(new SelectOption('None','- None -'));
      string ObjName = TaskUpdateObj.Object_To_Update__c ;
      ShowRelationshipObjField = true;
      
    if (ObjName == null || ObjName == 'None')
      return optionList;
      
      SObjectType objToken = Schema.getGlobalDescribe().get(ObjName);
     DescribeSObjectResult objDef = objToken.getDescribe();
    
    
    List<Schema.ChildRelationship>   lstchildrelationships = objDef.getChildRelationships(); 
    integer counter = 0;
    
    for(Schema.ChildRelationship relname:lstchildrelationships)
    {
      if (String.ValueOf(relname.getChildSObject()) == TaskUpdateObj.Child_Object__c)
      {
        optionList.add(new SelectOption( String.ValueOf(relname.getField()) , String.ValueOf(relname.getField()) ));
        counter++;
      }
     
    }
    if (counter > 0)
      ShowRelationshipObjField = false;
      
    return optionList ;
    
    }
  public List<SelectOption> getTaskFields ()
  {
    List<SelectOption> optionList = new List<SelectOption>();
    optionList.add(new SelectOption('None','- None -'));
    Map<String, Schema.SObjectField> M = Schema.SObjectType.Task.fields.getMap();

    for(string fName : M.keySet() )
        {
      Schema.SObjectField  obj = (m.get(fName) ) ;
      //System.Debug(fName + ':' + obj.getDescribe().isUpdateable);
      if (obj.getDescribe().isUpdateable() && String.ValueOf(obj.getDescribe().getType()) == 'PICKLIST'
      &&  !String.ValueOf(obj.getDescribe().getLabel()).contains('Recurrence') )
      //&& String.ValueOf(obj.getDescribe().getType()) != 'URL'
      //&&  !String.ValueOf(obj.getDescribe().getLabel()).contains('Recurrence') )
        optionList.add(new SelectOption( obj.getDescribe().getName() , obj.getDescribe().getLabel()  ));
    }
      
      
    return optionlist;
      
  }
  
  private void populateTaskObjectList ()
  {
    taskObjects = new set<string> ();
  
    //Set<Schema.SObjectType> objectsWithActivitiesEnabled = new Set<Schema.SObjectType>();
    //String objectNames = '';
    for (Schema.SObjectType objectType : Task.WhoId.getDescribe().getReferenceTo()) {
      taskObjects.add(String.ValueOf(objectType)  );
    }
    for (Schema.SObjectType objectType : Task.WhatId.getDescribe().getReferenceTo()) {
      taskObjects.add( String.ValueOf(objectType) );
    }
         //objectsWithActivitiesEnabled.add(objectType);
         //objectNames += '\n' + objectType;
  }


}