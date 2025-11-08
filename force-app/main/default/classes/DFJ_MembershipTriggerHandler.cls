/*
   * @Version : 1.0
   * @Created Date : 2021-09-29
   * @Description : This class will be used for handling trigger methods.
*/
public without sharing class DFJ_MembershipTriggerHandler {
     
    /*
     * @Description  This method will be invoked when new membership is created and is creating a membership request body.
     * @Param        List<Membership__c>
     * @Return       void
     * Event -       After Insert
    */
    public static void SetMembershipBody(List<Membership__c> membershipList){
        try{
            // Changes for DIN-213 : Set language in membership callout based on the market unit.
            // Start
            //Changes DIN-377
            //Start
         
            // Set<Id> Ids = new Set<Id>();
            // for(Membership__c membershipRecords : membershipList){
            //     Ids.add(membershipRecords.Id);
            // } 
            // String membersipIds = String.valueof(Ids).removeStart('{').removeEnd('}');
           
            //End
            List<Account> relatedAccountToMembership = new List<Account>();
            relatedAccountToMembership = [SELECT Id,Market_Unit__c FROM Account WHERE Id =: membershipList[0].Account__c LIMIT 1];
            String language = (!relatedAccountToMembership.isEmpty() && !String.isBlank(relatedAccountToMembership[0].Market_Unit__c)) ? (relatedAccountToMembership[0].Market_Unit__c.equals('DFJ_DK') || relatedAccountToMembership[0].Market_Unit__c.equals('Testamente_DK')) ? 'DK' : (relatedAccountToMembership[0].Market_Unit__c.equals('FA_SE') || relatedAccountToMembership[0].Market_Unit__c.equals('Testamente_SV')) ? 'SE' : '' : '';
            if (String.isBlank(language)) {
                List<Lead> LeadListForLanguage = new List<Lead>();
                String memberLeadId = membershipList[0].Lead__c;
                String query = 'SELECT Id,Market_Unit__c FROM Lead WHERE Id=\''+memberLeadId +'\'';

                LeadListForLanguage = Database.query(query);
                language = (!LeadListForLanguage.isEmpty() && !String.isBlank(LeadListForLanguage[0].Market_Unit__c)) ? (LeadListForLanguage[0].Market_Unit__c.equals('DFJ_DK') || LeadListForLanguage[0].Market_Unit__c.equals('Testamente_DK')) ? 'DK' : (LeadListForLanguage[0].Market_Unit__c.equals('FA_SE') || LeadListForLanguage[0].Market_Unit__c.equals('Testamente_SV')) ? 'SE' : '' : '';
            }
            if (String.isBlank(language)) {
                DFJ_ErrorController.addErrorLogs('Membership Id -> '+membershipList[0].Id, 'Checking for the language is blank.', 'Unable to set language setting blank value.', 'Warning', 'DFJ_MembershipTriggerHandler.SetMembershipBody apex class.', '');
            }
            // Stop 
            //Changes TCS-27
            //Start
            String requestbody = '';
            for(Membership__c memberShipRecord : membershipList)
            { 
                requestbody = ConstructRequestBody(new List<Membership__c>{memberShipRecord},language,relatedAccountToMembership.isEmpty(),'set membership body');
                DFJ_MembershipController.PostMembershipDataToPlatform(requestbody,memberShipRecord.Id);
            }
            //End
            if(Test.isRunningTest()){
                if(membershipList[0].Name.contains('Test2')){
                    requestbody = '';
                    
                }
            }
            //Chnages DIN-377
            //Start
         
            //DFJ_MembershipController.PostMembershipDataToPlatform(requestbody,membersipIds);
            //End
          
        } catch(Exception exp){
            DFJ_ErrorController.addErrorLogs('Membership Id -> '+membershipList[0].Id, 'Set membership body to be sent.', exp.getMessage(), 'Error', 'DFJ_MembershipTriggerHandler.SetMembershipBody apex class.', String.valueOf(exp.getLineNumber()));
        }
    }

    public static String ValidateProperty(String propertyName,String propertyValue,Boolean accountEmptyOrNot){
        if (propertyName.equals('responsibleAgent') && (!String.isBlank(propertyValue) && propertyValue.equals('Imported (No owner)') || accountEmptyOrNot)) {
            return '"responsibleAgent":null';
        }
        return '"'+propertyName+'":"'+(!String.isBlank(propertyValue) ? propertyValue : '' )+'"';
    }

    public static String  ConstructRequestBody  (List<Membership__c> membershipList,String language,Boolean accountEmptyOrNot,String calledFrom){
        try {
            List<Membership__c> memberToSetResponsibleOwner = new List<Membership__c>();
            if (!calledFrom.equals('resend webhook')) {
                memberToSetResponsibleOwner = [Select Id,Name,Owner.Name,CreatedBy.Name FROM Membership__c WHERE Id =: membershipList[0].Id LIMIT 1];
            }else{
                memberToSetResponsibleOwner.addall(membershipList);
            }
       
        //Changes DIN-377 Create Membership from docfab record data
        //Start
         //Changes TCS-27
        //Start
            String requestbody ='{';     
            requestbody += ValidateProperty('first_name', membershipList[0].First_Name__c,accountEmptyOrNot) + ',';
            requestbody += ValidateProperty('last_name', membershipList[0].Last_Name__c,accountEmptyOrNot) + ',';
            requestbody += ValidateProperty('country',language,accountEmptyOrNot) + ',';
            requestbody += ValidateProperty('language', language,accountEmptyOrNot) + ',';
            requestbody += ValidateProperty('email', membershipList[0].Email__c,accountEmptyOrNot)+ ',';
            requestbody += ValidateProperty('responsibleAgent', (memberToSetResponsibleOwner.isEmpty() ? 'Imported (No owner)' : memberToSetResponsibleOwner[0].Owner.Name) , accountEmptyOrNot )+ ',';
            requestbody += ValidateProperty('phone_number',String.valueOf(membershipList[0].Phone__c),accountEmptyOrNot)+ ',';
            requestbody += ValidateProperty('membershipObjectId', membershipList[0].Id,accountEmptyOrNot)+ ',';
            requestbody += ValidateProperty('Is_Customer', String.valueOf(membershipList[0].Is_customer__c),accountEmptyOrNot);
            requestbody += '}';

            System.debug('membership requestbody>>> '+requestbody);
            return requestbody;
        //End
        //End
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('Membership Id -> '+membershipList[0].Id, 'Constructing requestbody.', ex.getMessage(), 'Error', 'DFJ_MembershipTriggerHandler.ConstructRequestBody apex class.', String.valueOf(ex.getLineNumber()));
        }
        return '';
    }

}