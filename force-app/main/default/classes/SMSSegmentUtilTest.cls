@IsTest
private class SMSSegmentUtilTest {

    @IsTest
    static void testPureGsmUnder160() {
        String msg = 'Hello world! 0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        SMSSegmentUtil.AnalysisResult res = SMSSegmentUtil.analyze(msg);
        System.assertEquals(SMSSegmentUtil.Encoding.GSM_7, res.encoding);
        System.assertEquals(1, res.segments);
        System.assertEquals(0, res.unicodeCount);
        System.assert(res.messageUnits > 0, 'Units should be > 0');
        System.assertEquals(160, res.perSegmentLimit);
    }

    @IsTest
    static void testGsmExtendedSinglePart() {
        // Contains { } \ [ ] | ^ ~ and €
        String msg = 'Curly {braces} and backslash \\ square [brackets] pipe | caret ^ tilde ~ and euro €';
        SMSSegmentUtil.AnalysisResult res = SMSSegmentUtil.analyze(msg);
        System.assertEquals(SMSSegmentUtil.Encoding.GSM_7_EXTENDED, res.encoding);
        System.assertEquals(1, res.segments, 'Should still fit in one GSM part');
        System.assert(res.gsmExtendedCount > 0, 'Must count extended characters');
        System.assertEquals(160, res.perSegmentLimit, 'Single-part limit still 160 (units may be < 160)');
    }

    @IsTest
    static void testGsmConcatenated153Rule() {
        // Build 161 basic GSM chars to force concatenation (2 segments with limit 153)
        String msg = '';
        for (Integer i=0; i<161; i++) msg += 'A';
        SMSSegmentUtil.AnalysisResult res = SMSSegmentUtil.analyze(msg);
        System.assertEquals(SMSSegmentUtil.Encoding.GSM_7, res.encoding);
        System.assertEquals(2, res.segments, '161 septets -> 2 segments at 153/segment');
        System.assertEquals(153, res.perSegmentLimit);
    }

    @IsTest
    static void testDanishLettersAsExtended() {
        // Danish letters should be treated as extended (2 septets), not UCS-2
        String msg = 'Smørrebrød med ål og ÆBLE: æøå ÆØÅ';
        SMSSegmentUtil.AnalysisResult res = SMSSegmentUtil.analyze(msg);
        System.assertEquals(SMSSegmentUtil.Encoding.GSM_7_EXTENDED, res.encoding);
        System.assert(res.gsmExtendedCount >= 6, 'At least æøåÆØÅ counted as extended');
        System.assertEquals(0, res.unicodeCount, 'No UCS-2 forced by Danish letters alone');
    }

    @IsTest
    static void testHyphenVsEnDash_3vs7Segments() {
        // Use 459 GSM chars so GSM = 3 segments (153*3=459). UCS-2: ceil(459/67)=7.
        String base = '';
        for (Integer i=0; i<459; i++) base += 'x';

        // Replace one character with hyphen (GSM) -> stays 3 segments
        String hyphenMsg  = base.substring(0, 230) + '-' + base.substring(231);
        SMSSegmentUtil.AnalysisResult resHyphen = SMSSegmentUtil.analyze(hyphenMsg);
        System.assertEquals(SMSSegmentUtil.Encoding.GSM_7, resHyphen.encoding);
        System.assertEquals(3, resHyphen.segments, 'GSM hyphen should keep 3 segments');

        // Replace one character with en dash (U+2013) -> UCS-2, 7 segments
        String enDash = '–';
        String enDashMsg = base.substring(0, 230) + enDash + base.substring(231);
        SMSSegmentUtil.AnalysisResult resDash = SMSSegmentUtil.analyze(enDashMsg);
        System.assertEquals(SMSSegmentUtil.Encoding.UCS_2, resDash.encoding);
        System.assertEquals(7, resDash.segments, 'UCS-2 flip should yield 7 segments at 67/segment');
    }

    @IsTest
    static void testEmojiForcesUnicode() {
        String msg = 'Hello 🙂 emoji';
        SMSSegmentUtil.AnalysisResult res = SMSSegmentUtil.analyze(msg);
        System.assertEquals(SMSSegmentUtil.Encoding.UCS_2, res.encoding);
        System.assert(res.unicodeCount > 0, 'Emoji counted as Unicode');
        System.assertEquals(70, res.perSegmentLimit, 'Single-part Unicode limit 70 if short enough');
    }

    @IsTest
    static void testNewlinesTabsQuotesAndEmpty() {
        String msg = 'Line1\nLine2\r\n"Quoted"\nTabbed\tHere';
        SMSSegmentUtil.AnalysisResult res = SMSSegmentUtil.analyze(msg);
        // Tab (\t) is not GSM -> UCS-2
        System.assertEquals(SMSSegmentUtil.Encoding.UCS_2, res.encoding);
        System.assert(res.segments >= 1);

        // Empty
        SMSSegmentUtil.AnalysisResult emptyRes = SMSSegmentUtil.analyze('');
        System.assertEquals(null, emptyRes.encoding);
        System.assertEquals(0, emptyRes.segments);
    }

    @IsTest
    static void testVeryLongMessagePerformance() {
        // 10k GSM basic characters should be okay
        String msg = '';
        for (Integer i=0; i<10000; i++) msg += 'A';
        SMSSegmentUtil.AnalysisResult res = SMSSegmentUtil.analyze(msg);
        System.assertEquals(SMSSegmentUtil.Encoding.GSM_7, res.encoding);
        System.assert(res.segments > 0);
        // Quick sanity: 10000/153 ~ 66 segments (approx)
        System.assert(res.segments >= 60 && res.segments <= 70);
    }
}