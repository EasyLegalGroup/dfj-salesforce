/**
 * @description This class is for CPR Response Service
 */
public class DFJ_CPRResponseService {
    // The URL for the CPR API
    public static String cprUrl = 'https://gctp.cpr.dk/cpr-online-gctp/gctp';
    
    // DFJ-290 Changes: Added parameter recId to method callPNRApiService
    
    /**
     * @description This method calls the PNR API Service to fetch CPR data.
     * @param tokenWrapper DFJ_CPRService.CprResponseWrapper containing token and error message
     * @param cprNumber String representing the CPR number to query
     * @return DFJ_CPRService.CprResponseWrapper containing the response from the CPR service
     */
    public static DFJ_CPRService.CprResponseWrapper callPNRApiService(DFJ_CPRService.CprResponseWrapper tokenWrapper, String cprNumber) {
        // Initialize a new response wrapper
        DFJ_CPRService.CprResponseWrapper responseWrapper = new DFJ_CPRService.CprResponseWrapper();
        responseWrapper.errorMessage = tokenWrapper.errorMessage;
        
        // Check if the token and CPR number are valid
        if (String.isNotBlank(tokenWrapper.token) && String.isNotBlank(cprNumber)) {
            String endpoint = cprUrl;
            
            // Prepare the XML payload for the request
            String requestBody = '<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>' +
                '<root xmlns="http://www.cpr.dk">' +
                '    <Gctp v="2.0">' +
                '        <System r="CprSoeg">' +
                '            <Service r="STAMP">' +
                '                <CprServiceHeader r="STAMP">' +
                '                    <Key>' +
                '                        <Field r="PNR" v="' + cprNumber + '"/>' +
                '                    </Key>' +
                '                </CprServiceHeader>' +
                '            </Service>' +
                '        </System>' +
                '    </Gctp>' +
                '</root>';
            
            // Initialize the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'text/xml');
            req.setHeader('User-Agent', 'CPR/1.0');
            req.setHeader('Cookie', 'Token=' + tokenWrapper.token);
            req.setBody(requestBody);
            
            // Send the request and capture the response
            Http http = new Http();
            try {
                HttpResponse res = http.send(req);
                
                // Handle the response
                if (res.getStatusCode() == 200) {
                    responseWrapper.statusCode = String.valueOf(res.getStatusCode());
                    responseWrapper = DFJ_CPRResponseParser.parseCprResponse(res.getBody());
                } else {
                    responseWrapper.statusCode = 'Something went wrong';
                }
            } catch (Exception ex) {
                // Log any exceptions that occur during the request
                responseWrapper.errorMessage = 'Error in Line ' + String.valueOf(ex.getLineNumber()) + ' ' + ex.getMessage();
                DFJ_ErrorLogController.addErrorLogs('', 'Process DFJ_CPRResponseService', ex.getMessage(), 'Error', 'DFJ_CPRResponseService.callPNRApiService', '', String.valueOf(ex.getLineNumber()));
            }
        } else {
            // Handle the case where token or CPR number is missing
            responseWrapper.statusCode = 'Something went wrong';
        }
        
        // Return the response wrapper with the status and any errors
        return responseWrapper;
    }
}