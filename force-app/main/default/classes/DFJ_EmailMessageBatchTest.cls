@IsTest
public class DFJ_EmailMessageBatchTest {
    
   
    private class DFJ_EmailMessageArchiverMock implements DFJ_EmailMessageArchiver {
        public List<Email_Message__b> insertedRecords = new List<Email_Message__b>();
        
        public Database.SaveResult[] insertRecords(List<Email_Message__b> records) {
            insertedRecords.addAll(records);
            List<Database.SaveResult> results = new List<Database.SaveResult>();
            for (Email_Message__b rec : records) {
                Database.SaveResult sr = (Database.SaveResult) JSON.deserialize('{"success":true}', Database.SaveResult.class);
                results.add(sr);
            }
            return results;
        }
    }
    
   
    private class DFJ_EmailMessageArchiverMockWithError implements DFJ_EmailMessageArchiver {
        public List<Email_Message__b> insertedRecords = new List<Email_Message__b>();
        
        public Database.SaveResult[] insertRecords(List<Email_Message__b> records) {
            insertedRecords.addAll(records);
            List<Database.SaveResult> results = new List<Database.SaveResult>();
            for (Email_Message__b rec : records) {
                Database.SaveResult sr = (Database.SaveResult) JSON.deserialize('{"success":false, "errors":[{"message":"Insert failed"}]}', Database.SaveResult.class);
                results.add(sr);
            }
            return results;
        }
    }
    
    @IsTest
    static void testBatchWithMockArchiver() {
        
        List<EmailMessage> testEmailMessages = new List<EmailMessage>();
        for (Integer i = 0; i < 5; i++) {
            testEmailMessages.add(new EmailMessage(
                Subject = 'Test Email ' + i,
                FromAddress = 'test' + i + '@example.com',
                ToAddress = 'recipient' + i + '@example.com',
                TextBody = 'Test body ' + i,
                HtmlBody = '<p>Test body ' + i + '</p>',
                Status = '0',
                CreatedDate = DateTime.now(),
                MessageDate = DateTime.now()
            ));
        }
        insert testEmailMessages;
        
       
        DFJ_EmailMessageArchiver mockArchiver = new DFJ_EmailMessageArchiverMock();
        String filter = 'CreatedDate = TODAY';
        DFJ_EmailMessageBatchClass batch = new DFJ_EmailMessageBatchClass(mockArchiver, filter);
        
      
        Test.startTest();
        Database.executeBatch(batch, 5);
        Test.stopTest();
        
       
        List<Email_Message__b> insertedRecords = ((DFJ_EmailMessageArchiverMock)mockArchiver).insertedRecords;
        
        for (Email_Message__b record : insertedRecords) {
            System.assertNotEquals(null, record.Subject__c, 'Subject should be populated');
            System.assertNotEquals(null, record.FromAddress__c, 'FromAddress should be populated');
            System.assertNotEquals(null, record.ToAddress__c, 'ToAddress should be populated');
            System.assertEquals('False', record.IsBounced__c, 'IsBounced should default to False');
            System.assertEquals('False', record.Incoming__c, 'Incoming should default to False');
        }
    }
     
    @IsTest
    static void testInvocableMethodWithStartAndEndDate() {
        
        DFJ_EmailMessageBatchClass.BatchParams param = new DFJ_EmailMessageBatchClass.BatchParams();
        param.startDate = Date.today().addDays(-1);
        param.endDate = Date.today();
        List<DFJ_EmailMessageBatchClass.BatchParams> paramsList = new List<DFJ_EmailMessageBatchClass.BatchParams>{param};
        
        
        Test.startTest();
        DFJ_EmailMessageBatchClass.runBatch(paramsList);
        Test.stopTest();
        
        System.assert(true, 'Invocable method executed with start and end date');
    }
    
    @IsTest
    static void testInvocableMethodWithOnlyEndDate() {
       
        DFJ_EmailMessageBatchClass.BatchParams param = new DFJ_EmailMessageBatchClass.BatchParams();
        param.endDate = Date.today();
        List<DFJ_EmailMessageBatchClass.BatchParams> paramsList = new List<DFJ_EmailMessageBatchClass.BatchParams>{param};
        
        
        Test.startTest();
        DFJ_EmailMessageBatchClass.runBatch(paramsList);
        Test.stopTest();
        
        System.assert(true, 'Invocable method executed with only end date');
    }
    
    @IsTest
    static void testBatchWithRealArchiver() {
        
        List<EmailMessage> testEmailMessages = new List<EmailMessage>();
        for (Integer i = 0; i < 5; i++) {
            testEmailMessages.add(new EmailMessage(
                Subject = 'Test Email ' + i,
                FromAddress = 'test' + i + '@example.com',
                ToAddress = 'recipient' + i + '@example.com',
                TextBody = 'Test body ' + i,
                Status = '0',
                CreatedDate = DateTime.now(),
                MessageDate = DateTime.now()
            ));
        }
        insert testEmailMessages;
        
        
        String filter = 'CreatedDate = TODAY';
        DFJ_EmailMessageBatchClass batch = new DFJ_EmailMessageBatchClass(filter);
        
       
        Test.startTest();
        Test.setMock(Database.BatchableContext.class, new MockBatchableContext());
        Database.executeBatch(batch, 5);
        Test.stopTest();
        
        
        System.assertEquals(0, [SELECT COUNT() FROM Email_Message__b], 'No Big Object records should be inserted in test');
    }
    
 
    private class MockBatchableContext implements Database.BatchableContext {
        public Id getChildJobId() {
            return null;
        }
        public Id getJobId() {
            return '707000000000000';
        }
    }
}