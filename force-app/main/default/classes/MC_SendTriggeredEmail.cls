public with sharing class MC_SendTriggeredEmail {

    // ===== Inputs from Flow =====
    public class Request {
        @InvocableVariable(required=true) public String definitionKey;   // e.g., 'LEC_REM_28Days_DK'
        @InvocableVariable(required=true) public String subscriberKey;   // e.g., Contact/Lead/PersonAccount Id
        @InvocableVariable(required=true) public String emailAddress;    // recipient email

        // Optional personalization (must match your MC Profile Attribute names)
        @InvocableVariable public String firstName;            // "First Name"
        @InvocableVariable public String lastName;             // "Last Name"
        @InvocableVariable public String phone;                // "Phone"
        @InvocableVariable public String eventDate;            // "EventDate"
        @InvocableVariable public String lecturerName;         // "LecturerName"
        @InvocableVariable public String hostAddressStreet;    // "HostAddressStreet"
        @InvocableVariable public String hostAddressZipCode;   // "HostAddressZipCode"
        @InvocableVariable public String hostAddressCity;      // "HostAddressCity"
        @InvocableVariable public String eventTime;            // "EventTime"
        @InvocableVariable public String bookingId;            // "BookingId"
        @InvocableVariable public String venueName;            // "VenueName"

        // Optional: set to false to use ASYNC; default (null/true) = SYNC (better for surfacing errors)
        @InvocableVariable public Boolean useSync;
    }

    // ===== Outputs back to Flow (optional to wire) =====
    public class Result {
        @InvocableVariable public Boolean success;
        @InvocableVariable public Integer statusCode;
        @InvocableVariable public String requestId;
        @InvocableVariable public String responseBody;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(label='Send MC Triggered Email')
    public static List<Result> send(List<Request> inputs) {
        List<Result> outs = new List<Result>();
        for (Request r : inputs) {
            Result res = new Result();
            try {
                // Build SubscriberAttributes (keys must match MC Profile Attribute names exactly)
                Map<String, Object> subAttrs = new Map<String, Object>();
                putIfNotBlank(subAttrs, 'Email Address', r.emailAddress);
                putIfNotBlank(subAttrs, 'First Name', r.firstName);
                putIfNotBlank(subAttrs, 'Last Name', r.lastName);
                putIfNotBlank(subAttrs, 'Phone', r.phone);
                putIfNotBlank(subAttrs, 'EventDate', r.eventDate);
                putIfNotBlank(subAttrs, 'EventTime', r.eventTime);
                putIfNotBlank(subAttrs, 'LecturerName', r.lecturerName);
                putIfNotBlank(subAttrs, 'HostAddressStreet', r.hostAddressStreet);
                putIfNotBlank(subAttrs, 'HostAddressZipCode', r.hostAddressZipCode);
                putIfNotBlank(subAttrs, 'HostAddressCity', r.hostAddressCity);
                putIfNotBlank(subAttrs, 'BookingId', r.bookingId);
                putIfNotBlank(subAttrs, 'VenueName', r.venueName);

                Map<String, Object> to = new Map<String, Object>{
                    'Address' => r.emailAddress,
                    'SubscriberKey' => r.subscriberKey,
                    'ContactAttributes' => new Map<String, Object>{
                        'SubscriberAttributes' => subAttrs
                    }
                };

                String reqType = (r.useSync == null || r.useSync) ? 'SYNC' : 'ASYNC';

                Map<String, Object> payload = new Map<String, Object>{
                    'To' => to,
                    'Options' => new Map<String, Object>{ 'RequestType' => reqType }
                };

                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setTimeout(20000);
                String keyEnc = EncodingUtil.urlEncode(r.definitionKey, 'UTF-8');
                req.setEndpoint('callout:MC_REST/messaging/v1/messageDefinitionSends/key:' + keyEnc + '/send');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(payload));

                HttpResponse resp = new Http().send(req);
                res.statusCode = resp.getStatusCode();
                res.responseBody = resp.getBody();

                if (resp.getStatusCode() >= 200 && resp.getStatusCode() < 300) {
                    res.success = true;
                    // Try to extract requestId
                    try {
                        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                        if (body != null && body.containsKey('requestId')) {
                            res.requestId = String.valueOf(body.get('requestId'));
                        }
                    } catch (Exception ignore) {}
                } else {
                    res.success = false;
                    res.errorMessage = 'MC send failed: ' + resp.getStatus() + ' — ' + resp.getBody();
                }

            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Exception: ' + e.getMessage();
            }
            outs.add(res);
        }
        return outs;
    }

    // Helper: only add non-blank strings
    private static void putIfNotBlank(Map<String, Object> m, String key, String val) {
        if (val != null && String.valueOf(val).trim().length() > 0) {
            m.put(key, val);
        }
    }
}