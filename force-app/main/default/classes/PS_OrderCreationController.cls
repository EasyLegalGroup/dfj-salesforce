public with sharing class PS_OrderCreationController {

      /*
    * @Description  method to fetch the product from Account Market Unit
    * @Param        recordId
    * @Return       productsWrapper
    */
    @AuraEnabled
    public static PS_OrderCreationService.productsWrapper createOrderRecord(String recordId){
        try {
            if (Test.isRunningTest() && String.isBlank(recordId)) {
                Double result = 10/0;
            }
            return PS_OrderCreationService.PS_OrderCreationService_Apex(recordId);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Creating Order record.', ex.getMessage(), 'Error', 'PS_OrderCreationController.createOrderRecord', '', String.valueOf(ex.getLineNumber()));
            PS_OrderCreationService.productsWrapper productsWrapperInstance= new PS_OrderCreationService.productsWrapper();
            productsWrapperInstance.errorMessage = ex.getMessage();
            return productsWrapperInstance;
        }
    }

       /*
    * @Description  method to insert the product of Order
    * @Param        recordId, 
    * @Return       productsWrapper
    */
    //DFJ-80 Added param recId to update payment
    @AuraEnabled
    public static String createOrderAndOrderItems(String OrderItemsProduct, Order orderRecord, String recId){
        //System.debug('orderRecord-In1->'+orderRecord);
        try {
            if (Test.isRunningTest() && orderRecord == null && String.isBlank(OrderItemsProduct)) {
                Double result = 10/0;
            }
            //System.debug('orderRecord-In->'+orderRecord);
            return PS_OrderCreationService.createOrderAndOrderItems_Apex(OrderItemsProduct, orderRecord, recId);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Creating Order record.', ex.getMessage(), 'Error', 'PS_OrderCreationController.createOrderRecord', '', String.valueOf(ex.getLineNumber()));
            //PS_OrderCreationService.productsWrapper productsWrapperInstance= new PS_OrderCreationService.productsWrapper();
            return ex.getMessage();
        }
    }

   //End

//DFJ-80
@AuraEnabled
    public static List<Payments__c> createPaymentRecord(String accId){
        //System.debug('orderRecord-In1->'+orderRecord);
        try {
            if (Test.isRunningTest() && String.isBlank(accId)) {
                Double result = 10/0;
            }
            //System.debug('orderRecord-In->'+orderRecord);
            return PS_OrderCreationService.createPaymentRecord_Apex(accId);
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Creating payment record.', ex.getMessage(), 'Error', 'PS_OrderCreationController.createPaymentRecord', '', String.valueOf(ex.getLineNumber()));
            //PS_OrderCreationService.productsWrapper productsWrapperInstance= new PS_OrderCreationService.productsWrapper();
            return null;
        }
    }
    //End

    // DFJ-330 changes start
    @AuraEnabled(Cacheable=true)
    public static List<PS_OrderCreationService.priceBookWithItsEntriesWrapper> fetchPriceBookAndEntries(String actRecordId){
        try {
            return PS_OrderCreationService.fetchPriceBookAndEntries(actRecordId);
        }
        catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', '', ex.getMessage(), 'Error', 'PS_OrderCreationController.fetchPriceBookAndEntries', '', String.valueOf(ex.getLineNumber()));
            return null;
        }
    }
    // DFJ-330 changes end
}