@RestResource(urlMapping='/cpr/outbound06/*')
global with sharing class CPROutbound06_API {
    // GET /services/apexrest/cpr/outbound06/batchfile/{batchId}
    @HttpGet
    global static void getBatchFile() {
        try {
            // Parse .../batchfile/{batchId}
            List<String> parts = RestContext.request.requestURI.split('/');
            String batchId = (parts.isEmpty() ? null : parts[parts.size()-1]);
            if (String.isBlank(batchId)) throw new AuraHandledException('Missing batchId');

            // Batch (for file name)
            CPR_Outbound_Batch__c b = [
                SELECT Id, File_Name__c
                FROM CPR_Outbound_Batch__c
                WHERE Id = :batchId LIMIT 1
            ];

            // NEW: use SystemModstamp (not CreatedDate) on ContentDocumentLink
            ContentDocumentLink cdl = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :b.Id
                ORDER BY SystemModstamp DESC, Id DESC
                LIMIT 1
            ];

            // Latest ContentVersion for that document
            ContentVersion cv = [
                SELECT Id, Title, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId = :cdl.ContentDocumentId
                ORDER BY VersionNumber DESC, CreatedDate DESC
                LIMIT 1
            ];

            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/octet-stream');
            RestContext.response.addHeader(
                'Content-Disposition',
                'attachment; filename="' + (String.isBlank(b.File_Name__c) ? cv.Title : b.File_Name__c) + '"'
            );
            RestContext.response.responseBody = cv.VersionData;

        } catch (Exception e) {
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
}