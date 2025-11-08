public with sharing class CPROutbound06Exporter {

    public class Req {
        @InvocableVariable(required=false) public Id batchId;
    }
    public class Res {
        @InvocableVariable public Id batchId;
        @InvocableVariable public Integer lines;
        @InvocableVariable public String message;
        @InvocableVariable public Id contentVersionId;
    }

    @InvocableMethod(label='CPR Export inddata 06')
    public static List<Res> run(List<Req> reqs) {
        List<Res> out = new List<Res>();
        for (Req r : reqs) {
            Res rr = new Res();
            CPR_Outbound_Batch__c b = null;
            try {
                // --- Settings (CMDT) ---
                String og = '000000'; // Opgavenummer (6)
                String nk = '';       // Nøglekonstant (15, optional)
                if (Schema.getGlobalDescribe().containsKey('CPR_Outbound_06_Setting__mdt')) {
                    List<SObject> rows = Database.query(
                        'SELECT Opgavenummer__c, Noeglekonstant__c FROM CPR_Outbound_06_Setting__mdt LIMIT 1'
                    );
                    if (!rows.isEmpty()) {
                        SObject s = rows[0];
                        String ogx = (String)s.get('Opgavenummer__c');
                        String nkx = (String)s.get('Noeglekonstant__c');
                        if (!String.isBlank(ogx)) og = onlyDigits(ogx);
                        if (!String.isBlank(nkx)) nk = nkx;
                    }
                }

                // --- Batch ---
                if (r.batchId == null) {
                    Date fd = Date.today();
                    b = new CPR_Outbound_Batch__c(
                        File_Name__c = fileName06(og, fd),
                        File_Date__c = fd,
                        Status__c = 'New'
                    );
                    insert b;
                } else {
                    b = [
                        SELECT Id, File_Name__c, File_Date__c, Status__c, Notes__c
                        FROM CPR_Outbound_Batch__c
                        WHERE Id = :r.batchId LIMIT 1
                    ];
                    if (String.isBlank(b.File_Name__c)) {
                        Date fd = (b.File_Date__c == null ? Date.today() : b.File_Date__c);
                        b.File_Name__c = fileName06(og, fd);
                        update b;
                    }
                }
                rr.batchId = b.Id;

                // --- Queue ---
                List<CPR_Subscription_Add__c> q = [
                SELECT Id, Name, CPR__c, Operation__c
                FROM CPR_Subscription_Add__c
                WHERE (Status__c IN ('Queued','New')) AND (Outbound_Batch__c = NULL)
                ORDER BY CreatedDate ASC
                LIMIT 5000
                ];
                if (q.isEmpty()) {
                    b.Status__c = 'Failed';
                    b.Notes__c = 'No queued CPRs to export.';
                    update b;
                    rr.message = 'No rows';
                    out.add(rr);
                    continue;
                }

                // --- Build lines ---
                List<String> lines = new List<String>();
                List<CPR_Subscription_Add__c> included = new List<CPR_Subscription_Add__c>();
                List<CPR_Subscription_Add__c> failedInvalid = new List<CPR_Subscription_Add__c>();
                List<String> failedNames = new List<String>();
                Integer opCount = 0, slCount = 0;

                Boolean hasOperationField = hasOperationPicklist();

                for (CPR_Subscription_Add__c row : q) {
                    String cpr = onlyDigits(row.CPR__c);
                    if (cpr.length() != 10) {
                        row.Status__c = 'Failed';
                        failedInvalid.add(row);
                        failedNames.add(row.Name);
                        continue;
                    }
                    String opSl = (hasOperationField ? opFromRow(row) : 'OP');
                    if ('SL' == opSl) slCount++; else opCount++;
                    lines.add(build80_06(og, opSl, cpr, nk));
                    included.add(row);
                }

                if (included.isEmpty()) {
                    if (!failedInvalid.isEmpty()) update failedInvalid;
                    b.Status__c = 'Failed';
                    b.Notes__c = 'No valid CPR (10 digits) found. Skipped invalid: ' + failedInvalid.size();
                    update b;
                    rr.message = 'No valid CPR';
                    out.add(rr);
                    continue;
                }

                // Breadcrumb
                String head20 = lines[0].substring(0, Math.min(20, lines[0].length()));
                String notes = 'Lines: ' + included.size()
                    + ' | OP=' + opCount + ', SL=' + slCount
                    + ' | HEAD20=' + head20
                    + ' | Upload dir: /ind';
                if (!failedInvalid.isEmpty()) {
                    notes += ' | Skipped invalid CPR: ' + failedInvalid.size() + ' (' + String.join(failedNames, ', ') + ')';
                }
                b.Notes__c = notes;
                update b;

                String body = String.join(lines, '\n') + '\n';

                // File
                ContentVersion cv = new ContentVersion(
                    Title = b.File_Name__c,
                    PathOnClient = b.File_Name__c,
                    VersionData = Blob.valueOf(body)
                );
                insert cv;
                rr.contentVersionId = cv.Id;

                // Link file to batch
                ContentDocumentLink cdl = new ContentDocumentLink(
                    ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
                    LinkedEntityId = b.Id,
                    ShareType = 'V'
                );
                insert cdl;

                // Update rows
                if (!failedInvalid.isEmpty()) update failedInvalid;
                for (CPR_Subscription_Add__c row : included) {
                    row.Outbound_Batch__c = b.Id;
                    row.Status__c = 'Exported';
                }
                update included;

                b.Status__c = 'Generated';
                update b;

                rr.lines = included.size();
                rr.message = 'OK';

            } catch (Exception e) {
                if (b != null) {
                    try {
                        b.Status__c = 'Failed';
                        b.Notes__c = (b.Notes__c == null ? '' : b.Notes__c + ' | ') + 'Error: ' + e.getMessage();
                        update b;
                    } catch (Exception ignore) {}
                }
                rr.message = 'Failed: ' + e.getMessage();
            }
            out.add(rr);
        }
        return out;
    }

    // ---------- Helpers ----------

    private static Boolean hasOperationPicklist() {
        try {
            Schema.DescribeSObjectResult d = CPR_Subscription_Add__c.SObjectType.getDescribe();
            return d != null && d.fields.getMap().containsKey('Operation__c');
        } catch (Exception e) {
            return false;
        }
    }

    private static String opFromRow(CPR_Subscription_Add__c row) {
        try {
            // Only call when hasOperationPicklist() == true
            Object val = row.get('Operation__c');
            if (val == null) return 'OP';
            String s = String.valueOf(val).trim().toUpperCase();
            return (s == 'SL') ? 'SL' : 'OP';
        } catch (Exception e) {
            return 'OP';
        }
    }

    // 06 layout
    private static String build80_06(String opgavenr6, String opSl, String cpr, String noegle) {
        String kdn = kundenrFromOpgave(opgavenr6);
        String left =
            '06' +
            padLeft(onlyDigits(kdn), 4, '0') +
            '00' +
            (String.isBlank(opSl) ? 'OP' : opSl) +
            padLeft(onlyDigits(cpr), 10, '0') +
            padRight(noegle == null ? '' : noegle, 15);
        return padRight(left, 80);
    }

    private static String kundenrFromOpgave(String og6) {
        String d = onlyDigits(og6);
        if (String.isBlank(d)) d = '000000';
        if (d.length() < 6) d = padLeft(d, 6, '0');
        return d.substring(0, 4);
    }

    private static String fileName06(String opgavenr6, Date d) {
        String og = onlyDigits(opgavenr6);
        if (String.isBlank(og)) og = '000000';
        if (og.length() < 6) og = padLeft(og, 6, '0');
        return 'd' + yymmdd(d) + '.i' + og;
    }

    private static String yymmdd(Date d) {
        String yy = String.valueOf(d.year()).substring(2, 4);
        return yy + pad2(d.month()) + pad2(d.day());
    }
    private static String pad2(Integer n) {
        if (n == null) return '00';
        return (n < 10 ? '0' : '') + String.valueOf(n);
    }
    private static String onlyDigits(String x) { return x == null ? '' : x.replaceAll('\\D',''); }
    private static String padLeft(String v, Integer len, String ch) { if (v == null) v = ''; while (v.length() < len) v = ch + v; return (v.length() > len ? v.substring(0, len) : v); }
    private static String padRight(String v, Integer len) { if (v == null) v = ''; while (v.length() < len) v += ' '; return (v.length() > len ? v.substring(0, len) : v); }
}