@isTest
public class DFJ_CPRServiceFlowInvoker_Test {
    /**
     * Combined mock that inspects the request path or body and returns the appropriate mock
     * response for token or PNR operations. This keeps the test simple and avoids
     * registering multiple mocks separately.
     */
    private class CombinedMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            // If the body contains 'signon' assume token endpoint
            if (req.getBody() != null && req.getBody().contains('signon')) {
                res.setStatusCode(200);
                res.setHeader('Set-Cookie', 'Token=testToken; Path=/');
                return res;
            }

            // Otherwise return the PNR XML used by DFJ_CPRResponseServiceMock_Test
            res.setStatusCode(200);
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
            res.setBody(xmlString);
            return res;
        }
    }

    @isTest
    static void testInvocable() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CombinedMock());

        DFJ_CPRServiceFlowInvoker.Request req = new DFJ_CPRServiceFlowInvoker.Request();
        req.cprNumber = '2307922749';
        req.recordId = '001000000000001';

        List<DFJ_CPRServiceFlowInvoker.Request> inputs = new List<DFJ_CPRServiceFlowInvoker.Request>{ req };
        List<DFJ_CPRServiceFlowInvoker.Response> results = DFJ_CPRServiceFlowInvoker.invoke(inputs);

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        DFJ_CPRServiceFlowInvoker.Response r = results[0];
        System.assertEquals('200', r.statusCode, 'Status code should be 200');
        System.assertEquals('Schwaan Theoder', r.name, 'Name should match mock');
        System.assertEquals('V', r.gender, 'Gender should match mock');
        Test.stopTest();
    }
}