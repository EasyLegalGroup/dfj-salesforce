public class ContentVersionTriggerHander {
    
    public static void AttachAccount(List<ContentVersion> ContentVersionList){
        
        List<ContentDocumentLink> CDLList = new List<ContentDocumentLink>();   
        for(ContentVersion cv: ContentVersionList){
            if(cv.Related_Account_Id__c != NULL){
                CDLList.add(AttachFile(cv.Id, cv.Related_Account_Id__c));
            }
        }
        if (!CDLList.isEmpty()) {
            Database.SaveResult[] CDLResults = Database.insert(CDLList, false);
            for (Integer i = 0; i < CDLResults.size(); i++) {
                if (!CDLResults[i].isSuccess()) {
                    Database.Error error = CDLResults[i].getErrors()[0];
                    System.debug('CDLResults record ' + i + ' failed to insert attach. Error: ' + error.getMessage());
                }
            }
        }
    }
    
    
    public static ContentDocumentLink AttachFile(Id contentVersionId, Id recordId) {
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
    }
}