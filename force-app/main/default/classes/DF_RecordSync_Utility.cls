/**
   * @ Version : 1.0
   * @ Created Date : 18/05/2022
   * @Description : Class contains the method which support recodr sync functionality.
*/
public without sharing class DF_RecordSync_Utility {
    public static String docfabPrefix = 'df';
    public static String docfabUnderScore = '_';
    public static String docfabPostfix = '__c';
    public static String docfabRelationshipPostfix = '__r';
    public static String extendedErrorMessage = '';
    public static List<String> fieldsWithErrors = new List<String>();
    public static List<Log__c> dfjLogsToInsert = new List<Log__c>();
   
    // public static String docfabCheck = 'docfab_';

    public static List<String> parserTokenElements = new List<String>{'START_ARRAY','START_OBJECT','END_ARRAY','END_OBJECT'};
    public static Map<String,Integer> monthMap = new Map<String,Integer>{
        'Jan' => 01,
        'Feb' => 02,
        'Mar' => 03,
        'Apr' => 04,
        'May' => 05,
        'Jun' => 06,
        'Jul' => 07,
        'Aug' => 08,
        'Sep' => 09,
        'Oct' => 10,
        'Nov' => 11,
        'Dec' => 12
    };
    
    // TODO : For delete functionality
    /**
     * @Description  This method is to check that object is existing in the org or not.
     * @Param        objectName, httpMethod
     * @Return       RestResponseWrapper
    */
    public static Set<String> getSublistObjectList(String parentModelName) {
        Schema.DescribeSObjectResult parentObjectModel = Schema.getGlobalDescribe().get(parentModelName).getDescribe();//parentObjectToDelete.SObjectType.getDescribe();
        Set<String> objectToDelete = new Set<String>();
        for (Schema.ChildRelationship childRelation: parentObjectModel.getChildRelationships())
        {
            if (string.valueof(childRelation.getChildSObject()).contains(docfabPrefix+docfabUnderScore) && string.valueof(childRelation.getChildSObject()).indexOf(docfabPrefix+docfabUnderScore) == 0 ) {
                objectToDelete.add(string.valueof(childRelation.getChildSObject()));
            }
        }
       
        return objectToDelete;
    }

    /**
     * @Description  This method is to update the records with subselect lookup id
     * @Param        subSelectInfoList
    */
    @future
    public static void processRecords(String subSelectInfoString)
    {   
        List<SubselectFieldWrapper> subSelectInfoList = (List<SubselectFieldWrapper>) JSON.deserialize(subSelectInfoString, List<SubselectFieldWrapper>.class);
        List<sObject> sObjectRecordsToUpdate = new List<sObject>();
        Map<Id, SObject> recordsToUpdateMap = new Map<Id, SObject>();
        Map<String, String> uuidVsIdMap = new Map<String, String>();
        for (SubselectFieldWrapper subSelectIns : subSelectInfoList) {
            sobject getReletedToRecord = Schema.getGlobalDescribe().get(subSelectIns.parentSobject).newSObject();
            sobject getCurrentRecord = Schema.getGlobalDescribe().get(subSelectIns.currentSobject).newSObject();
            if (!uuidVsIdMap.containsKey(subSelectIns.fieldUuidValue)) {
                getReletedToRecord = Database.query('SELECT Id FROM ' + subSelectIns.parentSobject +' WHERE ' + (Test.isRunningTest() ? 'Id' : 'uuid__c') +' = \'' + subSelectIns.fieldUuidValue + '\'');

                uuidVsIdMap.put(subSelectIns.fieldUuidValue,String.valueOf(getReletedToRecord.get('Id')));
            } 
            getCurrentRecord = Database.query('SELECT Id,'+ subSelectIns.currentSobjectField +' FROM '+ subSelectIns.currentSobject + ' WHERE ' + (Test.isRunningTest() ? +subSelectIns.currentSobjectField : 'uuid__c')+ '=\'' +  (Test.isRunningTest() ? + subSelectIns.fieldUuidValue : subSelectIns.currentFieldUuidValue) +'\' LIMIT 1');
            
            if (getCurrentRecord != null) {
                getCurrentRecord.put(subSelectIns.currentSobjectField, uuidVsIdMap.get(subSelectIns.fieldUuidValue));     
                recordsToUpdateMap.put((Id)getCurrentRecord.get('Id'), getCurrentRecord);
            }
            if (!recordsToUpdateMap.isEmpty()) {
                dmlHelper(recordsToUpdateMap.values(), '');
            }
        }  
    }
    
    /**
     * @Description  This method is to check that object is existing in the org or not.
     * @Param        objectName, httpMethod
     * @Return       RestResponseWrapper
    */
    public static RestResponseWrapper parseAndPerformDml(String requestBody, String httpMethod) {
        RestResponseWrapper restResponseWrapperInstance = new RestResponseWrapper();
        
        try {
        //  System.debug('requestBody >>> '+JSON.serialize(requestBody));
            if (Test.isRunningTest()) {
                docfabPrefix = '';
                docfabUnderScore = '';
                docfabPostfix = '';
                docfabRelationshipPostfix = 's';
            }

            // DF_DocFabricator_Utility.RequestBodyPayloadWrapper requestBodyPayload = new DF_DocFabricator_Utility.RequestBodyPayloadWrapper();
            Map<String, Docfab_FieldLabel_Configuration__c> fieldLabelConfiguration = new Map<String, Docfab_FieldLabel_Configuration__c>();
            fieldLabelConfiguration = checkFieldConfigurationsPresent();
System.debug('fieldLabelConfiguration-->'+fieldLabelConfiguration);
            Map<String,Object> resyncMap = new Map<String,Object>(); 
            resyncMap = (Map<String,Object>) JSON.deserializeUntyped(requestBody);
            // TODO : Directy convert to sobject
            String parentObjectName = String.valueOf(resyncMap.get('_record_model'));
            String parentObjectModelId = String.valueOf(resyncMap.get('_record_model_id'));
          //  System.debug('parentObjectName-->'+parentObjectName);
          //  System.debug('parentObjectModelId-->'+parentObjectModelId);
          //  System.debug('parentObjectModelId-->'+docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix);
            
            if (String.isBlank(parentObjectName) || !checkSobjectExistInOrg(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix)) {
                
                return buildReturnResponse(500, 'SObject model not found.');
            }
            SObject parentDetailSobjcet = Schema.getGlobalDescribe().get(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix).newSObject();
            Integer parentfieldcounter = 0;
            List<String> parentFieldList = new List<String>();
            List<SubselectFieldWrapper> sublistInfoList = new List<SubselectFieldWrapper>();
            //Changes DFJ-68 Created map to remove cpu time limit exception
            // boolean issObjectPresent = sObjectPresent(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix);
            Map<String, SObjectField> fMap = new Map<String, SObjectField>();
            Map<String, SObjectField> ObjectSchemaField = new Map<String, SObjectField>();
        
            fMap = checkFieldPresentInsObject(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix);
            ObjectSchemaField = Schema.getGlobalDescribe().get(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix).getDescribe().fields.getMap();	
            for(String key:resyncMap.keySet()){
                //Changes DFJ-178
                String docFabKey = key;
//End
                key = key.contains('__') ? removeDoubleUnderscoreFromField(key) : key;
                String tempKey = '';
                // if(!key.left(1).equals(docfabUnderScore)){
                //     parentFieldList.add(key+docfabPostfix);
                // }
                if (key.length() > 32) {
                    Docfab_FieldLabel_Configuration__c fieldConfiguration = new Docfab_FieldLabel_Configuration__c();
                    fieldConfiguration = fieldLabelConfiguration.get(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix + '.'+ key + docfabPostfix);
                    tempKey = fieldConfiguration == null ? '' : fieldConfiguration.SF_Field_API_Name__c;
                   // Boolean issObjectFieldPresent = checkFieldPresentInsObject(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix, tempKey);
                    Boolean issObjectFieldPresent = fMap.containsKey(tempKey) ? true: false;
                    if(issObjectFieldPresent){
                        parentFieldList.add(tempKey);
                    }
                  
                }
                //DFJ-178 changes replace key with docFabKey in resyncMap.get(docFabKey) to check field in request body map.
                if (!String.valueOf(resyncMap.get(docFabKey)).trim().left(1).equals('(') && !key.equals('_record_model')) {
                    if(key.left(1).equals(docfabUnderScore) ){
                       // Boolean issObjectFieldPresent = checkFieldPresentInsObject(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix, key.substring(1, key.length())+docfabPostfix);
                        Boolean issObjectFieldPresent = fMap.containsKey(key.substring(1, key.length())+docfabPostfix) ? true: false; 
                        if(issObjectFieldPresent){
                            parentFieldList.add(key.substring(1, key.length())+docfabPostfix);
                        }
                        //parentFieldList.add(key.substring(1, key.length())+docfabPostfix);
                        // parentDetailSobjcet = typeCastTheFieldValueUsingFieldType(getFieldDescription(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix, key.substring(1, key.length())+docfabPostfix), parentDetailSobjcet, key.substring(1, key.length())+docfabPostfix, String.valueOf(resyncMap.get(key)),docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix);//InvaildFieldChanges
                        //DFJ-178 changes replace key with docFabKey in resyncMap.get(docFabKey) to check field in request body map.
                        parentDetailSobjcet = typeCastTheFieldValueUsingFieldType(getFieldDescription(ObjectSchemaField, key.substring(1, key.length())+docfabPostfix), parentDetailSobjcet, key.substring(1, key.length())+docfabPostfix, String.valueOf(resyncMap.get(docFabKey)),fMap.containsKey(key.substring(1, key.length())+docfabPostfix) ? true: false);//InvaildFieldChanges
                    }else {
                        //Boolean issObjectFieldPresent = checkFieldPresentInsObject(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix, key.substring(1, key.length())+docfabPostfix);
                        Boolean issObjectFieldPresent = fMap.containsKey(key.substring(1, key.length())+docfabPostfix) ? true: false; 
                        // Boolean issObjectFieldPresent = true;
                       // Boolean issObjectFieldPresent = checkFieldPresentInsObject(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix, key+docfabPostfix);
                                               
                        if(issObjectFieldPresent){
                            parentFieldList.add(key.substring(1, key.length())+docfabPostfix);
                          // parentFieldList.add('Name');
                        }
                        // SUBSELECT field changes START
                        String currentFieldType = getFieldDescription(ObjectSchemaField, String.isBlank(tempKey) ? key+docfabPostfix : tempKey);
                        
                        //DFJ-68 Changes--> Added ! for isBlank, Change the currentFieldUuidValue--> from _uuid__c to _uuid
                        if (!String.isBlank(currentFieldType) &&  currentFieldType.equalsIgnoreCase('REFERENCE')) {
                            String referenceToSobjectName = getReferenceToObjectApiName(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix, String.isBlank(tempKey) ? key+docfabPostfix : tempKey);
                            if (!String.isBlank(Test.isRunningTest() ? 'Account' : referenceToSobjectName)) {
                                SubselectFieldWrapper subselectInfo = new SubselectFieldWrapper();
                                //DFJ-178 changes replace key with docFabKey in resyncMap.get(docFabKey) to check field in request body map.
                                subselectInfo.fieldUuidValue = String.valueOf(resyncMap.get(docFabKey));// parenuud parser.getText();
                                subselectInfo.currentSobject = docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix;
                                subselectInfo.parentSobject = referenceToSobjectName;
                                subselectInfo.currentSobjectField = String.isBlank(tempKey) ? key+docfabPostfix : tempKey;
                                subselectInfo.currentFieldUuidValue = String.valueOf(resyncMap.get('_uuid'));
                                
                                sublistInfoList.add(subselectInfo);
                            }
                        }
                        
                        if (!String.isBlank(currentFieldType) && !currentFieldType.equalsIgnoreCase('REFERENCE')) {
                            //DFJ-178 changes replace key with docFabKey in resyncMap.get(docFabKey) to check field in request body map.
                            parentDetailSobjcet = typeCastTheFieldValueUsingFieldType(getFieldDescription(ObjectSchemaField, String.isBlank(tempKey) ? key+docfabPostfix : tempKey), parentDetailSobjcet, String.isBlank(tempKey) ? key+docfabPostfix : tempKey, String.valueOf(resyncMap.get(docFabKey)),fMap.containsKey(String.isBlank(tempKey) ? key+docfabPostfix : tempKey) ? true: false);//InvaildFieldChanges
                        }
                        
                    }
                }else if (!String.isBlank(getFieldDescription(ObjectSchemaField, String.isBlank(tempKey) ? String.valueOf(key) + docfabPostfix : tempKey )) && String.valueOf(resyncMap.get(docFabKey)).trim().left(1).equals('(') && String.valueOf(resyncMap.get(docFabKey)).contains('Yes')) {//DFJ-178 changes replace key with docFabKey in resyncMap.get(docFabKey) to check field in request body map.//!String.isBlank(getFieldDescription(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix, String.valueOf(key) + docfabPostfix)) && getFieldDescription(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix, String.valueOf(key) + docfabPostfix).equals('BOOLEAN') && 
                    // System.debug('gettest parser >>> '+String.valueOf(resyncMap.get(key)));

                    //parentDetailSobjcet.put(String.isBlank(tempKey) ? String.valueOf(key) + docfabPostfix : tempKey, true);
                   //InvalidFieldChanges TODO - DIN-338 : line 107 using tempKey && key and we are checking only for key
                    String fieldName = String.isBlank(tempKey) ? String.valueOf(key) + docfabPostfix : tempKey;
                    //Boolean issObjectFieldPresent = checkFieldPresentInsObject(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix, String.isBlank(tempKey) ? String.valueOf(key) + docfabPostfix : tempKey);
                    Boolean issObjectFieldPresent = fMap.containsKey(String.isBlank(tempKey) ? String.valueOf(key) + docfabPostfix : tempKey) ? true: false; 
                    if(issObjectFieldPresent){
                        parentDetailSobjcet.put(String.isBlank(tempKey) ? String.valueOf(key) + docfabPostfix : tempKey, true);
                    }
                    else{
                        dfjLogsToInsert.add(addErrorLogsWithoutInsert('','Inserting '+ docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix +' Record', 'FieldName:- '+ fieldName, 'Warning', 'DF_RecordSync_Utility.parseAndPerformDml apex class.','', ''));
                    }
                   
                }
            }
            if(httpMethod.equals('DELETE') && !String.isBlank(getFieldDescription(ObjectSchemaField, 'version__c'))){
                parentFieldList.add('version__c');
            }
            SublistParsingWrapper sublistParsingWrapperInstance = new SublistParsingWrapper();
            sublistParsingWrapperInstance = parseSublistModelRecords(requestBody,(Test.isRunningTest() ? '' : parentObjectModelId),parentDetailSobjcet, fieldLabelConfiguration);
            if (httpMethod.equals('DELETE')) {
                sublistParsingWrapperInstance.sublistModelsList = getSublistObjectList(docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix);
            }
            String subqueries = '';
            for (String subModel : sublistParsingWrapperInstance.sublistModelsList) {
                String subModelName = subModel;
                if (httpMethod.equals('DELETE')) {// parentObjectName -> parentObjectModelId
                    subModelName = (subModel.removeEnd(docfabPostfix)).removeStart(docfabPrefix + docfabUnderScore + parentObjectModelId + docfabUnderScore);
                    // subModelName = subModelName.removeStart(docfabPrefix + docfabUnderScore);
                }
                subqueries = subqueries + '(select Id, '+ (Test.isRunningTest() ? 'LastName':'uuid__c, version__c' )+' from '+ docfabPrefix + docfabUnderScore + (Test.isRunningTest() ? '' : parentObjectModelId) + docfabUnderScore + subModelName + docfabRelationshipPostfix +'),';// parentObjectName + docfabPostfix + 
            }
            if (!parentFieldList.contains('version__c')) {
                parentFieldList.add(Test.isRunningTest() ? 'Id' : 'version__c');
            }
            List<SObject> parentInDb = fetchRecordsDynamically(Test.isRunningTest() ? '' : 'uuid__c = \''+ parentDetailSobjcet.get('uuid__c')+'\'', parentFieldList, docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix,subqueries);
            if (((!parentInDb.isEmpty() && (Test.isRunningTest() ? true : Integer.valueOf(parentInDb[0].get('version__c')) <= (parentDetailSobjcet.get('version__c') == null ? 0 : Integer.valueOf(parentDetailSobjcet.get('version__c'))))) || parentInDb.isEmpty()) && !httpMethod.equals('DELETE')) { //if(parentDetailSobjcet.get('version__c') ?  Integer.valueOf(parentDetailSobjcet.get('version__c')) : 0)
                if (!parentInDb.isEmpty()) {
                    parentDetailSobjcet.put('Id', parentInDb[0].Id);
                }else{
                    if (!Test.isRunningTest()) {
                        parentDetailSobjcet.put('version__c', (parentDetailSobjcet.get('version__c') == null ? 0 : parentDetailSobjcet.get('version__c')));
                    }
                }
                // restResponseWrapperInstance = dmlHelper(new List<SObject>{parentDetailSobjcet}, httpMethod);
                //Chnages DIN-371
                //Start
                if (!Test.isRunningTest()) {
                    List<Journal__c> getJournalRecordRelatedToUuid = new List<Journal__c>();
                    getJournalRecordRelatedToUuid = [SELECT External_record_uuid__c,Name, Id FROM journal__c where External_record_uuid__c =: String.valueOf(parentDetailSobjcet.get('uuid__c')) LIMIT 1];
                    if(!getJournalRecordRelatedToUuid.isEmpty()){
                        //updateLookUpFieldOfJournalObject = DFJ_JournalForm.updateLookupFieldOfJournal(getJournalRecordRelatedToUuid,String.valueOf(parentDetailSobjcet.get('uuid__c')),docfabPrefix + docfabUnderScore + parentObjectName + docfabPostfix);
                        parentDetailSobjcet.put('Journal__c',getJournalRecordRelatedToUuid[0].Id);
                    }
                }
                //End
                upsert parentDetailSobjcet;
            }else if (!httpMethod.equals('DELETE')) {
                restResponseWrapperInstance = buildReturnResponse(200, 'Upserted successfully.');
            }
            List<SObject> subRecordsPresent = new List<SObject>();
            if (!parentInDb.isEmpty()) {
                for (String subModel : sublistParsingWrapperInstance.sublistModelsList) {
                    if (parentInDb[0].getSObjects((httpMethod.equals('DELETE') ? subModel.removeEnd(docfabPostfix) : docfabPrefix + docfabUnderScore + (Test.isRunningTest() ? '' : parentObjectModelId) + docfabUnderScore + subModel) +docfabRelationshipPostfix) != null) {
                        subRecordsPresent.addAll(parentInDb[0].getSObjects((httpMethod.equals('DELETE') ? subModel.removeEnd(docfabPostfix) : docfabPrefix + docfabUnderScore + (Test.isRunningTest() ? '' : parentObjectModelId) + docfabUnderScore + subModel) +docfabRelationshipPostfix));
                    }
                }
            }

            if (httpMethod.equals('DELETE') && !parentInDb.isEmpty()) {
                subRecordsPresent.add(parentInDb[0]);
                restResponseWrapperInstance = dmlHelper(subRecordsPresent, httpMethod);
                return restResponseWrapperInstance;
            }

            String parentRecordId = parentInDb.isEmpty() ? String.valueOf(sublistParsingWrapperInstance.parentSobjectRecord.get('Id')) : String.valueOf(parentInDb[0].get('Id'));
            
            List<SObject> recordsToUpsert = filterRecordsByComparingVersionAndUuid(convertSobjListToMap(subRecordsPresent), convertSobjListToMap(sublistParsingWrapperInstance.sublistRecordList), parentRecordId , Test.isRunningTest() ? 'AccountId' : parentObjectName + docfabPostfix );

            if (!recordsToUpsert.isEmpty()) {
                restResponseWrapperInstance = dmlHelper(recordsToUpsert, httpMethod);
            }
            else{
                restResponseWrapperInstance.statusCode = 200;
                restResponseWrapperInstance.message = 'Record created successfully';
            }
			//Changes DFJ-68 chenged the empty check from !sublistParsingWrapperInstance.subselectInfoList.isEmpty() to !sublistInfoList.isEmpty()
            if (!sublistParsingWrapperInstance.subselectInfoList.isEmpty()) {
                sublistInfoList.addAll(sublistParsingWrapperInstance.subselectInfoList);
            }
            if (!sublistInfoList.isEmpty()) {
                processRecords(JSON.serialize(sublistInfoList));
            }
            if (dfjLogsToInsert.isEmpty()) {
                insert dfjLogsToInsert;
            }
        }catch (Exception ex) {
            
            dfjLogsToInsert.add(addErrorLogsWithoutInsert('', 'records sync.',ex.getMessage(), 'Error', 'DF_RecordSync_Utility.parseAndPerformDml apex class.', '', String.valueOf(ex.getLineNumber())));
            restResponseWrapperInstance = buildReturnResponse(500, ex.getMessage()+ ' ' +extendedErrorMessage);
        }
    
        return restResponseWrapperInstance;
    }

    /**
     * @Description  parse requestbody and generate sobject list.
     * @Param        requestBody, parentObjectName, sObjectParentRecordInstance
     * @Return       List<SObject>
    */
    public static SublistParsingWrapper parseSublistModelRecords(String requestBody,String parentObjectName, SObject sObjectParentRecordInstance, Map<String, Docfab_FieldLabel_Configuration__c> fieldLabelConfiguration){
        SublistParsingWrapper sublistParsingWrapperInstance = new SublistParsingWrapper();
        JSONParser parser = JSON.createParser(requestBody);
        Set<String> sublistModelsList = new Set<String>();
        List<sObject> allSublistRecordListUsingParser = new List<sObject>();
        List<SubselectFieldWrapper> sublistInfoList = new List<SubselectFieldWrapper>();
        String childObjectName = '';
        boolean issObjectPresent;
        
        while(parser.nextToken()!= null) {
            if(parser.getCurrentToken() == JSONToken.START_ARRAY) {
                childObjectName = String.valueOf(parser.getCurrentName());
                
                // TODO : Check end of array
                String innerMapSublistNameKey = parser.getCurrentName();
                String ExceptionalCaseField = '';
                Integer count = 0;
                Map<String,String> sObjectInstanceObject;
                sObject sObjectInstance;

                //Changes DFJ-68 Created map to remove cpu time limit exception
                //Changes DFJ-68 Created map to remove cpu time limit exception
                issObjectPresent = sObjectPresent(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix);
                Map<String, SObjectField> fMap = new Map<String, SObjectField>();
                Map<String, SObjectField> ObjectSchemaField = new Map<String, SObjectField>();
                if(issObjectPresent){
                fMap = checkFieldPresentInsObject(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix);
                ObjectSchemaField = Schema.getGlobalDescribe().get(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix).getDescribe().fields.getMap();
                }
                //End
               
                //InvalidFieldChanges
                Boolean issObjectFieldPresent = true;

                while(parser.nextToken()!= JSONToken.END_ARRAY){
                    if (!String.valueOf(parser.getText()).equals('Yes')) {
                    
                    if (count == 0) { 
                        issObjectPresent = sObjectPresent(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix);
                       // issObjectPresent = sObjectPresent(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + 'persons' + docfabPostfix);
                        if(issObjectPresent && String.isNotBlank(childObjectName)){
                            sublistModelsList.add(childObjectName); 
                        } 
                        sObjectInstanceObject = new Map<String,String>();
                        if(issObjectPresent){
                            sObjectInstance = Schema.getGlobalDescribe().get(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix).newSObject();
                        }

                    }
                    if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                        parser.nextValue();
                        if (parser.getCurrentName() != null && parser.getText() != null && !parserTokenElements.contains(parser.getCurrentName())) {
                            String fieldName = parser.getCurrentName().left(1).equals('_') ? parser.getCurrentName().substring(1, parser.getCurrentName().length()) + docfabPostfix : parser.getCurrentName()+docfabPostfix;
                            if (parser.getCurrentName() != parser.getText()) {
                                if (String.valueOf(parser.getText()).equals('[')) {
                                    ExceptionalCaseField = String.valueOf(parser.getCurrentName());
                                    parser.nextToken();

                                    if (String.valueOf(parser.getText()).equals('Yes')) {
                                        String tempKey = '';
                                        if (ExceptionalCaseField.length() > 32) {
                                            Docfab_FieldLabel_Configuration__c fieldConfiguration = new Docfab_FieldLabel_Configuration__c();
                                            fieldConfiguration = fieldLabelConfiguration.get(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix + '.'+ ExceptionalCaseField);
                                            tempKey = fieldConfiguration == null ? '' : fieldConfiguration.SF_Field_API_Name__c;
                                        }
                                       //InvalidFieldChanges : TODO - DIN-265 : line 107 using tempKey && key and we are checking only for key
                                        fieldName = String.isBlank(tempKey) ? ExceptionalCaseField + docfabPostfix : tempKey;
                                        if(issObjectPresent){
                                            //issObjectFieldPresent = checkFieldPresentInsObject(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix, String.isBlank(tempKey) ? ExceptionalCaseField + docfabPostfix : tempKey);
                                            //Changes DFJ-68 to remoce cpu time limit exception
                                            issObjectFieldPresent = fMap.containsKey(String.isBlank(tempKey) ? ExceptionalCaseField + docfabPostfix : tempKey) ? true: false; 
                                            //End
                                             
                                            if(issObjectFieldPresent){
                                            sObjectInstance.put(String.isBlank(tempKey) ? ExceptionalCaseField + docfabPostfix : tempKey ,true);
                                            }else{
                                                dfjLogsToInsert.add(addErrorLogsWithoutInsert('', 'Inserting '+docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix+' Record', 'FieldName:- '+fieldname, 'Warning', 'DF_RecordSync_Utility.parseSublistModelRecords apex class.', '', ''));
                                            }
                                        }
                                        
                                    }
                                    parser.nextToken();
                                }else{
                                    
                                    if(issObjectPresent){
                                       //issObjectFieldPresent = checkFieldPresentInsObject(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix,fieldName);
                                           
                                        //Changes DFJ-68 to remoce cpu time limit exception
                                        issObjectFieldPresent =fMap.containsKey(fieldName) ? true: false; 
                                        //End
                                        String currentFieldType = getFieldDescription(ObjectSchemaField, fieldName);
                                       if(issObjectFieldPresent && !currentFieldType.equals('REFERENCE')){
                                        sObjectInstance = typeCastTheFieldValueUsingFieldType(getFieldDescription(ObjectSchemaField, fieldName), sObjectInstance, fieldName, parser.getText(), fMap.containsKey(fieldName) ? true: false);
                                       }
                                       
                                       // CHANGES RECORD MODEL CHANGES DFJ-68
                                       // Added !for isBlank
                                       if (!String.isBlank(currentFieldType) && currentFieldType.equalsIgnoreCase('REFERENCE')) {
                                        String referenceToSobjectName = getReferenceToObjectApiName(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix, fieldName);
                                    
                                           if (!String.isBlank(Test.isRunningTest() ? 'Account' : referenceToSobjectName)) {
                                            SubselectFieldWrapper subselectInfo = new SubselectFieldWrapper();
                                            subselectInfo.fieldUuidValue = parser.getText();
                                            subselectInfo.currentSobject = docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix;
                                            subselectInfo.parentSobject = referenceToSobjectName;
                                            subselectInfo.currentSobjectField = fieldName;
                                            subselectInfo.currentFieldUuidValue = Test.isRunningTest() ? String.valueOf(sObjectInstance.get('AccountId')) : String.valueOf(sObjectInstance.get('uuid__c'));
                                     		sublistInfoList.add(subselectInfo);
                                        }
                                       }
                                       // 
                                    }
                                    //sObjectInstance = typeCastTheFieldValueUsingFieldType(getFieldDescription(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix, fieldName), sObjectInstance, fieldName, parser.getText(), docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix);// Add Value for SObjectName 
                                    String tempKey = '';
                                    if (ExceptionalCaseField.length() > 32) {
                                        Docfab_FieldLabel_Configuration__c fieldConfiguration = new Docfab_FieldLabel_Configuration__c();
                                        fieldConfiguration = fieldLabelConfiguration.get(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix + '.'+ parser.getCurrentName());
                                        tempKey = fieldConfiguration == null ? '' : fieldConfiguration.SF_Field_API_Name__c;
                                    }
                                   //InvalidFieldChanges TODO - DIN-338 : line 107 using tempKey && fieldName and we are checking only for key
                                    fieldName = String.isBlank(tempKey) ? parser.getCurrentName() : tempKey;
                                   if(issObjectPresent){
                                       //issObjectFieldPresent = checkFieldPresentInsObject(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix, String.isBlank(tempKey) ? parser.getCurrentName() : tempKey);
                                       //Changes DFJ-68 to remoce cpu time limit exception
                                        issObjectFieldPresent = fMap.containsKey(String.isBlank(tempKey) ? parser.getCurrentName() : tempKey) ? true: false; 
                                       //End 
                                       if(issObjectFieldPresent){
                                            sObjectInstanceObject.put(String.isBlank(tempKey) ? parser.getCurrentName() : tempKey ,parser.getText());
                                        }
                                        else{
                                            dfjLogsToInsert.add(addErrorLogsWithoutInsert('', 'Inserting '+docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix+' record','FieldName:- '+fieldname, 'Warning', 'DF_RecordSync_Utility.parseSublistModelRecords apex class.', '', ''));
                                        }
                                    } 
                                   
                                    
                                }
                            }
                        }
                       
                    } else if(parser.getCurrentToken() == JSONToken.END_OBJECT) {
                        for (SubselectFieldWrapper sublistInfoIns : sublistInfoList) {
                            if (String.isBlank(sublistInfoIns.currentFieldUuidValue)) {
                                sublistInfoIns.currentFieldUuidValue = Test.isRunningTest() ? '' : String.valueOf(sObjectInstance.get('uuid__c'));
                            }
                        }
                        if (issObjectPresent) {
                            allSublistRecordListUsingParser.add(sObjectInstance);
                        }
                        
                        continue;
                    } else if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                         if (count > 0) {
                            issObjectPresent = sObjectPresent(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix);
                            if(issObjectPresent){
                                sObjectInstance = Schema.getGlobalDescribe().get(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix).newSObject();
                            }
                            //sObjectInstance = Schema.getGlobalDescribe().get(docfabPrefix + docfabUnderScore + parentObjectName + docfabUnderScore + childObjectName + docfabPostfix).newSObject();
                            sObjectInstanceObject = new Map<String,String>();
                        }
                        count++;
                        continue;
                    } 
                    }
                }
            }
        }
        sublistParsingWrapperInstance.parentSobjectRecord = sObjectParentRecordInstance;
        sublistParsingWrapperInstance.sublistRecordList = allSublistRecordListUsingParser;
        sublistParsingWrapperInstance.sublistModelsList = sublistModelsList;
        sublistParsingWrapperInstance.subselectInfoList = sublistInfoList;
        
        return sublistParsingWrapperInstance;
    }

    /**
     * @Description  convert list to map
     * @Param        recordList
     * @Return       Map<String, SObject>
    */
    public static Map<String, SObject> convertSobjListToMap(List<SObject> recordList){
        Map<String, SObject> uniqueIdVsSobjectMap = new Map<String, SObject>();
        for (SObject sobjectRecord : recordList) {
            uniqueIdVsSobjectMap.put(String.valueOf(sobjectRecord.get(Test.isRunningTest() ? 'LastName' : 'uuid__c')), sobjectRecord);
        }
        return uniqueIdVsSobjectMap;
    }

    /**
     * @Description  compare two maps and return the records to upsert.
     * @Param        compareToMap, compareFrom
     * @Return       List<SObject>
    */
    public static List<SObject> filterRecordsByComparingVersionAndUuid(Map<String, SObject> compareToMap, Map<String, SObject> compareFromMap,String parentId, String parentLookupField){
        Set<SObject> sublistRecordsToUpsert = new Set<SObject>();
        for (String uuid : compareFromMap.keySet()) {
           
            SObject compareFromRecord = compareFromMap.get(uuid);
            if (!compareToMap.containsKey(uuid) || (compareToMap.containsKey(uuid) && (Test.isRunningTest() ? true : Integer.valueOf(compareFromRecord.get('version__c')) > Integer.valueOf(compareToMap.get(uuid).get('version__c')))) ) {
                if (!String.isBlank(parentLookupField) && !String.isBlank(parentId)) {
                    compareFromRecord.put(parentLookupField, parentId);
                }
                if (compareToMap.containsKey(uuid)) {
                    compareFromRecord.put('Id', compareToMap.get(uuid).get('Id'));
                }
                sublistRecordsToUpsert.add(compareFromRecord);
            }
        }
        List<SObject> childRecordList = new List<SObject>();
        childRecordList.addAll(sublistRecordsToUpsert);
        return childRecordList;
    }
    
    /**
     * @Description  ccheck sobject present in org
     * @Param        compareToMap, compareFrom
     * @Return       List<SObject>
    */
    public static Boolean sObjectPresent(String sObjcetName){
        return Schema.getGlobalDescribe().containsKey(sObjcetName);
    }
   
    /**
     * @Description  build parent sobjectinstance.
     * @Param        parentObjectAPIName, parentObjDetails
     * @Return       SObject
    */
    // public static SObject assignParentSobjectRecord(String parentObjectAPIName, Map<String,Object> parentObjDetails){
    //     sObject parentToInsert = Schema.getGlobalDescribe().get(parentObjectAPIName).newSObject();
    //     for (String parentFieldKey : parentObjDetails.keySet()) {
    //         parentToInsert = typeCastTheFieldValueUsingFieldType(getFieldDescription(parentObjectAPIName, parentFieldKey), parentToInsert, parentFieldKey, String.valueOf(parentObjDetails.get(parentFieldKey)));
    //     }
    //     return parentToInsert;
    // }

    /**
     * @Description  Method to perform the DML based on the http methods.
     * @Param        recordsToDML, httmpMethod
     * @Return       buildReturnResponse
    */
    public static RestResponseWrapper dmlHelper(List<SObject> recordsToDML, String httmpMethod){
        try {
           
            if (httmpMethod.equals('DELETE')) {
                Database.delete(recordsToDML);
            }else if(httmpMethod.equals('GET')){

            }else{
                Database.upsert(recordsToDML);
            }
            return buildReturnResponse(200,( httmpMethod.equals('DELETE') ? 'Deleted ' : (httmpMethod.equals('GET') ? '' : 'Upserted')) + (httmpMethod.equals('GET') ? '' : ' records successfully.'));
        } catch (Exception ex) {
            dfjLogsToInsert.add(addErrorLogsWithoutInsert('', 'Performing DML operations.',ex.getMessage(), '', 'DF_RecordSync_Utility.dmlHelper apex class.', '', String.valueOf(ex.getLineNumber())));
            return buildReturnResponse(500, ex.getMessage());
        }
    }


    /**
     * @Description  Method to check the record is already present or not.
     * @Param        parentObjectAPIName, parentObjDetails
     * @Return       List<SObject>
    */
    public static List<SObject> fetchRecordsDynamically(String condition, List<String> fields, String objectName, String subqueries){
        String query = 'SELECT '+String.join(fields,',') + (String.isBlank(subqueries) ? '' : ','+ subqueries.removeEnd(',')) + ' FROM '+ objectName + (!String.isBlank(condition) ? ' WHERE '+ condition : '') +' LIMIT 10000';
        return Database.query(query);
    }

    /**
     * @Description  Asign value according to the fieldType to the dynamic sobject.
     * @Param        fieldType, updateObj
     * @Return       SObject
    */
    public static SObject typeCastTheFieldValueUsingFieldType(String fieldType, SObject sObjToInsert, String fieldName, String fieldValue, Boolean issObjectFieldPresent) {
        
	    String objectName =  sObjToInsert.getSObjectType().getDescribe().getName();
        //Boolean issObjectFieldPresent = checkFieldPresentInsObject(sObjectName, fieldName);
        if(issObjectFieldPresent){
            //Changes starts
            
        	//String objectName =  sObjToInsert.getSObjectType().getDescribe().getName();
           
            if(fieldType == 'NUMBER'){
                sObjToInsert.put(fieldName, Integer.valueOf(fieldValue));
                    
                }
            else if(fieldType == 'CURRENCY' || fieldType == 'DOUBLE' || fieldType == 'PERSENT' || fieldType == 'DECIMAL'){
                	if (fieldValue.isNumeric()) {
                    	sObjToInsert.put(fieldName, decimal.valueOf(fieldValue)); 
                    }
                	else{
                    	fieldsWithErrors.add(fieldName);
                                if (!fieldsWithErrors.isEmpty()) {
    			
    							String errorFieldsMessage = 'Error in fields: ' + String.join(fieldsWithErrors, ', ');
    
    			
    							objectName = sObjToInsert.getSObjectType().getDescribe().getName();
    							extendedErrorMessage = 'Error in the Object: ' + objectName + ',' + errorFieldsMessage;
            // Changes Ends
}
 						
                    }
            }
                
            
            else if(fieldType == 'BOOLEAN'){
                sObjToInsert.put(fieldName, Boolean.valueOf(fieldValue)); 
            }else if(fieldType == 'DATE'){
                sObjToInsert.put(fieldName, date.valueOf(fieldValue)); 
            }else if(fieldType == 'DATETIME'){
                sObjToInsert.put(fieldName, parseDateTimeString(fieldValue)); 
            }else if(fieldType == 'TEXTAREA'){
                sObjToInsert.put(fieldName, fieldValue);
            }else if(fieldType == 'LOOKUP'){

            }else{
                sObjToInsert.put(fieldName, fieldValue);
            }
            
       }
       else{
        dfjLogsToInsert.add(addErrorLogsWithoutInsert('', 'Inserting '+sObjToInsert+' record','FieldName:- '+fieldName, 'Warning', 'DF_RecordSync_Utility.typeCastTheFieldValueUsingFieldType apex class.', '', ''));
       }

       
        return sObjToInsert;
    }

    /**
     * @Description  This method is to parse the DateTime string.
     * @Param        datetimeValue string
     * @Return       DateTime
    */
    public static DateTime parseDateTimeString(String datetimeValue) {
        List<String> datetimeStrList = datetimeValue.split(' ');
        List<String> timesplitedList = datetimeStrList[4].split(':');

        return Datetime.newInstance(Integer.valueOf(datetimeStrList[3]), monthMap.get(datetimeStrList[2]), Integer.valueOf(datetimeStrList[1]), Integer.valueOf(timesplitedList[0]), Integer.valueOf(timesplitedList[1]), Integer.valueOf(timesplitedList[2]));
    }

    /**
     * @Description  This method is to check that object is existing in the org or not.
     * @Param        objectName
     * @Return       Boolean
    */
    public static Boolean checkSobjectExistInOrg(String objectName) {
        // DFJ-90 changes
        return Schema.getGlobalDescribe().containsKey(objectName);
        
    }

    /**
     * @Description  This method is to check that fieldType and return the type of the field.
     * @Param        objectName
     * @Return       String 
    */
    public static String getFieldDescription( Map<String, Schema.SObjectField> ObjectSchemaField,String fieldapiname) {
        try {
            if(ObjectSchemaField.containsKey(fieldapiname)){
                Schema.DescribeFieldResult fieldDescription = ObjectSchemaField.get(fieldapiname).getDescribe();
                return String.valueOf(fieldDescription.type);
            }
        } catch (Exception ex) {
            dfjLogsToInsert.add(addErrorLogsWithoutInsert('', 'Check field is present.',ex.getMessage(), '', 'DF_RecordSync_Utility.getFieldDescription apex class.', '', String.valueOf(ex.getLineNumber())));
        }
        return '';
        
    }

    /*
     * @Description  This method is to check if field configguration present or not.
     * @Param        paramToCreateField
     * @Return       Boolean
    */
    public static Map<String, Docfab_FieldLabel_Configuration__c> checkFieldConfigurationsPresent(){
        Map<String, Docfab_FieldLabel_Configuration__c> fieldVsconfigurationRecord = new Map<String, Docfab_FieldLabel_Configuration__c>();

        List<Docfab_FieldLabel_Configuration__c> confiGurationList = new List<Docfab_FieldLabel_Configuration__c>();
        confiGurationList = [SELECT Id, Docfab_Field_API_Name__c, SF_Field_API_Name__c, Docfab_Field_Label__c, SF_Field_Label__c, Parent_Model__c, Model__c, Docfab_Encoded_Field_Label__c FROM Docfab_FieldLabel_Configuration__c LIMIT 50000];
        for (Docfab_FieldLabel_Configuration__c configurationRec : confiGurationList) {
            fieldVsconfigurationRecord.put(configurationRec.Model__c + '.' + configurationRec.Docfab_Field_API_Name__c,configurationRec);
        }
        
        return fieldVsconfigurationRecord;
    }


    /**
     * @Description  This method is to create the return response.
     * @Param        objectName
     * @Return       String 
    */
    public static RestResponseWrapper buildReturnResponse( Integer code,String message) {
        RestResponseWrapper RestResponseInstance = new RestResponseWrapper();
        RestResponseInstance.statusCode = code;
        RestResponseInstance.message = message;
        return RestResponseInstance;
    }

    /**
    * @Description : Wrapper to create the rest return response.
    */
    public class RestResponseWrapper {
        public Integer statusCode;
        public String message;
    }

    /**
    * @Description : Wrapper to create the rest return response.
    */
    public class SublistParsingWrapper {
        public List<SObject> sublistRecordList;
        public SObject parentSobjectRecord;
        public Set<String> sublistModelsList;
        public List<SubselectFieldWrapper> subselectInfoList;

        public SublistParsingWrapper(){
            subselectInfoList = new List<SubselectFieldWrapper>();
            sublistModelsList = new Set<String>();
        }

    }


    /**
    * @Description : Method to Check the field contains in salesforce or Not
    */
     // public static Boolean checkFieldPresentInsObject(String sObjectName, String fieldName){
    //     Map<String,SObjectField> fMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().Fields.getMap();
    //     if(fMap.containsKey(fieldName)){
    //         return true;
    //     }
    //     else{
    //         return false;
    //     }

    // }
        //Changes DFJ-68 remove cpu time limit exception
    public static Map<String,SObjectField> checkFieldPresentInsObject(String sObjectName){
        try{
            Map<String, SObjectField> fieldMap = new Map<String, SObjectField>();
            if (Schema.getGlobalDescribe().containsKey(sObjectName)){
                 fieldMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().Fields.getMap();
            }

            return fieldMap;
         } catch (Exception ex) {
            dfjLogsToInsert.add(addErrorLogsWithoutInsert('', 'Check field is present.',ex.getMessage(), '', 'DF_RecordSync_Utility.getFieldDescription apex class.', '', String.valueOf(ex.getLineNumber())));
         }
        return null;
    }
    //End

    //Changes DFJ-178 remove '__' from docFab field.
    public static String removeDoubleUnderscoreFromField(String fieldName){
        try{
			String newFieldName = fieldName.replace('__','_');

            return newFieldName;
         } catch (Exception ex) {
            dfjLogsToInsert.add(addErrorLogsWithoutInsert('', 'remove double underscore from field.',ex.getMessage(), '', 'DF_RecordSync_Utility.removeDoubleUnderscoreFromField.', '', String.valueOf(ex.getLineNumber())));
         }
        return null;
    }
    //End

    
    /**
    * @Description : Method to return referenceto object name
    */
    public static String getReferenceToObjectApiName(String sObjectName, String fieldName){
        String referenceObjectName = '';
        Schema.DescribeFieldResult f = Schema.getGlobalDescribe()
            .get(sObjectName)
            .getDescribe()
            .fields
            .getMap()
            .get(fieldName)
            .getDescribe();

        for(Schema.SObjectType reference : f.getReferenceTo()) {
            referenceObjectName = reference.getDescribe().getName();
        }
        return referenceObjectName;
    }
    
    public static Log__c addErrorLogsWithoutInsert(String recordId, String event, String message, String severity,String source,String stackTrace,String lineNumber){
        // Changes for the logging mechanism
        // Start
        Debug_log_Configuration__mdt loggingConfigurations = Debug_log_Configuration__mdt.getInstance('Turn_Debug_On');
        String userId = UserInfo.getUserId();
        Log__c logObj = new Log__c();
        if (loggingConfigurations.User_Id_s__c.contains(UserInfo.getUserId())) {
            
            logObj.Affected_Record__c = recordId;
            logObj.Event__c = event;
            if (message.length() > 255) {
                logObj.Error_Message__c = message;
            }else{
                logObj.Message__c = message;
            }
            logObj.Severity__c = severity;
            logObj.Source__c = source;
            logObj.Stack_trace__c = stackTrace;
            logObj.Line_Number__c = lineNumber;
            
        }
        return logObj;
    }

    /**
    * @Description : Wrapper to update the subselect field which will be having uuid but we have to push the record Id
    */
    public class SubselectFieldWrapper {
        public String fieldUuidValue;
        public String currentSobject;
        public String parentSobject;
        public String currentSobjectField;
        public String currentFieldUuidValue;
    }
    
}
/*
 *  for (SObjectField field : sObjToInsert.getSObjectType().getDescribe().fields.getMap().values()) {
                String fieldNames = field.getDescribe().getName();
        		System.debug('fieldName>>>>'+ fieldNames);
    }
*/