public with sharing class PS_OrderCreationService {
    public static productsWrapper PS_OrderCreationService_Apex(String recordId) {
        try {
            productsWrapper productsWrapperInstance = new productsWrapper();
            List<Account> accountRecord = new List<account>();
            List<Pricebook2> pricebookRecord = new List<Pricebook2>();
            List<PricebookEntry> listOfProducts = new List<PricebookEntry>();
            List<Campaign> getCampaign = new List<Campaign>();
            if(recordId != '' && String.isNotBlank(recordId)){
//DFJ-101 add the Related_Event_ID__c in the Account Query
                accountRecord = [SELECT 
                                    Id, 
                                    Related_Event_ID__c,
                                    Market_Unit__c,
                                    Lead__c 
                                    FROM 
                                    Account 
                                    WHERE 
                                    Id =: recordId 
                                    LIMIT 1];
                if(!accountRecord.isEmpty()){
                    //DFJ-101
                    getCampaign = [SELECT Id,Related_Event_ID__c FROM Campaign WHERE Related_Event_ID__c =:accountRecord[0].Related_Event_ID__c LIMIT 1];
                    //End
                    //Changes Starts DFJ-77
                    List<Journal__c> listOfJournals = new List<Journal__c>();
           			listOfJournals = [SELECT Id, Name, Journal_States__c FROM Journal__c WHERE Account__c =: accountRecord[0].Id];
            		if(!listOfJournals.isEmpty()){
               			productsWrapperInstance.relatedJournals = listOfJournals;
          			}
                    //End
                    
                    
                    Currency_Configurater__mdt currencyConfigurationSetting = Currency_Configurater__mdt.getInstance(accountRecord[0].Market_Unit__c);
               
                    if(String.isNotBlank(currencyConfigurationSetting.CurrencyIsoCode__c)){
            //Added check of Is_Opportunity_PriceBook__c in Query for fetching Pricebook DFJ-275
                    pricebookRecord = [SELECT
                                        Id,
                                        Name,
                                        CurrencyIsoCode
                                        FROM 
                                        Pricebook2 
                                        WHERE 
                                        IsActive = true 
                                        AND
                                        CurrencyIsoCode =: currencyConfigurationSetting.CurrencyIsoCode__c 
                                        AND IsStandard = false 
                                        AND Is_Opportunity_PriceBook__c = false
                                        LIMIT 1];
                    //System.debug(pricebookRecord); 
                    if(!pricebookRecord.isEmpty()){
                        listOfProducts = [ SELECT 
                                                Id,
                                                Name,
                                                PriceBook2.Id,
                                                Product2.Name,
                                                Product2.CurrencyIsoCode,
                                                Product2.Plan__c,
                                                Product2.Is_subscription__c,
                                                Product2.ProductCode,
                                                PriceBook2.Name,
                                                PriceBook2.CurrencyIsoCode,
                                                Partner_provision_value__c,
                                                Partner_sales_value__c,
                                                Provision_base__c,
                                                IsActive,
                                                convertCurrency(UnitPrice)
                                                FROM PriceBookEntry WHERE PriceBook2.Id =:pricebookRecord[0].Id AND IsActive = true AND Product2.IsActive = true ORDER BY Sort_Key__c DESC NULLS LAST];
                    }
                    
                    if(!listOfProducts.isEmpty()){
                        productsWrapperInstance.selectedPriceBookEnteries = listOfProducts;
                        productsWrapperInstance.selectedPriceBook = pricebookRecord[0];
                    }
                        productsWrapperInstance.marketUnit = accountRecord[0].Market_Unit__c;
                        productsWrapperInstance.accountRecordInstance = accountRecord[0];
                      // if(!getCampaign.isEmpty()){
                            productsWrapperInstance.campaignRecordInstance = getCampaign;
                     //  }
                        
                       // System.debug('productsWrapperInstance-->'+productsWrapperInstance);
                        return productsWrapperInstance;    
                    } 
                }     
            }
        } catch (Exception ex) {
            System.debug('Error -->'+ ex.getMessage());
        } 
        return null;
    }

// DFJ-80 Changes added recId in class param
    public static string createOrderAndOrderItems_Apex(String OrderItemsProducts, Order orderRecordToInsert, String recId){
        try {
            List<OrderItem> orderItemList = new List<OrderItem>();
            if(orderRecordToInsert != null && String.isNotBlank(OrderItemsProducts)){
                //System.debug('orderRecordToInsert-->'+orderRecordToInsert);
               upsert orderRecordToInsert;
               //System.debug('orderRecordToInsert-11->'+orderRecordToInsert);
               List<OrderItem> OrderProductsList = (List<OrderItem>)JSON.deserialize(OrderItemsProducts, List<OrderItem>.class);
            
               for(OrderItem orderItemRecord : OrderProductsList){
                    orderItemRecord.OrderId = orderRecordToInsert.Id;
                   //System.debug('orderItemRecord.OrderId-->'+orderItemRecord.OrderId);
                    orderItemList.add(orderItemRecord);
               }
               //DFJ-80 Changes added check to add payment on recently created Order on account
               String orderId = orderRecordToInsert.Id;
               if(String.isNotBlank(recId)){
                String sObjectType = PS_PaymentUtility.getSobjectTypeFromRecordId_Apex(recId);
                if(sObjectType.equalsIgnoreCase('Account')){
                    relatePaymentToOrder(recId,orderId);
                }

               }
               if(!orderItemList.isEmpty()){
                   upsert orderItemList;
                   return 'Order Created Successfully';
               }

            }
        } catch (Exception e) {
            system.debug('error message-->'+e.getMessage()+' in line '+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
        return 'Something went wrong';
    }

    // DFJ-80 Changes starts
    public static string relatePaymentToOrder(String recId, String orderId){
        try {
            List<Payments__c> currentpayment =  [SELECT Id, Order__c FROM Payments__c WHERE Account__c=:recId ORDER BY CreatedDate DESC LIMIT 1];
            List<Payments__c> updatePaymentList = new List<Payments__c>();
            if (currentpayment.isEmpty()) {
                return 'Unable to fetch payment record';
            }else{
                Payments__c paymentInst = new Payments__c();
                paymentInst.Id = currentpayment[0].Id;
                paymentInst.Order__c = orderId;
                updatePaymentList.add(paymentInst);
            }
               if(!updatePaymentList.isEmpty()){
                   update updatePaymentList;
                   return 'payment Created Successfully';
               }

            }catch (Exception e) {
                system.debug('error message-->'+e.getMessage()+' in line '+e.getLineNumber());
                throw new AuraHandledException(e.getMessage());
            }
            return 'Something went wrong';
    } 
   //End

 //Start Changes DFJ-77 Add picklist value for Journal related to that account
 // Description :Show the Journal related to the account when clicking the Create additional Order Button on Account.
 /*   public static List<Journal__c> journalAssociatedWithAccount(String recordId){
       System.debug('recordId-->'+recordId);
        if(recordId.trim() != '' && recordId != null){
            List<Journal__c> listOfJournals = new List<Journal__c>();
            listOfJournals = [SELECT Id, Name, Journal_States__c FROM Journal__c WHERE Account__c =: recordId];
            if(!listOfJournals.isEmpty()){
               return listOfJournals;
           }
        }
        return null;
    }
   */
//End
//DFJ-80
@AuraEnabled
public static List<Payments__c> createPaymentRecord_Apex(String accId){
    try {
        if(String.isBlank(accId)){
            return null;
        }
        List<Payments__c> paymentInstList  = new List<Payments__c>();
      
           if(!String.isBlank(accId)){
            Payments__c paymentInst = new Payments__c();
               paymentInst.Account__c = accId;
               paymentInstList.add(paymentInst);
           }
           if(!paymentInstList.isEmpty()){
            insert paymentInstList;
           }
           
    return paymentInstList;
    } catch (DmlException e) {
        throw new AuraHandledException('Error::-->' + e.getMessage() + 'at line number::->' + e.getLineNumber());
    }
   // return null;
}
//End

    // DFJ-330 changes start
            public static List<priceBookWithItsEntriesWrapper> fetchPriceBookAndEntries(String actRecordId){
        try {
            Account actRecord = [SELECT Id, Market_Unit__c FROM Account WHERE Id = :actRecordId] ?? null;
            String marketUnitFilterValueToUseToFilterPricebooks = actRecord.Market_Unit__c;

            List<Pricebook2> listOfPricebooks = new List<Pricebook2>();
            listOfPricebooks = [
                    SELECT Id, Name, CurrencyIsoCode, IsStandard, Market_Unit__c
                    FROM Pricebook2
                    WHERE
                            IsActive = TRUE AND
                            Pricebook2.Market_Unit__c = :marketUnitFilterValueToUseToFilterPricebooks AND
                            Is_Opportunity_PriceBook__c = FALSE
                    LIMIT 10000
            ];

            if (listOfPricebooks.isEmpty()) {
                listOfPricebooks = [
                        SELECT Id, Name, CurrencyIsoCode, IsStandard, Market_Unit__c
                        FROM Pricebook2
                        WHERE
                                IsActive = TRUE AND
                                Is_Opportunity_PriceBook__c = FALSE
                        LIMIT 10000
                ];
            }

            List<PricebookEntry> listOfProducts = new List<PricebookEntry>();

            listOfProducts = [
                    SELECT Id,
                            Name,
                            PriceBook2.Id,
                            Product2.Name,
                            Product2.CurrencyIsoCode,
                            Product2.Plan__c,
                            Product2.Is_subscription__c,
                            Product2.ProductCode,
                            PriceBook2.Name,
                            PriceBook2.CurrencyIsoCode,
                            Partner_provision_value__c,
                            Partner_sales_value__c,
                            Provision_base__c,
                            convertCurrency(UnitPrice)
                    FROM PriceBookEntry
                    WHERE PriceBook2.Id IN :listOfPricebooks AND IsActive = TRUE AND Product2.IsActive = TRUE
                    ORDER BY Sort_Key__c DESC NULLS LAST
            ];


            Map<Id, List<PricebookEntry>> priceBookIdVSPricebookEntries = new Map<Id, List<PricebookEntry>>();

            for (PricebookEntry pbe : listOfProducts) {
                if (!priceBookIdVSPricebookEntries.containsKey(pbe.Pricebook2.Id)) {
                    priceBookIdVSPricebookEntries.put(pbe.Pricebook2.Id, new List<PricebookEntry>());
                }
                priceBookIdVSPricebookEntries.get(pbe.Pricebook2.Id).add(pbe);
            }

            List<priceBookWithItsEntriesWrapper> priceBookWithItsEntriesWrapperList = new List<priceBookWithItsEntriesWrapper>();
            for (Pricebook2 pb : listOfPricebooks) {
                priceBookWithItsEntriesWrapper priceBookWithItsEntriesWrapperObj = new priceBookWithItsEntriesWrapper();
                priceBookWithItsEntriesWrapperObj.pricebookRecord = pb;
                priceBookWithItsEntriesWrapperObj.pricebookEntries = priceBookIdVSPricebookEntries.get(pb.Id);
                priceBookWithItsEntriesWrapperList.add(priceBookWithItsEntriesWrapperObj);
            }

            return priceBookWithItsEntriesWrapperList;
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Error while fetching Pricebook and its entries.', e.getMessage(), 'Error', 'PS_OrderCreationService.fetchPriceBookAndEntries', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }

    public class priceBookWithItsEntriesWrapper{
        @AuraEnabled public Pricebook2 pricebookRecord;
        @AuraEnabled public List<PricebookEntry> pricebookEntries;
    }
//    DFJ-330 changes end



    public class productsWrapper{
        @AuraEnabled public priceBook2 selectedPriceBook;
        @AuraEnabled public List<PricebookEntry> selectedPriceBookEnteries;
        @AuraEnabled public string errorMessage;
        @AuraEnabled public String marketUnit;
        @AuraEnabled public Account accountRecordInstance;
        //Changes Starts DFJ-77
        @AuraEnabled public List<Journal__c> relatedJournals;
        //End
        //Changes DFJ-101
        @AuraEnabled public List<Campaign> campaignRecordInstance;
        //End
      
    }
}