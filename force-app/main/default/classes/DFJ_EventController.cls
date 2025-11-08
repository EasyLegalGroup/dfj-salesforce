public with sharing class DFJ_EventController {
    @AuraEnabled(cacheable=true)
    public static List<wrapper> getAllEventethod(String userId, String accId, String changeUserid){
        System.debug('userId;;'+userId);
        List<wrapper> wrapperList = New List<wrapper>();
        List<Event> getEvent = [SELECT Id, WhatId, StartDateTime, EndDateTime, OwnerId, AccountId, Journal__c, Subject FROM Event WHERE (OwnerId=:changeUserid)  LIMIT 10000];
        for (Event eve : getEvent) {
            wrapper wrp = new wrapper();
            wrp.TIMEE = String.ValueOf(eve.StartDateTime);
            wrp.EVENTE = String.ValueOf(eve.Subject);
            wrapperList.add(wrp);

        }
        return wrapperList;
    }
    public class wrapper{
       @AuraEnabled
          public string TIMEE;
          @AuraEnabled
          public string EVENTE;

    } 

    @auraEnabled
    public static List<EventDataWrapper> getAllRelatedEvents(DateTime selectedDateTime , String selectedUserId){
        try {
            List<EventDataWrapper> eventDataWrapperList = new List<EventDataWrapper>();
            Date activityDate = Date.newInstance(selectedDateTime.year(),selectedDateTime.month(),selectedDateTime.day());
            List<Event> eventsList = new List<Event>();
            eventsList = [SELECT Id,
                            OwnerId,
                            Description,
                            Subject,
                            StartDateTime,
                            EndDateTime,
                            WhoId,
                            CreatedDate FROM Event
                            WHERE OwnerId = :selectedUserId AND ActivityDate = :activityDate ORDER BY StartDateTime ASC LIMIT 10000]; //(WhoId != null OR whatId != null)
                            system.debug('eventsList'+eventsList);
            if(!eventsList.isEmpty()){
                for(Event eventLoop : eventsList){
                EventDataWrapper eventDataWrapperInstance = new EventDataWrapper();
                eventDataWrapperInstance.eventStartTime = String.valueOf(eventLoop.StartDateTime);
                eventDataWrapperInstance.eventEndTime = String.valueOf(eventLoop.EndDateTime);
                eventDataWrapperInstance.eventName = eventLoop.Subject;
                eventDataWrapperList.add(eventDataWrapperInstance);
            } 
            }           
        return eventDataWrapperList;
        } catch(Exception ex) {
            System.debug(ex.getMessage());
            DFJ_ErrorLogController.addErrorLogs('', 'Getting all related events', ex.getMessage(), 'Error', 'DFJ_EventController.getAllRelatedEvent()', ex.getStackTraceString(), String.valueOf(ex.getLineNumber()));
        }
        return null;
    }

    public class EventDataWrapper{
        @auraEnabled
        public String eventStartTime;
        @auraEnabled
        public String eventEndTime;
        @auraEnabled
        public String eventName;
    }
}