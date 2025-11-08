// CPRIngestInvocable.cls
public with sharing class CPRIngestInvocable {
    public class Request {
        @InvocableVariable(required=true) public Id contentVersionId;
        @InvocableVariable public Id fileRunId;
        @InvocableVariable public Date fileDate;
    }
    public class Response {
        @InvocableVariable public Integer eventsCreated;
        @InvocableVariable public String message;
        @InvocableVariable public Id fileRunId;
    }

    // Helper holder (must be at class scope in Apex)
    private class EventWithCpr {
        CPR_Event__c ev; String cpr;
        EventWithCpr(CPR_Event__c e, String c) {
            ev = e;
            String cc = (c == null ? null : c.trim());
            cpr = cc;
        }
    }
    private class Parsed {
        String eventCode; String statusCode; Date effectiveDate; String cpr;
        Datetime eventDateTime;
    }

    @InvocableMethod(label='CPR Ingest U09480-P')
    public static List<Response> run(List<Request> requests) {
        List<Response> out = new List<Response>();
        for (Request req : requests) {
            Response r = new Response();
            CPR_File_Run__c fr;
            try {
                // --- Load the uploaded file blob ---
                ContentVersion cv = [
                    SELECT Id, Title, VersionData, ContentDocumentId, CreatedDate, PathOnClient
                    FROM ContentVersion WHERE Id = :req.contentVersionId LIMIT 1
                ];

                // --- Create/refresh File Run ---
                if (req.fileRunId == null) {
                    fr = new CPR_File_Run__c(
                        File_Name__c = (cv.PathOnClient != null ? cv.PathOnClient : cv.Title),
                        File_Date__c = (req.fileDate == null ? Date.today() : req.fileDate),
                        Status__c    = coerceRunStatus('Received')
                    );
                    insert fr;
                } else {
                    fr = [
                        SELECT Id, File_Name__c, Status__c, Notes__c, Record_001_Count__c, Event_009_Count__c
                        FROM CPR_File_Run__c
                        WHERE Id = :req.fileRunId
                        LIMIT 1
                        FOR UPDATE
                    ];
                    fr.Status__c = coerceRunStatus('Received');
                    if (String.isBlank(fr.File_Name__c)) {
                        fr.File_Name__c = (cv.PathOnClient != null ? cv.PathOnClient : cv.Title);
                    }
                    update fr;
                }

                r.fileRunId = fr.Id;

                // --- Two bodies: machine-safe + diacritics-preserved ---
                String bodySafe   = asciiFromBlob(cv.VersionData);   // tab & CR normalized
                String bodyPretty = detailFromBlob(cv.VersionData);  // keeps ÅÆØ/åæø etc.

                List<String> linesSafe   = bodySafe.split('\n');
                List<String> linesPretty = bodyPretty.split('\n');

                // --- Fast pre-scan (daily vs snapshot) ---
                Integer cnt001 = 0, cnt009 = 0;
                for (String ln : linesSafe) {
                    if (String.isBlank(ln)) continue;
                    String t = safeSub(ln.trim(), 0, 3);
                    if      (t == '001') cnt001++;
                    else if (t == '009') cnt009++;
                }
                Boolean looksMonthlyByName =
                    fr.File_Name__c != null && fr.File_Name__c.endsWith('.l585602');

                if (looksMonthlyByName || (cnt009 == 0 && cnt001 > 100)) {
                    fr.Record_001_Count__c = cnt001;
                    try { fr.put('Event_009_Count__c', cnt009); } catch (Exception ignore) {}
                    fr.Status__c = coerceRunStatus('Rejected');
                    fr.Notes__c  = 'Skipped snapshot/non-daily file. 001=' + cnt001 + ', 009=' + cnt009 +
                                   (looksMonthlyByName ? ' (by filename)' : ' (by content)');
                    update fr;

                    r.eventsCreated = 0;
                    r.message = 'Skipped snapshot';
                    out.add(r);
                    continue; // next request
                }

                // --- Parse daily file (collect events; one-shot Contact lookup) ---
                String lastCprFrom001 = null;
                String last001RawPretty = null;

                List<EventWithCpr> staged = new List<EventWithCpr>();
                Set<String> cprSet = new Set<String>();

                for (Integer i = 0; i < linesSafe.size(); i++) {
                    String rawLineSafe   = linesSafe[i];
                    String rawLinePretty = (i < linesPretty.size() ? linesPretty[i] : rawLineSafe);
                    if (String.isBlank(rawLineSafe)) continue;

                    String line = rawLineSafe.trim();
                    String recType = safeSub(line, 0, 3);

                    if (recType == '001') {
                        String cprCandidate = safeSub(line, 3, 10);
                        lastCprFrom001 = (cprCandidate != null && cprCandidate.length() == 10) ? cprCandidate : null;
                        last001RawPretty = rawLinePretty; // keep pretty header for context
                        continue;
                    }

                    if (recType == '009' || recType == '090' || recType == '091' || recType == '099') {
                        Parsed p = parseEvent009(line);
                        if (p.cpr == null) p.cpr = lastCprFrom001;

                        // Create event *only* on 009 lines
                        if (recType == '009') {
                            // Idempotency key = SHA-256 of normalized 009 line
                            String key = EncodingUtil.convertToHex(
                                Crypto.generateDigest('SHA-256', Blob.valueOf(line))
                            );

                            CPR_Event__c ev = new CPR_Event__c(
                                Event_Key__c        = key,
                                Raw_Record__c       = rawLineSafe,
                                CPR_File_Run__c     = fr.Id,
                                Event_Code__c       = p.eventCode,
                                Effective_Date__c   = p.effectiveDate,
                                Status_Code__c      = p.statusCode,
                                CPR_From_File__c    = p.cpr,
                                Event_Datetime__c   = p.eventDateTime
                            );

                            // Map Action
                            if      (p.eventCode == 'A21') ev.Action__c = 'Death_A21';
                            else if (p.eventCode == 'A25') ev.Action__c = 'Revert_A25';
                            else if (p.eventCode == 'P02') ev.Action__c = 'AddressChange';
                            else if (p.eventCode == 'P03') ev.Action__c = 'NameChange';
                            else if (p.eventCode == 'A01' || p.eventCode == 'A13' || p.eventCode == 'P11') ev.Action__c = 'Other';
                            else if (p.eventCode != null && p.eventCode.startsWith('P')) ev.Action__c = 'AddressChange';

                            // If P02/P03, capture following 090/091 lines (pretty, preserves æøå etc.)
                            if (ev.Action__c == 'AddressChange' || ev.Action__c == 'NameChange') {
                                List<String> detailsPretty = new List<String>();
                                Integer j = i + 1;
                                while (j < linesSafe.size()) {
                                    String nxtSafe   = linesSafe[j];
                                    String nxtPretty = (j < linesPretty.size() ? linesPretty[j] : nxtSafe);
                                    if (nxtSafe == null) break;
                                    String nxtTrim = nxtSafe.trim();
                                    if (nxtTrim == '') { j++; continue; }
                                    String nt = safeSub(nxtTrim, 0, 3);
                                    if (nt == '090' || nt == '091') {
                                        detailsPretty.add(nxtPretty);
                                        j++;
                                        continue;
                                    }
                                    break;
                                }
                                if (!detailsPretty.isEmpty()) {
                                    try { ev.put('Details_Raw__c', String.join(detailsPretty, '\n')); } catch (Exception ignore) {}
                                    applyOffsetsToEvent(detailsPretty, ev.Event_Code__c, ev);
                                } else if (last001RawPretty != null) {
                                    try { ev.put('Details_Raw__c', last001RawPretty); } catch (Exception ignore) {}
                                }
                                i = j - 1; // fast-forward past details
                            } else if (last001RawPretty != null) {
                                try { ev.put('Details_Raw__c', last001RawPretty); } catch (Exception ignore) {}
                            }

                            // Stage for bulk contact lookup
                            if (p.cpr != null && p.cpr.length() == 10) {
                                cprSet.add(p.cpr);
                            }
                            staged.add(new EventWithCpr(ev, p.cpr));
                        }
                    }
                }

                // Bulk Contact lookup
                Map<String, Contact> byCpr = new Map<String, Contact>();
                if (!cprSet.isEmpty()) {
                    for (Contact conRec : [
                        SELECT Id, AccountId, CPR__c
                        FROM Contact
                        WHERE CPR__c IN :cprSet
                    ]) {
                        if (conRec.CPR__c != null) byCpr.put(conRec.CPR__c, conRec);
                    }
                }
                // Attach Contact/Account to staged events
                for (EventWithCpr ewc : staged) {
                    if (ewc == null || ewc.ev == null) continue;
                    if (ewc.cpr != null && byCpr.containsKey(ewc.cpr)) {
                        Contact con = byCpr.get(ewc.cpr);
                        ewc.ev.Contact__c = con.Id;
                        if (con.AccountId != null) ewc.ev.Account__c = con.AccountId;
                    }
                }

                // ---- Build flat list from staged wrappers ----
                List<CPR_Event__c> eventsToUpsert = new List<CPR_Event__c>();
                for (EventWithCpr ewc2 : staged) {
                    if (ewc2 != null && ewc2.ev != null) eventsToUpsert.add(ewc2.ev);
                }

                // ---- Deduplicate by External ID (Event_Key__c) to prevent DUPLICATE_VALUE ----
                Map<String, CPR_Event__c> byKey = new Map<String, CPR_Event__c>();
                Integer dupCount = 0;
                for (CPR_Event__c evx : eventsToUpsert) {
                    if (String.isBlank(evx.Event_Key__c)) continue;
                    if (byKey.containsKey(evx.Event_Key__c)) {
                        dupCount++;
                    } else {
                        byKey.put(evx.Event_Key__c, evx);
                    }
                }
                List<CPR_Event__c> deduped = new List<CPR_Event__c>(byKey.values());

                // (Optional) store duplicate count if such a field exists
                try { fr.put('Duplicate_Events_In_Batch__c', dupCount); } catch (Exception ignore) {}

                // ---- Upsert in safe chunks using the External ID field token ----
                Integer created = 0;
                if (!deduped.isEmpty()) {
                    Integer CHUNK_SIZE = 100;
                    List<CPR_Event__c> batchUpsert = new List<CPR_Event__c>();
                    for (CPR_Event__c evx2 : deduped) {
                        batchUpsert.add(evx2);
                        if (batchUpsert.size() == CHUNK_SIZE) {
                            Database.upsert(batchUpsert, CPR_Event__c.Fields.Event_Key__c, /* allOrNone */ false);
                            batchUpsert.clear();
                        }
                    }
                    if (!batchUpsert.isEmpty()) {
                        Database.upsert(batchUpsert, CPR_Event__c.Fields.Event_Key__c, false);
                    }

                    // Count persisted 009 events for this run
                    created = [SELECT count()
                               FROM CPR_Event__c
                               WHERE CPR_File_Run__c = :fr.Id];
                }

                // Finish: persist counts + status
                fr.Record_001_Count__c = cnt001;
                try { fr.put('Event_009_Count__c', created); } catch (Exception ignore) {}
                fr.Status__c = coerceRunStatus('Parsed');
                fr.Notes__c  = 'Events (upserted): ' + String.valueOf(created)
                             + (dupCount > 0 ? ' | Duplicates dropped: ' + dupCount : '');
                update fr;

                r.eventsCreated = created;
                r.message = 'OK';
            } catch (Exception e) {
                // Ensure File Run is marked as failed
                try {
                    if (fr != null && fr.Id != null) {
                        fr.Status__c = coerceRunStatus('Failed');
                        fr.Notes__c  = (fr.Notes__c == null ? '' : fr.Notes__c + ' | ')
                                     + 'Exception: ' + e.getMessage();
                        update fr;
                    }
                } catch (Exception ignore) {}
                r.message = 'Failed: ' + e.getMessage();
                r.eventsCreated = 0;
            }
            out.add(r);
        }
        return out;
    }

    // ---------- Helpers ----------
    private static String coerceRunStatus(String desired) {
        try {
            Schema.DescribeFieldResult d = CPR_File_Run__c.Status__c.getDescribe();
            List<Schema.PicklistEntry> vals = d.getPicklistValues();
            Set<String> allowed = new Set<String>();
            for (Schema.PicklistEntry pe : vals) allowed.add(pe.getValue());
            if (allowed.contains(desired)) return desired;
            if (allowed.contains('Failed')) return 'Failed';
            if (allowed.contains('Error'))  return 'Error';
            if (!vals.isEmpty()) return vals[0].getValue();
            return desired;
        } catch (Exception ignore) {
            return desired;
        }
    }

    private static String safeSub(String s, Integer start, Integer len) {
        try {
            return (s != null && s.length() >= start + len) ? s.substring(start, start+len) : '';
        } catch (Exception e) { return ''; }
    }

    // Hex nibble: safe & fast (no throwing)
    private static Integer hexNibble(String oneHexChar) {
        if (oneHexChar == null || oneHexChar.length() == 0) return 0;
        String h = oneHexChar.substring(0,1);
        if (h >= '0' && h <= '9') return Integer.valueOf(h);
        h = h.toLowerCase();
        String digits = 'abcdef';
        Integer idx = digits.indexOf(h);
        return (idx >= 0) ? (10 + idx) : 0;
    }

    private static String asciiFromBlob(Blob b) {
        // Fast path: valid UTF-8 -> normalize whitespace
        try {
            return b.toString()
                    .replace('\r','')
                    .replace('\t',' ');
        } catch (Exception ex) {
            // Fallback: treat as 8-bit text and keep [0-9A-Za-z -] + LF
            String hex = EncodingUtil.convertToHex(b);
            Integer n = hex.length();
            List<String> parts = new List<String>();
            String buf = '';
            final String DIG = '0123456789';
            final String UPP = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
            final String LOW = 'abcdefghijklmnopqrstuvwxyz';
            for (Integer i = 0; i < n; i += 2) {
                Integer v = (hexNibble(hex.substring(i, i+1)) << 4)
                          +  hexNibble(hex.substring(i+1, i+2));
                if      (v == 10) { buf += '\n'; }              // LF
                else if (v == 13) { /* drop CR */ }
                else if (v == 9 || v == 32) { buf += ' '; }     // TAB/space -> space
                else if (v >= 48 && v <= 57)  { buf += DIG.substring(v-48, v-47); }
                else if (v >= 65 && v <= 90)  { buf += UPP.substring(v-65, v-64); }
                else if (v >= 97 && v <= 122) { buf += LOW.substring(v-97, v-96); }
                else if (v == 45) { buf += '-'; }               // hyphen
                else { buf += ' '; }
                if (buf.length() >= 8192) { parts.add(buf); buf = ''; }
            }
            if (buf != '') parts.add(buf);
            return String.join(parts, '');
        }
    }

    // Decode line fully, preserving common Nordic diacritics and punctuation
    private static String detailFromBlob(Blob b) {
        String hex = EncodingUtil.convertToHex(b);
        String out = '';
        final String DIG = '0123456789';
        final String UPP = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        final String LOW = 'abcdefghijklmnopqrstuvwxyz';
        for (Integer i = 0; i < hex.length(); i += 2) {
            Integer v = (hexNibble(hex.substring(i, i+1)) * 16) + hexNibble(hex.substring(i+1, i+2));
            if (v == 10) { out += '\n'; continue; } // LF
            if (v == 13) { continue; }              // CR -> drop
            if (v == 9 || v == 32) { out += ' '; continue; }
            if (v >= 48 && v <= 57) { out += DIG.substring(v-48, v-47); continue; }
            if (v >= 65 && v <= 90) { out += UPP.substring(v-65, v-64); continue; }
            if (v >= 97 && v <= 122){ out += LOW.substring(v-97, v-96); continue; }
            if (v == 39 || v == 40 || v == 41 || v == 44 || v == 45 || v == 46 ||
                v == 47 || v == 58 || v == 59 || v == 35 || v == 43 || v == 38) {
                out += ((String)String.fromCharArray(new List<Integer>{v})); continue;
            }
            if      (v == 197) { out += 'Å'; continue; }
            else if (v == 198) { out += 'Æ'; continue; }
            else if (v == 216) { out += 'Ø'; continue; }
            else if (v == 229) { out += 'å'; continue; }
            else if (v == 230) { out += 'æ'; continue; }
            else if (v == 248) { out += 'ø'; continue; }
            else if (v == 233) { out += 'é'; continue; }
            else if (v == 201) { out += 'É'; continue; }
            else if (v == 246) { out += 'ö'; continue; }
            else if (v == 214) { out += 'Ö'; continue; }
            else if (v == 252) { out += 'ü'; continue; }
            else if (v == 220) { out += 'Ü'; continue; }
            else if (v == 228) { out += 'ä'; continue; }
            else if (v == 196) { out += 'Ä'; continue; }
            else if (v == 243) { out += 'ó'; continue; }
            else if (v == 211) { out += 'Ó'; continue; }
            else if (v == 225) { out += 'á'; continue; }
            else if (v == 193) { out += 'Á'; continue; }
            out += ' ';
        }
        return out;
    }

    // 009 layout: 0..2='009', 3..12=CPR(10), 13..20=YYYYMMDD, 21..24=HHMM, last 3 = Axx/Pxx
    private static Parsed parseEvent009(String line) {
        Parsed p = new Parsed();
        if (String.isBlank(line)) return p;

        String cpr10 = safeSub(line, 3, 10);
        String ymd   = safeSub(line, 13, 8);
        String hhmm  = safeSub(line, 21, 4);
        String code  = (line.length() >= 3) ? line.substring(line.length() - 3) : null;

        if (cpr10 != null && Pattern.compile('\\d{10}').matcher(cpr10).matches()) p.cpr = cpr10;
        if (code  != null && Pattern.compile('(A\\d{2}|P\\d{2})').matcher(code).matches()) p.eventCode = code;

        if (ymd != null && Pattern.compile('(19|20)\\d{6}').matcher(ymd).matches()) {
            try {
                Integer y = Integer.valueOf(ymd.substring(0,4));
                Integer m = Integer.valueOf(ymd.substring(4,6));
                Integer d = Integer.valueOf(ymd.substring(6,8));
                p.effectiveDate = Date.newInstance(y,m,d);

                Integer hh = 0, mm = 0;
                if (hhmm != null && Pattern.compile('\\d{4}').matcher(hhmm).matches()) {
                    hh = Integer.valueOf(hhmm.substring(0,2));
                    mm = Integer.valueOf(hhmm.substring(2,4));
                }
                p.eventDateTime = Datetime.newInstance(y, m, d, hh, mm, 0);
            } catch (Exception ignore) {}
        }

        if ('A21' == p.eventCode)      p.statusCode = '90';
        else if ('A25' == p.eventCode) p.statusCode = '00';

        return p;
    }

    private static void applyOffsetsToEvent(List<String> detailsPretty, String eventCode, CPR_Event__c ev) {
        if (detailsPretty == null || detailsPretty.isEmpty() || String.isBlank(eventCode)) return;

        Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();
        if (!g.containsKey('CPR_Field_Offset__mdt')) return;

        String q = 'SELECT Event_Code__c, Record_Type__c, Field_API__c, Start__c, Length__c ' +
                   'FROM CPR_Field_Offset__mdt ' +
                   'WHERE Event_Code__c = \'' + String.escapeSingleQuotes(eventCode) + '\' ' +
                   'ORDER BY Record_Type__c, Start__c';
        List<SObject> rows = Database.query(q);
        if (rows.isEmpty()) return;

        Map<String, List<String>> byType = new Map<String, List<String>>{
            '090' => new List<String>(), '091' => new List<String>()
        };
        for (String d : detailsPretty) {
            String t = safeSub(d, 0, 3);
            if (byType.containsKey(t)) byType.get(t).add(d);
        }

        for (SObject r : rows) {
            String recType = (String) r.get('Record_Type__c');
            String fieldApi = (String) r.get('Field_API__c');
            Integer start = 0, len = 0;
            Object sVal = r.get('Start__c'); Object lVal = r.get('Length__c');
            if (sVal != null) start = Integer.valueOf(String.valueOf(sVal));
            if (lVal != null) len   = Integer.valueOf(String.valueOf(lVal));
            if (String.isBlank(recType) || String.isBlank(fieldApi) || len <= 0) continue;

            List<String> pool = byType.get(recType);
            if (pool == null || pool.isEmpty()) continue;
            String line = pool[0];

            String val = safeSub(line, start, len);
            if (val != null) val = val.trim();
            if (!String.isBlank(val)) {
                try { ev.put(fieldApi, val); } catch (Exception e) { /* ignore unknown fields */ }
            }
        }
    }
}