public class DFJ_TelegentaCallHistoryBatchClass implements Database.Batchable<SObject>, Database.Stateful, DFJ_callhistoryArchiver {
    
    private Set<Id> successfulInsertIds = new Set<Id>();    private String dateFilter;
    private DFJ_callhistoryArchiver archiver;   
    private Set<Id> failedIds = new Set<Id>();
   
    public DFJ_TelegentaCallHistoryBatchClass(String filter) {
        this.archiver = this;  
        this.dateFilter = filter;
    } 
    
    public DFJ_TelegentaCallHistoryBatchClass(DFJ_callhistoryArchiver archiver, String filter) {
        this.archiver = archiver;
        this.dateFilter = filter;
    } 
 
    public Database.SaveResult[] insertRecords(List<Telegenta_Call_History__b> records) {
        if (!records.isEmpty() && !Test.isRunningTest()) {
            return Database.insertImmediate(records);
        }
        return new List<Database.SaveResult>();
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, CreatedById, CreatedDate, CurrencyIsoCode, Follow_up_Complete__c, IsDeleted, Market_Unit__c, OwnerId, ' +
            'telegenta__Account__c, telegenta__Active_Duration__c, telegenta__Call_Campaign_State__c, telegenta__Call_End_Time__c, ' +
            'telegenta__Call_Start_Time__c, telegenta__Caller_Number__c, telegenta__Contact__c, telegenta__Destination_Country__c, ' +
            'telegenta__Destination_number__c, telegenta__Dialer_Session__c, telegenta__Direction__c, telegenta__Disposition__c, ' +
            'telegenta__Duration_In_Milliseconds__c, telegenta__Incoming_Number__c, telegenta__Info_State__c, telegenta__Lead__c, ' +
            'telegenta__Opportunity__c, telegenta__Privacy__c, telegenta__Puuid__c, telegenta__Recording_Delete_Date__c, ' +
            'telegenta__Total_Cost__c, telegenta__Total_Duration__c, ActiveDurationMore300__c, Phone_Formatted__c ' +
            'FROM telegenta__Telegenta_Call_History__c WHERE ' + dateFilter
        );
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (scope != null && !scope.isEmpty()) {    
            List<Telegenta_Call_History__b> callHistoryRecordsToInsert = new List<Telegenta_Call_History__b>();
            for (SObject sObj : scope) {
                telegenta__Telegenta_Call_History__c callHistory = (telegenta__Telegenta_Call_History__c) sObj; 
                Telegenta_Call_History__b callHistoryRecord = new Telegenta_Call_History__b();
                callHistoryRecord.telegenta_Puuid__c = callHistory.telegenta__Puuid__c != null ? callHistory.telegenta__Puuid__c : '';
                callHistoryRecord.Name__c = callHistory.Name;       
                callHistoryRecord.ActiveDurationMore300__c = callHistory.ActiveDurationMore300__c == true ? 'True' : 'False';  
                callHistoryRecord.CreatedById__c = callHistory.CreatedById;
                callHistoryRecord.Phone_Formatted__c = callHistory.Phone_Formatted__c != null ? callHistory.Phone_Formatted__c : '';
                callHistoryRecord.CreatedDate__c = callHistory.CreatedDate;
                callHistoryRecord.CurrencyIsoCode__c = callHistory.CurrencyIsoCode != null ? callHistory.CurrencyIsoCode : '';
                callHistoryRecord.Follow_up_Complete__c = callHistory.Follow_up_Complete__c == true ? 'True' : 'False';
                callHistoryRecord.ID__c = callHistory.Id;
                callHistoryRecord.OwnerId__c = callHistory.OwnerId;
                callHistoryRecord.IsDeleted__c = callHistory.IsDeleted == true ? 'True' : 'False';
                callHistoryRecord.Market_Unit__c = callHistory.Market_Unit__c != null ? callHistory.Market_Unit__c : '';
                callHistoryRecord.telegenta_Account__c = callHistory.telegenta__Account__c != null ? callHistory.telegenta__Account__c : null;
                callHistoryRecord.telegenta_Active_Duration__c = callHistory.telegenta__Active_Duration__c != null ? callHistory.telegenta__Active_Duration__c : 0;
                callHistoryRecord.telegenta_Call_Campaign_State__c = 
                    (callHistory.telegenta__Call_Campaign_State__c != null) ? (Id)callHistory.telegenta__Call_Campaign_State__c : null;
                callHistoryRecord.telegenta_Call_End_Time__c = callHistory.telegenta__Call_End_Time__c != null ? callHistory.telegenta__Call_End_Time__c : null;
                callHistoryRecord.telegenta_Call_Start_Time__c = callHistory.telegenta__Call_Start_Time__c != null ? callHistory.telegenta__Call_Start_Time__c : null;
                callHistoryRecord.telegenta_Caller_Number__c = callHistory.telegenta__Caller_Number__c != null ? callHistory.telegenta__Caller_Number__c : '';
                callHistoryRecord.telegenta_Contact__c = callHistory.telegenta__Contact__c != null ? callHistory.telegenta__Contact__c : null;
                callHistoryRecord.telegenta_Destination_Country__c = callHistory.telegenta__Destination_Country__c != null ? callHistory.telegenta__Destination_Country__c : '';
                callHistoryRecord.telegenta_Destination_number__c = callHistory.telegenta__Destination_number__c != null ? callHistory.telegenta__Destination_number__c : '';
                callHistoryRecord.telegenta_Dialer_Session__c = 
                    (callHistory.telegenta__Dialer_Session__c != null) ? (Id)callHistory.telegenta__Dialer_Session__c : null;
                callHistoryRecord.telegenta_Direction__c = callHistory.telegenta__Direction__c != null ? callHistory.telegenta__Direction__c : '';
                callHistoryRecord.telegenta_Disposition__c = callHistory.telegenta__Disposition__c != null ? callHistory.telegenta__Disposition__c : '';
                callHistoryRecord.telegenta_Duration_In_Milliseconds__c = callHistory.telegenta__Duration_In_Milliseconds__c != null ? callHistory.telegenta__Duration_In_Milliseconds__c : 0;
                callHistoryRecord.telegenta_Incoming_Number__c = callHistory.telegenta__Incoming_Number__c != null ? callHistory.telegenta__Incoming_Number__c : '';
                callHistoryRecord.telegenta_Info_State__c = callHistory.telegenta__Info_State__c != null ? callHistory.telegenta__Info_State__c : '';
                callHistoryRecord.telegenta_Lead__c = callHistory.telegenta__Lead__c != null ? callHistory.telegenta__Lead__c : null;
                callHistoryRecord.telegenta_Opportunity__c = callHistory.telegenta__Opportunity__c != null ? callHistory.telegenta__Opportunity__c : null;
                callHistoryRecord.telegenta_Privacy__c = callHistory.telegenta__Privacy__c == true ? 'True' : 'False';
                callHistoryRecord.telegenta_Recording_Delete_Date__c = callHistory.telegenta__Recording_Delete_Date__c != null ? callHistory.telegenta__Recording_Delete_Date__c : null;
                callHistoryRecord.telegenta_Total_Duration__c = callHistory.telegenta__Total_Duration__c != null ? callHistory.telegenta__Total_Duration__c : '0';
                callHistoryRecord.telegenta_Total_Cost__c = callHistory.telegenta__Total_Cost__c != null ? String.valueOf(callHistory.telegenta__Total_Cost__c) : '0';
                callHistoryRecordsToInsert.add(callHistoryRecord);
            }
            
            if (!callHistoryRecordsToInsert.isEmpty()) {
                try {
                    Database.SaveResult[] results = archiver.insertRecords(callHistoryRecordsToInsert); 
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult sr = results[i]; 
                        String recordIdentifier = callHistoryRecordsToInsert[i].ID__c; 
                        if (!sr.isSuccess()) {FailedIds.add(recordIdentifier);
                            }   
                         else {
                            successfulInsertIds.add(recordIdentifier);
                        }
                    }   
                } catch (Exception e) {
                    System.debug('error:-->'+ e.getMessage()+ 'on line No-->'+ e.getLineNumber());
                    
                }
            } 
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('failedIds: ' + failedIds);
        if (!successfulInsertIds.isEmpty()) {
            
            Database.executeBatch(new DFJ_DeleteRecords(successfulInsertIds, 'telegenta__Telegenta_Call_History__c'), 2000);
        } 
    }
    
    public class BatchParams {
        @InvocableVariable(required=false) public Date startDate;
        @InvocableVariable(required=true) public Date endDate;
    }
    
    @InvocableMethod(label='Run Telegenta Call History Batch')
    public static void runBatch(List<BatchParams> paramsList) {
        BatchParams params = (paramsList != null && !paramsList.isEmpty()) ? paramsList[0] : new BatchParams();
        String filter; 
        Date endDate = params.endDate;
        Date startDate = params.startDate;
        DateTime endDT = DateTime.newInstance(endDate, Time.newInstance(23, 59, 59, 0));
        if (startDate != null) {
            DateTime startDT = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            filter = 'CreatedDate >= ' + startDT.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' AND CreatedDate <= ' + endDT.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        } else {
            filter = 'CreatedDate <= ' + endDT.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        }        
        Database.executeBatch(new DFJ_TelegentaCallHistoryBatchClass(filter), 2000);
    }
}