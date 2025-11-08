@RestResource(urlMapping='/mc/inbound-sms')
global without sharing class MC_InboundSMS_API {

    // ====== Defaults / Config ======
    private static final String  DIR_INCOMING          = 'Incoming';
    private static final String  STATUS_RECEIVED       = 'Received';
    private static final String  TYPE_INBOUND          = 'Inbound';
    private static final Boolean SYNCED_TO_MC_DEFAULT  = false;

    // If To_Number__c is required by validation rules during verification,
    // use a safe fallback. Adjust to your org (e.g., your service number).
    private static final String VERIFY_TO_FALLBACK = '0000000000';

    // Tests may flip this to bypass token checks in @IsTest
    @TestVisible private static Boolean BYPASS_AUTH = false;

    // ====== ENS probe (GET, no auth) ======
    @HttpGet
    global static void ping() {
        RestResponse res = RestContext.response;
        res.addHeader('Cache-Control','no-store');
        res.addHeader('Content-Type','application/json');
        send200(res, 'OK', new Map<String,Object>{ 'status' => 'alive' });
    }

    // ====== Main POST handler (ALWAYS 200 back to MC) ======
    @HttpPost
    global static void handle() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Cache-Control','no-store');
        res.addHeader('Content-Type','application/json');

        // 0) Token from header (X-Auth-Token or Authorization: Bearer/Token) OR query param ?t=
        String token   = req.headers.get('X-Auth-Token');
        String authHdr = req.headers.get('Authorization');
        if (String.isBlank(token) && !String.isBlank(authHdr)) {
            String a = authHdr.trim(); String al = a.toLowerCase();
            if (al.startsWith('bearer ')) token = a.substring(7).trim();
            else if (al.startsWith('token ')) token = a.substring(6).trim();
        }
        String qSecret = (req.params != null) ? req.params.get('t') : null;
        if (String.isBlank(token) && !String.isBlank(qSecret)) token = qSecret;
        if (token != null) token = token.trim();

        // Body string (may be null/empty/{} for liveness probes)
        String body = (req.requestBody == null) ? null : req.requestBody.toString().trim();

        // --- Liveness probe: empty body → ALWAYS 200 ---
        if (String.isBlank(body)) {
            send200(res, 'OK', new Map<String,Object>{ 'status' => 'handshake-ok' });
            return;
        }

        // 1) Parse any non-empty JSON
        Object root;
        try {
            root = JSON.deserializeUntyped(body);
        } catch (Exception e) {
            send200(res, 'ERROR', new Map<String,Object>{
                'status' => 'ERROR', 'error' => 'Invalid JSON'
            });
            return;
        }

        // 2) VERIFICATION PAYLOAD (token may or may not be present; accept both)
        // Accept modern 'verificationKey' or legacy 'signatureKey'
        if (root instanceof Map<String, Object>) {
            Map<String, Object> m = (Map<String, Object>) root;
            String callbackId      = (String) m.get('callbackId');
            String verificationKey = (String) m.get('verificationKey');
            if (String.isBlank(verificationKey)) verificationKey = (String) m.get('signatureKey');

            if (!String.isBlank(callbackId) && !String.isBlank(verificationKey)) {
                SMS__c v = new SMS__c();
                v.External_ID__c  = 'ENS-VERIFY-' + String.valueOf(Datetime.now().getTime());
                v.Direction__c    = DIR_INCOMING;
                v.Status__c       = STATUS_RECEIVED;
                v.Type__c         = TYPE_INBOUND;
                v.Message__c      = 'ENS Verification Payload';
                v.To_Number__c    = VERIFY_TO_FALLBACK;
                v.From_Number__c  = 'ENS';
                v.Raw_Response__c = fitToField(JSON.serialize(m), SMS__c.Raw_Response__c);
                insert v;

                send200(res, 'OK', new Map<String,Object>{ 'status' => 'verification-received' });
                return;
            }
        }

        // 2b) Liveness/odd pings (e.g., {} or any Map w/o events/verification) → 200
        if (root instanceof Map<String, Object>) {
            Map<String, Object> m = (Map<String, Object>) root;
            Boolean looksVerify = m.containsKey('callbackId') &&
                                  (m.containsKey('verificationKey') || m.containsKey('signatureKey'));
            Boolean hasEvents  = m.containsKey('events') && (m.get('events') instanceof List<Object>);
            if (!looksVerify && !hasEvents) {
                send200(res, 'OK', new Map<String,Object>{ 'status' => 'handshake-ok' });
                return;
            }
        }

        // 3) REAL EVENTS REQUIRE AUTH (header or ?t=)
        if (!(BYPASS_AUTH || isValidToken(token))) {
            send200(res, 'IGNORED', new Map<String,Object>{
                'status' => 'IGNORED', 'error' => 'Unauthorized'
            });
            return;
        }

        // 4) Normalize to a list of event objects
        List<Object> events = normalizeToEventList(root);
        if (events.isEmpty()) {
            send200(res, 'ERROR', new Map<String,Object>{
                'status' => 'ERROR', 'error' => 'No events found'
            });
            return;
        }

        // 5) Map → SMS__c rows
        List<SMS__c> rows     = new List<SMS__c>();
        List<Result> results  = new List<Result>();
        Integer idx           = 0;

        for (Object o : events) {
            if (!(o instanceof Map<String, Object>)) {
                results.add(new Result(idx++, null, 'error', null, 'Event must be an object'));
                continue;
            }
            Map<String, Object> ev = (Map<String, Object>) o;

            // Accept many possible id key names
            String messageId = firstString(ev, new String[]{
                'messageId','eventId','MessageID','id','moMessageId','moId','requestId','requestID',
                'requestMessageId','requestMessageID','messageSid'
            });

            String toNum   = firstString(ev, new String[]{
                'destinationNumber','to','destination','longCode','shortCode','recipientNumber'
            });
            String fromNum = firstString(ev, new String[]{
                'subscriberNumber','msisdn','from','senderNumber','origination'
            });

            // Prefer plain text, fall back to Base64 variants
            String text    = firstTextOrB64(ev);

            String keyword = firstString(ev, new String[]{'keyword','Keyword'});
            String tsStr   = firstString(ev, new String[]{
                'eventTimestamp','timestamp','sentTimestamp','receivedTimestamp'
            });

            // Stable fallback id if supplier fails to send an id
            if (String.isBlank(messageId)) {
                String basis = (safeStr(toNum) + '|' + safeStr(fromNum) + '|' +
                                safeStr(tsStr) + '|' + safeStr(text)).trim();
                String digest = EncodingUtil.convertToHex(
                    Crypto.generateDigest('SHA1', Blob.valueOf(basis))
                );
                messageId = 'mo-' + digest.substring(0, 20);
            }

            SMS__c s = new SMS__c();
            s.External_ID__c = messageId;     // upsert key (idempotency)
            s.From_Number__c = fromNum;
            s.To_Number__c   = String.isBlank(toNum) ? VERIFY_TO_FALLBACK : toNum;

            if (!String.isBlank(text)) {
                s.Message__c       = fitToField(text, SMS__c.Message__c);
                s.Response_Body__c = fitToField(text, SMS__c.Response_Body__c);
            }
            if (!String.isBlank(keyword)) s.Keyword__c = keyword;

            s.Direction__c  = DIR_INCOMING;
            s.Status__c     = STATUS_RECEIVED;
            s.Type__c       = TYPE_INBOUND;
            s.Is_Synced_to_Marketing_Cloud__c = SYNCED_TO_MC_DEFAULT;

            Datetime ts = parseIsoToDatetime(tsStr);
            if (ts != null) s.Sent_Received_Time__c = ts;

            // Optional extras when present
            String media = extractFirstMediaUrl(ev);
            if (!String.isBlank(media)) s.Media_URL__c = media;

            String statusCode = firstString(ev, new String[]{'statusCode','StatusCode','status'});
            if (!String.isBlank(statusCode) && fieldExists('SMS__c','Status_Code__c')) {
                s.put('Status_Code__c', fitString(statusCode, 10));
            }

            s.Raw_Response__c = fitToField(JSON.serialize(ev), SMS__c.Raw_Response__c);
            if (fieldExists('SMS__c','Full_Response__c')) {
                s.put('Full_Response__c', fitString(body, 131000));
            }

            rows.add(s);
            results.add(new Result(idx++, messageId, 'pending', null, null));
        }

        // 6) Upsert (idempotent)
        Integer ok=0, err=0, skipped=0;
        if (!rows.isEmpty()) {
            Database.UpsertResult[] urs = Database.upsert(rows, SMS__c.External_ID__c, false);
            Integer r = 0;
            for (Integer i = 0; i < results.size(); i++) {
                Result rr = results[i];
                if (rr.status != 'pending') {
                    if (rr.status == 'skipped') skipped++;
                    if (rr.status == 'error')   err++;
                    continue;
                }
                Database.UpsertResult ur = urs[r++];
                if (ur.isSuccess()) {
                    rr.status = ur.isCreated() ? 'created' : 'updated';
                    rr.id     = String.valueOf(ur.getId());
                    ok++;
                } else {
                    rr.status = 'error';
                    rr.error  = firstError(ur.getErrors());
                    err++;
                }
                results[i] = rr;
            }
        } else {
            for (Result rr : results) {
                if (rr.status == 'skipped') skipped++;
                if (rr.status == 'error')   err++;
            }
        }

        // 7) Response body with status summary (HTTP always 200)
        String overall =
            (err>0 && ok>0) ? 'PARTIAL' :
            (err>0 ? 'ERROR' : 'OK');

        Map<String, Object> out = new Map<String, Object>{
            'status'       => overall,
            'successCount' => ok,
            'errorCount'   => err,
            'skipped'      => skipped,
            'results'      => results
        };
        send200(res, overall, out);
    }

    // ====== Auth via Protected CMDT (Inbound_SMS_Auth__mdt) ======
    private static Boolean isValidToken(String token) {
        if (String.isBlank(token)) return false;
        String t = token.trim();
        // Be tolerant of ""+"" → "" "" decoding from querystrings (rare secrets contain real spaces)
        String tFix = t.contains(' ') ? t.replace(' ', '+') : t;

        for (Inbound_SMS_Auth__mdt r :
             [SELECT Active__c, Shared_Secret__c FROM Inbound_SMS_Auth__mdt WHERE Active__c = true]) {
            String s = r.Shared_Secret__c;
            if (t == s || tFix == s) return true;
        }
        return false; // fail closed
    }

    // ====== DTO & helpers ======
    public class Result {
        public Integer index;
        public String  messageId;
        public String  status;
        public String  id;
        public String  error;
        public Result(Integer i, String m, String s, String idv, String err) {
            index = i; messageId = m; status = s; id = idv; error = err;
        }
    }

    // Always-200 helper with consistent headers (serialize bodyObject as JSON)
    private static void send200(RestResponse res, String resultHeader, Object bodyObject){
        res.statusCode   = 200;
        if (!String.isBlank(resultHeader)) res.addHeader('X-Result', resultHeader);
        res.responseBody = Blob.valueOf(JSON.serialize(bodyObject));
    }

    private static List<Object> normalizeToEventList(Object root){
        if (root instanceof Map<String, Object>) {
            Map<String, Object> m = (Map<String, Object>) root;
            if (m.containsKey('events') && m.get('events') instanceof List<Object>)
                return (List<Object>) m.get('events');
            return new List<Object>{ root };
        }
        if (root instanceof List<Object>) return (List<Object>) root;
        return new List<Object>();
    }

    private static String firstString(Map<String, Object> m, String[] keys){
        for (String k : keys) {
            if (!m.containsKey(k) || m.get(k) == null) continue;
            String v = String.valueOf(m.get(k));
            if (!String.isBlank(v)) return v.trim();
        }
        return null;
    }

    // Prefer plain text keys; if blank, attempt Base64-decoded variants
    private static String firstTextOrB64(Map<String, Object> ev){
        // Normal fields first
        String t = firstString(ev, new String[]{'messageText','text','body','message','Message','moText'});
        if (!String.isBlank(t)) return t;

        // Base64 variants (lets AMPScript avoid JSON-escaping headaches)
        String b64 = firstString(ev, new String[]{'messageText_b64','text_b64','body_b64'});
        if (!String.isBlank(b64)) {
            try {
                return EncodingUtil.base64Decode(b64).toString();
            } catch (Exception e) {
                // ignore and fall through
            }
        }
        return null;
    }

    private static String extractFirstMediaUrl(Map<String, Object> ev){
        for (String key : new List<String>{'media','mediaUrls','attachments','Media','MediaUrls'}) {
            Object v = ev.get(key);
            if (v instanceof List<Object>) {
                List<Object> arr = (List<Object>) v;
                if (arr.isEmpty()) continue;
                Object first = arr[0];
                if (first instanceof String) return (String) first;
                if (first instanceof Map<String,Object>) {
                    Map<String,Object> mm = (Map<String,Object>) first;
                    if (mm.get('url') != null)      return String.valueOf(mm.get('url'));
                    if (mm.get('mediaUrl') != null) return String.valueOf(mm.get('mediaUrl'));
                }
            } else if (v instanceof String) {
                return (String) v;
            }
        }
        if (ev.get('mediaUrl') != null) return String.valueOf(ev.get('mediaUrl'));
        return null;
    }

    private static Datetime parseIsoToDatetime(String s){
        try {
            if (String.isBlank(s)) return null;
            String x = s.trim();
            if (x.contains('.')) {
                Integer z   = Math.max(x.indexOf('Z'), Math.max(x.lastIndexOf('+'), x.lastIndexOf('-')));
                Integer dot = x.indexOf('.', 10);
                if (dot > 0) x = x.substring(0, dot) + (z > 0 ? x.substring(z) : '');
            }
            if (x.endsWith('Z')) return Datetime.valueOfGmt(x.substring(0, x.length()-1).replace('T',' '));
            Integer pm = Math.max(x.lastIndexOf('+'), x.lastIndexOf('-'));
            if (pm > 9) {
                String base = x.substring(0, pm).replace('T',' ');
                String off  = x.substring(pm);
                Integer sign = off.startsWith('+') ? 1 : -1;
                List<String> hm = off.substring(1).split(':');
                Integer h = Integer.valueOf(hm[0]);
                Integer m = (hm.size() > 1) ? Integer.valueOf(hm[1]) : 0;
                Datetime g = Datetime.valueOfGmt(base);
                return g.addHours(-sign*h).addMinutes(-sign*m);
            }
            return Datetime.valueOfGmt(x.replace('T',' '));
        } catch (Exception e) {
            return null;
        }
    }

    private static String fitToField(String s, Schema.SObjectField f){
        if (s == null) return null;
        Integer max = f.getDescribe().getLength();
        return s.length() > max ? s.substring(0, max) : s;
    }

    private static String fitString(String s, Integer max){
        if (s == null) return null;
        return s.length() > max ? s.substring(0, max) : s;
    }

    private static Boolean fieldExists(String sobj, String field){
        Schema.SObjectType t = Schema.getGlobalDescribe().get(sobj);
        return t != null && t.getDescribe().fields.getMap().containsKey(field);
    }

    private static String firstError(Database.Error[] errs){
        if (errs == null || errs.isEmpty()) return 'Unknown DML error';
        Database.Error e = errs[0];
        return (e.getStatusCode()!=null ? String.valueOf(e.getStatusCode()) + ': ' : '') + e.getMessage();
    }

    private static String safeStr(String s) { return String.isBlank(s) ? '' : s; }
}