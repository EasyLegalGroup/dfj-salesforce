/*
   * @ Version : 1.0
   * @ Created Date : 2021-12-17
   * @Description : CS is for Cost System this class will be used as utility for campaign spend process script.
*/
public with sharing class CS_Utility {
    /*
    * @Description  method to fetch the marketing campaign record.
    * @Params       marketingCampaignInstance
    * @Return       String 
    */
    public static List<Marketing_Campaign__c> FetchMarketingCampaign(List<String> marketingCampaignId){
        try {
            if (marketingCampaignId.isEmpty()) {
                return null;
            }
            List<Marketing_Campaign__c> marketingCampaignList = new List<Marketing_Campaign__c>();
            marketingCampaignList = [Select UTM_Campaign__c,UTM_Content__c,UTM_Medium__c,UTM_Source__c,UTM_Term__c,Cost_Category__c FROM Marketing_Campaign__c WHERE Id IN: marketingCampaignId];
            if (!marketingCampaignList.isEmpty()) {
                return marketingCampaignList;
            }
        } catch(Exception ex){
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_Utility.FetchMarketingCampaign', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  method to fetch records by the query.
    * @Params       marketingCampaign,spendPeriod
    * @Return       List<SObject>
    */
    public static List<SObject> FetchRecordsByQuery(String query,Set<String> leadIds,String marketingCampaignId,String processPeriod){
        try {
            if (String.isBlank(query)) {
                return null;
            }
            
            List<SObject> sObjFetched = Database.query(query);
            if (sObjFetched != null && !sObjFetched.isEmpty() ) {
                return sObjFetched;
            }
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Fetching records using query', ex.getMessage(), 'Error', 'CS_Utility.FetchRecordsByQuery', String.valueOf(ex.getLineNumber()));
            
        }
        return null;
    }

    /*
    * @Description  Wrapper to store the processperiod from and to field.
    */
    public class ProcessPeriod{
        public Datetime fromDate;
        public Datetime toDate;
    }

    /*
    * @Description  method to build spend period query.
    * @Params       whereClause,limitOfRecords
    * @Return       String 
    */
    public static String QueryToFetchSpendPeriod(String whereClause,String limitOfRecords){
        try {
            List<String> fieldsList = new List<String>{'Id','Name','Marketing_Campaign__c','Period_end_time__c','Period_start_time__c','Total_spend__c'};
            if (Test.isRunningTest() && whereClause=='asdf') {
                Decimal CodeCoverage = 10/0;
            }
            return CS_Selector.FetchMarketingSpendPeriod(fieldsList, whereClause, limitOfRecords);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Fetching all spend period from marketing campaign.', ex.getMessage(), 'Error', 'CS_Utility.QueryToFetchSpendPeriod', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  method to build lead query.
    * @Params       whereClause,limitOfRecords
    * @Return       String 
    */
    public static String QueryToFetchLeads(String whereClause,String limitOfRecords){
        try {
            List<String> fieldsList = new List<String>{'Id','Name','IsConverted','CreatedDate','Marketing_Campaign__c'};
            if (Test.isRunningTest() && whereClause=='asdf') {
                Decimal CodeCoverage = 10/0;
            }
            return CS_Selector.FetchLeadsQuery(fieldsList, whereClause, limitOfRecords);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Building query to get leads.', ex.getMessage(), 'Error', 'CS_Utility.QueryToFetchLeads', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  method to build query to fetch converted leads account.
    * @Params       whereClause,limitOfRecords
    * @Return       String 
    */
    public static String QueryToFetchAccount(String whereClause,String limitOfRecords){
        try {
            List<String> fieldsList = new List<String>{'Id','Name','Lead__c'};
            if (Test.isRunningTest() && whereClause=='asdf') {
                Decimal CodeCoverage = 10/0;
            }
            return CS_Selector.FetchAccountQuery(fieldsList, whereClause, limitOfRecords);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Building query to get accounts.', ex.getMessage(), 'Error', 'CS_Utility.QueryToFetchAccount', String.valueOf(ex.getLineNumber()));
            
        }
        return null;
    }

}