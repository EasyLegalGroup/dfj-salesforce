@IsTest
public class MarketingCloudSMSServiceTest {
    
    private class MockSMSResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message":"SMS Sent Successfully"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @IsTest
    static void testSendSingleSMS_Success() {
        Test.setMock(HttpCalloutMock.class, new MockSMSResponse());
        
        MarketingCloudSMSService.SMSWrapper smsData = new MarketingCloudSMSService.SMSWrapper();
        smsData.toNumber = '+4561555338';
        smsData.contactKey = 'Contact123';
        smsData.firstName = 'Test';
        smsData.messageBody = 'Hello, this is a test message!';
        smsData.messageKey = 'TestMsgKey';
        smsData.definitionKey = 'DefKey123';
        
        List<MarketingCloudSMSService.SMSWrapper> smsList = new List<MarketingCloudSMSService.SMSWrapper>{ smsData };
        
        Test.startTest();
        List<MarketingCloudSMSService.SMSResponseWrapper> responses = MarketingCloudSMSService.sendSingleSMS(smsList);
        Test.stopTest();
        
        System.assertNotEquals(null, responses);
        System.assertEquals(1, responses.size());
        System.assertEquals('200', responses[0].statusCode);
        System.assert(responses[0].responseBody.contains('SMS Sent Successfully'));
    }
}