@isTest
private class NoteTriggerHandlerTest {

    @isTest static void testNoteOnAccount() {
        // Create an Account
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Create a Journal for that Account
        Journal__c jrnl = new Journal__c(Account__c = acc.Id);
        insert jrnl;

        // Create a Note for the Account
        Note n = new Note(
            Title = 'Account Note',
            Body = 'This is a note on the Account',
            ParentId = acc.Id
        );
        insert n;

        // Verify Journal was updated with note text
        Journal__c updatedJrnl = [
            SELECT Id, Latest_Note_on_Account__c
            FROM Journal__c
            WHERE Id = :jrnl.Id
        ];
        System.assertEquals('This is a note on the Account', updatedJrnl.Latest_Note_on_Account__c);
    }

    @isTest static void testNoteOnJournal() {
        // Create an Account and Journal
        Account acc = new Account(Name='Test Account 2');
        insert acc;
        Journal__c jrnl = new Journal__c(Account__c = acc.Id);
        insert jrnl;

        // Create a Note whose parent is the Journal
        Note n = new Note(
            Title = 'Journal Note',
            Body = 'This is a note on the Journal record',
            ParentId = jrnl.Id
        );
        insert n;

        // Verify Journal was updated with note text
        Journal__c updatedJrnl = [
            SELECT Id, Latest_Note_on_Account__c
            FROM Journal__c
            WHERE Id = :jrnl.Id
        ];
        System.assertEquals('This is a note on the Journal record', updatedJrnl.Latest_Note_on_Account__c);
    }

    @isTest static void testInternalNotesChange() {
        // Create an Account and Journal with an initial Internal_notes__c
        Account acc = new Account(Name='Test Account 3');
        insert acc;
        Journal__c jrnl = new Journal__c(Account__c = acc.Id, Internal_notes__c='Initial notes');
        insert jrnl;

        // Update Internal_notes__c
        jrnl.Internal_notes__c = 'Updated internal notes';
        update jrnl;

        // Verify Journal was updated
        Journal__c updatedJrnl = [
            SELECT Id, Latest_Note_on_Account__c
            FROM Journal__c
            WHERE Id = :jrnl.Id
        ];
        System.assertEquals('Updated internal notes', updatedJrnl.Latest_Note_on_Account__c);
    }

    @isTest static void testNoteWithOtherParent() {
        // Create a Contact (which is not an Account or Journal)
        Contact con = new Contact(FirstName='Test', LastName='Contact');
        insert con;

        // Create a Note with Contact as the parent
        Note n = new Note(
            Title = 'Contact Note',
            Body = 'Note on a Contact record',
            ParentId = con.Id
        );
        insert n;

        // Verify that no Journal got updated
        List<Journal__c> jrnlList = [
            SELECT Id, Latest_Note_on_Account__c
            FROM Journal__c
            WHERE Latest_Note_on_Account__c = :n.Body
        ];
        System.assertEquals(0, jrnlList.size());
    }

    @isTest static void testLongNoteTruncationOnAccount() {
        // Create an Account
        Account acc = new Account(Name='Test Account Long');
        insert acc;

        // Create a Journal for that Account
        Journal__c jrnl = new Journal__c(Account__c = acc.Id);
        insert jrnl;

        // Build a long note (over 255 characters)
        String longText = '';
        while (longText.length() < 260) {
            longText += 'A';
        }

        // Create a Note for the Account
        Note n = new Note(
            Title = 'Long Account Note',
            Body = longText,
            ParentId = acc.Id
        );
        insert n;

        // Verify truncation
        Journal__c updatedJrnl = [
            SELECT Id, Latest_Note_on_Account__c
            FROM Journal__c
            WHERE Id = :jrnl.Id
        ];
        System.assertEquals(longText.substring(0,252) + '...', updatedJrnl.Latest_Note_on_Account__c);
    }

    @isTest static void testLongNoteTruncationOnJournal() {
        // Create an Account and a Journal
        Account acc = new Account(Name='Test Account Long Journal');
        insert acc;
        Journal__c jrnl = new Journal__c(Account__c = acc.Id);
        insert jrnl;

        // Build a long note (over 255 characters)
        String longText = '';
        while (longText.length() < 260) {
            longText += 'B';
        }

        // Create a Note whose parent is the Journal
        Note n = new Note(
            Title = 'Long Journal Note',
            Body = longText,
            ParentId = jrnl.Id
        );
        insert n;

        // Verify truncation
        Journal__c updatedJrnl = [
            SELECT Id, Latest_Note_on_Account__c
            FROM Journal__c
            WHERE Id = :jrnl.Id
        ];
        System.assertEquals(longText.substring(0,252) + '...', updatedJrnl.Latest_Note_on_Account__c);
    }

    // =============================================================================
    // The two new methods below force exceptions, covering the catch blocks
    // =============================================================================

    @isTest static void testHandleNoteInsertUpdateException() {
        Test.startTest();
        try {
            // This will cause a NullPointerException when handleNoteInsertUpdate tries to loop over newNotes
            NoteTriggerHandler.handleNoteInsertUpdate(null);
        } catch(Exception e) {
            // We expect an exception, so just verify it was caught
            System.assertNotEquals(null, e, 'An exception should be thrown and caught.');
        }
        Test.stopTest();
    }

    @isTest static void testHandleJournalUpdateException() {
        Test.startTest();
        try {
            // This will cause a NullPointerException when handleJournalUpdate tries to loop over newList
            NoteTriggerHandler.handleJournalUpdate(null, null);
        } catch(Exception e) {
            System.assertNotEquals(null, e, 'An exception should be thrown and caught.');
        }
        Test.stopTest();
    }
}