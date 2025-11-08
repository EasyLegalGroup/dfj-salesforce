public with sharing class OrderAssetCreator {

    @InvocableMethod(label='Create Assets from Order' 
                     description='Creates an Asset record for each unit in an OrderItem. Each Asset has a quantity of 1. Also updates the input Order to mark assets as created.')
    public static void createAssets(List<RequestWrapper> requestList) {
        // Retrieve the RecordTypeId for “Product_Assets”
        String productAssetsRtId = Schema.SObjectType.Asset
            .getRecordTypeInfosByDeveloperName()
            .get('Product_Assets')
            .getRecordTypeId();
        if (productAssetsRtId == null) {
            throw new AuraHandledException('Asset Record Type "Product_Assets" not found');
        }

        List<Asset> assetsToInsert = new List<Asset>();
        List<Order> ordersToUpdate = new List<Order>();
        
        for (RequestWrapper req : requestList) {
            List<OrderItem> orderItems = [
                SELECT Id, OrderId, Quantity, UnitPrice, Product2Id, Product_Name__c, Requires_Tinglysning__c,
                       Order.AccountId, Order.CreatedDate, Order.CurrencyIsoCode, Order.Account.PersonContactId,
                       Order.Journal__c
                  FROM OrderItem
                 WHERE OrderId = :req.orderId
            ];
            
            for (OrderItem oi : orderItems) {
                Integer numAssets = Integer.valueOf(oi.Quantity);
                for (Integer i = 0; i < numAssets; i++) {
                    Asset ast = new Asset();
                    ast.Name                            = oi.Product_Name__c;
                    ast.Product2Id                      = oi.Product2Id;
                    ast.AccountId                       = oi.Order.AccountId;
                    ast.ContactId                       = oi.Order.Account.PersonContactId;
                    ast.CurrencyIsoCode                 = oi.Order.CurrencyIsoCode;
                    ast.Public_Registration_Required__c = oi.Requires_Tinglysning__c;
                    ast.Public_Registration_Status__c   = oi.Requires_Tinglysning__c
                                                            ? 'Pending Document Approval'
                                                            : 'Not Required';
                    ast.Order__c        = oi.OrderId;
                    ast.Order_Product__c = oi.Id;
                    ast.Price            = oi.UnitPrice;
                    ast.Quantity         = 1;
                    ast.PurchaseDate     = oi.Order.CreatedDate.date();
                    ast.Journal__c       = oi.Order.Journal__c;
                    ast.RecordTypeId     = productAssetsRtId;
                    
                    assetsToInsert.add(ast);
                }
            }
            
            ordersToUpdate.add(
                new Order(Id = req.orderId, Assets_Created__c = true)
            );
        }
        
        if (!assetsToInsert.isEmpty()) {
            insert assetsToInsert;
        }
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
    
    public class RequestWrapper {
        @InvocableVariable(required=true)
        public Id orderId;
    }
}