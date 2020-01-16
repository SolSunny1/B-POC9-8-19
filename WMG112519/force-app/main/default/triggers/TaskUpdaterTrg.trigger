trigger TaskUpdaterTrg on Task (after insert, after update) 
{
  TaskTriggerHandler handler = new TaskTriggerHandler ();
    
    if(Trigger.isAfter && Trigger.isUpdate) {
        handler.onAfterUpdate(Trigger.new,Trigger.oldMap);
    }
    
    if (Trigger.isAfter && Trigger.isInsert)
      handler.onAfterInsert(trigger.new) ;
}