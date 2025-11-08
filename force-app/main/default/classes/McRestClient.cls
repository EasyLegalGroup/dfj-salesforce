public with sharing class McRestClient {
    /** Named Credential used for all callouts (stays MC_Rest as requested). */
    public static String NC = 'MC_Rest';
    private static final Integer TIMEOUT_MS = 120000;

    // ---- Convenience: SMS send + lookups -----------------------------------

    public static McRestClient.Result sendSms(
        String definitionKey,
        String toMsisdn,
        String contactKey,
        Map<String,Object> attributes
    ){
        Map<String,Object> payload = new Map<String,Object>();
        payload.put('definitionKey', definitionKey);

        if (attributes != null && !attributes.isEmpty()) {
            payload.put('attributes', attributes);
        }

        Map<String,Object> one = new Map<String,Object>();
        one.put('to', toMsisdn);
        if (String.isBlank(contactKey)) contactKey = toMsisdn;
        one.put('contactKey', contactKey);

        payload.put('recipients', new List<Object>{ one });

        return post('/messaging/v1/sms/messages', payload);
    }

    public static McRestClient.Result getMessage(String messageKey) {
        return get('/messaging/v1/sms/messages/' + EncodingUtil.urlEncode(messageKey, 'UTF-8'));
    }
    public static McRestClient.Result getMessageEvents(String messageKey) {
        return get('/messaging/v1/sms/messages/' + EncodingUtil.urlEncode(messageKey, 'UTF-8') + '/events');
    }
    public static McRestClient.Result getDefinition(String definitionKey) {
        return get('/messaging/v1/sms/definitions/' + definitionKey);
    }

    // ---- Generic REST helpers ----------------------------------------------

    public class Result {
        public Integer status;
        public String body;
        public Map<String,String> headers = new Map<String,String>();
        public Result() {}
    }
    public static String serialize(Object payload) { return JSON.serialize(payload); }

    public static McRestClient.Result get(String path) {
        System.HttpRequest req = base(path, 'GET');
        return send(req);
    }
    public static McRestClient.Result post(String path, Object payload) {
        System.HttpRequest req = base(path, 'POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(serialize(payload));
        return send(req);
    }
    public static McRestClient.Result patch(String path, Object payload) {
        System.HttpRequest req = base(path, 'PATCH');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(serialize(payload));
        return send(req);
    }

    // ---- Low-level plumbing -------------------------------------------------

    private static System.HttpRequest base(String path, String method) {
        System.HttpRequest req = new System.HttpRequest();
        String clean = String.valueOf(path);
        if (clean.startsWith('/')) clean = clean.substring(1);
        req.setEndpoint('callout:' + NC + '/' + clean);
        req.setMethod(method);
        req.setTimeout(TIMEOUT_MS);
        return req;
    }

    /** Minimal retry for transient responses (401/429/5xx). Uses MC_Rest only. */
    private static McRestClient.Result send(System.HttpRequest req) {
        System.Http http = new System.Http();
        McRestClient.Result last = null;
        Integer maxAttempts = 3;

        for (Integer attempt = 0; attempt < maxAttempts; attempt++) {
            System.HttpResponse res = http.send(req);

            McRestClient.Result r = new McRestClient.Result();
            r.status = res.getStatusCode();
            r.body   = res.getBody();

            List<String> keys = res.getHeaderKeys();
            if (keys != null) {
                for (String h : keys) r.headers.put(h, res.getHeader(h));
            }
            last = r;

            Integer code = (r.status == null ? 0 : r.status);
            Boolean retryable = (code == 401 || code == 429 || (code >= 500 && code <= 599));
            if (!retryable) {
                return r;
            }
            // else: loop and retry (up to maxAttempts)
        }
        // If all attempts exhausted, return the last response we saw
        return (last == null ? new McRestClient.Result() : last);
    }

    // ---- Idempotent send (messageKey in path) -------------------------------

    public static McRestClient.Result sendSmsWithKey(
        String definitionKey,
        String toMsisdn,
        String contactKey,
        Map<String,Object> attributes,
        String messageKey
    ){
        if (String.isBlank(contactKey)) contactKey = toMsisdn;

        Map<String,Object> body = new Map<String,Object>{
            'definitionKey' => definitionKey,
            'recipient' => new Map<String,Object>{
                'to' => toMsisdn,
                'contactKey' => contactKey,
                'attributes' => (attributes == null ? new Map<String,Object>() : attributes)
            }
        };

        String path = '/messaging/v1/sms/messages/' + EncodingUtil.urlEncode(messageKey, 'UTF-8');
        return post(path, body);
    }
}