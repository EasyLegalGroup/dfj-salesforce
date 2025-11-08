/**
 * DFJ_SendSMS
 * Send an SMS via Twilio in one of three ways:
 *   1) messagingServiceSid  → adds &MessagingServiceSid=MG…
 *   2) sendFromSenderId=true → adds &From=<Alphanumeric Sender ID from metadata>
 *   3) fromNumber supplied  → adds &From=<fromNumber>
 *
 * Prereq custom-metadata record “Din_Familie_Jurist” in Send_SMS_From_SenderId__mdt
 * with Account_SID__c, Auth_Token__c, Alphanumeric_Sender_ID__c.
 */
public class DFJ_SendSMS {

    /*──────── Invocable input ────────*/
    public class SMSInput {
        @InvocableVariable(required=true)  public String  message;
        @InvocableVariable(required=true)  public String  toPhoneNumber;
        @InvocableVariable(required=false) public String  messagingServiceSid;
        @InvocableVariable(required=false) public Boolean sendFromSenderId;
        @InvocableVariable(required=false) public String  fromNumber;
    }

    @InvocableMethod(label='Send SMS (Service SID / Sender ID / From)')
    public static void send(List<SMSInput> inList) {
        if (inList.isEmpty()) return;
        SMSInput p = inList[0];

        /* validate */
        if (String.isBlank(p.messagingServiceSid)) {
            if (p.sendFromSenderId == true) {
                /* ok – will use Sender ID from metadata */
            } else if (!String.isBlank(p.fromNumber)) {
                /* ok – will use explicit From */
            } else {
                throw new AuraHandledException(
                    'Supply messagingServiceSid, or set sendFromSenderId = true, or pass fromNumber.');
            }
        }

        /* hand off to @future (all primitives) */
        makeCallout(p.toPhoneNumber, p.message,
                    p.messagingServiceSid,
                    (p.sendFromSenderId == true),   // null → false
                    p.fromNumber);
    }

    /*──────── Actual callout ────────*/
    @future(callout=true)
    private static void makeCallout(String toNum, String bodyTxt,
                                    String svcSid, Boolean useSenderId,
                                    String fromNum) {

        Send_SMS_From_SenderId__mdt cfg =
            Send_SMS_From_SenderId__mdt.getInstance('Din_Familie_Jurist');
        if (cfg == null) return;

        String acct   = cfg.Account_SID__c;
        String token  = cfg.Auth_Token__c;
        String sId    = cfg.Alphanumeric_Sender_ID__c;

        /* build body */
        String body = 'To='   + EncodingUtil.urlEncode(toNum,  'UTF-8')
                    + '&Body=' + EncodingUtil.urlEncode(bodyTxt,'UTF-8');

        if (!String.isBlank(svcSid)) {
            body += '&MessagingServiceSid=' +
                    EncodingUtil.urlEncode(svcSid, 'UTF-8');
        } else if (useSenderId) {
            body += '&From=' + EncodingUtil.urlEncode(sId, 'UTF-8');
        } else {
            body += '&From=' + EncodingUtil.urlEncode(fromNum, 'UTF-8');
        }

        /* DEBUG – see exactly what we send */
        System.debug('Twilio BODY → ' + body);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.twilio.com/2010-04-01/Accounts/'
                        + acct + '/Messages.json');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Authorization', 'Basic ' +
            EncodingUtil.base64Encode(Blob.valueOf(acct + ':' + token)));
        req.setBody(body);

        HttpResponse res = (new Http()).send(req);
        System.debug('Twilio response: ' +
                     res.getStatusCode() + ' → ' + res.getBody());
    }
}