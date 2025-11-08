@isTest
public class DFJ_CPRTokenServiceMock_Test implements HttpCalloutMock {
    /**
     * @description Simulates an HTTP response for testing the DFJ_CPRTokenService.
     * @param req The HTTP request that triggers the mock response
     * @return HTTPResponse A mocked HTTP response with a status code and cookie
     */
    public HTTPResponse respond(HTTPRequest req) {
        // Create a new HttpResponse object to build the response
        HttpResponse res = new HttpResponse();
        
        // Set the HTTP status code to 200 (OK) to indicate a successful response
        res.setStatusCode(200);
        
        // Set the Set-Cookie header to simulate the token returned by the CPR service
        res.setHeader('Set-Cookie', 'Token=testToken; Path=/');
        
        // Return the constructed response
        return res;
    }
}