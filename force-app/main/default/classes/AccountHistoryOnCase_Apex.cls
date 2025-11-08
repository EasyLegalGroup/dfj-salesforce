public class AccountHistoryOnCase_Apex {
    
    @AuraEnabled
    public static List<consolidatedViewWrapper> fetchConsolidatedViewData(String recId) {
        try{
            if (recId != null && recId.trim() != '') {
                List<consolidatedViewWrapper> consolidatedViewWrappersList = new List<consolidatedViewWrapper>();
                List<Case> getCaseRecord = [SELECT Id, AccountId FROM Case WHERE Id=:recId];
                if(getCaseRecord.isEmpty() || getCaseRecord[0].AccountId==null){
                    return null;
                }
                Map<Id, telegenta__Telegenta_Call_History__c> callHistoriesByIdsMap = new Map<Id, telegenta__Telegenta_Call_History__c>();
                Map<Id, List<telegenta__Telegenta_Call_Recording__c>> callHistoryIdVSCallRecordingList = new Map<Id, List<telegenta__Telegenta_Call_Recording__c>>();
                Set<Id> EmailActivityIdSet = new Set<Id>();
                List<telegenta__Telegenta_Call_History__c> callHistories = new List<telegenta__Telegenta_Call_History__c>();
                String recordId = getCaseRecord[0].AccountId;
                String sobjectToQuery = 'SELECT Id,telegenta__Account__c,telegenta__Account__r.Name,telegenta__Contact__c,telegenta__Contact__r.Name,telegenta__Lead__c,telegenta__Lead__r.Name,telegenta__Call_Start_Time__c,telegenta__Active_Duration__c,telegenta__Total_Duration__c,telegenta__Call_End_Time__c,telegenta__Caller_Number__c,telegenta__Destination_Country__c,telegenta__Destination_number__c,telegenta__Direction__c,telegenta__Disposition__c,CreatedDate,CreatedBy.Name,telegenta__Incoming_Number__c FROM telegenta__Telegenta_Call_History__c WHERE telegenta__Account__c  = :recordId ORDER BY CreatedDate DESC LIMIT 10000';
                callHistories = Database.query(sobjectToQuery);
                Set<Id> callHistoryIdSet = new Set<Id>();
                for (telegenta__Telegenta_Call_History__c callHistoryIdLoop : callHistories) {
                    // To put all the Id in the set
                    callHistoryIdSet.add(callHistoryIdLoop.Id);
                    // Fill all the values of call history
                    callHistoryIdVSCallRecordingList.put(callHistoryIdLoop.Id, new List<telegenta__Telegenta_Call_Recording__c>());
                }
                List<telegenta__Telegenta_Call_Recording__c> telegentaCallRecordings = new List<telegenta__Telegenta_Call_Recording__c>();
                telegentaCallRecordings = [SELECT Id,Name,telegenta__Telegenta_Call_History__c,telegenta__Length__c,telegenta__Media_URL__c,telegenta__Record_Player__c,telegenta__Recording_Delete_Date__c,telegenta__Size__c,telegenta__Start_Time__c FROM telegenta__Telegenta_Call_Recording__c WHERE telegenta__Telegenta_Call_History__c IN:callHistoryIdSet ORDER BY CreatedDate DESC];
                for (telegenta__Telegenta_Call_Recording__c callRecording : telegentaCallRecordings) {
                    if (callRecording.telegenta__Telegenta_Call_History__c != null) {
                        if (callHistoryIdVSCallRecordingList.containsKey(callRecording.telegenta__Telegenta_Call_History__c)) {
                            callHistoryIdVSCallRecordingList.get(callRecording.telegenta__Telegenta_Call_History__c).add(callRecording);
                            callHistoryIdVSCallRecordingList.put(callRecording.telegenta__Telegenta_Call_History__c, callHistoryIdVSCallRecordingList.get(callRecording.telegenta__Telegenta_Call_History__c));
                        }
                    }
                }
                List<callHistoryReturnWrapper> callHistoryReturnWrappersList = new List<callHistoryReturnWrapper>();
                for (telegenta__Telegenta_Call_History__c callHistoryIdLoop : callHistories) {
                    callHistoryReturnWrapper callHistoryInstance = new callHistoryReturnWrapper();
                    callHistoryInstance.callHistory = callHistoryIdLoop;
                    callHistoryInstance.callRecordingsList = callHistoryIdVSCallRecordingList.get(callHistoryIdLoop.Id);
                    
                    consolidatedViewWrapper viewInstance = new consolidatedViewWrapper();
                    viewInstance.sobjectName = 'CallHistory';
                    viewInstance.objectData = callHistoryIdLoop;
                    viewInstance.createdDatetime = callHistoryIdLoop.CreatedDate;
                    viewInstance.callObjectData = callHistoryInstance;
                    consolidatedViewWrappersList.add(viewInstance);
                }
                List<consolidatedViewWrapper> callCampaignStateHistories = new List<consolidatedViewWrapper>();
                callCampaignStateHistories = getLastOutcomeHistoryView_Apex(getCaseRecord[0].AccountId, 'Account');
                if(callCampaignStateHistories!=null && !callCampaignStateHistories.isEmpty()){
                    consolidatedViewWrappersList.addAll(callCampaignStateHistories);
                }
                List<Note> notesList = new List<Note>();
                notesList = [SELECT Id,ParentId,Body,Title,CreatedDate,CreatedBy.Name FROM Note WHERE ParentId = :recordId ORDER BY CreatedDate DESC];
                for (Note noteLoop : notesList) {
                    consolidatedViewWrapper viewInstance = new consolidatedViewWrapper();
                    viewInstance.sobjectName = 'NoteHistory';
                    viewInstance.objectData = noteLoop;
                    viewInstance.createdDatetime = noteLoop.CreatedDate;
                    consolidatedViewWrappersList.add(viewInstance);
                }
                System.debug(JSON.serialize(consolidatedViewWrappersList));
                return consolidatedViewWrappersList;
            }
        } catch(Exception ex){
            DFJ_ErrorLogController.addErrorLogs('', 'Getting Wrapper Instance.', ex.getMessage(), 'Error', 'AccountHistoryOnCase_Apex.fetchConsolidatedViewData', '', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }
    public static List<consolidatedViewWrapper> getLastOutcomeHistoryView_Apex(String recordId, String sObjectName){
        try{
            List<telegenta__Call_Campaign_State__c> callCampaignStateList = new List<telegenta__Call_Campaign_State__c>();
            List<telegenta__Campaign__c> relatedCampaignList = new List<telegenta__Campaign__c>();
            List<consolidatedViewWrapper> consolidatedViewWrappersList = new List<consolidatedViewWrapper>();
            Map<String,telegenta__Call_Campaign_State__c> callCampaignStateIdVsCallCampaignState = new Map<String,telegenta__Call_Campaign_State__c>();
            String getCallCampaignState = 'SELECT telegenta__Call_Campaign__c,'+
                'telegenta__Last_Call_Time__c,'+
                'telegenta__Call_Campaign__r.telegenta__Lead_group__c,'+
                'telegenta__Call_Campaign__r.Name,'+
                'telegenta__Last_Outcome__c,'+
                'telegenta__Has_appointment__c,'+
                'telegenta__Caller_Id__c,'+
                'telegenta__Phone_Number__c,'+
                'telegenta__Next_Call_Time__c,'+
                'telegenta__Unsuccessful_calls__c,'+
                'telegenta__Lock_Period__c,'+
                'telegenta__Total_Unsucccessful_Call__c,'+
                'telegenta__'+sObjectName+'__c,'+
                'telegenta__Total_calls__c,'+
                'telegenta__Stop_Calling__c '+
                'FROM telegenta__Call_Campaign_State__c WHERE telegenta__'+sObjectName+'__c = \''+recordId+'\'  ORDER BY CreatedDate DESC LIMIT 10000';
            
            callCampaignStateList = (List<telegenta__Call_Campaign_State__c>)Database.query(getCallCampaignState);
            
            if(!callCampaignStateList.isEmpty()){
                for(telegenta__Call_Campaign_State__c callCampaignStateLoop : callCampaignStateList){
                    callCampaignStateIdVsCallCampaignState.put(callCampaignStateLoop.Id,callCampaignStateLoop);
                }
                List<telegenta__Call_Campaign_State__History> callCampaignStateHistories = new List<telegenta__Call_Campaign_State__History>();
                callCampaignStateHistories = [SELECT Id, IsDeleted, ParentId, CreatedById, CreatedDate,CreatedBy.Name, Field, DataType, OldValue, NewValue FROM telegenta__Call_Campaign_State__History WHERE Field = 'telegenta__Last_Outcome__c' AND ParentId IN :callCampaignStateIdVsCallCampaignState.keySet() AND DataType = 'Text' LIMIT 50000];
                
                for(telegenta__Call_Campaign_State__History callCampaignStateHistoryLoop : callCampaignStateHistories){
                    consolidatedViewWrapper viewInstance = new consolidatedViewWrapper();
                    viewInstance.sobjectName = 'telegenta__Call_Campaign_State__c';
                    viewInstance.objectData = callCampaignStateHistoryLoop;
                    viewInstance.callCampaignName = callCampaignStateIdVsCallCampaignState.get(callCampaignStateHistoryLoop.ParentId).telegenta__Call_Campaign__r.Name;
                    viewInstance.createdDatetime = callCampaignStateHistoryLoop.CreatedDate;
                    consolidatedViewWrappersList.add(viewInstance);
                }
                return consolidatedViewWrappersList;
            }
        } catch(Exception ex){
            System.debug('Error----'+ex.getMessage()+' at line number---'+ex.getLineNumber());
            DFJ_ErrorLogController.addErrorLogs('', 'Creating Notes record.', ex.getMessage(), 'Error', 'AccountHistoryOnCase_Apex.getLastOutcomeHistoryView_Apex', '', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }
    
    //DFJ-207
    @AuraEnabled
    public static List<consolidatedViewWrapper> fetchConsolidatedViewDataForLead(String recId) {
        try{
            if (recId != null && recId.trim() != '') {
                List<consolidatedViewWrapper> consolidatedViewWrappersList = new List<consolidatedViewWrapper>();
                List<Case> getCaseRecord = [SELECT Id, Lead__c FROM Case WHERE Id=:recId];
                if(getCaseRecord.isEmpty() || getCaseRecord[0].Lead__c==null){
                    return null;
                }
                Map<Id, telegenta__Telegenta_Call_History__c> callHistoriesByIdsMap = new Map<Id, telegenta__Telegenta_Call_History__c>();
                Map<Id, List<telegenta__Telegenta_Call_Recording__c>> callHistoryIdVSCallRecordingList = new Map<Id, List<telegenta__Telegenta_Call_Recording__c>>();
                Set<Id> EmailActivityIdSet = new Set<Id>();
                List<telegenta__Telegenta_Call_History__c> callHistories = new List<telegenta__Telegenta_Call_History__c>();
                // String fieldToQuery = sObjectName == 'Lead' ? 'telegenta__Lead__c' : sObjectName == 'Account' ? 'telegenta__Account__c' : sObjectName == 'Contact' ? 'telegenta__Contact__c' : 'telegenta__Lead__c';
                String recordId = getCaseRecord[0].Lead__c;
                String sobjectToQuery = 'SELECT Id,telegenta__Account__c,telegenta__Account__r.Name,telegenta__Contact__c,telegenta__Contact__r.Name,telegenta__Lead__c,telegenta__Lead__r.Name,telegenta__Call_Start_Time__c,telegenta__Active_Duration__c,telegenta__Total_Duration__c,telegenta__Call_End_Time__c,telegenta__Caller_Number__c,telegenta__Destination_Country__c,telegenta__Destination_number__c,telegenta__Direction__c,telegenta__Disposition__c,CreatedDate,CreatedBy.Name,telegenta__Incoming_Number__c FROM telegenta__Telegenta_Call_History__c WHERE telegenta__Lead__c  = :recordId ORDER BY CreatedDate DESC LIMIT 10000';
                callHistories = Database.query(sobjectToQuery);
                Set<Id> callHistoryIdSet = new Set<Id>();
                for (telegenta__Telegenta_Call_History__c callHistoryIdLoop : callHistories) {
                    // To put all the Id in the set
                    callHistoryIdSet.add(callHistoryIdLoop.Id);
                    // Fill all the values of call history
                    callHistoryIdVSCallRecordingList.put(callHistoryIdLoop.Id, new List<telegenta__Telegenta_Call_Recording__c>());
                }
                List<telegenta__Telegenta_Call_Recording__c> telegentaCallRecordings = new List<telegenta__Telegenta_Call_Recording__c>();
                telegentaCallRecordings = [SELECT Id,Name,telegenta__Telegenta_Call_History__c,telegenta__Length__c,telegenta__Media_URL__c,telegenta__Record_Player__c,telegenta__Recording_Delete_Date__c,telegenta__Size__c,telegenta__Start_Time__c FROM telegenta__Telegenta_Call_Recording__c WHERE telegenta__Telegenta_Call_History__c IN:callHistoryIdSet ORDER BY CreatedDate DESC];
                for (telegenta__Telegenta_Call_Recording__c callRecording : telegentaCallRecordings) {
                    if (callRecording.telegenta__Telegenta_Call_History__c != null) {
                        if (callHistoryIdVSCallRecordingList.containsKey(callRecording.telegenta__Telegenta_Call_History__c)) {
                            callHistoryIdVSCallRecordingList.get(callRecording.telegenta__Telegenta_Call_History__c).add(callRecording);
                            callHistoryIdVSCallRecordingList.put(callRecording.telegenta__Telegenta_Call_History__c, callHistoryIdVSCallRecordingList.get(callRecording.telegenta__Telegenta_Call_History__c));
                        }
                    }
                }
                List<callHistoryReturnWrapper> callHistoryReturnWrappersList = new List<callHistoryReturnWrapper>();
                for (telegenta__Telegenta_Call_History__c callHistoryIdLoop : callHistories) {
                    callHistoryReturnWrapper callHistoryInstance = new callHistoryReturnWrapper();
                    callHistoryInstance.callHistory = callHistoryIdLoop;
                    callHistoryInstance.callRecordingsList = callHistoryIdVSCallRecordingList.get(callHistoryIdLoop.Id);
                    
                    consolidatedViewWrapper viewInstance = new consolidatedViewWrapper();
                    viewInstance.sobjectName = 'CallHistory';
                    viewInstance.objectData = callHistoryIdLoop;
                    viewInstance.createdDatetime = callHistoryIdLoop.CreatedDate;
                    viewInstance.callObjectData = callHistoryInstance;
                    consolidatedViewWrappersList.add(viewInstance);
                }
                List<consolidatedViewWrapper> callCampaignStateHistories = new List<consolidatedViewWrapper>();
                callCampaignStateHistories = getLastOutcomeHistoryView_Apex(getCaseRecord[0].Lead__c, 'Lead');
                if(callCampaignStateHistories!=null && !callCampaignStateHistories.isEmpty()){
                    consolidatedViewWrappersList.addAll(callCampaignStateHistories);
                }
                List<Note> notesList = new List<Note>();
                notesList = [SELECT Id,ParentId,Body,Title,CreatedDate,CreatedBy.Name FROM Note WHERE ParentId = :recordId ORDER BY CreatedDate DESC LIMIT 50000];
                for (Note noteLoop : notesList) {
                    consolidatedViewWrapper viewInstance = new consolidatedViewWrapper();
                    viewInstance.sobjectName = 'NoteHistory';
                    viewInstance.objectData = noteLoop;
                    viewInstance.createdDatetime = noteLoop.CreatedDate;
                    consolidatedViewWrappersList.add(viewInstance);
                }
                // Fetch all the events
                List<Event> eventsList = new List<Event>();
                String eventQuery = 'SELECT Id,OwnerId,Description,Subject,StartDateTime,EndDateTime,WhoId,CreatedDate,CreatedBy.Name FROM Event WHERE WhoId = :recordId';
                
                eventsList = Database.query(eventQuery);
                for (Event eventLoop : eventsList) {
                    consolidatedViewWrapper viewInstance = new consolidatedViewWrapper();
                    viewInstance.sobjectName = 'EventHistory';
                    viewInstance.objectData = eventLoop;
                    viewInstance.createdDatetime = eventLoop.CreatedDate;
                    consolidatedViewWrappersList.add(viewInstance);
                }
                List<LeadHistory> leadHistories = new List<LeadHistory>();
                leadHistories = [SELECT Id,Field,LeadId,OldValue,NewValue,CreatedById,CreatedDate,CreatedBy.Name FROM LeadHistory WHERE Field = 'telegenta__Last_Contact_State__c' AND LeadId = :recordId LIMIT 50000];
                for (LeadHistory leadHistoryLoop : leadHistories) {
                    consolidatedViewWrapper viewInstance = new consolidatedViewWrapper();
                    viewInstance.sobjectName = 'FieldsHistory';
                    viewInstance.objectData = leadHistoryLoop;
                    viewInstance.createdDatetime = leadHistoryLoop.CreatedDate;
                    consolidatedViewWrappersList.add(viewInstance);
                }
                System.debug('consolidatedViewWrappersList-->'+JSON.serialize(consolidatedViewWrappersList));
                return consolidatedViewWrappersList;
            }
        } catch(Exception ex){
            System.debug('Error----'+ex.getMessage()+' at line number---'+ex.getLineNumber());
            DFJ_ErrorLogController.addErrorLogs('', 'Getting Wrapper Instance.', ex.getMessage(), 'Error', 'LeadHistoryOnCase_Apex.fetchConsolidatedViewDataForLead', '', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }
    public class consolidatedViewWrapper {
        @AuraEnabled public String sobjectName { get; set; }
        @AuraEnabled public String callCampaignName { get; set; }
        @AuraEnabled public Datetime createdDatetime { get; set; }
        @AuraEnabled public Sobject objectData { get; set; }
        @AuraEnabled public callHistoryReturnWrapper callObjectData { get; set; }
    }
    public class callHistoryReturnWrapper {
        @AuraEnabled public telegenta__Telegenta_Call_History__c callHistory { get; set; }
        @AuraEnabled public List<telegenta__Telegenta_Call_Recording__c> callRecordingsList { get; set; }
    }
    
    
}