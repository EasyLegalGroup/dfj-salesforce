@IsTest
private class McSmsRouting_Test {

    @IsTest
    static void test_routing_with_injected_rules() {
        // Inject "metadata" rows in-memory so the test works in any org/stage
        McSmsRouting.TEST_RULES = new List<McSmsRouting__mdt>{
            new McSmsRouting__mdt(
                CountryPrefix__c     = '+45',
                CurrencyIsoCode__c   = 'DKK',
                DefinitionKey__c     = 'SMS_TRX_DK',
                AlphaDefinitionKey__c= 'SMS_TRX_DK',
                IsDefault__c         = true
            ),
            new McSmsRouting__mdt(
                CountryPrefix__c     = '+46',
                CurrencyIsoCode__c   = 'SEK',
                DefinitionKey__c     = 'SMS_TRX_SE',
                AlphaDefinitionKey__c= 'SMS_TRX_SE',
                IsDefault__c         = false
            )
        };

        // 1) Match by From number (DK)
        String k1 = McSmsRouting.resolveDefinitionKey(
            new SMS__c(From_Number__c = '+45 400 000 00', CurrencyIsoCode = 'DKK'));
        System.assertEquals('SMS_TRX_DK', k1, 'From-number DK should route to DK');

        // 2) Match by To number (SE)
        String k2 = McSmsRouting.resolveDefinitionKey(
            new SMS__c(To_Number__c = '+46 (70) 000 0000', CurrencyIsoCode = 'SEK'));
        System.assertEquals('SMS_TRX_SE', k2, 'To-number SE should route to SE');

        // 3) Match by currency only -> default DK in our sample rules
        String k3 = McSmsRouting.resolveDefinitionKey(
            new SMS__c(CurrencyIsoCode = 'DKK'));
        System.assertEquals('SMS_TRX_DK', k3, 'Currency DKK should route to DK');

        // 4) Alpha path (same key here, but exercise the branch)
        String k4 = McSmsRouting.resolveDefinitionKey(
            new SMS__c(From_Number__c = '+45 1234 5678',
                       CurrencyIsoCode = 'DKK',
                       Send_From_Alphanumeric_Sender_ID__c = true));
        System.assertEquals('SMS_TRX_DK', k4, 'Alpha sender should still pick DK in our rules');

        // Tidy
        McSmsRouting.TEST_RULES = null;
    }
}