/*
   * @Version : 1.0
   * @Created Date : 2021-09-22
   * @Description : This class will be used for utilities methods for membership.
*/
public without sharing class DFJ_Utility {

    /*
     * @Description  This method will authorize the IP address from the request.
     * @Param        remoteAddess,token
     * @Return       Boolean
    */
    public static Boolean AuthorizeUser(String remoteAddress,String token){
        try {
            if (String.isBlank(token)) {
                DFJ_ErrorController.addErrorLogs(remoteAddress, 'Authorizing the token.', 'Token not found Please send token in request header.', 'Warning', 'DFJ_Utility.AuthorizeUser apex class.', '');
                return false;
            }
            Boolean isSandboxEnv = [SELECT IsSandbox FROM Organization LIMIT 1]?.IsSandbox;
            String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
            DFJ_Membership_Authorizer__mdt membershipIpAuthorizer = new DFJ_Membership_Authorizer__mdt();
            // Checking if isSandboxEnv is true checking for dinsweden or sandbox org and getting dinsweden or membership metadata type record
            // else getting metadata type record of production.
            membershipIpAuthorizer = isSandboxEnv ? baseUrl.contains('dinsweden') ? DFJ_Membership_Authorizer__mdt.getInstance('Dinsweden_Sandbox') : baseUrl.contains('membership') ? DFJ_Membership_Authorizer__mdt.getInstance('Membership_Sandbox') : null :DFJ_Membership_Authorizer__mdt.getInstance('TokenIPAuth');
            if (Test.isRunningTest()) {
                membershipIpAuthorizer = DFJ_Membership_Authorizer__mdt.getInstance('Test');
            }
            if (membershipIpAuthorizer == null || String.isBlank(membershipIpAuthorizer.IP_Address__c) || String.isBlank(remoteAddress)) {
                DFJ_ErrorController.addErrorLogs(remoteAddress, 'Authorizing the user IP.', 'IP not authorized some empty value in remote address or field.', 'Warning', 'DFJ_Utility.AuthorizeUser apex class.', '');
                return false;
            }
            
            if (membershipIpAuthorizer.IP_Address__c.contains(remoteAddress) && membershipIpAuthorizer.Static_Token__c.equals(token)) {
                return true;
            }
            DFJ_ErrorController.addErrorLogs(remoteAddress, 'Authorizing the user IP and static token.', 'IP or token not matched.', 'Warning', 'DFJ_Utility.AuthorizeUser apex class.', '');
            return false;
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Authorizing the user token and IP.', 'Exception occured in AuthorizeUser method.', 'Error', 'DFJ_Utility.AuthorizeUser apex class.', String.valueOf(ex.getLineNumber()));
            return false;
        }
    }

    /*
     * @Description  This method is get the membership record.
     * @Param        membreshipId
     * @Return       ResponseReturnWrapper
    */
    public static ResponseReturnWrapper GetMembership(String membershipId){
        ResponseReturnWrapper responseReturnWrapperInstance = new ResponseReturnWrapper();
        try {
            if (String.isBlank(membershipId)) {
                DFJ_ErrorController.addErrorLogs('', 'Get the membership record.', 'NULL/Empty Id(s) in the request parameters', 'Warning', 'DFJ_Utility.GetMembership apex class.','');
                return CreateReturnResponse('Bad request.',400);
            }
            List<Membership__c> membershipList = new List<Membership__c>();
            membershipList = [SELECT  Id, Name, First_Name__c, Last_Name__c, Email__c,Owner.Email, Responsible_Lawyer__r.Name, Phone__c, Profile_Link__c,  Sign_up_Date__c FROM Membership__c WHERE Id = :membershipId LIMIT 1];

            if (membershipList.isEmpty()) {
                DFJ_ErrorController.addErrorLogs('membershipId -> '+membershipId, 'Get the membership record.', 'membershipList is empty while fetching records.', 'Warning', 'DFJ_Utility.GetMembership apex class.','');
                responseReturnWrapperInstance = CreateReturnResponse('Not found.',404);
                return responseReturnWrapperInstance;
            }
            SubscriberWrapper subscriberWrapperInstance = new SubscriberWrapper();
            //subscriberWrapperInstance.name = membershipList[0].Name;
            subscriberWrapperInstance.first_name = String.isBlank(membershipList[0].First_Name__c) ? '' : membershipList[0].First_Name__c;
            subscriberWrapperInstance.last_name = String.isBlank(membershipList[0].Last_Name__c) ? '' : membershipList[0].Last_Name__c;
            subscriberWrapperInstance.email = String.isBlank(membershipList[0].Email__c) ? '': membershipList[0].Email__c;
            subscriberWrapperInstance.responsible_lawyer = String.isBlank(membershipList[0].Responsible_Lawyer__r.Name)? '': membershipList[0].Responsible_Lawyer__r.Name;
            // DIN-281 : Add ResponsibleAgentEmail field to membership API response.
            // Description : Added responsilbe agent mail.
            // Start
            subscriberWrapperInstance.responsible_agent_email = String.isBlank(membershipList[0].Owner.Email)? '': membershipList[0].Owner.Email;
            // End
            subscriberWrapperInstance.phone_number = String.isBlank(membershipList[0].Phone__c) ? '' : membershipList[0].Phone__c;
            subscriberWrapperInstance.profile_link = String.isBlank(membershipList[0].Profile_Link__c) ? '' : membershipList[0].Profile_Link__c;
            subscriberWrapperInstance.signup_date = String.valueOf(membershipList[0].Sign_up_Date__c);
            subscriberWrapperInstance.language = 'DK';
            //responseReturnWrapperInstance = membershipList.isEmpty() ? CreateReturnResponse('Not found.',404) : CreateReturnResponse(JSON.serialize(membershipList),200);
            responseReturnWrapperInstance = CreateReturnResponse(JSON.serialize(subscriberWrapperInstance), 200);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('Membership Id -> '+membershipId, 'Get the membership record.', ex.getMessage(), 'Error', 'DFJ_Utility.GetMembership apex class.', String.valueOf(ex.getLineNumber()));
            responseReturnWrapperInstance = CreateReturnResponse('Server error.',500);

        }
        return responseReturnWrapperInstance;

    }

    /*
     * @Description  This method is to get particular relative.
     * @Param        membershipId, relativeId
     * @Return       ResponseReturnWrapper
    */
    public static ResponseReturnWrapper GetSingleRelative(String membershipId, String relativeId){
        ResponseReturnWrapper responseReturnWrapperInstance = new ResponseReturnWrapper();
        try {
            if(String.isBlank(membershipId) || String.isBlank(relativeId)){
                DFJ_ErrorController.addErrorLogs('', 'Get the relative record.', 'NULL/Empty Id(s) in the request parameters', 'Warning', 'DFJ_Utility.GetSingleRelative apex class.','');
                return CreateReturnResponse('Bad request.',400);
            }
            List<Relative__c> relativeList = new List<Relative__c>();
            relativeList = [SELECT Id, Name, Email__c, Phone__c, Membership__c FROM Relative__c WHERE Id = :relativeId And Membership__c = :membershipId LIMIT 1];

            if (relativeList.isEmpty()) {
                DFJ_ErrorController.addErrorLogs('relativeId ->'+relativeId, 'Get the relative record.', 'relativeList is empty while fetching records.', 'Warning', 'DFJ_Utility.GetSingleRelative apex class.','');
                responseReturnWrapperInstance = CreateReturnResponse('Not found.',404);
                return responseReturnWrapperInstance;
            }
            RelativeWrapper RelativeWrapperInstance = new RelativeWrapper();
            // Changes for ticket DIN-202 : Add Id to relative API response 
            // Start
            // Description - Added the relativeObect Id in the response
            RelativeWrapperInstance.relativeObjectId = relativeList[0].Id;
            // End
            RelativeWrapperInstance.name = relativeList[0].Name;
            RelativeWrapperInstance.email = String.isBlank(relativeList[0].Email__c) ? '' : relativeList[0].Email__c;
            RelativeWrapperInstance.phone_number = String.isBlank(relativeList[0].Phone__c) ? '' : relativeList[0].Phone__c;

            responseReturnWrapperInstance = CreateReturnResponse(JSON.serialize(RelativeWrapperInstance), 200);
            //responseReturnWrapperInstance = relativeList.isEmpty() ? CreateReturnResponse('Not found.',404) : CreateReturnResponse(JSON.serialize(relativeList),200);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('Relative Id -> '+relativeId, 'Get the relative record.', ex.getMessage(), 'Error', 'DFJ_Utility.GetSingleRelative apex class.', String.valueOf(ex.getLineNumber()));
            responseReturnWrapperInstance = CreateReturnResponse('Server error.',500);
        }
        return responseReturnWrapperInstance;

    }

    /*
     * @Description  This method is to get relatives.
     * @Param        membershipId
     * @Return       ResponseReturnWrapper
    */
    public static ResponseReturnWrapper GetRelatives(String membershipId){
        ResponseReturnWrapper responseReturnWrapperInstance = new ResponseReturnWrapper();
        try {
            if (String.isBlank(membershipId)) {
                DFJ_ErrorController.addErrorLogs('', 'Get the relative records.', 'NULL/Empty Id(s) in the request parameters', 'Warning', 'DFJ_Utility.GetRelatives apex class.','');
                return CreateReturnResponse('Bad request.',400);
            }
            List<Relative__c> relativeList = new List<Relative__c>();

            relativeList = [SELECT Id, Name, Email__c, Phone__c, Membership__c FROM Relative__c WHERE Membership__c = :membershipId LIMIT 50000];

            if (relativeList.isEmpty()) {
                DFJ_ErrorController.addErrorLogs('membershipId -> '+membershipId, 'Get the relative records.', 'relativeList is empty while fetching records.', 'Warning', 'DFJ_Utility.GetRelatives apex class.','');
                responseReturnWrapperInstance = CreateReturnResponse('Not found.',404);
                return responseReturnWrapperInstance;
            }

            List<RelativeWrapper> RelativeWrapperList = new List<RelativeWrapper>();
            for (Relative__c relativeLoop : relativeList) {
                RelativeWrapper RelativeWrapperInstance = new RelativeWrapper();
                // Changes for ticket DIN-202 : Add Id to relative API response 
                // Start
                // Description - Added the relativeObect Id in the response
                RelativeWrapperInstance.relativeObjectId = relativeLoop.Id;
                // End
                RelativeWrapperInstance.name = relativeLoop.Name;
                RelativeWrapperInstance.email = String.isBlank(relativeLoop.Email__c) ? '' : relativeLoop.Email__c;
                RelativeWrapperInstance.phone_number = String.isBlank(relativeLoop.Phone__c) ? '' : relativeLoop.Phone__c;
                RelativeWrapperList.add(RelativeWrapperInstance);
            }
            responseReturnWrapperInstance = CreateReturnResponse(JSON.serialize(RelativeWrapperList),200);
            //responseReturnWrapperInstance = relativeList.isEmpty() ? CreateReturnResponse('Not found.',404) : CreateReturnResponse(JSON.serialize(relativeList),200);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('Membership Id -> '+membershipId, 'Getting the relative records.', ex.getMessage(), 'Error', 'DFJ_Utility.GetRelatives apex class.', String.valueOf(ex.getLineNumber()));
            responseReturnWrapperInstance = CreateReturnResponse('Server error.',500);
        }
        return responseReturnWrapperInstance;

    }

    /*
     * @Description  This method is to create the response.
     * @Param        returnMessage, returnStatusCode
     * @Return       ResponseReturnWrapper
    */
    public static ResponseReturnWrapper CreateReturnResponse(String returnMessage,Integer returnStatusCode){
        ResponseReturnWrapper responseReturnWrapperInstance = new ResponseReturnWrapper();
        
        responseReturnWrapperInstance.Message = returnMessage;
        responseReturnWrapperInstance.statuscode = returnStatusCode;
        return responseReturnWrapperInstance;
        
    }


    /*
     * @Description  This method is to create the relative record associated to membership Id.
     * @Param        responseBody, membershipId
     * @Return       ResponseReturnWrapper
    */
    public static ResponseReturnWrapper CreateRealtive(String responseBody,String membershipId){
        ResponseReturnWrapper responseReturnWrapperInstance = new ResponseReturnWrapper();
        try {
            if (String.isBlank(responseBody) || String.isBlank(membershipId)) {
                DFJ_ErrorController.addErrorLogs('', 'Creating the relative record.', 'ResponseBody or NULL/Empty Id(s) in the request parameters', 'Warning', 'DFJ_Utility.CreateRealtive apex class.','');
                return CreateReturnResponse('Bad request.',400);
            }

            List<Membership__c> membershipList = new List<Membership__c>();
            membershipList = [SELECT  Id, Name, First_Name__c, Last_Name__c, Email__c, Responsible_Lawyer__r.Name, Phone__c, Profile_Link__c,  Sign_up_Date__c FROM Membership__c WHERE Id = :membershipId LIMIT 1];
            if (membershipList.isEmpty()) {
                DFJ_ErrorController.addErrorLogs('membershipId ->'+membershipId, 'Creating the relative records.', 'Membership record not found, so can not create record.', 'Warning', 'DFJ_Utility.CreateRealtive apex class.','');
                return CreateReturnResponse('Not found.', 404);
            }
            // List<ParsedResponseWrapper> parsedResponseList = parseResponse(req.requestBody.toString());
            List<RelativeWrapper> relativeWrapperList = new List<RelativeWrapper>();
            if (!responseBody.contains('[')) {
                RelativeWrapper relative = (RelativeWrapper)  JSON.deserialize(responseBody, RelativeWrapper.class);
                relativeWrapperList.add(relative);
            }else {
                relativeWrapperList = (List<RelativeWrapper>) JSON.deserialize(responseBody, List<RelativeWrapper>.class);
            }
            
            if (relativeWrapperList.isEmpty()) {
                DFJ_ErrorController.addErrorLogs('membershipId ->'+membershipId, 'Creating the relative records.', 'relativeWrapperList is empty so can not create record.', 'Warning', 'DFJ_Utility.CreateRealtive apex class.','');
                return CreateReturnResponse('Bad request.',400);
            }

            List<Relative__c> relativeList = new List<Relative__c>();
            for (RelativeWrapper relativeWrapperLoop : relativeWrapperList) {
                Relative__c relativeInstance = new Relative__c();
                relativeInstance.Name = String.isBlank(relativeWrapperLoop.name) ? '' : relativeWrapperLoop.name;
                relativeInstance.Email__c = String.isBlank(relativeWrapperLoop.email) ? '' : relativeWrapperLoop.email;
                relativeInstance.Phone__c = String.isBlank(relativeWrapperLoop.phone_number) ? '' : relativeWrapperLoop.phone_number; 
                relativeInstance.Membership__c = membershipId;
                relativeList.add(relativeInstance);
            }
            
            if (relativeList.isEmpty() ) {
                DFJ_ErrorController.addErrorLogs('membershipId ->'+membershipId, 'Creating the relative records.', 'DML failed.', 'Warning', 'DFJ_Utility.CreateRealtive apex class.','');
                return CreateReturnResponse('Bad request.', 400);
            }
            insert relativeList;
            List<RelativeWrapper> RelativeWrapperListToReturn = new List<RelativeWrapper>();
            for (Relative__c relativeLoop : relativeList) {
                RelativeWrapper relativeWrapperInstance = new RelativeWrapper();
                relativeWrapperInstance.relativeObjectId = relativeLoop.Id;
                relativeWrapperInstance.name = relativeLoop.Name;
                relativeWrapperInstance.email = String.isBlank(relativeLoop.Email__c) ? '' : relativeLoop.Email__c;
                relativeWrapperInstance.phone_number = String.isBlank(relativeLoop.Phone__c) ? '' : relativeLoop.Phone__c;
                RelativeWrapperListToReturn.add(relativeWrapperInstance);
            }
            responseReturnWrapperInstance = CreateReturnResponse(JSON.serialize(RelativeWrapperListToReturn), 200);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('membershipId ->'+membershipId, 'Creating the relative records.', ex.getMessage(), 'Error', 'DFJ_Utility.CreateRealtive apex class.', String.valueOf(ex.getLineNumber()));
            responseReturnWrapperInstance = CreateReturnResponse('Server error.',500);
        }
        return responseReturnWrapperInstance;
    }

    /*
     * @Description  This method is to update the membership.
     * @Param        membership
     * @Return       ResponseReturnWrapper
    */
    public static ResponseReturnWrapper UpdateMembership(String membership,String membershipId){
        try {
            if (String.isBlank(membership) || String.isBlank(membershipId)) {
                return CreateReturnResponse('Bad request.',400);
            }
            List<Membership__c> membershipList = new List<Membership__c>();
            membershipList = [SELECT  Id, Name, First_Name__c, Last_Name__c, Email__c, Phone__c, Profile_Link__c,  Sign_up_Date__c FROM Membership__c WHERE Id = :membershipId LIMIT 1];
            if (membershipList.isEmpty()) {
                DFJ_ErrorController.addErrorLogs('', 'Updating the membership record.', 'membershipList is empty while fetching record to update.', 'Warning', 'DFJ_Utility.UpdateMembership apex class.','');
                
                return CreateReturnResponse('Not found.',404);
            }
            SubscriberWrapper subscriberWrapperInstance = (SubscriberWrapper) JSON.deserialize(membership, SubscriberWrapper.class);
            if (subscriberWrapperInstance == null) {
                DFJ_ErrorController.addErrorLogs(membershipId, 'Updating the membership record.', 'subscriberWrapperInstance is null so cannot update record.', 'Warning', 'DFJ_Utility.UpdateMembership apex class.','');
                return CreateReturnResponse('Bad request.',400);
            }

            membershipList[0].First_Name__c = String.isBlank(subscriberWrapperInstance.first_name) ? membershipList[0].First_Name__c : subscriberWrapperInstance.first_name;
            membershipList[0].Last_Name__c = String.isBlank(subscriberWrapperInstance.last_name) ? membershipList[0].Last_Name__c : subscriberWrapperInstance.last_name;
            membershipList[0].Email__c = String.isBlank(subscriberWrapperInstance.email) ? membershipList[0].Email__c : subscriberWrapperInstance.email ;
            membershipList[0].Phone__c = String.isBlank(subscriberWrapperInstance.phone_number) ? membershipList[0].Phone__c : subscriberWrapperInstance.phone_number;
            membershipList[0].Name = String.isBlank(subscriberWrapperInstance.first_name) ? String.isBlank(subscriberWrapperInstance.last_name) ? membershipList[0].Name : subscriberWrapperInstance.last_name : String.isBlank(subscriberWrapperInstance.last_name) ? subscriberWrapperInstance.first_name : subscriberWrapperInstance.first_name +' '+ subscriberWrapperInstance.last_name;

            update membershipList;
            
            // Set Id to return for the POST request.
            return CreateReturnResponse(JSON.serialize('OK'), 200);
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('membershipId -> '+membershipId, 'Updating the membership record.',ex.getMessage() , 'Error', 'DFJ_Utility.UpdateMembership apex class.', String.valueOf(ex.getLineNumber()));
            return CreateReturnResponse('Server error.', 500);
        }
    }

    /*
     * @Description  This method is to update the relative.
     * @Param        relative
     * @Return       ResponseReturnWrapper
    */
    public static ResponseReturnWrapper UpdateRelative(String relative,String membershipId,String relativeId){
        try {
            if (String.isBlank(relative)||String.isBlank(membershipId)||String.isBlank(relativeId)) {
                return CreateReturnResponse('Bad request.', 400);
            }
            List<Relative__c> relativeList = new List<Relative__c>();

            relativeList = [SELECT Id, Name, Email__c, Phone__c, Membership__c FROM Relative__c WHERE Membership__c = :membershipId AND Id=:relativeId LIMIT 1];
            if (relativeList.isEmpty()) {
                DFJ_ErrorController.addErrorLogs('', 'Updating the relative record.', 'relativeList is empty while fetching record to update.', 'Warning', 'DFJ_Utility.UpdateRelative apex class.','');
                
                return CreateReturnResponse('Not found.',404);
            }
            RelativeWrapper relativeWrapperInstance = (RelativeWrapper) JSON.deserialize(relative, RelativeWrapper.class);
            if (relativeWrapperInstance == null) {
                DFJ_ErrorController.addErrorLogs('relativeId ->'+relativeId, 'Updating the relative record.', 'relativeWrapperInstance is null so cannot update record.', 'Warning', 'DFJ_Utility.UpdateRelative apex class.','');
                return CreateReturnResponse('Bad request.',400);
            }
            relativeList[0].Name = String.isBlank(relativeWrapperInstance.name) ? relativeList[0].Name : relativeWrapperInstance.name;
            relativeList[0].Email__c = String.isBlank(relativeWrapperInstance.email) ? relativeList[0].Email__c : relativeWrapperInstance.email;
            relativeList[0].Phone__c = String.isBlank(relativeWrapperInstance.phone_number) ? relativeList[0].Phone__c : relativeWrapperInstance.phone_number;

            
            update relativeList;
            return CreateReturnResponse(JSON.serialize('OK'), 200);
            
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Updating the relative record.', ex.getMessage(), 'Error', 'DFJ_Utility.UpdateRelative apex class.', String.valueOf(ex.getLineNumber()));
            return CreateReturnResponse('Server error.', 500);
        }
    }

    /*
     * @Description  This method is to delete particular relative.
     * @Param        membershipId, relativeId
     * @Return       ResponseReturnWrapper
    */
    public static ResponseReturnWrapper DeleteRelative(String membershipId, String relativeId){
        ResponseReturnWrapper responseReturnWrapperInstance = new ResponseReturnWrapper();
        try {
            if(String.isBlank(membershipId) || String.isBlank(relativeId)){
                DFJ_ErrorController.addErrorLogs('', 'Deleting the relative record.', 'NULL/Empty Id(s) in the request parameters', 'Warning', 'DFJ_Utility.DeleteRelative apex class.','');
                return CreateReturnResponse('Bad request.',400);
            }
            List<Relative__c> relativeList = new List<Relative__c>();
            relativeList = [SELECT Id, Name, Email__c, Phone__c, Membership__c FROM Relative__c WHERE Id = :relativeId And Membership__c = :membershipId LIMIT 1];
            responseReturnWrapperInstance = relativeList.isEmpty() ? CreateReturnResponse('Not found.',404) : CreateReturnResponse(JSON.serialize('OK'),200);
            if (!relativeList.isEmpty()) {
                delete relativeList;
            }
            
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('Relative Id -> '+relativeId, 'Deleting the relative record.', ex.getMessage(), 'Error', 'DFJ_Utility.DeleteRelative apex class.', String.valueOf(ex.getLineNumber()));
            responseReturnWrapperInstance = CreateReturnResponse('Server error.',500);
        }
        return responseReturnWrapperInstance;
    }

    /*
    * @Description  This method is delete the membership record.
    * @Param        membreshipId
    * @Return       ResponseReturnWrapper
    */
    public static ResponseReturnWrapper DeleteMembership(String membershipId){
    ResponseReturnWrapper responseReturnWrapperInstance = new ResponseReturnWrapper();
    try {
        if (String.isBlank(membershipId)) {
            DFJ_ErrorController.addErrorLogs('', 'Deleting the membership record.', 'NULL/Empty Id(s) in the request parameters', 'Warning', 'DFJ_Utility.DeleteMembership apex class.','');
            return CreateReturnResponse('Bad request.',400);
        }
        List<Membership__c> membershipList = new List<Membership__c>();
        membershipList = [SELECT Profile_Link__c, Responsible_Lawyer__c, CPR__c, Phone__c, Sign_up_Date__c, Email__c, Membership_Number__c, Account__c, Name, Id FROM Membership__c
        WHERE Id = :membershipId LIMIT 1];
        responseReturnWrapperInstance = membershipList.isEmpty() ? CreateReturnResponse('Not found.',404) : CreateReturnResponse(JSON.serialize('OK'),200);
        if (!membershipList.isEmpty()) {
            delete membershipList;
        }
        
    } catch (Exception ex) {
        DFJ_ErrorController.addErrorLogs('Membership Id -> '+membershipId, 'Deleting the membership record.', ex.getMessage(), 'Error', 'DFJ_Utility.DeleteMembership apex class.', String.valueOf(ex.getLineNumber()));
        responseReturnWrapperInstance = CreateReturnResponse('Server error.',500);
    }
    return responseReturnWrapperInstance;

    }

    /*
    * @Description : Wrapper for the Membership data.
    */
    public class SubscriberWrapper {
        // public String name;
        public String first_name;
        public String last_name;
        public String email;
        public String responsible_lawyer;
        public String language;
        public String phone_number;
        public String profile_link;
        public String signup_date;
        // DIN-281 : Add ResponsibleAgentEmail field to membership API response.
        // Description : Added responsilbe agent mail.
        // Start
        public String responsible_agent_email ;
        // End
    }

    /*
    * @Description : Wrapper for relative data.
    */
    public class RelativeWrapper {
        public String relativeObjectId;
        public String name;
        public String email;
        public String phone_number;
    }

    /*
    * @Description : Wrapper to store rest response.
    */
    public class ResponseReturnWrapper {
        public String Message;
        public Integer statuscode;
    }
}