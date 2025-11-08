@isTest
public class GoogleAPIMethods_Test {
    
    @isTest
    public static void TestingAllMethods(){
        Google_Auth__c auth = new Google_Auth__c(
            Token_Name__c = 'Latest',
            Access_Token__c = 'TestAccessToken'
        );
        insert auth;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        GoogleAPIMethods.getLatestAccessToken();
        GoogleAPIMethods.fetchGoogleDriveFileContent('folderId');
        GoogleAPIMethods.getParentFolderDetails('folderId');
        GoogleAPIMethods.getFilesCreatedLastMinute();
        Test.stopTest();
    }
}