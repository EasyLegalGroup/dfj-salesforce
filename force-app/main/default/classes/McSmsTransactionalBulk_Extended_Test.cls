@IsTest
private class McSmsTransactionalBulk_Extended_Test {

    // Mock that FAILS if FromName is present (numeric) and asserts prefixes
    private class MockNumeric implements HttpCalloutMock {
        private final String expectPrefix;
        MockNumeric(String p){ expectPrefix = p; }
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            if (req.getMethod()=='POST' && String.valueOf(req.getEndpoint()).contains('/messaging/v1/sms/messages/')) {
                String body = req.getBody();
                System.assert(body.contains('"to":"'+ expectPrefix), 'to must start with ' + expectPrefix);
                System.assert(!body.contains('"FromName"'), 'Numeric path must NOT include FromName');
                res.setStatusCode(202);
                res.setBody('{"responses":[{"messageKey":"mk"}]}');
                return res;
            }
            res.setStatusCode(404); res.setBody('{"message":"nf"}');
            return res;
        }
    }

    // Mock that REQUIRES FromName (alpha)
    private class MockAlpha implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            if (req.getMethod()=='POST' && String.valueOf(req.getEndpoint()).contains('/messaging/v1/sms/messages/')) {
                String body = req.getBody();
                System.assert(body.contains('"FromName"'), 'Alpha path must include FromName');
                System.assert(body.contains('"to":"45'), 'DK alpha to must start with 45');
                res.setStatusCode(202);
                res.setBody('{"responses":[{"messageKey":"mk"}]}');
                return res;
            }
            res.setStatusCode(404); res.setBody('{"message":"nf"}');
            return res;
        }
    }

    @IsTest static void test_dk_numeric_no_fromname() {
        Test.setMock(HttpCalloutMock.class, new MockNumeric('45'));
        McSmsTransactionalBulk.SMSWrapper w = new McSmsTransactionalBulk.SMSWrapper();
        w.to = '+45 42 45 51 50';
        w.contactKey = 'CK1';
        w.definitionKey = 'SMS_TRX_DK_CODE';
        List<McSmsTransactionalBulk.SendResult> out = McSmsTransactionalBulk.bulkSend(new List<McSmsTransactionalBulk.SMSWrapper>{ w });
        System.assertEquals(202, out[0].httpStatus);
        System.assert(out[0].normalizedTo.startsWith('45'));
    }

    @IsTest static void test_dk_alpha_requires_fromname() {
        Test.setMock(HttpCalloutMock.class, new MockAlpha());
        McSmsTransactionalBulk.SMSWrapper w = new McSmsTransactionalBulk.SMSWrapper();
        w.to = '42455150'; // 8 digits -> 45+…
        w.contactKey = 'CK2';
        w.definitionKey = 'SMS_TRX_DK_ALPHA';
        // omit attributes to test default injection
        List<McSmsTransactionalBulk.SendResult> out = McSmsTransactionalBulk.bulkSend(new List<McSmsTransactionalBulk.SMSWrapper>{ w });
        System.assertEquals(202, out[0].httpStatus);
    }

    @IsTest static void test_se_numeric_local_normalizes_and_no_fromname() {
        Test.setMock(HttpCalloutMock.class, new MockNumeric('46'));
        McSmsTransactionalBulk.SMSWrapper w = new McSmsTransactionalBulk.SMSWrapper();
        w.to = '070 123 45 67'; // local Swedish format
        w.contactKey = 'CK3';
        w.definitionKey = 'SMS_TRX_SE_CODE';
        List<McSmsTransactionalBulk.SendResult> out = McSmsTransactionalBulk.bulkSend(new List<McSmsTransactionalBulk.SMSWrapper>{ w });
        System.assertEquals(202, out[0].httpStatus);
        System.assert(out[0].normalizedTo.startsWith('46'));
    }

    @IsTest static void test_numeric_strips_fromname_if_provided() {
        Test.setMock(HttpCalloutMock.class, new MockNumeric('45'));
        // Caller accidentally passes FromName on numeric; class must strip it.
        McSmsTransactionalBulk.AttributeKV kv = new McSmsTransactionalBulk.AttributeKV();
        kv.name = 'FromName'; kv.value = 'ShouldBeStripped';
        McSmsTransactionalBulk.SMSWrapper w = new McSmsTransactionalBulk.SMSWrapper();
        w.to = '+45 42 45 51 50';
        w.contactKey = 'CK4';
        w.definitionKey = 'SMS_TRX_DK_CODE';
        w.attributes = new List<McSmsTransactionalBulk.AttributeKV>{ kv };

        List<McSmsTransactionalBulk.SendResult> out = McSmsTransactionalBulk.bulkSend(new List<McSmsTransactionalBulk.SMSWrapper>{ w });
        System.assertEquals(202, out[0].httpStatus);
        System.assert(out[0].normalizedTo.startsWith('45'));
    }
}