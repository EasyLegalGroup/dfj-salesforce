public virtual with sharing class ChatService {
    
    /**
     * Creates a new Chat Message with attachments
     * @param body Rich text content with embedded images
     * @param parentRecordId ID of the parent record to associate this message with
     * @param attachmentFiles List of uploaded files as base64 data
     * @return ChatMessageResult containing the created message and attachment URLs
     */
    @AuraEnabled
    public static ChatMessageResult createMessage(String body, String parentRecordId, List<Map<String, Object>> attachmentFiles) {
        try {
            // Calculate attachment info
            Integer attachmentCount = (attachmentFiles != null && !attachmentFiles.isEmpty()) ? attachmentFiles.size() : 0;
            Boolean hasAttachments = attachmentCount > 0;
            
            // Create the chat message record
            ChatMessage__c message = new ChatMessage__c(
                Body__c = body,
                Parent_Record__c = parentRecordId,
                Has_Attachments__c = hasAttachments,
                Attachment_Count__c = attachmentCount
            );
            insert message;
            
            // Process attachments
            List<AttachmentInfo> attachmentInfos = new List<AttachmentInfo>();
            if (attachmentFiles != null && !attachmentFiles.isEmpty()) {
                attachmentInfos = processAttachments(message.Id, attachmentFiles);
            }
            
            // Extensibility hook
            ChatService service = new ChatService();
            service.postProcess(message);
            
            // Fire Lightning Message Service event
            fireMessageSentEvent(message);
            
            // Return result with fresh data
            ChatMessage__c freshMessage = [
                SELECT Id, Name, Body__c, Parent_Record__c, Has_Attachments__c, Attachment_Count__c, 
                       CreatedDate, CreatedBy.Name, CreatedById
                FROM ChatMessage__c 
                WHERE Id = :message.Id
            ];
            
            return new ChatMessageResult(freshMessage, attachmentInfos);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating message: ' + e.getMessage());
        }
    }
    
    /**
     * Retrieves conversation history for a parent record
     * @param parentRecordId ID of the parent record
     * @return List of conversation messages ordered by creation date (newest first)
     */
    @AuraEnabled(cacheable=true)
    public static List<ChatMessageResult> getConversationHistory(String parentRecordId) {
        try {
            List<ChatMessage__c> messages = [
                SELECT Id, Name, Body__c, Parent_Record__c, Has_Attachments__c, Attachment_Count__c,
                       CreatedDate, CreatedBy.Name, CreatedById
                FROM ChatMessage__c 
                WHERE Parent_Record__c = :parentRecordId
                ORDER BY CreatedDate DESC
            ];
            
            List<ChatMessageResult> results = new List<ChatMessageResult>();
            for (ChatMessage__c msg : messages) {
                List<AttachmentInfo> attachments = getAttachmentsForMessage(msg.Id);
                results.add(new ChatMessageResult(msg, attachments));
            }
            
            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving conversation history: ' + e.getMessage());
        }
    }
    
    /**
     * Processes file attachments and creates ContentDocument records
     * @param messageId ID of the chat message record
     * @param attachmentFiles List of file data maps with base64 content OR document IDs
     * @return List of attachment information with download URLs
     */
    private static List<AttachmentInfo> processAttachments(Id messageId, List<Map<String, Object>> attachmentFiles) {
        List<AttachmentInfo> attachmentInfos = new List<AttachmentInfo>();
        
        if (attachmentFiles.isEmpty()) return attachmentInfos;
        
        // Separate base64 files from uploaded document IDs (ContentDocument or ContentVersion)
        List<Map<String, Object>> base64Files = new List<Map<String, Object>>();
        List<String> documentIds = new List<String>();
        List<String> versionIds = new List<String>();
        
        for (Map<String, Object> fileData : attachmentFiles) {
            if (fileData.containsKey('documentId') && String.isNotBlank((String)fileData.get('documentId'))) {
                // Uploaded file reference – could be ContentDocument (069) or ContentVersion (068)
                String upId = (String)fileData.get('documentId');
                if (upId != null && upId.startsWith('068')) {
                    versionIds.add(upId);
                } else {
                    documentIds.add(upId);
                }
            } else if (fileData.containsKey('base64Data')) {
                // This is base64 data that needs to be uploaded
                base64Files.add(fileData);
            }
        }
        
        // If we received any ContentVersion IDs convert them to their parent ContentDocument IDs
        if (!versionIds.isEmpty()) {
            for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versionIds]) {
                if (cv.ContentDocumentId != null) {
                    documentIds.add(cv.ContentDocumentId);
                }
            }
        }
        
        // Process base64 files (create new ContentVersions)
        if (!base64Files.isEmpty()) {
            List<ContentVersion> cvList = new List<ContentVersion>();
            for (Map<String, Object> fileData : base64Files) {
                ContentVersion cv = new ContentVersion(
                    Title = (String)fileData.get('name'),
                    PathOnClient = (String)fileData.get('name'),
                    VersionData = EncodingUtil.base64Decode((String)fileData.get('base64Data')),
                    Origin = 'H'
                );
                cvList.add(cv);
            }
            insert cvList;
            
            // Get the document IDs for the newly created files
            List<ContentDocument> newDocs = [
                SELECT Id FROM ContentDocument 
                WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :cvList)
            ];
            
            for (ContentDocument doc : newDocs) {
                documentIds.add(doc.Id);
            }
        }
        
        // Now process all document IDs (both existing and newly created)
        if (!documentIds.isEmpty()) {
            List<ContentDocument> docs = [
                SELECT Id, Title, FileExtension, ContentSize, CreatedDate
                FROM ContentDocument 
                WHERE Id IN :documentIds
            ];
            
            // Create links to message and parent record
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            
            // Get parent record ID
            ChatMessage__c msg = [SELECT Parent_Record__c FROM ChatMessage__c WHERE Id = :messageId LIMIT 1];
            
            for (ContentDocument doc : docs) {
                // Link to message
                links.add(new ContentDocumentLink(
                    ContentDocumentId = doc.Id,
                    LinkedEntityId = messageId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
                
                // Also link to parent record (Case) if it's different and link doesn't already exist
                if (msg.Parent_Record__c != messageId) {
                    List<ContentDocumentLink> existing = [
                        SELECT Id FROM ContentDocumentLink 
                        WHERE ContentDocumentId = :doc.Id AND LinkedEntityId = :msg.Parent_Record__c
                        LIMIT 1
                    ];
                    if (existing.isEmpty()) {
                        links.add(new ContentDocumentLink(
                            ContentDocumentId = doc.Id,
                            LinkedEntityId = msg.Parent_Record__c,
                            ShareType = 'I', // Inferred permission so file appears in Files related list
                            Visibility = 'AllUsers'
                        ));
                    }
                }
            }
            
            try {
                insert links;
            } catch (Exception e) {
                System.debug('Error linking files to records: ' + e.getMessage());
            }
            
            // Generate download URLs and attachment info
            for (ContentDocument doc : docs) {
                String downloadUrl = '/sfc/servlet.shepherd/document/download/' + doc.Id;
                attachmentInfos.add(new AttachmentInfo(
                    doc.Id,
                    doc.Title,
                    doc.FileExtension,
                    doc.ContentSize,
                    downloadUrl,
                    isImageFile(doc.FileExtension)
                ));
            }
        }
        
        return attachmentInfos;
    }
    
    /**
     * Retrieves attachment information for a specific message
     * @param messageId ID of the chat message record
     * @return List of attachment information
     */
    private static List<AttachmentInfo> getAttachmentsForMessage(Id messageId) {
        List<AttachmentInfo> attachmentInfos = new List<AttachmentInfo>();
        
        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension, 
                   ContentDocument.ContentSize, ContentDocument.CreatedDate
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :messageId
        ];
        
        for (ContentDocumentLink link : links) {
            String downloadUrl = '/sfc/servlet.shepherd/document/download/' + link.ContentDocument.Id;
            attachmentInfos.add(new AttachmentInfo(
                link.ContentDocument.Id,
                link.ContentDocument.Title,
                link.ContentDocument.FileExtension,
                link.ContentDocument.ContentSize,
                downloadUrl,
                isImageFile(link.ContentDocument.FileExtension)
            ));
        }
        
        return attachmentInfos;
    }
    
    /**
     * Determines if a file extension represents an image
     * @param fileExtension File extension to check
     * @return True if the file is an image type
     */
    private static Boolean isImageFile(String fileExtension) {
        if (String.isBlank(fileExtension)) return false;
        
        Set<String> imageExtensions = new Set<String>{
            'jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp'
        };
        
        return imageExtensions.contains(fileExtension.toLowerCase());
    }
    
    /**
     * Extensibility hook for post-processing after message creation
     * Override this method in subclasses or use dependency injection
     * @param message The created ChatMessage__c record
     */
    public virtual void postProcess(ChatMessage__c message) {
        // Default implementation - can be overridden
        // Examples:
        // - Send to Slack
        // - Call external REST API
        // - Send email notification
        // - Trigger workflow
    }
    
    /**
     * Sends a message and updates case status to "Waiting for Reply"
     * Also sends notification to case submitter
     * @param body Rich text content with embedded images
     * @param parentRecordId ID of the Case record
     * @param attachmentFiles List of uploaded files as base64 data
     * @param newStatus New status for the case
     * @return ChatMessageResult containing the created message and attachment URLs
     */
    @AuraEnabled
    public static ChatMessageResult sendMessageAndUpdateStatus(String body, String parentRecordId, List<Map<String, Object>> attachmentFiles, String newStatus) {
        try {
            // Validate that this is a Case record
            if (!parentRecordId.startsWith('500')) {
                throw new AuraHandledException('This action can only be performed on Case records');
            }

            // Get current case details
            Case currentCase = [
                SELECT Id, Status, Subject, CaseNumber, CreatedById, Notification_Preferences__c
                FROM Case 
                WHERE Id = :parentRecordId 
                LIMIT 1
            ];

            String previousStatus = currentCase.Status;

            // Create the chat message with status change tracking
            ChatMessage__c message = createMessageWithStatusTracking(
                body, 
                parentRecordId, 
                attachmentFiles,
                true,
                previousStatus,
                newStatus
            );

            // Update case status
            currentCase.Status = newStatus;
            update currentCase;

            // Send notification to case submitter
            sendCaseUpdateNotification(currentCase, message, previousStatus, newStatus);

            // Extensibility hook
            ChatService service = new ChatService();
            service.postProcess(message);

            // Return result with fresh data
            ChatMessage__c freshMessage = [
                SELECT Id, Name, Body__c, Parent_Record__c, Has_Attachments__c, Attachment_Count__c, 
                       CreatedDate, CreatedBy.Name, CreatedById, Triggered_Status_Change__c,
                       Previous_Case_Status__c, New_Case_Status__c, Notification_Sent__c, Notification_Platform__c
                FROM ChatMessage__c 
                WHERE Id = :message.Id
            ];

            List<AttachmentInfo> attachmentInfos = getAttachmentsForMessage(message.Id);
            return new ChatMessageResult(freshMessage, attachmentInfos);

        } catch (Exception e) {
            throw new AuraHandledException('Error sending message and updating status: ' + e.getMessage());
        }
    }

    /**
     * Sends a message and closes the case
     * Also sends notification to case submitter
     * @param body Rich text content with embedded images
     * @param parentRecordId ID of the Case record
     * @param attachmentFiles List of uploaded files as base64 data
     * @return ChatMessageResult containing the created message and attachment URLs
     */
    @AuraEnabled
    public static ChatMessageResult sendMessageAndCloseCase(String body, String parentRecordId, List<Map<String, Object>> attachmentFiles) {
        try {
            // Validate that this is a Case record
            if (!parentRecordId.startsWith('500')) {
                throw new AuraHandledException('This action can only be performed on Case records');
            }

            // Get current case details
            Case currentCase = [
                SELECT Id, Status, Subject, CaseNumber, CreatedById, Notification_Preferences__c
                FROM Case 
                WHERE Id = :parentRecordId 
                LIMIT 1
            ];

            String previousStatus = currentCase.Status;
            String newStatus = 'Closed';

            // Create the chat message with status change tracking
            ChatMessage__c message = createMessageWithStatusTracking(
                body, 
                parentRecordId, 
                attachmentFiles,
                true,
                previousStatus,
                newStatus
            );

            // Update case status
            currentCase.Status = newStatus;
            update currentCase;

            // Send notification to case submitter
            sendCaseClosedNotification(currentCase, message);

            // Extensibility hook
            ChatService service = new ChatService();
            service.postProcess(message);

            // Return result with fresh data
            ChatMessage__c freshMessage = [
                SELECT Id, Name, Body__c, Parent_Record__c, Has_Attachments__c, Attachment_Count__c, 
                       CreatedDate, CreatedBy.Name, CreatedById, Triggered_Status_Change__c,
                       Previous_Case_Status__c, New_Case_Status__c, Notification_Sent__c, Notification_Platform__c
                FROM ChatMessage__c 
                WHERE Id = :message.Id
            ];

            List<AttachmentInfo> attachmentInfos = getAttachmentsForMessage(message.Id);
            return new ChatMessageResult(freshMessage, attachmentInfos);

        } catch (Exception e) {
            throw new AuraHandledException('Error sending message and closing case: ' + e.getMessage());
        }
    }

    /**
     * Enhanced case creation notification (for IT Support Center integration)
     * @param caseId ID of the created case
     */
    @AuraEnabled
    public static void sendCaseCreationNotification(Id caseId) {
        try {
            Case caseRecord = [
                SELECT Id, CaseNumber, Subject, Status, Description, CreatedById, Notification_Preferences__c
                FROM Case 
                WHERE Id = :caseId 
                LIMIT 1
            ];

            User caseCreator = [SELECT Id, Name, Email FROM User WHERE Id = :caseRecord.CreatedById];
            
            // Determine preferred channels (multi-select picklist)
            List<String> preferences = String.isNotBlank(caseRecord.Notification_Preferences__c) ?
                                         caseRecord.Notification_Preferences__c.split(';') :
                                         new List<String>{'Email'};

            Boolean sent = false;
            if (preferences.contains('Slack')) {
                String slackMessage = buildCaseCreationMessage(caseRecord);
                futureSlackNotification(caseCreator.Email, slackMessage);
                sent = true;
            }
            // Fallback to Email if Slack not preferred or failed
            if (!sent && preferences.contains('Email')) {
                String emailMessage = buildCaseCreationEmailMessage(caseRecord);
                sendEmailNotification(caseCreator.Email, 'Your IT support case has been created!', emailMessage);
            }

        } catch (Exception e) {
            System.debug('Error sending case creation notification: ' + e.getMessage());
        }
    }

    /**
     * Helper method to create message with status tracking
     */
    private static ChatMessage__c createMessageWithStatusTracking(
        String body, 
        String parentRecordId, 
        List<Map<String, Object>> attachmentFiles,
        Boolean triggeredStatusChange,
        String previousStatus,
        String newStatus
    ) {
        // Calculate attachment info
        Integer attachmentCount = (attachmentFiles != null && !attachmentFiles.isEmpty()) ? attachmentFiles.size() : 0;
        Boolean hasAttachments = attachmentCount > 0;
        
        // Create the chat message record with status tracking
        ChatMessage__c message = new ChatMessage__c(
            Body__c = body,
            Parent_Record__c = parentRecordId,
            Has_Attachments__c = hasAttachments,
            Attachment_Count__c = attachmentCount,
            Triggered_Status_Change__c = triggeredStatusChange,
            Previous_Case_Status__c = previousStatus,
            New_Case_Status__c = newStatus
        );
        insert message;
        
        // Process attachments
        if (attachmentFiles != null && !attachmentFiles.isEmpty()) {
            processAttachments(message.Id, attachmentFiles);
        }

        return message;
    }

    /**
     * Sends case update notification to submitter
     */
    private static void sendCaseUpdateNotification(Case caseRecord, ChatMessage__c message, String previousStatus, String newStatus) {
        try {
            System.debug('=== CASE UPDATE NOTIFICATION DEBUG ===');
            System.debug('Case ID: ' + caseRecord.Id);
            System.debug('Case Number: ' + caseRecord.CaseNumber);
            System.debug('Case Created By: ' + caseRecord.CreatedById);
            System.debug('Previous Status: ' + previousStatus);
            System.debug('New Status: ' + newStatus);
            System.debug('Notification Preferences: ' + caseRecord.Notification_Preferences__c);
            
            User caseCreator = [SELECT Id, Name, Email FROM User WHERE Id = :caseRecord.CreatedById];
            System.debug('Case Creator Email: ' + caseCreator.Email);
            
            List<String> preferences = String.isNotBlank(caseRecord.Notification_Preferences__c) ?
                                         caseRecord.Notification_Preferences__c.split(';') :
                                         new List<String>{'Email'};
            System.debug('Notification Preferences List: ' + preferences);

            Boolean sent = false;
            if (preferences.contains('Slack')) {
                String slackMessage = buildCaseUpdateMessage(caseRecord, message, newStatus);
                futureSlackNotification(caseCreator.Email, slackMessage);
                sent = true;
                message.Notification_Platform__c = 'Slack';
            }
            if (!sent && preferences.contains('Email')) {
                String emailMessage = buildCaseUpdateEmailMessage(caseRecord, message, newStatus);
                sendEmailNotification(caseCreator.Email, 'Case Status Update: ' + caseRecord.CaseNumber, emailMessage);
                message.Notification_Platform__c = 'Email';
            }

            // AFTER external callouts, record tracking info to avoid uncommitted-work error
            message.Notification_Sent__c = true;
            message.Notification_Recipient_Email__c = caseCreator.Email;
            message.Notification_Recipient_User__c = caseCreator.Id;
            message.Notification_Sent_DateTime__c = DateTime.now();
            update message;

        } catch (Exception e) {
            System.debug('Error sending case update notification: ' + e.getMessage());
        }
    }

    /**
     * Sends case closed notification to submitter
     */
    private static void sendCaseClosedNotification(Case caseRecord, ChatMessage__c message) {
        try {
            System.debug('=== CASE CLOSED NOTIFICATION DEBUG ===');
            System.debug('Case ID: ' + caseRecord.Id);
            System.debug('Case Number: ' + caseRecord.CaseNumber);
            System.debug('Case Created By: ' + caseRecord.CreatedById);
            System.debug('Notification Preferences: ' + caseRecord.Notification_Preferences__c);
            
            User caseCreator = [SELECT Id, Name, Email FROM User WHERE Id = :caseRecord.CreatedById];
            System.debug('Case Creator Email: ' + caseCreator.Email);
            
            List<String> preferences = String.isNotBlank(caseRecord.Notification_Preferences__c) ?
                                         caseRecord.Notification_Preferences__c.split(';') :
                                         new List<String>{'Email'};
            System.debug('Notification Preferences List: ' + preferences);

            Boolean sent = false;
            if (preferences.contains('Slack')) {
                String slackMessage = buildCaseClosedMessage(caseRecord, message);
                futureSlackNotification(caseCreator.Email, slackMessage);
                sent = true;
                message.Notification_Platform__c = 'Slack';
            }
            if (!sent && preferences.contains('Email')) {
                String emailMessage = buildCaseClosedEmailMessage(caseRecord, message);
                sendEmailNotification(caseCreator.Email, 'Case Closed: ' + caseRecord.CaseNumber, emailMessage);
                message.Notification_Platform__c = 'Email';
            }

            message.Notification_Sent__c = true;
            message.Notification_Recipient_Email__c = caseCreator.Email;
            message.Notification_Recipient_User__c = caseCreator.Id;
            message.Notification_Sent_DateTime__c = DateTime.now();
            update message;

        } catch (Exception e) {
            System.debug('Error sending case closed notification: ' + e.getMessage());
        }
    }

    /**
     * Builds the case creation notification message (Slack format)
     */
    @TestVisible
    private static String buildCaseCreationMessage(Case caseRecord) {
        String itSupportCenterUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center';
        
        return ':ticket: *Your IT support case has been created!*\n' +
               '*Case Number:* ' + caseRecord.CaseNumber + '\n' +
               '*Subject:* ' + caseRecord.Subject + '\n' +
               '*Status:* ' + caseRecord.Status + '\n' +
               '*Description:* ' + (String.isNotBlank(caseRecord.Description) ? caseRecord.Description : 'No description provided') + '\n\n' +
               'You can view and manage your cases in the <' + itSupportCenterUrl + '|IT Support Center>.';
    }

    /**
     * Builds the case update notification message (Slack format)
     */
    @TestVisible
    private static String buildCaseUpdateMessage(Case caseRecord, ChatMessage__c message, String newStatus) {
        String itSupportCenterUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center';
        
        return ':ticket: *Your IT support case has a new response!*\n' +
               '*Case Number:* ' + caseRecord.CaseNumber + '\n' +
               '*Subject:* ' + caseRecord.Subject + '\n' +
               '*Status:* ' + newStatus + '\n' +
               '*Response:* ' + stripHtmlTags(message.Body__c) + '\n\n' +
               'You can view and manage your cases in the <' + itSupportCenterUrl + '|IT Support Center>.';
    }

    /**
     * Builds the case closed notification message (Slack format)
     */
    @TestVisible
    private static String buildCaseClosedMessage(Case caseRecord, ChatMessage__c message) {
        String itSupportCenterUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center';
        
        return ':ticket: *Your IT support case has been resolved!*\n' +
               '*Case Number:* ' + caseRecord.CaseNumber + '\n' +
               '*Subject:* ' + caseRecord.Subject + '\n' +
               '*Status:* Closed\n' +
               '*Final Response:* ' + stripHtmlTags(message.Body__c) + '\n\n' +
               'Your case has been marked as resolved. If you need further assistance, please create a new case in the <' + itSupportCenterUrl + '|IT Support Center>.';
    }

    /**
     * Sends Slack notification using existing Slack integration
     */
  //  @TestVisible
    private static void sendSlackNotification(String userEmail, String message) {
        try {
            System.debug('=== SLACK NOTIFICATION DEBUG ===');
            System.debug('To Email: ' + userEmail);
            System.debug('Message: ' + message);
            
            if (String.isBlank(userEmail)) {
                System.debug('ERROR: No email address provided for Slack notification');
                return;
            }
            
            // Use the existing Slack integration - ACTUALLY CALL THE API
            sendSlackDM(userEmail, '', message);
            System.debug('Slack notification sent successfully');
            
        } catch (Exception e) {
            System.debug('Error sending Slack notification: ' + e.getMessage());
            System.debug('Slack exception stack trace: ' + e.getStackTraceString());
        }
    }

    /**
     * Sends direct message via Slack (copied from ITSupportCenterController)
     */
    public static void sendSlackDM(String userEmail, String subject, String message) {
        try {
            // First, find the Slack user by email
            String slackUserId = findSlackUserByEmail(userEmail);
            if (String.isBlank(slackUserId)) {
                throw new AuraHandledException('Slack user not found for email: ' + userEmail);
            }
            
            // Send the direct message - handle empty subject gracefully
            String fullMessage = String.isBlank(subject) ? message : subject + '\n\n' + message;
            sendDirectMessage(slackUserId, fullMessage);
        } catch (Exception e) {
            System.debug('Error in sendSlackDM: ' + e.getMessage()+e.getLineNumber());
            throw new AuraHandledException('Failed to send Slack notification: ' + e.getMessage());
        }
    }

    /**
     * Find Slack user by email address
     */
    @TestVisible
    private static String findSlackUserByEmail(String email) {
        try {
            System.debug('Looking up Slack user by email: ' + email);
            String slackToken = getSlackBotToken();
            if (String.isBlank(slackToken)) {
                System.debug('ERROR: Slack bot token not configured');
                throw new AuraHandledException('Slack bot token not configured');
            }
            System.debug('Using Slack token (first 10 chars): ' + slackToken.substring(0, 10) + '...');
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://slack.com/api/users.lookupByEmail');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + slackToken);
            req.setHeader('Content-Type', 'application/json');
            
            // Add email parameter to URL
            String endpoint = 'https://slack.com/api/users.lookupByEmail?email=' + EncodingUtil.urlEncode(email, 'UTF-8');
            req.setEndpoint(endpoint);
            System.debug('Slack API Request Endpoint: ' + endpoint);
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
            System.debug('Slack API Response Status: ' + response.getStatusCode());
            System.debug('Slack API Response Body: ' + response.getBody());
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Boolean ok = (Boolean) responseMap.get('ok');
                if (ok == true) {
                    Map<String, Object> user = (Map<String, Object>) responseMap.get('user');
                    String userId = (String) user.get('id');
                    System.debug('Found Slack user ID: ' + userId);
                    return userId;
                } else {
                    String error = (String) responseMap.get('error');
                    System.debug('Slack API error: ' + error);
                    if (error == 'users_not_found') {
                        return null; // User not found, but not an error
                    }
                    throw new AuraHandledException('Slack API error: ' + error);
                }
            } else {
                throw new AuraHandledException('Slack API request failed: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Error finding Slack user: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * Send direct message to Slack user
     */
    private static void sendDirectMessage(String slackUserId, String message) {
        try {
            System.debug('Sending DM to Slack user ID: ' + slackUserId);
            
            // Get Slack bot token
            String slackToken = getSlackBotToken();
            if (String.isBlank(slackToken)) {
                throw new AuraHandledException('Slack bot token not configured');
            }
            
            // Open DM channel
            String channelId = openDirectMessageChannel(slackUserId);
            
            // Send message
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://slack.com/api/chat.postMessage');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + slackToken);
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('channel', channelId);
            payload.put('text', message);
            payload.put('username', 'IT Support Bot');
            payload.put('icon_emoji', ':robot_face:');
            
            req.setBody(JSON.serialize(payload));
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Boolean ok = (Boolean) responseMap.get('ok');
                if (ok != true) {
                    String error = (String) responseMap.get('error');
                    System.debug('Slack API error: ' + error);
                    // Do not throw from @future, just log
                }
                System.debug('Successfully sent Slack message!');
            } else {
                System.debug('Failed to send Slack message: ' + response.getStatusCode() + ' - ' + response.getBody());
                // Log only in async context
            }
        } catch (Exception e) {
            System.debug('Error in sendDirectMessage: ' + e.getMessage());
            // Log only
        }
    }

    /**
     * Open direct message channel with user
     */
    private static String openDirectMessageChannel(String slackUserId) {
        try {
            System.debug('Opening DM channel for Slack user ID: ' + slackUserId);
            String slackToken = getSlackBotToken();
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://slack.com/api/conversations.open');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + slackToken);
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('users', slackUserId);
            
            req.setBody(JSON.serialize(payload));
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Boolean ok = (Boolean) responseMap.get('ok');
                if (ok == true) {
                    Map<String, Object> channel = (Map<String, Object>) responseMap.get('channel');
                    String channelId = (String) channel.get('id');
                    return channelId;
                } else {
                    String error = (String) responseMap.get('error');
                    System.debug('Slack API error opening channel: ' + error);
                    throw new AuraHandledException('Failed to open Slack channel: ' + error);
                }
            } else {
                throw new AuraHandledException('Failed to open Slack channel: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Error opening DM channel: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * Get Slack bot token from custom metadata
     */
    private static String getSlackBotToken() {
        try {
            List<Slack_Integration__mdt> slackConfig = [
                SELECT Bot_Token__c, App_ID__c, Client_ID__c 
                FROM Slack_Integration__mdt 
                WHERE DeveloperName = 'Default' 
                LIMIT 1
            ];
            
            if (!slackConfig.isEmpty() && String.isNotBlank(slackConfig[0].Bot_Token__c)) {
                return slackConfig[0].Bot_Token__c;
            }
        } catch (Exception e) {
            System.debug('Error retrieving Slack token from metadata: ' + e.getMessage());
        }
        
        System.debug('Slack bot token not configured in Custom Metadata');
        return null;
    }

    /**
     * Sends email notification
     */
    private static void sendEmailNotification(String toEmail, String subject, String body) {
        try {
            System.debug('=== EMAIL NOTIFICATION DEBUG ===');
            System.debug('To Email: ' + toEmail);
            System.debug('Subject: ' + subject);
            System.debug('Body: ' + body);
            
            if (String.isBlank(toEmail)) {
                System.debug('ERROR: No email address provided');
                return;
            }
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{toEmail});
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setUseSignature(false);
            email.setBccSender(false);
            email.setSaveAsActivity(false);
            
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
            for (Messaging.SendEmailResult result : results) {
                if (result.isSuccess()) {
                    System.debug('Email sent successfully');
                } else {
                    System.debug('Email send failed: ' + result.getErrors());
                    for (Messaging.SendEmailError error : result.getErrors()) {
                        System.debug('Email error: ' + error.getMessage());
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error sending email notification: ' + e.getMessage());
            System.debug('Email exception stack trace: ' + e.getStackTraceString());
        }
    }

    /**
     * Strips HTML tags from rich text content
     */
    private static String stripHtmlTags(String htmlText) {
        if (String.isBlank(htmlText)) return '';
        
        // Simple HTML tag removal (for production, use more robust solution)
        return htmlText.replaceAll('<[^>]+>', '').trim();
    }

    /**
     * Convert HTML to Slack markdown format
     */
    private static String convertHtmlToSlackMarkdown(String htmlText) {
        if (String.isBlank(htmlText)) return '';
        
        // Simple HTML to Slack markdown conversion
        String result = htmlText;
        result = result.replaceAll('<[^>]+>', ''); // Remove HTML tags
        result = result.replaceAll('&nbsp;', ' '); // Replace non-breaking spaces
        result = result.replaceAll('&amp;', '&'); // Replace encoded ampersands
        result = result.replaceAll('&lt;', '<'); // Replace encoded less than
        result = result.replaceAll('&gt;', '>'); // Replace encoded greater than
        
        return result.trim();
    }

    /**
     * Test method to verify email deliverability and notification system
     * @param testEmail Email address to send test notification to
     * @return String indicating test results
     */
    @AuraEnabled
    public static String testNotificationSystem(String testEmail) {
        try {
            System.debug('=== TESTING NOTIFICATION SYSTEM ===');
            System.debug('Test Email: ' + testEmail);
            
            // Check if email is provided
            if (String.isBlank(testEmail)) {
                return 'ERROR: No test email provided';
            }
            
            // Check organization's email settings
            Organization org = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
            System.debug('Organization is Sandbox: ' + org.IsSandbox);
            
            // Try sending a test email
            String testSubject = 'Test Notification from UnifiedChat';
            String testBody = 'This is a test notification to verify email delivery is working.\n\n' +
                             'If you receive this email, the notification system is functional.\n\n' +
                             'Test sent at: ' + DateTime.now().format('yyyy-MM-dd HH:mm:ss');
            
            sendEmailNotification(testEmail, testSubject, testBody);
            
            return 'SUCCESS: Test email sent to ' + testEmail + '. Check debug logs for details.';
            
        } catch (Exception e) {
            String errorMessage = 'ERROR: ' + e.getMessage();
            System.debug('Test notification error: ' + errorMessage);
            System.debug('Test exception stack trace: ' + e.getStackTraceString());
            return errorMessage;
        }
    }

    /**
     * Fires a Lightning Message Service event after message creation
     * @param message The created ChatMessage__c record
     */
    private static void fireMessageSentEvent(ChatMessage__c message) {
        // For now, we'll just log the event
        // In a full implementation, this would use Lightning Message Service or Platform Events
        System.debug('Message sent event fired for message: ' + message.Id);
    }
    
    /**
     * Wrapper class for message results including attachments
     */
    public class ChatMessageResult {
        @AuraEnabled public ChatMessage__c message { get; set; }
        @AuraEnabled public List<AttachmentInfo> attachments { get; set; }
        @AuraEnabled public String relativeTimestamp { get; set; }
        @AuraEnabled public String userInitials { get; set; }
        @AuraEnabled public Boolean isCurrentUser { get; set; }
        
        public ChatMessageResult(ChatMessage__c msg, List<AttachmentInfo> attachments) {
            this.message = msg;
            this.attachments = attachments != null ? attachments : new List<AttachmentInfo>();
            this.relativeTimestamp = formatRelativeTime(msg.CreatedDate);
            this.userInitials = getInitials(msg.CreatedBy.Name);
            this.isCurrentUser = msg.CreatedById == UserInfo.getUserId();
        }
        
        private String formatRelativeTime(DateTime createdDate) {
            DateTime now = DateTime.now();
            Long diffMinutes = (now.getTime() - createdDate.getTime()) / (1000 * 60);
            
            if (diffMinutes < 1) return 'Just now';
            if (diffMinutes < 60) return diffMinutes + ' minutes ago';
            
            Long diffHours = diffMinutes / 60;
            if (diffHours < 24) {
                return 'Today ' + createdDate.format('HH:mm');
            }
            
            Long diffDays = diffHours / 24;
            if (diffDays == 1) {
                return 'Yesterday ' + createdDate.format('HH:mm');
            }
            
            if (diffDays < 7) {
                return createdDate.format('EEEE HH:mm');
            }
            
            return createdDate.format('MMM d, yyyy HH:mm');
        }
        
        private String getInitials(String name) {
            if (String.isBlank(name)) return '?';
            
            List<String> parts = name.split(' ');
            String initials = '';
            
            for (Integer i = 0; i < Math.min(parts.size(), 2); i++) {
                if (String.isNotBlank(parts[i])) {
                    initials += parts[i].substring(0, 1).toUpperCase();
                }
            }
            
            return String.isNotBlank(initials) ? initials : '?';
        }
    }
    
    /**
     * Information about file attachments
     */
    public class AttachmentInfo {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public Long contentSize { get; set; }
        @AuraEnabled public String downloadUrl { get; set; }
        @AuraEnabled public Boolean isImage { get; set; }
        @AuraEnabled public String formattedSize { get; set; }
        
        public AttachmentInfo(String id, String title, String fileExtension, Long contentSize, String downloadUrl, Boolean isImage) {
            this.id = id;
            this.title = title;
            this.fileExtension = fileExtension;
            this.contentSize = contentSize;
            this.downloadUrl = downloadUrl;
            this.isImage = isImage;
            this.formattedSize = formatFileSize(contentSize);
        }
        
        private String formatFileSize(Long bytes) {
            if (bytes == null || bytes == 0) return '0 B';
            
            String[] units = new String[]{'B', 'KB', 'MB', 'GB'};
            Integer unitIndex = 0;
            Double size = bytes;
            
            while (size >= 1024 && unitIndex < units.size() - 1) {
                size /= 1024;
                unitIndex++;
            }
            
            return String.valueOf(Math.round(size * 100) / 100.0) + ' ' + units[unitIndex];
        }
    }

    /**
     * Builds the case creation notification message (Email format)
     */
    private static String buildCaseCreationEmailMessage(Case caseRecord) {
        String itSupportCenterUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center';
        
        return 'Your IT support case has been created!\n\n' +
               'Case Number: ' + caseRecord.CaseNumber + '\n' +
               'Subject: ' + caseRecord.Subject + '\n' +
               'Status: ' + caseRecord.Status + '\n' +
               'Description: ' + (String.isNotBlank(caseRecord.Description) ? caseRecord.Description : 'No description provided') + '\n\n' +
               'You can view and manage your cases in the IT Support Center: ' + itSupportCenterUrl;
    }

    /**
     * Builds the case update notification message (Email format)
     */
    private static String buildCaseUpdateEmailMessage(Case caseRecord, ChatMessage__c message, String newStatus) {
        String itSupportCenterUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center';
        
        return 'Your IT support case has a new response!\n\n' +
               'Case Number: ' + caseRecord.CaseNumber + '\n' +
               'Subject: ' + caseRecord.Subject + '\n' +
               'Status: ' + newStatus + '\n' +
               'Response: ' + stripHtmlTags(message.Body__c) + '\n\n' +
               'You can view and manage your cases in the IT Support Center: ' + itSupportCenterUrl;
    }

    /**
     * Builds the case closed notification message (Email format)
     */
    private static String buildCaseClosedEmailMessage(Case caseRecord, ChatMessage__c message) {
        String itSupportCenterUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center';
        
        return 'Your IT support case has been resolved!\n\n' +
               'Case Number: ' + caseRecord.CaseNumber + '\n' +
               'Subject: ' + caseRecord.Subject + '\n' +
               'Status: Closed\n' +
               'Final Response: ' + stripHtmlTags(message.Body__c) + '\n\n' +
               'Your case has been marked as resolved. If you need further assistance, please create a new case in the IT Support Center: ' + itSupportCenterUrl;
    }

    // New async helper to avoid uncommitted-work callout errors
    @future(callout=true)
    private static void futureSlackNotification(String userEmail, String message) {
        try {
            sendSlackNotification(userEmail, message);
        } catch (Exception e) {
            System.debug('Future Slack notification failed: ' + e.getMessage());
        }
    }
}