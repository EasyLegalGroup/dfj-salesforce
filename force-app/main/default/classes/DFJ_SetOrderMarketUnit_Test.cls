@isTest
public with sharing class DFJ_SetOrderMarketUnit_Test {
    @isTest
    public static void setOrderMarketUnit_Apex_Test(){
        Account accInstance = new Account();
        accInstance.Name = 'Test';
        insert accInstance;
        List<Order> orderList = new List<Order>();
        for(Integer i=0;i<10;i++){
            Order orderInstance = new Order();
            orderInstance.AccountId = accInstance.Id;
            orderInstance.EffectiveDate = Date.today();
            orderInstance.Status = 'Draft';
            orderList.add(orderInstance);
        }
        insert orderList;
        Test.startTest();
        update orderList;
        DFJ_SetOrderMarketUnit.setOrderMarketUnit_Apex(orderList);
        
        Test.stopTest();
    }
}