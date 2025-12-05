/**
 * Test class for Phone Triggers (Lead, Contact, Account)
 * Tests trigger logic for phone normalization queueable job enqueueing
 */
@isTest
private class PhoneTriggerTest {
    
    // ==================== LEAD TRIGGER TESTS ====================
    
    /**
     * Test Lead insert triggers phone normalization
     */
    @isTest
    static void testLeadInsertTriggersNormalization() {
        Test.startTest();
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'Ireland',
            Country = 'Ireland',
            MobilePhone = '+353 0 87 123 4567',
            Phone = '087 654 3210'
        );
        insert testLead;
        Test.stopTest();
        
        // Verify normalization occurred
        Lead updatedLead = [SELECT MobilePhone, Phone FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('+353871234567', updatedLead.MobilePhone, 'MobilePhone should be normalized on insert');
        System.assertEquals('+353876543210', updatedLead.Phone, 'Phone should be normalized on insert');
    }
    
    /**
     * Test Lead update triggers phone normalization
     */
    @isTest
    static void testLeadUpdateTriggersNormalization() {
        // Insert with normalized number
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'Ireland'
        );
        insert testLead;
        
        Test.startTest();
        // Update with unnormalized number
        testLead.MobilePhone = '+353 0 87 999 8888';
        update testLead;
        Test.stopTest();
        
        Lead updatedLead = [SELECT MobilePhone FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('+353879998888', updatedLead.MobilePhone, 'MobilePhone should be normalized on update');
    }
    
    /**
     * Test Lead with no phone fields doesn't trigger normalization
     */
    @isTest
    static void testLeadNoPhoneFieldsNoNormalization() {
        Test.startTest();
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'Ireland'
            // No phone fields
        );
        insert testLead;
        Test.stopTest();
        
        // Should complete without error
        Lead updatedLead = [SELECT MobilePhone, Phone FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(null, updatedLead.MobilePhone, 'MobilePhone should remain null');
        System.assertEquals(null, updatedLead.Phone, 'Phone should remain null');
    }
    
    /**
     * Test Lead bulk insert
     */
    @isTest
    static void testLeadBulkInsert() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 50; i++) {
            leads.add(new Lead(
                FirstName = 'Test' + i,
                LastName = 'Lead' + i,
                Company = 'Test Company ' + i,
                Market_Unit__c = 'DFJ_DK',
                MobilePhone = '+45 0 42 45 51 5' + Math.mod(i, 10)
            ));
        }
        
        Test.startTest();
        insert leads;
        Test.stopTest();
        
        List<Lead> updatedLeads = [SELECT MobilePhone FROM Lead WHERE Id IN :leads];
        for (Lead l : updatedLeads) {
            System.assert(l.MobilePhone.startsWith('+454245515'), 'All leads should be normalized');
            System.assert(!l.MobilePhone.contains('+450'), 'Zero after country code should be removed');
        }
    }
    
    // ==================== CONTACT TRIGGER TESTS ====================
    
    /**
     * Test Contact insert triggers phone normalization
     */
    @isTest
    static void testContactInsertTriggersNormalization() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Test.startTest();
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Market_Unit__c = 'FA_SE',
            MailingCountry = 'Sweden',
            MobilePhone = '+46 0 70 123 45 67',
            Phone = '070 987 65 43'
        );
        insert testContact;
        Test.stopTest();
        
        Contact updatedContact = [SELECT MobilePhone, Phone FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('+46701234567', updatedContact.MobilePhone, 'MobilePhone should be normalized on insert');
        System.assertEquals('+46709876543', updatedContact.Phone, 'Phone should be normalized on insert');
    }
    
    /**
     * Test Contact update triggers phone normalization
     */
    @isTest
    static void testContactUpdateTriggersNormalization() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Market_Unit__c = 'FA_SE'
        );
        insert testContact;
        
        Test.startTest();
        testContact.MobilePhone = '+46 0 70 111 22 33';
        update testContact;
        Test.stopTest();
        
        Contact updatedContact = [SELECT MobilePhone FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('+46701112233', updatedContact.MobilePhone, 'MobilePhone should be normalized on update');
    }
    
    /**
     * Test Contact with multiple phone fields
     */
    @isTest
    static void testContactMultiplePhoneFields() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Test.startTest();
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Market_Unit__c = 'DFJ_DK',
            MailingCountry = 'Denmark',
            AssistantPhone = '+45 0 11 22 33 44',
            HomePhone = '+45 0 22 33 44 55',
            MobilePhone = '+45 0 33 44 55 66',
            OtherPhone = '+45 0 44 55 66 77',
            Phone = '+45 0 55 66 77 88'
        );
        insert testContact;
        Test.stopTest();
        
        Contact updated = [SELECT AssistantPhone, HomePhone, MobilePhone, OtherPhone, Phone 
                          FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('+4511223344', updated.AssistantPhone, 'AssistantPhone should be normalized');
        System.assertEquals('+4522334455', updated.HomePhone, 'HomePhone should be normalized');
        System.assertEquals('+4533445566', updated.MobilePhone, 'MobilePhone should be normalized');
        System.assertEquals('+4544556677', updated.OtherPhone, 'OtherPhone should be normalized');
        System.assertEquals('+4555667788', updated.Phone, 'Phone should be normalized');
    }
    
    // ==================== ACCOUNT TRIGGER TESTS ====================
    
    /**
     * Test Account insert triggers phone normalization
     */
    @isTest
    static void testAccountInsertTriggersNormalization() {
        Test.startTest();
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'Ireland',
            BillingCountry = 'Ireland',
            Phone = '+353 0 1 234 5678'
        );
        insert testAccount;
        Test.stopTest();
        
        Account updatedAccount = [SELECT Phone FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('+35312345678', updatedAccount.Phone, 'Phone should be normalized on insert');
    }
    
    /**
     * Test Account update triggers phone normalization
     */
    @isTest
    static void testAccountUpdateTriggersNormalization() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'Ireland'
        );
        insert testAccount;
        
        Test.startTest();
        testAccount.Phone = '+353 0 87 111 2222';
        update testAccount;
        Test.stopTest();
        
        Account updatedAccount = [SELECT Phone FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('+353871112222', updatedAccount.Phone, 'Phone should be normalized on update');
    }
    
    /**
     * Test Account bulk insert
     */
    @isTest
    static void testAccountBulkInsert() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Market_Unit__c = 'Ireland',
                BillingCountry = 'Ireland',
                Phone = '+353 0 87 ' + String.valueOf(1000000 + i)
            ));
        }
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        List<Account> updatedAccounts = [SELECT Phone FROM Account WHERE Id IN :accounts];
        for (Account a : updatedAccounts) {
            System.assert(a.Phone.startsWith('+35387'), 'All accounts should be normalized with +35387 prefix');
            System.assert(!a.Phone.contains('+3530'), 'Zero after country code should be removed');
        }
    }
    
    /**
     * Test Account with no phone field doesn't trigger normalization
     */
    @isTest
    static void testAccountNoPhoneFieldNoNormalization() {
        Test.startTest();
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'Ireland'
            // No phone field
        );
        insert testAccount;
        Test.stopTest();
        
        // Should complete without error
        Account updatedAccount = [SELECT Phone FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(null, updatedAccount.Phone, 'Phone should remain null');
    }
    
    /**
     * Test Account with ShippingCountry fallback
     */
    @isTest
    static void testAccountShippingCountryFallback() {
        Test.startTest();
        Account testAccount = new Account(
            Name = 'Test Account',
            Market_Unit__c = 'FA_SE',
            ShippingCountry = 'Sweden', // Using ShippingCountry instead of BillingCountry
            Phone = '+46 0 70 123 45 67'
        );
        insert testAccount;
        Test.stopTest();
        
        Account updatedAccount = [SELECT Phone FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('+46701234567', updatedAccount.Phone, 'Phone should be normalized using ShippingCountry');
    }
    
    /**
     * Test Person Account insert triggers phone normalization for Person Account fields
     */
    @isTest
    static void testPersonAccountInsertTriggersNormalization() {
        // Get Person Account RecordType
        RecordType personAccountRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1];
        
        Test.startTest();
        Account personAccount = new Account(
            RecordTypeId = personAccountRT.Id,
            FirstName = 'Test',
            LastName = 'Person',
            Market_Unit__c = 'Ireland',
            BillingCountry = 'Ireland',
            PersonMobilePhone = '+353 0 87 123 4567',
            PersonHomePhone = '+353 0 1 234 5678'
        );
        insert personAccount;
        Test.stopTest();
        
        Account updated = [SELECT PersonMobilePhone, PersonHomePhone, Phone FROM Account WHERE Id = :personAccount.Id];
        // Verify normalization occurred (zero removed after country code)
        System.assert(!String.valueOf(updated.PersonMobilePhone).contains('+3530'), 'PersonMobilePhone should not have zero after country code');
        System.assert(!String.valueOf(updated.PersonHomePhone).contains('+3530'), 'PersonHomePhone should not have zero after country code');
        System.assert(updated.PersonMobilePhone != null, 'PersonMobilePhone should be set');
        System.assert(updated.PersonHomePhone != null, 'PersonHomePhone should be set');
    }
    
    /**
     * Test Person Account update triggers phone normalization
     */
    @isTest
    static void testPersonAccountUpdateTriggersNormalization() {
        RecordType personAccountRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1];
        
        Account personAccount = new Account(
            RecordTypeId = personAccountRT.Id,
            FirstName = 'Test',
            LastName = 'Person',
            Market_Unit__c = 'Ireland'
        );
        insert personAccount;
        
        Test.startTest();
        personAccount.PersonMobilePhone = '+353 0 87 999 8888';
        personAccount.PersonOtherPhone = '+353 0 86 777 6666';
        update personAccount;
        Test.stopTest();
        
        Account updated = [SELECT PersonMobilePhone, PersonOtherPhone FROM Account WHERE Id = :personAccount.Id];
        // Verify normalization occurred (zero removed after country code)
        System.assert(!String.valueOf(updated.PersonMobilePhone).contains('+3530'), 'PersonMobilePhone should not have zero after country code');
        System.assert(!String.valueOf(updated.PersonOtherPhone).contains('+3530'), 'PersonOtherPhone should not have zero after country code');
    }
    
    /**
     * Test Person Account with all phone fields
     */
    @isTest
    static void testPersonAccountAllPhoneFields() {
        RecordType personAccountRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1];
        
        Test.startTest();
        Account personAccount = new Account(
            RecordTypeId = personAccountRT.Id,
            FirstName = 'Test',
            LastName = 'Person',
            Market_Unit__c = 'DFJ_DK',
            BillingCountry = 'Denmark',
            PersonAssistantPhone = '+45 0 22 33 44 55',
            PersonHomePhone = '+45 0 33 44 55 66',
            PersonMobilePhone = '+45 0 44 55 66 77',
            PersonOtherPhone = '+45 0 55 66 77 88'
        );
        insert personAccount;
        Test.stopTest();
        
        Account updated = [SELECT Phone, PersonAssistantPhone, PersonHomePhone, PersonMobilePhone, PersonOtherPhone 
                          FROM Account WHERE Id = :personAccount.Id];
        // Verify normalization occurred (zero removed after country code)
        if (updated.PersonAssistantPhone != null) {
            System.assert(!updated.PersonAssistantPhone.contains('+450'), 'PersonAssistantPhone should not have zero after country code');
        }
        if (updated.PersonHomePhone != null) {
            System.assert(!updated.PersonHomePhone.contains('+450'), 'PersonHomePhone should not have zero after country code');
        }
        if (updated.PersonMobilePhone != null) {
            System.assert(!updated.PersonMobilePhone.contains('+450'), 'PersonMobilePhone should not have zero after country code');
        }
        if (updated.PersonOtherPhone != null) {
            System.assert(!updated.PersonOtherPhone.contains('+450'), 'PersonOtherPhone should not have zero after country code');
        }
    }
    
    // ==================== EDGE CASE TESTS ====================
    
    /**
     * Test that unchanged phone fields don't trigger normalization
     */
    @isTest
    static void testUnchangedPhoneNoNormalization() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Market_Unit__c = 'Ireland',
            MobilePhone = '+353871234567' // Already normalized
        );
        insert testLead;
        
        // Allow async job to complete
        Test.startTest();
        // Update a non-phone field
        testLead.Company = 'Updated Company';
        update testLead;
        Test.stopTest();
        
        // Number should remain unchanged
        Lead updatedLead = [SELECT MobilePhone FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('+353871234567', updatedLead.MobilePhone, 'Unchanged phone should remain the same');
    }
    
    /**
     * Test mixed batch - some records need normalization, some don't
     */
    @isTest
    static void testMixedBatchNormalization() {
        List<Lead> leads = new List<Lead>();
        
        // Lead with unnormalized phone
        leads.add(new Lead(
            FirstName = 'Unnormalized',
            LastName = 'Lead',
            Company = 'Test Company 1',
            Market_Unit__c = 'Ireland',
            MobilePhone = '+353 0 87 111 1111'
        ));
        
        // Lead with already normalized phone
        leads.add(new Lead(
            FirstName = 'Normalized',
            LastName = 'Lead',
            Company = 'Test Company 2',
            Market_Unit__c = 'Ireland',
            MobilePhone = '+353872222222'
        ));
        
        // Lead with no phone
        leads.add(new Lead(
            FirstName = 'NoPhone',
            LastName = 'Lead',
            Company = 'Test Company 3',
            Market_Unit__c = 'Ireland'
        ));
        
        Test.startTest();
        insert leads;
        Test.stopTest();
        
        Map<Id, Lead> updatedLeads = new Map<Id, Lead>([SELECT FirstName, MobilePhone FROM Lead WHERE Id IN :leads]);
        
        for (Lead l : updatedLeads.values()) {
            if (l.FirstName == 'Unnormalized') {
                System.assertEquals('+353871111111', l.MobilePhone, 'Unnormalized lead should be normalized');
            } else if (l.FirstName == 'Normalized') {
                System.assertEquals('+353872222222', l.MobilePhone, 'Already normalized lead should remain same');
            } else if (l.FirstName == 'NoPhone') {
                System.assertEquals(null, l.MobilePhone, 'Lead without phone should remain null');
            }
        }
    }
    
    /**
     * Test the specific bug scenario reported in ticket
     */
    @isTest
    static void testReportedBugScenarioIreland() {
        // Exact scenario from ticket: Irish number with 0 after +353
        Test.startTest();
        Lead testLead = new Lead(
            FirstName = 'Bug',
            LastName = 'Report',
            Company = 'Client Company',
            Market_Unit__c = 'Ireland',
            Country = 'Ireland',
            MobilePhone = '+353087123456' // The reported problematic format
        );
        insert testLead;
        Test.stopTest();
        
        Lead updatedLead = [SELECT MobilePhone FROM Lead WHERE Id = :testLead.Id];
        
        // This is the fix - zero should be removed
        System.assertEquals('+35387123456', updatedLead.MobilePhone, 
            'BUG FIX VERIFICATION: Zero after +353 should be removed');
        System.assert(!updatedLead.MobilePhone.startsWith('+3530'), 
            'BUG FIX VERIFICATION: Phone should not start with +3530');
    }
    
    /**
     * Test all three country codes with the leading zero bug pattern
     */
    @isTest
    static void testLeadingZeroBugAllCountries() {
        Test.startTest();
        
        // Ireland
        Lead irishLead = new Lead(
            FirstName = 'Irish',
            LastName = 'Lead',
            Company = 'Irish Company',
            Market_Unit__c = 'Ireland',
            MobilePhone = '+353087654321'
        );
        
        // Denmark
        Lead danishLead = new Lead(
            FirstName = 'Danish',
            LastName = 'Lead',
            Company = 'Danish Company',
            Market_Unit__c = 'DFJ_DK',
            MobilePhone = '+45012345678'
        );
        
        // Sweden
        Lead swedishLead = new Lead(
            FirstName = 'Swedish',
            LastName = 'Lead',
            Company = 'Swedish Company',
            Market_Unit__c = 'FA_SE',
            MobilePhone = '+46070123456'
        );
        
        insert new List<Lead>{irishLead, danishLead, swedishLead};
        Test.stopTest();
        
        Map<Id, Lead> updated = new Map<Id, Lead>([
            SELECT FirstName, MobilePhone FROM Lead 
            WHERE Id IN :new List<Id>{irishLead.Id, danishLead.Id, swedishLead.Id}
        ]);
        
        for (Lead l : updated.values()) {
            if (l.FirstName == 'Irish') {
                System.assertEquals('+35387654321', l.MobilePhone, 'Irish: Zero after +353 should be removed');
            } else if (l.FirstName == 'Danish') {
                System.assertEquals('+4512345678', l.MobilePhone, 'Danish: Zero after +45 should be removed');
            } else if (l.FirstName == 'Swedish') {
                System.assertEquals('+4670123456', l.MobilePhone, 'Swedish: Zero after +46 should be removed');
            }
        }
    }
}
