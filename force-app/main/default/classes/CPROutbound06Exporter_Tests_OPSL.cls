@IsTest
private class CPROutbound06Exporter_Tests_OPSL {

    private static Boolean hasOperationField() {
        Schema.DescribeSObjectResult d = CPR_Subscription_Add__c.SObjectType.getDescribe();
        return d != null && d.fields.getMap().containsKey('Operation__c');
    }
    private static String getBodyByTitle(String title) {
        ContentVersion cv = [
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE Title = :title
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        return cv.VersionData.toString();
    }

    @IsTest
    static void export_honors_OP_and_SL_when_present() {
        // Arrange two valid rows: one OP (default), one SL if field exists
        CPR_Subscription_Add__c r1 = new CPR_Subscription_Add__c(CPR__c='1010101010', Status__c='Queued');
        CPR_Subscription_Add__c r2 = new CPR_Subscription_Add__c(CPR__c='2020202020', Status__c='Queued');
        Boolean hasOp = hasOperationField();
        if (hasOp) {
            // dynamic put to avoid compile-time dependency
            r2.put('Operation__c','SL');
        }
        insert new List<CPR_Subscription_Add__c>{ r1, r2 };

        // Act
        CPROutbound06Exporter.Req req = new CPROutbound06Exporter.Req();
        Test.startTest();
        List<CPROutbound06Exporter.Res> resp = CPROutbound06Exporter.run(new List<CPROutbound06Exporter.Req>{ req });
        Test.stopTest();

        System.assertEquals(1, resp.size());
        System.assertEquals('OK', resp[0].message);
        Id batchId = resp[0].batchId;

        CPR_Outbound_Batch__c b = [
            SELECT Id, File_Name__c, Status__c, Notes__c
            FROM CPR_Outbound_Batch__c WHERE Id = :batchId
        ];
        System.assertEquals('Generated', b.Status__c);

        // Assert file content mapping CPR→OP/SL at pos 9-10
        String body = getBodyByTitle(b.File_Name__c);
        String[] lines = body.split('\n');
        Map<String,String> cprToOp = new Map<String,String>();
        for (String line : lines) {
            if (String.isBlank(line)) continue;
            cprToOp.put(line.substring(10,20), line.substring(8,10)); // CPR[11-20], OP/SL[9-10]
        }
        System.assertEquals('OP', cprToOp.get('1010101010'), 'First should be OP');
        if (hasOp) {
            System.assertEquals('SL', cprToOp.get('2020202020'), 'Second should be SL when field exists');
        } else {
            System.assertEquals('OP', cprToOp.get('2020202020'), 'Fallback OP when field missing');
        }
    }
}