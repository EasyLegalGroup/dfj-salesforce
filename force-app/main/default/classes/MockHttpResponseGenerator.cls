public class MockHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Create a mock HTTP response for the Calendly API
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"resource": {"name": "Test Event"}}');
        response.setStatusCode(200);
        return response;
    }
}