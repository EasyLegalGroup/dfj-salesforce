public class TelegentaOutcomeHelper {
    @InvocableMethod(label='Update Outcome Records')
    public static void updateRecord(List<InvocableAttributes> records){
        String recordId = records[0].recordId;
        telegenta__Call_Campaign_State__c campaignStateRecord = records[0].campaignStateRecord;
        telegenta__Campaign__c campaignRecord = records[0].campaignRecord;
        telegenta__Outcome__c outcomeRecord = records[0].outcomeRecord;
        List<telegenta__Outcome_Field_Value__c> fieldValueRecords = records[0].fieldValueRecord;
        String objectName = records[0].objectName;
        
		List<telegenta__Telegenta_Call_History__c> callHistoryRecords = [SELECT Id FROM telegenta__Telegenta_Call_History__c where (telegenta__Contact__c =: recordId OR telegenta__Lead__c =: recordId OR telegenta__Account__c =: recordId OR telegenta__Opportunity__c =: recordId) AND telegenta__Direction__c = 'OUTBOUND'];
        Map<String, String> outcomeFieldValueMap = new Map<String, String>();
        if(!fieldValueRecords.isEmpty()){
            for(telegenta__Outcome_Field_Value__c fieldValue : fieldValueRecords){
                if(fieldValue.telegenta__Question__c == null){
                	outcomeFieldValueMap.put(fieldValue.telegenta__Field_Name__c, fieldValue.telegenta__Field_Value__c);   
                }
            }
        }
        updateRecord(recordId, objectName, campaignStateRecord, campaignRecord, outcomeFieldValueMap, callHistoryRecords.size());
    }

    public static void updateRecord(Id recordId, String objectName, telegenta__Call_Campaign_State__c campaignStateRecord, telegenta__Campaign__c campaignRecord, Map<String, String> outcomeFieldValueMap, Integer callHistorySize){
        String recordTypeName = '';
        if(objectName == 'Account'){
            Account accRecord = [SELECT Id, Name, RecordType.Name, RecordType.DeveloperName from Account where Id =: recordId LIMIT 1];
            recordTypeName = accRecord.RecordType.DeveloperName;
        }
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        SObject record = sObjectType.newSObject();
        record.Id = recordId;
        if(objectName != 'Lead'){
            record.put('Total_Calls__c', callHistorySize);
            if(objectName != 'Account' || (objectName == 'Account' && recordTypeName != 'PersonAccount')){
                record.put('Unsuccessful_Calls__c', campaignStateRecord.telegenta__Unsuccessful_calls__c);
                record.put('Has_Appointment__c', campaignStateRecord.telegenta__Has_appointment__c);
                record.put('Last_Campaign__c', campaignRecord.Name);
                record.put('Stop_Calling__c', campaignStateRecord.telegenta__Stop_Calling__c);
                record.put('Call_Campaign__c', campaignRecord.Id);
                record.put('Call_Campaign_State__c', campaignStateRecord.Id);
                record.put('Last_Call_Time__c', campaignStateRecord.telegenta__Last_Call_Time__c);
                record.put('Next_Call_Time__c', campaignStateRecord.telegenta__Next_Call_Time__c);
            } else if(objectName == 'Account' && recordTypeName == 'PersonAccount'){
                record.put('Total_Calls__pc', callHistorySize);
                record.put('Unsuccessful_Calls__pc', campaignStateRecord.telegenta__Unsuccessful_calls__c);
                record.put('Has_Appointment__pc', campaignStateRecord.telegenta__Has_appointment__c);
                record.put('Last_Campaign__pc', campaignRecord.Name);
                record.put('Stop_Calling__pc', campaignStateRecord.telegenta__Stop_Calling__c);
                record.put('Call_Campaign__pc', campaignRecord.Id);
                record.put('Call_Campaign_State__pc', campaignStateRecord.Id);
                record.put('Last_Call_Time__pc', campaignStateRecord.telegenta__Last_Call_Time__c);
                record.put('Next_Call_Time__pc', campaignStateRecord.telegenta__Next_Call_Time__c);
            }
        } else {
            record.put('telegenta__Total_calls__c', callHistorySize);
            record.put('telegenta__Unsuccessful_Calls__c', campaignStateRecord.telegenta__Unsuccessful_calls__c);
            record.put('Has_Appointment__c', campaignStateRecord.telegenta__Has_appointment__c);
            record.put('Last_Campaign__c', campaignRecord.Name);
            record.put('Stop_Calling__c', campaignStateRecord.telegenta__Stop_Calling__c);
            record.put('Call_Campaign__c', campaignRecord.Id);
            record.put('Call_Campaign_State__c', campaignStateRecord.Id);
            record.put('Last_Call_Time__c', campaignStateRecord.telegenta__Last_Call_Time__c);
            record.put('telegenta__Next_Call_Time__c', campaignStateRecord.telegenta__Next_Call_Time__c);
        }

        Map<String, Schema.SObjectField> fieldsMap = sObjectType.getDescribe().fields.getMap();
        if(!outcomeFieldValueMap.keySet().isEmpty()){
            for(String key : outcomeFieldValueMap.keySet()){
                if(fieldsMap.containsKey(key)){
                    if(objectName != 'Account' || (objectName == 'Account' && ((key.endsWith('__pc') && recordTypeName == 'PersonAccount') || (key.endsWith('__c') && recordTypeName != 'PersonAccount')))){
                        record.put(key, outcomeFieldValueMap.get(key));
                    }
                }
            }
        }
        update record;
    }
    
    public class InvocableAttributes{
        @InvocableVariable(required=true)
        public ID recordId;
        
        @InvocableVariable
        public String objectName;
        
        @InvocableVariable
        public Contact contactRecord;
        
        @InvocableVariable
        public Opportunity opportunityRecord;
        
        @InvocableVariable
        public Account accountRecord;
        
        @InvocableVariable
        public Lead leadRecord;
        
        @InvocableVariable
        public telegenta__Call_Campaign_State__c campaignStateRecord;
        
        @InvocableVariable
        public telegenta__Campaign__c campaignRecord;
        
        @InvocableVariable
        public telegenta__Outcome__c outcomeRecord;
        
        @InvocableVariable
        public List<telegenta__Outcome_Field_Value__c> fieldValueRecord;
    }
}