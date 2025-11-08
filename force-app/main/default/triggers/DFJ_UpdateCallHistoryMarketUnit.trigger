trigger DFJ_UpdateCallHistoryMarketUnit on telegenta__Telegenta_Call_History__c (before insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        DFJ_UpdateCallHistoryMarketUnit_Apex.setMarketUnit_Apex(Trigger.new);
    }
}