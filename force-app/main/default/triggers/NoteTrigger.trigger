trigger NoteTrigger on Note (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        NoteTriggerHandler.handleNoteInsertUpdate(Trigger.new);
    }
}