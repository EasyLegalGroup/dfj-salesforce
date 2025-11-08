trigger ContentVersionTrigger on ContentVersion (after insert) {

    ContentVersionTriggerHander.AttachAccount(Trigger.New);
}