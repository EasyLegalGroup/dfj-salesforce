public with sharing class DFJ_AppointmentController_Apex {
    @AuraEnabled
    public static DFJ_AppointmentService_Apex.AppointmentSetupWrapper getAppointmentConfigurations(){
        try {
            return DFJ_AppointmentService_Apex.getAppointmentConfigurations();
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Error in getting GetAllPicklistValues_Apex', ex.getMessage(), 'Error', 'DFJ_AppointmentController_Apex.GetAllPicklistValues_Apex', String.valueOf(ex.getLineNumber()));
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static DFJ_AppointmentService_Apex.ResponseWrapper saveAccountAndEventInformation(String accountData, String eventData, String accountId, Integer timeDuration, String startTime,String startHours,String inputStartdate) 
    {
        DFJ_AppointmentService_Apex.ResponseWrapper returnResponse = new DFJ_AppointmentService_Apex.ResponseWrapper();
        try {
            if (String.isBlank(accountData) || String.isBlank(eventData)) {
                returnResponse.message = 'Please verify If event information is populated';
                returnResponse.success = false;
                return returnResponse;
            }
            Account accountToUpdate = (Account) JSON.deserialize(accountData, Account.class); 
            Event eventToCreate = (Event) JSON.deserialize(eventData, Event.class);
            List<Journal__c> accountRelatedJournal = new List<Journal__c>();
            if (accountToUpdate != null) {
                accountToUpdate.Id = accountId;
                accountToUpdate.Legal_assistance__c = String.isBlank(accountToUpdate.Legal_assistance__c) ? '' : accountToUpdate.Legal_assistance__c ;
                accountToUpdate.Service_call__c = String.isBlank(accountToUpdate.Service_call__c) ? '' : accountToUpdate.Service_call__c ;
                accountToUpdate.Sales_meeting__c = String.isBlank(accountToUpdate.Sales_meeting__c) ? '' : accountToUpdate.Sales_meeting__c ;
                update accountToUpdate;
            }
            Account acc = [Select Id,Name,Phone,Lead__c,Legal_assistance__c,Service_call__c,Sales_meeting__c,Meeting_Type__c,Send_SMS_Reminders__c FROM Account WHERE Id =: accountToUpdate.Id];

            accountRelatedJournal = [SELECT Id,Name FROM Journal__c WHERE Account__c =: acc.Id ORDER BY CreatedDate desc LIMIT 1];

            if (eventToCreate != null) {
                List<string> datetimeVals = inputStartdate.split('T');
                List<string> dateOnly = datetimeVals[0].split('-');
                List<string> timeOnly = startHours.split(':');
                eventToCreate.StartDateTime = Datetime.newInstance(Integer.valueOf( dateOnly[0]), Integer.valueOf(dateOnly[1]), Integer.valueOf(dateOnly[2]), Integer.valueOf(timeOnly[0]), Integer.valueOf(timeOnly[1]) , 0);
                eventToCreate.EndDateTime = eventToCreate.StartDateTime.addMinutes(timeDuration);
                eventToCreate.Account__c =  accountId;
                eventToCreate.WhatId =  accountId;
                eventToCreate.Lead__c = acc.Lead__c;
                if (!accountRelatedJournal.isEmpty()) {
                    eventToCreate.Journal__c = accountRelatedJournal[0].Id;
                }
                eventToCreate.Name_Text__c = acc.Name;
                eventToCreate.Phone_Text__c = acc.Phone;
                eventToCreate.SMS_Reminders_New__c = acc.Send_SMS_Reminders__c;
                eventToCreate.Subject = 'Call with '+ acc.name + ' (Account: '+ (String.isBlank(acc.Legal_assistance__c) ? (String.isBlank(acc.Service_call__c) ? (String.isBlank(acc.Sales_meeting__c) ? acc.Sales_meeting__c : acc.Sales_meeting__c )  : acc.Service_call__c ): acc.Legal_assistance__c) + ')';
                insert eventToCreate;
            }

            returnResponse.message = 'Event Info saved successfully';
            returnResponse.success = true;

            return returnResponse;
         } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}