@isTest
public with sharing class DFJ_AppointmentController_Test {
    @isTest
    private static void getAppointmentConfigurations_Test(){
        Test.startTest();
        DFJ_AppointmentController_Apex.getAppointmentConfigurations();
        Test.stopTest();
    }

    @isTest
    private static void saveAccountAndEventInformation_Test(){
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;
        
        String evtData = '{"StartDateTime":"2023-06-29T18:58:00.000Z","Subject":"asas","Journal__c":"","OwnerId":"0051t000002kYspAAE","WhatId":"","EndDateTime":"","Account__c":""}';
        String accData ='{"Id":"'+acc.Id +'","Send_SMS_Reminders__c":"No","Meeting_Type__c":"Sales meeting","Legal_assistance__c":"","Service_call__c":"","Sales_meeting__c":"Ring igen"}';
        Test.startTest();
        DFJ_AppointmentController_Apex.saveAccountAndEventInformation(accData,evtData, acc.Id, 20, '2023-06-29T18:58:00.000Z','00:45:00.000','2023-07-06');
        Test.stopTest();
    }

}