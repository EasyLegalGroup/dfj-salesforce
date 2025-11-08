public class GettingNextLead {
 public static String nextLeadFromSession_Apex(String currentSessionId) {

        Integer MAX = 0;
        System.debug('CurrentSessionId---'+currentSessionId);
        if (currentSessionId != null && currentSessionId.trim() != '') {
            List<Event> listOfEvents = new List<Event>();
            Datetime currentTime = Datetime.now();
            String userIdString = String.valueOf(UserInfo.getUserId());
            List<telegenta__Dialer_Session__c> dialerSessionActiveSession = new List<telegenta__Dialer_Session__c>();
            dialerSessionActiveSession = [SELECT Id,telegenta__Lead_group__c,telegenta__End_Time__c,telegenta__Pause_Next__c,telegenta__Start_Time__c,telegenta__Status__c,telegenta__Stop_Next__c,telegenta__Talking_Time__c,telegenta__Filter_Query__c FROM telegenta__Dialer_Session__c WHERE telegenta__Status__c != 'Ended' AND Id = :currentSessionId WITH SECURITY_ENFORCED LIMIT 1];
            System.debug('dialerSessionActiveSession---'+dialerSessionActiveSession);
            if (dialerSessionActiveSession.isEmpty()) {
                return 'Session has been ended';
            }

            List<Lead> leadsList = new List<Lead>();
            List<telegenta__Lead_group__c> leadGroupsList = new List<telegenta__Lead_group__c>();
            if (!dialerSessionActiveSession.isEmpty()) {

                leadGroupsList = [SELECT Id,Name,telegenta__Description__c,telegenta__Filter__c,telegenta__Filter_Query__c,telegenta__Auto_Dial_Mode__c,telegenta__Phone_Number__c,telegenta__Phone_number_Id__c,telegenta__Reassign_No_Answer_Owner__c,telegenta__Change_Owner_on_No_Answer__c,telegenta__Priority_String__c,telegenta__Call_Interval__c FROM telegenta__Lead_group__c WHERE Id = :dialerSessionActiveSession[0].telegenta__Lead_group__c WITH SECURITY_ENFORCED LIMIT 1];
                String ReassignNoAnswerOwnerId = '';
                if(leadGroupsList != null){
                    if(!leadGroupsList.isEmpty()){
                        ReassignNoAnswerOwnerId = leadGroupsList[0].telegenta__Reassign_No_Answer_Owner__c;
                    }
                }
                System.debug('leadGroupsList---'+leadGroupsList);

                String ReassignNoAnswerOwnerForEvent = ReassignNoAnswerOwnerId == null ? '' : ' OR OwnerId =: ReassignNoAnswerOwnerId';
                System.debug('ReassignNoAnswerOwnerForEvent---'+ReassignNoAnswerOwnerForEvent);
                List<Event> events = new List<Event>();
                List<Lead> listOfLeadsWithEvents = new List<Lead>();
                //events = [SELECT Id,WhoId,CreatedDate,ActivityDateTime,Subject,Type FROM Event WHERE Type = 'Callback' AND (OwnerId =: userIdString OR OwnerId =: ReassignNoAnswerOwnerForEvent) AND WhoId != NULL AND telegenta__Process_Time__c = NULL AND ActivityDateTime <: currentTime ORDER BY ActivityDateTime ASC LIMIT 1];
                String eventQueryString ='';
                String leadId ='';
                String callbackType = 'Callback';
                eventQueryString = 'SELECT Id,WhoId,CreatedDate,StartDateTime,Subject,Type FROM Event WHERE Type =: callbackType AND (OwnerId =: userIdString OR OwnerId =: ReassignNoAnswerOwnerForEvent) AND WhoId != NULL AND telegenta__Process_Time__c = NULL AND StartDateTime <:currentTime'+' WITH SECURITY_ENFORCED'+' ORDER BY StartDateTime ASC'+' LIMIT 100';
                System.debug('eventQueryString---'+eventQueryString);
                events = Database.query(eventQueryString);
                System.debug(JSON.serialize(events));
                /* if(events != null && !events.isEmpty()){
                     for (Event eventLoop : events) {
                         leadId = eventLoop.WhoId;
                         break;
                     }
                 }*/

                if (!events.isEmpty()) {
                  String sObjectName = '';
                    System.debug('events---'+events);
                    
                    for (Event eventLoop : events) {
                        if (Id.valueOf(eventLoop.WhoId).getSObjectType().getDescribe().getName() == 'Lead') {
                            leadId = eventLoop.WhoId;
                            eventLoop.telegenta__Process_Time__c = currentTime;
                            eventLoop.telegenta__Lead_group__c = leadGroupsList[0].Id;
                            listOfEvents.add(eventLoop);
                            break;
                        }
                       
                    }
                    if (leadId != null && leadId.trim() != '') {
                       System.debug('leadId----'+leadId);
                       // String sObjectName = Id.valueOf(leadId).getSObjectType().getDescribe().getName(); //Getting the name of the object from Id.
                        System.debug('sObjectName----'+sObjectName);
                            listOfLeadsWithEvents = [SELECT Id,IsConverted,Name FROM Lead WHERE Id =: leadId WITH SECURITY_ENFORCED];
                            System.debug('listOfLeadsWithEvents---'+listOfLeadsWithEvents);
                            //events[0].telegenta__Process_Time__c = currentTime; //Process time should be the current time (When the "next" button is clicked)
                           // events[0].telegenta__Lead_group__c = leadGroupsList[0].Id; //Current lead group Id is set in the event.
                            if(listOfLeadsWithEvents != null && !listOfLeadsWithEvents.isEmpty()){
                                System.debug('events---'+events);
                                update listOfEvents;
                                System.debug('listOfLeadsWithEvents[0].Id----'+listOfLeadsWithEvents[0].Id);
                                //return listOfLeadsWithEvents[0].Id;

                                //Recording the information in the Log object that "The Lead has already been converted" if the lead has already been converted.
                                telegenta__Log__c logsToInsert = new telegenta__Log__c();
                                logsToInsert.telegenta__Affected_record__c = leadId;
                                logsToInsert.telegenta__Event__c = 'Getting lead of the specified event.';
                                logsToInsert.telegenta__Message__c = 'Lead has been converted.';
                                logsToInsert.telegenta__Severity__c = 'Info';
                                logsToInsert.telegenta__Source__c = 'nextLeadFromSession_Apex';
                                System.debug('logsToInsert---'+logsToInsert);
                                insert logsToInsert;
                                // return missing
                                if (listOfLeadsWithEvents[0].IsConverted == true) {
                                    //System.debug('You had an appointment with '+' '+listOfLeadsWithEvents[0].Name+' '+ 'at'+' '+ events[0].StartDateTime +' '+' but this lead is converted and can’t be processed. Please press next lead again to get another lead.');
                                    String eventDate = events[0].StartDateTime.format('yyyy/MM/dd kk:mm:ss');
                                    return 'You had an appointment with '+' '+listOfLeadsWithEvents[0].Name+' '+ 'at'+' '+ eventDate +' '+' but this lead is converted and can’t be processed. Please press Get Next Lead again to get another lead.'  ;
                                } else {
                                    System.debug('leadId----'+listOfLeadsWithEvents[0].Id);
                                    return listOfLeadsWithEvents[0].Id;
                                }
                                //return fetchNextLead_Apex(ReassignNoAnswerOwnerId,leadGroupsList,dialerSessionActiveSession,leadsList,events,leadId,userIdString,currentTime);
                            }
                    }
                    // return missing
                    return fetchNextLead_Apex(ReassignNoAnswerOwnerId,leadGroupsList,dialerSessionActiveSession,leadsList,events,leadId,userIdString,currentTime);
                } else {
                    return fetchNextLead_Apex(ReassignNoAnswerOwnerId,leadGroupsList,dialerSessionActiveSession,leadsList,events,leadId,userIdString,currentTime);
                }


            }
        }
        return null;
    }

    public static String fetchNextLead_Apex(String ReassignNoAnswerOwnerId,List<telegenta__Lead_group__c>leadGroupsList,List<telegenta__Dialer_Session__c>dialerSessionActiveSession,List<Lead>leadsList,List<Event>events,String leadId,String userIdString,Datetime currentTime){
        try{
            System.debug('ReassignNoAnswerOwnerId---' + ReassignNoAnswerOwnerId);
            String ReassignNoAnswerOwner = ReassignNoAnswerOwnerId == null ? '' : ' OR OwnerId =: ReassignNoAnswerOwnerId';
            List<String> orderByQueryList = new List<String>();
            Set<String> fieldsToQuerySet = new Set<String>();
            String fieldsToQuery = '';
            if (leadGroupsList[0].telegenta__Priority_String__c != null && leadGroupsList[0].telegenta__Priority_String__c.trim() != '') {
                orderByQueryList = leadGroupsList[0].telegenta__Priority_String__c.split(';');
                for (String fieldCheck : orderByQueryList) {
                    fieldCheck = fieldCheck.trim();
                    if (fieldCheck.split(' ')[0] != 'telegenta__Next_Call_Time__c') {
                        fieldsToQuerySet.add(fieldCheck.split(' ')[0]);
                    }
                }
            }
            String orderByQuery = String.join(orderByQueryList, ' NULLS LAST ,');
            System.debug('orderByQueryBefore----'+orderByQuery);
            //orderByQuery = orderByQuery != '' ? ' ORDER BY ' + orderByQuery + ' NULLS LAST LIMIT 50000' : ' LIMIT 50000';
            orderByQuery = orderByQuery != '' ? ' ORDER BY ' + orderByQuery + ' NULLS LAST LIMIT 1' : ' LIMIT 1';
            System.debug('orderByQueryAfter----'+orderByQuery);
            System.debug('dialerSessionActiveSession[0].telegenta__Filter_Query__c' + dialerSessionActiveSession[0].telegenta__Filter_Query__c);
            if (!fieldsToQuerySet.isEmpty()) {
                fieldsToQuery = ',' + String.join(new List<String>(fieldsToQuerySet), ',');
            }
            System.debug('fieldsToQuery---' + fieldsToQuery);

            /* String queryString = 'SELECT Id,Name,telegenta__Next_Call_Time__c' + fieldsToQuery + ' FROM LEAD WHERE (' + dialerSessionActiveSession[0].telegenta__Filter_Query__c + ' AND ' +
                     '( (OwnerId =: userIdString ' + ReassignNoAnswerOwner + ') AND (telegenta__Next_Call_Time__c <=: currentTime OR telegenta__Next_Call_Time__c = null) AND (Status = \'' + 'New' + '\' OR Status = \'' + 'Working' + '\' OR Status = \'' + 'Open - Not Contacted' + '\') )) OR ' +
                     '( OwnerId =: userIdString AND telegenta__Next_Call_Time__c <=: currentTime AND IsConverted = false ) ' + orderByQuery;
             System.debug('queryString---' + queryString);*/


            /*New Changes*/
            String queryString = 'SELECT Id,Name,telegenta__Next_Call_Time__c,telegenta__Last_Contact_State__c'+ fieldsToQuery +' FROM LEAD WHERE (' + dialerSessionActiveSession[0].telegenta__Filter_Query__c + ' AND ' +
                    '( (OwnerId =: userIdString '+ReassignNoAnswerOwner+') AND (telegenta__Next_Call_Time__c <=: currentTime OR telegenta__Next_Call_Time__c = null) AND telegenta__Last_Contact_State__c != \''+'Got appointment'+'\' AND (Status = \''+'New'+'\' OR Status = \''+'Working'+'\' OR Status = \''+'Open - Not Contacted'+'\') )) '+' WITH SECURITY_ENFORCED '+orderByQuery;
            System.debug('queryString---'+queryString);
            leadsList = Database.query(queryString);
            if (!leadsList.isEmpty()) {
                String callInterval = String.valueOf(leadGroupsList[0].telegenta__Call_Interval__c);
                if (!leadGroupsList.isEmpty()) {
                    callInterval = callInterval == null ? '3' : callInterval;
                }
                leadsList[0].telegenta__Next_Call_Time__c = Datetime.now().addHours(Integer.valueOf(callInterval));
                System.debug('leadsList[0].telegenta__Next_Call_Time__c---'+leadsList[0].telegenta__Next_Call_Time__c);
                System.debug('leadsList---'+leadsList);
                update leadsList;
                update events;
                System.debug('leadsList[0].Id----'+leadsList[0].Id);
                return leadsList[0].Id;
            } else {
                return 'No lead found';
            }

        }catch(Exception ex){
            System.debug('Error---'+ex.getMessage()+' At line---'+ex.getLineNumber());
            telegenta__Log__c logsToInsert = new telegenta__Log__c();
            logsToInsert.telegenta__Affected_record__c = leadId;
            logsToInsert.telegenta__Event__c = 'Processing next lead by normal query.';
            logsToInsert.telegenta__Message__c = ex.getMessage() + ' At line '+ex.getLineNumber();
            logsToInsert.telegenta__Severity__c = 'Error';
            logsToInsert.telegenta__Source__c = 'processNextLeadIfLeadConverted_Apex';
            System.debug('logsToInsert---'+logsToInsert);
            insert logsToInsert;
        }
        return null;
    }
}