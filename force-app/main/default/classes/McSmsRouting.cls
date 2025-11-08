public with sharing class McSmsRouting {

    // Allow tests to inject in-memory rules (no runtime behavior change)
    @TestVisible static List<McSmsRouting__mdt> TEST_RULES;

    /** Returns the Transactional Definition Key to use for this SMS__c row. */
    public static String resolveDefinitionKey(SMS__c s) {
        String fromNum   = norm(s.From_Number__c);
        String toNum     = norm(s.To_Number__c);
        String cur       = s.CurrencyIsoCode;
        Boolean wantAlpha = (s.Send_From_Alphanumeric_Sender_ID__c == true);

        // Use injected rules in tests; otherwise read org metadata
        List<McSmsRouting__mdt> rules = (TEST_RULES != null)
            ? TEST_RULES
            : [
                SELECT CountryPrefix__c, CurrencyIsoCode__c,
                       DefinitionKey__c, AlphaDefinitionKey__c, IsDefault__c
                FROM McSmsRouting__mdt
              ];

        // 1) Match by From_Number__c country prefix
        for (McSmsRouting__mdt r : rules) {
            if (!String.isBlank(fromNum)
             && !String.isBlank(r.CountryPrefix__c)
             && fromNum.startsWith(r.CountryPrefix__c)) {
                return pick(r, wantAlpha);
            }
        }

        // 2) Match by To_Number__c country prefix
        for (McSmsRouting__mdt r : rules) {
            if (!String.isBlank(toNum)
             && !String.isBlank(r.CountryPrefix__c)
             && toNum.startsWith(r.CountryPrefix__c)) {
                return pick(r, wantAlpha);
            }
        }

        // 3) Match by CurrencyIsoCode
        for (McSmsRouting__mdt r : rules) {
            if (!String.isBlank(cur) && cur == r.CurrencyIsoCode__c) {
                return pick(r, wantAlpha);
            }
        }

        // 4) Fallback to default row
        for (McSmsRouting__mdt r : rules) {
            if (r.IsDefault__c) return pick(r, wantAlpha);
        }
        return null;
    }

    private static String pick(McSmsRouting__mdt r, Boolean alpha) {
        return (alpha && !String.isBlank(r.AlphaDefinitionKey__c))
            ? r.AlphaDefinitionKey__c
            : r.DefinitionKey__c;
    }

    // Normalize to +E.164-ish for prefix checks
    private static String norm(String n) {
        if (String.isBlank(n)) return null;
        String digits = n.replaceAll('[^0-9+]', '');
        if (String.isBlank(digits)) return null;
        return digits.startsWith('+') ? digits : ('+' + digits);
    }
}