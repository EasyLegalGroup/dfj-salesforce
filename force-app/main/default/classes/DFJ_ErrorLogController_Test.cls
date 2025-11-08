@isTest
public class DFJ_ErrorLogController_Test {
    @isTest
    public static void addErrorLogs_Test(){
        // List<telegenta__Phone_Group_User__c> phoneUsers = DFJ_TestDataFactory.createPhoneGroupUsers(1,true);
        Test.startTest();
        Boolean result = DFJ_ErrorLogController.addErrorLogs('Test RecordId', 'Test Event', 'Test Message', 'Test Error', 'Test Souece', 'Test Stacttrace','Test Line number');
        Boolean result1 =DFJ_ErrorLogController.addErrorLogs('Test RecordId', 'Test Event', 'Truncated text. When the driver determines that an Excel column contains text data, the driver selects the data type (string or memo) based on the longest value that it samples. If the driver does not discover any values longer than 255 characters in the rows that it samples, it treats the column as a 255-character string column instead of a memo column. Therefore, values longer than 255 characters may be truncated. To import data from a memo column without truncation, you must make sure that the memo column in at least one of the sampled rows contains a value longer than 255 characters', 'Test Error', 'Test Souece', 'Test Stacttrace','Test Line number');
        Test.stopTest();
        System.assertEquals(true, result);
        System.assertEquals(true, result1);
    }
}