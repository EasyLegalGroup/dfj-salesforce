/**
 * Test class for PhoneFieldNormalizer
 * Tests the Queueable phone normalization for Lead, Contact, and Account objects
 */
@isTest
private class PhoneFieldNormalizerTest {
    
    /**
     * Test Lead phone normalization via Queueable
     */
    @isTest
    static void testLeadPhoneNormalization() {
        // Create test lead with unnormalized phone numbers
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'Ireland',
            Country = 'Ireland',
            MobilePhone = '+353 0 87 123 4567',
            Phone = '00353 087 654 3210'
        );
        insert testLead;
        
        // Create snapshot for the normalizer
        Lead snapshot = new Lead(
            Id = testLead.Id,
            Market_Unit__c = testLead.Market_Unit__c,
            Country = testLead.Country,
            MobilePhone = testLead.MobilePhone,
            Phone = testLead.Phone
        );
        
        List<String> phoneFields = new List<String>{'MobilePhone', 'Phone'};
        
        Test.startTest();
        System.enqueueJob(new PhoneFieldNormalizer('Lead', new List<Lead>{snapshot}, phoneFields));
        Test.stopTest();
        
        // Verify normalization
        Lead updatedLead = [SELECT MobilePhone, Phone FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('+353871234567', updatedLead.MobilePhone, 'MobilePhone should be normalized');
        System.assertEquals('+353876543210', updatedLead.Phone, 'Phone should be normalized');
    }
    
    /**
     * Test Contact phone normalization via Queueable
     */
    @isTest
    static void testContactPhoneNormalization() {
        // Create test account first (required for Contact)
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test contact with unnormalized phone numbers
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Market_Unit__c = 'DFJ_DK',
            MailingCountry = 'Denmark',
            MobilePhone = '+45 0 42 45 51 50',
            Phone = '0045 042 12 34 56'
        );
        insert testContact;
        
        // Create snapshot for the normalizer
        Contact snapshot = new Contact(
            Id = testContact.Id,
            Market_Unit__c = testContact.Market_Unit__c,
            MailingCountry = testContact.MailingCountry,
            MobilePhone = testContact.MobilePhone,
            Phone = testContact.Phone
        );
        
        List<String> phoneFields = new List<String>{'MobilePhone', 'Phone'};
        
        Test.startTest();
        System.enqueueJob(new PhoneFieldNormalizer('Contact', new List<Contact>{snapshot}, phoneFields));
        Test.stopTest();
        
        // Verify normalization
        Contact updatedContact = [SELECT MobilePhone, Phone FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('+4542455150', updatedContact.MobilePhone, 'MobilePhone should be normalized');
        System.assertEquals('+4542123456', updatedContact.Phone, 'Phone should be normalized');
    }
    
    /**
     * Test Account phone normalization via Queueable
     */
    @isTest
    static void testAccountPhoneNormalization() {
        // Create test account with unnormalized phone number
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'FA_SE',
            BillingCountry = 'Sweden',
            Phone = '+46 0 70 123 45 67'
        );
        insert testAccount;
        
        // Create snapshot for the normalizer
        Account snapshot = new Account(
            Id = testAccount.Id,
            Market_Unit__c = testAccount.Market_Unit__c,
            BillingCountry = testAccount.BillingCountry,
            Phone = testAccount.Phone
        );
        
        List<String> phoneFields = new List<String>{'Phone'};
        
        Test.startTest();
        System.enqueueJob(new PhoneFieldNormalizer('Account', new List<Account>{snapshot}, phoneFields));
        Test.stopTest();
        
        // Verify normalization
        Account updatedAccount = [SELECT Phone FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('+46701234567', updatedAccount.Phone, 'Phone should be normalized');
    }
    
    /**
     * Test that already normalized numbers are not updated
     */
    @isTest
    static void testAlreadyNormalizedNumber() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'Ireland',
            MobilePhone = '+353871234567' // Already normalized
        );
        insert testLead;
        
        Lead snapshot = new Lead(
            Id = testLead.Id,
            Market_Unit__c = testLead.Market_Unit__c,
            MobilePhone = testLead.MobilePhone
        );
        
        List<String> phoneFields = new List<String>{'MobilePhone'};
        
        Test.startTest();
        System.enqueueJob(new PhoneFieldNormalizer('Lead', new List<Lead>{snapshot}, phoneFields));
        Test.stopTest();
        
        // Number should remain the same
        Lead updatedLead = [SELECT MobilePhone FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('+353871234567', updatedLead.MobilePhone, 'Already normalized number should remain unchanged');
    }
    
    /**
     * Test with null phone fields
     */
    @isTest
    static void testNullPhoneFields() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'DFJ_DK'
            // No phone numbers set
        );
        insert testLead;
        
        Lead snapshot = new Lead(
            Id = testLead.Id,
            Market_Unit__c = testLead.Market_Unit__c
        );
        
        List<String> phoneFields = new List<String>{'MobilePhone', 'Phone'};
        
        Test.startTest();
        System.enqueueJob(new PhoneFieldNormalizer('Lead', new List<Lead>{snapshot}, phoneFields));
        Test.stopTest();
        
        // Should complete without error
        Lead updatedLead = [SELECT MobilePhone, Phone FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(null, updatedLead.MobilePhone, 'Null MobilePhone should remain null');
        System.assertEquals(null, updatedLead.Phone, 'Null Phone should remain null');
    }
    
    /**
     * Test with empty record list
     */
    @isTest
    static void testEmptyRecordList() {
        List<String> phoneFields = new List<String>{'MobilePhone', 'Phone'};
        
        Test.startTest();
        // Should not throw error with empty list
        System.enqueueJob(new PhoneFieldNormalizer('Lead', new List<Lead>(), phoneFields));
        Test.stopTest();
        
        // Test passes if no exception thrown
        System.assert(true, 'Empty record list should not cause errors');
    }
    
    /**
     * Test with null record list
     */
    @isTest
    static void testNullRecordList() {
        List<String> phoneFields = new List<String>{'MobilePhone', 'Phone'};
        
        Test.startTest();
        // Should not throw error with null list
        System.enqueueJob(new PhoneFieldNormalizer('Lead', null, phoneFields));
        Test.stopTest();
        
        // Test passes if no exception thrown
        System.assert(true, 'Null record list should not cause errors');
    }
    
    /**
     * Test with null phone fields list
     */
    @isTest
    static void testNullPhoneFieldsList() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'DFJ_DK',
            MobilePhone = '+45 42 45 51 50'
        );
        insert testLead;
        
        Lead snapshot = new Lead(
            Id = testLead.Id,
            Market_Unit__c = testLead.Market_Unit__c,
            MobilePhone = testLead.MobilePhone
        );
        
        Test.startTest();
        // Should not throw error with null phone fields
        System.enqueueJob(new PhoneFieldNormalizer('Lead', new List<Lead>{snapshot}, null));
        Test.stopTest();
        
        // Test passes if no exception thrown
        System.assert(true, 'Null phone fields list should not cause errors');
    }
    
    /**
     * Test market unit resolution from Country field (Lead)
     */
    @isTest
    static void testMarketUnitFromCountryLead() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Country = 'Ireland', // Country set, no Market_Unit__c
            MobilePhone = '087 123 4567'
        );
        insert testLead;
        
        Lead snapshot = new Lead(
            Id = testLead.Id,
            Country = testLead.Country,
            MobilePhone = testLead.MobilePhone
        );
        
        List<String> phoneFields = new List<String>{'MobilePhone'};
        
        Test.startTest();
        System.enqueueJob(new PhoneFieldNormalizer('Lead', new List<Lead>{snapshot}, phoneFields));
        Test.stopTest();
        
        Lead updatedLead = [SELECT MobilePhone FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('+353871234567', updatedLead.MobilePhone, 'Should use Ireland country code from Country field');
    }
    
    /**
     * Test market unit resolution from MailingCountry field (Contact)
     */
    @isTest
    static void testMarketUnitFromMailingCountryContact() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            MailingCountry = 'Sweden',
            MobilePhone = '070 123 45 67'
        );
        insert testContact;
        
        Contact snapshot = new Contact(
            Id = testContact.Id,
            MailingCountry = testContact.MailingCountry,
            MobilePhone = testContact.MobilePhone
        );
        
        List<String> phoneFields = new List<String>{'MobilePhone'};
        
        Test.startTest();
        System.enqueueJob(new PhoneFieldNormalizer('Contact', new List<Contact>{snapshot}, phoneFields));
        Test.stopTest();
        
        Contact updatedContact = [SELECT MobilePhone FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('+46701234567', updatedContact.MobilePhone, 'Should use Sweden country code from MailingCountry');
    }
    
    /**
     * Test bulk processing
     */
    @isTest
    static void testBulkProcessing() {
        List<Lead> leads = new List<Lead>();
        List<Lead> snapshots = new List<Lead>();
        
        // Create 50 leads with various phone formats
        for (Integer i = 0; i < 50; i++) {
            leads.add(new Lead(
                FirstName = 'Test' + i,
                LastName = 'Lead' + i,
                Company = 'Test Company ' + i,
                Market_Unit__c = 'Ireland',
                MobilePhone = '+353 0 87 ' + String.valueOf(1000000 + i)
            ));
        }
        insert leads;
        
        // Create snapshots
        for (Lead l : leads) {
            snapshots.add(new Lead(
                Id = l.Id,
                Market_Unit__c = l.Market_Unit__c,
                MobilePhone = l.MobilePhone
            ));
        }
        
        List<String> phoneFields = new List<String>{'MobilePhone'};
        
        Test.startTest();
        System.enqueueJob(new PhoneFieldNormalizer('Lead', snapshots, phoneFields));
        Test.stopTest();
        
        // Verify all leads were normalized
        List<Lead> updatedLeads = [SELECT MobilePhone FROM Lead WHERE Id IN :leads];
        for (Lead l : updatedLeads) {
            System.assert(l.MobilePhone.startsWith('+35387'), 'All leads should be normalized with +35387 prefix');
            System.assert(!l.MobilePhone.contains('0871'), 'Zero after country code should be removed');
        }
    }
    
    /**
     * Test various country name formats
     */
    @isTest
    static void testCountryNameVariations() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create contacts with different country name formats
        // Use phone numbers that require market unit to determine country code
        // (numbers that don't auto-detect via pattern)
        List<Contact> contacts = new List<Contact>();
        
        // Denmark variations - use 8-digit number (will auto-detect as DK)
        contacts.add(new Contact(
            FirstName = 'Test', LastName = 'Denmark', AccountId = testAccount.Id,
            MailingCountry = 'Denmark', MobilePhone = '42455150'
        ));
        contacts.add(new Contact(
            FirstName = 'Test', LastName = 'DK', AccountId = testAccount.Id,
            MailingCountry = 'DK', MobilePhone = '42455151'
        ));
        
        // Sweden variations - use number with leading 0 and 7-prefix (Swedish mobile pattern)
        contacts.add(new Contact(
            FirstName = 'Test', LastName = 'Sweden', AccountId = testAccount.Id,
            MailingCountry = 'Sweden', MobilePhone = '0701234567'
        ));
        contacts.add(new Contact(
            FirstName = 'Test', LastName = 'SE', AccountId = testAccount.Id,
            MailingCountry = 'SE', MobilePhone = '0701234568'
        ));
        contacts.add(new Contact(
            FirstName = 'Test', LastName = 'Sverige', AccountId = testAccount.Id,
            MailingCountry = 'Sverige', MobilePhone = '0701234569'
        ));
        
        // Ireland variations - use number with leading 0 and 8-prefix (Irish mobile pattern)
        contacts.add(new Contact(
            FirstName = 'Test', LastName = 'Ireland', AccountId = testAccount.Id,
            MailingCountry = 'Ireland', MobilePhone = '0871234567'
        ));
        contacts.add(new Contact(
            FirstName = 'Test', LastName = 'IE', AccountId = testAccount.Id,
            MailingCountry = 'IE', MobilePhone = '0871234568'
        ));
        contacts.add(new Contact(
            FirstName = 'Test', LastName = 'Eire', AccountId = testAccount.Id,
            MailingCountry = 'Eire', MobilePhone = '0871234569'
        ));
        
        insert contacts;
        
        // Create snapshots
        List<Contact> snapshots = new List<Contact>();
        for (Contact c : contacts) {
            snapshots.add(new Contact(
                Id = c.Id,
                MailingCountry = c.MailingCountry,
                MobilePhone = c.MobilePhone
            ));
        }
        
        Test.startTest();
        System.enqueueJob(new PhoneFieldNormalizer('Contact', snapshots, new List<String>{'MobilePhone'}));
        Test.stopTest();
        
        // Verify results
        Map<String, String> countryToExpectedPrefix = new Map<String, String>{
            'Denmark' => '+45',
            'DK' => '+45',
            'Sweden' => '+46',
            'SE' => '+46',
            'Sverige' => '+46',
            'Ireland' => '+353',
            'IE' => '+353',
            'Eire' => '+353'
        };
        
        List<Contact> updatedContacts = [SELECT LastName, MobilePhone FROM Contact WHERE Id IN :contacts];
        for (Contact c : updatedContacts) {
            String expectedPrefix = countryToExpectedPrefix.get(c.LastName);
            System.assert(
                c.MobilePhone.startsWith(expectedPrefix), 
                'Country "' + c.LastName + '" should map to prefix ' + expectedPrefix + ', got: ' + c.MobilePhone
            );
        }
    }
    
    /**
     * Test the specific bug scenario: Irish numbers with leading zero
     */
    @isTest
    static void testIrishLeadingZeroBugScenario() {
        // This is the exact scenario from the ticket
        Lead testLead = new Lead(
            FirstName = 'Bug',
            LastName = 'Report',
            Company = 'Test Company',
            Market_Unit__c = 'Ireland',
            Country = 'Ireland',
            MobilePhone = '+353087123456' // Zero after country code - the reported bug
        );
        insert testLead;
        
        Lead snapshot = new Lead(
            Id = testLead.Id,
            Market_Unit__c = testLead.Market_Unit__c,
            Country = testLead.Country,
            MobilePhone = testLead.MobilePhone
        );
        
        List<String> phoneFields = new List<String>{'MobilePhone'};
        
        Test.startTest();
        System.enqueueJob(new PhoneFieldNormalizer('Lead', new List<Lead>{snapshot}, phoneFields));
        Test.stopTest();
        
        Lead updatedLead = [SELECT MobilePhone FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('+35387123456', updatedLead.MobilePhone, 
            'BUG FIX: Leading zero after +353 should be removed');
        System.assert(!updatedLead.MobilePhone.contains('+3530'), 
            'BUG FIX: Number should not contain +3530');
    }
}
