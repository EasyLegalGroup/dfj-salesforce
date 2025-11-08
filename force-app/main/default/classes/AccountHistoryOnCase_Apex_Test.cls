@isTest
public class AccountHistoryOnCase_Apex_Test {
    @testSetup static void setup() {
         Account accInstance = new Account();
        accInstance.Name = 'TestName';
        insert accInstance;
        //Create Lead
        Lead leadInst = new Lead();
        leadInst.Provider_id__c= 'Test';
        leadInst.LastName = 'TestLead';
        insert leadInst;
        Case caseInst = new Case();
        caseInst.AccountId = accInstance.Id;
        caseInst.Lead__c = leadInst.Id;
        insert caseInst;
      

        telegenta__Telegenta_Call_History__c callInstance = new telegenta__Telegenta_Call_History__c();
        callInstance.telegenta__Account__c = accInstance.Id;
        callInstance.telegenta__Destination_Country__c = 'Denmark';
        callInstance.telegenta__Direction__c = 'OUTBOUND';
        callInstance.telegenta__Privacy__c = true;
        insert callInstance;
        
        Event evInstanceForLead = new Event();
        evInstanceForLead.Type = 'Email';
        evInstanceForLead.Description = 'test description';
        evInstanceForLead.WhoId = leadInst.Id;
        evInstanceForLead.DurationInMinutes =50;
        evInstanceForLead.ActivityDateTime = Datetime.now();
        insert evInstanceForLead;
        
        telegenta__Telegenta_Call_History__c callInstanceForLead = new telegenta__Telegenta_Call_History__c();
        callInstanceForLead.telegenta__Lead__c = leadInst.Id;
        callInstanceForLead.telegenta__Destination_Country__c = 'Denmark';
        callInstanceForLead.telegenta__Direction__c = 'OUTBOUND';
        callInstanceForLead.telegenta__Privacy__c = true;
        insert callInstanceForLead;
        
		Event evInstance = new Event();
        evInstance.Type = 'Email';
        evInstance.Description = 'test description';
        evInstance.WhatId = accInstance.Id;
        evInstance.DurationInMinutes =50;
        evInstance.ActivityDateTime = Datetime.now();
        insert evInstance;
        
        telegenta__Telegenta_Call_Recording__c recordingInstance = new telegenta__Telegenta_Call_Recording__c();
        recordingInstance.telegenta__Telegenta_Call_History__c = callInstance.Id;
        recordingInstance.telegenta__Record_Player__c = 'test url';
        insert recordingInstance;

        Note noteInstance = new Note();
        noteInstance.Body = 'NotesData';
        noteInstance.ParentId = accInstance.Id;
        noteInstance.Title = accInstance.Name +' Note';
        insert noteInstance;
        
        Note noteInstanceForLead = new Note();
        noteInstanceForLead.Body = 'NotesData';
        noteInstanceForLead.ParentId = leadInst.Id;
        noteInstanceForLead.Title = accInstance.Name +' Note';
        insert noteInstanceForLead;
        
        telegenta__Campaign__c campaignInstance = new telegenta__Campaign__c();
        campaignInstance.Name = 'Test';
        //campaignInstance.telegenta__Outcome_profile__c = outcomeProfileInstance.Id;
        Insert campaignInstance;
        
        telegenta__Call_Campaign_State__c callCampaignStateInstance = new telegenta__Call_Campaign_State__c();
        callCampaignStateInstance.telegenta__Account__c = accInstance.Id;
        callCampaignStateInstance.telegenta__Call_Campaign__c = campaignInstance.Id;
        insert callCampaignStateInstance;
        
        telegenta__Campaign__c campaignInstanceForLead = new telegenta__Campaign__c();
        campaignInstanceForLead.Name = 'Test';
        //campaignInstance.telegenta__Outcome_profile__c = outcomeProfileInstance.Id;
        Insert campaignInstanceForLead;
        
        telegenta__Call_Campaign_State__c callCampaignStateInstanceForLead = new telegenta__Call_Campaign_State__c();
        callCampaignStateInstanceForLead.telegenta__Lead__c = leadInst.Id;
        callCampaignStateInstanceForLead.telegenta__Call_Campaign__c = campaignInstanceForLead.Id;
        insert callCampaignStateInstanceForLead;
        
      /*  telegenta__Call_Campaign_State__History historyInst = new telegenta__Call_Campaign_State__History();
		historyInst.parentId = callCampaignStateInstance.Id;
		insert historyInst;*/
    }
    
     @isTest
    private static void fetchConsolidatedViewData_Test(){
        List<Account> accInst = [SELECT Id FROM Account WHERE name='TestName' LIMIT 1]; 
        List<Case> caseInst = [SELECT Id,AccountId FROM Case WHERE AccountId=:accInst[0].Id LIMIT 1]; 
        
        Test.startTest();
        AccountHistoryOnCase_Apex.fetchConsolidatedViewData(caseInst[0].Id); 
        AccountHistoryOnCase_Apex.getLastOutcomeHistoryView_Apex(caseInst[0].AccountId,'Account');
        Test.stopTest();
    }
    
    //DFJ-208
    @isTest
    private static void fetchConsolidatedViewDataForLead_Test(){
        List<Lead> leadInst = [SELECT Id FROM Lead WHERE LastName='TestLead' LIMIT 1]; 
        List<Case> caseInst = [SELECT Id,Lead__c FROM Case WHERE Lead__c=:leadInst[0].Id LIMIT 1]; 
        
        Test.startTest();
        AccountHistoryOnCase_Apex.fetchConsolidatedViewDataForLead(caseInst[0].Id); 
        AccountHistoryOnCase_Apex.getLastOutcomeHistoryView_Apex(caseInst[0].Lead__c,'Lead');
        Test.stopTest();
    }

}