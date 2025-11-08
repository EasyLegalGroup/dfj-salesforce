/**
 * @description This class is used to fetch the consolidated history data for the
 * current record and the associated contacts with their history.
 */
public with sharing class DFJ_ShowHistory_Apex {

    /**
     * @description Wrapper used to fetch the consolidated history data for the
     * current record and the associated contacts with their history.
     */
    public class ConsolidatedDataWrapper {
        @AuraEnabled public List<HistoryDataWrapper> currentRecordHistoryData { get; set; }
        @AuraEnabled public List<ContactWithHistoryDataWrapper> contactsWithHistoryData { get; set; }

        public ConsolidatedDataWrapper() {
            currentRecordHistoryData = new List<HistoryDataWrapper>();
            contactsWithHistoryData = new List<ContactWithHistoryDataWrapper>();
        }
    }

    /**
     * @description Wrapper for the contact with their history.
     */
    public class ContactWithHistoryDataWrapper {
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public List<HistoryDataWrapper> listOfDataToShowInHistory { get; set; }

        public ContactWithHistoryDataWrapper() {
            listOfDataToShowInHistory = new List<DFJ_ShowHistory_Apex.HistoryDataWrapper>();
        }
    }

    /**
     * @description Wrapper for the history data.
     */
    public class HistoryDataWrapper {
        @AuraEnabled public String sobjectName { get; set; }
        @AuraEnabled public SObject record { get; set; }
    }

    /**
     * @description This method is used to fetch the consolidated history data for the
     * current record and the associated contacts with their history.
     *
     * @param recordId Record ID of the sObject.
     * @param objectName sObjectName of the sObject.
     * @return Returns an instance of ConsolidatedDataWrapper class.
     */
    @AuraEnabled
    public static ConsolidatedDataWrapper getConsolidatedData(String recordId, String objectName) {
        try {
            ConsolidatedDataWrapper consolidatedData = new ConsolidatedDataWrapper();

            // get contactId to contact map of all contacts related to the account
            Map<Id, Contact> mapIdVsContact;

            if (objectName.equals('Account')) {
                mapIdVsContact = new Map<Id, Contact>([SELECT Id, Name FROM Contact WHERE AccountId = :recordId ORDER BY CreatedDate DESC LIMIT 1000]);
            }

            Map<Id, ContactWithHistoryDataWrapper> mapContactIdVsContactWithHistoryDataWrapper = new Map<Id, ContactWithHistoryDataWrapper>();

            // get all the notes related to the contact
            List<Note> noteList = [
                    SELECT Id, ParentId, Parent.Name, Title, Body, CreatedDate, CreatedBy.Name
                    FROM Note
                    WHERE
                            ParentId IN :mapIdVsContact.keySet() OR
                            ParentId = :recordId
                    ORDER BY CreatedDate DESC
                    LIMIT 10000
            ];

            // add contactId, name of every contacts in mapContactIdVsContactWithHistoryDataWrapper
            for (Id contactId:mapIdVsContact.keySet()){
                ContactWithHistoryDataWrapper contactWithHistoryDataWrapperObject = new ContactWithHistoryDataWrapper();

                contactWithHistoryDataWrapperObject.contactId = contactId;
                contactWithHistoryDataWrapperObject.contactName = mapIdVsContact.get(contactId).Name;

                mapContactIdVsContactWithHistoryDataWrapper.put(contactId, contactWithHistoryDataWrapperObject);
            }

            for (Note currentNote : noteList) {
                Id parentIdOfNote = currentNote.ParentId;
                if (parentIdOfNote != null) {
                    populateHistoryData(mapIdVsContact, mapContactIdVsContactWithHistoryDataWrapper, parentIdOfNote, 'Note', currentNote, recordId, consolidatedData);
                }
            }


            List<telegenta__Call_Campaign_State__c> callCampaignStateList = new List<telegenta__Call_Campaign_State__c>();
            Set<Id> idSet = mapIdVsContact.keySet();

            String childObjectName = objectName.equals('Account') ? 'Contact' : null;

            String getCallCampaignStateQuery;
            if (objectName.equals('Account')) {

                getCallCampaignStateQuery = 'SELECT telegenta__Call_Campaign__c,' +
                        'telegenta__Last_Call_Time__c,' +
                        'telegenta__Call_Campaign__r.telegenta__Lead_group__c,' +
                        'telegenta__Call_Campaign__r.Name,' +
                        'telegenta__Last_Outcome__c,' +
                        'telegenta__Has_appointment__c,' +
                        'telegenta__Caller_Id__c,' +
                        'telegenta__Phone_Number__c,' +
                        'telegenta__Next_Call_Time__c,' +
                        'telegenta__Unsuccessful_calls__c,' +
                        'telegenta__Lock_Period__c,' +
                        'telegenta__Total_Unsucccessful_Call__c,' +
                        'telegenta__' + objectName + '__c,' +
                        'telegenta__' + childObjectName + '__c,' +
                        'telegenta__Total_calls__c,' +
                        'telegenta__Stop_Calling__c ' +
                        'FROM telegenta__Call_Campaign_State__c WHERE ' +
                        'telegenta__' + objectName + '__c = \'' + recordId + '\'  ' +
                        'OR ' + 'telegenta__' + childObjectName + '__c ' + 'IN :idSet ' +
                        'ORDER BY CreatedDate DESC LIMIT 10000';

            }

            callCampaignStateList = getCallCampaignStateQuery == null ? (new List<telegenta__Call_Campaign_State__c>()) : Database.query(getCallCampaignStateQuery);


            if (!callCampaignStateList.isEmpty()) {
                Map<String, telegenta__Call_Campaign_State__c> callCampaignStateIdVsCallCampaignState = new Map<String, telegenta__Call_Campaign_State__c>();
                for (telegenta__Call_Campaign_State__c callCampaignStateLoop : callCampaignStateList) {
                    callCampaignStateIdVsCallCampaignState.put(callCampaignStateLoop.Id, callCampaignStateLoop);
                }

                List<telegenta__Call_Campaign_State__History> callCampaignStateHistories = new List<telegenta__Call_Campaign_State__History>();
                callCampaignStateHistories = [SELECT Id, IsDeleted, ParentId, CreatedById,
                        CreatedDate, CreatedBy.Name, Field, DataType, OldValue, NewValue
                FROM telegenta__Call_Campaign_State__History WHERE Field = 'telegenta__Last_Outcome__c' AND ParentId IN :callCampaignStateIdVsCallCampaignState.keySet() AND DataType = 'Text' LIMIT 50000];

                for (telegenta__Call_Campaign_State__History callCampaignStateHistory : callCampaignStateHistories) {

                    Id idOfRelatedParentRecord;
                    if (callCampaignStateIdVsCallCampaignState.containsKey(callCampaignStateHistory.ParentId)) {
                        idOfRelatedParentRecord = (Id) (callCampaignStateIdVsCallCampaignState.get(callCampaignStateHistory.ParentId)).get('telegenta__' + objectName + '__c');

                        if (idOfRelatedParentRecord == null) {
                            idOfRelatedParentRecord = (Id) (callCampaignStateIdVsCallCampaignState.get(callCampaignStateHistory.ParentId)).get('telegenta__' + childObjectName + '__c');
                        }
                    }

                    if (idOfRelatedParentRecord != null) {
                        populateHistoryData(mapIdVsContact, mapContactIdVsContactWithHistoryDataWrapper,
                                idOfRelatedParentRecord, 'telegenta__Call_Campaign_State__History', callCampaignStateHistory, recordId, consolidatedData);
                    }
                }
            }

            List<telegenta__Telegenta_Call_History__c> callHistories = new List<telegenta__Telegenta_Call_History__c>();

            if (objectName.equals('Account')) {

                String queryContent = 'SELECT Id,telegenta__Account__c,' +
                        'telegenta__Account__r.Name,telegenta__Contact__c,telegenta__Contact__r.Name,telegenta__Lead__c,telegenta__Lead__r.Name,telegenta__Call_Start_Time__c,' +
                        'telegenta__Active_Duration__c,telegenta__Total_Duration__c,telegenta__Call_End_Time__c,telegenta__Caller_Number__c,telegenta__Destination_Country__c,' +
                        'telegenta__Destination_number__c,telegenta__Direction__c,telegenta__Disposition__c,CreatedDate,CreatedBy.Name,telegenta__Incoming_Number__c ' +
                        'FROM telegenta__Telegenta_Call_History__c ' +
                        'WHERE ' +
                        'telegenta__' + objectName + '__c = \'' + recordId + '\'  ' +
                        'OR ' + 'telegenta__' + childObjectName + '__c ' + 'IN :idSet ' +
                        'ORDER BY CreatedDate DESC LIMIT 10000';

                callHistories = Database.query(
                        queryContent
                );

            }

            for (telegenta__Telegenta_Call_History__c callHistoryRecord : callHistories ) {

                Id idOfRelatedParentRecord = (Id) callHistoryRecord.get('telegenta__' + objectName + '__c');

                if (idOfRelatedParentRecord != null) {
                    populateHistoryData(mapIdVsContact, mapContactIdVsContactWithHistoryDataWrapper, idOfRelatedParentRecord, 'telegenta__Telegenta_Call_History__c',
                            callHistoryRecord, recordId, consolidatedData);
                }

                idOfRelatedParentRecord = (Id) callHistoryRecord.get('telegenta__' + childObjectName + '__c');

                if (idOfRelatedParentRecord != null) {
                    populateHistoryData(mapIdVsContact, mapContactIdVsContactWithHistoryDataWrapper, idOfRelatedParentRecord, 'telegenta__Telegenta_Call_History__c',
                            callHistoryRecord, recordId, consolidatedData);
                }
            }

            // field history
            List<SObject> listOfFieldHistories = new List<SObject>();

            String queryContent = 'SELECT Id,Field,AccountId,OldValue,NewValue,CreatedById,CreatedDate,CreatedBy.Name FROM ' +
                    objectName+'History WHERE ' +
                    objectName+'Id = :recordId AND ' +
                    '                    Field != \'created\'' +
                    '            LIMIT 50000';
            listOfFieldHistories = Database.query(queryContent);

            for (SObject currentFieldHistoryRecord : listOfFieldHistories) {
                HistoryDataWrapper historyDataWrapperObject = new HistoryDataWrapper();

                historyDataWrapperObject.record = currentFieldHistoryRecord;
                historyDataWrapperObject.sobjectName = 'FieldHistory';

                consolidatedData.currentRecordHistoryData.add(historyDataWrapperObject);
            }

            if(String.isNotBlank(childObjectName)){
                // field history for child object
                queryContent = 'SELECT Id,Field,' +
                        childObjectName + 'Id' + ',' + 'OldValue,NewValue,CreatedById,CreatedDate,CreatedBy.Name ' +
                        'FROM ' +
                        childObjectName + 'History WHERE ' +
                        childObjectName + 'Id IN :idSet AND ' +
                        '                    Field != \'created\'' +
                        '            LIMIT 50000';

                listOfFieldHistories = Database.query(queryContent);

                for (SObject currentFieldHistoryRecord : listOfFieldHistories) {
                    Id idOfRelatedParentRecord = (Id) currentFieldHistoryRecord.get(childObjectName + 'Id');

                    HistoryDataWrapper historyDataWrapperObject = new HistoryDataWrapper();

                    historyDataWrapperObject.record = currentFieldHistoryRecord;
                    historyDataWrapperObject.sobjectName = 'FieldHistory';

                    mapContactIdVsContactWithHistoryDataWrapper.get(idOfRelatedParentRecord).listOfDataToShowInHistory.add(historyDataWrapperObject);
                }
            }

            // event history
            List<Event> eventsList = new List<Event>();
            eventsList = [
                    SELECT Id,OwnerId,Description,Subject,StartDateTime,EndDateTime,
                            WhoId,WhatId,
                                    CreatedDate,CreatedBy.Name FROM Event
                    WHERE
                            WhatId = :recordId
                            OR WhoId IN :idSet
            ];

            for (Event eventRecord: eventsList){
                HistoryDataWrapper historyDataWrapperObject = new HistoryDataWrapper();

                historyDataWrapperObject.record = eventRecord;
                historyDataWrapperObject.sobjectName = 'EventHistory';

                if (eventRecord.WhoId != null) {
                    Id idOfRelatedParentRecord = eventRecord.WhoId;

                    mapContactIdVsContactWithHistoryDataWrapper.get(idOfRelatedParentRecord).listOfDataToShowInHistory.add(historyDataWrapperObject);
                }

                if (eventRecord.WhatId != null) {
                    consolidatedData.currentRecordHistoryData.add(historyDataWrapperObject);
                }
            }

            consolidatedData.contactsWithHistoryData = mapContactIdVsContactWithHistoryDataWrapper.values();


            return consolidatedData;
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Get Consolidated Data', e.getMessage(), 'Error', 'DFJ_ShowHistory_Apex.getConsolidatedData', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }

    private static void populateHistoryData(Map<Id, Contact> mapIdVsContact,
            Map<Id, ContactWithHistoryDataWrapper> mapContactIdVsContactWithHistoryDataWrapper,
            Id idOfRelatedParentRecord, String sobjectNameOfHistoryData, SObject currentHistoryData,
            String stringValueOfRecordId, ConsolidatedDataWrapper consolidatedData) {
        try {

            if (mapIdVsContact.keySet().contains(idOfRelatedParentRecord) && mapContactIdVsContactWithHistoryDataWrapper.containsKey(idOfRelatedParentRecord)) {

                    HistoryDataWrapper historyData = new HistoryDataWrapper();
                    historyData.sobjectName = sobjectNameOfHistoryData;
                    historyData.record = currentHistoryData;

                    mapContactIdVsContactWithHistoryDataWrapper.get(idOfRelatedParentRecord).listOfDataToShowInHistory.add(historyData);
            } else if (stringValueOfRecordId.equals(idOfRelatedParentRecord)) {
                HistoryDataWrapper historyData = new HistoryDataWrapper();
                historyData.sobjectName = sobjectNameOfHistoryData;
                historyData.record = currentHistoryData;

                consolidatedData.currentRecordHistoryData.add(historyData);
            }

        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Populate History Data', e.getMessage(), 'Error', 'DFJ_ShowHistory_Apex.populateHistoryData', '', String.valueOf(e.getLineNumber()));
        }
    }
}