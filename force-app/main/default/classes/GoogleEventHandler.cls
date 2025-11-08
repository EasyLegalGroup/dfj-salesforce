public class GoogleEventHandler {
    
    @future(callout=true)
    public static void MainLogic(){
        try {
            String accessToken = GoogleAPIMethods.getLatestAccessToken();
            // Call the method to get files created in the last minute
            Map<String, Map<String, String>> allFiles = GoogleAPIMethods.getFilesCreatedLastMinute();
            // Create two separate Maps for folders and other types
            Map<String, String> folderFiles = new Map<String, String>();
            Map<String, String> otherFiles = new Map<String, String>();
            // Loop through the Map and separate the files based on their MIME type
            for (String fileId : allFiles.keySet()) {
                Map<String, String> fileInfo = allFiles.get(fileId);
                String mimeType = fileInfo.get('mimeType');
                String fileName = fileInfo.get('name');
                // system.debug('File Name: ' + fileName);
                if (mimeType != 'application/vnd.google-apps.folder') {
                    otherFiles.put(fileId, fileName);
                } 
            }
            
            // Query Google_Attachment__c records for other files
            List<Google_Attachment__c> existingAttachments = [SELECT Id, Google_Attachment_id__c 
                                                              FROM Google_Attachment__c 
                                                              WHERE Google_Attachment_id__c 
                                                              IN :otherFiles.keySet()];
            
            // Create a set to keep track of Google_Attachment_id__c values that already exist
            Set<String> existingAttachmentIds = new Set<String>();
            for (Google_Attachment__c attachment : existingAttachments) {
                existingAttachmentIds.add(attachment.Google_Attachment_id__c);
            }
            
            // Find other files that are not in Google_Attachment__c
            Map<String, String> unattachedFiles = new Map<String, String>();
            for (String fileId : otherFiles.keySet()) {
                if (!existingAttachmentIds.contains(fileId)) {
                    unattachedFiles.put(fileId, otherFiles.get(fileId));
                }
            }
            
            // Step 1: Extract the first 9 characters of the parent names and store them in a set
            Set<String> parentNameSubstrings = new Set<String>();
            Map<String, String> fileIdToParentName = new Map<String, String>();
            for (String fileId : unattachedFiles.keySet()) {
                Map<String, String> ParentDetail = GoogleAPIMethods.getParentFolderDetails(fileId);
                String parentName = ParentDetail.get('parentName');
                if (parentName != null 
                    && parentName.length() >= 9) {
                        String parentNameSubstring = parentName.substring(0, 9);
                        parentNameSubstrings.add(parentNameSubstring);
                        fileIdToParentName.put(fileId, parentNameSubstring);
                    }
            }
            
            // Step 2: Query for Journal__c records that match any of these names
            Map<String, Journal__c> parentNameToJournalId = new Map<String, Journal__c>();
            if (!parentNameSubstrings.isEmpty()) {
                List<Journal__c> journals = [SELECT Id, Name, Account__c 
                                             FROM Journal__c 
                                             WHERE Name IN :parentNameSubstrings];
                for (Journal__c journal : journals) {
                    parentNameToJournalId.put(journal.Name, journal);
                }
            }
            
            // Step 3: Collect all ContentVersion records to insert at once
            List<Google_Attachment__c> GAList = new List<Google_Attachment__c>();
            List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
            Map<Id, Journal__c> journalIdToContentVersionMap = new Map<Id, Journal__c>();
            for (String fileId : fileIdToParentName.keySet()) {
                String parentNameSubstring = fileIdToParentName.get(fileId);
                if (parentNameToJournalId.containsKey(parentNameSubstring)) {
                    Journal__c journal = parentNameToJournalId.get(parentNameSubstring);
                    Blob fileContent = GoogleAPIMethods.fetchGoogleDriveFileContent(fileId);
                    if (fileContent != null) {
                        ContentVersion contentVersion = new ContentVersion();contentVersion.Title = unattachedFiles.get(fileId);contentVersion.PathOnClient = unattachedFiles.get(fileId);contentVersion.FirstPublishLocationId = journal.Id;contentVersion.VersionData = fileContent;contentVersion.Related_Account_Id__c = journal.Account__c;contentVersion.Google_Drive_Id__c = fileId;contentVersionsToInsert.add(contentVersion);journalIdToContentVersionMap.put(contentVersion.Id, journal);
                        Google_Attachment__c GA = new Google_Attachment__c(Google_Attachment_id__c = fileId, Attachment_Id__c = contentVersion.id);
                        GAList.add(GA);
                    }
                }
            }
            
            // Insert all ContentVersion records at once
            if (!contentVersionsToInsert.isEmpty()) {
                Database.SaveResult[] contentVersionResults = Database.insert(contentVersionsToInsert, false);
                Database.SaveResult[] gaListResults = Database.insert(GAList, false);
                //  Map<String, String> CVwithIDs = new Map<String, String>(); 
              /*  List<ContentDocumentLink> CDLList = new List<ContentDocumentLink>();   
                for(ContentVersion cv: contentVersionsToInsert){
                  //  CDLList.add(AttachFile(cv.Id, cv.Related_Account_Id__c));
                }
                if (!CDLList.isEmpty()) {
                    Database.SaveResult[] CDLResults = Database.insert(CDLList, false);
                }*/
            }
            
        } catch(Exception ex) {
            System.debug('Exception occurred inside main fun: ' + ex.getMessage());
        }
    }
    
   /* public static ContentDocumentLink AttachFile(Id contentVersionId, Id recordId) {
        try {
            ContentDocumentLink contentLink = new ContentDocumentLink();
            contentLink.ContentDocumentId = [SELECT Id, ContentDocumentId 
                                             FROM ContentVersion 
                                             WHERE Id = :contentVersionId].ContentDocumentId;
            contentLink.LinkedEntityId = recordId;
            contentLink.ShareType = 'V';
            contentLink.Visibility = 'AllUsers';
            return contentLink;
        } catch (DmlException e) {
            System.debug('Error Attaching File: ' + e); 
            return NULL;
        }
    }*/
}