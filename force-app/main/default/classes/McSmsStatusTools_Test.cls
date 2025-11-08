@IsTest
private class McSmsStatusTools_Test {

    private class Mock implements System.HttpCalloutMock {
        public System.HttpResponse respond(System.HttpRequest req) {
            System.HttpResponse res = new System.HttpResponse();
            res.setHeader('Content-Type','application/json; charset=UTF-8');
            String ep = String.valueOf(req.getEndpoint());

            // mk-sent → SMSSent-like happy path
            if (ep.endsWith('/messaging/v1/sms/messages/mk-sent')) {
                res.setStatusCode(200);
                res.setBody('{"eventCategoryType":"TransactionalSendEvents.SMSSent","timestamp":"2025-09-09T08:00:00.000Z","info":{"to":"4542455150"}}');
                res.setStatus('OK');
                return res;
            }
            // mk-notsent → NotSent with statusCode 46
            if (ep.endsWith('/messaging/v1/sms/messages/mk-notsent')) {
                res.setStatusCode(200);
                res.setBody('{"eventCategoryType":"TransactionalSendEvents.SMSNotSent","statusCode":46,"statusMessage":"MessageRenderFailure","info":{"to":"+4542455150"}}');
                res.setStatus('OK');
                return res;
            }

            res.setStatusCode(404);
            res.setBody('{"message":"not found"}');
            res.setStatus('OK');
            return res;
        }
    }

    @IsTest
    static void test_poll_maps_fields_and_codes() {
        Test.setMock(System.HttpCalloutMock.class, new Mock());

        List<McSmsStatusTools.PollInput> ins = new List<McSmsStatusTools.PollInput>();
        McSmsStatusTools.PollInput a = new McSmsStatusTools.PollInput();
        a.messageKey = 'mk-sent';
        ins.add(a);

        McSmsStatusTools.PollInput b = new McSmsStatusTools.PollInput();
        b.messageKey = 'mk-notsent';
        ins.add(b);

        Test.startTest();
        List<McSmsStatusTools.PollOutput> out = McSmsStatusTools.poll(ins);
        Test.stopTest();

        System.assertEquals(2, out.size());

        // mk-sent assertions
        McSmsStatusTools.PollOutput po1 = out[0];
        System.assertEquals('mk-sent', po1.messageKey);
        System.assertEquals(200, po1.httpStatus);
        System.assertEquals('TransactionalSendEvents.SMSSent', po1.eventCategoryType);
        System.assertEquals('4542455150', po1.infoTo);
        System.assertNotEquals(null, po1.timestamp);

        // mk-notsent assertions (code 46 mapping)
        McSmsStatusTools.PollOutput po2 = out[1];
        System.assertEquals('mk-notsent', po2.messageKey);
        System.assertEquals(200, po2.httpStatus);
        System.assertEquals('TransactionalSendEvents.SMSNotSent', po2.eventCategoryType);
        System.assertEquals('46', po2.statusCode);
        System.assertEquals('MessageRenderFailure', po2.codeName, '46 should map to MessageRenderFailure');
        System.assert(po2.statusMessage != null);
    }
}