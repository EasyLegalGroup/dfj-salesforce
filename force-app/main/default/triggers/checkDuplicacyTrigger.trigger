trigger checkDuplicacyTrigger on Lead(before insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        DFJ_checkDuplicacy.checkDuplicatePhoneNumbers(Trigger.new);
    }
}