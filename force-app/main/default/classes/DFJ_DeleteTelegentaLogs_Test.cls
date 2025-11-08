@isTest 
public class DFJ_DeleteTelegentaLogs_Test {
    @isTest
    public static void deleteLogs_Test() 
    {
        telegenta__Log__c logObj = new telegenta__Log__c();
        logObj.telegenta__Affected_record__c = 'TestRecordId';
        logObj.telegenta__Event__c = 'Exception in handleReceiveMessage_Helper.';
        logObj.telegenta__Message__c = 'TestMessage';
        logObj.telegenta__Severity__c = 'Error';
        logObj.telegenta__Source__c = 'Lightning : AL_ActivityUtility';
        logObj.telegenta__Stack_trace__c = 'TeststackTrace';
        logObj.telegenta__Line_Number__c = 'TestlineNumber';
        insert logObj;
        
        String query = 'Select ID from telegenta__Log__c Where telegenta__Source__c =  ' +'\''+'Lightning : AL_ActivityUtility'+'\''+' AND telegenta__Event__c = ' +'\''+'Exception in handleReceiveMessage_Helper.'+'\''+' LIMIT 5000000';
        Test.startTest();
        DFJ_DeleteTelegentaLogs del = new DFJ_DeleteTelegentaLogs(query);
        DataBase.executeBatch(del);             
        // DFJ_DeleteTelegentaLogs del2 = new DFJ_DeleteTelegentaLogs('Select Id from Membership where Id=\''+'abcd'+'\'');
        // DataBase.executeBatch(del2);
        Test.stopTest();
        String source = 'Lightning : AL_ActivityUtility';
        String event = 'Exception in handleReceiveMessage_Helper.';
		String assertQuery = 'Select ID from telegenta__Log__c Where telegenta__Source__c =  ' +'\''+'Lightning : AL_ActivityUtility'+'\''+' AND telegenta__Event__c = ' +'\''+'Exception in handleReceiveMessage_Helper.'+'\''+' LIMIT 1';
        List<telegenta__Log__c> telegentaLogRec = Database.query(assertQuery);
        System.assertEquals(telegentaLogRec.isEmpty(),true);
    }
}