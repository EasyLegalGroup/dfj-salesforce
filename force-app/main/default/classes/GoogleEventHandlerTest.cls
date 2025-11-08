@isTest
public class GoogleEventHandlerTest {

    @testSetup
    private static void setupTestData() {
        Google_Auth__c auth = new Google_Auth__c(
            Token_Name__c = 'Latest',
            Access_Token__c = 'TestAccessToken'
        );
        insert auth;


        // Insert test ContentVersion records
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        contentVersions.add(new ContentVersion(
            Title = 'Mock File',
            PathOnClient = 'mockFile.txt',
            VersionData = Blob.valueOf('mock file content'),
            Google_Drive_Id__c = 'mock-file-id12'
        ));
        insert contentVersions;

        Account acc = new Account(LastName = 'Test acc');
        insert acc;
        // Insert test Journal__c records
        List<Journal__c> journals = new List<Journal__c>();
        journals.add(new Journal__c(
            Account__c = acc.id
        ));
        insert journals;
    }
    
    @isTest
    public static void TestingMainMethods(){
        
        Blob fileContent = blob.valueof('This is BLob');
        String accessToken = GoogleAPIMethods.getLatestAccessToken();
        Journal__c Journal = [SELECT id, Account__c FROM Journal__c LIMIT 1];
        ContentVersion contentVersion = new ContentVersion();
                        contentVersion.Title = 'Title';
                        contentVersion.PathOnClient = '\Filaname';
                        contentVersion.FirstPublishLocationId = Journal.Id;
                        contentVersion.VersionData = fileContent;
                        contentVersion.Google_Drive_Id__c = 'fileId';
        insert contentVersion;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        GoogleEventHandler.MainLogic();
        
     //   GoogleEventHandler.AttachFile(contentVersion.Id, Journal.Id);
        
        Test.stopTest();
    }
}