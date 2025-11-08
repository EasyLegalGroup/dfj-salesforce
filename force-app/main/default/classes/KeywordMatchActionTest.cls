@IsTest
private class KeywordMatchActionTest {
    private static KeywordMatchAction.Input inp(String body, String keywords) {
        KeywordMatchAction.Input i = new KeywordMatchAction.Input();
        i.body = body; i.keywords = keywords; return i;
    }

    @IsTest
    static void returnsAllMatchesInBodyOrder_CaseInsensitive() {
        // Example: keywords "Ja, nej, måske, hjælp, stop"
        // Body has Stop, måske, hjælp (in that order, mixed case)
        List<KeywordMatchAction.Input> ins = new List<KeywordMatchAction.Input>{
            inp('Stop, måske skal jeg have hjælp', 'Ja;nej;måske;hjælp;stop'),
            inp('JA og derefter Nej.', 'Ja;Nej')
        };

        Test.startTest();
        List<KeywordMatchAction.Output> outs = KeywordMatchAction.run(ins);
        Test.stopTest();

        System.assertEquals(3, outs[0].matchedKeywords.size());
        System.assertEquals('stop',   outs[0].matchedKeywords[0]);
        System.assertEquals('måske',  outs[0].matchedKeywords[1]);
        System.assertEquals('hjælp',  outs[0].matchedKeywords[2]);

        System.assertEquals(2, outs[1].matchedKeywords.size());
        System.assertEquals('Ja', outs[1].matchedKeywords[0]);
        System.assertEquals('Nej', outs[1].matchedKeywords[1]);
    }

    @IsTest
    static void doesNotMatchSubstrings_OnlyWholeWords() {
        List<KeywordMatchAction.Input> ins = new List<KeywordMatchAction.Input>{
            inp('Januar er kold', 'ja;nej'),        // "ja" inside "Januar" → no
            inp('okay-ja-videre', 'ja'),            // hyphen creates boundary → yes
            inp('okayja videre', 'ja'),             // no boundary → no
            inp('nejtak men okay', 'nej')           // "nej" in "nejtak" → no
        };
        List<KeywordMatchAction.Output> outs = KeywordMatchAction.run(ins);

        System.assertEquals(0, outs[0].matchedKeywords.size());
        System.assertEquals(new List<String>{'ja'}, outs[1].matchedKeywords);
        System.assertEquals(0, outs[2].matchedKeywords.size());
        System.assertEquals(0, outs[3].matchedKeywords.size());
    }

    @IsTest
    static void uniqueMatches_NoDuplicates() {
        List<KeywordMatchAction.Input> ins = new List<KeywordMatchAction.Input>{
            inp('ja JA ja, stadig ja.', 'ja')
        };
        List<KeywordMatchAction.Output> outs = KeywordMatchAction.run(ins);

        System.assertEquals(1, outs[0].matchedKeywords.size());
        System.assertEquals('ja', outs[0].matchedKeywords[0]);
    }

    @IsTest
    static void handlesNullAndBlankInputs() {
        List<KeywordMatchAction.Input> ins = new List<KeywordMatchAction.Input>{
            inp(null, 'Ja;Nej'),
            inp('ja', null),
            inp('', ' ;  ;  ')
        };
        List<KeywordMatchAction.Output> outs = KeywordMatchAction.run(ins);

        System.assertEquals(0, outs[0].matchedKeywords.size());
        System.assertEquals(0, outs[1].matchedKeywords.size());
        System.assertEquals(0, outs[2].matchedKeywords.size());
    }
}