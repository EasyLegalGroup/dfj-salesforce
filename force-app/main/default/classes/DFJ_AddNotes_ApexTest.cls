@isTest
public class DFJ_AddNotes_ApexTest {

    @IsTest
    static void saveNotesAndRelateToAccount_Test(){
        Account accInstance = new Account();
        accInstance.Name = 'TestName';
        insert accInstance;

        Test.startTest();
        DFJ_AddNotes_Apex.saveNotesAndRelateToAccount(accInstance.Id,'Note data for testing.');
        Test.stopTest();

        Note noteAssociatedWithAct = [
                SELECT Id
                , Body
                FROM Note
                WHERE
                ParentId = :accInstance.Id
                LIMIT 1
        ]??null;

        System.assertNotEquals(null,noteAssociatedWithAct);
    }

    @isTest
    private static void saveNotesForAddNotes_Test(){
        Account accInstance = new Account();
        accInstance.Name = 'TestName';
        insert accInstance;
        Case caseInst = new Case();
        caseInst.AccountId = accInstance.Id;
        insert caseInst;
        
        /*Note noteInstance = new Note();
noteInstance.Body = 'TestNoteBody';
noteInstance.ParentId = leadInstance.Id;
noteInstance.Title = userInfo.getName()+' '+System.now();
insert noteInstance;*/
        Test.startTest();
        DFJ_AddNotes_Apex.saveNotesForAddNotes(caseInst.Id,'Test Note');
        Test.stopTest();
        List<Note> getNoteList = [SELECT Id,ParentId,Body FROM Note WHERE ParentId =:accInstance.Id LIMIT 1];
        System.assertEquals(1,getNoteList.size());
    }
    @isTest
    private static void getCaseRecord_Test(){
        Account accInstance = new Account();
        accInstance.Name = 'TestName';
        insert accInstance;
        Lead leadInst = new Lead();
        leadInst.Provider_id__c= 'Test1';
        leadInst.LastName = 'TestLead';
        insert leadInst;
        Case caseInst = new Case();
        caseInst.AccountId = accInstance.Id;
        caseInst.Lead__c = leadInst.Id;
        insert caseInst;
        
        Test.startTest();
        DFJ_AddNotes_Apex.getCaseRecord(caseInst.Id);
        Test.stopTest();
        List<Case> getCaseList = [SELECT Id FROM Case WHERE AccountId =:accInstance.Id LIMIT 1];
        System.assertEquals(1,getCaseList.size());
    }
    //DFJ-208
    
    @isTest
    private static void saveLeadNotesFromCase_Test(){
        //Create Account
        Account accInstance = new Account();
        accInstance.Name = 'TestName';
        insert accInstance;
        //Create Lead
        Lead leadInst = new Lead();
        leadInst.Provider_id__c= 'Test';
        leadInst.LastName = 'TestLead';
        insert leadInst;
         //Create Case
        Case caseInst = new Case();
        caseInst.AccountId = accInstance.Id;
        caseInst.Lead__c = leadInst.Id;
        insert caseInst;

        Test.startTest();
        DFJ_AddNotes_Apex.saveLeadNotesFromCase(caseInst.Id,'Test Note');
        Test.stopTest();
        List<Note> getNoteList = [SELECT Id,ParentId,Body FROM Note WHERE ParentId =:leadInst.Id LIMIT 1];
        System.assertEquals(1,getNoteList.size());
    }
    @isTest
    private static void saveLeadNotesFromCaseWithNoAccount_Test2(){
        //Create Lead
        Lead leadInst = new Lead();
        leadInst.Provider_id__c='TestAbc';
        leadInst.LastName = 'TestLead';
        insert leadInst;
         //Create Case
        Case caseInst = new Case();
        caseInst.Lead__c = leadInst.Id;
        insert caseInst;

        Test.startTest();
        DFJ_AddNotes_Apex.saveLeadNotesFromCase(caseInst.Id,'Test Note');
        Test.stopTest();
        List<Note> getNoteList = [SELECT Id,ParentId,Body FROM Note WHERE ParentId =:leadInst.Id LIMIT 1];
        System.assertEquals(1,getNoteList.size());
    }
     @isTest
    private static void saveLeadNotesFromCaseWithNoAccountNoLead_Test3(){
        //Create Lead
        Lead leadInst = new Lead();
        leadInst.Provider_id__c='TestAbc';
        leadInst.LastName = 'TestLead';
        //insert leadInst;
         //Create Case
        Case caseInst = new Case();
        //caseInst.Lead__c = leadInst.Id;
        insert caseInst;

        Test.startTest();
        DFJ_AddNotes_Apex.saveLeadNotesFromCase(caseInst.Id,'Test Note');
        DFJ_AddNotes_Apex.saveNotesForAddNotes(caseInst.Id,'Test Note');
        Test.stopTest();
    }
}