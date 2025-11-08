public with sharing class DFJ_SetOrderMarketUnit {
  
    public static void setOrderMarketUnit_Apex(List<Order> orderList){
        try{
            Set<Id> accountIdSet = new Set<Id>();  //Creating a set of account Id from Order.
            Set<Id> userIdSet = new Set<Id>();  //Creating a set of user Id from Order.
            Map<Id,Account> IdVSAccountMap = new Map<Id,Account>();  //Creating a map of Id and Account.
            Map<Id,User> IdVSUserMap = new Map<Id,User>();  //Creating a map of Id and User.
            Set<Id> orderIdSet = new Set<Id>();

            //Inserting the Id's of account and user in sets.
            for(Order orderObj : orderList){
                accountIdSet.add(orderObj.AccountId );
                orderIdSet.add(orderObj.Id);
            }

            //System.debug('accountIdSet----->'+accountIdSet);
            //System.debug('userIdSet----->'+userIdSet);

           if(!accountIdSet.isEmpty()){
            //Fetching all the accounts from the Id set. 
            List<Account> accountList = new List<Account>();
            accountList = [SELECT Id,Name,Market_Unit__c,OwnerId FROM Account WHERE Id IN: accountIdSet LIMIT 10000];
            for(Account accObject : accountList){
                IdVSAccountMap.put(accObject.Id,accObject);
                userIdSet.add(accObject.OwnerId);
            }
           }

           if(!userIdSet.isEmpty()){
               //Fetching all the user from Id set.
            List<User> userList = new List<User>();
            userList = [SELECT ID,Name,Market_Unit__c FROM User WHERE Id IN: userIdSet LIMIT 10000];
            for(User userObj : userList){
                IdVSUserMap.put(userObj.Id,userObj);
            }
           }



           List<Order> orderListNew = new List<Order>();
           
           orderListNew = [SELECT Id,Market_Unit__c,AccountId,OwnerId FROM Order WHERE Id IN:orderIdSet LIMIT 10000];

           //System.debug('orderListNew----->'+orderListNew);

           //Inserting the maket unit value from the account or user in order's market unit.
           if(!orderListNew.isEmpty()){
               for(Order orderObj : orderListNew){
                if(orderObj.AccountId != null){
                    String ownerId = IdVSAccountMap.get(orderObj.AccountId).OwnerId;
                    if(IdVSAccountMap.get(orderObj.AccountId).Market_Unit__c != null){
                        orderObj.Market_Unit__c = IdVSAccountMap.get(orderObj.AccountId).Market_Unit__c;
                    }else if(IdVSUserMap.get(ownerId).Market_Unit__c != null){
                        orderObj.Market_Unit__c = IdVSUserMap.get(ownerId).Market_Unit__c;
                    }
                }
               }
           }
           
            
            //System.debug('orderListNewUpdtaed----->'+orderListNew);
            if(!orderListNew.isEmpty()){
                update orderListNew;
            }
            
        }catch(Exception ex){
            System.debug('Exception occured::'+ex.getMessage()+' at Line Number::'+ex.getLineNumber());
        }
    }
}