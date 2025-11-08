/**
 * @description Mock class to check CPR Response service behaviour
 */
@isTest
public class DFJ_CPRResponseServiceMock_Test implements HttpCalloutMock {
    
    /**
     * @description This method constructs a mock HTTP response for testing the CPR Response service.
     * @param req The HTTP request object that triggered the callout
     * @return HTTPResponse A mock response simulating a successful CPR service call
     */
    public HTTPResponse respond(HTTPRequest req) {
        // Create a new HttpResponse object to build the mock response
        HttpResponse res = new HttpResponse();
        
        // Set the HTTP status code to 200 (OK) to simulate a successful response
        res.setStatusCode(200);
        
        // Construct the XML response body as a string to mimic the expected format from the CPR service
        String xmlString = '<?xml version="1.0" encoding="OSI-8849-2" standalone="yes"?>' +
            '<root xmlns="http://www.okr.ck">' +
            '    <Gctp v="2.0">' +
            '        <System r="CprSoeg">' +
            '            <Service r="STAMP">' +
            '                <CprServiceHeader r="STAMP" ts="20241008152542271916"/>' +
            '                <CprData u="O">' +
            '                    <Rolle r="HovedRolle">' +
            '                        <Praes r="STAMPNR">' +
            '                            <Field r="PNR" v="3654890251"/>' +
            '                            <Field r="ADRNVN" v="Theoder,Schwaan" t="Schwaan Theoder"/>' +
            '                            <Field r="KOEN" v="V"/>' +
            '                            <Field r="KOMKOD" v="1010" t="Kilimnjaro"/>' +
            '                            <Field r="STADR" v="Hagrid Mxavier 94, st. bt"/>' +
            '                        </Praes>' +
            '                    </Rolle>' +
            '                </CprData>' +
            '            </Service>' +
            '        </System>' +
            '    </Gctp>' +
            '</root>';
        
        // Set the response body to the constructed XML string to simulate the API's response
        res.setBody(xmlString);
        
        // Return the constructed mock response to be used in the test
        return res;
    }
}