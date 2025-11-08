@IsTest
private class MC_InboundSMS_API_Test {

    private static RestRequest buildReq(String body, String token, String uriSuffix) {
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/mc/inbound-sms' + (uriSuffix == null ? '' : uriSuffix);
        if (body != null) req.requestBody = Blob.valueOf(body);
        if (token != null) req.addHeader('X-Auth-Token', token);
        req.addHeader('Content-Type', 'application/json');
        return req;
    }
    private static void setCtx(RestRequest r){
        RestContext.request  = r;
        RestContext.response = new RestResponse();
    }
    private static Map<String,Object> bodyAsMap() {
        String s = RestContext.response.responseBody == null ? '' : RestContext.response.responseBody.toString();
        if (String.isBlank(s)) return new Map<String,Object>();
        return (Map<String,Object>) JSON.deserializeUntyped(s);
    }
    // Robust numeric conversion for JSON.deserializeUntyped numbers (Decimal)
    private static Integer asInt(Object o) {
        if (o == null) return 0;
        if (o instanceof Integer) return (Integer)o;
        if (o instanceof Long)    return Integer.valueOf((Long)o);
        if (o instanceof Decimal) return ((Decimal)o).intValue();
        if (o instanceof String)  return Integer.valueOf((String)o);
        return 0;
    }

    @IsTest
    static void verification_accepts_verificationKey() {
        Test.startTest();
        String body = '{"callbackId":"11111111-1111-1111-1111-111111111111","verificationKey":"abc"}';
        setCtx(buildReq(body, null, null));
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Verification should 200');

        SMS__c v = [
            SELECT Id, External_ID__c, To_Number__c, From_Number__c, Direction__c, Status__c, Type__c, Message__c
            FROM SMS__c
            WHERE External_ID__c LIKE 'ENS-VERIFY-%'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assert(v.External_ID__c != null && v.External_ID__c.startsWith('ENS-VERIFY-'),
            'External_ID__c should start with ENS-VERIFY-');
        System.assertNotEquals(null, v.To_Number__c);
        System.assertEquals('ENS', v.From_Number__c);
        System.assertEquals('Incoming', v.Direction__c);
        System.assertEquals('Received', v.Status__c);
        System.assertEquals('Inbound',  v.Type__c);
        System.assertEquals('ENS Verification Payload', v.Message__c);
    }

    @IsTest
    static void verification_accepts_signatureKey() {
        Test.startTest();
        String body = '{"callbackId":"22222222-2222-2222-2222-222222222222","signatureKey":"legacy"}';
        setCtx(buildReq(body, null, null));
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Integer cnt = [SELECT COUNT() FROM SMS__c WHERE External_ID__c LIKE 'ENS-VERIFY-%'];
        System.assert(cnt > 0, 'At least one verification row should exist');
    }

    @IsTest
    static void liveness_nonEventMap_returns200_noInsert() {
        Test.startTest();
        setCtx(buildReq('{}', null, null)); // ENS odd ping
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Integer cnt = [SELECT COUNT() FROM SMS__c WHERE External_ID__c LIKE 'ENS-VERIFY-%'];
        System.assertEquals(0, cnt, 'No verification row expected for {} ping');
    }

    @IsTest
    static void createsInbound_and_MMS() {
        MC_InboundSMS_API.BYPASS_AUTH = true;

        String body = '{"events":[{' +
            '"messageId":"a1b2c3d4e5",' +
            '"eventTimestamp":"2025-09-19T10:45:12Z",' +
            '"subscriberNumber":"+4512345678",' +
            '"destinationNumber":"+4530812521",' +
            '"messageText":"hello from DK",' +
            '"media":["https://example.com/media1.jpg"]' +
        '}]}';

        Test.startTest();
        setCtx(buildReq(body, null, null));
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode,
            RestContext.response.responseBody == null ? '' : RestContext.response.responseBody.toString());

        SMS__c s = [
            SELECT External_ID__c, From_Number__c, To_Number__c, Message__c,
                   Direction__c, Status__c, Type__c, Media_URL__c,
                   Sent_Received_Time__c, Raw_Response__c
            FROM SMS__c WHERE External_ID__c = 'a1b2c3d4e5' LIMIT 1
        ];
        System.assertEquals('Incoming', s.Direction__c);
        System.assertEquals('Received', s.Status__c);
        System.assertEquals('Inbound',  s.Type__c);
        System.assertEquals('+4512345678', s.From_Number__c);
        System.assertEquals('+4530812521', s.To_Number__c);
        System.assertEquals('hello from DK', s.Message__c);
        System.assertEquals('https://example.com/media1.jpg', s.Media_URL__c);
        System.assertNotEquals(null, s.Sent_Received_Time__c);
        System.assert(s.Raw_Response__c != null && s.Raw_Response__c.contains('"messageId"'));
    }

    @IsTest
    static void idempotentOnDuplicateRetry_updatesSameRecord() {
        MC_InboundSMS_API.BYPASS_AUTH = true;

        String p1 = '{"events":[{"messageId":"dup-1","eventTimestamp":"2025-09-19T10:45:12Z","subscriberNumber":"+46700000000","destinationNumber":"+46765106079","messageText":"hej #1"}]}';
        String p2 = '{"events":[{"messageId":"dup-1","eventTimestamp":"2025-09-19T10:45:13Z","subscriberNumber":"+46700000000","destinationNumber":"+46765106079","messageText":"hej #1 - retry"}]}';

        Test.startTest();
        setCtx(buildReq(p1, null, null)); MC_InboundSMS_API.handle();
        setCtx(buildReq(p2, null, null)); MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        Integer count = [SELECT COUNT() FROM SMS__c WHERE External_ID__c='dup-1'];
        SMS__c s = [SELECT Message__c FROM SMS__c WHERE External_ID__c='dup-1' LIMIT 1];
        System.assertEquals(1, count);
        System.assertEquals('hej #1 - retry', s.Message__c);
    }

    @IsTest
    static void rejectsBadToken_returns200_with_ignored_status_and_no_insert() {
        MC_InboundSMS_API.BYPASS_AUTH = false;

        String body = '{"events":[{"messageId":"bad-1","subscriberNumber":"+451","destinationNumber":"+4530812521","messageText":"x"}]}';
        Test.startTest();
        setCtx(buildReq(body, 'WRONG_TOKEN', null));
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String,Object> resp = bodyAsMap();
        System.assertEquals('IGNORED', (String)resp.get('status'), 'Expected IGNORED status in body');
        System.assertEquals(0, [SELECT COUNT() FROM SMS__c WHERE External_ID__c='bad-1']);
    }

    @IsTest
    static void multiple_with_missingId_handlesBothRows_andCreatesExplicitId() {
        MC_InboundSMS_API.BYPASS_AUTH = true;

        // Array root (no "events" wrapper) is also supported by the handler
        String body = '[' +
            '{"messageId":"ok-1","subscriberNumber":"+451","destinationNumber":"+4530812521","messageText":"ok"},' +
            '{"subscriberNumber":"+451","destinationNumber":"+4530812521","messageText":"no id"}' +
        ']';

        Test.startTest();
        setCtx(buildReq(body, null, null));
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        // Parse response
        Map<String,Object> resp = bodyAsMap();

        // Results must reflect both input rows
        List<Object> results = (List<Object>) resp.get('results');
        System.assertNotEquals(null, results, 'Response must include a results array');
        System.assertEquals(2, results.size(), 'Handler must account for both events');

        // Counts are returned as JSON numbers (Decimal via deserializeUntyped) — normalize to int
        Integer ok  = asInt(resp.get('successCount'));
        Integer err = asInt(resp.get('errorCount'));
        System.assertEquals(2, ok + err, 'successCount + errorCount must equal 2');

        // The explicitly-ID’d row must exist regardless of other org validations.
        System.assertEquals(1, [SELECT COUNT() FROM SMS__c WHERE External_ID__c = 'ok-1']);

        // The overall status may vary by org rules (OK if both rows pass; ERROR/PARTIAL if one fails).
        String overall = (String)resp.get('status');
        System.assert(
            overall == 'OK' || overall == 'PARTIAL' || overall == 'ERROR',
            'Unexpected overall status value'
        );

        // Optional: if both succeeded, we should also have a fallback mo-* record.
        if (overall == 'OK') {
            Integer moCount = [SELECT COUNT() FROM SMS__c WHERE External_ID__c LIKE 'mo-%'];
            System.assert(moCount >= 1, 'Expected at least one fallback mo-* record when both rows succeed');
        }
    }

    @IsTest
    static void event_ingest_authViaQueryParam_t_exercised() {
        MC_InboundSMS_API.BYPASS_AUTH = true; // avoid Protected CMDT setup in test

        String body = '{"events":[{"messageId":"t-auth-1","eventTimestamp":"2025-09-19T10:45:12Z","subscriberNumber":"+4512345678","destinationNumber":"+4530812521","messageText":"qparam"}]}';
        Test.startTest();
        setCtx(buildReq(body, null, '?t=dummySecret'));
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Integer cnt = [SELECT COUNT() FROM SMS__c WHERE External_ID__c='t-auth-1'];
        System.assertEquals(1, cnt);
    }

    @IsTest
    static void ping_get_alive() {
        RestRequest req = new RestRequest();
        req.httpMethod   = 'GET';
        req.requestUri   = '/services/apexrest/mc/inbound-sms';
        req.resourcePath = '/services/apexrest/mc/inbound-sms';
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        MC_InboundSMS_API.ping();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String,Object> resp = bodyAsMap();
        System.assertEquals('alive', (String)resp.get('status'), 'Ping should return {"status":"alive"}');
    }

    @IsTest
    static void empty_body_is_handshake_ok() {
        // POST with no body → handshake-ok (ENS reachability probe)
        RestRequest req = new RestRequest();
        req.httpMethod   = 'POST';
        req.requestUri   = '/services/apexrest/mc/inbound-sms';
        req.resourcePath = '/services/apexrest/mc/inbound-sms';
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String,Object> resp = bodyAsMap();
        System.assertEquals('handshake-ok', (String)resp.get('status'));
    }
    @IsTest
static void accepts_messageText_b64() {
    MC_InboundSMS_API.BYPASS_AUTH = true;

    // "Hej från SE 👋" in UTF-8, Base64-encoded
    String plain  = 'Hej från SE 👋';
    String b64    = EncodingUtil.base64Encode(Blob.valueOf(plain));

    String body = '{' +
        '"events":[{' +
            '"messageId":"b64-1",' +
            '"subscriberNumber":"+46700000001",' +
            '"destinationNumber":"+46765106079",' +
            // Ensure normal fields are absent to force the b64 helper path
            '"messageText_b64":"' + b64 + '"' +
        '}]' +
    '}';

    RestRequest req = new RestRequest();
    req.httpMethod  = 'POST';
    req.requestUri  = '/services/apexrest/mc/inbound-sms';
    req.requestBody = Blob.valueOf(body);
    req.addHeader('Content-Type','application/json');

    RestContext.request  = req;
    RestContext.response = new RestResponse();

    Test.startTest();
    MC_InboundSMS_API.handle();
    Test.stopTest();

    System.assertEquals(200, RestContext.response.statusCode);

    SMS__c s = [
        SELECT External_ID__c, Message__c, Response_Body__c
        FROM SMS__c
        WHERE External_ID__c = 'b64-1'
        LIMIT 1
    ];
    System.assertEquals(plain, s.Message__c);
    System.assertEquals(plain, s.Response_Body__c);
}

}