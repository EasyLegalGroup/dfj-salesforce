/**
 * @description This class creates payment for Opportunity.
 */
public with sharing class DFJ_PaymentCreatorForOpportunity_Apex {
    
    /**
     * @description Wrapper class to hold Account and Opportunity data along with Opportunity Line Items.
     */
    public class ProductsWrapper {
        @AuraEnabled public Account accountRecordInstance; // Account related to the Opportunity
        @AuraEnabled public Opportunity opportunityRecordInstance; // Opportunity record
        @AuraEnabled public List<OpportunityLineItem> opportunityProductsData; // List of Opportunity Line Items
    }
    
    /**
     * @description Retrieves data for the Confirm Order page based on the given Opportunity record Id.
     * @param recordId The Id of the Opportunity record.
     * @return ProductsWrapper containing Account, Opportunity, and Opportunity Line Item data.
     */
    @AuraEnabled
    public static ProductsWrapper getDataForConfirmOrderPage(String recordId) {
        try {
            // Check if recordId is not blank
            if (String.isNotBlank(recordId)) {
                ProductsWrapper productsWrapperInstance = new ProductsWrapper(); // Initialize wrapper
                
                // Fetch Opportunity records based on recordId
                List<Opportunity> opportunityRecords = fetchRecordsDynamically(
                    'Id = \'' + recordId + '\'',
                new List<String>{'Id', 'Name', 'AccountId', 'Order_Total__c'},
                'Opportunity',
                ' LIMIT 1 '
                    );
                
                // If Opportunity records exist, set the instance
                if (!opportunityRecords.isEmpty()) {
                    productsWrapperInstance.opportunityRecordInstance = opportunityRecords[0];
                }
                
                // Fetch Account related to the Opportunity
                if (!opportunityRecords.isEmpty() && opportunityRecords[0].AccountId != null) {
                    List<Account> accountRecord = fetchRecordsDynamically(
                        'Id = \'' + opportunityRecords[0].AccountId + '\'',
                    new List<String>{'Id', 'Name', 'PersonEmail', 'Phone', 'BillingCity', 'BillingCountry', 'BillingState', 'BillingPostalCode', 'BillingStreet'},
                    'Account',
                    ' LIMIT 1 '
                        );
                    
                    // Set the Account instance
                    if (!accountRecord.isEmpty()) {
                        productsWrapperInstance.accountRecordInstance = accountRecord[0];
                    }
                }
                
                // Fetch Opportunity Line Items associated with the Opportunity
                List<OpportunityLineItem> oppProducts = [
                    SELECT Id, Name, Discount, TotalPrice,UnitPrice,Net_Total_Price__c, ListPrice, Product2.Name, Pricebook_Id__c, Is_subscription__c, Plan_handle__c,
                    PricebookEntryId, PricebookEntry_Id__c, Product2Id, Quantity, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c 
                    FROM OpportunityLineItem 
                    WHERE OpportunityId = :recordId WITH SECURITY_ENFORCED
                ];
                
                // Set the Opportunity Line Items in the wrapper
                productsWrapperInstance.opportunityProductsData = oppProducts;
                
                return productsWrapperInstance; // Return the populated wrapper
            }
            
            // Return empty wrapper if no recordId is provided
            return new ProductsWrapper();
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', ' Getting data for Confirm Order page. ', e.getMessage(), 'Error', 'DFJ_PaymentCreatorForOpportunity_Apex.getDataForConfirmOrderPage', '', String.valueOf(e.getLineNumber()));

            // Handle exceptions and return empty wrapper
            return new ProductsWrapper();
        }
    }
    
    /**
     * @description Fetches records dynamically based on the given parameters.
     * @param condition The condition for the query.
     * @param fields The fields to select in the query.
     * @param objectName The name of the object to query.
     * @param queryLimit The limit for the query.
     * @return List of SObjects matching the query criteria.
     */
    public static List<SObject> fetchRecordsDynamically(String condition, List<String> fields, String objectName, String queryLimit) {
        try {
            if (String.isBlank(objectName) || fields.isEmpty() || String.isBlank(queryLimit)) {
                return null;
            }
            String query = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName +
                    (!String.isBlank(condition) ? ' WHERE ' + condition : '') + queryLimit;
            return Database.query(query); // Execute the dynamic query and return results

        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Getting Records.', e.getMessage(), 'Error', 'DFJ_PaymentCreatorForOpportunity_Apex.fetchRecordsDynamically', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }
}