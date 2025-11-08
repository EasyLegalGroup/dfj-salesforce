public class MarketingCloudSMSService {
    
    private static final String NAMED_CREDENTIAL = 'callout:MarketingCloud_SMS_Auth';
    private static final String ENDPOINT = '/messaging/v1/sms/messages/';
    
    public class SMSWrapper {
        @InvocableVariable(required=true)
        public String toNumber;
        @InvocableVariable(required=true)
        public String contactKey;
        @InvocableVariable(required=false)
        public String firstName;
        @InvocableVariable
        public String messageBody;
        @InvocableVariable(required=true)
        public String messageKey;    
        @InvocableVariable(required=true)
        public String definitionKey;    
    }
    
    // Response wrapper for Flow
    public class SMSResponseWrapper {
        @InvocableVariable
        public String responseBody;
        @InvocableVariable
        public String statusCode;
        
    }
    
    public class SMSRecipient {
        public String to;
        public String contactKey;
        public Map<String, String> attributes;
    }
    
    public class SMSContent {
        public String message;
    }
    
    public class SMSRequest {
        public String definitionKey;
        public SMSRecipient recipient;
        public SMSContent content;
    }
    
    @InvocableMethod(label='Send Single SMS via Marketing Cloud' callout=true)
    public static List<SMSResponseWrapper> sendSingleSMS(List<SMSWrapper> smsList) {
        List<SMSResponseWrapper> responseList = new List<SMSResponseWrapper>();
        
        if (smsList == null || smsList.isEmpty()) {
            return responseList;
        }
        SMSWrapper smsData = smsList[0];
        
        try {
            Map<String, String> attributes = new Map<String, String>();
            if (String.isNotBlank(smsData.firstName)) {
                attributes.put('FirstName', smsData.firstName);
            }
            
            //External_AccountId_Metadata__mdt record =  External_AccountId_Metadata__mdt.getInstance('Send_SMS');
            
            SMSRecipient recipient = new SMSRecipient();
            recipient.to = smsData.toNumber;
            recipient.contactKey = smsData.contactKey;
            recipient.attributes = attributes;
            
            SMSContent content = new SMSContent();
            content.message = smsData.messageBody;
            
            SMSRequest smsRequest = new SMSRequest();
            smsRequest.definitionKey = smsData.definitionKey;
            smsRequest.recipient = recipient;
            smsRequest.content = content;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(NAMED_CREDENTIAL + ENDPOINT + smsData.messageKey);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(smsRequest));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            Integer StatusCode = res.getStatusCode();
            String ResponseBody = res.getBody();
            
            SMSResponseWrapper resp = new SMSResponseWrapper();
            resp.responseBody = ResponseBody;
            resp.statusCode = String.valueOf(StatusCode);
            responseList.add(resp);
            
            
            
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('','Exception while sending SMS',ex.getMessage(),'Error','MarketingCloudSMSService.sendSingleSMS',JSON.serialize(smsData),String.valueOf(ex.getLineNumber()) );
        }
        
        return responseList;
    }
}