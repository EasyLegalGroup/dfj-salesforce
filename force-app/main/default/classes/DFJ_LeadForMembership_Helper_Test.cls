@isTest
public with sharing class DFJ_LeadForMembership_Helper_Test {
    @isTest
    static void basicTestwithAccount() {
        List<Lead> leadIns = DFJ_TestDataFactory.CreateLeadWithHarAccepteFied(1);
        Test.startTest();
        DFJ_LeadForMembership_Helper.CreateMembership_Apex(leadIns);
        Test.stopTest();
        Membership__c member = [Select Id,Last_Name__c,First_Name__c,Lead__c FROM Membership__c Where Lead__c =: leadIns[0].Id Limit 1];
        System.assertEquals(leadIns[0].Id, member.Lead__c);
    }

    @isTest
    static void createMembershipBySendingEmpty() {
        Test.startTest();
        Boolean success = DFJ_LeadForMembership_Helper.CreateMembership_Apex(null);
        Test.stopTest();
        System.assertEquals(false, success);
    }
}