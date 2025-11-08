@isTest
public class ContentVersionTriggerHanderTest {

    @isTest static void testAttachAccount() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test ContentVersion
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.PathOnClient = 'TestDocument.txt';
        contentVersion.VersionData = Blob.valueOf('Test content data');
        contentVersion.Origin = 'H';
        contentVersion.Related_Account_Id__c = testAccount.Id;
        Test.startTest();
        insert contentVersion;
        
        // List of ContentVersions to pass to the method
        List<ContentVersion> contentVersionList = new List<ContentVersion>{ contentVersion };

        // Execute the method
        
        ContentVersionTriggerHander.AttachAccount(contentVersionList);
        Test.stopTest();
 
    }
}