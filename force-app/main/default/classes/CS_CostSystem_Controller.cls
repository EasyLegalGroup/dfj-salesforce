/*
   * @ Version : 1.0
   * @ Created Date : 2021-12-15
   * @Description : Controller class for CostSystem for lead and account.
*/
public with sharing class CS_CostSystem_Controller {
    /*
    * @Description  method to get the marketing campaign records.
    * @Return       CampaignWrapper
    */
    @AuraEnabled
    public static CampaignWrapper GetAllTheMarketingCampaign_Apex(){
        try{
            CampaignWrapper campaignWrapperInstance = new CampaignWrapper();
            List<Marketing_Campaign__c> campaignList = new List<Marketing_Campaign__c>();
            campaignList = [SELECT Id,Name,UTM_Campaign__c,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,Cost_Category__c FROM Marketing_Campaign__c ORDER BY LastModifiedDate DESC LIMIT 10000];
            List<PicklistOptions> picklistOptions = GetAllPicklistValues_Apex('Marketing_Campaign__c','Cost_Category__c');
            if(picklistOptions != null && !picklistOptions.isEmpty()){
                campaignWrapperInstance.picklistOptions = picklistOptions;
            }
            // Changes for DIN-237 : Manage spend periods on marketing campaign.
            // Description : Fetching spend periods
            // Start
            List<Marketing_Spend_Period__c> spendPeriodList = new List<Marketing_Spend_Period__c>();
            spendPeriodList = [SELECT Id,Name,Marketing_Campaign__c,Period_end_time__c,Period_start_time__c,Total_spend__c,Lead_Processed__c FROM Marketing_Spend_Period__c ORDER BY Period_start_time__c DESC LIMIT 10000];
            if (!spendPeriodList.isEmpty()) {
                campaignWrapperInstance.spendPeriodList = spendPeriodList;
            }
            // End
            if (!campaignList.isEmpty()) {
                campaignWrapperInstance.marketingCampaignList = campaignList;
                
            }
            return campaignWrapperInstance;
        } catch(Exception ex){
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_CostSystem_Controller.GetAllTheMarketingCampaign_Apex', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  method to save the marketing campaign record.
    * @Params marketingCampaignInstance
    * @Return       String 
    */
    @AuraEnabled
    public static String SaveMarketingCampaign(String marketingCampaignInstance){
        try {
            if (String.isBlank(marketingCampaignInstance)) {
                return null;
            }
            Marketing_Campaign__c marketingCampaign = (Marketing_Campaign__c) JSON.deserialize(marketingCampaignInstance,Marketing_Campaign__c.class);
            if (marketingCampaign != null) {
                upsert marketingCampaign;
                return marketingCampaign.Id;
            }
            
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_CostSystem_Controller.SaveMarketingCampaign', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }
    
    /*
    * @Description  method to delete the marketing campaign record and related spend period records.
    * @Params campaignIdToBeDeleted
    * @Return       Boolean
    */
    @AuraEnabled
    public static Boolean DeleteMarketingCampaign(string campaignIdToBeDeleted){
        try {
            if(String.isBlank(campaignIdToBeDeleted)){
                return false;
            }
            List<Marketing_Spend_Period__c> spendPeriodList = new List<Marketing_Spend_Period__c>();
            spendPeriodList = [SELECT Id,Name,Marketing_Campaign__c,Period_end_time__c,Period_start_time__c,Total_spend__c FROM Marketing_Spend_Period__c WHERE Marketing_Campaign__c=:campaignIdToBeDeleted LIMIT 10000];
            if (!spendPeriodList.isEmpty()) {
                delete spendPeriodList;
            }
            List<Marketing_Campaign__c> CampaignListTodelete = new List<Marketing_Campaign__c>();
            CampaignListTodelete = [SELECT Id,Name FROM Marketing_Campaign__c WHERE Id =: campaignIdToBeDeleted LIMIT 1];
            if(!CampaignListTodelete.isEmpty()){
                delete CampaignListTodelete;
                return true;
            }
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_CostSystem_Controller.DeleteMarketingCampaign', String.valueOf(ex.getLineNumber()));
        }
        return false;
    }
    

    /*
    * @Description  This method will return the picklist options by accpting objectAPIName and fieldApiName.
    * @Params objectApiName,fieldApiName
    * @Return       List<PicklistOptions>
    */
    public static List<PicklistOptions> GetAllPicklistValues_Apex(String objectApiName, String fieldApiName){
        List<PicklistOptions> picklistOptionList = new List<PicklistOptions>();
        try {
            Schema.SObjectType obj_describe = Schema.getGlobalDescribe().get(objectApiName) ;
            Schema.DescribeSObjectResult obj_describe_result = obj_describe.getDescribe() ;
            Map<String,Schema.SObjectField> fields = obj_describe_result.fields.getMap() ;
            Schema.DescribeFieldResult fieldResult = fields.get(fieldApiName).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            PicklistOptions option = null;
            for (Schema.PicklistEntry pickListVal : ple) {
                option = new PicklistOptions(pickListVal.getLabel(), pickListVal.getValue());
                picklistOptionList.add(option);
            }
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Getting all picklist options.', ex.getMessage(), 'Error', 'CS_CostSystem_Controller.GetAllPicklistValues_Apex', String.valueOf(ex.getLineNumber()));
        }
        return picklistOptionList;
    }

    /*
    * @Description  This method is for campaign spend process.
    * @Params       spendPeriod
    * @Return       
    */
    @AuraEnabled
    public static String CalculateSpendPerLead(String spendPeriodId){
        try {
            if (String.isBlank(spendPeriodId)) {
                return 'Can not find spend period.';
            }
            List<Marketing_Spend_Period__c> spendPeriod = CS_Utility.FetchRecordsByQuery('SELECT Id,Name,Marketing_Campaign__c,Period_end_time__c,Period_start_time__c,Total_spend__c,Lead_Processed__c FROM Marketing_Spend_Period__c WHERE Id=\''+spendPeriodId+'\' LIMIT 10000',null,null,null);
            if (spendPeriod== null || spendPeriod.isEmpty()) {
                return 'Spend period not found.';
            }
            List<Marketing_Campaign__c> marketingCampaignList = CS_Utility.FetchMarketingCampaign(new List<String> {spendPeriod[0].Marketing_Campaign__c});
            if (marketingCampaignList== null || marketingCampaignList.isEmpty()) {

                return 'Market campaign not found corresponding to spend period.';
            }

            String marketingConditionForLead = '';
            marketingConditionForLead = String.isBlank(marketingCampaignList[0].UTM_Campaign__c) ? marketingConditionForLead + '' : marketingConditionForLead + ' UTM_Campaign__c =\''+marketingCampaignList[0].UTM_Campaign__c+'\' AND ';
            marketingConditionForLead = String.isBlank(marketingCampaignList[0].UTM_Content__c) ? marketingConditionForLead + '' : marketingConditionForLead + ' UTM_Content__c =\''+ marketingCampaignList[0].UTM_Content__c+'\' AND ';
            marketingConditionForLead = String.isBlank(marketingCampaignList[0].UTM_Medium__c) ? marketingConditionForLead + '' : marketingConditionForLead + ' UTM_Medium__c =\''+marketingCampaignList[0].UTM_Medium__c+'\' AND ';
            marketingConditionForLead = String.isBlank(marketingCampaignList[0].UTM_Source__c) ? marketingConditionForLead + '' : marketingConditionForLead + ' UTM_Source__c =\''+marketingCampaignList[0].UTM_Source__c+'\' AND ';
            marketingConditionForLead = String.isBlank(marketingCampaignList[0].UTM_Term__c) ? marketingConditionForLead + '' : marketingConditionForLead + ' UTM_Term__c =\''+marketingCampaignList[0].UTM_Term__c+'\' AND ';

            String leadQueryToFetch = 'SELECT Id,Name,IsConverted,CreatedDate,Marketing_Campaign__c FROM Lead WHERE';
            String createDateOfLeadCondition = ' CreatedDate >='+ String.valueOf(spendPeriod[0].Period_start_time__c).replace(' ', 'T')+'.000Z'+ ' AND CreatedDate <' + String.valueOf(spendPeriod[0].Period_end_time__c).replace(' ', 'T')+'.000Z';
            leadQueryToFetch = String.isBlank(marketingConditionForLead) ? leadQueryToFetch + createDateOfLeadCondition +' LIMIT 10000 ' : leadQueryToFetch + marketingConditionForLead + createDateOfLeadCondition +' LIMIT 10000 ';
            
            List<Lead> filteredLead = Database.query(leadQueryToFetch);

            if (filteredLead == null || filteredLead.isEmpty()) {
                spendPeriod[0].Lead_Processed__c = 0;
                update spendPeriod;
                return 'lead records not found for this spend period.';
            }
            Set<String> leadIds = new Set<String>();
            for (Lead leadloop : filteredLead) {
                leadIds.add(leadloop.Id);
            }

            Decimal spendPerLead = spendPeriod[0].Total_spend__c != null ? spendPeriod[0].Total_spend__c/filteredLead.size() : 0;
            String queryToFetchCLRecordsToDelete = 'SELECT Id,Name,Lead__c,Marketing_campaign__c,Marketing_Spend__c,Cost_type__c,Amount_of_cost__c,Time_of_cost__c FROM Cost_Ledger__c WHERE Marketing_Spend__c=\''+spendPeriod[0].Id + '\' LIMIT 10000';
            List<Cost_Ledger__c> costLedgers = CS_Utility.FetchRecordsByQuery(queryToFetchCLRecordsToDelete,null,null,null);
            // Changes for DIN-247 : When running spend period process script we must delete all cost ledgers for that period
            // Description : deleteing the costledger record for spend period which is running.
            // Start
            if (costLedgers != null && !costLedgers.isEmpty()) {
                delete costLedgers;
            }
            // End
            
            List<Account> accountList = CS_Utility.FetchRecordsByQuery('SELECT Id,Name,Lead__c FROM Account WHERE Lead__c IN:leadIds LIMIT 10000',leadIds,null,null);
            Map<Id,Account> leadIdVsAccountMap = new Map<Id,Account>();
            if (accountList != null && !accountList.isEmpty()) {
                for (Account accountLoop : accountList) {
                    if (!leadIdVsAccountMap.containsKey(accountLoop.Lead__c)) {
                        leadIdVsAccountMap.put(accountLoop.Lead__c,accountLoop);
                    }
                }
            }
            

            List<Cost_Ledger__c> costLedgerList = new List<Cost_Ledger__c>();
            for (Lead leadloop : filteredLead) {
                // DIN-230 : Create lookup of Lead on Marketing Campaign
                // Description : populating the marketing campaign field;
                // Start
                leadloop.Marketing_Campaign__c = marketingCampaignList[0].Id;
                // End
                
                Cost_Ledger__c newCostLedgerInstance = new Cost_Ledger__c();
                newCostLedgerInstance.Cost_type__c = marketingCampaignList[0].Cost_Category__c;
                newCostLedgerInstance.Amount_of_cost__c = spendPerLead;
                newCostLedgerInstance.Lead__c = leadloop.Id;
                newCostLedgerInstance.Time_of_cost__c = leadloop.CreatedDate;
                newCostLedgerInstance.Marketing_campaign__c = marketingCampaignList[0].Id;
                newCostLedgerInstance.Marketing_Spend__c = spendPeriod[0].Id;
                // Changes for DIN-233 : When adding cost ledger to converted lead, account id must be set.
                // Description : Populating account field when lead is converted.
                // Start
                if (leadloop.IsConverted) {
                    newCostLedgerInstance.Account__c = leadIdVsAccountMap.get(leadloop.Id)?.Id;
                }
                // End
                costLedgerList.add(newCostLedgerInstance);
            }
            
            if (!costLedgerList.isEmpty()) {
                insert costLedgerList;
                update filteredLead;
                spendPeriod[0].Lead_Processed__c = filteredLead.size();
                update spendPeriod;
                return 'Total '+ filteredLead.size()+' leads processed and each one costs '+spendPerLead.setScale(2);
            }
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_CostSystem_Controller.CalculateSpendPerLead', String.valueOf(ex.getLineNumber()));
        }
        return 'Something went wrong.';
    }

    /*
    * @Description  This method is for campaign spend process.
    * @Params       spendPeriod
    * @Return       
    */
    @AuraEnabled
    public static LeadSpendPeriodWrapper ReprocessUnprocessedLeads(String marketingCampaignId,String processPeriod){
        LeadSpendPeriodWrapper leadSpendPeriodWrapperInstance = new LeadSpendPeriodWrapper();
        try {
            if (String.isBlank(marketingCampaignId) || String.isBlank(processPeriod)) {
                leadSpendPeriodWrapperInstance.message = 'Marketing campaign or reprocess time empty.';
                return leadSpendPeriodWrapperInstance;
            }
            CS_Utility.ProcessPeriod processPeriodInstance = (CS_Utility.ProcessPeriod) JSON.deserialize(processPeriod, CS_Utility.ProcessPeriod.class);
            // Building spend period query.
            String conditionForQuery = 'Marketing_Campaign__c =\''+ marketingCampaignId +'\' AND Period_start_time__c >'+ String.valueOf(processPeriodInstance.fromDate).replace(' ', 'T')+'.000Z'+' AND Period_end_time__c > '+ String.valueOf(processPeriodInstance.fromDate).replace(' ', 'T')+'.000Z' + ' AND Period_start_time__c < '+ String.valueOf(processPeriodInstance.toDate).replace(' ', 'T')+'.000Z'+' AND Period_end_time__c <'+ String.valueOf(processPeriodInstance.toDate).replace(' ', 'T')+'.000Z'+'';
            String queryToFetchRecords = CS_Utility.QueryToFetchSpendPeriod(conditionForQuery, 'LIMIT 10000');
            if (String.isBlank(queryToFetchRecords)) {
                leadSpendPeriodWrapperInstance.message = 'Can not find spend periods.';
                return leadSpendPeriodWrapperInstance;
            }

            // Fetching spend period records
            List<Marketing_Spend_Period__c> spendPeriodsList = CS_Utility.FetchRecordsByQuery(queryToFetchRecords,new Set<String>(),marketingCampaignId,processPeriod);
            if (spendPeriodsList == null || spendPeriodsList.isEmpty() || spendPeriodsList.size() > 20) {
                leadSpendPeriodWrapperInstance.message = spendPeriodsList == null || spendPeriodsList.isEmpty() ? 'Spend period not found.' : 'Can not process more than 20 spend periods.';
                return leadSpendPeriodWrapperInstance;
            }
            conditionForQuery = 'Marketing_Campaign__c=null AND CreatedDate > '+String.valueOf(processPeriodInstance.fromDate).replace(' ', 'T')+'.000Z'+' AND CreatedDate < '+ String.valueOf(processPeriodInstance.toDate).replace(' ', 'T')+'.000Z';
            queryToFetchRecords = CS_Utility.QueryToFetchLeads(conditionForQuery, 'LIMIT 10000');

            if (String.isBlank(queryToFetchRecords)) {
                leadSpendPeriodWrapperInstance.message = 'Can not find leads.';

                return leadSpendPeriodWrapperInstance;
            }

            // Fetching leads records
            List<Lead> leadList = CS_Utility.FetchRecordsByQuery(queryToFetchRecords,new Set<String>(),marketingCampaignId,processPeriod);
            if (leadList == null || leadList.isEmpty()) {
                leadSpendPeriodWrapperInstance.message = 'Lead records not found.';
                return leadSpendPeriodWrapperInstance;
            }

            conditionForQuery = 'Lead__c IN:leadIds';
            queryToFetchRecords = CS_Utility.QueryToFetchAccount(conditionForQuery, 'LIMIT 10000');
            if (String.isBlank(queryToFetchRecords)) {
                leadSpendPeriodWrapperInstance.message = 'Can not find accounts.';
                return leadSpendPeriodWrapperInstance;
            }
            Set<String> leadIds = new Set<String>();
            for (Lead leadLoop : leadList) {
                leadIds.add(leadLoop.Id);
            }
            List<Account> accountList = CS_Utility.FetchRecordsByQuery(queryToFetchRecords,leadIds,null,null);
            if (accountList != null && !accountList.isEmpty()) {
                leadSpendPeriodWrapperInstance.accountList = accountList;
            }

            leadSpendPeriodWrapperInstance.spendPeriodList = spendPeriodsList;
            leadSpendPeriodWrapperInstance.leadList = leadList;
            leadSpendPeriodWrapperInstance.message = 'success';
            return leadSpendPeriodWrapperInstance;

        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Reprocessing unprocessed leads.', ex.getMessage(), 'Error', 'CS_CostSystem_Controller.ReprocessUnprocessedLeads', String.valueOf(ex.getLineNumber()));
            leadSpendPeriodWrapperInstance.message = 'Somthing went wrong.';
        }
        return leadSpendPeriodWrapperInstance;
    }

    /*
    * @Description  This method is to create cost ledger records.
    * @Params       spendPeriod
    * @Return       String
    */
    @AuraEnabled
    public static String CreateCostLedgerForUnprocessedLeads(String costLedgerList,String leadToupdateList){
        try {
            if (String.isBlank(costLedgerList)) {
                return 'Cost ledger list empty or null.';
            }
            List<Cost_Ledger__c> costLedgerObjectlist = new List<Cost_Ledger__c>();
            costLedgerObjectlist = (List<Cost_Ledger__c>) JSON.deserialize(costLedgerList, List<Cost_Ledger__c>.class);
            if (costLedgerObjectlist != null && !costLedgerObjectlist.isEmpty()) {
                insert costLedgerObjectlist;
            }
            if (!String.isBlank(leadToupdateList)) {
                List<lead> leadToupdate = (List<Lead>) JSON.deserialize(leadToupdateList, List<Lead>.class);
                if (leadToupdate != null && !leadToupdate.isEmpty()) {
                    update leadToupdate;
                }
            }
            return 'Processed the leads successfully';
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Creating cost ledger for unprocessed leads.', ex.getMessage(), 'Error', 'CS_CostSystem_Controller.CreateCostLedgerForUnprocessedLeads', String.valueOf(ex.getLineNumber()));
        }
        return 'Something went wrong.';
    }
    
    /*
    * @Description  method to update the marketing campaign  with updated spend periods and marketing campaign.
    * @Params marketingCampaignInstance
    * @Return       String 
    */
    @AuraEnabled
    public static CampaignWrapper UpdateCampaignWithUpdatedPeriods(String campaignInstanceToSave,String spendPeriodToSave,String spendPeriodToDelete){
        CampaignWrapper CampaignWrapperInstance = new CampaignWrapper();
        try {
            if (String.isBlank(campaignInstanceToSave)) {
                return null;
            }
            Marketing_Campaign__c marketingCampaign = (Marketing_Campaign__c) JSON.deserialize(campaignInstanceToSave,Marketing_Campaign__c.class);
            if (marketingCampaign == null ) {
                return null;
            }
            upsert marketingCampaign;
            CampaignWrapperInstance.marketingCampaignList = new List<Marketing_Campaign__c>{marketingCampaign};
            if (!String.isBlank(spendPeriodToSave)) {
                List<Marketing_Spend_Period__c> spendPeriodList = (List<Marketing_Spend_Period__c>) JSON.deserialize(spendPeriodToSave,List<Marketing_Spend_Period__c>.class);
                if (spendPeriodList != null && !spendPeriodList.isEmpty()) {
                    for (Marketing_Spend_Period__c mspLoop : spendPeriodList) {
                        mspLoop.Marketing_Campaign__c = String.isBlank(mspLoop.Marketing_Campaign__c) ? marketingCampaign.Id : mspLoop.Marketing_Campaign__c;
                    }
                    upsert spendPeriodList;
                    CampaignWrapperInstance.spendPeriodList = spendPeriodList;
                }
            }
            if (!String.isBlank(spendPeriodToDelete)) {
                List<Marketing_Spend_Period__c> deleteSpendPeriodList = new List<Marketing_Spend_Period__c>();
                deleteSpendPeriodList = (List<Marketing_Spend_Period__c>) JSON.deserialize(spendPeriodToDelete,List<Marketing_Spend_Period__c>.class);
                if (deleteSpendPeriodList != null && !deleteSpendPeriodList.isEmpty()) {
                    delete deleteSpendPeriodList;
                }
            }
            return CampaignWrapperInstance;
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_CostSystem_Controller.UpdateCampaignWithUpdatedPeriods', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  Wrapper for the picklistoptions.
    */
    public class PicklistOptions {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        
        public PicklistOptions(String label, String val) {
            this.label = label;
            this.value = val;
        }
    }

    /*
    * @Description  Wrapper to send marketing campaign records and the picklistoptions.
    */
    public class CampaignWrapper{
        @AuraEnabled
        public List<Marketing_Campaign__c> marketingCampaignList;
        @AuraEnabled
        public List<PicklistOptions> picklistOptions;
        @AuraEnabled
        public List<Marketing_Spend_Period__c> spendPeriodList;
    }

    /*
    * @Description  Wrapper to send marketing campaign records and the picklistoptions.
    */
    public class LeadSpendPeriodWrapper{
        @AuraEnabled
        public List<Lead> leadList;
        @AuraEnabled
        public List<Account> accountList;
        @AuraEnabled
        public List<Marketing_Spend_Period__c> spendPeriodList;
        @AuraEnabled
        public String message;
    }
}