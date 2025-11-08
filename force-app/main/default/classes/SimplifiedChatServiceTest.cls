@IsTest
public class SimplifiedChatServiceTest {

    /* ------------------------------------------------------------------ *
     * Shared data
     * ------------------------------------------------------------------ */
    @TestSetup
    static void setup() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        insert new List<ChatMessage__c>{
            new ChatMessage__c(
                Body__c          = 'Test inbound message',
                Parent_Record__c = acct.Id,
                Is_Inbound__c    = true
            ),
            new ChatMessage__c(
                Body__c          = 'Test outbound message',
                Parent_Record__c = acct.Id,
                Is_Inbound__c    = false
            )
        };
    }

    /* ------------------------------------------------------------------ *
     * getMessages() – happy path
     * ------------------------------------------------------------------ */
    @IsTest
    static void testGetMessages() {
        Id parentId = [SELECT Id FROM Account LIMIT 1].Id;

        Test.startTest();
        List<ChatMessage__c> msgs = SimplifiedChatService.getMessages(parentId);
        Test.stopTest();

        System.assertEquals(2, msgs.size(), 'Should return two messages');

        Boolean hasInbound  = false;
        Boolean hasOutbound = false;
        for (ChatMessage__c m : msgs) {
            if (m.Is_Inbound__c)  hasInbound  = true;
            if (!m.Is_Inbound__c) hasOutbound = true;
        }
        System.assert(hasInbound , 'Inbound message missing');
        System.assert(hasOutbound, 'Outbound message missing');
    }

    /* ------------------------------------------------------------------ *
     * createMessage() – happy path
     * ------------------------------------------------------------------ */
    @IsTest
    static void testCreateMessage() {
        Id parentId = [SELECT Id FROM Account LIMIT 1].Id;

        Test.startTest();
        ChatMessage__c result =
            SimplifiedChatService.createMessage('Hello World', parentId, false);
        Test.stopTest();

        ChatMessage__c saved = [
            SELECT Body__c, Is_Inbound__c
            FROM   ChatMessage__c
            WHERE  Id = :result.Id
        ];

        System.assertNotEquals(null, saved, 'Message should be persisted');
        System.assertEquals(false, saved.Is_Inbound__c, 'Should be outbound');
        System.assertEquals('Hello World', saved.Body__c);
    }

    /* ------------------------------------------------------------------ *
     * createMessage() – empty body
     * ------------------------------------------------------------------ */
    @IsTest
    static void testCreateMessage_EmptyBody() {
        Id parentId = [SELECT Id FROM Account LIMIT 1].Id;

        Test.startTest();
        try {
            SimplifiedChatService.createMessage('', parentId, false);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            // In Apex tests AuraHandledException often masks the custom text.
            // Just assert that we received the exception.
            System.assert(true, 'AuraHandledException was thrown as expected');
        }
        Test.stopTest();
    }

    /* ------------------------------------------------------------------ *
     * createMessage() – empty record Id
     * ------------------------------------------------------------------ */
    @IsTest
    static void testCreateMessage_EmptyRecordId() {
        Test.startTest();
        try {
            SimplifiedChatService.createMessage('Text', '', false);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException was thrown as expected');
        }
        Test.stopTest();
    }
}