/**
 * SMSSegmentUtil
 * ----------------
 * Analyzes SMS text for GSM 03.38 basic/extended vs UCS-2 (Unicode) and computes segment usage.
 */
public with sharing class SMSSegmentUtil {

    public enum Encoding { GSM_7, GSM_7_EXTENDED, UCS_2 }

    public class AnalysisResult {
        public Encoding encoding;
        public Integer segments;
        public Integer gsmBasicCount;
        public Integer gsmExtendedCount;
        public Integer unicodeCount;
        public Integer messageUnits;     // septets (GSM) or code points (UCS-2)
        public Integer perSegmentLimit;  // 160/153 or 70/67
        public Map<String,String> costly = new Map<String,String>();
    }

    // --------- Configuration & character tables ---------

    private static final String BASIC_CHARS_LITERAL =
        '@£$¥èéùìòÇ' +
        '\r' + '\n' + // CR, LF
        'ØøÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ ' +
        '!"#¤%&\'()*+,-./' +
        '0123456789:;<=>?' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§' +
        'abcdefghijklmnopqrstuvwxyzäöñüà';

    private static final String EXTENDED_CHARS_LITERAL = '^{}\\[~]|€';
    private static final String DANISH_EXTENDED_LITERAL = 'æøåÆØÅ';

    private static Set<Integer> FORCE_UCS2_SET = new Set<Integer>();
    private static Boolean SETTINGS_LOADED = false;

    private static final Set<Integer> BASIC_SET;
    private static final Set<Integer> EXTENDED_SET;
    private static final Set<Integer> DANISH_EXTENDED_SET;

    static {
        BASIC_SET = cpSetFromString(BASIC_CHARS_LITERAL);
        EXTENDED_SET = cpSetFromString(EXTENDED_CHARS_LITERAL);
        DANISH_EXTENDED_SET = cpSetFromString(DANISH_EXTENDED_LITERAL);

        // Shift Danish letters to extended per business rule
        BASIC_SET.removeAll(DANISH_EXTENDED_SET);
        EXTENDED_SET.addAll(DANISH_EXTENDED_SET);
    }

    // --------- Public API ---------

    public static AnalysisResult analyze(String message) {
        AnalysisResult res = new AnalysisResult();
        if (message == null || message == '') {
            res.encoding = null; res.segments = 0; res.gsmBasicCount = 0; res.gsmExtendedCount = 0;
            res.unicodeCount = 0; res.messageUnits = 0; res.perSegmentLimit = 0;
            return res;
        }

        ensureSettingsLoaded();

        String cleaned = trimTrailingCrLf(message);

        Integer basicCount = 0, extCount = 0, uniCount = 0;
        Integer unitsGsm = 0, totalCodePoints = 0;

        Map<Integer,Integer> extendedCounts = new Map<Integer,Integer>();
        Map<Integer,Integer> unicodeCounts  = new Map<Integer,Integer>();

        Boolean hasUnicode = false, hasExtended = false;

        for (Integer cp : codePoints(cleaned)) {
            totalCodePoints++;

            if (FORCE_UCS2_SET.contains(cp)) {
                hasUnicode = true;
                uniCount++;
                unicodeCounts.put(cp, (unicodeCounts.containsKey(cp) ? unicodeCounts.get(cp) : 0) + 1);
                continue;
            }

            if (isGsmBasic(cp)) {
                basicCount++; unitsGsm += 1;               // 1 septet
            } else if (isGsmExtended(cp)) {
                extCount++;  hasExtended = true; unitsGsm += 2; // escape + char
                extendedCounts.put(cp, (extendedCounts.containsKey(cp) ? extendedCounts.get(cp) : 0) + 1);
            } else {
                hasUnicode = true;
                uniCount++;
                unicodeCounts.put(cp, (unicodeCounts.containsKey(cp) ? unicodeCounts.get(cp) : 0) + 1);
            }
        }

        Encoding enc; Integer units;
        if (hasUnicode) {
            enc = Encoding.UCS_2;        units = totalCodePoints;
        } else if (hasExtended) {
            enc = Encoding.GSM_7_EXTENDED; units = unitsGsm;
        } else {
            enc = Encoding.GSM_7;        units = unitsGsm;
        }

        res.encoding = enc;
        res.gsmBasicCount = basicCount;
        res.gsmExtendedCount = extCount;
        res.unicodeCount = uniCount;
        res.messageUnits = units;

        Integer singleLimit = (enc == Encoding.UCS_2) ? 70 : 160;
        Integer concatLimit = (enc == Encoding.UCS_2) ? 67 : 153;
        res.perSegmentLimit = (units <= singleLimit && units > 0) ? singleLimit : (units > 0 ? concatLimit : 0);
        res.segments = countSegments(enc, units);

        if (enc == Encoding.UCS_2) {
            for (Integer cp : unicodeCounts.keySet()) {
                String ch = fromCodePoint(cp);
                Integer c  = unicodeCounts.get(cp);
                res.costly.put(ch, '×' + String.valueOf(c) + ' → non-GSM (UCS-2)');
            }
        } else if (enc == Encoding.GSM_7_EXTENDED) {
            for (Integer cp : extendedCounts.keySet()) {
                String ch = fromCodePoint(cp);
                Integer c = extendedCounts.get(cp);
            res.costly.put(ch, '×' + String.valueOf(c) + ' → 2 septets (extended)');
            }
        }
        return res;
    }

    public static Integer countSegments(Encoding enc, Integer unitCount) {
        if (unitCount == null || unitCount == 0) return 0;
        Integer singleLimit = (enc == Encoding.UCS_2) ? 70 : 160;
        Integer concatLimit = (enc == Encoding.UCS_2) ? 67 : 153;
        if (unitCount <= singleLimit) return 1;
        return (Integer)Math.ceil((Decimal)unitCount / concatLimit);
    }

    // --------- Classification ---------

    private static Boolean isGsmBasic(Integer cp)   { return BASIC_SET.contains(cp); }
    private static Boolean isGsmExtended(Integer cp){ return EXTENDED_SET.contains(cp); }
    private static Boolean isUnicode(Integer cp)    { return !isGsmBasic(cp) && !isGsmExtended(cp); }

    // --------- UTF-8 → code points (Apex-safe, O(n)) ---------

    private static List<Integer> codePoints(String s) {
        if (s == null || s == '') return new List<Integer>();
        Blob b = Blob.valueOf(s); // UTF-8 bytes
        String hex = EncodingUtil.convertToHex(b); // 2 hex chars per byte
        Integer totalBytes = hex.length() / 2;
        Integer i = 0;
        List<Integer> cps = new List<Integer>();

        while (i < totalBytes) {
            Integer b1 = readByte(hex, i++);

            if (b1 < 128) { // 0x80
                cps.add(b1);
                continue;
            }
            // 2-byte: 110xxxxx
            if ((b1 & 224) == 192 && i + 1 <= totalBytes) { // 0xE0, 0xC0
                Integer b2 = readByte(hex, i++);
                Integer cp = ((b1 & 31) << 6) | (b2 & 63); // 0x1F, 0x3F
                cps.add(cp);
                continue;
            }
            // 3-byte: 1110xxxx
            if ((b1 & 240) == 224 && i + 2 <= totalBytes) { // 0xF0, 0xE0
                Integer b2 = readByte(hex, i++);
                Integer b3 = readByte(hex, i++);
                Integer cp = ((b1 & 15) << 12) | ((b2 & 63) << 6) | (b3 & 63); // 0x0F, 0x3F
                cps.add(cp);
                continue;
            }
            // 4-byte: 11110xxx
            if ((b1 & 248) == 240 && i + 3 <= totalBytes) { // 0xF8, 0xF0
                Integer b2 = readByte(hex, i++);
                Integer b3 = readByte(hex, i++);
                Integer b4 = readByte(hex, i++);
                Integer cp = ((b1 & 7) << 18) | ((b2 & 63) << 12) | ((b3 & 63) << 6) | (b4 & 63); // 0x07, 0x3F
                cps.add(cp);
                continue;
            }
            // Fallback (replacement char U+FFFD)
            cps.add(65533); // 0xFFFD
        }
        return cps;
    }

    /** Convert a single code point to a Java/Apex String by constructing its UTF-8 bytes. */
    private static String fromCodePoint(Integer cp) {
        List<Integer> bytes = new List<Integer>();
        if (cp <= 127) { // 0x7F
            bytes.add(cp);
        } else if (cp <= 2047) { // 0x7FF
            bytes.add(192 | (cp >> 6));          // 0xC0
            bytes.add(128 | (cp & 63));          // 0x80, 0x3F
        } else if (cp <= 65535) { // 0xFFFF
            bytes.add(224 | (cp >> 12));         // 0xE0
            bytes.add(128 | ((cp >> 6) & 63));   // 0x80, 0x3F
            bytes.add(128 | (cp & 63));          // 0x80, 0x3F
        } else {
            bytes.add(240 | (cp >> 18));         // 0xF0
            bytes.add(128 | ((cp >> 12) & 63));  // 0x80
            bytes.add(128 | ((cp >> 6) & 63));   // 0x80
            bytes.add(128 | (cp & 63));          // 0x80
        }
        String hex = '';
        for (Integer b : bytes) hex += toHexByte(b);
        Blob bl = EncodingUtil.convertFromHex(hex);
        return bl.toString();
    }

    // --------- Helpers ---------

    private static Set<Integer> cpSetFromString(String s) {
        Set<Integer> result = new Set<Integer>();
        for (Integer cp : codePoints(s)) {
            result.add(cp);
        }
        return result;
    }

    private static String trimTrailingCrLf(String s) {
        if (s == null || s == '') return s;
        Integer endPos = s.length();
        while (endPos > 0) {
            String last = s.substring(endPos - 1, endPos);
            if (last == '\n' || last == '\r') endPos--;
            else break;
        }
        return (endPos == s.length()) ? s : s.substring(0, endPos);
    }

    private static Integer readByte(String hex, Integer byteIndex) {
        Integer pos = byteIndex * 2;
        return (hexDigit(hex.substring(pos, pos + 1)) << 4)
             | (hexDigit(hex.substring(pos + 1, pos + 2)));
    }

    private static Integer hexDigit(String c) {
        if (c == '0') return 0; if (c == '1') return 1; if (c == '2') return 2; if (c == '3') return 3;
        if (c == '4') return 4; if (c == '5') return 5; if (c == '6') return 6; if (c == '7') return 7;
        if (c == '8') return 8; if (c == '9') return 9;
        if (c == 'A' || c == 'a') return 10;
        if (c == 'B' || c == 'b') return 11;
        if (c == 'C' || c == 'c') return 12;
        if (c == 'D' || c == 'd') return 13;
        if (c == 'E' || c == 'e') return 14;
        if (c == 'F' || c == 'f') return 15;
        return 0;
    }

    private static String toHexByte(Integer b) {
        String digits = '0123456789ABCDEF';
        Integer hi = (b >> 4) & 15; // 0x0F
        Integer lo = b & 15;
        return digits.substring(hi, hi+1) + digits.substring(lo, lo+1);
    }

    /**
     * Lazy-load optional metadata:
     *  - Object: SMS_Encoding_Settings__mdt
     *  - Fields: Treat_Danish_As_Extended__c (Checkbox), Force_UCS2_Chars__c (Text)
     */
    private static void ensureSettingsLoaded() {
        if (SETTINGS_LOADED == true) return;
        SETTINGS_LOADED = true;

        FORCE_UCS2_SET.clear();
        try {
            List<SObject> rows = Database.query(
                'SELECT Treat_Danish_As_Extended__c, Force_UCS2_Chars__c FROM SMS_Encoding_Settings__mdt LIMIT 1'
            );
            if (!rows.isEmpty()) {
                SObject rec = rows[0];
                Object forceChars = rec.get('Force_UCS2_Chars__c');

                if (forceChars != null) {
                    String s = String.valueOf(forceChars);
                    for (Integer cp : codePoints(s)) {
                        // ignore commas, spaces, CR/LF so admins can paste comma-separated lists
                        if (cp != 44 && cp != 32 && cp != 10 && cp != 13) {
                            FORCE_UCS2_SET.add(cp);
                        }
                    }
                }
            }
        } catch (Exception e) {
            // No metadata available; ignore.
        }
    }
}