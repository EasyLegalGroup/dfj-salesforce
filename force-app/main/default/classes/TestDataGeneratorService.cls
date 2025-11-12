/**
 * @description Service class to generate test data for sandbox initialization
 * @author Copilot
 * @date 2025
 * 
 * Generates:
 * - 20 Leads with various Market Units, Record Types, and Statuses
 * - 10 PersonAccounts (converted from 10 of the Leads)
 * - 13 Orders (10 PersonAccounts: 7 with 1 order, 3 with 2 orders)
 * - 13 Journals with bidirectional relationship to Orders
 */
public with sharing class TestDataGeneratorService {
    
    /**
     * @description LWC-callable method to generate test data
     */
    @AuraEnabled
    public static TestDataResult generateTestData() {
        List<TestDataResult> results = generateTestDataInternal();
        return results.isEmpty() ? new TestDataResult() : results[0];
    }
    
    /**
     * @description Invocable method for Flow/Process Builder
     */
    @InvocableMethod(
        label='Generate Test Data' 
        description='Generates test Leads, PersonAccounts, Orders, and Journals for sandbox testing'
        category='Test Data'
    )
    public static List<TestDataResult> generateTestDataInternal() {
        List<TestDataResult> results = new List<TestDataResult>();
        
        try {
            // Get Record Type IDs
            Map<String, Id> leadRecordTypes = getLeadRecordTypes();
            Map<String, Id> accountRecordTypes = getAccountRecordTypes();
            
            // Step 1: Create 20 Leads with various attributes
            List<Lead> leadsToInsert = createLeads(leadRecordTypes);
            insert leadsToInsert;
            
            // Step 2: Convert 10 Leads to PersonAccounts
            List<Id> convertedAccountIds = convertLeadsToPersonAccounts(leadsToInsert, accountRecordTypes);
            
            // Step 3: Create 13 Orders on the converted PersonAccounts
            List<Order> ordersToInsert = createOrders(convertedAccountIds);
            insert ordersToInsert;
            
            // Step 4: Create 13 Journals with bidirectional relationship to Orders
            List<Journal__c> journalsToInsert = createJournals(convertedAccountIds, ordersToInsert);
            insert journalsToInsert;
            
            // Step 5: Update Orders with Journal lookups to complete bidirectional relationship
            updateOrdersWithJournals(ordersToInsert, journalsToInsert);
            
            // Build success result
            TestDataResult result = new TestDataResult();
            result.success = true;
            result.message = String.format(
                'Successfully created {0} Leads, {1} PersonAccounts, {2} Orders, and {3} Journals',
                new List<Object>{
                    leadsToInsert.size(),
                    convertedAccountIds.size(),
                    ordersToInsert.size(),
                    journalsToInsert.size()
                }
            );
            result.leadCount = leadsToInsert.size();
            result.accountCount = convertedAccountIds.size();
            result.orderCount = ordersToInsert.size();
            result.journalCount = journalsToInsert.size();
            results.add(result);
            
        } catch (Exception e) {
            TestDataResult result = new TestDataResult();
            result.success = false;
            result.message = 'Error generating test data: ' + e.getMessage();
            result.errorDetails = e.getStackTraceString();
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * Get Lead Record Type IDs
     */
    private static Map<String, Id> getLeadRecordTypes() {
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Lead' 
            AND IsActive = true
        ]) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }
        return recordTypeMap;
    }
    
    /**
     * Get Account Record Type IDs
     */
    private static Map<String, Id> getAccountRecordTypes() {
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Account' 
            AND IsActive = true
        ]) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }
        return recordTypeMap;
    }
    
    /**
     * Create 20 Leads with various Market Units, Record Types, and Statuses
     */
    private static List<Lead> createLeads(Map<String, Id> leadRecordTypes) {
        List<Lead> leads = new List<Lead>();
        List<String> statuses = new List<String>{'New', 'Contacted', 'Qualified', 'Unqualified'};
        List<String> sources = new List<String>{'Website Contact Form', 'Inbound Phone', 'Lecture', 'Reference'};
        
        // Create 5 DFJ_DK Leads
        for (Integer i = 1; i <= 5; i++) {
            Lead l = new Lead();
            l.FirstName = 'Test DK';
            l.LastName = 'Lead ' + i;
            l.Company = 'Test Company DK ' + i;
            l.Market_Unit__c = 'DFJ_DK';
            l.RecordTypeId = leadRecordTypes.get('DFJ_DK');
            l.Status = statuses[Math.mod(i, statuses.size())];
            l.LeadSource = sources[Math.mod(i, sources.size())];
            l.Email = 'testdk' + i + '@example.com';
            l.Phone = '+45' + String.valueOf(10000000 + i);
            l.Civil_Status__c = Math.mod(i, 2) == 0 ? 'Gift' : 'Enlig';
            leads.add(l);
        }
        
        // Create 5 FA_SE Leads
        for (Integer i = 1; i <= 5; i++) {
            Lead l = new Lead();
            l.FirstName = 'Test SE';
            l.LastName = 'Lead ' + i;
            l.Company = 'Test Company SE ' + i;
            l.Market_Unit__c = 'FA_SE';
            l.RecordTypeId = leadRecordTypes.get('FA_SE');
            l.Status = statuses[Math.mod(i, statuses.size())];
            l.LeadSource = sources[Math.mod(i, sources.size())];
            l.Email = 'testse' + i + '@example.com';
            l.Phone = '+46' + String.valueOf(700000000 + i);
            l.Marital_Status__c = Math.mod(i, 2) == 0 ? 'Married' : 'Single';
            leads.add(l);
        }
        
        // Create 5 Ireland Leads
        for (Integer i = 1; i <= 5; i++) {
            Lead l = new Lead();
            l.FirstName = 'Test IE';
            l.LastName = 'Lead ' + i;
            l.Company = 'Test Company IE ' + i;
            l.Market_Unit__c = 'Ireland';
            l.RecordTypeId = leadRecordTypes.get('Ireland');
            l.Status = statuses[Math.mod(i, statuses.size())];
            l.LeadSource = sources[Math.mod(i, sources.size())];
            l.Email = 'testie' + i + '@example.com';
            l.Phone = '+353' + String.valueOf(800000000 + i);
            l.Marital_Status__c = Math.mod(i, 2) == 0 ? 'Married' : 'Cohabiting';
            leads.add(l);
        }
        
        // Create 5 Host Leads (B2B)
        for (Integer i = 1; i <= 5; i++) {
            Lead l = new Lead();
            l.FirstName = 'Test Host';
            l.LastName = 'Lead ' + i;
            l.Company = 'Host Company ' + i;
            l.RecordTypeId = leadRecordTypes.get('Host');
            l.Status = statuses[Math.mod(i, statuses.size())];
            l.LeadSource = sources[Math.mod(i, sources.size())];
            l.Email = 'testhost' + i + '@example.com';
            l.Phone = '+45' + String.valueOf(20000000 + i);
            l.Leadtype__c = 'B2B';
            l.Host_Type__c = 'Company';
            leads.add(l);
        }
        
        return leads;
    }
    
    /**
     * Convert 10 Leads to PersonAccounts (2 from each Market Unit type + all Host)
     */
    private static List<Id> convertLeadsToPersonAccounts(List<Lead> allLeads, Map<String, Id> accountRecordTypes) {
        List<Id> convertedAccountIds = new List<Id>();
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        
        // Get converted status
        LeadStatus convertStatus = [
            SELECT MasterLabel 
            FROM LeadStatus 
            WHERE IsConverted = true 
            LIMIT 1
        ];
        
        // Convert first 2 from each regular market unit (6 total) + all 4 Host leads (10 total)
        Integer leadsToConvert = 0;
        for (Lead l : allLeads) {
            // Convert 2 from each B2C market unit and all Host leads
            if ((l.Market_Unit__c == 'DFJ_DK' && leadsToConvert < 2) ||
                (l.Market_Unit__c == 'FA_SE' && leadsToConvert >= 2 && leadsToConvert < 4) ||
                (l.Market_Unit__c == 'Ireland' && leadsToConvert >= 4 && leadsToConvert < 6) ||
                (l.Leadtype__c == 'B2B' && leadsToConvert >= 6 && leadsToConvert < 10)) {
                
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(l.Id);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                lc.setDoNotCreateOpportunity(true);
                leadConverts.add(lc);
                leadsToConvert++;
            }
            
            if (leadsToConvert >= 10) {
                break;
            }
        }
        
        // Perform bulk conversion
        List<Database.LeadConvertResult> results = Database.convertLead(leadConverts, true);
        
        // Collect converted Account IDs
        for (Database.LeadConvertResult result : results) {
            if (result.isSuccess()) {
                convertedAccountIds.add(result.getAccountId());
            }
        }
        
        // Update Accounts with Lead lookup
        List<Account> accountsToUpdate = [
            SELECT Id, Lead__c 
            FROM Account 
            WHERE Id IN :convertedAccountIds
        ];
        
        Map<Id, Lead> leadMap = new Map<Id, Lead>([
            SELECT Id, ConvertedAccountId 
            FROM Lead 
            WHERE ConvertedAccountId IN :convertedAccountIds
        ]);
        
        for (Account acc : accountsToUpdate) {
            for (Lead l : leadMap.values()) {
                if (l.ConvertedAccountId == acc.Id) {
                    acc.Lead__c = l.Id;
                    break;
                }
            }
        }
        
        update accountsToUpdate;
        
        return convertedAccountIds;
    }
    
    /**
     * Create 13 Orders on 10 PersonAccounts (7 with 1 order, 3 with 2 orders)
     */
    private static List<Order> createOrders(List<Id> accountIds) {
        List<Order> orders = new List<Order>();
        
        if (accountIds.isEmpty()) {
            return orders;
        }
        
        // Get standard pricebook
        Id pricebookId = Test.isRunningTest() ? 
            Test.getStandardPricebookId() : 
            [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
        
        // Create 1 order for first 7 accounts
        for (Integer i = 0; i < 7 && i < accountIds.size(); i++) {
            Order o = new Order();
            o.AccountId = accountIds[i];
            o.Status = 'Draft';
            o.EffectiveDate = Date.today();
            o.Pricebook2Id = pricebookId;
            orders.add(o);
        }
        
        // Create 2 orders for next 3 accounts
        for (Integer i = 7; i < 10 && i < accountIds.size(); i++) {
            // First order
            Order o1 = new Order();
            o1.AccountId = accountIds[i];
            o1.Status = 'Draft';
            o1.EffectiveDate = Date.today();
            o1.Pricebook2Id = pricebookId;
            orders.add(o1);
            
            // Second order
            Order o2 = new Order();
            o2.AccountId = accountIds[i];
            o2.Status = 'Activated';
            o2.EffectiveDate = Date.today().addDays(-30);
            o2.Pricebook2Id = pricebookId;
            orders.add(o2);
        }
        
        return orders;
    }
    
    /**
     * Create 13 Journals with lookup to Orders (one Journal per Order)
     */
    private static List<Journal__c> createJournals(List<Id> accountIds, List<Order> orders) {
        List<Journal__c> journals = new List<Journal__c>();
        
        // Get Leads from Accounts
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Lead__c 
            FROM Account 
            WHERE Id IN :accountIds
        ]);
        
        // Create one Journal per Order
        for (Order o : orders) {
            Journal__c j = new Journal__c();
            j.Account__c = o.AccountId;
            j.Order__c = o.Id;
            
            // Set Lead lookup if available
            if (accountMap.containsKey(o.AccountId) && accountMap.get(o.AccountId).Lead__c != null) {
                j.Lead__c = accountMap.get(o.AccountId).Lead__c;
            }
            
            journals.add(j);
        }
        
        return journals;
    }
    
    /**
     * Update Orders with Journal lookups to complete bidirectional relationship
     */
    private static void updateOrdersWithJournals(List<Order> orders, List<Journal__c> journals) {
        // Create map of Order ID to Journal ID
        Map<Id, Id> orderToJournalMap = new Map<Id, Id>();
        for (Journal__c j : journals) {
            if (j.Order__c != null) {
                orderToJournalMap.put(j.Order__c, j.Id);
            }
        }
        
        // Update Orders with Journal lookups
        for (Order o : orders) {
            if (orderToJournalMap.containsKey(o.Id)) {
                o.Journal__c = orderToJournalMap.get(o.Id);
            }
        }
        
        update orders;
    }
    
    /**
     * Wrapper class for Invocable Method result
     */
    public class TestDataResult {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String message;
        
        @InvocableVariable
        public String errorDetails;
        
        @InvocableVariable
        public Integer leadCount;
        
        @InvocableVariable
        public Integer accountCount;
        
        @InvocableVariable
        public Integer orderCount;
        
        @InvocableVariable
        public Integer journalCount;
    }
}
