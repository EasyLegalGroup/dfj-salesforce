/*
   * @ Version : 1.0
   * @ Created Date : 2021-12-24
   * @Description : CS is for Cost System and this class is used as selector class for cost system.
*/
public with sharing class CS_Selector {
    /*
    * @Description  build query to fetch marketing spend periods.
    * @Params       fieldIds,whereClause,limitOfRecords
    * @Return       String 
    */
    public static String FetchMarketingSpendPeriod(List<String> fieldIds,String whereClause,String limitOfRecords){
        try {
            if (fieldIds.isEmpty() || String.isBlank(limitOfRecords)) {
                return null;
            }
            return 'SELECT '+ String.join(fieldIds, ',') +' FROM Marketing_Spend_Period__c ' +(String.isBlank(whereClause) ? '' : 'WHERE '+whereClause) + ' ' + limitOfRecords;
        } catch(Exception ex){
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_Utility.FetchMarketingCampaign', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  build query to fetch lead records.
    * @Params       fieldIds,whereClause,limitOfRecords
    * @Return       String 
    */
    public static String FetchLeadsQuery(List<String> fieldIds,String whereClause,String limitOfRecords){
        try {
            if (fieldIds.isEmpty() || String.isBlank(limitOfRecords)) {
                return null;
            }
            return 'SELECT '+ String.join(fieldIds, ',') +' FROM Lead ' +(String.isBlank(whereClause) ? '' : 'WHERE '+whereClause) + ' ' + limitOfRecords;
        } catch(Exception ex){
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_Utility.FetchLeadsQuery', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  build query to fetch Account records.
    * @Params       fieldIds,whereClause,limitOfRecords
    * @Return       String 
    */
    public static String FetchAccountQuery(List<String> fieldIds,String whereClause,String limitOfRecords){
        try {
            if (fieldIds.isEmpty() || String.isBlank(limitOfRecords)) {
                return null;
            }
            return 'SELECT '+ String.join(fieldIds, ',') +' FROM Account ' +(String.isBlank(whereClause) ? '' : 'WHERE '+whereClause) + ' ' + limitOfRecords;
        } catch(Exception ex){
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_Utility.FetchAccountQuery', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    
}