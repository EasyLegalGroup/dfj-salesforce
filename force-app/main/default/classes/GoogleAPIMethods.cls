public class GoogleAPIMethods {
    
    /* 
*********************************************************
@Method Name    : getLatestAccessToken 
@author         : Sohaib Saqib
@description    : To get latest Access token that will be used in every API call. And to avoide querying again and again. 
@param          : void
@return         : Access Token
********************************************************
*/
    public static String getLatestAccessToken() {
        List<Google_Auth__c> authList = [SELECT Access_Token__c FROM Google_Auth__c WHERE Token_Name__c = 'Latest' LIMIT 1];
        if (authList != null && !authList.isEmpty()) {
            Google_Auth__c auth = authList[0];
            if (auth.Access_Token__c != null) {
                return auth.Access_Token__c;
            }
        }
        return null;
    }
    
    public static Blob fetchGoogleDriveFileContent(String googleDriveFileId) {
        String accessToken = getLatestAccessToken();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://www.googleapis.com/drive/v3/files/' + googleDriveFileId + '?alt=media');
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        
        try {
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() == 200) {
                return response.getBodyAsBlob();
            } else {
                System.debug('Error fetching content: ' + response.getStatusCode() + ' - ' + response.getStatus());
                System.debug('Full Google Drive API response: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return null;
    }
    
    public static Map<String, Map<String, String>> getFilesCreatedLastMinute() {
        String accessToken = getLatestAccessToken();
        Map<String, Map<String, String>> fileDetails = new Map<String, Map<String, String>>();
        String endpointAPI = 'https://www.googleapis.com/drive/v3/files?q=trashed=false&orderBy=createdTime%20desc&pageSize=5' ;
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointAPI);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setHeader('Content-Type', 'application/json');
        
        try {
            HttpResponse response = new Http().send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> files = (List<Object>) responseData.get('files');
                if (files != null && !files.isEmpty()) {
                    for (Object file : files) {
                        String mimeType = (String) ((Map<String, Object>) file).get('mimeType');
                        String fileId = (String) ((Map<String, Object>) file).get('id');
                        String fileName = (String) ((Map<String, Object>) file).get('name');
                        Map<String, String> fileInfo = new Map<String, String>();
                        fileInfo.put('mimeType', mimeType);
                        fileInfo.put('name', fileName);
                        fileDetails.put(fileId, fileInfo);
                    }
                }
            } else {
                System.debug('Error Response: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        return fileDetails;
    }
    
    
    public static Map<String, String> getParentFolderDetails(String fileId) {
        String accessToken = getLatestAccessToken();
        Map<String, String> result = new Map<String, String>();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://www.googleapis.com/drive/v3/files/' + fileId + '?fields=parents');
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        
        try {
            HttpResponse response = new Http().send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (responseData.containsKey('parents')) {
                    List<Object> parents = (List<Object>) responseData.get('parents');
                    if (parents != null && !parents.isEmpty()) {
                        String parentId = (String) parents[0];
                        
                        // Make a request to get the parent folder details
                        HttpRequest parentRequest = new HttpRequest();
                        parentRequest.setEndpoint('https://www.googleapis.com/drive/v3/files/' + parentId + '?fields=name');
                        parentRequest.setMethod('GET');
                        parentRequest.setHeader('Authorization', 'Bearer ' + accessToken);
                        
                        HttpResponse parentResponse = new Http().send(parentRequest);
                        
                        if (parentResponse.getStatusCode() == 200) {
                            Map<String, Object> parentData = (Map<String, Object>) JSON.deserializeUntyped(parentResponse.getBody());
                            if (parentData.containsKey('name')) {
                                String parentName = (String) parentData.get('name');
                                result.put('parentId', parentId);
                                result.put('parentName', parentName);
                                return result;
                            } else {
                                result.put('error', 'Parent name not found');
                                return result;
                            }
                        } else {
                            result.put('error', 'Error retrieving parent details');
                            return result;
                        }
                    } else {
                        result.put('error', '404');  // No parent folder
                        return result;
                    }
                } else {
                    result.put('error', '404');  // No parent folder
                    return result;
                }
            } else {
                result.put('error', '001');  // Error: Non-200 status code
                return result;
            }
        } catch (Exception e) {
            result.put('error', '001');  // Error: Exception occurred
            return result;
        }
    }
    
}