/*
   * @ Version : 1.0
   * @ Created Date : 2021-09-22
   * @Description : This class is apex web service class for membership and relatives functionality.
*/
@RestResource(urlMapping='/v1/membership/*')
global without sharing class DFJ_MembershipWebhook {
    /*
    * @Description  This http GET will return the membership/relative/List of relative according to the URI.
    * @Return       RestResponse
    */
    @HttpGet
    global static void GetMembershipRelatedData() {
        RestRequest request = RestContext.request;
        RestResponse responseToSend = RestContext.response;
        DFJ_Utility.ResponseReturnWrapper responseReturnWrapperInstance = new DFJ_Utility.ResponseReturnWrapper();
        try {
            String requestToken = request.headers.containsKey('X-Provider-token') ? request.headers.get('X-Provider-token') : '';
            Boolean isIPAuthorized = DFJ_Utility.AuthorizeUser(request.remoteAddress,requestToken);
            if (isIPAuthorized != null && isIPAuthorized) {
                List<String> uriStringList = new List<String>();
                uriStringList = request.requestURI.split('/');
                // Check for the operation we have to perform. 
                // If URI contains relative in it and last string of URI is relatives then calling GetRelatives. 
                // If URI contains relative in it and last string of URI is not relatives then calling GetSingleRelative.
                // If URI not contains relative and also index after membership is there in it then calling GetMembership
                // else returning bad request.
                responseReturnWrapperInstance = request.requestURI.contains('relatives') ?  (uriStringList[uriStringList.size()-1]).equals('relatives') ? DFJ_Utility.GetRelatives(uriStringList[uriStringList.indexOf('membership')+1]) : DFJ_Utility.GetSingleRelative(uriStringList[uriStringList.indexOf('membership')+1],uriStringList[uriStringList.indexOf('relatives')+1]) : uriStringList.size()-1 == uriStringList.indexOf('membership')+1 ? DFJ_Utility.GetMembership(uriStringList[uriStringList.size()-1]) :  DFJ_Utility.CreateReturnResponse('Bad request.', 400);
                if(responseReturnWrapperInstance != null){
                    responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
                    responseToSend.responseBody = Blob.valueOf(responseReturnWrapperInstance.Message);
                }
            }else{
                responseReturnWrapperInstance = DFJ_Utility.CreateReturnResponse('Unauthorized Access.', 401);
                responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
                responseToSend.responseBody = Blob.valueOf(JSON.serialize(responseReturnWrapperInstance.Message));
            }
        } catch (Exception ex) {
            responseReturnWrapperInstance = DFJ_Utility.CreateReturnResponse('Server error.', 500);
            responseToSend.responseBody = Blob.valueOf(responseReturnWrapperInstance.Message);
            responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
            DFJ_ErrorController.addErrorLogs('', 'Getting Membership related data.', ex.getMessage(), 'Error', 'DFJ_MembershipWebhook.GetMembershipRelatedData apex class.', String.valueOf(ex.getLineNumber()));

        }
    }

    /*
    * @Description  This http POST create relative.
    * @Return       RestResponse
    */
    @HttpPost
    global static void CreateMembershipRelatedData() {
        RestRequest request = RestContext.request;
        RestResponse responseToSend = RestContext.response;
        DFJ_Utility.ResponseReturnWrapper responseReturnWrapperInstance = new DFJ_Utility.ResponseReturnWrapper();
        try {
            String requestToken = request.headers.containsKey('X-Provider-token') ? request.headers.get('X-Provider-token') : '';
            Boolean isIPAuthorized = DFJ_Utility.AuthorizeUser(request.remoteAddress,requestToken);
            if (isIPAuthorized != null && isIPAuthorized) {
                List<String> uriStringList = new List<String>();
                uriStringList = request.requestURI.split('/');
                // If URI contains relatives then calling CreateRealtive to create the relatives else returning Bad Request.
                responseReturnWrapperInstance = request.requestURI.contains('relatives') ? DFJ_Utility.CreateRealtive(request.requestBody.toString(),uriStringList[uriStringList.indexOf('membership')+1]) : DFJ_Utility.CreateReturnResponse('Bad request.', 400);
                if (responseReturnWrapperInstance != null ) {
                    responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
                    responseToSend.responseBody = Blob.valueOf(responseReturnWrapperInstance.Message);
                }
            }else {
                responseReturnWrapperInstance = DFJ_Utility.CreateReturnResponse('Unauthorized Access.', 401);
                responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
                responseToSend.responseBody = Blob.valueOf(JSON.serialize(responseReturnWrapperInstance.Message));
            }
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Creating Membership related data.', ex.getMessage(), 'Error', 'DFJ_MembershipWebhook.CreateMembershipRelatedData apex class.', String.valueOf(ex.getLineNumber()));
             
            responseReturnWrapperInstance = DFJ_Utility.CreateReturnResponse('Server error.', 500);
             responseToSend.responseBody = Blob.valueOf(responseReturnWrapperInstance.Message);
            responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
        }
    }

    /*
    * @Description  This http PUT method will update the membership/relative according to the URI.
    * @Return       RestResponse
    */
    @HttpPut
    global static void UpdateMembershipRelatedData() {
        RestRequest request = RestContext.request;
        RestResponse responseToSend = RestContext.response;
        DFJ_Utility.ResponseReturnWrapper responseReturnWrapperInstance = new DFJ_Utility.ResponseReturnWrapper();
        try {
            String requestToken = request.headers.containsKey('X-Provider-token') ? request.headers.get('X-Provider-token') : '';
            Boolean isIPAuthorized = DFJ_Utility.AuthorizeUser(request.remoteAddress,requestToken);
            if (isIPAuthorized != null && isIPAuthorized) {
                    responseReturnWrapperInstance = DFJ_Utility.CreateReturnResponse('Unauthorized Access.', 401);
                    responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
                    responseToSend.responseBody = Blob.valueOf(JSON.serializePretty(responseReturnWrapperInstance.Message));
                
                    List<String> uriStringList = new List<String>();
                    uriStringList = request.requestURI.split('/');
                    // Checking the URI also we can use the Id of membership and relative if needed form the uriStringList
                    responseReturnWrapperInstance = request.requestURI.contains('relatives') ? uriStringList.size()-1 == uriStringList.indexOf('relatives')+1 ? DFJ_Utility.UpdateRelative(request.requestBody.toString(),uriStringList[uriStringList.indexOf('membership')+1],uriStringList[uriStringList.indexOf('relatives')+1]) : DFJ_Utility.CreateReturnResponse('Bad request.', 400) : uriStringList.size()-1 == uriStringList.indexOf('membership')+1 ? DFJ_Utility.UpdateMembership(request.requestBody.toString(),uriStringList[uriStringList.indexOf('membership')+1]) : DFJ_Utility.CreateReturnResponse('Bad request.', 400) ;

                if (responseReturnWrapperInstance != null) {
                    responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
                    responseToSend.responseBody = Blob.valueOf(responseReturnWrapperInstance.Message);
                }
            }else{
                responseReturnWrapperInstance = DFJ_Utility.CreateReturnResponse('Unauthorized Access.', 401);
                responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
                responseToSend.responseBody = Blob.valueOf(JSON.serialize(responseReturnWrapperInstance.Message));
            }
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Updating Membership related data.', ex.getMessage(), 'Error', 'DFJ_MembershipWebhook.UpdateMembershipRelatedData apex class.', String.valueOf(ex.getLineNumber()));
            responseReturnWrapperInstance = DFJ_Utility.CreateReturnResponse('Server error.', 500);
            responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
            responseToSend.responseBody = Blob.valueOf(responseReturnWrapperInstance.Message);
        }
    }

    /*
    * @Description  This http DELETE delete the membership/relative according to the URI.
    * @Return       RestResponse
    */
    @HttpDelete
    global static void DeleteMembershipRelatedData() {
        RestRequest request = RestContext.request;
        RestResponse responseToSend = RestContext.response;
        DFJ_Utility.ResponseReturnWrapper responseReturnWrapperInstance = new DFJ_Utility.ResponseReturnWrapper();
        try {
            String requestToken = request.headers.containsKey('X-Provider-token') ? request.headers.get('X-Provider-token') : '';
            Boolean isIPAuthorized = DFJ_Utility.AuthorizeUser(request.remoteAddress,requestToken);
            if (isIPAuthorized != null && isIPAuthorized) {
            
                List<String> uriStringList = new List<String>();
                uriStringList = request.requestURI.split('/');
                // Checking If URI contains and have Id in url at next index of relative then calling DeleteRelative.
                // else checking Id in url at next index of membership calling DeleteMembership.
                // else returning bad request.
                responseReturnWrapperInstance = request.requestURI.contains('relatives') ? uriStringList.size()-1 == uriStringList.indexOf('relatives')+1 ? DFJ_Utility.DeleteRelative(uriStringList[uriStringList.indexOf('membership')+1],uriStringList[uriStringList.indexOf('relatives')+1]) : DFJ_Utility.CreateReturnResponse('Bad request.', 400) : uriStringList.size()-1 == uriStringList.indexOf('membership')+1 ?DFJ_Utility.DeleteMembership(uriStringList[uriStringList.indexOf('membership')+1]) : DFJ_Utility.CreateReturnResponse('Bad request.', 400);
                if(responseReturnWrapperInstance != null){
                    responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
                    responseToSend.responseBody = Blob.valueOf(responseReturnWrapperInstance.Message);
                }
            }else {
                responseReturnWrapperInstance = DFJ_Utility.CreateReturnResponse('Unauthorized Access.', 401);
                responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
                responseToSend.responseBody = Blob.valueOf(JSON.serialize(responseReturnWrapperInstance.Message));
            }
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Deleting Membership related data.', ex.getMessage(), 'Error', 'DFJ_MembershipWebhook.DeleteMembershipRelatedData apex class.', String.valueOf(ex.getLineNumber()));
            responseReturnWrapperInstance = DFJ_Utility.CreateReturnResponse('Server error.', 500);
            responseToSend.statusCode = responseReturnWrapperInstance.statuscode;
            responseToSend.responseBody = Blob.valueOf(responseReturnWrapperInstance.Message);
        }
    }

}