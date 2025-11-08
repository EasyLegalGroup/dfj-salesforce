trigger SMSTrigger on SMS__c (before insert, before update) {
    SMSTriggerHandler.beforeUpsert(Trigger.new, Trigger.oldMap);
}