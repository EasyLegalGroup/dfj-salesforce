trigger setRecordTypeTrigger on Lead (before insert,before update,after insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        DFJ_SetRecordType.setRecordType_Apex(Trigger.new,null);
    }else if(Trigger.isBefore && Trigger.isUpdate){
        DFJ_SetRecordType.setRecordType_Apex(Trigger.new,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isInsert){
        // changes for ticket DIN-226 : Create memberships from lead directly
        // Description - Creating membership record after lead creation.
        DFJ_LeadForMembership_Helper.CreateMembership_Apex(Trigger.new);
    }
}