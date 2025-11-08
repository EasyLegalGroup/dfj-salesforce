@isTest
public with sharing class PS_SalesDocumentHelper_Test {
     @isTest
    private static void SalesDocumentMethodWithoutRecId(){
        Test.startTest();
        String result = PS_SalesDocumentHelper.CreateSalesDocumentAndDeleteDraft_Apex('');
        Test.stopTest();
        System.assertEquals('Error, Something went wrong.', result);
    }
   /* @isTest
    private static void SalesDocumentMethodWithoutRecId(){
        String recordId = '';
        Test.startTest();
        String result = PS_SalesDocumentHelper.CreateSalesDocumentAndDeleteDraft_Apex(recordId);
        Test.stopTest();
        System.assertEquals('Error, Got recordId empty.', result);
    }

    @isTest
    private static void SalesDocumentMethodWithWrongRecId(){
        Test.startTest();
        String result = PS_SalesDocumentHelper.CreateSalesDocumentAndDeleteDraft_Apex('asHjsu7Kjs8sa');
        String result1 = PS_SalesDocumentHelper.CreateSalesDocumentAndDeleteDraft_Apex('00Q1q000006OcmAEAS');
        Test.stopTest();
        System.assertEquals('Error, Lead not found.', result1);
        System.assertEquals('Error, Something went wrong.', result);
    }

    @isTest
    private static void SalesDocumentMethodWithRecId(){
        List<Lead> leadList = DFJ_TestDataFactory.CreateLeadWithSalesDocument(1, 1,1);
        Test.startTest();
        String result = PS_SalesDocumentHelper.CreateSalesDocumentAndDeleteDraft_Apex(leadList[0].Id);
        Test.stopTest();
        List<bt_stripe__Sales_Document__c> salesDocumentList = [Select Id FROM bt_stripe__Sales_Document__c LIMIT 10000];
        List<bt_stripe__Line_Item__c> listItemList = [Select Id FROM bt_stripe__Line_Item__c LIMIT 10000];
        System.assertEquals(1, salesDocumentList.size());
        System.assertEquals(0, listItemList.size());
    }

    @isTest
    private static void SalesDocumentMethodWithRecIdAndleadProduct(){
        List<Lead> leadList = DFJ_TestDataFactory.CreateLeadWithLeadProduct(1,1);
        Test.startTest();
        String result = PS_SalesDocumentHelper.CreateSalesDocumentAndDeleteDraft_Apex(leadList[0].Id);
        Test.stopTest();
        List<bt_stripe__Sales_Document__c> salesDocumentList = [Select Id FROM bt_stripe__Sales_Document__c LIMIT 10000];
        List<bt_stripe__Line_Item__c> listItemList = [Select Id FROM bt_stripe__Line_Item__c LIMIT 10000];
        System.assertEquals(1, salesDocumentList.size());
        System.assertEquals(1, listItemList.size());
    }

    @isTest
    private static void SalesDocumentMethodNegativeResults(){
        Test.startTest();
        String result = PS_Utility.QueryToFetchLeads('asdf','');
        String result1 = PS_Utility.FetchLeadQuery(new List<String>(),'','');
        String result2 = PS_Utility.FetchLeadQuery(null,'','');
        String result3 = PS_Utility.QueryToFetchSalesDocument('asdf','');
        String result4 = PS_Utility.FetchSalesDocumentQuery(null,'','');
        String result5 = PS_Utility.FetchSalesDocumentQuery(new List<String>(),'','');
        String result6 = PS_Utility.QueryToFetchLeadProducts('asdf','');
        String result7 = PS_Utility.FetchLeadProductsQuery(new List<String>(),'','');
        String result8 = PS_Utility.FetchLeadProductsQuery(null,'','');
        Test.stopTest();
        System.assertEquals(null, result);
        System.assertEquals(null, result1);
        System.assertEquals(null, result2);
        System.assertEquals(null, result3);
        System.assertEquals(null, result4);
        System.assertEquals(null, result5);
        System.assertEquals(null, result6);
        System.assertEquals(null, result7);
        System.assertEquals(null, result8);
    }*/
}