trigger DFJ_UpdateEventSubject on Event (Before insert) {
    if(trigger.isBefore && trigger.isInsert){
        DFJ_EventHandler.UpdateEventSubject(trigger.new);
    }
}