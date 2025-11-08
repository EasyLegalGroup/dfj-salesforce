@IsTest
private class McRestAndSmsTests {
    // Simple mock that handles the endpoints used in these tests
    private class DummyHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String url = req.getEndpoint() == null ? '' : req.getEndpoint();
            String method = req.getMethod();

            // 1) Token context sanity-check for GET helper
            if (url.endsWith('/platform/v1/tokenContext')) {
                res.setStatusCode(200);
                res.setBody('{"tenant":"ok"}');
                return res;
            }

            // 2) PATCH a definition (we just echo success)
            if (url.endsWith('/messaging/v1/sms/definitions/SMS_TRX_DK') && method == 'PATCH') {
                res.setStatusCode(200);
                res.setBody('{"definitionKey":"SMS_TRX_DK","status":"Active"}');
                return res;
            }

            // 3) GET a definition
            if (url.endsWith('/messaging/v1/sms/definitions/SMS_TRX_DK') && method == 'GET') {
                res.setStatusCode(200);
                res.setBody('{"definitionKey":"SMS_TRX_DK","status":"Active"}');
                return res;
            }

            // 4) Send message (recipients ARRAY version used by sendSms)
            if (url.endsWith('/messaging/v1/sms/messages') && method == 'POST') {
                String body = req.getBody();
                if (body != null && body.contains('"recipients"')) {
                    res.setStatusCode(202);
                    res.setBody('{"responses":[{"messageKey":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}]}');
                } else {
                    res.setStatusCode(400);
                    res.setBody('{"message":"missing recipients"}');
                }
                return res;
            }

            // 5) Send message with key in URL (used by sendSmsWithKey)
            if (url.contains('/messaging/v1/sms/messages/') && method == 'POST') {
                res.setStatusCode(202);
                res.setBody('{"responses":[{"messageKey":"mk"}]}');
                return res;
            }

            // 6) GET message status (encoded key)
            if (url.endsWith('/messaging/v1/sms/messages/mk%2Bspace%2Fplus') && method == 'GET') {
                res.setStatusCode(200);
                res.setBody('{"eventCategoryType":"TransactionalSendEvents.SMSQueued"}');
                return res;
            }

            // 7) GET message events (encoded key)
            if (url.endsWith('/messaging/v1/sms/messages/mk%2Bspace%2Fplus/events') && method == 'GET') {
                res.setStatusCode(200);
                res.setBody('[{"eventCategoryType":"TransactionalSendEvents.SMSQueued"}]');
                return res;
            }

            // default
            res.setStatusCode(404);
            res.setBody('{"message":"not found in test mock"}');
            return res;
        }
    }

    @IsTest
    static void testGetHelper() {
        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());
        McRestClient.Result r = McRestClient.get('/platform/v1/tokenContext');
        System.assertEquals(200, r.status);
        System.assert(r.body.contains('ok'));
    }

    @IsTest
    static void testPatchAndGetDefinition() {
        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());

        Test.startTest();
        McRestClient.Result patchRes = McRestClient.patch(
            '/messaging/v1/sms/definitions/SMS_TRX_DK',
            new Map<String,Object>{ 'status' => 'Active' }
        );
        McRestClient.Result getRes = McRestClient.getDefinition('SMS_TRX_DK');
        Test.stopTest();

        System.assertEquals(200, patchRes.status);
        System.assertEquals(200, getRes.status);
        System.assert(getRes.body.contains('"Active"'));
    }

    @IsTest
    static void testSendSms_arrayRecipients() {
        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());

        Map<String, Object> attrs = new Map<String, Object>{ 'FirstName' => 'Test' };
        Test.startTest();
        McRestClient.Result sendRes = McRestClient.sendSms('SMS_TRX_DK', '+4511122233', null, attrs);
        Test.stopTest();

        System.assertEquals(202, sendRes.status, 'Send should be 202 Accepted');
        System.assert(sendRes.body.contains('messageKey'), 'Body should include messageKey');
    }

    @IsTest
    static void test_send_with_key_and_get_with_encoding() {
        Test.setMock(System.HttpCalloutMock.class, new DummyHttpMock());

        Test.startTest();
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