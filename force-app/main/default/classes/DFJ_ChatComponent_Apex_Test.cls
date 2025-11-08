@IsTest
private with sharing class DFJ_ChatComponent_Apex_Test {
    @TestSetup
    static void testSetupMethod() {
        List<RecordType> denmarkLeadRecordType = [
            SELECT Id
            FROM RecordType
            WHERE SobjectType = 'Lead'
              AND DeveloperName = 'DFJ_DK'
            LIMIT 1
        ];

        if (!denmarkLeadRecordType.isEmpty()) {
            Lead leadRecord = new Lead(
                RecordTypeId    = denmarkLeadRecordType[0].Id,
                LastName        = 'test',
                Company         = 'Acme',
                Provider_id__c  = 'test@gmail.com',
                CurrencyIsoCode = 'DKK',
                Phone           = '12345'
            );
            insert leadRecord;
        }
    }

    @IsTest
    static void getRenderedEmailTemplateTest() {
        List<Folder> folder = [SELECT Id, Name FROM Folder WHERE Name LIKE '%mail%' LIMIT 1];
        List<Lead> leadRecord = getLeadRecord();

        if (!folder.isEmpty() && !leadRecord.isEmpty()) {
            Id folderId = folder[0].Id;
            EmailTemplate emailTemplate = new EmailTemplate(
                Name          = 'Test Email Template',
                FolderId      = folderId,
                TemplateType  = 'text',
                DeveloperName = 'Test_Email_Template',
                Subject       = 'Test Email Template',
                HtmlValue     = '<html><head></head><body><p>Test Email Template</p></body></html>'
            );
            insert emailTemplate;

            String rendered = DFJ_ChatComponent_Apex.getRenderedEmailTemplate(emailTemplate.Id, leadRecord[0].Id);
            System.assertNotEquals(null, rendered, 'Rendered email template should not be null.');
        }
    }

    @IsTest
    static void getSMSDetailsTest() {
        List<Lead> leadRecord = getLeadRecord();
        if (!leadRecord.isEmpty()) {
            DFJ_ChatComponent_Apex.SMSDetailsWrapper wrap =
                DFJ_ChatComponent_Apex.getSMSDetails(leadRecord[0].Id, 'Phone');
            System.assertNotEquals(null, wrap, 'Wrapper should not be null');
            System.assertEquals('Lead', wrap.sObjectName, 'Should resolve sObject name to Lead');
        }
    }

    @IsTest
    static void createOutgoingSMSRecordTestWithAlphanumericSender() {
        List<Lead> leadRecord = getLeadRecord();
        if (!leadRecord.isEmpty()) {
            String response = DFJ_ChatComponent_Apex.createOutgoingSMSRecord(
                leadRecord[0].Id, 'Id', 'FamJurist', '54321', 'Test', 'DFJ_DK', 'DKK'
            );
            System.assertEquals('Success', response);
        }
    }

    @IsTest
    static void testGetEmailTemplatesByFolderName() {
        List<EmailTemplate> tpls = DFJ_ChatComponent_Apex.getEmailTemplatesByFolderName();
        System.assertNotEquals(null, tpls, 'List should not be null');
    }

    @IsTest
    static void testGetSobjectTypeFromRecordId_Apex() {
        Lead l = getLeadRecord()[0];
        String name = DFJ_ChatComponent_Apex.getSobjectTypeFromRecordId_Apex(l.Id);
        System.assertEquals('Lead', name);
    }

    @IsTest
    static void testGetSendToOptionValues_OnLead() {
        Lead l = getLeadRecord()[0];
        Map<String,String> options = DFJ_ChatComponent_Apex.getSendToOptionValues(l.Id, 'Lead');
        System.assertNotEquals(null, options);
        System.assert(options.size() > 0);
    }

    @IsTest
    static void testGetSMSRecords_NoDataSafePath() {
        Lead l = getLeadRecord()[0];
        List<SMS__c> listy = DFJ_ChatComponent_Apex.getSMSRecords((String)l.Id, 'Lead');
        System.assertNotEquals(null, listy);
    }

    // Readback test uses direct inserts (doesn't depend on Flow behavior)
    @IsTest
    static void testGetSMSRecords_AfterFlowInsertion() {
        Lead l = getLeadRecord()[0];

        insert new SMS__c(
            Record_ID__c = l.Id,
            Message__c   = 'Incoming hi',
            Direction__c = 'Incoming',
            To_Number__c = '4542455150',
            From_Number__c = '4511122233',
            Type__c      = 'Custom'
        );
        insert new SMS__c(
            Record_ID__c = l.Id,
            Message__c   = 'Outgoing yo',
            Direction__c = 'Outgoing',
            To_Number__c = '4511122233',
            From_Number__c = '4542455150',
            Type__c      = 'Custom'
        );

        List<SMS__c> records = DFJ_ChatComponent_Apex.getSMSRecords((String)l.Id, 'Lead');
        System.assert(records.size() >= 2, 'Should retrieve at least the two inserted SMS');
    }

    @IsTest
    static void testGetCurrencyIsoCode() {
        Lead l = getLeadRecord()[0];
        String code = DFJ_ChatComponent_Apex.getCurrencyIsoCode((String)l.Id, 'Lead');
        System.assertEquals('DKK', code);
    }

    @IsTest
    static void testGetMarketUnit_OnLead_NotNull() {
        Lead l = getLeadRecord()[0];
        String mu = DFJ_ChatComponent_Apex.getMarketUnit((String)l.Id, 'Lead');
        System.assertNotEquals(null, mu, 'Market Unit is populated in this org');
    }

    @IsTest
    static void testGetSendToOptionDefaultValue_AllowsFormatted() {
        Lead l = getLeadRecord()[0];
        String val = DFJ_ChatComponent_Apex.getSendToOptionDefaultValue((String)l.Id, 'Lead', 'Phone');
        System.assertNotEquals(null, val);
        System.assert(val.endsWith('12345'), 'Allow normalized phone (+45…) but must end with seeded 12345');
    }

    @IsTest
    static void testGetCustomerName_DefaultAndExplicitField() {
        Lead l = getLeadRecord()[0];

        String nameDefault = DFJ_ChatComponent_Apex.getCustomerName((String)l.Id, 'Lead', null);
        System.assertNotEquals('Customer', nameDefault, 'Default should resolve a name, not the fallback');

        String dbLast = [SELECT LastName FROM Lead WHERE Id = :l.Id].LastName;
        String lastName = DFJ_ChatComponent_Apex.getCustomerName((String)l.Id, 'Lead', 'LastName');
        System.assertEquals(dbLast, lastName, 'Should return whatever LastName is in DB');
    }

    @IsTest
    static void test_getSMSDetails_marketUnit_branches() {
        Lead l = getLeadRecord()[0];

        l.Market_Unit__c = 'FA_SE';
        update l;
        DFJ_ChatComponent_Apex.SMSDetailsWrapper seWrap = DFJ_ChatComponent_Apex.getSMSDetails(l.Id, 'Phone');
        System.assertEquals('FA_SE', seWrap.marketUnit);
        System.assertEquals('+46 765106079', seWrap.sendFromPhoneNumber);

        l.Market_Unit__c = 'Ireland';
        update l;
        DFJ_ChatComponent_Apex.SMSDetailsWrapper ieWrap = DFJ_ChatComponent_Apex.getSMSDetails(l.Id, 'Phone');
        System.assertEquals('Ireland', ieWrap.marketUnit);
        System.assertEquals('N/A', ieWrap.sendFromPhoneNumber);

        l.Market_Unit__c = 'DFJ_DK';
        update l;
        DFJ_ChatComponent_Apex.SMSDetailsWrapper dkWrap = DFJ_ChatComponent_Apex.getSMSDetails(l.Id, 'Phone');
        System.assertEquals('DFJ_DK', dkWrap.marketUnit);
        System.assertEquals('+45 30812521', dkWrap.sendFromPhoneNumber);
    }

    @IsTest
    static void test_getSMSDetails_fallback_onContact() {
        Contact c = new Contact(LastName = 'C Test', Phone = '(+45) 42 45 51 50');
        insert c;
        DFJ_ChatComponent_Apex.SMSDetailsWrapper wrap = DFJ_ChatComponent_Apex.getSMSDetails(c.Id, 'Phone');
        System.assertEquals('Contact', wrap.sObjectName);
        System.assertNotEquals(null, wrap.sendToOptionLabelsAndValues);
        System.assertNotEquals(null, wrap);
    }

    @IsTest
    static void test_createOutgoingSMSRecord_normalization_mappings() {
        Lead l = getLeadRecord()[0];

        String resSE = DFJ_ChatComponent_Apex.createOutgoingSMSRecord(
            l.Id, 'Id', '+46 765106079', '0701234567', 'Hej SE', 'FA_SE', 'SEK'
        );
        System.assertEquals('Success', resSE);

        String resIE = DFJ_ChatComponent_Apex.createOutgoingSMSRecord(
            l.Id, 'Id', 'N/A', '0871234567', 'Hi IE', 'Ireland', 'EUR'
        );
        System.assertEquals('Success', resIE);

        String resFallbackField = DFJ_ChatComponent_Apex.createOutgoingSMSRecord(
            l.Id, 'DoesNotExist__c', '+45 30812521', '42455150', 'Field fallback', 'DFJ_DK', 'DKK'
        );
        System.assertEquals('Success', resFallbackField);
    }

    @IsTest
    static void test_catch_paths_invalids() {
        Lead l = getLeadRecord()[0];

        Map<String,String> badOptions = DFJ_ChatComponent_Apex.getSendToOptionValues(l.Id, 'Nope__c');
        System.assertEquals(null, badOptions);

        String badSendTo = DFJ_ChatComponent_Apex.getSendToOptionDefaultValue((String)l.Id, 'Lead', 'DoesNotExist__c');
        System.assertEquals(null, badSendTo);

        String sObj = DFJ_ChatComponent_Apex.getSobjectTypeFromRecordId_Apex((Id) null);
        System.assertEquals(null, sObj);

        List<SMS__c> injected = DFJ_ChatComponent_Apex.getSMSRecords('bad\'id', 'Lead');
        System.assertEquals(0, injected.size());

        String badIso = DFJ_ChatComponent_Apex.getCurrencyIsoCode((String)l.Id, 'Nope__c');
        System.assertEquals(null, badIso);

        String fallbackName = DFJ_ChatComponent_Apex.getCustomerName((String)l.Id, 'Lead', 'Nope__c');
        System.assertEquals('Customer', fallbackName);
    }

    @IsTest
    static void test_PersonAccount_getSMSDetails() {
        Account personAccount = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            PersonEmail = 'john.doe@test.com',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsPersonType = true LIMIT 1]?.Id
        );
        if (personAccount.RecordTypeId != null) {
            insert personAccount;
            personAccount = [SELECT Id, PersonContactId, IsPersonAccount FROM Account WHERE Id = :personAccount.Id];
            DFJ_ChatComponent_Apex.SMSDetailsWrapper wrapper = DFJ_ChatComponent_Apex.getSMSDetails(personAccount.Id, 'PersonMobilePhone');
            System.assertEquals(true, wrapper.isPersonAccount, 'Should detect PersonAccount');
            System.assertEquals(personAccount.PersonContactId, wrapper.personContactId, 'Should return PersonContactId');
            System.assertEquals('Account', wrapper.sObjectName, 'Should be Account object');
        }
    }

    @IsTest
    static void test_PersonAccount_getSMSRecords() {
        Account personAccount = new Account(
            FirstName = 'Jane',
            LastName = 'Smith',
            PersonEmail = 'jane.smith@test.com',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsPersonType = true LIMIT 1]?.Id
        );
        if (personAccount.RecordTypeId != null) {
            insert personAccount;
            personAccount = [SELECT Id, PersonContactId, IsPersonAccount FROM Account WHERE Id = :personAccount.Id];

            SMS__c sms1 = new SMS__c(
                Record_ID__c = personAccount.Id,
                Message__c   = 'SMS to Account ID',
                Direction__c = 'Outgoing',
                To_Number__c = '4542455150',
                Type__c      = 'Custom'
            );
            SMS__c sms2 = new SMS__c(
                Record_ID__c = personAccount.PersonContactId,
                Message__c   = 'SMS to PersonContactId',
                Direction__c = 'Incoming',
                To_Number__c = '4542455150',
                Type__c      = 'Custom'
            );
            insert new List<SMS__c>{sms1, sms2};

            List<SMS__c> smsRecords = DFJ_ChatComponent_Apex.getSMSRecords(personAccount.Id, 'Account');
            System.assertEquals(2, smsRecords.size(), 'Should retrieve SMS records matching both AccountId and PersonContactId');
            Set<String> messages = new Set<String>();
            for (SMS__c sms : smsRecords) messages.add(sms.Message__c);
            System.assert(messages.contains('SMS to Account ID'));
            System.assert(messages.contains('SMS to PersonContactId'));
        }
    }

    @IsTest
    static void test_markSMSAsRead() {
        Lead l = getLeadRecord()[0];

        SMS__c sms1 = new SMS__c(
            Record_ID__c = l.Id,
            Message__c   = 'Unread message 1',
            Direction__c = 'Incoming',
            To_Number__c = '4542455150',
            From_Number__c = '4512345678',
            Type__c      = 'Custom',
            Is_Read__c   = false
        );
        SMS__c sms2 = new SMS__c(
            Record_ID__c = l.Id,
            Message__c   = 'Unread message 2',
            Direction__c = 'Incoming',
            To_Number__c = '4542455150',
            From_Number__c = '4512345678',
            Type__c      = 'Custom',
            Is_Read__c   = false
        );
        insert new List<SMS__c>{sms1, sms2};

        List<SMS__c> unreadMessages = [SELECT Id, Is_Read__c FROM SMS__c WHERE Id IN :new List<Id>{sms1.Id, sms2.Id}];
        for (SMS__c sms : unreadMessages) System.assertEquals(false, sms.Is_Read__c);

        String result = DFJ_ChatComponent_Apex.markSMSAsRead(new List<String>{sms1.Id, sms2.Id});
        System.assertEquals('Success', result);

        List<SMS__c> readMessages = [SELECT Id, Is_Read__c FROM SMS__c WHERE Id IN :new List<Id>{sms1.Id, sms2.Id}];
        for (SMS__c sms : readMessages) System.assertEquals(true, sms.Is_Read__c);
    }

    @IsTest
    static void test_markSMSAsRead_emptyList() {
        String result = DFJ_ChatComponent_Apex.markSMSAsRead(new List<String>());
        System.assertEquals('Success', result);
        result = DFJ_ChatComponent_Apex.markSMSAsRead(null);
        System.assertEquals('Success', result);
    }

    @IsTest
    static void test_getFieldValue() {
        List<Lead> leadRecords = getLeadRecord();
        System.assertNotEquals(0, leadRecords.size(), 'Should have a test Lead record');
        Lead l = leadRecords[0];

        Test.startTest();
        String lastName = DFJ_ChatComponent_Apex.getFieldValue(l.Id, 'Lead', 'LastName');
        System.assertNotEquals(null, lastName);
        String phone = DFJ_ChatComponent_Apex.getFieldValue(l.Id, 'Lead', 'Phone');
        System.assertNotEquals(null, phone);
        String invalidField = DFJ_ChatComponent_Apex.getFieldValue(l.Id, 'Lead', 'NonExistentField__c');
        System.assertEquals(null, invalidField);
        Test.stopTest();
    }

    @IsTest
    static void test_getFieldValue_invalidInputs() {
        List<Lead> leadRecords = getLeadRecord();
        if (!leadRecords.isEmpty()) {
            Test.startTest();
            String result = DFJ_ChatComponent_Apex.getFieldValue(leadRecords[0].Id, null, 'LastName');
            System.assertEquals(null, result, 'Should return null for null sObjectName');
            Test.stopTest();
        }
    }

    private static List<Lead> getLeadRecord() {
        return [SELECT Id, LastName, Phone, CurrencyIsoCode FROM Lead LIMIT 1];
    }
}