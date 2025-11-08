/**
 * @description This class fetches the token and response from the CPR service endpoint.
 */
public class DFJ_CPRTokenService {
    // Public static variable to hold the URL of the CPR service
    public static String cprUrl = 'https://gctp.cpr.dk/cpr-online-gctp/gctp';
    
    /**
     * @description Retrieves the CPR token by authenticating with the CPR service.
     * @return DFJ_CPRService.CprResponseWrapper containing the token and status code
     */
    public static DFJ_CPRService.CprResponseWrapper getCPRToken() {
        // Define the authentication endpoint URL
        String authEndpoint = cprUrl;
        
        // Create a response wrapper to hold the response data
        DFJ_CPRService.CprResponseWrapper responseWrapper = new DFJ_CPRService.CprResponseWrapper();
        
        // Retrieve CPR service credentials from organization defaults
        DFJ_CPR_Services__c getCPRCreds = DFJ_CPR_Services__c.getOrgDefaults();
        String cprUsername = getCPRCreds.Username__c; // Username for authentication
        String cprPassword = getCPRCreds.Password__c; // Password for authentication
        
        // Prepare the XML payload with user credentials for the signon function
        String authRequestBody = '<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>' +
            '<root xmlns="http://www.cpr.dk">' +
            '    <Gctp v="2.0">' +
            '        <Sik function="signon" userid="'+ cprUsername + '" password="'+ cprPassword +'"/>' +
            '    </Gctp>' +
            '</root>';
        
        // Initialize the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(authEndpoint); // Set the endpoint URL
        req.setMethod('POST'); // Set the HTTP method to POST
        req.setHeader('Content-Type', 'text/xml'); // Set the content type for XML
        req.setHeader('User-Agent', 'CPR/1.0'); // Set the user agent for the request
        req.setHeader('Host', 'gctp.cpr.dk'); // Set the host for the request
        req.setBody(authRequestBody); // Set the request body
        
        Http http = new Http(); // Create an HTTP object to send the request
        
        try {
            // Send the request and capture the response
            HttpResponse res = http.send(req);
            
            // Check if the response status code indicates success (200)
            if (res.getStatusCode() == 200) {
                // Extract the Set-Cookie header for the token
                String cookieHeader = res.getHeader('Set-Cookie');
                
                // Parse the cookie header to extract the token
                String token = '';
                if (cookieHeader != null && cookieHeader.contains('Token=')) {
                    token = cookieHeader.substringBetween('Token=', ';'); // Extract the token value
                    responseWrapper.token = token; // Set the token in the response wrapper
                    responseWrapper.statusCode = '200'; // Set the status code to 200
                }
                return responseWrapper; // Return the response wrapper with the token
            } else {
                // If the response status is not 200, set an error message in the response wrapper
                responseWrapper.statusCode = 'Something went wrong';
                return responseWrapper; // Return the response wrapper
            }
        } catch (Exception ex) {
            // Handle any exceptions that occur during the process
            responseWrapper.errorMessage = 'Error in Line ' + String.valueOf(ex.getLineNumber()) + ' ' + ex.getMessage();
            // Log the error details for troubleshooting
            DFJ_ErrorLogController.addErrorLogs('', 'Process DFJ_CPRTokenService', ex.getMessage(), 'Error', 'DFJ_CPRTokenService.getCPRToken', '', String.valueOf(ex.getLineNumber()));
            return responseWrapper; // Return the response wrapper with the error message
        }
    }
}