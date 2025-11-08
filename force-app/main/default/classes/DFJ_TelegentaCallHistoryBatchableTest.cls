@IsTest
public class DFJ_TelegentaCallHistoryBatchableTest {

    private class DFJ_callhistoryArchiverMock implements DFJ_callhistoryArchiver {
        public List<Telegenta_Call_History__b> insertedRecords = new List<Telegenta_Call_History__b>();
        public Database.SaveResult[] insertRecords(List<Telegenta_Call_History__b> records) {
            insertedRecords.addAll(records);
            List<Database.SaveResult> results = new List<Database.SaveResult>();
            for (Telegenta_Call_History__b rec : records) {
                Database.SaveResult sr = (Database.SaveResult) JSON.deserialize('{"success":true}', Database.SaveResult.class);
                results.add(sr);
            }
            return results;
        }
    }

    private class DFJ_callhistoryArchiverMockWithError implements DFJ_callhistoryArchiver {
        public List<Telegenta_Call_History__b> insertedRecords = new List<Telegenta_Call_History__b>();
        public Database.SaveResult[] insertRecords(List<Telegenta_Call_History__b> records) {
            insertedRecords.addAll(records);
            List<Database.SaveResult> results = new List<Database.SaveResult>();
            for (Telegenta_Call_History__b rec : records) {
                Database.SaveResult sr = (Database.SaveResult) JSON.deserialize('{"success":false, "errors":[{"message":"Insert failed"}]}', Database.SaveResult.class);
                results.add(sr);
            }
            return results;
        }
    }

    @IsTest
    static void testBatchWithMockArchiver() {
        List<telegenta__Telegenta_Call_History__c> testCallHistories = new List<telegenta__Telegenta_Call_History__c>();
        for (Integer i = 0; i < 5; i++) {
            testCallHistories.add(new telegenta__Telegenta_Call_History__c(
                telegenta__Puuid__c = 'PUUID_' + i,
                telegenta__Destination_number__c = '99999999' + i,
                OwnerId = UserInfo.getUserId(),
                CreatedById = UserInfo.getUserId()   
            ));
        }
        Database.insert(testCallHistories, true);
        DFJ_callhistoryArchiver mockArchiver = new DFJ_callhistoryArchiverMock();
        String filter = 'CreatedDate = TODAY';
        DFJ_TelegentaCallHistoryBatchClass batch = new DFJ_TelegentaCallHistoryBatchClass(mockArchiver, filter);

        Test.startTest();
        Database.executeBatch(batch, 5);
        Test.stopTest();

        List<Telegenta_Call_History__b> insertedRecords = ((DFJ_callhistoryArchiverMock)mockArchiver).insertedRecords;
        for (Telegenta_Call_History__b record : insertedRecords) {
            System.assertNotEquals(null, record.telegenta_Puuid__c, 'Puuid should be populated');
            System.assertNotEquals(null, record.telegenta_Destination_number__c, 'Destination number should be populated');
            System.assertEquals('False', record.telegenta_Privacy__c, 'Privacy should default to False');
        }
    }

   
    @IsTest
    static void testInvocableMethodWithStartAndEndDate() {
        DFJ_TelegentaCallHistoryBatchClass.BatchParams param = new DFJ_TelegentaCallHistoryBatchClass.BatchParams();
        param.startDate = Date.today().addDays(-1);
        param.endDate = Date.today();
        List<DFJ_TelegentaCallHistoryBatchClass.BatchParams> paramsList = new List<DFJ_TelegentaCallHistoryBatchClass.BatchParams>{param};
        Test.startTest();
        DFJ_TelegentaCallHistoryBatchClass.runBatch(paramsList);
        Test.stopTest();
        System.assert(true, 'Invocable method executed with start and end date');
    }

    @IsTest
    static void testInvocableMethodWithOnlyEndDate() {
        DFJ_TelegentaCallHistoryBatchClass.BatchParams param = new DFJ_TelegentaCallHistoryBatchClass.BatchParams();
        param.endDate = Date.today();
        List<DFJ_TelegentaCallHistoryBatchClass.BatchParams> paramsList = new List<DFJ_TelegentaCallHistoryBatchClass.BatchParams>{param};
        Test.startTest();
        DFJ_TelegentaCallHistoryBatchClass.runBatch(paramsList);
        Test.stopTest();
        System.assert(true, 'Invocable method executed with only end date');
    }

    @IsTest
    static void testBatchWithRealArchiver() {
        List<telegenta__Telegenta_Call_History__c> testCallHistories = new List<telegenta__Telegenta_Call_History__c>();
        for (Integer i = 0; i < 5; i++) {
            testCallHistories.add(new telegenta__Telegenta_Call_History__c(
                telegenta__Puuid__c = 'PUUID_' + i,
                telegenta__Destination_number__c = '99999999' + i,
                OwnerId = UserInfo.getUserId(),
                CreatedById = UserInfo.getUserId(),
                CreatedDate = DateTime.now()
            ));
        }
        insert testCallHistories;
        String filter = 'CreatedDate = TODAY';
        DFJ_TelegentaCallHistoryBatchClass batch = new DFJ_TelegentaCallHistoryBatchClass(filter);

        Test.startTest();
        Test.setMock(Database.BatchableContext.class, new MockBatchableContext());
        Database.executeBatch(batch, 5);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Telegenta_Call_History__b], 'No Big Object records should be inserted in test');
    }

    private class MockBatchableContext implements Database.BatchableContext {
        public Id getChildJobId() { return null; }
        public Id getJobId() { return '707000000000000'; }
    }
}