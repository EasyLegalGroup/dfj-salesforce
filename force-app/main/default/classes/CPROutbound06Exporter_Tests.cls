@IsTest
private class CPROutbound06Exporter_Tests {

    // Helper: fetch file body by batch title
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
    static void export_creates_batch_exports_valid_marks_invalid_failed_and_links_file() {
        // Arrange: one valid + one invalid (should be marked Failed)
        CPR_Subscription_Add__c ok = new CPR_Subscription_Add__c(
            CPR__c = '2307922737', Status__c = 'Queued'
        );
        CPR_Subscription_Add__c bad = new CPR_Subscription_Add__c(
            CPR__c = '123', Status__c = 'Queued'
        );
        insert new List<CPR_Subscription_Add__c>{ ok, bad };

        // Act
        CPROutbound06Exporter.Req req = new CPROutbound06Exporter.Req();
        Test.startTest();
        List<CPROutbound06Exporter.Res> resp = CPROutbound06Exporter.run(new List<CPROutbound06Exporter.Req>{ req });
        Test.stopTest();

        // Assert response
        System.assertEquals(1, resp.size(), 'one response');
        System.assertEquals('OK', resp[0].message, 'export should succeed');
        System.assertEquals(1, resp[0].lines, 'one valid line should be exported');
        System.assertNotEquals(null, resp[0].batchId, 'batch should be created');
        Id batchId = resp[0].batchId;

        // Assert batch fields
        CPR_Outbound_Batch__c b = [
            SELECT Id, File_Name__c, Status__c, Notes__c
            FROM CPR_Outbound_Batch__c WHERE Id = :batchId
        ];
        System.assertEquals('Generated', b.Status__c);
        System.assertNotEquals(null, b.File_Name__c);
        System.assert(b.Notes__c != null && b.Notes__c.contains('Lines: 1') && b.Notes__c.contains('HEAD20='),
            'Notes should include count and HEAD20 breadcrumb');
        System.assert(b.Notes__c.contains('Skipped invalid CPR: 1'), 'Notes should mention skipped invalid CPR');

        // Assert rows: valid exported, invalid failed
        ok = [SELECT Status__c, Outbound_Batch__c FROM CPR_Subscription_Add__c WHERE Id = :ok.Id];
        bad = [SELECT Status__c, Outbound_Batch__c FROM CPR_Subscription_Add__c WHERE Id = :bad.Id];
        System.assertEquals('Exported', ok.Status__c);
        System.assertEquals(batchId, ok.Outbound_Batch__c);
        System.assertEquals('Failed', bad.Status__c, 'invalid CPR should be marked Failed');
        System.assertEquals(null, bad.Outbound_Batch__c, 'invalid should not be linked to batch');

        // Assert file content
        String body = getBodyByTitle(b.File_Name__c);
        System.assertNotEquals(null, body, 'file body should exist');
        String firstLine = body.split('\n')[0];
        System.assertEquals(80, firstLine.length(), 'each record must be exactly 80 chars');
        System.assertEquals('06', firstLine.substring(0, 2), 'record type');

        // NEW 06 layout checks:
        // [2..6)=kundenr(4), [6..8)='00', [8..10)='OP', [10..20)=CPR(10)
        System.assertEquals('00', firstLine.substring(6, 8), 'positions 7-8 should be 00');
        System.assertEquals('OP', firstLine.substring(8, 10), 'positions 9-10 should be OP');
        System.assertEquals('2307922737', firstLine.substring(10, 20), 'CPR at pos 11-20');
    }

    @IsTest
    static void export_with_precreated_batch_without_filename_self_heals() {
        // Arrange: pre-create batch without File_Name__c, plus one valid CPR
        CPR_Outbound_Batch__c pre = new CPR_Outbound_Batch__c(
            File_Date__c = Date.newInstance(2025, 8, 20),
            Status__c = 'New'
        );
        insert pre;
        CPR_Subscription_Add__c row = new CPR_Subscription_Add__c(
            CPR__c = '1111111111', Status__c = 'Queued'
        );
        insert row;

        // Act
        CPROutbound06Exporter.Req req = new CPROutbound06Exporter.Req();
        req.batchId = pre.Id;
        Test.startTest();
        List<CPROutbound06Exporter.Res> resp = CPROutbound06Exporter.run(new List<CPROutbound06Exporter.Req>{ req });
        Test.stopTest();

        // Assert
        System.assertEquals(1, resp.size());
        System.assertEquals('OK', resp[0].message);
        System.assertEquals(pre.Id, resp[0].batchId);

        CPR_Outbound_Batch__c b = [
            SELECT Id, File_Name__c, Status__c, Notes__c
            FROM CPR_Outbound_Batch__c WHERE Id = :pre.Id
        ];
        System.assertEquals('Generated', b.Status__c);
        System.assertNotEquals(null, b.File_Name__c);

        // Title must match batch file name
        String body = getBodyByTitle(b.File_Name__c);
        System.assertNotEquals(null, body);
        String line = body.split('\n')[0];
        System.assertEquals(80, line.length());
        System.assertEquals('06', line.substring(0,2));
        System.assertEquals('00', line.substring(6,8));
        System.assertEquals('OP', line.substring(8,10));
        System.assertEquals('1111111111', line.substring(10, 20)); // CPR at pos 11-20

        // Row marked exported and linked to batch
        row = [SELECT Status__c, Outbound_Batch__c FROM CPR_Subscription_Add__c WHERE Id = :row.Id];
        System.assertEquals('Exported', row.Status__c);
        System.assertEquals(pre.Id, row.Outbound_Batch__c);
    }
}