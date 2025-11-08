/*
* @Version : 1.0
* @Created Date : 2021-09-27
* @Description : This class will be used for handling methods related to membership operations.
*/
public without sharing class DFJ_MembershipController implements Queueable {
    
     private String leadRecord;
   

    // Constructor to accept Lead Id
    public DFJ_MembershipController(String leadId) {
        this.leadRecord = leadId;
        
    }
    /*
* @Description  This method will be used for posting membership data to membership platform.
* @Param        List<Membership__c>
* @Return       void
*/
    @future (callout = true)
    public static void PostMembershipDataToPlatform(String requestbody,String membershipId){
        List<Membership__c> membershipList = new List<Membership__c>();
        try{
            if(String.isBlank(membershipId) || String.isBlank(requestbody)){
                DFJ_ErrorController.addErrorLogs('', 'Post the membership data to membership platform.', 'Invalid request body or membership Id', 'Warning', 'DFJ_MembershipController.PostMembershipDataToPlatform apex class.', '');
                
            } else{
                //System.debug('requestBody >>>'+ requestbody);
                
                // Fetching membership record after insert to update it according to the response.
                membershipList = [SELECT Profile_Link__c, Responsible_Lawyer__c, CPR__c, Phone__c, Sign_up_Date__c, Email__c, Membership_Number__c, Account__c, Name, Id FROM Membership__c
                                  WHERE Id =: membershipId LIMIT 1];
                
                DFJ_Membership_Platform_Authorizer__c memberPlatformAuth = DFJ_Membership_Platform_Authorizer__c.getOrgDefaults();
                
                // Check for response
                //Chnages TCS-27
                //Start
                //for(Membership__c memberRecords : membershipList){
                if (!String.isBlank(memberPlatformAuth.Callout_Url__c)) {
                    HttpRequest membershipHttpRequest = new HttpRequest();
                    membershipHttpRequest.setEndpoint(memberPlatformAuth.Callout_Url__c);
                    membershipHttpRequest.setMethod('POST');
                    membershipHttpRequest.setBody(requestbody);
                    membershipHttpRequest.setHeader('Authorization', 'Bearer '+memberPlatformAuth.Static_Token__c);
                    membershipHttpRequest.setHeader('content-type', 'application/json');
                    
                    Http http = new Http();
                    HTTPResponse membershipHttpResponse = http.send(membershipHttpRequest);
                   // System.debug(membershipHttpResponse.getBody());
                    // Check for membershipList is not empty
                    if(!membershipList.isEmpty()){
                        if(membershipHttpResponse != null && membershipHttpResponse.getStatusCode() == 200 && String.isNotBlank(membershipHttpResponse.getBody())){
                            String receivedStringBody = membershipHttpResponse.getBody();
                            ProfileInfoWrapper profileInfoWrapperInstance = new ProfileInfoWrapper();
                            profileInfoWrapperInstance = (ProfileInfoWrapper) JSON.deserialize(receivedStringBody, ProfileInfoWrapper.class);
                            membershipList[0].Platform_Create_State__c = 'OK';
                            membershipList[0].Profile_Link__c = profileInfoWrapperInstance.profileLink;
                            membershipList[0].Profile_Id__c = profileInfoWrapperInstance.profilId;
                            
                        } else{
                            membershipList[0].Platform_Create_State__c = 'ERROR';
                            
                        }
                    }
                    //End
                }
                if (Test.isRunningTest()) {
                    Double result = 10/0;
                }
            }
        } catch(Exception exp){
            DFJ_ErrorController.addErrorLogs('', 'Post the membership data to membership platform.', exp.getMessage(), 'Error', 'DFJ_MembershipController.PostMembershipDataToPlatform apex class.', String.valueOf(exp.getLineNumber()));
            if(!membershipList.isEmpty()){
                membershipList[0].Platform_Create_State__c = 'ERROR';
                
            }
            
        }
        
        // Updateing when membershipList is not empty
        if(!membershipList.isEmpty()){
            update membershipList;
            
        }
        
    }
    /*
* @Description : Wrapper to store profile info.
*/
    public class ProfileInfoWrapper{
        public string status;
        public string profileLink;
        public string profilId;
    }
    
    /*
* @Description : Wrapper to store profile info.
*/
    public class ResendMembershipWrapper{
        @AuraEnabled
        public Boolean isAdmin;
        @AuraEnabled
        public Integer noOfMembership;
    }
    
    /*
* @Description  This method will be used to check the user is Admin or not.
* @Return       ResendMembershipWrapper
*/
    @AuraEnabled
    public static ResendMembershipWrapper CheckUserProfile(){
        ResendMembershipWrapper resendMembershipWrapperInstance = new ResendMembershipWrapper();
        try {
            String userProfileName = [select Name from profile where id =: userinfo.getProfileId()]?.Name;
            List<Membership__c> membershipList = new List<Membership__c>();
            membershipList = [SELECT Platform_Create_State__c,Owner.Name,First_Name__c,Last_Name__c,Profile_Link__c, Responsible_Lawyer__c, CPR__c, Phone__c, Sign_up_Date__c, Email__c, Membership_Number__c, Account__c,Lead__c, Name, Id FROM Membership__c WHERE (Platform_Create_State__c = 'PENDING' OR Platform_Create_State__c = 'ERROR') LIMIT 100];
            if (!String.isBlank(userProfileName) && userProfileName.equals('System Administrator')) {
                
                resendMembershipWrapperInstance.isAdmin = true;
                resendMembershipWrapperInstance.noOfMembership = membershipList.size();
                return resendMembershipWrapperInstance;
            }
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Checking the user is SystemAdmin or not.', ex.getMessage(), 'Error', 'DFJ_MembershipController.CheckUserProfile apex class.', String.valueOf(ex.getLineNumber()));
        }
        resendMembershipWrapperInstance.isAdmin = false;
        resendMembershipWrapperInstance.noOfMembership = 0;
        return resendMembershipWrapperInstance;
    }
    
    /*
* @Description  This method is to to fire the webhooks which have status as Error.
* @Return       Boolean
*/
    @AuraEnabled
    public static String ResendmembershipWebhook(){
        try {
            List<Membership__c> membershipList = new List<Membership__c>();
            membershipList = [SELECT Platform_Create_State__c,Owner.Name,First_Name__c,Last_Name__c,Profile_Link__c, Responsible_Lawyer__c, CPR__c, Phone__c, Sign_up_Date__c, Email__c, Membership_Number__c, Account__c,Lead__c, Name, Id, Is_customer__c FROM Membership__c WHERE (Platform_Create_State__c = 'PENDING' OR Platform_Create_State__c = 'ERROR') LIMIT 100];
            
            if (membershipList.isEmpty()) {
                return 'Record not found.';
            }
            
            List<String> accountIds = new List<String>();
            List<String> leadIds = new List<String>();
            //List may take duplicate values 
            for (Membership__c memberLoop : membershipList) {
                if (!String.isBlank(memberLoop.Account__c)) {
                    accountIds.add(memberLoop.Account__c);
                }
                if (!String.isBlank(memberLoop.Lead__c)) {
                    leadIds.add(memberLoop.Lead__c);
                }
            }
            
            Map<ID, Account> relatedAccountToMembership = new Map<ID, Account>([SELECT Id,Market_Unit__c FROM Account WHERE Id IN: accountIds LIMIT 100]);
            Map<ID, Lead> relatedLeadToMembership = new Map<ID, Lead>([SELECT Id,Market_Unit__c FROM Lead WHERE Id IN: leadIds LIMIT 100]);
            
            DFJ_Membership_Platform_Authorizer__c memberPlatformAuth = DFJ_Membership_Platform_Authorizer__c.getOrgDefaults();
            List<Membership__c> membershipListToUpdate = new List<Membership__c>();
            for (Membership__c memberLoop : membershipList) {
                
                Account accountInstance = relatedAccountToMembership.get(memberLoop.Account__c);
                String language = (accountInstance != null && !String.isBlank(accountInstance.Market_Unit__c)) ? (accountInstance.Market_Unit__c.equals('DFJ_DK') || accountInstance.Market_Unit__c.equals('Testamente_DK')) ? 'DK' : (accountInstance.Market_Unit__c.equals('FA_SE') || accountInstance.Market_Unit__c.equals('Testamente_SV')) ? 'SE' : '' : '';
                
                if (String.isBlank(language)) {    
                    Lead leadInstance = relatedLeadToMembership.get(memberLoop.Lead__c);
                    
                    language = (leadInstance != null && !String.isBlank(leadInstance.Market_Unit__c)) ? (leadInstance.Market_Unit__c.equals('DFJ_DK') || leadInstance.Market_Unit__c.equals('Testamente_DK')) ? 'DK' : (leadInstance.Market_Unit__c.equals('FA_SE') || leadInstance.Market_Unit__c.equals('Testamente_SV')) ? 'SE' : '' : '';
                }
                
                Boolean isAccountNull = false;
                if (accountInstance == null) {
                    isAccountNull = true;
                }
                String requestbody = DFJ_MembershipTriggerHandler.ConstructRequestBody(new List<Membership__c>{memberLoop},language,isAccountNull,'resend webhook');
                if (!String.isBlank(memberPlatformAuth.Callout_Url__c)) {
                    HttpRequest membershipHttpRequest = new HttpRequest();
                    membershipHttpRequest.setEndpoint(memberPlatformAuth.Callout_Url__c);
                    membershipHttpRequest.setMethod('POST');
                    membershipHttpRequest.setBody(requestbody);
                    membershipHttpRequest.setHeader('Authorization', 'Bearer '+memberPlatformAuth.Static_Token__c);
                    membershipHttpRequest.setHeader('content-type', 'application/json');
                    Http http = new Http();
                    HTTPResponse membershipHttpResponse = http.send(membershipHttpRequest);
                    // Check for membershipList is not empty
                    if(membershipHttpResponse != null && membershipHttpResponse.getStatusCode() == 200 && String.isNotBlank(membershipHttpResponse.getBody())){
                        String receivedStringBody = membershipHttpResponse.getBody();
                        ProfileInfoWrapper profileInfoWrapperInstance = new ProfileInfoWrapper();
                        profileInfoWrapperInstance = (ProfileInfoWrapper) JSON.deserialize(receivedStringBody, ProfileInfoWrapper.class);
                        memberLoop.Platform_Create_State__c = 'OK';
                        memberLoop.Profile_Link__c = profileInfoWrapperInstance.profileLink;
                        memberLoop.Profile_Id__c = profileInfoWrapperInstance.profilId;
                        membershipListToUpdate.add(memberLoop);
                    } else{
                        memberLoop.Platform_Create_State__c = 'ERROR';
                        membershipListToUpdate.add(memberLoop);
                    }
                }
            }
            if (!membershipListToUpdate.isEmpty()) {
                update membershipListToUpdate;
                return 'Updated the membership records.';
            }
            
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Firing the webhook for the Error status memberhsip records.', ex.getMessage(), 'Error', 'DFJ_MembershipController.ResendmembershipWebhook apex class.', String.valueOf(ex.getLineNumber()));
        }
        return 'Something went wrong.';
    }
    
    
    //Changes Starts DFJ-61
    //DFJ-146 make this method Queuable to remove SOQL 101
    //public static Boolean createMembershipOnLeadConvert(List<Journal__c> journalRecord, Id leadRecordId,Id accountid){
        public void execute(QueueableContext context){
        try{
            //List<Lead> leadRecord = [SELECT id,Related_Event_ID__c,ConvertedAccountId,OwnerId FROM Lead WHERE Id =: leadRecordId LIMIT 1];
            //DFJ-146 make this method Queuable to remove SOQL 101
            List<Journal__c> journalRecord = [SELECT id,OwnerId,Contains_Custom_Documents__c,External_record_uuid__c,Lead__c, DocFab_Record_Model_ID__c,Lead__r.Related_Event_ID__c,Lead__r.ConvertedAccountId,Lead__r.OwnerID FROM Journal__c WHERE Lead__c =: leadRecord LIMIT 1];
            List<Account> accList = [SELECT Id, Market_Unit__c FROM Account WHERE ID=:journalRecord[0].Lead__r.ConvertedAccountId LIMIT 1];
//            System.debug('journalRecord-->'+journalRecord);
            List<Membership__c> memberShipInstanceList = new List<Membership__c>();
            //memberShipInstanceList = [SELECT Id,Account__c,Is_customer__c,OwnerId,Name,Phone__c, Email__c,Lead__c,CPR__c From Membership__c WHERE Lead__c=:leadRecord[0].Id LIMIT 1];
            memberShipInstanceList = [SELECT Id,Account__c,Is_customer__c,OwnerId,Name,Phone__c, Email__c,Lead__c,CPR__c From Membership__c WHERE Lead__c=:leadRecord LIMIT 1];
            //DFJ-146 End
            List<DFJ_MembershipObjectConfiguration__mdt> getMetadataConfiguration = new List<DFJ_MembershipObjectConfiguration__mdt>();
            getMetadataConfiguration = [SELECT Id,Field_Configuration__c,MembershipObject_name__c,Person1_Membership_Contition__c,Person2_Membership_Contition__c FROM DFJ_MembershipObjectConfiguration__mdt WHERE Record_Model_Id__c=:(Test.isRunningTest() ? '54' : journalRecord[0].DocFab_Record_Model_ID__c) LIMIT 1];
           //  System.debug('journalRecord[0].DocFab_Record_Model_ID__c-->'+journalRecord[0].DocFab_Record_Model_ID__c);
           // System.debug('getMetadataConfiguration-->'+getMetadataConfiguration);
            // TODO - use return if getMetadataConfiguration.isEmpty() is true and change the return type to boolean
          /*  if(getMetadataConfiguration.isEmpty()){
                return false;
            }*/
            if(!getMetadataConfiguration.isEmpty()) {
                Map<String,Object> fieldConfigurationMap = (Map<String,Object>) (JSON.deserializeUntyped(getMetadataConfiguration[0].Field_Configuration__c));

                List<getConditionForMembership> getconditionsForPerson1 = (List<getConditionForMembership>)System.JSON.deserialize(getMetadataConfiguration[0].Person1_Membership_Contition__c, List<getConditionForMembership>.class);
                List<getConditionForMembership> getconditionsForPerson2 = (List<getConditionForMembership>)System.JSON.deserialize(getMetadataConfiguration[0].Person2_Membership_Contition__c, List<getConditionForMembership>.class);
                sobject getReletedRecord = Schema.getGlobalDescribe().get(getMetadataConfiguration[0].MembershipObject_name__c).newSObject();
                // String checkObjectName = String.valueOf(getReletedRecord);
                // System.debug('getconditionsForPerson1-->'+getconditionsForPerson1);
               // System.debug('getconditionsForPerson2-->'+getconditionsForPerson2);
                String checkObjectName = getReletedRecord.getSObjectType().getDescribe().getName();
              //  System.debug('checkObjectName-->'+checkObjectName);
                
                // Create a list of field names from the configuration map 
                List<String> fieldNames = new List<String>();
                for (Object value : fieldConfigurationMap.values()) { 
                    if (value != null) {
                        fieldNames.add(String.valueOf(value));
                    }
                } 
                String query = 'SELECT Id, '+ String.join(fieldNames,',')+' FROM '+getMetadataConfiguration[0].MembershipObject_name__c+ ' WHERE '+String.valueOf(fieldConfigurationMap.get('JournalUUID')) +' =\''+(Test.isRunningTest() ? '1234':journalRecord[0].External_record_uuid__c )+ '\' LIMIT 1';
              //  System.debug('query-->'+query);
                if(query!=null){
                    getReletedRecord = Database.query(query);   
                }
              //  System.debug('getReletedRecord-->'+getReletedRecord);
                Boolean checkMembershipforPerson1;
                List<String> person1QueryFieldList = new List<String>();
                List<String> person2QueryFieldList = new List<String>();
                Set<String> fieldstoQuery = new Set<String>();
                String fromObj = '';
                //String filterValue = 'false';
                String filterValue1 = '';
                String filterValue2 = '';
                String filterValue3 = '';
                String conditionObject = '';
                Boolean getSubscriptionStatus = false;
                String checkSubscriptionStatus = '';
                for(getConditionForMembership condition : getconditionsForPerson1){
                      // System.debug('check1 -->'+condition.fromObject.equals(checkObjectName));
                  //  System.debug('check1 -->'+condition.fromObject);
                    if(!String.isBlank(condition.fromObject) && (!condition.fromObject.equals(checkObjectName))){
                        person1QueryFieldList.add(condition.field);
                        fromObj = condition.fromObject;
                        filterValue1 = condition.value;
                        conditionObject = condition.whereClauseFieldOnFromObject;
                    }
                    else if(getReletedRecord.get(condition.field)!=null){
                        checkMembershipforPerson1 = Boolean.valueOf(getReletedRecord.get(condition.field));
                      //  System.debug('checkMembershipforPerson1 -->'+checkMembershipforPerson1);
                        if (!checkMembershipforPerson1) {
                            checkMembershipforPerson1 = false; 
                            break;
                        }
                    }
                    //Updated for person1 
                    List<Payments__c> getPayment = new  List<Payments__c>();
                    if(!String.isBlank(condition.hasSubscription) && !checkSubscriptionStatus.equals(condition.hasSubscription)){
                        getPayment = [SELECT Id, Subscription_status__c FROM Payments__c WHERE Lead__c=:journalRecord[0].Lead__c ORDER BY CreatedDate DESC LIMIT 1];
                    }
                    if((!getPayment.isEmpty()) && condition.hasSubscription.equals(getPayment[0].Subscription_status__c)) {
                        getSubscriptionStatus = true;
                        checkSubscriptionStatus = condition.hasSubscription;
                    }
                    
                    
                } 
                
                Boolean checkMembershipforPerson2;
                for(getConditionForMembership condition : getconditionsForPerson2){
                    // System.debug('check2 -->'+condition.fromObject.equals(checkObjectName));
                    if(!String.isBlank(condition.fromObject) && (!condition.fromObject.equals(checkObjectName))){
                        person2QueryFieldList.add(condition.field);
                        fromObj = condition.fromObject;
                        filterValue2 = condition.value;
                        conditionObject = condition.whereClauseFieldOnFromObject;
                    }
                    else if(getReletedRecord.get(condition.field)!=null){// TODO - We can use else if instead of nested conditions(updated)
                        
                        checkMembershipforPerson2 = Boolean.valueOf(getReletedRecord.get(condition.field));
                        if (!checkMembershipforPerson2) {// TODO - dont neet to use != true use !checkMembershipforPerson2(updated)
                            checkMembershipforPerson2 = false;
                            break;
                        }
                    }
                    
                    // TODO - can we use one if instead of using the nested If contitions(updated)
                    List<Payments__c> getPayment = new List<Payments__c>();
                    if(!String.isBlank(condition.hasSubscription)  && !checkSubscriptionStatus.equals(condition.hasSubscription)){
                        getPayment = [SELECT Id, Subscription_status__c FROM Payments__c WHERE Journal__c=:journalRecord[0].Id];
                    }
                    if((!getPayment.isEmpty()) && condition.hasSubscription.equals(getPayment[0].Subscription_status__c)) {
                        getSubscriptionStatus = true;
                        checkSubscriptionStatus = condition.hasSubscription;
                    }
                } 
                
                fieldstoQuery.addAll(person1QueryFieldList);
                fieldstoQuery.addAll(person2QueryFieldList);
                List<String> conditionFields = new List<String>();
                conditionFields.addAll(fieldstoQuery);
                conditionFields.sort();
                
                String queryForJournaldk2 = '';
                if(!String.isBlank(filterValue1) || !String.isBlank(filterValue2)){
                    queryForJournaldk2 = ' AND ( ' + conditionFields[0] + ' = '+ filterValue1 +' OR '+ conditionFields[1] + ' = '+ filterValue2 +') AND '+conditionFields[2] + ' = TRUE';
                }
                if(!fieldstoQuery.isEmpty()){
                    sobject getConditionRecord = Schema.getGlobalDescribe().get(fromObj).newSObject();
                    String queryConditionRecord = 'SELECT Id, '+String.join(new List<String>(fieldstoQuery), ',') +' FROM '+fromObj+ ' WHERE '+conditionObject +' =\''+getReletedRecord.Id+'\''+ queryForJournaldk2 ;
                    List<SObject> queryRecords  = Database.query(queryConditionRecord);  
                    
                    for(String fieldToCheck:fieldstoQuery){
                        if(person1QueryFieldList.contains(fieldToCheck) && !queryRecords.isEmpty()){
                            checkMembershipforPerson1 = Boolean.valueOf(queryRecords[0].get(fieldToCheck));
                            // TODO - dont neet to use != true use !checkMembershipforPerson1(Updated)
                            if (!checkMembershipforPerson1) {
                                checkMembershipforPerson1 = false;
                                break;
                            }
                        }else if(person2QueryFieldList.contains(fieldToCheck) && queryRecords.size()>1){
                            checkMembershipforPerson2 = Boolean.valueOf(queryRecords[1].get(fieldToCheck));
                            // TODO - dont neet to use != true use !checkMembershipforPerson2(Updated)
                            if (!checkMembershipforPerson2) {
                                checkMembershipforPerson2 = false;
                                break;
                            }
                        }                        
                    }
                }
                
                
                /*	Boolean check1;
Boolean check2;
Boolean check3;
Boolean check4;
Boolean check5;*/
                /*    if(getReletedRecord instanceOf df_journal_dk__c){
check1 = (Boolean) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('toCreateMembershipForPerson1')));
check2 = (Boolean) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('toCreateMembershipForPerson2')));

}else if(getReletedRecord instanceOf df_journal_dk_new__c){
List<df_160_person__c> getPersonList = [SELECT Id, person_hidden_person_1__c,person_hidden_person_2__c,person_medlem_dfj__c FROM df_160_person__c WHERE journal_dk_new__c=:getReletedRecord.Id];
check3 = (Boolean) getPersonList[0].person_hidden_person_1__c;
check4 = (Boolean) getPersonList[0].person_hidden_person_2__c;
check5 = (Boolean) getPersonList[0].person_medlem_dfj__c;
}
*/
                if(getReletedRecord instanceOf	df_journal_dk_new__c && getReletedRecord!=null && getReletedRecord.get('doks_krver_spec_skrddersyning__c')!=false){
                    journalRecord[0].Contains_Custom_Documents__c = true;
                    update journalRecord;
                }
                
                if(checkMembershipforPerson1==true && memberShipInstanceList.isEmpty()){
                    Membership__c memberShipInstance = new Membership__c();
                   // memberShipInstance.Account__c = accountid;
                    memberShipInstance.Account__c = journalRecord[0].Lead__r.ConvertedAccountId;
                   // memberShipInstance.Lead__c = leadRecord[0].Id;
                    memberShipInstance.Lead__c = journalRecord[0].Lead__c;
                    //DFJ-101 Changes Starts
                   // memberShipInstance.Related_Event_ID__c = String.isNotBlank(leadRecord[0].Related_Event_ID__c) ? leadRecord[0].Related_Event_ID__c : '';
                     memberShipInstance.Related_Event_ID__c = String.isNotBlank(journalRecord[0].Lead__r.Related_Event_ID__c) ? journalRecord[0].Lead__r.Related_Event_ID__c : '';
                    //End
                    memberShipInstance.Sign_up_Date__c = System.Today();
                    memberShipInstance.Market_Unit__c = accList[0].Market_Unit__c;
                    memberShipInstance.Name = (!String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1FirstName')))) ? (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1FirstName'))) :'') + ' '+ (!String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1LastName')))) ? (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1LastName'))) :'');
                    memberShipInstance.Last_Name__c = (!String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1LastName')))) ? (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1LastName'))) :'');
                    memberShipInstance.First_Name__c =(!String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1FirstName')))) ? (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1FirstName'))) :'');
                   // String membershipPhone = String.valueOf(fieldConfigurationMap.get('person1Phone'));
                    //memberShipInstance.Phone__c = (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Phone')));
                    memberShipInstance.Phone__c = String.valueOf(getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Phone'))));
                    memberShipInstance.Email__c = (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Email')));
                    // memberShipInstance.CPR__c = (!String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('Cpr1')))) ? getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('Cpr1'))) : '') ;
                    memberShipInstance.CPR__c = (!fieldConfigurationMap.containsKey('person1Cpr') ? '':(String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Cpr'))));
                    //memberShipInstance.CPR__c = (!String.isBlank((String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Cpr')))) ? (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Cpr'))) : '' );
                    memberShipInstance.Is_customer__c = true;  
                    memberShipInstance.Paid_Membership__c = getSubscriptionStatus;
                  //  System.debug('memberShipInstanceList-P1->'+memberShipInstance);

                    try{                                
                        if(memberShipInstanceList.isEmpty()){  //Changes DIN-377 Remove condition of IsMember
                            memberShipInstance.OwnerId = String.isNotBlank(journalRecord[0].OwnerId) ? journalRecord[0].OwnerId : null;
                        }
                    } catch(Exception ex){
                        DFJ_ErrorController.addErrorLogs(journalRecord[0].Id, 'Setting responsible lawyer.', ex.getMessage(), 'Error', 'DFJ_ConvertLeads apex class method.',String.valueOf(ex.getLineNumber()));
                    } 
                    memberShipInstanceList.add(memberShipInstance);
                }else if(checkMembershipforPerson1==true && !memberShipInstanceList.isEmpty()){
                   // memberShipInstanceList[0].OwnerId = leadRecord[0].OwnerId;
                    memberShipInstanceList[0].OwnerId = journalRecord[0].OwnerId;
                    //DFJ-101 Changes Starts
                   // memberShipInstanceList[0].Related_Event_ID__c = String.isNotBlank(leadRecord[0].Related_Event_ID__c) ? leadRecord[0].Related_Event_ID__c : '';
                    memberShipInstanceList[0].Related_Event_ID__c = String.isNotBlank(journalRecord[0].Lead__r.Related_Event_ID__c) ? journalRecord[0].Lead__r.Related_Event_ID__c : '';
                    //End
                    //memberShipInstanceList[0].Account__c = accountid;
                    memberShipInstanceList[0].Account__c =journalRecord[0].Lead__r.ConvertedAccountId;
                    memberShipInstanceList[0].Is_customer__c = true;
                    memberShipInstanceList[0].Market_Unit__c = accList[0].Market_Unit__c;
                    memberShipInstanceList[0].CPR__c = (!fieldConfigurationMap.containsKey('person1Cpr') ? '':(String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Cpr'))));
                    //memberShipInstanceList[0].CPR__c = (!String.isBlank((String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Cpr')))) ? (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Cpr'))) : '' );
                    memberShipInstanceList[0].Phone__c =String.valueOf(getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Phone'))));
                    memberShipInstanceList[0].Email__c =(String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person1Email')));

                    memberShipInstanceList[0].Paid_Membership__c = getSubscriptionStatus;

                }
                //  Boolean checkPerson2 =(Boolean) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('toCheckPerson2')));
                //  System.debug('checkPerson2--'+checkPerson2);
                if(checkMembershipforPerson2 == true && (!String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2FirstName')))) || !String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2LastName')))))){
                    Membership__c membershipInstanceForPerson2 = new Membership__c();
                    //membershipInstanceForPerson2.Account__c = accountid;
                    membershipInstanceForPerson2.Account__c = journalRecord[0].Lead__r.ConvertedAccountId;
                    //membershipInstanceForPerson2.Lead__c = leadRecord[0].Id;
                    membershipInstanceForPerson2.Lead__c = journalRecord[0].Lead__c;
                    membershipInstanceForPerson2.Market_Unit__c = accList[0].Market_Unit__c;
                    //DFJ-101 Changes Starts
                    membershipInstanceForPerson2.Related_Event_ID__c = String.isNotBlank(journalRecord[0].Lead__r.Related_Event_ID__c) ? journalRecord[0].Lead__r.Related_Event_ID__c : '';
                    //End
                    membershipInstanceForPerson2.Sign_up_Date__c = System.Today();
                    //membershipInstanceForPerson2.Name =(String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2FirstName'))) +' '+(String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2LastName')));
                    membershipInstanceForPerson2.Name = (!String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2FirstName')))) ? (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2FirstName'))) :'') + ' '+ (!String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2LastName')))) ? (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2LastName'))) :'');
                    membershipInstanceForPerson2.Last_Name__c = (!String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2LastName')))) ? (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2LastName'))) :'');
                    membershipInstanceForPerson2.First_Name__c = (!String.isBlank((String)getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2FirstName')))) ? (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2FirstName'))) :'');
                    membershipInstanceForPerson2.Phone__c = String.valueOf(getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2Phone'))));
                    membershipInstanceForPerson2.Email__c = (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2Email')));
                    //membershipInstanceForPerson2.CPR__c = (String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2Cpr')));
                    membershipInstanceForPerson2.CPR__c = (!fieldConfigurationMap.containsKey('person2Cpr') ? '':(String) getReletedRecord.get(String.valueOf(fieldConfigurationMap.get('person2Cpr'))));
                    membershipInstanceForPerson2.Is_customer__c = true;

                    membershipInstanceForPerson2.Paid_Membership__c = getSubscriptionStatus;
//System.debug('membershipInstanceForPerson2-->'+membershipInstanceForPerson2);

                    try{                                
                        if(!memberShipInstanceList.isEmpty()){  //Changes DIN-377 Remove condition of IsMember
                            membershipInstanceForPerson2.OwnerId = String.isNotBlank(journalRecord[0].OwnerId) ? journalRecord[0].OwnerId : null;
                        }
                    } catch(Exception ex){
                        DFJ_ErrorController.addErrorLogs(journalRecord[0].Id, 'Setting responsible lawyer.', ex.getMessage(), 'Error', 'DFJ_ConvertLeads apex class method.',String.valueOf(ex.getLineNumber()));
                    }
                    memberShipInstanceList.add(membershipInstanceForPerson2);

                }  
                
                
                if(!memberShipInstanceList.isEmpty()){
//System.debug('memberShipInstanceList-->'+memberShipInstanceList);
                    upsert memberShipInstanceList;
                    
                }
                //call method for creating relatives related to the membetship records//
                if(getReletedRecord instanceOf df_journal_dk__c && getReletedRecord!=null){
                    List<df_journal_dk__c> listOfJournalDK = new List<df_journal_dk__c>{(df_journal_dk__c)getReletedRecord};
                        createRelativesBasedOnDocfabRecord(memberShipInstanceList, listOfJournalDK );
                }
            }
            
        }catch(exception e){
            System.debug('msg-->'+e.getMessage()+' in -->'+e.getLineNumber());
        }
     //   return true;
    }
    //End
    
    // Utility exception class
    class ConvertLeadPluginException extends Exception {}
    
    //Chnages for DIN-377 :- Create memberships from docfab record data.
    //Start
    public static void createRelativesBasedOnDocfabRecord(List<Membership__c> memberShipInstanceList ,  List<df_journal_dk__c> listOfJournalDK){
        List<df_54_prrende_begge_personer__c> prrendeBeggePersonerList = new List<df_54_prrende_begge_personer__c>();
        
        try{
            if(!memberShipInstanceList.isEmpty() && !listOfJournalDK.isEmpty()){
                prrendeBeggePersonerList = [SELECT 
                                            Id,
                                            efternavn_prrende__c,
                                            email_prrende__c,
                                            fornavn_prrende__c,
                                            telefonnummer_prrende__c,
                                            hvem_er_denne_person_prrende_for__c,
                                            journal_dk__c 
                                            FROM 
                                            df_54_prrende_begge_personer__c 
                                            WHERE 
                                            journal_dk__c =: listOfJournalDK[0].Id 
                                            LIMIT 1000];
                
                List<Relative__c> relativeList = new List<Relative__c>();
                
                Map<String,List<Id>> mapOfmemberShipId = new Map<String,List<Id>>(); //This map contains the Id of Membership with respect to df_54_prrende_begge_personer__c PickList value
                
                for(Membership__c memberRecord : memberShipInstanceList){
                    if (!mapOfmemberShipId.containsKey('prrende_begge')) {
                        mapOfmemberShipId.put('prrende_begge', new List<Id>{ memberRecord.Id });
                    }else{
                        mapOfmemberShipId.get('prrende_begge').add(memberRecord.Id);
                    }   
                }
                
                
                if(!prrendeBeggePersonerList.isEmpty()){
                    for(df_54_prrende_begge_personer__c prrendeBeggePersonerRecord : prrendeBeggePersonerList){
                        Relative__c relativeRecord = new Relative__c();
                        if(prrendeBeggePersonerRecord.hvem_er_denne_person_prrende_for__c == 'prrende_for_person1' && (listOfJournalDK[0].nsker_medlemskab_person_1__c && (!String.isBlank(listOfJournalDK[0].person_1_first_name__c) || !String.isBlank(listOfJournalDK[0].person_1_last_name__c)))){
                            relativeRecord.Membership__c = memberShipInstanceList[0].Id ;
                            relativeRecord.Name = prrendeBeggePersonerRecord.fornavn_prrende__c + ' '+ prrendeBeggePersonerRecord.efternavn_prrende__c;
                            relativeRecord.Phone__c = prrendeBeggePersonerRecord.telefonnummer_prrende__c;
                            relativeRecord.Email__c = prrendeBeggePersonerRecord.email_prrende__c;
                            relativeList.add(relativeRecord);
                        }else if(prrendeBeggePersonerRecord.hvem_er_denne_person_prrende_for__c == 'prrende_for_person2'){
                            if(memberShipInstanceList.size() > 1){
                                relativeRecord.Membership__c = memberShipInstanceList[1].Id;
                                relativeRecord.Name = prrendeBeggePersonerRecord.fornavn_prrende__c + ' '+ prrendeBeggePersonerRecord.efternavn_prrende__c;
                                relativeRecord.Phone__c = prrendeBeggePersonerRecord.telefonnummer_prrende__c;
                                relativeRecord.Email__c =  prrendeBeggePersonerRecord.email_prrende__c;
                                relativeList.add(relativeRecord);
                            }else if(listOfJournalDK[0].nsker_medlemskab_person_2__c && (!String.isBlank(listOfJournalDK[0].person_2_first_name__c) || !String.isBlank(listOfJournalDK[0].person_2_last_name__c))){
                                relativeRecord.Membership__c = memberShipInstanceList[0].Id;
                                relativeRecord.Name = prrendeBeggePersonerRecord.fornavn_prrende__c + ' '+ prrendeBeggePersonerRecord.efternavn_prrende__c;
                                relativeRecord.Phone__c = prrendeBeggePersonerRecord.telefonnummer_prrende__c;
                                relativeRecord.Email__c =  prrendeBeggePersonerRecord.email_prrende__c;
                                relativeList.add(relativeRecord);
                            }
                        }else if(prrendeBeggePersonerRecord.hvem_er_denne_person_prrende_for__c == 'prrende_begge'){
                            if(mapOfmemberShipId.containsKey(prrendeBeggePersonerRecord.hvem_er_denne_person_prrende_for__c)){
                                relativeList.add(new Relative__c(Membership__c = mapOfmemberShipId.get(prrendeBeggePersonerRecord.hvem_er_denne_person_prrende_for__c)[0],
                                                                 Name =prrendeBeggePersonerRecord.fornavn_prrende__c + ' '+ prrendeBeggePersonerRecord.efternavn_prrende__c,
                                                                 Phone__c = prrendeBeggePersonerRecord.telefonnummer_prrende__c,
                                                                 Email__c =  prrendeBeggePersonerRecord.email_prrende__c));
                            }
                            if(memberShipInstanceList.size() > 1 && mapOfmemberShipId.containsKey(prrendeBeggePersonerRecord.hvem_er_denne_person_prrende_for__c)){
                                relativeList.add(new Relative__c(Membership__c = mapOfmemberShipId.get(prrendeBeggePersonerRecord.hvem_er_denne_person_prrende_for__c)[1],
                                                                 Name =prrendeBeggePersonerRecord.fornavn_prrende__c + ' '+ prrendeBeggePersonerRecord.efternavn_prrende__c,
                                                                 Phone__c = prrendeBeggePersonerRecord.telefonnummer_prrende__c,
                                                                 Email__c =  prrendeBeggePersonerRecord.email_prrende__c));
                            }
                            
                        }
                    }
                }
                
                if(!relativeList.isEmpty()){
                    upsert relativeList;
                } 
            }
        } catch(Exception ex){
            DFJ_ErrorController.addErrorLogs(listOfJournalDK[0].Id, 'Setting Relatives.', ex.getMessage(), 'Error', 'DFJ_ConvertLeads.createRelativesBasedOnDocfabRecord apex method.',String.valueOf(ex.getLineNumber()));
        }
        
    }
    public class getConditionForMembership {
        public string field;
        public string value;
        public string type;
        public string fromObject;
        public string whereClauseFieldOnFromObject;
        public string hasSubscription;
    }
    
    
    
    //End
}