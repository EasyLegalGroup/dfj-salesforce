trigger PaymentsTrigger on Payments__c (after update) {
    System.debug('Inn Trigger---');
     if(trigger.isAfter && trigger.isUpdate){
         System.debug('Inn Trigger--11-');
         Set<Id> paymentIdSet = new Set<Id>();
        for (Payments__c record : trigger.new) {
            System.debug('record.Order__c -'+record.Order__c );
                System.debug('record.Status__c -'+record.Status__c );
                 System.debug('record.isInsertOrder__c-'+record.isInsertOrder__c);
			if(record.Order__c == Null && record.isInsertOrder__c && record.Status__c.equals('Settled')){
                System.debug('Inn Settled--11-');
                 
                paymentIdSet.add(record.Id);
            }
        }
        if(!paymentIdSet.isEmpty()){
             PaymentsTriggerHandler.createOrderAndOrderItem(paymentIdSet);
        }
    }
}