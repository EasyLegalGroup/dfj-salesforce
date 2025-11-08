@IsTest 
public class PaymentsTriggerHandlerTest {
    
    
    @isTest
    private static void createOrderAndOrderItem_Test1(){
        try{
            
            Product2 pro = new Product2(Name = 'iPhone X', Family = 'Mobile');
        Insert pro;
        Pricebook2 standardPricebook = new Pricebook2( Id = Test.getStandardPricebookId(), IsActive = true);
        Update standardPricebook;
        
        
        
        //Create the PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = pro.Id,
            UnitPrice = 1020,
            IsActive = true
        );
        Insert pbe;
     Lead testLead = new Lead(Company='Test Lead',FirstName='John',LastName='Doe',Provider_id__c = '1324');
            insert testLead;
            Account accInst = new Account();
            accInst.Name = 'test Acc';
            accInst.Lead__c = testLead.Id;
            insert accInst;
            
            Journal__c journalInstance = new Journal__c();
            journalInstance.External_record_uuid__c = 'test';
            journalInstance.Lead__c = testLead.Id;
            journalInstance.Account__c = accInst.id;
            insert journalInstance;
            
            Payments__c paymentRecord = new Payments__c();
            paymentRecord.Account__c = accInst.id;
            paymentRecord.Type__c = 'Onetime';
            paymentRecord.Amount__c =  100 ;
            paymentRecord.CurrencyIsoCode =  'DKK' ;
            paymentRecord.Pricebook2Id__c = standardPricebook.Id;
            paymentRecord.Lead__c = testLead.Id;
            paymentRecord.Order_Status__c = 'Draft';
            paymentRecord.Market_Unit__c = 'DFJ_DK';
            paymentRecord.Related_Event_ID__c = '' ;
            paymentRecord.Fixed_discount_Type__c = 10 ;
            paymentRecord.Campaign__c = null ;
            paymentRecord.isInsertOrder__c = true ;
            paymentRecord.Journal__c = null ;
            paymentRecord.Status__c = 'Pending' ;
            paymentRecord.IsInsertOrder__c = true;
            paymentRecord.BillingCountry__c = 'DK';
            paymentRecord.Billing_name__c = accInst.Name;
            paymentRecord.Billing_email__c = 'test@test.com';
            insert paymentRecord;
            
            Payment_order_line__c paymentOrderItem = new Payment_order_line__c();
            //for OrderItems
            paymentOrderItem.Provision_base__c = 0;
            paymentOrderItem.Discount__c = 10;
            paymentOrderItem.UnitPrice__c = 100;
            paymentOrderItem.Product2Id__c = pro.Id;
            paymentOrderItem.PricebookEntryId__c = pbe.Id;
            paymentOrderItem.CurrencyIsoCode = 'DKK';
            //End
            paymentOrderItem.Amount__c = 20; 
            paymentOrderItem.Quantity__c = 1;
            paymentOrderItem.Vat__c = 0;
            paymentOrderItem.Name = 'Test';
            paymentOrderItem.Payments__c = paymentRecord.Id;
            insert paymentOrderItem;
            Payments__c updatepaymentRecord = new Payments__c();
            updatepaymentRecord.Id =   paymentRecord.Id;
            updatepaymentRecord.Status__c = 'Settled';
            update  updatepaymentRecord;
            

            List<Order> orderList = [SELECT Id FROM Order WHERE Payments__c =:paymentRecord.id];
            System.assertEquals(1, orderList.size());
            //System.debug('journalList-->'+journalList);
        }catch(exception ex){
            System.debug('error message--> '+ ex.getmessage()+ '--InLine --->'+ex.getlinenumber());
        }
    }
    
    @isTest
    private static void createOrderAndOrderItem_Test2(){
        try{
            
            
             Product2 pro = new Product2(Name = 'iPhone X', Family = 'Mobile');
        Insert pro;
        Pricebook2 standardPricebook = new Pricebook2( Id = Test.getStandardPricebookId(), IsActive = true);
        Update standardPricebook;
        
        
        
        //Create the PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = pro.Id,
            UnitPrice = 1020,
            IsActive = true
        );
        Insert pbe;
           
            
            
            Lead testLead = new Lead(Company='Test Lead',FirstName='John',LastName='Doe',Provider_id__c = '1324');
            insert testLead;
            Account accInst = new Account();
            accInst.Name = 'test Acc';
            accInst.Lead__c = testLead.Id;
            insert accInst;
            
            Journal__c journalInstance = new Journal__c();
            journalInstance.External_record_uuid__c = 'test';
            journalInstance.Lead__c = testLead.Id;
            journalInstance.Account__c = accInst.id;
            insert journalInstance;
            
            Payments__c paymentRecord = new Payments__c();
            paymentRecord.Account__c = accInst.id;
            paymentRecord.Type__c = 'Onetime';
            paymentRecord.Amount__c =  100 ;
            paymentRecord.CurrencyIsoCode =  'DKK' ;
            paymentRecord.Pricebook2Id__c = standardPricebook.Id;
            paymentRecord.Lead__c = testLead.Id;
            paymentRecord.Order_Status__c = 'Draft';
            paymentRecord.Market_Unit__c = 'DFJ_DK';
            paymentRecord.Related_Event_ID__c = '' ;
            paymentRecord.Fixed_discount_Type__c = 10 ;
            paymentRecord.Campaign__c = null ;
            paymentRecord.isInsertOrder__c = true ;
            paymentRecord.Journal__c = null ;
            paymentRecord.Status__c = 'Pending' ;
            paymentRecord.IsInsertOrder__c = true;
            paymentRecord.BillingCountry__c = 'DK';
            paymentRecord.Billing_name__c = accInst.Name;
            paymentRecord.Billing_email__c = 'test@test.com';
            insert paymentRecord;
            
            Payment_order_line__c paymentOrderItem = new Payment_order_line__c();
            //for OrderItems
            paymentOrderItem.Provision_base__c = 0;
            paymentOrderItem.Discount__c = 10;
            paymentOrderItem.UnitPrice__c = 100;
            paymentOrderItem.Product2Id__c = pro.Id;
            paymentOrderItem.PricebookEntryId__c = pbe.Id;
            paymentOrderItem.CurrencyIsoCode = 'DKK';
            //End
            paymentOrderItem.Amount__c = 20; 
            paymentOrderItem.Quantity__c = 1;
            paymentOrderItem.Vat__c = 0;
            paymentOrderItem.Name = 'Test';
            paymentOrderItem.Payments__c = paymentRecord.Id;
            insert paymentOrderItem;
            Payments__c updatepaymentRecord = new Payments__c();
            updatepaymentRecord.Id =   paymentRecord.Id;
            updatepaymentRecord.Status__c = 'Settled';
            update  updatepaymentRecord;
            
            
            List<Payments__c> paymentList = [SELECT Id,IsInsertOrder__c FROM Payments__c WHERE Id =:paymentRecord.id];
            System.assertEquals(false, paymentList[0].IsInsertOrder__c);
            //System.debug('journalList-->'+journalList);
        }catch(exception ex){
            System.debug('error message--> '+ ex.getmessage()+ '--InLine --->'+ex.getlinenumber());
        }
    }
}