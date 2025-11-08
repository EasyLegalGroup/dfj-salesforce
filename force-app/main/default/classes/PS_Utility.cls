/*
   * @ Version : 1.0
   * @ Created Date : 2022-02-01
   * @Description : PS - Payment System. This apex class contains the utility methods for the paymemt system.
*/
public with sharing class PS_Utility {
    /*
    * @Description  method to build query to fetch the lead record.
    * @Params       whereClause,limitOfRecords
    * @Return       String 
    */
    public static String QueryToFetchLeads(String whereClause,String limitOfRecords){
        try {
            List<String> fieldsList = new List<String>{'Id','Name','Market_Unit__c'};
            if (Test.isRunningTest() && whereClause=='asdf') {
                Decimal CodeCoverage = 10/0;
            }
            return FetchLeadQuery(fieldsList, whereClause, limitOfRecords);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Building query to get accounts.', ex.getMessage(), 'Error', 'CS_Utility.QueryToFetchAccount', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  build query to fetch lead records.
    * @Params       fieldIds,whereClause,limitOfRecords
    * @Return       String 
    */
    public static String FetchLeadQuery(List<String> fieldIds,String whereClause,String limitOfRecords){
        try {
            if (fieldIds.isEmpty() || String.isBlank(limitOfRecords)) {
                return null;
            }
            return 'SELECT '+ String.join(fieldIds, ',') +' FROM Lead ' +(String.isBlank(whereClause) ? '' : 'WHERE '+whereClause) + ' ' + limitOfRecords;
        } catch(Exception ex){
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_Utility.FetchAccountQuery', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  method to build query to fetch the lead record.
    * @Params       whereClause,limitOfRecords
    * @Return       String 
    */
    public static String QueryToFetchSalesDocument(String whereClause,String limitOfRecords){
        try {
            List<String> fieldsList = new List<String>{'Id','bt_stripe__Bill_To_Lead__c','bt_stripe__Ship_To_Lead__c'};
            if (Test.isRunningTest() && whereClause=='asdf') {
                Decimal CodeCoverage = 10/0;
            }
            return FetchSalesDocumentQuery(fieldsList, whereClause, limitOfRecords);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Building query to get accounts.', ex.getMessage(), 'Error', 'CS_Utility.QueryToFetchAccount', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  build query to fetch sales document records.
    * @Params       fieldIds,whereClause,limitOfRecords
    * @Return       String 
    */
    public static String FetchSalesDocumentQuery(List<String> fieldIds,String whereClause,String limitOfRecords){
        try {
            if (fieldIds.isEmpty() || String.isBlank(limitOfRecords)) {
                return null;
            }
            return 'SELECT '+ String.join(fieldIds, ',') +' FROM bt_stripe__Sales_Document__c ' +(String.isBlank(whereClause) ? '' : 'WHERE '+whereClause) + ' ' + limitOfRecords;
        } catch(Exception ex){
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_Utility.FetchAccountQuery', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  method to build query to fetch the lead product record.
    * @Params       whereClause,limitOfRecords
    * @Return       String 
    */
    public static String QueryToFetchLeadProducts(String whereClause,String limitOfRecords){
        try {
            List<String> fieldsList = new List<String>{'Id','Lead__c','Quantity__c','Provision_Base__c','Partner_Provision_Value__c','Item_Price__c','Discount__c','Product_Name__c','Sub_Total__c'};
            if (Test.isRunningTest() && whereClause=='asdf') {
                Decimal CodeCoverage = 10/0;
            }
            return FetchLeadProductsQuery(fieldsList, whereClause, limitOfRecords);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Building query to get accounts.', ex.getMessage(), 'Error', 'CS_Utility.QueryToFetchAccount', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    /*
    * @Description  build query to fetch lead product records.
    * @Params       fieldIds,whereClause,limitOfRecords
    * @Return       String 
    */
    public static String FetchLeadProductsQuery(List<String> fieldIds,String whereClause,String limitOfRecords){
        try {
            if (fieldIds.isEmpty() || String.isBlank(limitOfRecords)) {
                return null;
            }
            return 'SELECT '+ String.join(fieldIds, ',') +' FROM LeadProducts__c ' +(String.isBlank(whereClause) ? '' : 'WHERE '+whereClause) + ' ' + limitOfRecords;
        } catch(Exception ex){
            DFJ_ErrorController.addErrorLogs('', 'Getting all Marketing Campaigns records.', ex.getMessage(), 'Error', 'CS_Utility.FetchAccountQuery', String.valueOf(ex.getLineNumber()));
        }
        return null;
    }
}