@IsTest
private class MC_InboundSMS_API_Handshake_Test {
    @IsTest static void handshake_empty_post_returns_200() {
        // No BYPASS_AUTH here; we want to ensure the handshake bypass works.
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/mc/inbound-sms';
        // No headers and empty body to simulate ENS registration probe
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, RestContext.response.responseBody.toString());
        System.assert(MC_InboundSMS_API.BYPASS_AUTH == false, 'Auth bypass flag should be irrelevant here');
    }
}