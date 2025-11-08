trigger JournalTrigger on Journal__c (after update) {
    NoteTriggerHandler.handleJournalUpdate(Trigger.new, Trigger.oldMap);
}