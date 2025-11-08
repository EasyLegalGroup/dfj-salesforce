@IsTest
private class CPRInboundU09480REST_Tests {
    @IsTest
    static void post_ingests_sample() {
        // minimal sample file body
        String body =
            '0012012711398202204291453\n' +
            '0092012711398202508181205A21\n' +
            '99900000002\n';
        ContentVersion cv = new ContentVersion(
            Title='u09480_sample.txt',
            PathOnClient='u09480_sample.txt',
            VersionData=Blob.valueOf(body)
        );
        insert cv;

        // prepare REST context
        CPRInboundU09480REST.Req inReq = new CPRInboundU09480REST.Req();
        inReq.contentVersionId = cv.Id;
        inReq.fileDate = Date.today();

        RestRequest rr = new RestRequest();
        rr.httpMethod  = 'POST';
        rr.requestUri  = '/services/apexrest/cpr/inbound/u09480';
        rr.requestBody = Blob.valueOf(JSON.serialize(inReq));
        RestResponse rs = new RestResponse();
        RestContext.request = rr;
        RestContext.response = rs;

        CPRInboundU09480REST.Res out = CPRInboundU09480REST.post();
        System.assertEquals('OK', out.message);
        System.assert(out.eventsCreated > 0, 'Should create at least one event');
        System.assertNotEquals(null, out.fileRunId);
    }
}