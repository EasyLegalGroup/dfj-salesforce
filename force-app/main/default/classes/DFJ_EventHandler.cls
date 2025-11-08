public class DFJ_EventHandler {
    public static void UpdateEventSubject(List<Event> eventList){
        Set<Id> leadIdSet = new Set<Id>();
        try{
            for(Event eventLoop : eventList){                
                if(eventLoop.whoId != null){
                    DescribeSObjectResult describe = Id.valueOf(eventLoop.whoId).getSObjectType().getDescribe();
                	String ObjectNameFromCall = String.valueOf(describe.SObjectType);
                    System.debug('ObjectNameFromCall-->>'+ObjectNameFromCall);
                    if(ObjectNameFromCall == 'Lead'){
                        leadIdSet.add(eventLoop.whoId);
                    }
                    
                }            
            }
            if(!leadIdSet.isEmpty()){
                List<Lead> leadList = new List<Lead>();
                Map<Id,String> leadIdVsLeadRatingMap = new Map<Id,string>();
                leadList = [SELECT Id,Name,Rating FROM LEAD WHERE Id IN : leadIdSet LIMIT 10000];
                for(Lead leadLoop : leadList){
                    if(leadLoop.Rating != null){
                        leadIdVsLeadRatingMap.put(leadLoop.Id,leadLoop.Rating);
                    }
                }
                System.debug('leadIdVsLeadRatingMap--->>'+leadIdVsLeadRatingMap);
                for(Event eventLoop : eventList){
                    if(eventLoop.whoId != null){
                        if(leadIdVsLeadRatingMap.containsKey(eventLoop.whoId)){
                            eventLoop.Subject += ' ('+String.valueOf(leadIdVsLeadRatingMap.get(eventLoop.whoId)).trim()+')';
                        } 
                    }
                }                
            }
            System.debug('Event with updated subject--->>'+eventList);
        } catch(Exception exp){
            System.debug('Error----'+exp.getMessage()+' at line number----'+exp.getLineNumber());
            AddErrorLogs_Apex('Record id not available','Updating event subject',exp.getMessage(),'Error','UpdateEventSubject Trigger',String.valueOf(exp.getLineNumber()));            
        }    
    }
    
    public static void AddErrorLogs_Apex(String recordId, String event, String message, String severnity,String source,String lineNumber){
        Log__c logObj = new Log__c();
        logObj.Affected_record__c = recordId;
        logObj.Event__c = event;
        logObj.Message__c = message;
        logObj.Severity__c = severnity;
        logObj.Source__c = source;
        logObj.Line_Number__c = lineNumber;
        insert logObj;
    }
}