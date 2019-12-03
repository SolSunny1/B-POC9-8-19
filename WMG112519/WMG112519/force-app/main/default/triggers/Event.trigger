Trigger Event on Event (after insert, after update) {

  EventTriggerHandler handler = new EventTriggerHandler ();
    
    if( Trigger.isAfter && Trigger.isUpdate ) {
        handler.onAfterUpdate( Trigger.new, Trigger.oldMap );
    }
    
    if ( Trigger.isAfter && Trigger.isInsert )
      handler.onAfterInsert( Trigger.new ) ;
}