@IsTest 
public class DFJ_SendSMS_From_SenderId_Test {
    @isTest
    private static void sendSMS_Test(){
        try{
        List<DFJ_SendSMS_From_SenderId.SMSInputParameter> smsInputParams = new List<DFJ_SendSMS_From_SenderId.SMSInputParameter>();
        DFJ_SendSMS_From_SenderId.SMSInputParameter inputParam = new DFJ_SendSMS_From_SenderId.SMSInputParameter();
        inputParam.message = 'Test Message';
        inputParam.toPhoneNumber = '+1234567890';
        smsInputParams.add(inputParam);
		
            // Mock the callout response
        Test.setMock(HttpCalloutMock.class, new DFJ_SendSMS_MockUtility_Test());

        // Test the sendSMS method
        Test.startTest();
        DFJ_SendSMS_From_SenderId.sendSMS(smsInputParams);
        Test.stopTest();
        }catch(exception ex){
            System.debug('error message--> '+ ex.getmessage()+ '--InLine --->'+ex.getlinenumber());
        }
    }
}