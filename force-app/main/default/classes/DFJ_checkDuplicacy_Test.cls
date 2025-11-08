/**
 * Created by Shubham Sharma on 03-07-2019.
 */
@isTest
public with sharing class DFJ_checkDuplicacy_Test {

    @isTest
    private static void duplicayCheck(){
        Lead leadInstance = new Lead();
        leadInstance.FirstName = 'TestLead';
        leadInstance.LastName= 'Test Last Name';
        leadInstance.Company = 'Test Company';
        leadInstance.Provider_id__c = '1122';
        leadInstance.Phone='1122334455';
        leadInstance.Phone2__c='1122334455';
        leadInstance.Phone3__c='1122334455';
        leadInstance.Publisher_name__c='Facebook';
        insert leadInstance;

        Lead leadInstance1 = new Lead();
        leadInstance1.FirstName = 'TestLead';
        leadInstance1.LastName= 'Test Last Name';
        leadInstance1.Company = 'Test Company';
        leadInstance1.Provider_id__c = '11221';
        leadInstance1.Phone='1122334455';
        leadInstance.Phone2__c='112233442';
        leadInstance.Phone3__c='1122333';
        leadInstance1.Publisher_name__c='Facebook';
        insert leadInstance1;
    }

}