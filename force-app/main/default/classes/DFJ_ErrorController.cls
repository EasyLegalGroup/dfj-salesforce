public with sharing class DFJ_ErrorController {
    public static void addErrorLogs(String recordId, String event, String message, String severnity,String source,String lineNumber){
        // Changes for the logging mechanism
        // Start
        // List<telegenta__Phone_Group_User__c> phoneGroupUserList = new List<telegenta__Phone_Group_User__c>();
        // Id userId = UserInfo.getUserId();
        // phoneGroupUserList = [SELECT Id,Name,telegenta__Log_Activity__c,telegenta__Debug_Log__c,telegenta__User__c FROM telegenta__Phone_Group_User__c WHERE telegenta__User__c =: userId LIMIT 1];
        
        // End
        // if (!phoneGroupUserList.isEmpty() && phoneGroupUserList[0].telegenta__Debug_Log__c) {
            Log__c logObj = new Log__c();
            logObj.Affected_Record__c = recordId;
            logObj.Event__c = event;
            logObj.Message__c = message;
            logObj.Severity__c = severnity;
            logObj.Source__c = source;
            logObj.Line_Number__c = lineNumber;
            insert logObj;
        // }
        
    }
}