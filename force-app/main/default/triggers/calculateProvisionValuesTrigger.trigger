trigger calculateProvisionValuesTrigger on OrderItem (before insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        DFJ_CalculateProvisionValues.calculateProvisionValues_Apex(Trigger.new);
    }
}