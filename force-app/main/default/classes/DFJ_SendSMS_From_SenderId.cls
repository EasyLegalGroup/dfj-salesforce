public class DFJ_SendSMS_From_SenderId {
    @InvocableMethod(label='Send SMS from SenderId' )
    public static void sendSMS(List<SMSInputParameter> smsInputParams) {
        try{
            
            String message = smsInputParams[0].message;
            String toPhoneNumber = smsInputParams[0].toPhoneNumber;  
            makeHttpCallout(toPhoneNumber, message);
            
        }catch(Exception ex){
            System.debug('Message code' + ex.getMessage() +' in line number-->'+ex.getLineNumber());
            // DFJ_ErrorLogController.addErrorLogs('', 'Sending Sms from sender Id', ex.getMessage(), 'Error', 'DFJ_SendSMS_From_SenderId.sendSMS', '', String.valueOf(ex.getLineNumber()));
        }      
        
    }
    @future(callout=true)
    public static void makeHttpCallout(String toPhoneNumber, String message) {
        try {
            Send_SMS_From_SenderId__mdt getSenderdetails = Send_SMS_From_SenderId__mdt.getInstance('Din_Familie_Jurist');
            if(getSenderdetails!=null){
                String accountSid = getSenderdetails.Account_SID__c;
                String token = getSenderdetails.Auth_Token__c;
                String senderId = getSenderdetails.Alphanumeric_Sender_ID__c;
                String endPoint = 'https://api.twilio.com/2010-04-01/Accounts/'+accountSid+'/Messages';
                Blob creds = Blob.valueOf(accountSid+':' +token);
                HttpRequest req = new HttpRequest();
                Http http = new Http();
                HTTPResponse res = new HTTPResponse();
                req.setEndpoint(endPoint);
                req.setMethod('POST');
                String VERSION  = '3.2.0';
                req.setHeader('X-Twilio-Client', 'salesforce-' + VERSION);
                req.setHeader('User-Agent', 'twilio-salesforce/' + VERSION);
                req.setHeader('Accept', 'application/json');
                req.setHeader('Accept-Charset', 'utf-8');
                req.setHeader('Authorization', 'Basic '+EncodingUtil.base64Encode(creds));
                req.setBody('To=' + EncodingUtil.urlEncode(toPhoneNumber, 'UTF-8') + '&From=' + EncodingUtil.urlEncode(senderId,'UTF-8') + '&Body=' + message);
                res = http.send(req);
                System.debug(res.getBody());
                
                System.debug('status code' + res.getStatusCode());
            }
            
        }catch(Exception ex){
            System.debug('Message code' + ex.getMessage() +' in line number-->'+ex.getLineNumber());
            //  DFJ_ErrorLogController.addErrorLogs('', 'Sending Sms from sender Id', ex.getMessage(), 'Error', 'DFJ_SendSMS_From_SenderId.makeHttpCallout', '', String.valueOf(ex.getLineNumber()));
        }  
    }
    
    public class SMSInputParameter {
        @InvocableVariable(required=true)
        public String message;
        
        @InvocableVariable(required=true)
        public String toPhoneNumber;
        
    }
    
}