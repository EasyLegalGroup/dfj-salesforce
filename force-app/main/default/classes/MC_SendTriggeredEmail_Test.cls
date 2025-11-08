@IsTest
private class MC_SendTriggeredEmail_Test {

    // --- Shared state for mocks (must be on a top-level type for 'static')
    private static Integer mockStatusCode;
    private static String  mockResponseBody;
    private static String  lastEndpoint;
    private static String  lastRequestBody;

    // --- Success/echo mock
    private class MC_Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            MC_SendTriggeredEmail_Test.lastEndpoint    = req.getEndpoint();
            MC_SendTriggeredEmail_Test.lastRequestBody = req.getBody();

            HttpResponse res = new HttpResponse();
            res.setStatusCode(MC_SendTriggeredEmail_Test.mockStatusCode);
            // setStatus is the text (e.g., "Accepted", "Bad Request") used by resp.getStatus()
            if (MC_SendTriggeredEmail_Test.mockStatusCode == 202) res.setStatus('Accepted');
            if (MC_SendTriggeredEmail_Test.mockStatusCode == 400) res.setStatus('Bad Request');

            res.setBody(MC_SendTriggeredEmail_Test.mockResponseBody);
            return res;
        }
    }

    // --- Throwing mock
    private class MC_Mock_Throws implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new System.CalloutException('Simulated network error');
        }
    }

    @IsTest
    static void testSuccess_SYNC_and_Payload() {
        Contact c = new Contact(LastName='Tester', Email='anna@example.com');
        insert c;

        mockStatusCode   = 202;
        mockResponseBody = '{"requestId":"REQ-OK-1"}';

        Test.setMock(HttpCalloutMock.class, new MC_Mock());
        Test.startTest();
        MC_SendTriggeredEmail.Request r = new MC_SendTriggeredEmail.Request();
        r.definitionKey = 'LEC_REM_28Days_DK';
        r.subscriberKey = c.Id;
        r.emailAddress  = c.Email;
        r.firstName     = 'Anna';
        r.lastName      = '';                  // omitted
        r.phone         = null;                // omitted
        r.eventDate     = '2025-09-14';
        r.eventTime     = '18:00';
        r.lecturerName  = 'Adv. Mads Hansen';
        r.hostAddressStreet  = 'Nørregade 10';
        r.hostAddressZipCode = '2100';
        r.hostAddressCity    = 'København';
        r.bookingId     = 'B-12345';
        r.venueName     = 'DFJ HQ';
        r.useSync       = true;

        List<MC_SendTriggeredEmail.Result> out =
            MC_SendTriggeredEmail.send(new List<MC_SendTriggeredEmail.Request>{ r });
        Test.stopTest();

        System.assertEquals(1, out.size());
        System.assertEquals(true, out[0].success);
        System.assertEquals(202, out[0].statusCode);
        System.assertEquals('REQ-OK-1', out[0].requestId);

        System.assert(lastEndpoint.startsWith('callout:MC_REST/messaging/v1/messageDefinitionSends/key:'));
        System.assert(lastEndpoint.endsWith('/send'));

        Map<String,Object> payload =
            (Map<String,Object>) JSON.deserializeUntyped(lastRequestBody);
        Map<String,Object> to = (Map<String,Object>) payload.get('To');
        System.assertEquals('anna@example.com', (String)to.get('Address'));
        System.assertEquals((String)c.Id, (String)to.get('SubscriberKey'));

        Map<String,Object> subs =
            (Map<String,Object>) ((Map<String,Object>)to.get('ContactAttributes')).get('SubscriberAttributes');

        System.assertEquals('anna@example.com', (String)subs.get('Email Address'));
        System.assertEquals('Anna', (String)subs.get('First Name'));
        System.assertEquals('2025-09-14', (String)subs.get('EventDate'));
        System.assertEquals('18:00', (String)subs.get('EventTime'));
        System.assertEquals('Adv. Mads Hansen', (String)subs.get('LecturerName'));
        System.assertEquals('Nørregade 10', (String)subs.get('HostAddressStreet'));
        System.assertEquals('2100', (String)subs.get('HostAddressZipCode'));
        System.assertEquals('København', (String)subs.get('HostAddressCity'));
        System.assertEquals('B-12345', (String)subs.get('BookingId'));
        System.assertEquals('DFJ HQ', (String)subs.get('VenueName'));

        System.assertEquals(false, subs.containsKey('Last Name'));
        System.assertEquals(false, subs.containsKey('Phone'));

        System.assertEquals('SYNC', (String)((Map<String,Object>)payload.get('Options')).get('RequestType'));
    }

    @IsTest
    static void testAsync_RequestType_AND_Minimal() {
        Lead l = new Lead(LastName='Lead', Company='Acme', Email='lead@example.com');
        insert l;

        mockStatusCode   = 202;
        mockResponseBody = '{"requestId":"REQ-OK-ASYNC"}';

        Test.setMock(HttpCalloutMock.class, new MC_Mock());
        Test.startTest();
        MC_SendTriggeredEmail.Request r = new MC_SendTriggeredEmail.Request();
        r.definitionKey = 'LEC_REM_28Days_DK';
        r.subscriberKey = l.Id;
        r.emailAddress  = l.Email;
        r.useSync       = false; // ASYNC

        List<MC_SendTriggeredEmail.Result> out =
            MC_SendTriggeredEmail.send(new List<MC_SendTriggeredEmail.Request>{ r });
        Test.stopTest();

        System.assertEquals(true, out[0].success);
        System.assertEquals('REQ-OK-ASYNC', out[0].requestId);

        Map<String,Object> payload =
            (Map<String,Object>) JSON.deserializeUntyped(lastRequestBody);
        System.assertEquals('ASYNC',
            (String)((Map<String,Object>)payload.get('Options')).get('RequestType'));
    }

    @IsTest
    static void testFailure_400() {
        mockStatusCode   = 400;
        mockResponseBody = '{"message":"Bad Request","errorcode":12345}';

        Test.setMock(HttpCalloutMock.class, new MC_Mock());
        Test.startTest();
        MC_SendTriggeredEmail.Request r = new MC_SendTriggeredEmail.Request();
        r.definitionKey = 'LEC_REM_28Days_DK';
        r.subscriberKey = '003000000000AAA';
        r.emailAddress  = 'bad@example.com';
        r.useSync       = true;

        List<MC_SendTriggeredEmail.Result> out =
            MC_SendTriggeredEmail.send(new List<MC_SendTriggeredEmail.Request>{ r });
        Test.stopTest();

        System.assertEquals(false, out[0].success);
        System.assertEquals(400, out[0].statusCode);
        // Error message uses resp.getStatus() (text), not the numeric code
        System.assert(out[0].errorMessage != null && out[0].errorMessage.contains('Bad Request'),
                      'errorMessage should include the HTTP status text');
    }

    @IsTest
    static void testExceptionBranch() {
        Test.setMock(HttpCalloutMock.class, new MC_Mock_Throws());
        Test.startTest();
        MC_SendTriggeredEmail.Request r = new MC_SendTriggeredEmail.Request();
        r.definitionKey = 'LEC REM 28 Days DK'; // covers urlEncode
        r.subscriberKey = '005000000000AAA';
        r.emailAddress  = 'oops@example.com';

        List<MC_SendTriggeredEmail.Result> out =
            MC_SendTriggeredEmail.send(new List<MC_SendTriggeredEmail.Request>{ r });
        Test.stopTest();

        System.assertEquals(false, out[0].success);
        System.assert(out[0].errorMessage != null &&
                      out[0].errorMessage.startsWith('Exception:'));
    }
}