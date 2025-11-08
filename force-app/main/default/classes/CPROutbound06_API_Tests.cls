@IsTest
private class CPROutbound06_API_Tests {

    @IsTest
    static void get_serves_latest_contentversion() {
        // Arrange: batch with filename
        CPR_Outbound_Batch__c b = new CPR_Outbound_Batch__c(
            File_Name__c = 'd250821.i585601',
            File_Date__c = Date.today(),
            Status__c    = 'Generated'
        );
        insert b;

        // First version (creates the ContentDocument)
        ContentVersion v1 = new ContentVersion(
            Title='inddata06_test_v1.txt',
            PathOnClient='inddata06_test_v1.txt',
            VersionData=Blob.valueOf('FIRST_VERSION_BODY')
        );
        insert v1;

        // Fetch its document id
        Id docId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :v1.Id
        ].ContentDocumentId;

        // Link the document to the batch (the API queries by this link)
        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId    = b.Id,
            ShareType         = 'V'
        );

        // Newest version (what the API should return)
        ContentVersion v2 = new ContentVersion(
            ContentDocumentId = docId,
            Title='inddata06_test_v2.txt',
            PathOnClient='inddata06_test_v2.txt',
            VersionData=Blob.valueOf('SECOND_VERSION_BODY')
        );
        insert v2;

        // Act: call GET /services/apexrest/cpr/outbound06/batchfile/{batchId}
        RestRequest req = new RestRequest();
        req.httpMethod  = 'GET';
        req.requestUri  = '/services/apexrest/cpr/outbound06/batchfile/' + b.Id;
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CPROutbound06_API.getBatchFile();
        Test.stopTest();

        // Assert: 200 and body == latest version content
        System.assertEquals(200, RestContext.response.statusCode, 'Expected 200');
        String body = RestContext.response.responseBody.toString();
        System.assertEquals('SECOND_VERSION_BODY', body, 'Should stream newest ContentVersion bytes');
    }

    @IsTest
    static void get_missing_batchid_returns_400() {
        // Act: no id at end of URI
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.requestUri = '/services/apexrest/cpr/outbound06/batchfile/'; // trailing slash → empty last segment
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CPROutbound06_API.getBatchFile();
        Test.stopTest();

        // Assert: 400 and a helpful error
        System.assertEquals(400, RestContext.response.statusCode, 'Expected 400');
        String err = RestContext.response.responseBody.toString();
        System.assert(err.contains('Missing batchId') || err.startsWith('Error:'), 'Should indicate missing id');
    }
}