public with sharing class DFJ_AppointmentService_Apex {
    @AuraEnabled
    public static AppointmentSetupWrapper getAppointmentConfigurations(){
        AppointmentSetupWrapper accountAppointmentWrapper = new AppointmentSetupWrapper();
        accountAppointmentWrapper.sendSMSReminderOptions = getAllPicklistValues_Apex('Account','Send_SMS_Reminders__c');
        accountAppointmentWrapper.meetingTypeOptions = getAllPicklistValues_Apex('Account','Meeting_Type__c');
        accountAppointmentWrapper.salesMeetingOptions = getAllPicklistValues_Apex('Account','Sales_meeting__c');
        accountAppointmentWrapper.serviceCallOptions = getAllPicklistValues_Apex('Account','Service_call__c');
        accountAppointmentWrapper.legalAssistanceOptions = getAllPicklistValues_Apex('Account','Legal_assistance__c');
        accountAppointmentWrapper.UserList = getUsers();
        return accountAppointmentWrapper;
    }

    public static List<PicklistOptions> getAllPicklistValues_Apex(String objectApiName, String fieldApiName){
        List<PicklistOptions> picklistOptionList = new List<PicklistOptions>();
        try {
            Schema.SObjectType obj_describe = Schema.getGlobalDescribe().get(objectApiName) ;
            Schema.DescribeSObjectResult obj_describe_result = obj_describe.getDescribe() ;
            Map<String,Schema.SObjectField> fields = obj_describe_result.fields.getMap() ;
            Schema.DescribeFieldResult fieldResult = fields.get(fieldApiName).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            PicklistOptions option = null;
            for (Schema.PicklistEntry pickListVal : ple) {
                option = new PicklistOptions(pickListVal.getLabel(), pickListVal.getValue());
                picklistOptionList.add(option);
            }
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Getting all picklist options.', ex.getMessage(), 'Error', 'DFJ_AppointmentService_Apex.GetAllPicklistValues_Apex', String.valueOf(ex.getLineNumber()));
        }
        return picklistOptionList;
    }
    @AuraEnabled
    public static List<User> getUsers() {
        List<User> userList = new List<User>();
        
        // Query and populate the userList with user data
        List<User> users = [SELECT Id, Name FROM User where IsActive = true];
        for (User user : users) {
            userList.add(user);
        }
        
        return userList;
    }

    public class AppointmentSetupWrapper {
        @AuraEnabled public List<PicklistOptions> sendSMSReminderOptions;
        @AuraEnabled public List<PicklistOptions> meetingTypeOptions;
        @AuraEnabled public List<PicklistOptions> salesMeetingOptions;
        @AuraEnabled public List<PicklistOptions> serviceCallOptions;
        @AuraEnabled public List<PicklistOptions> legalAssistanceOptions;
        @AuraEnabled public List<User> UserList;

        public AppointmentSetupWrapper() {
        this.sendSMSReminderOptions = new List<PicklistOptions>();
        this.meetingTypeOptions = new List<PicklistOptions>();
        this.salesMeetingOptions = new List<PicklistOptions>();
        this.serviceCallOptions = new List<PicklistOptions>();
        this.legalAssistanceOptions = new List<PicklistOptions>();
        this.UserList = new List<User>();
        }
    }

    public class PicklistOptions {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        
        public PicklistOptions(String label, String val) {
            this.label = label;
            this.value = val;
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String message;
    }
}