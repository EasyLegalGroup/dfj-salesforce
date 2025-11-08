@IsTest
private class McSmsTransactionalBulk_Test {

    // Basic mock: requires FromName in the payload (alpha behavior)
    private class Mock implements System.HttpCalloutMock {
        public System.HttpResponse respond(System.HttpRequest req) {
            System.HttpResponse res = new System.HttpResponse();
            res.setHeader('Content-Type','application/json; charset=UTF-8');

            String body = req.getBody();

            if (req.getMethod() == 'POST' && String.valueOf(req.getEndpoint()).contains('/messaging/v1/sms/messages/')) {
                // FIX: Match normal JSON once-quoted, not double-escaped
                System.assert(body != null && body.contains('"FromName":"FamJurist"'),
                    'Alpha body should include FromName default "FamJurist"');
                res.setStatusCode(202);
                res.setBody('{"responses":[{"messageKey":"mk"}]}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"message":"not found"}');
            }
            res.setStatus('OK');
            return res;
        }
    }

    @IsTest
    static void test_bulk_send_splits_and_queues_alpha() {
        Test.setMock(System.HttpCalloutMock.class, new Mock());

        // Reduce max per tx to 2 to exercise queueing
        McSmsTransactionalBulk.MAX_PER_TX_OVERRIDE = 2;
        McSmsTransactionalBulk.BULKQUEUE_MAX_PER_EXECUTE_OVERRIDE = 2;

        // Disable Queueable chaining inside tests to avoid stack depth recursion
        McSmsTransactionalBulk.DISABLE_CHAINING_IN_TESTS = true;

        List<McSmsTransactionalBulk.SMSWrapper> many = new List<McSmsTransactionalBulk.SMSWrapper>();
        for (Integer i = 0; i < 5; i++) {
            McSmsTransactionalBulk.SMSWrapper w = new McSmsTransactionalBulk.SMSWrapper();
            w.to = '+454200000' + String.valueOf(i);
            w.contactKey = 'CK' + i;
            w.definitionKey = 'SMS_TRX_DK_ALPHA'; // use alpha so FromName is expected
            // Intentionally do NOT pass FromName; code should inject it for ALPHA.
            many.add(w);
        }

        Test.startTest();
        List<McSmsTransactionalBulk.SendResult> out = McSmsTransactionalBulk.bulkSend(many);
        Test.stopTest();

        Integer nowCount = 0, queuedCount = 0;
        for (McSmsTransactionalBulk.SendResult r : out) {
            if (r.asyncQueued == true) queuedCount++;
            else if (r.httpStatus == 202) nowCount++;
        }
        System.assertEquals(2, nowCount, 'Should process up to MAX synchronously');
        System.assertEquals(3, queuedCount, 'Remaining should be queued');

        // Tidy test seams
        McSmsTransactionalBulk.MAX_PER_TX_OVERRIDE = null;
        McSmsTransactionalBulk.BULKQUEUE_MAX_PER_EXECUTE_OVERRIDE = null;
        McSmsTransactionalBulk.DISABLE_CHAINING_IN_TESTS = false;
    }
}