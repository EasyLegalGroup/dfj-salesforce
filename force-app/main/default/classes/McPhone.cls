public with sharing class McPhone {
    public class Norm {
        public String digits;     // digits-only MSISDN to send to SFMC
        public Boolean dkOk;      // kept for backwards compat; true when sanity passes
        public String warning;    // populated if sanity fails
        public String country;    // 'DK' / 'SE' / other
    }

    /** Remove all non-digits. For DK:
     *  - If starts with 0045, convert to 45...
     *  - If length is 8, prefix 45
     *  - Final sanity: starts with 45 and length 10 (no '+')
     */
    public static Norm normalizeDK(String raw) {
        Norm out = new Norm();
        out.country = 'DK';

        if (String.isBlank(raw)) {
            out.digits = null;
            out.dkOk = false;
            out.warning = 'Blank input';
            return out;
        }

        String digits = raw.replaceAll('[^0-9]', '');

        if (String.isBlank(digits)) {
            out.digits = null;
            out.dkOk = false;
            out.warning = 'No digits found';
            return out;
        }

        if (digits.startsWith('0045') && digits.length() >= 4) {
            digits = '45' + digits.substring(4);
        }

        if (digits.length() == 8) {
            digits = '45' + digits;
        }

        Boolean ok = (digits.startsWith('45') && digits.length() == 10);
        out.digits = digits;
        out.dkOk   = ok;
        out.warning = ok ? null : 'DK sanity check failed (expect 45 + 8 digits)';

        return out;
    }

    /** Sweden rules (pragmatic, covers common real-world inputs):
     *  - Strip non-digits.
     *  - 0046…  -> 46…
     *  - +46…   -> 46…  (handled by strip +)
     *  - 0XXXXXXXXX (national) -> 46 + XXXXXXXXX (drop leading 0)
     *  - Final sanity: starts with 46 and length between 10 and 12 (most mobiles: 11)
     */
    public static Norm normalizeSE(String raw) {
        Norm out = new Norm();
        out.country = 'SE';

        if (String.isBlank(raw)) {
            out.digits = null;
            out.dkOk = false;
            out.warning = 'Blank input';
            return out;
        }

        String digits = raw.replaceAll('[^0-9]', '');
        if (String.isBlank(digits)) {
            out.digits = null;
            out.dkOk = false;
            out.warning = 'No digits found';
            return out;
        }

        if (digits.startsWith('0046') && digits.length() >= 4) {
            digits = '46' + digits.substring(4);
        } else if (digits.startsWith('46')) {
            // already good
        } else if (digits.startsWith('0') && digits.length() >= 2) {
            // Drop leading 0, prefix country
            digits = '46' + digits.substring(1);
        }
        // else: if admin typed pure national without 0 (rare), we leave as-is

        Boolean ok = (digits.startsWith('46') && digits.length() >= 10 && digits.length() <= 12);
        out.digits  = digits;
        out.dkOk    = ok; // keep same flag name; true means "sanity ok"
        out.warning = ok ? null : 'SE sanity check failed (expect starts with 46 and reasonable length)';

        return out;
    }

    /** Ireland rules:
     *  - Strip non-digits.
     *  - 00353… -> 353…
     *  - +353… -> 353… (handled by strip +)
     *  - 0XXXXXXXXX (national) -> 353 + XXXXXXXXX (drop leading 0)
     *  - Final sanity: starts with 353 and length between 12 and 13
     */
    public static Norm normalizeIE(String raw) {
        Norm out = new Norm();
        out.country = 'IE';

        if (String.isBlank(raw)) {
            out.digits = null;
            out.dkOk = false;
            out.warning = 'Blank input';
            return out;
        }

        String digits = raw.replaceAll('[^0-9]', '');
        if (String.isBlank(digits)) {
            out.digits = null;
            out.dkOk = false;
            out.warning = 'No digits found';
            return out;
        }

        if (digits.startsWith('00353') && digits.length() >= 5) {
            digits = '353' + digits.substring(5);
        } else if (digits.startsWith('353')) {
            // already good
        } else if (digits.startsWith('0') && digits.length() >= 2) {
            // Drop leading 0, prefix country
            digits = '353' + digits.substring(1);
        }

        Boolean ok = (digits.startsWith('353') && digits.length() >= 12 && digits.length() <= 13);
        out.digits = digits;
        out.dkOk = ok;
        out.warning = ok ? null : 'IE sanity check failed (expect starts with 353 and reasonable length)';

        return out;
    }

    /** Country-aware normalize. */
    public static Norm normalize(String raw, String countryIso2) {
        if (countryIso2 == 'DK') return normalizeDK(raw);
        if (countryIso2 == 'SE') return normalizeSE(raw);
        if (countryIso2 == 'IE') return normalizeIE(raw);

        Norm out = new Norm();
        out.country = countryIso2;
        if (String.isBlank(raw)) {
            out.digits = null;
            out.dkOk = false;
            out.warning = 'Blank input';
            return out;
        }
        String digits = raw.replaceAll('[^0-9]', '');
        out.digits = digits;
        out.dkOk = true; // non-DK/SE/IE path is not validated here
        out.warning = null;
        return out;
    }
}