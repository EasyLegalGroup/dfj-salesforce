@isTest 
public class DFJ_DeleteLogs_Batch_Test {
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
        
        Datetime prevMonth = Datetime.now().addDays(-10);
        Test.setCreatedDate(logObj.Id, prevMonth); 
        Test.startTest();

            DFJ_DeleteLogs del = new DFJ_DeleteLogs();
            DataBase.executeBatch(del); 
            
        Test.stopTest();
        String source = 'Lightning : AL_ActivityUtility';
        String event = 'Exception in handleReceiveMessage_Helper.';
		String query = 'Select ID from telegenta__Log__c Where telegenta__Source__c =: source AND telegenta__Event__c =: event AND CreatedDate < THIS_MONTH LIMIT 5000000';
        List<telegenta__Log__c> telegentalogRec = (List<telegenta__Log__c>) Database.query(query);
        System.assertEquals(telegentalogRec.isEmpty(),true);
    }
}