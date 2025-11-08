@RestResource(urlMapping='/webhook/*')
global class GoogleDriveWebhookHandler {
    @HttpPost
    global static void handleWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Blob body = req.requestBody;
        String requestString = body.toString();
        String jsonString = req.requestBody.toString();
        GoogleEventHandler.MainLogic();
        res.responseBody = Blob.valueOf('Notification Recieved.');
        res.statusCode = 200;
        
    }
}