@IsTest(seeAllData=false)
private class DFJ_TimeFormatterTest {

    @IsTest
    static void testLocalizedLongAndTimeOnly() {
        Market_Unit_Time_Zone__mdt dk = new Market_Unit_Time_Zone__mdt(
            DeveloperName='DFJ_DK', Label='Denmark (DFJ_DK)',
            Market_Unit_Key__c='DFJ_DK', Time_Zone_Id__c='Europe/Copenhagen',
            Default_Format_Key__c='EU_24H', Language_Code__c='da'
        );
        Market_Unit_Time_Zone__mdt se = new Market_Unit_Time_Zone__mdt(
            DeveloperName='FA_SE', Label='Sweden (FA_SE)',
            Market_Unit_Key__c='FA_SE', Time_Zone_Id__c='Europe/Stockholm',
            Default_Format_Key__c='EU_24H', Language_Code__c='sv'
        );
        Market_Unit_Time_Zone__mdt ie = new Market_Unit_Time_Zone__mdt(
            DeveloperName='Ireland', Label='Ireland',
            Market_Unit_Key__c='Ireland', Time_Zone_Id__c='Europe/Dublin',
            Default_Format_Key__c='EU_24H', Language_Code__c='en-IE'
        );

        DFJ_TimeFormatter.TEST_BY_KEY_LOWER = new Map<String, Market_Unit_Time_Zone__mdt>{
            'dfj_dk'=>dk, 'fa_se'=>se, 'ireland'=>ie
        };

        Datetime dt = Datetime.newInstanceGmt(2025, 9, 14, 8, 55, 0); // Sunday

        DFJ_TimeFormatter.Request rDK = new DFJ_TimeFormatter.Request();
        rDK.value = dt; rDK.marketUnitKey = 'DFJ_DK'; rDK.formatKey = 'LONG';

        DFJ_TimeFormatter.Request rSE = new DFJ_TimeFormatter.Request();
        rSE.value = dt; rSE.marketUnitKey = 'FA_SE'; rSE.formatKey = 'LONG';

        DFJ_TimeFormatter.Request rIE = new DFJ_TimeFormatter.Request();
        rIE.value = dt; rIE.marketUnitKey = 'Ireland'; rIE.formatKey = 'LONG';

        Test.startTest();
        List<DFJ_TimeFormatter.Response> out =
            DFJ_TimeFormatter.format(new List<DFJ_TimeFormatter.Request>{ rDK, rSE, rIE });
        Test.stopTest();

        System.assertEquals(3, out.size());
        System.assertEquals('Europe/Copenhagen', out[0].timeZoneUsed);
        System.assertEquals('LONG(localized:da)', out[0].patternUsed);
        System.assertEquals('10:55', out[0].timeOnly);
        System.assertEquals('søndag, d. 14 September 2025, kl. 10:55', out[0].formatted);

        System.assertEquals('Europe/Stockholm', out[1].timeZoneUsed);
        System.assertEquals('LONG(localized:sv)', out[1].patternUsed);
        System.assertEquals('10:55', out[1].timeOnly);
        System.assertEquals('söndag den 14 september 2025 kl. 10:55', out[1].formatted);

        System.assertEquals('Europe/Dublin', out[2].timeZoneUsed);
        System.assertEquals('LONG(localized:en-IE)', out[2].patternUsed);
        System.assertEquals('09:55', out[2].timeOnly);
        System.assertEquals('Sunday, 14 September 2025, 09:55', out[2].formatted);

        DFJ_TimeFormatter.TEST_BY_KEY_LOWER = null;
    }

    @IsTest
    static void testPatternsAndFallbacks() {
        DFJ_TimeFormatter.TEST_BY_KEY_LOWER = null;

        Datetime dt = Datetime.newInstanceGmt(2025, 3, 3, 13, 5, 0);

        DFJ_TimeFormatter.Request r1 = new DFJ_TimeFormatter.Request();
        r1.value = dt; r1.timeZoneId = 'Europe/Copenhagen'; r1.pattern = 'HH:mm';

        DFJ_TimeFormatter.Request r2 = new DFJ_TimeFormatter.Request();
        r2.value = dt; r2.timeZoneId = 'Europe/Dublin'; r2.formatKey = 'SHORT';

        DFJ_TimeFormatter.Request r3 = new DFJ_TimeFormatter.Request();
        r3.value = dt; r3.timeZoneId = 'Bad/Timezone'; r3.formatKey = 'ISO_8601';

        Test.startTest();
        List<DFJ_TimeFormatter.Response> out =
            DFJ_TimeFormatter.format(new List<DFJ_TimeFormatter.Request>{ r1, r2, r3 });
        Test.stopTest();

        System.assertEquals('14:05', out[0].formatted);
        System.assertEquals('14:05', out[0].timeOnly);
        System.assertEquals('Europe/Copenhagen', out[0].timeZoneUsed);
        System.assertEquals('HH:mm', out[0].patternUsed);

        System.assertEquals('Europe/Dublin', out[1].timeZoneUsed);
        System.assertEquals('EEE, dd MMM yyyy HH:mm', out[1].patternUsed);
        System.assert(out[1].formatted.contains('2025'));
        System.assertEquals('13:05', out[1].timeOnly);

        System.assertEquals('UTC', out[2].timeZoneUsed);
        System.assertEquals('2025-03-03T13:05:00', out[2].formatted);
        System.assertEquals('13:05', out[2].timeOnly);
    }
}