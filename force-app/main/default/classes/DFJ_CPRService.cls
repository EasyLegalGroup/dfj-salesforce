/**
 * @description This class retrieves cpr data
 */
public with sharing class DFJ_CPRService {
    public static String cprUrl = 'https://gctp.cpr.dk/cpr-online-gctp/gctp';
    
    /**
     * @description Retrieves CPR data based on the provided CPR number and record ID.
     * @param recId String representing the record ID for storing the response data
     * @param cprNumber String representing the CPR number
     * @return DFJ_CPRService.CprResponseWrapper containing the CPR data response
     */
    @AuraEnabled
    public static DFJ_CPRService.CprResponseWrapper getCPRData(String recId, String cprNumber) {
        if (String.isBlank(cprNumber)) {
            return new DFJ_CPRService.CprResponseWrapper(); // Return an empty response if CPR number is blank
        }
        
        DFJ_CPRService.CprResponseWrapper responseWrapper = DFJ_CPRResponseService.callPNRApiService(
            DFJ_CPRTokenService.getCPRToken(), cprNumber);
        
        insertCprData(recId, responseWrapper, cprNumber);
        return responseWrapper;
    }
    
    /**
     * @description Inserts the retrieved CPR data into the Identity_Check__c object.
     * @param recId String representing the record ID for the CPR data
     * @param responseWrapper DFJ_CPRService.CprResponseWrapper containing the CPR data
     * @param cprNumber String representing the CPR number for reference
     */
    public static void insertCprData(String recId, DFJ_CPRService.CprResponseWrapper responseWrapper, String cprNumber) {
        try {
            Identity_Check__c record = createIdentityCheckRecord(recId, responseWrapper, cprNumber);
            if (record != null) {
                insert new List<Identity_Check__c>{ record };
            }
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Process DFJ_CPRService', ex.getMessage(), 'Error', 'DFJ_CPRService.insertCprData', '', String.valueOf(ex.getLineNumber()));
        }
    }
    
    private static Identity_Check__c createIdentityCheckRecord(String recId, DFJ_CPRService.CprResponseWrapper responseWrapper, String cprNumber) {
        Identity_Check__c record = new Identity_Check__c();
        record.Record_Id__c = String.isNotBlank(recId) ? recId : null; // Avoid empty string if recId is not valid
        record.Region__c = responseWrapper.city;
        record.Gender__c = responseWrapper.gender;
        record.National_Identification_Number__c = cprNumber;
        record.Name__c = responseWrapper.name;
        record.CreatedById = UserInfo.getUserId();
        record.Outcome__c = responseWrapper.statusCode == '200' ? 'Success' : 'Error';
        record.Address__PostalCode__s = responseWrapper.postalCode;
        record.Address__City__s = responseWrapper.city;
        record.Address__Street__s = responseWrapper.address;
        record.Time_of_Check__c = System.now();
        record.Error_Message__c = responseWrapper.errorMessage;
        
        return record;
    }
    /**
     * @description Inner class to wrap the CPR response data
     */
    public class CprResponseWrapper {
        @AuraEnabled public String statusCode;
        @AuraEnabled public String name;
        @AuraEnabled public String gender;
        @AuraEnabled public String city;
        @AuraEnabled public String address;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String errorMessage;
        public String token;
    }
}