@IsTest
private class MC_InboundSMS_API_Verify_Test {
    @IsTest static void verification_payload_is_captured_and_returns_200() {
        // Simulate ENS verification POST (no auth header)
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/mc/inbound-sms';
        req.requestBody = Blob.valueOf('{"callbackId":"cb-123","verificationKey":"vk-456"}');
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, RestContext.response.responseBody.toString());

        // Get the newest record (can't filter on long text fields)
        SMS__c v = [
            SELECT External_ID__c, Message__c, Raw_Response__c, CreatedDate
            FROM SMS__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('ENS Verification Payload', v.Message__c);
        System.assert(v.Raw_Response__c.contains('"callbackId":"cb-123"'));
        System.assert(v.Raw_Response__c.contains('"verificationKey":"vk-456"'));
    }

    @IsTest static void empty_post_handshake_returns_200() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/mc/inbound-sms';
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        MC_InboundSMS_API.handle();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String s = RestContext.response.responseBody == null ? '' : RestContext.response.responseBody.toString();
        Map<String,Object> resp = (Map<String,Object>) JSON.deserializeUntyped(s);
        System.assertEquals('handshake-ok', (String)resp.get('status'));
    }
}