public with sharing class DFJ_UpdateCallHistoryMarketUnit_Apex {
   
    public static void setMarketUnit_Apex(List<telegenta__Telegenta_Call_History__c> callHistoryList){
        try{
            String userId = UserInfo.getUserId();
            List<User> userList = new List<User>();
            userList = [SELECT Id,Name,Market_Unit__c FROM User WHERE Id =: userId];
            System.debug('userList----'+userList);
            if(callHistoryList[0].telegenta__Contact__c == null){
                if(callHistoryList[0].telegenta__Account__c == null){
                    if(callHistoryList[0].telegenta__Lead__c == null){
                        callHistoryList[0].Market_Unit__c = userList[0].Market_Unit__c;
                    }
                }
            }
            System.debug('callHistoryList----'+callHistoryList);
        }catch(Exception ex){
            System.debug('Error----'+ex.getMessage()+' at line number----'+ex.getLineNumber());
        }
    }
}