public with sharing class KeywordMatchAction {
    public class Input {
        @InvocableVariable(required=true) public String body;
        @InvocableVariable(required=true) public String keywords; // "Ja;Nej;..."
    }
    public class Output {
        @InvocableVariable public List<String> matchedKeywords;
    }

    @InvocableMethod(label='Find All Keyword Matches')
    public static List<Output> run(List<Input> inputs){
        List<Output> outs = new List<Output>();
        for (Input i : inputs){
            String body = i.body == null ? '' : i.body;
            // Build canonical list from semicolon-separated keywords
            List<String> rawKs = (i.keywords == null ? '' : i.keywords).split(';');
            List<String> ks = new List<String>();
            for (String k : rawKs) {
                if (!String.isBlank(k)) ks.add(k.trim());
            }
            Output o = new Output();
            o.matchedKeywords = new List<String>();
            if (ks.isEmpty()) { outs.add(o); continue; }

            // Map lowercase -> canonical keyword (to preserve provided casing)
            Map<String,String> canon = new Map<String,String>();
            List<String> parts = new List<String>();
            for (String k : ks){
                String canonKey = k.toLowerCase();
                canon.put(canonKey, k);
                parts.add(Pattern.quote(k));
            }

            // Unicode-safe word boundaries: (?<!\p{L}) and (?!\p{L})
            String regex = '(?i)(?<!\\p{L})(' + String.join(parts, '|') + ')(?!\\p{L})';
            Matcher m = Pattern.compile(regex).matcher(body);

            // Collect unique matches in the ORDER THEY APPEAR in the body
            Set<String> seen = new Set<String>();
            while (m.find()){
                String hit = m.group();               // Matched text as it appears
                String key = hit == null ? '' : hit.toLowerCase();
                if (canon.containsKey(key) && !seen.contains(key)){
                    o.matchedKeywords.add(canon.get(key));
                    seen.add(key);
                }
            }

            outs.add(o);
        }
        return outs;
    }
}