@IsTest
private class GoogleDriveWebhookHandlerTest {
    @IsTest
    static void testHandleWebhook() {
        // Set up the test REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/webhook/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"test":"payload"}');
        
        // Set the mock context
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the webhook handler
        Test.startTest();
        GoogleDriveWebhookHandler.handleWebhook();
        Test.stopTest();
     
    }
}