public with sharing class EnrichCustomerProfile {

    /* -------- Public entry point for Flow -------- */
    @InvocableMethod(label='Enrich Customer Profile')
    public static void enrich(List<Id> submissionIds) {

        if (submissionIds == null || submissionIds.isEmpty()) return;

        /* 1. Find the submissions that really have a parent profile */
        Map<Id, Id> submissionToProfile = new Map<Id, Id>();

        for (Form_Submission__c fs :
             [SELECT Id, Customer_Profile__c
              FROM   Form_Submission__c
              WHERE  Id IN :submissionIds
              AND    Customer_Profile__c != NULL]) {

            submissionToProfile.put(fs.Id, fs.Customer_Profile__c);
        }
        if (submissionToProfile.isEmpty()) return;

        /* 2. Field names that exist (and are write-able) on BOTH objects */
        Set<String> commonWriteable = getCommonWriteableFields();
        if (commonWriteable.isEmpty()) return;

        /* 3. Build SELECT clause without duplicates */
        List<String> selectList = new List<String>{ 'Id', 'Customer_Profile__c' };
        for (String f : commonWriteable) {
            if (f != 'Id' && f != 'Customer_Profile__c') selectList.add(f);
        }

        String soql =
            'SELECT ' + String.join(selectList, ',') +
            ' FROM Form_Submission__c WHERE Id IN :submissionIds';

        List<Form_Submission__c> detailedSubs = Database.query(soql);

        /* 4. Copy non-null values into stub Customer Profile records */
        Map<Id, Customer_Profile__c> updates = new Map<Id, Customer_Profile__c>();

        for (Form_Submission__c fs : detailedSubs) {
            Id profileId = submissionToProfile.get(fs.Id);
            if (profileId == null) continue;                 // safety

            Customer_Profile__c stub = updates.get(profileId);
            if (stub == null) {
                stub = new Customer_Profile__c(Id = profileId);
                updates.put(profileId, stub);
            }
            for (String fieldName : commonWriteable) {
                Object val = fs.get(fieldName);
                if (val != null) stub.put(fieldName, val);   // write only when NOT null
            }
        }

        if (!updates.isEmpty()) update updates.values();
    }

    /* -------- Helper: identify common, *create-able* fields -------- */
    @TestVisible private static Set<String> getCommonWriteableFields() {

        Map<String, Schema.SObjectField> fsFields =
            Form_Submission__c.SObjectType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> cpFields =
            Customer_Profile__c.SObjectType.getDescribe().fields.getMap();

        Set<String> common = new Set<String>();

        for (String name : fsFields.keySet()) {
            if (!cpFields.containsKey(name)) continue;                       // not on both
            if (!fsFields.get(name).getDescribe().isCreateable()) continue;  // read-only
            if (!cpFields.get(name).getDescribe().isUpdateable()) continue;  // read-only
            common.add(name);
        }
        /* “Id” is never copied; remove if it slipped through */
        common.remove('Id');
        return common;
    }
}