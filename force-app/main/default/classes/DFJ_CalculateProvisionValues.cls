public with sharing class DFJ_CalculateProvisionValues {
    public static void calculateProvisionValues_Apex(List<OrderItem> orderItemList){
        try{

            if(!orderItemList.isEmpty()){
                Map<Id, provisionFieldValues> productIdVSprovisionBaseValuesMap = new Map<Id, provisionFieldValues>();

                System.debug('orderItemList-->'+orderItemList);
                Set<Id> setOfProductId = new Set<Id>();
                Set<Id> setOfPricebookId = new Set<Id>();
                for (OrderItem item : orderItemList) {
                    setOfProductId.add(item.Product2Id);
                    setOfPricebookId.add(item.PricebookEntryId);
                    productIdVSprovisionBaseValuesMap.put(item.Product2Id, new provisionFieldValues());
                }
                System.debug('setOfProductId---->'+setOfProductId);
                System.debug('setOfPricebookId---->'+setOfPricebookId);
                List<PricebookEntry> listOfPricebookEntry = new List<PricebookEntry>();
                listOfPricebookEntry = [SELECT
                        Id,
                        Product2Id,
                        Pricebook2Id,
                        Provision_base__c,
                        Partner_provision_value__c,
                        Partner_sales_value__c
                FROM PricebookEntry
                WHERE Id IN: setOfPricebookId AND Product2Id IN: setOfProductId];
                System.debug('listOfPricebookEntry---->'+listOfPricebookEntry);

                if(listOfPricebookEntry != NULL){
                    for (PricebookEntry pricebookEntry : listOfPricebookEntry) {
                        if (productIdVSprovisionBaseValuesMap.containsKey(pricebookEntry.Product2Id)) {
                            provisionFieldValues provisionFieldValuesInstance = new provisionFieldValues();
                            provisionFieldValuesInstance.provisionBase = pricebookEntry.Provision_base__c;
                            provisionFieldValuesInstance.partnerProvisionValue = pricebookEntry.Partner_provision_value__c;
                            provisionFieldValuesInstance.partnerSalesValue = pricebookEntry.Partner_sales_value__c;
                            productIdVSprovisionBaseValuesMap.put(pricebookEntry.Product2Id,provisionFieldValuesInstance);
                        }
                    }
                }

                for (OrderItem orderItem : orderItemList) {
                    orderItem.Partner_sales_value__c = productIdVSprovisionBaseValuesMap.get(orderItem.Product2Id).partnerSalesValue;
                    orderItem.Partner_provision_value__c = productIdVSprovisionBaseValuesMap.get(orderItem.Product2Id).partnerProvisionValue;
                    orderItem.Provision_base__c = productIdVSprovisionBaseValuesMap.get(orderItem.Product2Id).provisionBase;
                }
                System.debug('Modified order items--->'+orderItemList);
            }

        }catch(Exception ex){
            System.debug('Exception occured::'+ex.getMessage()+' at Line Number::'+ex.getLineNumber());
            sObject logInstance = Schema.getGlobalDescribe().get('Log__c').newSObject() ;
            logInstance.put('Source__c','Adding provision values');
            logInstance.put('Event__c','While Adding provision values from the trigger');
            logInstance.put('Message__c','Message ---'+String.valueOf(ex.getMessage()) + ' ----- At line number -----'+ex.getLineNumber());
            logInstance.put('Severity__c','Error');
            insert logInstance;
        }
    }

    public class provisionFieldValues{
        public Decimal provisionBase;
        public Decimal partnerProvisionValue;
        public Decimal partnerSalesValue;
    }
}