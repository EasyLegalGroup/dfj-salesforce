public with sharing class SMSTriggerHandler {
    /**
     * before insert / update: calculate segments and encoding if Message__c is present and changed.
     */
    public static void beforeUpsert(List<SMS__c> newList, Map<Id, SMS__c> oldMap) {
        for (SMS__c row : newList) {
            // Null or empty message: clear fields
            if (row.Message__c == null || row.Message__c == '') {
                row.Segments__c = 0;
                row.Encoding__c = null;
                row.Non_Standard_Characters__c = null;
                continue;
            }
            // Only reanalyze if Message__c changed on update
            if (oldMap != null && oldMap.containsKey(row.Id)) {
                SMS__c oldRow = oldMap.get(row.Id);
                if (oldRow != null && oldRow.Message__c == row.Message__c) {
                    continue; // unchanged
                }
            }
            SMSSegmentUtil.AnalysisResult res = SMSSegmentUtil.analyze(row.Message__c);

            row.Segments__c = res.segments;

            if (res.encoding == SMSSegmentUtil.Encoding.GSM_7) {
                row.Encoding__c = 'GSM_7';
            } else if (res.encoding == SMSSegmentUtil.Encoding.GSM_7_EXTENDED) {
                row.Encoding__c = 'GSM_7_Extended';
            } else if (res.encoding == SMSSegmentUtil.Encoding.UCS_2) {
                row.Encoding__c = 'UCS-2';
            } else {
                row.Encoding__c = null;
            }

            if (!res.costly.isEmpty()) {
                List<String> parts = new List<String>();
                for (String ch : res.costly.keySet()) {
                    parts.add(formatCostlyEntry(ch, res.costly.get(ch)));
                }
                row.Non_Standard_Characters__c = String.join(parts, '; ');
            } else {
                row.Non_Standard_Characters__c = null;
            }
        }
    }

    private static String formatCostlyEntry(String ch, String reason) {
        // Prefer "x" for control or non-printable; otherwise print char directly.
        String printable = ch;
        if (ch == '\r') printable = '\\r';
        if (ch == '\n') printable = '\\n';
        return printable + ' ' + reason;
    }
}