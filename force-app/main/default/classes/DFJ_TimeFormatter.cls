public with sharing class DFJ_TimeFormatter {
    @TestVisible static Map<String, Market_Unit_Time_Zone__mdt> TEST_BY_KEY_LOWER;

    public class Request {
        @InvocableVariable(required=true) public Datetime value;
        @InvocableVariable public String marketUnitKey;  // DFJ_DK / FA_SE / Ireland (case-insensitive)
        @InvocableVariable public String timeZoneId;     // Optional override
        @InvocableVariable public String formatKey;      // ISO_8601, EU_24H, US_12H, LONG, SHORT
        @InvocableVariable public String pattern;        // Optional explicit pattern
    }
    public class Response {
        @InvocableVariable public String formatted;     // main output
        @InvocableVariable public String timeOnly;      // "HH:mm" in resolved TZ
        @InvocableVariable public String timeZoneUsed;  // normalized TZ id
        @InvocableVariable public String patternUsed;   // pattern or LONG(localized:<lang>)
    }

    private static final Map<String,String> FORMAT_PATTERNS = new Map<String,String>{
        'ISO_8601' => 'yyyy-MM-dd\'T\'HH:mm:ss',
        'EU_24H'   => 'dd/MM/yyyy HH:mm',
        'US_12H'   => 'MM/dd/yyyy hh:mm a',
        'LONG'     => 'LONG', // handled specially
        'SHORT'    => 'EEE, dd MMM yyyy HH:mm'
    };

    @InvocableMethod(label='Format DateTime (TZ/DST-safe)'
                     description='Formats a Datetime for a specific time zone using IANA IDs (DST-aware).')
    public static List<Response> format(List<Request> inputs) {
        List<Response> out = new List<Response>();
        if (inputs == null || inputs.isEmpty()) return out;

        Set<String> keysRaw = new Set<String>();
        for (Request r : inputs) if (r != null && !String.isBlank(r.marketUnitKey)) keysRaw.add(r.marketUnitKey.trim());

        Map<String, Market_Unit_Time_Zone__mdt> byKeyLower = new Map<String, Market_Unit_Time_Zone__mdt>();
        if (TEST_BY_KEY_LOWER != null) {
            byKeyLower.putAll(TEST_BY_KEY_LOWER);
        } else if (!keysRaw.isEmpty()) {
            for (Market_Unit_Time_Zone__mdt row : [
                SELECT Market_Unit_Key__c, Time_Zone_Id__c, Default_Format_Key__c, Language_Code__c
                FROM Market_Unit_Time_Zone__mdt
                WHERE Market_Unit_Key__c IN :keysRaw
            ]) {
                byKeyLower.put(row.Market_Unit_Key__c == null ? null : row.Market_Unit_Key__c.toLowerCase(), row);
            }
        }

        for (Request r : inputs) {
            Response res = new Response();
            if (r == null || r.value == null) { out.add(res); continue; }

            String tzCandidate = null;
            Market_Unit_Time_Zone__mdt row = null;
            if (!String.isBlank(r.timeZoneId)) {
                tzCandidate = r.timeZoneId.trim();
            } else if (!String.isBlank(r.marketUnitKey)) {
                row = byKeyLower.get(r.marketUnitKey.trim().toLowerCase());
                if (row != null) tzCandidate = row.Time_Zone_Id__c;
            }
            if (String.isBlank(tzCandidate)) tzCandidate = UserInfo.getTimeZone().getID();
            String tz = normalizeTz(tzCandidate);
            res.timeZoneUsed = tz;

            String pattern = null, key = (r.formatKey == null) ? null : r.formatKey.trim();
            if (!String.isBlank(r.pattern)) {
                pattern = r.pattern;
            } else if (!String.isBlank(key) && FORMAT_PATTERNS.containsKey(key)) {
                pattern = FORMAT_PATTERNS.get(key);
            } else if (row != null && !String.isBlank(row.Default_Format_Key__c)
                       && FORMAT_PATTERNS.containsKey(row.Default_Format_Key__c.trim())) {
                pattern = FORMAT_PATTERNS.get(row.Default_Format_Key__c.trim());
            } else {
                pattern = FORMAT_PATTERNS.get('ISO_8601');
            }

            try {
                if ('LONG'.equalsIgnoreCase(pattern)) {
                    String lang = (row != null && !String.isBlank(row.Language_Code__c)) ? row.Language_Code__c.trim() : 'en-IE';
                    res.formatted = buildLongLocalized(r.value, tz, lang);
                    res.patternUsed = 'LONG(localized:' + lang + ')';
                } else {
                    res.formatted = r.value.format(pattern, tz);
                    res.patternUsed = pattern;
                }
                res.timeOnly = r.value.format('HH:mm', tz);
            } catch (Exception e) {
                res.formatted = r.value.format('yyyy-MM-dd\'T\'HH:mm:ss', 'UTC');
                res.timeOnly  = r.value.format('HH:mm', 'UTC');
                res.timeZoneUsed = 'UTC';
                res.patternUsed = 'fallback';
            }

            out.add(res);
        }
        return out;
    }

    // --- Helpers ---

    @TestVisible
    private static String normalizeTz(String tzId) {
        if (String.isBlank(tzId)) return 'UTC';
        try {
            TimeZone z = TimeZone.getTimeZone(tzId);
            if (z == null) return 'UTC';
            String id = z.getID();
            if (String.isBlank(id)) return 'UTC';
            return (id == 'GMT') ? 'UTC' : id;
        } catch (Exception e) {
            return 'UTC';
        }
    }

    // integer floor division helper
    @TestVisible
    private static Integer floorDiv(Integer a, Integer b) {
        Decimal q = Decimal.valueOf(a) / Decimal.valueOf(b);
        return Math.floor(q).intValue();
    }

    // Weekday index (1=Sunday … 7=Saturday) via Zeller’s congruence with integer math
    @TestVisible
    private static Integer weekdayIndex(Integer year, Integer month, Integer day) {
        Integer y = year;
        Integer m = month;
        Integer d = day;
        if (m <= 2) { m += 12; y -= 1; }
        Integer K = Math.mod(y, 100);
        Integer J = floorDiv(y, 100);
        Integer h = Math.mod(
            d
            + floorDiv(13 * (m + 1), 5)
            + K
            + floorDiv(K, 4)
            + floorDiv(J, 4)
            + 5 * J
        , 7);
        // Zeller: 0=Saturday,1=Sunday,...,6=Friday -> convert to 1=Sunday..7=Saturday
        return Math.mod(h + 6, 7) + 1;
    }

    @TestVisible
    private static String buildLongLocalized(Datetime utc, String tz, String lang) {
        Integer year  = Integer.valueOf(utc.format('yyyy', tz));
        Integer month = Integer.valueOf(utc.format('M', tz));
        Integer day   = Integer.valueOf(utc.format('d', tz));
        String hhmm   = utc.format('HH:mm', tz);

        Integer dow = weekdayIndex(year, month, day);
        String lc = (lang == null) ? 'en-IE' : lang.toLowerCase();

        if (lc.startsWith('da')) {
            String weekday  = DA_WEEKDAYS[dow - 1];
            String monthName = DA_MONTHS_CAP[month - 1];
            return weekday + ', d. ' + day + ' ' + monthName + ' ' + year + ', kl. ' + hhmm;
        } else if (lc.startsWith('sv')) {
            String weekday  = SV_WEEKDAYS[dow - 1];
            String monthName = SV_MONTHS[month - 1];
            return weekday + ' den ' + day + ' ' + monthName + ' ' + year + ' kl. ' + hhmm;
        } else {
            String weekday  = EN_WEEKDAYS[dow - 1];
            String monthName = EN_MONTHS[month - 1];
            return weekday + ', ' + day + ' ' + monthName + ' ' + year + ', ' + hhmm;
        }
    }

    private static final List<String> DA_WEEKDAYS = new List<String>{
        'søndag','mandag','tirsdag','onsdag','torsdag','fredag','lørdag'
    };
    private static final List<String> SV_WEEKDAYS = new List<String>{
        'söndag','måndag','tisdag','onsdag','torsdag','fredag','lördag'
    };
    private static final List<String> EN_WEEKDAYS = new List<String>{
        'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'
    };

    private static final List<String> DA_MONTHS_CAP = new List<String>{
        'Januar','Februar','Marts','April','Maj','Juni','Juli','August','September','Oktober','November','December'
    };
    private static final List<String> SV_MONTHS = new List<String>{
        'januari','februari','mars','april','maj','juni','juli','augusti','september','oktober','november','december'
    };
    private static final List<String> EN_MONTHS = new List<String>{
        'January','February','March','April','May','June','July','August','September','October','November','December'
    };
}