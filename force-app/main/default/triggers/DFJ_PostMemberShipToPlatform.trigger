trigger DFJ_PostMemberShipToPlatform on Membership__c (after insert, before insert, after update) {
  // if(Trigger.isBefore && Trigger.isInsert){
  //   DFJ_MembershipTriggerHandler.SetFirstNLastName(Trigger.new);
  // }
  if(Trigger.isAfter && Trigger.isInsert){
    DFJ_MembershipTriggerHandler.SetMembershipBody(Trigger.new);
  }
   
      
}