/**
 * @description This Apex class DFJ_ChatComponent_Apex is responsible for handling chat-related operations and interactions within Salesforce.
 * It includes methods to retrieve SMS records, fetch send-to options, and render email templates.
 * This class also contains a nested SMSDetailsWrapper class for managing SMS details.
 *
 * @innerClass SMSDetailsWrapper
 *   - This inner class holds details related to SMS, including a list of SMS records, send-to option value, and the sObjectName where the component is placed.
 */
public with sharing class DFJ_ChatComponent_Apex {

    private static final String outgoingSmsDirection = 'Outgoing';
    private static final String outgoingSmsType = 'Custom';
    private static final String outgoingSmsStatus = 'Pending';

    // SMSDetailsWrapper class which includes required SMS related details.
    public class SMSDetailsWrapper {
        @AuraEnabled public List<SMS__c> smsRecords { get; set; }
        @AuraEnabled public String sendToOptionDefaultValue { get; set; }

        @AuraEnabled public String sendFromPhoneNumber { get; set; }
        @AuraEnabled public String alphanumericSenderId { get; set; }

        // sObjectName on whose record page the component is placed
        @AuraEnabled public String sObjectName { get; set; }

        @AuraEnabled public Map<String,String> sendToOptionLabelsAndValues { get; set; }
        
        @AuraEnabled public String marketUnit { get; set; }
        @AuraEnabled public String countryIsoCode { get; set; }
        
        @AuraEnabled public Boolean isPersonAccount { get; set; }
        @AuraEnabled public String personContactId { get; set; }
    }

    /**
     * @description Used to get SMS details for the LWC Component.
     * @param recordId Record ID of the sObject.
     * @param fieldName fieldName whose value will be used in SendTo dropdown in the LWC Component..
     * @return Returns an instance of SMSDetailsWrapper class.
     */
    @AuraEnabled(Cacheable=true)
    public static SMSDetailsWrapper getSMSDetails(String recordId, String fieldName) {
        try {
            SMSDetailsWrapper smsDetails = new SMSDetailsWrapper();

            String sObjectName = getSobjectTypeFromRecordId_Apex(Id.valueOf(recordId));
            smsDetails.sObjectName = sObjectName;

            // Check if this is a PersonAccount
            if (sObjectName == 'Account') {
                try {
                    String personQuery = 'SELECT Id, IsPersonAccount, PersonContactId FROM Account WHERE Id = \'' + recordId + '\' LIMIT 1';
                    List<SObject> accountRecords = Database.query(personQuery);
                    if (!accountRecords.isEmpty()) {
                        Boolean isPersonAccount = (Boolean) accountRecords[0].get('IsPersonAccount');
                        if (isPersonAccount != null && isPersonAccount) {
                            smsDetails.isPersonAccount = true;
                            Object personContactIdObj = accountRecords[0].get('PersonContactId');
                            if (personContactIdObj != null) {
                                smsDetails.personContactId = String.valueOf(personContactIdObj);
                            }
                        }
                    }
                } catch (Exception personEx) {
                    // Not a PersonAccount or fields not available
                    smsDetails.isPersonAccount = false;
                }
            }

            List<SMS__c> smsRecords = getSMSRecords(recordId, sObjectName);
            smsDetails.smsRecords = smsRecords;

            String currencyIsoCode = getCurrencyIsoCode(recordId, sObjectName);
            smsDetails.countryIsoCode = currencyIsoCode;

            // Get Market Unit from the record
            String marketUnit = getMarketUnit(recordId, sObjectName);
            smsDetails.marketUnit = marketUnit;

            // Set phone number based on Market Unit
            if (marketUnit == 'DFJ_DK') {
                smsDetails.sendFromPhoneNumber = '+45 30812521';
            } else if (marketUnit == 'FA_SE') {
                smsDetails.sendFromPhoneNumber = '+46 765106079';
            } else if (marketUnit == 'Ireland') {
                smsDetails.sendFromPhoneNumber = 'N/A';
            } else {
                // Fallback to old logic if market unit doesn't match
                Send_From_Number_Based_On_Currency__mdt record = Send_From_Number_Based_On_Currency__mdt.getInstance(currencyIsoCode);
                smsDetails.sendFromPhoneNumber = record != null ? record.Phone_Number__c : null;
            }

            smsDetails.alphanumericSenderId = System.Label.Alphanumeric_SenderId_Used_For_SMS;

            Map<String,String> sendToOptionsLabelAndValues = getSendToOptionValues(recordId, sObjectName);
            smsDetails.sendToOptionLabelsAndValues = sendToOptionsLabelAndValues;

            String sendToOptionDefaultValue = getSendToOptionDefaultValue(recordId, sObjectName, fieldName);
            smsDetails.sendToOptionDefaultValue = sendToOptionDefaultValue;

            return smsDetails;
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Get SMS Details', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.getSMSDetails', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }

    /**
     * @description Method to get Send to option values.
     * @param recordId Record ID of the sObject.
     * @param sObjectName SObject type name.
     * @return Returns a map of label and values.
     */
    public static Map<String,String> getSendToOptionValues(String recordId, String sObjectName) {

        try {
            // get all the field names from the sObject whose type is 'Phone'
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();

            Map<String, String> sendToOptionsLabelAndName = new Map<String, String>();

            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
                if (field.getType() == Schema.DisplayType.PHONE) {
                    sendToOptionsLabelAndName.put(field.getLabel(), field.getName());
                }
            }

            // create a map of label and values
            Map<String, String> sendToOptionsLabelAndValues = new Map<String, String>();

            // get values of all the field names from the sObject whose type is 'Phone'
            List<SObject> sObjects = Database.query('SELECT ' + String.join(new List<String>(sendToOptionsLabelAndName.values()), ',') + ' FROM ' + sObjectName + ' WHERE Id = :recordId');
            for (SObject sObjectRecord : sObjects) {
                for (String fieldLabel : sendToOptionsLabelAndName.keySet()) {
                    sendToOptionsLabelAndValues.put(fieldLabel, String.valueOf(sObjectRecord.get(sendToOptionsLabelAndName.get(fieldLabel))));
                }
            }

            return sendToOptionsLabelAndValues;
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Get Send To Option Values', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.getSendToOptionValues', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }


    /**
     * @description Method to get SObject type name from given recordId.
     * @param recordId Record ID of the sObject.
     * @return Returns the SObject type name.
     */
    public static String getSobjectTypeFromRecordId_Apex(Id recordId) {
        try {
            Schema.SObjectType sObjType = recordId.getSobjectType();
            Schema.DescribeSObjectResult sObjDescribeResult = sObjType.getDescribe();
            return sObjDescribeResult.getName();
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Get Sobject Type Name From RecordId.', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.getSobjectTypeFromRecordId_Apex', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }


    /**
     * @description Method to get SMS records for the given recordId and sObjectName.
     * @param recordId Record ID of the sObject.
     * @param sObjectName SObject type name.
     * @return Returns a list of SMS__c records.
     */
    @AuraEnabled(Cacheable=false)
    public static List<SMS__c> getSMSRecords(String recordId, String sObjectName) {
        try {
            // Check if this is a PersonAccount by checking for PersonContactId field
            String personContactId = null;
            if (sObjectName == 'Account') {
                try {
                    String personQuery = 'SELECT Id, PersonContactId FROM Account WHERE Id = \'' + recordId + '\' AND IsPersonAccount = true LIMIT 1';
                    List<SObject> personAccountRecords = Database.query(personQuery);
                    if (!personAccountRecords.isEmpty() && personAccountRecords[0].get('PersonContactId') != null) {
                        personContactId = String.valueOf(personAccountRecords[0].get('PersonContactId'));
                    }
                } catch (Exception personEx) {
                    // Not a PersonAccount or PersonContactId not available, continue with normal query
                }
            }
            
            // Build query with PersonContactId condition if applicable
            String query = 'SELECT Id, ' +
                    'Message__c, ' +
                    'Direction__c, ' +
                    'CreatedDate, ' +
                    'To_Phone__c, ' +
                    'From_Phone__c, ' +
                    'Is_Read__c ' +
                    'FROM SMS__c ' +
                    'WHERE Record_ID__c =\'' + recordId + '\' ';
            
            if (String.isNotBlank(personContactId)) {
                query += 'OR Record_ID__c =\'' + personContactId + '\' ';
            }
            
            query += 'ORDER BY CreatedDate';
            
            List<SMS__c> smsRecords = Database.query(query);
            return smsRecords;
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Get SMS Records', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.getSMSRecords', '', String.valueOf(e.getLineNumber()));
            return new List<SMS__c>();
        }
    }

    /**
     * @description Method to get currency ISO code for the given recordId and sObjectName.
     * @param recordId Record ID of the sObject.
     * @param sObjectName SObject type name.
     * @return Returns the currency ISO code.
     */
    public static String getCurrencyIsoCode(String recordId, String sObjectName) {
        try {
            Object currencyIsoCode;
            String queryContent = 'SELECT Id,' +
                    '   CurrencyIsoCode' +
                    '   FROM' +
                    '   ' + sObjectName +
                    '   WHERE Id = \'' + recordId + '\'';
            List<SObject> record = Database.query(
                    queryContent
            );
            currencyIsoCode = record[0].get('CurrencyIsoCode');
            return String.valueOf(currencyIsoCode);
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', ' Get Currency Iso Code ', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.getValueOfMarketUnit', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }

    /**
     * @description Method to get Market Unit for the given recordId and sObjectName.
     * @param recordId Record ID of the sObject.
     * @param sObjectName SObject type name.
     * @return Returns the Market Unit value.
     */
    public static String getMarketUnit(String recordId, String sObjectName) {
        try {
            String queryContent = 'SELECT Id, Market_Unit__c FROM ' + sObjectName + ' WHERE Id = \'' + recordId + '\'';
            List<SObject> record = Database.query(queryContent);
            if (!record.isEmpty() && record[0].get('Market_Unit__c') != null) {
                return String.valueOf(record[0].get('Market_Unit__c'));
            }
            return null;
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Get Market Unit', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.getMarketUnit', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }

    /**
     * @description Retrieves the value of a specified field for a given sObject record, which will be used for the SendTo dropdown .
     * @param recordId The ID of the sObject record.
     * @param sObjectName The API name of the sObject type.
     * @param fieldName The name of the field whose value is to be retrieved.
     * @return Returns the value of the specified field as a String.
     */
    public static String getSendToOptionDefaultValue(String recordId, String sObjectName, String fieldName) {
        try {
            String queryContent = 'SELECT Id,' +
                    '   ' + fieldName +
                    '   FROM' +
                    '   ' + sObjectName +
                    '   WHERE Id = \'' + recordId + '\'';
            List<SObject> record = Database.query(queryContent);
            Object value = record[0].get(fieldName);
            return String.valueOf(value);
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', ' Get Send To Option Value.', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.getSendToOptionValue', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }

    /**
     * @description Renders and returns the body of the specified email template.
     * @param emailTemplateId The ID of the email template to render.
     * @param recordId The ID of that record which will be used to populate merge fields if there are any. .
     * @return Returns the rendered email template body as a String.
     */
    @AuraEnabled(Cacheable=true)
    public static String getRenderedEmailTemplate(Id emailTemplateId, Id recordId) {
        try {
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplateId, recordId, recordId);
            String renderedBody = email.getPlainTextBody();
            return (renderedBody != null) ? renderedBody : '';
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('Get Rendered Email Template', '', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.getRenderedEmailTemplate', '', String.valueOf(e.getLineNumber()));
            return '';
        }
    }

    /**
     * @description Creates an outgoing SMS by invoking the AL_Create_Outbound_SMS flow.
     * @param recordId The ID of the record which will be used as the related record.
     * @param relatedRecordIdField The field name to use for getting the related record ID (e.g., 'Id', 'Account__c').
     * @param sendFromSelection The user's selection from the dropdown (phone number or 'FamJurist').
     * @param toIdentifier The value to be populated in the To Number field of the SMS record.
     * @param message The value to be populated in the Message field of the SMS record.
     * @param marketUnit The market unit value from the record.
     * @param countryIsoCode The country ISO code for phone normalization.
     * @return Returns the status of the flow execution as a String (Success or Failure).
     */
    @AuraEnabled
public static String createOutgoingSMSRecord(
    String recordId,
    String relatedRecordIdField,
    String sendFromSelection,
    String toIdentifier,
    String message,
    String marketUnit,
    String countryIsoCode
) {
    try {
        if (String.isBlank(recordId)) return 'Failure: recordId is required';

        String sObjectName = getSobjectTypeFromRecordId_Apex(Id.valueOf(recordId));

        // Derive the related record Id
        String relatedRecordId;
        if (String.isBlank(relatedRecordIdField) || relatedRecordIdField == 'Id') {
            relatedRecordId = recordId;
        } else {
            relatedRecordId = getFieldValue(recordId, sObjectName, relatedRecordIdField);
        }

        // Person Account safety: prefer the PersonContactId so the Flow gets a Contact/Lead Id
        if (sObjectName == 'Account' && (String.isBlank(relatedRecordIdField) || relatedRecordIdField == 'Id')) {
            try {
                Account a = [SELECT IsPersonAccount, PersonContactId FROM Account WHERE Id = :recordId LIMIT 1];
                if (a.IsPersonAccount && a.PersonContactId != null) {
                    relatedRecordId = String.valueOf(a.PersonContactId);
                }
            } catch (Exception ignore) {}
        }

        if (String.isBlank(relatedRecordId)) {
            relatedRecordId = recordId; // final fallback
        }

        // Normalize phone (DKK->DK, SEK->SE, EUR/Ireland->IE already handled inside)
        String normalizedToNumber = normalizePhoneNumber(toIdentifier, countryIsoCode);

        // Map SendFrom to Flow’s expected values
        String sendFromValue = (sendFromSelection == 'FamJurist' ||
                               (sendFromSelection != null && sendFromSelection.equalsIgnoreCase(System.Label.Alphanumeric_SenderId_Used_For_SMS)))
                               ? 'Alphanumeric Sender ID' : 'Short/Long Code';

        // Build Flow inputs. Send both "RelatedRecordId" and "RecordId" to cover naming differences.
        Map<String, Object> flowInputs = new Map<String, Object>{
            'ToNumber'        => normalizedToNumber,
            'MarketUnit'      => marketUnit,
            'RelatedRecordId' => relatedRecordId,
            'RecordId'        => relatedRecordId, // <-- extra alias, harmless if Flow doesn’t have it
            'SendFrom'        => sendFromValue,
            'Type'            => 'Custom',
            'Message'         => message
        };

        Flow.Interview.AL_Create_Outbound_SMS flow = new Flow.Interview.AL_Create_Outbound_SMS(flowInputs);
        flow.start();

        Boolean isSuccess  = (Boolean) flow.getVariableValue('IsSuccess');
        String  customError = (String)  flow.getVariableValue('CustomError');

        return (isSuccess == true) ? 'Success'
            : 'Failure: ' + (String.isNotBlank(customError) ? customError : 'Unknown error from flow');
    } catch (Exception e) {
        DFJ_ErrorLogController.addErrorLogs('', 'Create SMS Record via Flow', e.getMessage(), 'Error',
            'DFJ_ChatComponent_Apex.createOutgoingSMSRecord', '', String.valueOf(e.getLineNumber()));
        return 'Failure: Error Message: ' + e.getMessage();
    }
}

    
    /**
     * @description Normalizes a phone number using the McPhone utility class.
     * @param phoneNumber The raw phone number to normalize.
     * @param countryIsoCode The country ISO code (DK, SE, IE, etc.).
     * @return Returns the normalized phone number.
     */
    private static String normalizePhoneNumber(String phoneNumber, String countryIsoCode) {
        if (String.isBlank(phoneNumber)) {
            return phoneNumber;
        }
        
        // Map currency codes to country codes if needed
        String countryCode = countryIsoCode;
        if (countryIsoCode == 'DKK') {
            countryCode = 'DK';
        } else if (countryIsoCode == 'SEK') {
            countryCode = 'SE';
        } else if (countryIsoCode == 'EUR' || countryIsoCode == 'Ireland') {
            countryCode = 'IE';
        }
        
        McPhone.Norm normalized = McPhone.normalize(phoneNumber, countryCode);
        return normalized.digits;
    }
    
    /**
     * @description Gets the value of a specified field from a record.
     * @param recordId The ID of the record.
     * @param sObjectName The API name of the sObject type.
     * @param fieldName The name of the field to retrieve.
     * @return Returns the field value as a String, or null if field doesn't exist or has no value.
     */
    @AuraEnabled(Cacheable=false)
    public static String getFieldValue(String recordId, String sObjectName, String fieldName) {
        try {
            // Fast path: "Id" or blank -> just return the recordId
            if (String.isBlank(fieldName) || fieldName == 'Id') {
                return recordId;
            }
    
            String escapedRecordId   = String.escapeSingleQuotes(recordId);
            String escapedFieldName  = String.escapeSingleQuotes(fieldName);
            // Only select the requested field (no duplicate Id column)
            String soql = 'SELECT ' + escapedFieldName + ' FROM ' + sObjectName + 
                          ' WHERE Id = \'' + escapedRecordId + '\' LIMIT 1';
    
            List<SObject> rows = Database.query(soql);
            if (!rows.isEmpty()) {
                Object val = rows[0].get(fieldName);
                return (val != null) ? String.valueOf(val) : null;
            }
            return null;
        } catch (Exception e) {
            System.debug('getFieldValue error for ' + fieldName + ' on ' + sObjectName + ': ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Retrieves a list of email templates filtered by folder name.
     * @return Returns a list of EmailTemplate records which match the folder name specified in the Folder_Name_For_SMS_Email_Template custom label.
     */
    @AuraEnabled(Cacheable=true)
    public static List<EmailTemplate> getEmailTemplatesByFolderName() {
        try {
            String folderName = System.Label.Folder_Name_For_SMS_Email_Template;

            if (folderName == null) {
                folderName = '%';
            }

            return [
                    SELECT Id, Name, Body
                    FROM EmailTemplate
                    WHERE
                            Folder.Name LIKE :folderName
                    ORDER BY Name
            ];
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', ' Get email templates by folder name.', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.getEmailTemplatesByFolderName', '', String.valueOf(e.getLineNumber()));
            return new List<EmailTemplate>();
        }
    }
    
    /**
     * @description Retrieves the customer name from a specified field.
     * @param recordId The ID of the record.
     * @param sObjectName The API name of the sObject type.
     * @param fieldName The name of the field to retrieve (defaults to 'Name').
     * @return Returns the customer name as a String.
     */
    @AuraEnabled(Cacheable=true)
    public static String getCustomerName(String recordId, String sObjectName, String fieldName) {
        try {
            if (String.isBlank(fieldName)) {
                fieldName = 'Name';
            }
            String queryContent = 'SELECT Id, ' + fieldName + ' FROM ' + sObjectName + ' WHERE Id = \'' + recordId + '\'';
            List<SObject> record = Database.query(queryContent);
            if (!record.isEmpty() && record[0].get(fieldName) != null) {
                return String.valueOf(record[0].get(fieldName));
            }
            return 'Customer';
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Get Customer Name', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.getCustomerName', '', String.valueOf(e.getLineNumber()));
            return 'Customer';
        }
    }
    
    /**
     * @description Marks SMS records as read by setting Is_Read__c to true.
     * @param smsIds List of SMS record IDs to mark as read.
     * @return Returns 'Success' or error message.
     */
    @AuraEnabled
    public static String markSMSAsRead(List<String> smsIds) {
        try {
            if (smsIds == null || smsIds.isEmpty()) {
                return 'Success'; // Nothing to update
            }
            
            List<SMS__c> smsToUpdate = new List<SMS__c>();
            for (String smsId : smsIds) {
                smsToUpdate.add(new SMS__c(
                    Id = smsId,
                    Is_Read__c = true
                ));
            }
            
            if (!smsToUpdate.isEmpty()) {
                update smsToUpdate;
            }
            
            return 'Success';
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('', 'Mark SMS As Read', e.getMessage(), 'Error', 'DFJ_ChatComponent_Apex.markSMSAsRead', '', String.valueOf(e.getLineNumber()));
            return 'Error: ' + e.getMessage();
        }
    }
    
    /**
     * @description Normalizes a phone number using McPhone utility.
     * @param phoneNumber The phone number to normalize.
     * @param countryIsoCode The country ISO code (DK, SE, IE, etc.).
     * @return Returns the normalized phone number.
     */
    @AuraEnabled(Cacheable=true)
    public static String normalizePhoneNumberForDisplay(String phoneNumber, String countryIsoCode) {
        try {
            if (String.isBlank(phoneNumber)) {
                return phoneNumber;
            }
            
            // Map currency codes to country codes if needed
            String countryCode = countryIsoCode;
            if (countryIsoCode == 'DKK') {
                countryCode = 'DK';
            } else if (countryIsoCode == 'SEK') {
                countryCode = 'SE';
            } else if (countryIsoCode == 'EUR' || countryIsoCode == 'Ireland') {
                countryCode = 'IE';
            }
            
            McPhone.Norm normalized = McPhone.normalize(phoneNumber, countryCode);
            return normalized.digits;
        } catch (Exception e) {
            // If normalization fails, return original number
            return phoneNumber;
        }
    }
}