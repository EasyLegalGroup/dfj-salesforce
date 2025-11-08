public class TokenRefreshForGoogleDrive implements Schedulable{
    
     public void execute(SchedulableContext sc) {
        refreshToken();
    }
    
    public static void createWatch(Google_Auth__c authData, String accessToken, Boolean NewRec) {
        String pageToken = getPageToken(accessToken);
        if (pageToken == null) {
            System.debug('Failed to get page token. Aborting webhook setup.');
            return;
        }
		
        if(authData.Unique_Id__c != NULL && !NewRec){
            unwatchWebhook(authData.Unique_Id__c, authData.Resource_Id__c);
        }
        try {
            String callbackUrl =   System.Label.Webhook_URL;  
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://www.googleapis.com/drive/v3/changes/watch/?pageToken=' + pageToken);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            String body = '{"id": "unique-channel-id-' + Datetime.now().getTime() + '", "type": "web_hook", "address": "' + callbackUrl + '", "pageToken": "' + pageToken + '", "params": {"ttl": 360000000}}';
            req.setBody(body);

            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String resourceId = (String) jsonResponse.get('resourceId');
                String uniqueChannelId = (String) jsonResponse.get('id');
                authData.Unique_Id__c = uniqueChannelId;
                authData.Resource_Id__c = resourceId;
                if(NewRec){
                    insert authData;
                }else{
                    update authData;
                }   
            } else {
                System.debug('Failed to set up webhook. Status code: ' + res.getStatusCode());
                System.debug('Response: ' + res.getBody());
            }
        } catch (Exception ex) {
            System.debug('Exception occurred in createWatch: ' + ex.getMessage());
        }
    }

    // Method to fetch the latest page token
    public static String getPageToken(String accessToken) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://www.googleapis.com/drive/v3/changes/startPageToken');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);

            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return (String) jsonResponse.get('startPageToken');
            } else {
                System.debug('Failed to fetch page token. Status code: ' + res.getStatusCode());
                System.debug('Response: ' + res.getBody());
                return null;
            }
        } catch (Exception ex) {
            System.debug('Exception occurred in getPageToken: ' + ex.getMessage());
            return null;
        }
    }
    
    public static void unwatchWebhook(String channelId, String resourceId) {
        String accessToken = GoogleAPIMethods.getLatestAccessToken();

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://www.googleapis.com/drive/v3/channels/stop');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');

            String body = '{"id": "' + channelId + '" , "resourceId" : "' + resourceId + '"}';
            req.setBody(body);

            Http http = new Http();
            HttpResponse res = http.send(req);
        } catch (Exception ex) {
            System.debug('Exception occurred in unwatchWebhook: ' + ex.getMessage());
        }
    }
    
    @future(Callout=true)
    public static void refreshToken() {
        Google_Auth_Key__mdt googleCred = GoogleAuthHelper.getGoogleAuthMetaData();

        String endPoint = 'https://accounts.google.com/o/oauth2/token';
        String method = 'POST';
        Map<String, String> header = new Map<String, String>();
        header.put('Content-Type', 'application/x-www-form-urlencoded');

        // Fetch the refresh token from the Google_Auth__c object
        Google_Auth__c authData = [SELECT Refresh_Token__c FROM Google_Auth__c WHERE Token_Name__c = 'Latest' LIMIT 1];
        
        if (authData == null || String.isBlank(authData.Refresh_Token__c)) {           
            system.debug('Refresh token not found.');
            return;
        }
        
        String refreshToken = authData.Refresh_Token__c;

        String requestBody = 'client_id=' + EncodingUtil.urlEncode(googleCred.Client_Id__c, 'UTF-8');
        requestBody += '&client_secret=' + EncodingUtil.urlEncode(googleCred.Client_Secret__c, 'UTF-8');
        requestBody += '&refresh_token=' + EncodingUtil.urlEncode(refreshToken, 'UTF-8');
        requestBody += '&grant_type=refresh_token';

        HttpResponse response = GoogleAuthHelper.sendRequest(GoogleAuthHelper.prepareRequest(endPoint, method, header, requestBody));

        if (response.getStatusCode() == 200) {
            Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            if ([SELECT COUNT() FROM Google_Auth__c] == 1) {
                Google_Auth__c gAuth = [SELECT Id, Access_Token__c, Unique_Id__c, Resource_Id__c, Token_Type__c FROM Google_Auth__c WHERE Token_Name__c = 'Latest' LIMIT 1];
                gAuth.Access_Token__c = (String) tokenResponse.get('access_token');
                gAuth.Token_Type__c = (String) tokenResponse.get('token_type');
                createWatch(gAuth, gAuth.Access_Token__c, false);
            } else {
                Google_Auth__c gAuth = new Google_Auth__c();
                gAuth.Token_Name__c = 'Latest';
                gAuth.Access_Token__c = (String) tokenResponse.get('access_token');
                gAuth.Token_Type__c = (String) tokenResponse.get('token_type');
                createWatch(gAuth, gAuth.Access_Token__c, True);
            }
            System.debug('Token refreshed successfully');
        }
    }
}