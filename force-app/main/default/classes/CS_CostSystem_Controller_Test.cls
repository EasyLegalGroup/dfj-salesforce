@isTest
public with sharing class CS_CostSystem_Controller_Test {
    @isTest
    private static void GetAllTheMarketingCampaign_test(){
        DFJ_TestDataFactory.CreateMarketCampaignsWithSpendPeriod(1,1);
        Test.startTest();
        CS_CostSystem_Controller.CampaignWrapper campignWrapperIns = CS_CostSystem_Controller.GetAllTheMarketingCampaign_Apex();
        Test.stopTest();
        System.assertEquals(1, campignWrapperIns.marketingCampaignList.size());
    }

    @isTest
    private static void SaveMarketingCampaign_test(){
        List<Marketing_Campaign__c> marketingCampaignList= DFJ_TestDataFactory.CreateMarketCampaigns(2);
        Test.startTest();
        String campaignId = CS_CostSystem_Controller.SaveMarketingCampaign(JSON.serialize(new Marketing_Campaign__c(Name='Test MC',Cost_Category__c='Other')));
        String campaignId2 = CS_CostSystem_Controller.SaveMarketingCampaign(JSON.serialize(''));
        String campaignId3 = CS_CostSystem_Controller.SaveMarketingCampaign('');
        Test.stopTest();
        Marketing_Campaign__c campaignInstance = [select Id,Name,Cost_Category__c FROM Marketing_Campaign__c WHERE Id=:campaignId LIMIT 1];
        System.assertEquals('Test MC', campaignInstance.Name);
        System.assertEquals(null, campaignId2);
        System.assertEquals(null, campaignId3);
    }

    @isTest
    private static void DeleteMarketingCampaign_test(){
        List<Marketing_Campaign__c> marketingCampaignList= DFJ_TestDataFactory.CreateMarketCampaigns(2);
        List<Marketing_Campaign__c> marketingCampaignList2= DFJ_TestDataFactory.CreateMarketCampaigns(2);
        Test.startTest();
        Boolean deleted = CS_CostSystem_Controller.DeleteMarketingCampaign('');
        CS_CostSystem_Controller.DeleteMarketingCampaign(marketingCampaignList[0].Id);
        delete marketingCampaignList2[0];
        Boolean deleted2 = CS_CostSystem_Controller.DeleteMarketingCampaign(marketingCampaignList2[0].Id);
        Test.stopTest();
        list<Marketing_Campaign__c> campaignInstance = [select Id,Name,Cost_Category__c FROM Marketing_Campaign__c LIMIT 10000];
        System.assertEquals(2, campaignInstance.size());
        System.assertEquals(false, deleted);
        System.assertEquals(false, deleted2);
    }

    @isTest
    private static void CalculateSpendAndNoSpendPeriod_Test(){
        List<Marketing_Spend_Period__c> marketingCampaignList= DFJ_TestDataFactory.CreateMarketCampaignsWithSpendPeriod(0,1);
        List<Marketing_Spend_Period__c> marketingCampaignList2 = DFJ_TestDataFactory.CreateMarketCampaignsWithSpendPeriod(1,1);
        Test.startTest();
        String processed = CS_CostSystem_Controller.CalculateSpendPerLead('');
        String processed2 = CS_CostSystem_Controller.CalculateSpendPerLead('1234');
        String processed3 = CS_CostSystem_Controller.CalculateSpendPerLead(marketingCampaignList[0].Id);
        String processed4 = CS_CostSystem_Controller.CalculateSpendPerLead(marketingCampaignList2[0].Id);
        Test.stopTest();
        System.assertEquals('Can not find spend period.', processed);
        System.assertEquals('Spend period not found.', processed2);
        System.assertEquals('Spend period not found.', processed2);
        System.assertEquals('lead records not found for this spend period.', processed4);
    }

    @isTest
    private static void CalculateSpendAndWithLead_Test(){
        List<Marketing_Spend_Period__c> marketingCampaignList= DFJ_TestDataFactory.CreateMarketCampaignsWithSpendPeriod(1,1);
        List<Lead> leadList = DFJ_TestDataFactory.CreateLeadWithHarAccepteFied(2);
        
        Test.startTest();
        String processed = CS_CostSystem_Controller.CalculateSpendPerLead(marketingCampaignList[0].Id);
        Test.stopTest();
        System.assertEquals('Total 2 leads processed and each one costs 500.00', processed);
    }

    @isTest
    private static void CalculateSpendAndWithLeadAndLedger_Test(){
        List<Marketing_Spend_Period__c> marketingSpendPeriod = DFJ_TestDataFactory.CreateMarketCampaignsWithSpendPeriod(1,1);
        List<Lead> leadList = DFJ_TestDataFactory.CreateleadWithLedger(1,1,marketingSpendPeriod[0].Marketing_campaign__c,marketingSpendPeriod[0].Id);
        Test.startTest();
        String processed = CS_CostSystem_Controller.CalculateSpendPerLead(marketingSpendPeriod[0].Id);
        Test.stopTest();
        System.assertEquals('Total 1 leads processed and each one costs 1000.00', processed);
    }

    @isTest
    private static void ReprocessUnprocessedLeads_Test(){
        List<Marketing_Campaign__c> marketCampaigns = DFJ_TestDataFactory.CreateMarketCampaigns(1);
        CS_Utility.ProcessPeriod processPeriodInstance = new CS_Utility.ProcessPeriod();
        processPeriodInstance.fromDate = System.now().addDays(-1);
        processPeriodInstance.toDate = System.now().addDays(1);
        Test.startTest();
        CS_CostSystem_Controller.ReprocessUnprocessedLeads(marketCampaigns[0].Id,JSON.serialize(processPeriodInstance));
        Test.stopTest();
    }
    
    @isTest
    private static void CreateCostLedgerForUnprocessedLeads_Test(){
        List<Marketing_Spend_Period__c> marketingSpendPeriod = DFJ_TestDataFactory.CreateMarketCampaignsWithSpendPeriod(1,1);
        List<Lead> leadList = DFJ_TestDataFactory.CreateleadWithLedger(1,1,marketingSpendPeriod[0].Marketing_campaign__c,marketingSpendPeriod[0].Id);
        List<Cost_Ledger__c> ledgerList = [SELECT Id,Name,Lead__c,Marketing_campaign__c,Marketing_Spend__c,Cost_type__c,Amount_of_cost__c,Time_of_cost__c FROM Cost_Ledger__c];
        List<Cost_Ledger__c> ledgerList2 = new List<Cost_Ledger__c>();
        ledgerList2.add(new Cost_Ledger__c(Lead__c=leadList[0].Id));
        Test.startTest();
        String processed = CS_CostSystem_Controller.CreateCostLedgerForUnprocessedLeads(JSON.serialize(ledgerList2), JSON.serialize(leadList));
        String processed2 = CS_CostSystem_Controller.CreateCostLedgerForUnprocessedLeads(JSON.serialize(ledgerList), JSON.serialize(leadList));
        Test.stopTest();
        System.assertEquals('Processed the leads successfully', processed);
        System.assertEquals('Something went wrong.', processed2);
    }

    @isTest
    private static void CreateCostLedgerForUnprocessedLeads2_Test(){
        List<Marketing_Campaign__c> marketingcampaign = DFJ_TestDataFactory.CreateSpendWithMarketingCampaign(1,1);
        List<Lead> leadList = DFJ_TestDataFactory.CreateleadWithLedger(1,1,'','');
        List<Cost_Ledger__c> ledgerList = [SELECT Id,Name,Lead__c,Marketing_campaign__c,Marketing_Spend__c,Cost_type__c,Amount_of_cost__c,Time_of_cost__c FROM Cost_Ledger__c];
        CS_Utility.ProcessPeriod processPeriodInstance = new CS_Utility.ProcessPeriod();
        processPeriodInstance.fromDate = System.now().addDays(-1);
        processPeriodInstance.toDate = System.now().addDays(1);
        Test.startTest();
        CS_CostSystem_Controller.LeadSpendPeriodWrapper processed = CS_CostSystem_Controller.ReprocessUnprocessedLeads(marketingcampaign[0].Id, JSON.serialize(processPeriodInstance) );
        Test.stopTest();
        System.assertEquals('success', processed.message);
    }

    @isTest
    static void FetchMarketingCampaignBySendingEmpty() {
        Test.startTest();
        List<Marketing_Campaign__c> success = CS_Utility.FetchMarketingCampaign(null);
        List<Marketing_Campaign__c> success3 = CS_Utility.FetchRecordsByQuery('',null,'','');
        List<Marketing_Campaign__c> success2 = CS_Utility.FetchMarketingCampaign(new List<String>());
        Test.stopTest();
        System.assertEquals(null, success);
        System.assertEquals(null, success2);
        System.assertEquals(null, success3);
    }

    

    @isTest
    static void CreateMarketSpendPeriodWithEmpty() {
        Test.startTest();
        String query = CS_Selector.FetchMarketingSpendPeriod(null,'','');
        String query2 = CS_Selector.FetchMarketingSpendPeriod(new List<String>(),'','');
        Test.stopTest();
        System.assertEquals(null, query);
        System.assertEquals(null, query2);
    }

    @isTest
    static void CreateLeadWithEmptyFieldsList() {
        Test.startTest();
        String query = CS_Selector.FetchLeadsQuery(null,'','');
        String query2 = CS_Selector.FetchLeadsQuery(new List<String>(),'','');
        Test.stopTest();
        System.assertEquals(null, query);
        System.assertEquals(null, query2);
    }

    @isTest
    static void UpdateCampaignWithUpdatedPeriods() {
        List<Marketing_Campaign__c> marketingcampaign = DFJ_TestDataFactory.CreateSpendWithMarketingCampaign(1,1);
        List <Marketing_Spend_Period__c> spendpPeriodList = [SELECT Id,Name FROM Marketing_Spend_Period__c LIMIT 10];
        Test.startTest();
        CS_CostSystem_Controller.CampaignWrapper CampaignWrapperInstance = CS_CostSystem_Controller.UpdateCampaignWithUpdatedPeriods('', '', '');
        CS_CostSystem_Controller.CampaignWrapper CampaignWrapperInstance3 = CS_CostSystem_Controller.UpdateCampaignWithUpdatedPeriods(JSON.serialize(marketingcampaign[0]), JSON.serialize(spendpPeriodList), '');
        Test.stopTest();
        System.assertEquals(null, CampaignWrapperInstance);

    }

    @isTest
    static void DeleteSpendPeriodWhilUpdatingCampaign() {
        List<Marketing_Campaign__c> marketingcampaign = DFJ_TestDataFactory.CreateSpendWithMarketingCampaign(1,1);
        List <Marketing_Spend_Period__c> spendpPeriodList = [SELECT Id,Name FROM Marketing_Spend_Period__c LIMIT 1];
        Test.startTest();
        CS_CostSystem_Controller.CampaignWrapper CampaignWrapperInstance3 = CS_CostSystem_Controller.UpdateCampaignWithUpdatedPeriods(JSON.serialize(marketingcampaign[0]), '',JSON.serialize(spendpPeriodList));
        Test.stopTest();
        List <Marketing_Spend_Period__c> spendpPeriodToConfirm = [SELECT Id,Name FROM Marketing_Spend_Period__c LIMIT 10];
        System.assertEquals(0, spendpPeriodToConfirm.size());

    }
    
    @isTest
    static void UpdateMarketingCampaignWillAllRelatedSpends() {

        Test.startTest();
        String query = CS_Selector.FetchAccountQuery(null,'','');
        String query2 = CS_Selector.FetchAccountQuery(new List<String>(),'','');
        Test.stopTest();
        System.assertEquals(null, query);
        System.assertEquals(null, query2);

    }

    @isTest
    static void UtilityCodeCoverage() {

        Test.startTest();
        String query = CS_Utility.QueryToFetchAccount('asdf', '');
        String query1 = CS_Utility.QueryToFetchLeads('asdf', '');
        String query2 = CS_Utility.QueryToFetchSpendPeriod('asdf', '');
        Test.stopTest();
        System.assertEquals(null, query);
        System.assertEquals(null, query1);
        System.assertEquals(null, query2);

    }
}