public class PaymentsTriggerHandler {
    public static void createOrderAndOrderItem(Set<Id> paymentIds){
        try{
            List<Order> insertOrderList = new List<Order>();
            List<Payments__c> updatePaymentList = new List<Payments__c>();
            List<OrderItem> insertOrderItemList = new List<OrderItem>();
            Map<Id,Id> paymentIdVsOrderId = new Map<Id,Id>();
            
            List<Payments__c> getPayments = [SELECT Id, CreatedById,OwnerId, Account__c,Account__r.Lead__c,Order_Status__c,Lead__c,Market_Unit__c,Related_Event_ID__c,Pricebook2Id__c,CurrencyIsoCode,Fixed_discount_Type__c,Campaign__c,Journal__c FROM Payments__c WHERE Id=:paymentIds LIMIT 10000];
            for(Payments__c record: getPayments){
            	Order createOrder = new Order();
                createOrder.Payments__c = record.Id;
                createOrder.Status = !String.isBlank(record.Order_Status__c) ? record.Order_Status__c : '' ;
                createOrder.Market_Unit__c = !String.isBlank(record.Market_Unit__c) ? record.Market_Unit__c : '' ;
                createOrder.AccountId = (record.Account__c != null) ? record.Account__c : null ;
                createOrder.Related_Event_ID__c =  !String.isBlank(record.Related_Event_ID__c) ? record.Related_Event_ID__c : '' ; 
                createOrder.Pricebook2Id = (record.Pricebook2Id__c != null) ? record.Pricebook2Id__c : null ; 
                createOrder.Journal__c = (record.Journal__c != null) ? record.Journal__c : null ; 
                createOrder.CurrencyIsoCode = record.CurrencyIsoCode;
                createOrder.Fixed_discount_Type__c = (record.Fixed_discount_Type__c != null) ? record.Fixed_discount_Type__c : 0 ; 
                createOrder.EffectiveDate = System.Today();
                createOrder.Lead__c = (record.Account__r.Lead__c != null) ? record.Account__r.Lead__c : null ;
                createOrder.Campaign__c = (record.Campaign__c != null) ? record.Campaign__c : null ;
                createOrder.OwnerId = record.OwnerId;
                createOrder.CreatedById = record.CreatedById;
                insertOrderList.add(createOrder);
        	}
            

            
            if(!insertOrderList.isEmpty()){
                 insert insertOrderList;
                for(Order record:insertOrderList){
                    if(!paymentIdVsOrderId.containskey(record.Payments__c)){
                        paymentIdVsOrderId.put(record.Payments__c,record.Id);
                    }
                    Payments__c paymentRecord = new Payments__c();
                    paymentRecord.Id = record.Payments__c;
                    paymentRecord.Order__c = record.Id;
                    paymentRecord.isInsertOrder__c = false;
                    updatePaymentList.add(paymentRecord);
                }
            } 
            if(!insertOrderList.isEmpty()){
                List<Payment_order_line__c> getPaymentOrderLines = [SELECT Id,CreatedById,Name,Payments__c,Quantity__c,Payments__r.Pricebook2Id__c,PricebookEntryId__c,Product2Id__c,Discount__c,UnitPrice__c,Provision_base__c FROM Payment_order_line__c WHERE Payments__c=:paymentIds LIMIT 10000];
                for(Payment_order_line__c record: getPaymentOrderLines){
                	OrderItem createOrderItem = new OrderItem();
                	createOrderItem.OrderId = paymentIdVsOrderId.get(record.Payments__c);
                	createOrderItem.Discount__c = (record.Discount__c != null) ? record.Discount__c : null ;
                	createOrderItem.PricebookEntryId = (record.PricebookEntryId__c != null) ? record.PricebookEntryId__c : null ;
               		createOrderItem.Product2Id = (record.Product2Id__c != null) ? record.Product2Id__c : null ; 
                	createOrderItem.Quantity = (record.Quantity__c != null) ? record.Quantity__c : 0 ;
                	createOrderItem.UnitPrice =  (record.UnitPrice__c != null) ? record.UnitPrice__c : 0 ; 
                	createOrderItem.Product2Id = (record.Product2Id__c != null) ? record.Product2Id__c : null ; 
                    createOrderItem.CreatedById = record.CreatedById;
                
                	insertOrderItemList.add(createOrderItem);
            	}
                
            }
            
            
            
            if(!insertOrderItemList.isEmpty()){
                 insert insertOrderItemList;
            }
            if(!updatePaymentList.isEmpty()){
                 update updatePaymentList;
            }
            
            
            
            }catch(Exception ex){
        DFJ_ErrorLogController.addErrorLogs('', 'Error while creating Order and OrderItems on payment Settled record', ex.getMessage(), 'Error', 'PaymentsTriggerHandler.createOrderAndOrderItem', '', String.valueOf(ex.getLineNumber()));
    }
    }

}