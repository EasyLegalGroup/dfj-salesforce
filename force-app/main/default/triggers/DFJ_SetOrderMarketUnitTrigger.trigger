trigger DFJ_SetOrderMarketUnitTrigger on Order (after insert) {
    if(Trigger.isAfter && Trigger.isInsert){
        DFJ_SetOrderMarketUnit.setOrderMarketUnit_Apex(Trigger.new);
    }
}