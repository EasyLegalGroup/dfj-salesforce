@IsTest
private class DFJ_ShowHistory_Apex_Test {
    @TestSetup
    static void setup() {
        // Create an Account
        Account testAccount = new Account(
                Name = 'Test Account',
                RecordTypeId = '0121t000000ZCclAAG'
        );
        insert testAccount;

        // Create a Contact
        Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = testAccount.Id
        );
        insert testContact;

        // Create a Note and associate it with testAccount
        Note testNote1 = new Note(
                Title = 'Test Note',
                Body = 'This is a test note',
                ParentId = testAccount.Id
        );


        // Create a Note and associate it with testContact
        Note testNote2 = new Note(
                Title = 'Test Note',
                Body = 'This is a test note',
                ParentId = testContact.Id
        );

        insert new List<SObject>{testNote1, testNote2};

        // create an event
        Event testEvent = new Event(
                Subject = 'Test Event',
                DurationInMinutes = 30,
                ActivityDateTime = System.now().addDays(5),
                WhatId = testAccount.Id,
                WhoId = testContact.Id
        );
        insert testEvent;

        // create telegenta__Telegenta_Call_History__c
        telegenta__Telegenta_Call_History__c testCallHistory = new telegenta__Telegenta_Call_History__c(
                telegenta__Account__c = testAccount.Id,
                telegenta__Contact__c = testContact.Id
        );
        insert testCallHistory;
    }

    @IsTest
    static void testGetConsolidatedData() {

        // fetch account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String recordId = testAccount.Id;
        String objectName = 'Account';

        // call getConsolidatedData method
        DFJ_ShowHistory_Apex.ConsolidatedDataWrapper consolidatedData = DFJ_ShowHistory_Apex.getConsolidatedData(recordId, objectName);
        System.assertNotEquals(null, consolidatedData);
    }

}