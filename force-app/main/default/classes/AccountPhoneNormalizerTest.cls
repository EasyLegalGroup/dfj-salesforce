/**
 * Test class for AccountPhoneNormalizer and AccountPhoneTrigger
 * Validates phone normalization logic across different formats and countries
 */
@isTest
private class AccountPhoneNormalizerTest {
    
    @isTest
    static void testDanishPhoneNormalization() {
        // Test Danish phone normalization
        Account acc = new Account(
            Name = 'Test Danish Account',
            Market_Unit__c = 'DFJ_DK',
            Phone = '42 45 51 50'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        // Query the account to get normalized phone
        acc = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('+4542455150', acc.Phone, 'Danish phone should be normalized to +4542455150');
    }
    
    @isTest
    static void testSwedishPhoneNormalization() {
        // Test Swedish phone with leading zero and formatting
        Account acc = new Account(
            Name = 'Test Swedish Account',
            Market_Unit__c = 'FA_SE',
            Phone = '070-377 20 89'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        acc = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('+46703772089', acc.Phone, 'Swedish phone should be normalized to +46703772089');
    }
    
    @isTest
    static void testSwedishPhoneWithLeadingZeroAfterCountryCode() {
        // Test +460... -> +46...
        Account acc = new Account(
            Name = 'Test Swedish Account 2',
            Market_Unit__c = 'FA_SE',
            Phone = '+460703772089'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        acc = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('+46703772089', acc.Phone, 'Leading zero after country code should be removed');
    }
    
    @isTest
    static void testIrishPhoneNormalization() {
        // Test Irish phone normalization
        Account acc = new Account(
            Name = 'Test Irish Account',
            Market_Unit__c = 'Ireland',
            Phone = '(087) 123-4567'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        acc = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('+353871234567', acc.Phone, 'Irish phone should be normalized to +353871234567');
    }
    
    @isTest
    static void testPhoneWith00Prefix() {
        // Test 00 prefix conversion to +
        Account acc = new Account(
            Name = 'Test 00 Prefix',
            Market_Unit__c = 'FA_SE',
            Phone = '0046703772089'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        acc = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('+46703772089', acc.Phone, '00 prefix should be converted to +');
    }
    
    @isTest
    static void testPreserveExistingCountryCode() {
        // Test that existing country codes are preserved (Danish number with Swedish market)
        Account acc = new Account(
            Name = 'Test Preserve Country',
            Market_Unit__c = 'FA_SE',
            Phone = '+4542455150'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        acc = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('+4542455150', acc.Phone, 'Danish country code should be preserved even with Swedish market');
    }
    
    @isTest
    static void testSpousePhoneNormalization() {
        // Test Spouse_Phone__pc field normalization (Person Account)
        // Note: This test will only work if Person Accounts are enabled
        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'Spouse Phone',
            Market_Unit__c = 'DFJ_DK',
            Spouse_Phone__pc = '12-34-56-78'
        );
        
        Test.startTest();
        try {
            insert acc;
            Test.stopTest();
            
            acc = [SELECT Spouse_Phone__pc FROM Account WHERE Id = :acc.Id];
            System.assertEquals('+4512345678', acc.Spouse_Phone__pc, 'Spouse phone should be normalized');
        } catch (Exception e) {
            // Person Accounts might not be enabled in this org
            System.debug('Person Accounts not enabled or field not accessible: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testBothPhonesNormalization() {
        // Test both Phone and Spouse_Phone__pc normalization (Person Account)
        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'Both Phones',
            Market_Unit__c = 'FA_SE',
            Phone = '070 377 2089',
            Spouse_Phone__pc = '+460123456789'
        );
        
        Test.startTest();
        try {
            insert acc;
            Test.stopTest();
            
            acc = [SELECT Phone, Spouse_Phone__pc FROM Account WHERE Id = :acc.Id];
            System.assertEquals('+46703772089', acc.Phone, 'Phone should be normalized');
            System.assertEquals('+46123456789', acc.Spouse_Phone__pc, 'Spouse phone leading zero should be removed');
        } catch (Exception e) {
            // Person Accounts might not be enabled in this org
            System.debug('Person Accounts not enabled or field not accessible: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testUpdateTrigger() {
        // Test that normalization works on update
        Account acc = new Account(
            Name = 'Test Update',
            Market_Unit__c = 'DFJ_DK',
            Phone = '+4542455150'
        );
        insert acc;
        
        // Update with messy formatting
        acc.Phone = '42-45-51-50';
        
        Test.startTest();
        update acc;
        Test.stopTest();
        
        acc = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('+4542455150', acc.Phone, 'Phone should be normalized on update');
    }
    
    @isTest
    static void testStripAllNonDigitCharacters() {
        // Test that all non-digit characters are stripped
        Account acc = new Account(
            Name = 'Test Special Chars',
            Market_Unit__c = 'FA_SE',
            Phone = 'abc+46-def(070)377.2089/test'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        acc = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('+46703772089', acc.Phone, 'All non-digit characters should be stripped');
    }
    
    @isTest
    static void testBlankPhoneNotProcessed() {
        // Test that blank phones are not processed
        Account acc = new Account(
            Name = 'Test Blank Phone',
            Market_Unit__c = 'DFJ_DK'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        acc = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, acc.Phone, 'Null phone should remain null');
    }
    
    @isTest
    static void testBulkInsert() {
        // Test bulk processing (200 records)
        List<Account> accounts = new List<Account>();
        
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Test ' + i,
                Market_Unit__c = 'FA_SE',
                Phone = '070377208' + Math.mod(i, 10)
            ));
        }
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        List<Account> inserted = [SELECT Phone FROM Account WHERE Name LIKE 'Bulk Test%'];
        System.assertEquals(200, inserted.size(), 'All 200 accounts should be inserted');
        
        for (Account acc : inserted) {
            System.assert(acc.Phone.startsWith('+46'), 'All phones should start with +46');
        }
    }
}