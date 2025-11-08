global class DFJ_DeleteLogs implements Database.Batchable<sObject>{
    
     @InvocableMethod
    public static void executeDFJ_DeleteLogs() {
        Id jobId = Database.executeBatch(new DFJ_DeleteLogs(),2000);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        String source = 'Lightning : AL_ActivityUtility';
        String event = 'Exception in handleReceiveMessage_Helper.';
        String query = 'SELECT ID from telegenta__Log__c Where telegenta__Source__c =: source AND telegenta__Event__c =: event LIMIT 5000000';
        return Database.getQueryLocator(query); 
    }
     
    global void execute(Database.BatchableContext BC, List<telegenta__Log__c> TeleLogList) {
        
        try {
            System.debug('Tele Log List >>>'+TeleLogList);
            delete TeleLogList;
        } catch(Exception e) {
            System.debug('Error :'+e.getMessage()+' Line Number :'+e.getLineNumber());
        }
        
    }   
     
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }

}