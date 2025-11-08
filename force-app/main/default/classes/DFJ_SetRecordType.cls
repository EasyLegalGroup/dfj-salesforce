public with sharing class DFJ_SetRecordType {

    /**
     * Assign the correct Record Type to each Lead based on Market_Unit__c.
     * • newLeads  – records in the current trigger context  
     * • oldLeads  – null for BEFORE-INSERT,  Trigger.oldMap for BEFORE-UPDATE
     */
    public static void setRecordType_Apex(List<Lead> newLeads,
                                          Map<Id, Lead> oldLeads) {

        if (newLeads == null || newLeads.isEmpty()) return;

        /* ----  cache of Lead record-types keyed by DeveloperName  ---- */
        Map<String, Schema.RecordTypeInfo> infoByName =
            Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName();

        Id hostRT = infoByName.containsKey('Host')
                  ? infoByName.get('Host').getRecordTypeId()
                  : null;

        /* ----  main loop  ---- */
        for (Lead l : newLeads) {

            // skip if Host or Market_Unit__c is blank
            if (l.Market_Unit__c == null ||
                (hostRT != null && l.RecordTypeId == hostRT)) continue;

            // on update: skip if the pick-list didn’t really change
            if (oldLeads != null && oldLeads.containsKey(l.Id) &&
                l.Market_Unit__c == oldLeads.get(l.Id).Market_Unit__c) continue;

            // assign record-type that matches the pick-list
            if (infoByName.containsKey(l.Market_Unit__c)) {
                l.RecordTypeId = infoByName.get(l.Market_Unit__c).getRecordTypeId();
            }
        }
    }
}