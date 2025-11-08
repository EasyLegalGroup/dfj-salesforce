@isTest
public with sharing class DFJ_EventController_Test {
    @isTest
    private static void getAllEventethod_Test(){
        String accData ='{"Name":"Test","Send_SMS_Reminders__c":"No","Meeting_Type__c":"Sales meeting","Sales_meeting__c":"Ring igen"}';
        Account acc = (Account) JSON.deserialize(accData, Account.class);
        insert acc;

        String evtData = '{"EndDateTime":"2023-06-28T17:58:00.000Z","StartDateTime":"2023-06-28T16:58:00.000Z","Subject":"asas","Journal__c":"","OwnerId":"'+UserInfo.getUserId()+'","WhatId":"'+acc.Id +'","Account__c":"'+acc.Id +'"}';
        Event evt = (Event) JSON.deserialize(evtData, Event.class);
        insert evt;

        Test.startTest();
        DFJ_EventController.getAllEventethod(UserInfo.getUserId(), null, UserInfo.getUserId());
        Test.stopTest();
    }

    @isTest
    private static void getAllRelatedEvents_Test(){
        String accData ='{"Name":"Test","Send_SMS_Reminders__c":"No","Meeting_Type__c":"Sales meeting","Sales_meeting__c":"Ring igen"}';
        Account acc = (Account) JSON.deserialize(accData, Account.class);
        insert acc;

        String evtData = '{"EndDateTime":"2023-06-28T17:58:00.000Z","StartDateTime":"2023-06-28T16:58:00.000Z","Subject":"asas","Journal__c":"","OwnerId":"'+UserInfo.getUserId()+'","WhatId":"'+acc.Id +'","Account__c":"'+acc.Id +'"}';
        Event evt = (Event) JSON.deserialize(evtData, Event.class);
        insert evt;

        Test.startTest();
        DFJ_EventController.getAllRelatedEvents(Datetime.newInstance(2023, 06, 28, 16, 58, 0) ,UserInfo.getUserId());
        Test.stopTest();
    }
}