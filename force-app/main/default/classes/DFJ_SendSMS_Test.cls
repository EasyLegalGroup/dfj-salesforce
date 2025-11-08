@IsTest
private class DFJ_SendSMS_Test {

    @IsTest
    static void send_FromNumber() {

        DFJ_SendSMS.SMSInput p = new DFJ_SendSMS.SMSInput();
        p.message          = 'Test message';
        p.toPhoneNumber    = '+1234567890';
        p.sendFromSenderId = false;
        p.fromNumber       = '+19876543210';

        Test.setMock(HttpCalloutMock.class,
                     new DFJ_SendSMS_MockUtility_Test());

        Test.startTest();
        DFJ_SendSMS.send(new List<DFJ_SendSMS.SMSInput>{ p });
        Test.stopTest();
    }
}