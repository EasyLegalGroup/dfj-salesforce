@IsTest
private class CPRIngestInvocable_Tests {

    @IsTest
    static void ingest_A21_sets_datetime_and_is_idempotent() {
        Account a = new Account(Name = 'Test Account');
        insert a;
        Contact c = new Contact(LastName='Citizen', AccountId=a.Id, CPR__c='2012711398');
        insert c;

        String body =
            '0012012711398202204291453\n' +
            '0092012711398202508181205A21\n' +
            '99900000002\n';

        ContentVersion cv = new ContentVersion(
            Title='u09480_unit_test_a21.txt',
            PathOnClient='u09480_unit_test_a21.txt',
            VersionData=Blob.valueOf(body)
        );
        insert cv;

        CPRIngestInvocable.Request req = new CPRIngestInvocable.Request();
        req.contentVersionId = cv.Id;

        Test.startTest();
        CPRIngestInvocable.run(new List<CPRIngestInvocable.Request>{ req });
        // run twice to prove idempotency (upsert by Event_Key__c)
        CPRIngestInvocable.run(new List<CPRIngestInvocable.Request>{ req });
        Test.stopTest();

        CPR_Event__c ev = [
            SELECT Id, Event_Key__c, CPR_File_Run__c, Event_Code__c, Action__c, CPR_From_File__c,
                   Effective_Date__c, Status_Code__c, Event_Datetime__c, Contact__c, Account__c,
                   Raw_Record__c, Details_Raw__c
            FROM CPR_Event__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals('A21', ev.Event_Code__c);
        System.assertEquals('Death_A21', ev.Action__c);
        System.assertEquals('2012711398', ev.CPR_From_File__c);
        System.assertEquals('90', ev.Status_Code__c);
        System.assertEquals(Date.newInstance(2025, 8, 18), ev.Effective_Date__c);
        System.assertEquals(Datetime.newInstance(2025, 8, 18, 12, 5, 0), ev.Event_Datetime__c);
        System.assertEquals(c.Id, ev.Contact__c);
        System.assertEquals(a.Id, ev.Account__c);
        System.assertEquals('0092012711398202508181205A21', ev.Raw_Record__c.trim());

        Integer cnt = [SELECT count() FROM CPR_Event__c WHERE Event_Key__c = :ev.Event_Key__c];
        System.assertEquals(1, cnt, 'Upsert by Event_Key__c should prevent duplicates across runs.');
    }

    @IsTest
    static void ingest_P02_captures_detail_lines() {
        Contact c = new Contact(LastName='Address Person', CPR__c='1604852702');
        insert c;

        String body =
            '0011604852702202508200000\n' +
            '0091604852702202508200930P02\n' +
            '090 ADRESSE NY: Aboulevarden 1, 8000 Aarhus C | ADRESSE GL: Old Street 1, 2100 Kobenhavn O\n' +
            '99900000004\n';

        ContentVersion cv = new ContentVersion(
            Title='u09480_unit_test_p02.txt',
            PathOnClient='u09480_unit_test_p02.txt',
            VersionData=Blob.valueOf(body)
        );
        insert cv;

        CPRIngestInvocable.Request req = new CPRIngestInvocable.Request();
        req.contentVersionId = cv.Id;

        Test.startTest();
        CPRIngestInvocable.run(new List<CPRIngestInvocable.Request>{ req });
        Test.stopTest();

        CPR_Event__c ev = [
            SELECT Event_Code__c, Action__c, CPR_From_File__c,
                   Effective_Date__c, Event_Datetime__c,
                   Details_Raw__c, Contact__c
            FROM CPR_Event__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('P02', ev.Event_Code__c);
        System.assertEquals('AddressChange', ev.Action__c);
        System.assertEquals('1604852702', ev.CPR_From_File__c);
        System.assertEquals(Date.newInstance(2025, 8, 20), ev.Effective_Date__c);
        System.assertEquals(Datetime.newInstance(2025, 8, 20, 9, 30, 0), ev.Event_Datetime__c);
        System.assertEquals(c.Id, ev.Contact__c);
        System.assertNotEquals(null, ev.Details_Raw__c);
        System.assert(ev.Details_Raw__c.contains('ADRESSE NY:'), 'Expected detail text in Details_Raw__c');
    }

    @IsTest
    static void ingest_A01_attaches_preceding_001_snapshot() {
        Contact c = new Contact(LastName='A01 Person', CPR__c='0105941986');
        insert c;

        String body =
            '0010105941986202508010000    Test Street 1, 2100 City\n' +
            '0090105941986202508011232A01\n' +
            '99900000003\n';

        ContentVersion cv = new ContentVersion(
            Title='u09480_unit_test_a01.txt',
            PathOnClient='u09480_unit_test_a01.txt',
            VersionData=Blob.valueOf(body)
        );
        insert cv;

        CPRIngestInvocable.Request req = new CPRIngestInvocable.Request();
        req.contentVersionId = cv.Id;

        Test.startTest();
        CPRIngestInvocable.run(new List<CPRIngestInvocable.Request>{ req });
        Test.stopTest();

        CPR_Event__c ev = [
            SELECT Event_Code__c, Action__c, CPR_From_File__c, Details_Raw__c
            FROM CPR_Event__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('A01', ev.Event_Code__c);
        System.assertEquals('Other', ev.Action__c, 'A01 currently routed to review');
        System.assertEquals('0105941986', ev.CPR_From_File__c);
        System.assertNotEquals(null, ev.Details_Raw__c);
        System.assert(ev.Details_Raw__c.startsWith('0010105941986'),
            'Expect 001 snapshot copied into Details_Raw__c');
    }

    // Snapshot/monthly file should be skipped; do not assert a specific picklist value
    @IsTest
    static void reject_monthly_snapshot_is_rejected_and_creates_zero_events() {
        // Build a snapshot-looking body: many 001, no 009
        String body = '00058560220250801\n';
        for (Integer i = 0; i < 150; i++) {
            body += '0010101471047202204291453\n';
        }
        body += '99500002930202508010000\n9999999999999\n';

        // Name the file as monthly (.l585602) so filename guard triggers
        ContentVersion cv = new ContentVersion(
            Title='d250801.l585602',
            PathOnClient='d250801.l585602',
            VersionData=Blob.valueOf(body)
        );
        insert cv;

        CPRIngestInvocable.Request req = new CPRIngestInvocable.Request();
        req.contentVersionId = cv.Id;
        req.fileDate = Date.newInstance(2025, 8, 1);

        Test.startTest();
        List<CPRIngestInvocable.Response> resp =
            CPRIngestInvocable.run(new List<CPRIngestInvocable.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, resp.size());
        System.assertEquals('Skipped snapshot', resp[0].message);
        System.assertEquals(0, resp[0].eventsCreated);

        // Check the run record: don't assert a specific picklist value
        CPR_File_Run__c fr = [
            SELECT Status__c, Record_001_Count__c, Notes__c
            FROM CPR_File_Run__c
            WHERE Id = :resp[0].fileRunId
        ];
        System.assert(fr.Record_001_Count__c >= 150, 'Should record large 001 count');
        System.assertNotEquals('Parsed', fr.Status__c, 'Snapshot should not be Parsed');
        System.assert(fr.Notes__c != null && fr.Notes__c.contains('Skipped snapshot'),
            'Notes should explain rejection/skip');

        // Ensure no events got created
        Integer events = [SELECT count() FROM CPR_Event__c WHERE CPR_File_Run__c = :resp[0].fileRunId];
        System.assertEquals(0, events, 'No events should be created for snapshot files.');
    }

    @IsTest
    static void ingest_existing_file_run_path_sets_counts_and_events() {
        // Minimal valid "full" file (001 + 009 + 999)
        String body =
            '0012012711398202508260000\n' +
            '0092012711398202508260930A45\n' +
            '99900000003\n';

        ContentVersion cv = new ContentVersion(
            Title='u09480_unit_test_existing_run.txt',
            PathOnClient='d250826.l585601',
            VersionData=Blob.valueOf(body)
        );
        insert cv;

        // Pre-create File Run as if the flow already made it
        CPR_File_Run__c fr = new CPR_File_Run__c(
            File_Date__c = Date.newInstance(2025, 8, 26),
            File_Name__c = 'Manual Upload' // non-blank name (else-branch must SELECT it)
        );
        insert fr;

        CPRIngestInvocable.Request req = new CPRIngestInvocable.Request();
        req.contentVersionId = cv.Id;
        req.fileRunId        = fr.Id;
        req.fileDate         = Date.newInstance(2025, 8, 26);

        Test.startTest();
        List<CPRIngestInvocable.Response> resp =
            CPRIngestInvocable.run(new List<CPRIngestInvocable.Request>{ req });
        Test.stopTest();

        // Assert the run got parsed and counts were written
        fr = [SELECT Status__c, Record_001_Count__c, Event_009_Count__c, File_Name__c
              FROM CPR_File_Run__c WHERE Id = :fr.Id];
        System.assertNotEquals('Failed', fr.Status__c, 'Run should not be Failed');
        System.assertEquals(1, fr.Record_001_Count__c, '001 count');
        System.assertEquals(1, fr.Event_009_Count__c, '009 count');
        System.assert(!String.isBlank(fr.File_Name__c), 'File name should be available');

        Integer evs = [SELECT count() FROM CPR_Event__c WHERE CPR_File_Run__c = :fr.Id];
        System.assertEquals(1, evs, 'One event should be upserted');
        System.assertEquals('OK', resp[0].message);
        System.assertEquals(fr.Id, resp[0].fileRunId);
    }

    @IsTest
    static void ingest_existing_run_populates_missing_file_name_if_blank() {
        String body =
            '0010101010101202508260000\n' +
            '0090101010101202508260800A45\n' +
            '99900000003\n';

        ContentVersion cv = new ContentVersion(
            Title='u09480_unit_test_fill_name.txt',
            PathOnClient='my_upload.txt',
            VersionData=Blob.valueOf(body)
        );
        insert cv;

        // Create run WITHOUT File_Name__c to exercise the "fill from cv" code path
        CPR_File_Run__c fr = new CPR_File_Run__c(File_Date__c = Date.newInstance(2025, 8, 26));
        insert fr;

        CPRIngestInvocable.Request req = new CPRIngestInvocable.Request();
        req.contentVersionId = cv.Id;
        req.fileRunId        = fr.Id;

        Test.startTest();
        CPRIngestInvocable.run(new List<CPRIngestInvocable.Request>{ req });
        Test.stopTest();

        fr = [SELECT File_Name__c FROM CPR_File_Run__c WHERE Id = :fr.Id];
        System.assertEquals('my_upload.txt', fr.File_Name__c,
            'When File_Name__c is blank, it should be set from PathOnClient/Title');
    }
}