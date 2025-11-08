@IsTest
private class McRestClient_Test {

    // Captured request info from the mock so we can assert in tests
    private static String lastReqEndpoint;
    private static String lastReqMethod;
    private static String lastReqBody;

    // Simple router mock for all MC endpoints we hit in tests
    private class Mock implements System.HttpCalloutMock {
        public System.HttpResponse respond(System.HttpRequest req) {
            lastReqEndpoint = req.getEndpoint();
            lastReqMethod   = req.getMethod();
            lastReqBody     = req.getBody();

            System.HttpResponse res = new System.HttpResponse();
            res.setHeader('Content-Type', 'application/json; charset=UTF-8');

            String ep = String.valueOf(req.getEndpoint());

            if (ep.contains('/messaging/v1/sms/messages') && req.getMethod() == 'POST') {
                // simulate send response
                res.setStatusCode(202);
                res.setBody('{"requestId":"r1","errorcode":0,"responses":[{"messageKey":"m123"}]}');
            } else if (ep.endsWith('/messaging/v1/sms/messages/m123') && req.getMethod() == 'GET') {
                // simulate message status
                res.setStatusCode(200);
                res.setBody('{"requestId":"r2","eventCategoryType":"TransactionalSendEvents.SMSQueued","timestamp":"2025-09-04T06:42:25.7651"}');
            } else if (ep.endsWith('/messaging/v1/sms/messages/m123/events') && req.getMethod() == 'GET') {
                // simulate events list
                res.setStatusCode(200);
                res.setBody('[{"eventCategoryType":"TransactionalSendEvents.SMSQueued"}]');
            } else if (ep.endsWith('/messaging/v1/sms/definitions/SMS_TRX_DK') && req.getMethod() == 'GET') {
                // simulate definition fetch
                res.setStatusCode(200);
                res.setBody('{"definitionKey":"SMS_TRX_DK","status":"Active"}');
            } else if (ep.endsWith('/messaging/v1/sms/definitions/SMS_TRX_DK') && req.getMethod() == 'PATCH') {
                // simulate definition update
                res.setStatusCode(200);
                res.setBody('{"definitionKey":"SMS_TRX_DK","status":"Active"}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"message":"not found"}');
            }

            res.setStatus('OK');
            return res;
        }
    }

    /** Mock specifically for URL-encoded messageKey tests */
    private class MockUrl implements System.HttpCalloutMock {
        public System.HttpResponse respond(System.HttpRequest req) {
            lastReqEndpoint = req.getEndpoint();
            lastReqMethod   = req.getMethod();
            lastReqBody     = req.getBody();

            System.HttpResponse res = new System.HttpResponse();
            res.setHeader('Content-Type','application/json; charset=UTF-8');
            String ep = String.valueOf(req.getEndpoint());
            String m  = req.getMethod();

            if (m == 'POST' && ep.contains('/messaging/v1/sms/messages/')) {
                res.setStatusCode(202);
                res.setBody('{"requestId":"r1","responses":[{"messageKey":"mk"}]}');
            } else if (m == 'GET' && ep.endsWith('/messaging/v1/sms/messages/mk%2Bspace%2Fplus')) {
                res.setStatusCode(200);
                res.setBody('{"eventCategoryType":"TransactionalSendEvents.SMSQueued"}');
            } else if (m == 'GET' && ep.endsWith('/messaging/v1/sms/messages/mk%2Bspace%2Fplus/events')) {
                res.setStatusCode(200);
                res.setBody('[{"eventCategoryType":"TransactionalSendEvents.SMSQueued"}]');
            } else {
                res.setStatusCode(404);
                res.setBody('{"message":"not found"}');
            }
            res.setStatus('OK');
            return res;
        }
    }

    @IsTest static void testSendSms_success() {
        Test.setMock(System.HttpCalloutMock.class, new Mock());

        Test.startTest();
        McRestClient.Result r = McRestClient.sendSms(
            'SMS_TRX_DK',
            '+4512345678',
            null, // should default to MSISDN
            new Map<String,Object>{ 'FirstName' => 'John' }
        );
        Test.stopTest();

        System.assertEquals(202, r.status, 'Send should return 202');
        System.assert(r.body.contains('"messageKey"'), 'Response should include messageKey');
        System.assertEquals('POST', lastReqMethod);
        System.assert(lastReqEndpoint.startsWith('callout:'), 'Should use Named Credential endpoint');

        // Verify payload and defaulted contactKey
        Map<String,Object> payload = (Map<String,Object>) JSON.deserializeUntyped(lastReqBody);
        System.assertEquals('SMS_TRX_DK', (String)payload.get('definitionKey'));
        List<Object> recips = (List<Object>) payload.get('recipients');
        Map<String,Object> first = (Map<String,Object>) recips[0];
        System.assertEquals('+4512345678', (String) first.get('contactKey'),
            'contactKey should default to the MSISDN when null');
    }

    @IsTest static void testGetMessage_success() {
        Test.setMock(System.HttpCalloutMock.class, new Mock());

        Test.startTest();
        McRestClient.Result r = McRestClient.getMessage('m123');
        Test.stopTest();

        System.assertEquals(200, r.status);
        System.assert(r.body.contains('TransactionalSendEvents.SMSQueued'));
        System.assertEquals('GET', lastReqMethod);
        System.assert(lastReqEndpoint.contains('/messages/m123'));
    }

    @IsTest static void testGetMessageEvents_success() {
        Test.setMock(System.HttpCalloutMock.class, new Mock());

        Test.startTest();
        McRestClient.Result r = McRestClient.getMessageEvents('m123');
        Test.stopTest();

        System.assertEquals(200, r.status);
        System.assert(r.body.contains('SMSQueued'));
        System.assert(lastReqEndpoint.endsWith('/messages/m123/events'));
    }

    @IsTest static void testGetAndPatchDefinition_success() {
        Test.setMock(System.HttpCalloutMock.class, new Mock());

        Test.startTest();
        McRestClient.Result getRes = McRestClient.getDefinition('SMS_TRX_DK');
        McRestClient.Result patchRes = McRestClient.patch(
            '/messaging/v1/sms/definitions/SMS_TRX_DK',
            new Map<String,Object>{ 'status' => 'Active' }
        );
        Test.stopTest();

        System.assertEquals(200, getRes.status);
        System.assertEquals(200, patchRes.status);
        System.assertEquals('PATCH', lastReqMethod);
        System.assert(lastReqBody.contains('"Active"'));
    }

    @IsTest static void testPostWrapperDirect() {
        Test.setMock(System.HttpCalloutMock.class, new Mock());

        Test.startTest();
        McRestClient.Result r = McRestClient.post(
            '/messaging/v1/sms/messages',
            new Map<String,Object>{
                'definitionKey' => 'SMS_TRX_DK',
                'recipients'    => new List<Object>()
            }
        );
        Test.stopTest();

        System.assertEquals(202, r.status);
        System.assertEquals('POST', lastReqMethod);
    }

    @IsTest
    static void test_send_with_key_and_get_with_encoding() {
        Test.setMock(System.HttpCalloutMock.class, new MockUrl());

        Test.startTest();
        // Send with a key that needs encoding
        McRestClient.Result sendRes = McRestClient.sendSmsWithKey(
            'SMS_TRX_DK', '+4511122233', '+4511122233',
            new Map<String,Object>{ 'FirstName' => 'John' }, 'mk+space/plus'
        );
        McRestClient.Result getRes  = McRestClient.getMessage('mk+space/plus');
        McRestClient.Result evtRes  = McRestClient.getMessageEvents('mk+space/plus');
        Test.stopTest();

        System.assertEquals(202, sendRes.status);
        System.assertEquals(200, getRes.status);
        System.assertEquals(200, evtRes.status);
    }
}