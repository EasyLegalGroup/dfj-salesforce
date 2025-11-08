public with sharing class McSmsTransactionalBulk {

    // -------------------- DTOs --------------------

    public class AttributeKV {
        @InvocableVariable(required=true) public String name;
        @InvocableVariable(required=true) public String value;
    }

    /** Bulk wrapper (accepts messy numbers; Apex normalizes) */
    public class SMSWrapper {
        @InvocableVariable(required=true) public String to;
        @InvocableVariable(required=true) public String contactKey;
        @InvocableVariable(required=true) public String definitionKey;
        @InvocableVariable public List<AttributeKV> attributes;
        @InvocableVariable public String messageKey;
        @InvocableVariable public String messageOverride; // optional content override -> sent as content.message
    }

    /** Structured per-item result for Flow logging/branching */
    public class SendResult {
        @InvocableVariable public String  messageKey;
        @InvocableVariable public Integer httpStatus;     // 202 if sent now; 0 if queued
        @InvocableVariable public String  rawResponse;    // raw MC body
        @InvocableVariable public String  errorMessage;   // set if callout fails or non-2xx
        @InvocableVariable public String  normalizedTo;   // digits-only, what we actually sent
        @InvocableVariable public String  warning;        // sanity warning (if any)
        @InvocableVariable public Boolean asyncQueued;    // true if deferred to Queueable
        @InvocableVariable public String  asyncJobId;     // Queueable job Id if queued
    }

    // -------------------- Test seams / limits --------------------

    @TestVisible private static Integer MAX_PER_TX_OVERRIDE;                // for bulkSend sync slice
    @TestVisible private static Integer BULKQUEUE_MAX_PER_EXECUTE_OVERRIDE; // for BulkQueue.execute slice
    @TestVisible private static Boolean DISABLE_CHAINING_IN_TESTS = false;  // avoid enqueue recursion in tests
    @TestVisible private static String  DEFAULT_FROM_NAME = 'FamJurist';    // brand default

    private static Integer maxPerTx() { return (MAX_PER_TX_OVERRIDE == null ? 90 : MAX_PER_TX_OVERRIDE); }

    // -------------------- Helpers: key inference & attributes ----------------

    // Infer country from definition key (mirrors McSmsSendQueue)
    @TestVisible
    private static String inferCountryIso2FromDefKey(String defKey) {
        String k = (defKey == null ? '' : defKey.toUpperCase());
        if (k.contains('_SE') || k.endsWith('SE') || k.startsWith('SE') || k.contains('SE_')) return 'SE';
        return 'DK';
    }

    @TestVisible
    private static Boolean isAlphaKey(String defKey) {
        String k = (defKey == null ? '' : defKey.toUpperCase());
        return k.contains('ALPHA');
    }

    private static Boolean prefixMatchesIso(String digits, String iso2) {
        if (String.isBlank(digits) || String.isBlank(iso2)) return true;
        if (iso2 == 'DK') return digits.startsWith('45');
        if (iso2 == 'SE') return digits.startsWith('46');
        return true;
    }

    private static Map<String,Object> kvToMap(List<AttributeKV> kvs) {
        Map<String,Object> attrs = new Map<String,Object>();
        if (kvs != null) {
            for (AttributeKV kv : kvs) {
                if (kv != null && !String.isBlank(kv.name)) {
                    attrs.put(kv.name, kv.value);
                }
            }
        }
        return attrs;
    }

    /** Only used for ALPHA keys: inject default FromName if caller didn’t provide one. */
    private static Map<String,Object> ensureFromName(Map<String,Object> attrs) {
        if (attrs == null) attrs = new Map<String,Object>();
        if (!attrs.containsKey('FromName')
            || String.valueOf(attrs.get('FromName')) == null
            || String.valueOf(attrs.get('FromName')).trim() == '') {
            attrs.put('FromName', DEFAULT_FROM_NAME);
        }
        return attrs;
    }

    private static String generateMessageKey(String to, String ck) {
        Blob b = Blob.valueOf(String.valueOf(to) + ':' + String.valueOf(ck) + ':' + String.valueOf(Crypto.getRandomInteger()));
        String hex = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', b));
        return hex.substring(0, 32);
    }

    // -------------------- BULK send (invocable) ---------------------

    @InvocableMethod(label='Send SMS - Bulk (SFMC Transactional API)')
    public static List<SendResult> bulkSend(List<SMSWrapper> inputs) {
        List<SendResult> results = new List<SendResult>();
        if (inputs == null || inputs.isEmpty()) return results;

        Integer MAX = maxPerTx();

        // 1) Synchronous slice (up to MAX) -> return full results
        Integer syncCount = Math.min(inputs.size(), MAX);
        for (Integer i = 0; i < syncCount; i++) {
            results.add(sendOneSync(inputs[i]));
        }

        // 2) Remaining -> queue for async processing; return "QUEUED" placeholders
        if (inputs.size() > syncCount) {
            List<SMSWrapper> remainder = new List<SMSWrapper>();
            for (Integer i = syncCount; i < inputs.size(); i++) {
                remainder.add(inputs[i]);
            }

            String jobId = System.enqueueJob(new BulkQueue(remainder));
            for (SMSWrapper w : remainder) {
                SendResult r = placeholderQueued(w, jobId);
                results.add(r);
            }
        }

        return results;
    }

    private static SendResult sendOneSync(SMSWrapper w) {
        SendResult r = new SendResult();
        try {
            if (w == null) throw new AuraHandledException('Null item');
            if (String.isBlank(w.to) || String.isBlank(w.contactKey) || String.isBlank(w.definitionKey)) {
                throw new AuraHandledException('to, contactKey, and definitionKey are required.');
            }

            String iso2 = inferCountryIso2FromDefKey(w.definitionKey);
            McPhone.Norm norm = McPhone.normalize(w.to, iso2);
            if (norm.warning != null) {
                System.debug(LoggingLevel.WARN, iso2 + ' sanity warning: ' + norm.warning);
                r.warning = norm.warning;
            }
            if (String.isBlank(norm.digits)) throw new AuraHandledException('No digits found in phone number: ' + w.to);
            r.normalizedTo = norm.digits;

            String mk = String.isBlank(w.messageKey) ? generateMessageKey(norm.digits, w.contactKey) : w.messageKey;
            r.messageKey = mk;

            Boolean alpha = isAlphaKey(w.definitionKey);
            Map<String,Object> attrs = kvToMap(w.attributes);
            if (alpha) {
                attrs = ensureFromName(attrs); // inject only for alpha keys
            } else if (attrs != null) {
                // Defensive: never allow FromName on numeric sends
                attrs.remove('FromName');
                if (attrs.isEmpty()) attrs = null;
            }

            Map<String,Object> recip = new Map<String,Object>{
                'contactKey' => w.contactKey,
                'to' => norm.digits
            };
            if (attrs != null && !attrs.isEmpty()) recip.put('attributes', attrs);

            Map<String,Object> body = new Map<String,Object>{
                'definitionKey' => w.definitionKey,
                'recipient'     => recip
            };
            if (String.isNotBlank(w.messageOverride)) {
                body.put('content', new Map<String,Object>{ 'message' => w.messageOverride });
            }
            if (!prefixMatchesIso(norm.digits, iso2)) {
                System.debug(LoggingLevel.WARN, 'Definition/number country mismatch. defKey=' + w.definitionKey + ', iso2=' + iso2 + ', to=' + norm.digits);
            }

            McRestClient.Result res = McRestClient.post('/messaging/v1/sms/messages/' + EncodingUtil.urlEncode(mk,'UTF-8'), body);
            r.httpStatus  = res.status;
            r.rawResponse = res.body;

            if (res.status < 200 || res.status >= 300) {
                r.errorMessage = 'Failed ['+res.status+']';
            }
        } catch (Exception ex) {
            r.httpStatus   = null;
            r.errorMessage = ex.getTypeName() + ': ' + ex.getMessage();
        }
        r.asyncQueued = false;
        return r;
    }

    private static SendResult placeholderQueued(SMSWrapper w, String jobId) {
        SendResult r = new SendResult();
        String iso2 = inferCountryIso2FromDefKey(w.definitionKey);
        McPhone.Norm norm = McPhone.normalize(w.to, iso2);
        r.messageKey   = String.isBlank(w.messageKey) ? generateMessageKey((norm.digits==null? '':norm.digits), w.contactKey) : w.messageKey;
        r.normalizedTo = norm.digits;
        r.warning      = norm.warning;
        r.httpStatus   = 0;
        r.rawResponse  = null;
        r.errorMessage = 'QUEUED';
        r.asyncQueued  = true;
        r.asyncJobId   = jobId;
        return r;
    }

    // -------------------- Queueable for bulk chaining -------------------------

    public class BulkQueue implements Queueable, Database.AllowsCallouts {
        private List<SMSWrapper> items;

        public BulkQueue(List<SMSWrapper> items) { this.items = (items == null ? new List<SMSWrapper>() : items); }

        public void execute(QueueableContext qc) {
            Integer MAX = (McSmsTransactionalBulk.BULKQUEUE_MAX_PER_EXECUTE_OVERRIDE == null
                           ? 90
                           : McSmsTransactionalBulk.BULKQUEUE_MAX_PER_EXECUTE_OVERRIDE);
            if (items.isEmpty()) return;

            List<SMSWrapper> now   = new List<SMSWrapper>();
            List<SMSWrapper> later = new List<SMSWrapper>();
            for (Integer i = 0; i < items.size(); i++) {
                if (i < MAX) now.add(items[i]); else later.add(items[i]);
            }

            for (SMSWrapper w : now) {
                try {
                    String iso2 = inferCountryIso2FromDefKey(w.definitionKey);
                    McPhone.Norm norm = McPhone.normalize(w.to, iso2);
                    if (norm.warning != null) System.debug(LoggingLevel.WARN, iso2 + ' sanity warning (async): ' + norm.warning);
                    if (String.isBlank(norm.digits)) throw new AuraHandledException('No digits found in phone number: ' + w.to);

                    String mk = String.isBlank(w.messageKey) ? generateMessageKey(norm.digits, w.contactKey) : w.messageKey;

                    Boolean alpha = isAlphaKey(w.definitionKey);
                    Map<String,Object> attrs = kvToMap(w.attributes);
                    if (alpha) {
                        attrs = ensureFromName(attrs);
                    } else if (attrs != null) {
                        attrs.remove('FromName');
                        if (attrs.isEmpty()) attrs = null;
                    }

                    Map<String,Object> recip = new Map<String,Object>{
                        'contactKey' => w.contactKey,
                        'to' => norm.digits
                    };
                    if (attrs != null && !attrs.isEmpty()) recip.put('attributes', attrs);

                    Map<String,Object> body = new Map<String,Object>{
                        'definitionKey' => w.definitionKey,
                        'recipient'     => recip
                    };
                    if (String.isNotBlank(w.messageOverride)) {
                        body.put('content', new Map<String,Object>{ 'message' => w.messageOverride });
                    }
                    if (!prefixMatchesIso(norm.digits, iso2)) {
                        System.debug(LoggingLevel.WARN, 'Definition/number country mismatch (async). defKey=' + w.definitionKey + ', iso2=' + iso2 + ', to=' + norm.digits);
                    }

                    McRestClient.post('/messaging/v1/sms/messages/' + EncodingUtil.urlEncode(mk, 'UTF-8'), body);
                } catch (Exception ex) {
                    System.debug(LoggingLevel.ERROR, 'Async bulk send failed: ' + ex.getTypeName() + ' ' + ex.getMessage());
                }
            }

            if (!later.isEmpty()) {
                if (Test.isRunningTest() && McSmsTransactionalBulk.DISABLE_CHAINING_IN_TESTS == true) {
                    System.debug(LoggingLevel.INFO, 'Skipping enqueue chaining in tests (test seam active).');
                } else {
                    System.enqueueJob(new BulkQueue(later));
                }
            }
        }
    }
}