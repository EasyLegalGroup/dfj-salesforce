@isTest
public class GEN_RecordDeletionBatch_Test {
    
  @isTest static void recordDeletionBatchtest() {
        
        Record_Deletion_Batch_Configuration__c recordDeletionBatchConfig = new Record_Deletion_Batch_Configuration__c();
        recordDeletionBatchConfig.Email_addresses__c = 'kushagra.mishra@cloudanalogy.com,sahil.saini@cloudanalogy.com';
        recordDeletionBatchConfig.Is_active__c = true;
        insert recordDeletionBatchConfig;
        
        telegenta__Telegenta_Call_History__c telegentaHistory = new telegenta__Telegenta_Call_History__c();
        telegentaHistory.telegenta__Active_Duration__c = 124;
        insert telegentaHistory;
        
        Datetime startDateTime = Datetime.newInstance(2022, 23, 8, 12, 30, 2);
        Datetime endDateTime = Datetime.newInstance(2022, 25,8, 12,30,2);
        List<telegenta__Telegenta_Call_Recording__c> listofCallRecord = new List<telegenta__Telegenta_Call_Recording__c>();
        for(Integer i =0 ; i<10 ; i++){
            telegenta__Telegenta_Call_Recording__c callRecord = new telegenta__Telegenta_Call_Recording__c();
            callRecord.telegenta__Telegenta_Call_History__c = telegentaHistory.Id;
            callRecord.telegenta__Start_Time__c = startDateTime;
            callRecord.telegenta__Media_URL__c = 'www.xyz.com';
            callRecord.telegenta__Size__c = 123;
            callRecord.telegenta__Recording_Id__c = '12345678990';
            callRecord.telegenta__Length__c = 234;
            callRecord.telegenta__Recording_Delete_Date__c = endDateTime;
             callRecord.telegenta__Record_Player__c = 'www.abcde.com';
            listofCallRecord.add(callRecord);
        }
        insert listofCallRecord;
        System.debug('listofCallRecord'+ listofCallRecord);
      
        String query = 'SELECT Id, Name ,telegenta__Recording_Id__c,telegenta__Start_Time__c,telegenta__Recording_Delete_Date__c,telegenta__Media_URL__c ,telegenta__Telegenta_Call_History__c,telegenta__Length__c,telegenta__Size__c From telegenta__Telegenta_Call_Recording__c LIMIT 1000 ';
        String objName = 'telegenta__Telegenta_Call_Recording__c';
        List<String> emaillList = recordDeletionBatchConfig.Email_addresses__c.split(',');
        System.debug('emaillList>>> '+emaillList);
        //List<String> emailList = new List<String>{'kushagra.mishra@cloudanalogy.com'};

        Test.startTest();
        GEN_RecordDeletionBatch uca = new GEN_RecordDeletionBatch(query, objName,emaillList);
        Id batchId = Database.executeBatch(uca);
        Test.stopTest();
      
        System.assertEquals(0, [select count() From telegenta__Telegenta_Call_Recording__c], 'GEN_RecordDeletionBatch TestClass');
    }
    
    @isTest static void scheduleBatchTestWithCron() {
        List<String> emailList = new List<String>{'kushagra.mishra@cloudanalogy.com'};
        Test.startTest();
        GEN_RecordDeletionBatch.start('0 5 * * * ? *', 'SELECT Id, Name ,telegenta__Recording_Id__c,telegenta__Start_Time__c,telegenta__Recording_Delete_Date__c,telegenta__Media_URL__c ,telegenta__Telegenta_Call_History__c,telegenta__Length__c,telegenta__Size__c From telegenta__Telegenta_Call_Recording__c', 'telegenta__Telegenta_Call_Recording__c', 'SchedulableJobFirst',emailList);
        Test.stopTest();
    }
    
    @isTest static void scheduleBatchTestWithoutCron() {
        List<String> emailList = new List<String>{'kushagra.mishra@cloudanalogy.com'};
        Test.startTest();
        GEN_RecordDeletionBatch.start('', 'SELECT Id, Name ,telegenta__Recording_Id__c,telegenta__Start_Time__c,telegenta__Recording_Delete_Date__c,telegenta__Media_URL__c ,telegenta__Telegenta_Call_History__c,telegenta__Length__c,telegenta__Size__c From telegenta__Telegenta_Call_Recording__c', 'telegenta__Telegenta_Call_Recording__c', 'SchedulableJobFirst',emailList);
        Test.stopTest();
    }
}