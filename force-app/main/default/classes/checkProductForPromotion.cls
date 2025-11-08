public class checkProductForPromotion {
       public static void setPromotionalOrder(List<OrderItem> orderItemList) {
           try {
               Set<Id> orderIdSet = new Set<Id>();
               for (OrderItem orderInstance : orderItemList) {
                   orderIdSet.add(orderInstance.OrderId);
               }

               List<OrderItem> productList = new List<OrderItem>();
               productList = [SELECT Id, OrderId, Product2Id, Order.Promotional_Order__c, Product2.For_Promotion__c FROM OrderItem WHERE OrderId IN :orderIdSet];

               if (productList.size() > 0) {
                   Map<String, List<Boolean>> OrderVsProductPromotion = new Map<String, List<Boolean>>();
                   for (OrderItem orderItemInstance : productList) {
                       if (!OrderVsProductPromotion.containsKey(orderItemInstance.OrderId)) {
                           OrderVsProductPromotion.put(orderItemInstance.OrderId, new List<Boolean>());
                       }
                       OrderVsProductPromotion.get(orderItemInstance.OrderId).add(
                               orderItemInstance.Product2.For_Promotion__c);
                       OrderVsProductPromotion.put(orderItemInstance.OrderId,
                               OrderVsProductPromotion.get(orderItemInstance.OrderId));
                   }
                   Set<Id> updateTrueSet = new Set<Id>();
                   Set<Id> updateFalseSet = new Set<Id>();
                   for (Id orderIdInstance : OrderVsProductPromotion.keySet()) {
                       if (!OrderVsProductPromotion.get(orderIdInstance).contains(false)) {
                           updateTrueSet.add(orderIdInstance);
                       } else if (OrderVsProductPromotion.get(orderIdInstance).contains(false)) {
                           updateFalseSet.add(orderIdInstance);
                       }

                   }
                   List<Order> updateTrueList = new List<Order>();
                   updateTrueList = [SELECT Id, Promotional_Order__c FROM Order WHERE Id IN:updateTrueSet];
                   for (Order orderObj : updateTrueList) {
                       orderObj.Promotional_Order__c = true;
                   }
                   if(updateTrueList.size()>0) {
                       upsert updateTrueList;
                   }

                   List<Order> updateFalseList = new List<Order>();
                   updateFalseList = [SELECT Id, Promotional_Order__c FROM Order WHERE Id IN:updateFalseSet];
                   for (Order orderObj : updateFalseList) {
                       orderObj.Promotional_Order__c = false;
                   }
                   if(updateFalseList.size()>0) {
                       upsert updateFalseList;
                   }
               }
           }catch(Exception ex){
               System.debug('Exception occured::'+ex.getMessage()+' at Line Number::'+ex.getLineNumber());
           }
       }

}