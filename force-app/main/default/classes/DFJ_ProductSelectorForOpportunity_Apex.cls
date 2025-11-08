/**
 * @description This class handles product selection for opportunities.
 */
public with sharing class DFJ_ProductSelectorForOpportunity_Apex {
    
    /**
     * @description Method to fetch products from Account Market Unit.
     * @param recordId The ID of the opportunity.
     * @return ProductsWrapper containing relevant data.
     */
    @AuraEnabled
    public static ProductsWrapper getAllThePricebooksAndOpportunityProducts_Apex(String recordId) {
        if (String.isBlank(recordId)) {
            return null;
        }
        try {
            Map<Id, Pricebook2> idVSPricebook2s = new Map<Id, Pricebook2>();
            List<PricebookEntry> listOfProducts = new List<PricebookEntry>();
            Map<Id, List<PricebookEntry>> priceBookIdVSPricebookEntries = new Map<Id, List<PricebookEntry>>();
            List<Pricebook2> listOfPricebooks = new List<Pricebook2>();
            List<Opportunity> opportunityRecord = fetchRecordsDynamically(
                'Id = \'' + recordId + '\'',
            new List<String>{'Id', 'Market_Unit__c', 'Fixed_discount_Type__c','Pricebook2Id', 'AccountId', 'Lead__c'},
            'Opportunity',
            ' LIMIT 1 '
                );
            Currency_Configurater__mdt currencyConfigurationSetting = Currency_Configurater__mdt.getInstance(opportunityRecord[0].Market_Unit__c);
            
            if (!opportunityRecord.isEmpty()) {
                String pricebookCondition = opportunityRecord[0].Pricebook2Id != null ? 'Id = \''+ opportunityRecord[0].Pricebook2Id +'\'' : 'IsActive = true AND IsStandard = false AND Is_Opportunity_PriceBook__c = true AND CurrencyIsoCode = \'' + currencyConfigurationSetting.CurrencyIsoCode__c + '\'';
                listOfPricebooks = fetchRecordsDynamically(
                    pricebookCondition, new List<String>{'Id', 'Name', 'CurrencyIsoCode'},
                'Pricebook2',
                ' LIMIT 1 '
                    );
                
                /*   listOfPricebooks = fetchRecordsDynamically(
                    'IsActive = true AND IsStandard = false AND Is_Opportunity_PriceBook__c = true AND CurrencyIsoCode = \'' + currencyConfigurationSetting.CurrencyIsoCode__c + '\'',
                new List<String>{'Id', 'Name', 'CurrencyIsoCode'},
                'Pricebook2',
                ' LIMIT 1 '
                    );*/
                
                if (!listOfPricebooks.isEmpty()) {
                    listOfProducts = fetchRecordsDynamically(
                        'IsActive = true AND Product2.IsActive = true AND PriceBook2.Id = \'' + listOfPricebooks[0].Id + '\' ORDER BY Sort_Key__c DESC NULLS LAST',
                    new List<String>{'Id', 'PriceBook2.Id', 'Name', 'Product2.Name', 'Product2.CurrencyIsoCode', 'Product2.Plan__c', 'Product2.Is_subscription__c', 'Product2.ProductCode', 'PriceBook2.Name', 'PriceBook2.CurrencyIsoCode', 'IsActive', 'convertCurrency(UnitPrice)'},
                    'PriceBookEntry',
                    ' LIMIT 10000 '
                        );
                }
            }
            
            List<productDataWithPriceBook> productDataWithPriceBooksList = new List<productDataWithPriceBook>();
            for (PricebookEntry pbe : listOfProducts) {
                if (!priceBookIdVSPricebookEntries.containsKey(pbe.PriceBook2.Id)) {
                    priceBookIdVSPricebookEntries.put(pbe.PriceBook2.Id, new List<PricebookEntry>());
                }
                priceBookIdVSPricebookEntries.get(pbe.PriceBook2.Id).add(pbe);
            }
            
            for (Pricebook2 pb : listOfPricebooks) {
                productDataWithPriceBook productInstance = new productDataWithPriceBook();
                productInstance.pb2 = pb;
                productInstance.pbeList = priceBookIdVSPricebookEntries.get(pb.Id);
                productDataWithPriceBooksList.add(productInstance);
            }
            
            List<OpportunityLineItem> oppProducts = [
                SELECT Id, Discount, TotalPrice, ListPrice,UnitPrice,Net_Total_Price__c, Product2.Name, Pricebook_Id__c, Is_subscription__c, Plan_handle__c,
                PricebookEntryId, PricebookEntry_Id__c, Product2Id, Quantity, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c
                FROM OpportunityLineItem WHERE OpportunityId = :recordId
            ];
            
            String defaultCurrency = UserInfo.getDefaultCurrency();
            
            ProductsWrapper productInstance = new ProductsWrapper();
            productInstance.opportunityProductsData = oppProducts;
            productInstance.productData = productDataWithPriceBooksList;
            productInstance.DefaultCurrencyIsoCode = defaultCurrency;
            productInstance.currencyAccordingMarketUnit = currencyConfigurationSetting.CurrencyIsoCode__c;
            
            return productInstance;
            
        } catch (DmlException ex) {
            DFJ_ErrorLogController.addErrorLogs('', ' Get the price book and Opportunity Products. ', ex.getMessage(), 'Error', 'DFJ_ProductSelectorForOpportunity_Apex.getAllThePricebooksAndOpportunityProducts_Apex', '', String.valueOf(ex.getLineNumber()));
            throw new AuraHandledException('Error: ' + ex.getMessage() + ' at line number: ' + ex.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static void updateRecords_Apex(OpportunityLineItem changedDiscount) {
        try {
            if (changedDiscount != null) {
                upsert changedDiscount;
            }
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Update records', ex.getMessage(), 'Error', 'DFJ_ProductSelectorForOpportunity_Apex.updateRecords_Apex', '', String.valueOf(ex.getLineNumber()));
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<OpportunityLineItem> deleteRecords_Apex(String productId, String recId) {
        try {
            if ( String.isNotBlank(productId)  && productId.trim() != '') {
                OpportunityLineItem productInstance = [SELECT Id FROM OpportunityLineItem WHERE Id = :productId];
                delete productInstance;
                
                List<OpportunityLineItem> updatedProductsList = [
                    SELECT Id, Discount, TotalPrice, ListPrice, Product2.Name, Pricebook_Id__c, Is_subscription__c, Plan_handle__c,
                    PricebookEntry_Id__c, Product2Id, Quantity, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c
                    FROM OpportunityLineItem WHERE OpportunityId = :recId
                ];
                return updatedProductsList;
            }
        } catch (DmlException ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Delete records', ex.getMessage(), 'Error', 'DFJ_ProductSelectorForOpportunity_Apex.deleteRecords_Apex', '', String.valueOf(ex.getLineNumber()));
            throw new AuraHandledException(ex.getMessage() + ' at line: ' + ex.getLineNumber());
        }
        return null;
    }

    public static List<SObject> fetchRecordsDynamically(String condition, List<String> fields, String objectName, String queryLimit) {
        try {
            if ( fields.isEmpty() || String.isBlank(objectName) || String.isBlank(queryLimit) ) {
                return null;
            }

            String query = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName + (!String.isBlank(condition) ? ' WHERE ' + condition : '') + queryLimit;
            return Database.query(query);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Fetch records Dynamically.', ex.getMessage(), 'Error', 'DFJ_ProductSelectorForOpportunity_Apex.fetchRecordsDynamically', '', String.valueOf(ex.getLineNumber()));
            return null;
        }
    }
    
    public class ProductsWrapper {
        @AuraEnabled public String errorMessage;
        @AuraEnabled public List<OpportunityLineItem> opportunityProductsData;
        @AuraEnabled public List<productDataWithPriceBook> productData;
        @AuraEnabled public String DefaultCurrencyIsoCode;
        @AuraEnabled public String currencyAccordingMarketUnit;
    }
    
    public class productDataWithPriceBook {
        @AuraEnabled public Pricebook2 pb2;
        @AuraEnabled public List<PricebookEntry> pbeList;
    }

    @AuraEnabled
    public static List<OpportunityLineItem> insertRecords_Apex(List<OpportunityLineItem> newProductList) {
        try {
            if (!newProductList.isEmpty()) {
                upsert newProductList;
                return newProductList;
            }
        } catch (Exception ex) {

            DFJ_ErrorLogController.addErrorLogs('', 'Insert records', ex.getMessage(), 'Error', 'DFJ_ProductSelectorForOpportunity_Apex.insertRecords_Apex', '', String.valueOf(ex.getLineNumber()));
            throw new AuraHandledException(ex.getMessage());
        }
        return null;
    }

    @AuraEnabled
    public static void updateOpportunity(String opportunityId, Decimal orderTotal, Decimal fixedDiscount) {
        try {

            if (opportunityId == null) {
                return;
            }

            Opportunity opp = [SELECT Id, Order_Total__c, Fixed_Discount_Type__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

            opp.Order_Total__c = (orderTotal == null) ? 0 : orderTotal;
            opp.Fixed_Discount_Type__c =   (fixedDiscount == null ) ? 0 : fixedDiscount;

            update opp;
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Update Opportunity.', e.getMessage(), 'Error', 'DFJ_ProductSelectorForOpportunity_Apex.updateOpportunity', '', String.valueOf(e.getLineNumber()));
            throw new AuraHandledException('Error updating opportunity: ' + e.getMessage());
        }
    }

     //DFJ-347 Changes Start
    @AuraEnabled
    public static Integer getOrderCategorySize(Id oppId) {
        try{
            if(oppId != null){
                Opportunity opp = [SELECT Id, Market_Unit__c FROM Opportunity WHERE Id = :oppId];
            List<Order_Category_Definition__c> orderCategoryList = [SELECT Id FROM Order_Category_Definition__c WHERE Order_Category_Type__c = 'Product Bundle' AND Is_Active__c = true AND Market_Unit__c = :opp.Market_Unit__c];
            return orderCategoryList.size();
            }
            return null;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    //DFJ-347 Changes End


}