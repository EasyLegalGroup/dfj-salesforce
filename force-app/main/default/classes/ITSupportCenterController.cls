public with sharing class ITSupportCenterController {
    
    @AuraEnabled(cacheable=true)
    public static User getUserInfo() {
        Id userId = UserInfo.getUserId();
        return [SELECT Id, Name, Email FROM User WHERE Id = :userId LIMIT 1];
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getITSupportRecordTypeId() {
        try {
            // Return the specific IT Support Record Type ID
            return '012W5000000N9XFIA0';
        } catch (Exception e) {
            System.debug('Error getting record type ID: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Case> getCases() {
        Id userId = UserInfo.getUserId();
        return [
            SELECT Id, Subject, Description, Status, Category__c, Severity__c, CreatedDate,
                   LastModifiedDate, Origin, Type, RecordTypeId, CreatedById, IsClosed
            FROM Case
            WHERE CreatedById = :userId
            ORDER BY CreatedDate DESC
        ];
    }
    
    @AuraEnabled(cacheable=false)
    public static List<CaseComment> getCaseComments(Id caseId) {
        System.debug('Fetching comments for case: ' + caseId);
        List<CaseComment> comments = [
            SELECT Id, ParentId, CommentBody, CreatedDate, CreatedById, CreatedBy.Name, IsPublished
            FROM CaseComment
            WHERE ParentId = :caseId
            AND IsPublished = true
            ORDER BY CreatedDate DESC
        ];
        System.debug('Found ' + comments.size() + ' comments');
        return comments;
    }
    
    @AuraEnabled
    public static CaseComment createCaseComment(Id caseId, String commentBody) {
        // Get case details for notification
        Case caseRecord = [SELECT Id, Subject, CreatedById, Notification_Preferences__c FROM Case WHERE Id = :caseId];
        
        CaseComment comment = new CaseComment(
            ParentId = caseId,
            CommentBody = commentBody,
            IsPublished = true
        );
        
    //    insert comment;  // Added by kajal (shifted after callout)
        
        // Send notification if comment is from someone other than the case creator
        if (UserInfo.getUserId() != caseRecord.CreatedById) {
            User caseCreator = [SELECT Id, Name, Email FROM User WHERE Id = :caseRecord.CreatedById];
            
            // Send notifications based on case preferences
            if (String.isNotBlank(caseRecord.Notification_Preferences__c)) {
                List<String> notificationTypes = caseRecord.Notification_Preferences__c.split(';');
                
                for (String notificationType : notificationTypes) {
                    switch on notificationType {
                        when 'Salesforce' {
                            sendNotificationToUser(
                                caseRecord.CreatedById,
                                'New Comment on Your Case',
                                'A new comment has been added to case: ' + caseRecord.Subject,
                                caseId
                            );
                        }
                        when 'Email' {
                            try {
                                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                mail.setToAddresses(new String[]{caseCreator.Email});
                                mail.setSubject('New Comment on Case: ' + caseRecord.Subject);
                                mail.setPlainTextBody('A new comment has been added to your IT support case:\n\n' +
                                                    'Case: ' + caseRecord.Subject + '\n' +
                                                    'Comment: ' + commentBody + '\n\n' +
                                                    'Please check the IT Support Center for details.');
                                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                            } catch (Exception e) {
                                System.debug('Error sending email notification for comment: ' + e.getMessage());
                            }
                        }
                        when 'Slack' {
                            try {
                                String slackMessage = '💬 *New comment on your IT support case*\n\n' +
                                                    '*Case:* ' + caseRecord.Subject + '\n' +
                                                    '*Comment:* ' + commentBody + '\n\n' +
                                                    '_Check the IT Support Center for full details._';
                                
                                sendSlackDM(
                                    caseCreator.Email,
                                    '',
                                    slackMessage
                                );
                            } catch (Exception e) {
                                System.debug('Error sending Slack notification for comment: ' + e.getMessage());
                            }
                        }
                    }
                }
               // insert comment;
              

            } else {
                // Default to Salesforce notification if no preferences set
                sendNotificationToUser(
                    caseRecord.CreatedById,
                    'New Comment on Your Case',
                    'A new comment has been added to case: ' + caseRecord.Subject,
                    caseId
                );
            }
        }
insert comment;
  //       System.debug('insertion');
        return [
            SELECT Id, ParentId, CommentBody, CreatedDate, CreatedById, CreatedBy.Name, IsPublished
            FROM CaseComment
            WHERE Id = :comment.Id
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getLastUsedNotificationPreferences() {
        Id userId = UserInfo.getUserId();
        List<Case> lastCase = [
            SELECT Id, Notification_Preferences__c 
            FROM Case 
            WHERE CreatedById = :userId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        if (!lastCase.isEmpty() && lastCase[0].Notification_Preferences__c != null) {
            return lastCase[0].Notification_Preferences__c.split(';');
        }
        
        // Default to email notifications if no previous preferences
        return new List<String>{'Email'};
    }

    public class NotificationRequest {
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public List<String> notificationTypes { get; set; }
    }

    @AuraEnabled
    public static void sendNotifications(NotificationRequest request) {
        try {
            if (request == null || request.caseId == null || request.notificationTypes == null || request.notificationTypes.isEmpty()) {
                throw new AuraHandledException('Invalid notification request parameters');
            }

            Case caseRecord = [SELECT Id, Subject, Description, CaseNumber, Status, CreatedById FROM Case WHERE Id = :request.caseId];
            if (caseRecord == null) {
                throw new AuraHandledException('Case not found');
            }

            User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
            if (currentUser == null || String.isBlank(currentUser.Email)) {
                throw new AuraHandledException('User email not found');
            }
            
            for (String notificationType : request.notificationTypes) {
                if (String.isBlank(notificationType)) continue;
                
                switch on notificationType {
                    when 'Salesforce' {
                        sendNotificationToUser(
                            caseRecord.CreatedById,
                            'Case Status Update',
                            getNotificationMessage(caseRecord),
                            request.caseId
                        );
                    }
                    when 'Email' {
                        try {
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            mail.setToAddresses(new String[]{currentUser.Email});
                            mail.setSubject('Case Status Update: ' + caseRecord.CaseNumber);
                            mail.setPlainTextBody(getNotificationMessage(caseRecord));
                            mail.setUseSignature(false);
                            mail.setBccSender(false);
                            mail.setSaveAsActivity(false);
                            
                            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                        } catch (Exception e) {
                            System.debug('Error sending email notification: ' + e.getMessage());
                        }
                    }
                    when 'Slack' {
                        try {
                            sendSlackDM(
                                currentUser.Email,
                                '',
                                getSlackNotificationMessage(caseRecord)
                            );
                        } catch (Exception e) {
                            System.debug('Error sending Slack notification: ' + e.getMessage());
                        }
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

   // @TestVisible
    private static String getNotificationMessage(Case caseRecord) {
        String message = '';
        
        if (caseRecord.Status == 'New') {
            message = 'Your IT support case has been created!\n\n';
        } else if (caseRecord.Status == 'Closed') {
            message = 'Your IT support case has been resolved!\n\n';
        } else if (caseRecord.Status == 'Awaiting Reply') {
            message = 'Your IT support case requires your attention:\n\n';
        } else {
            message = 'Your IT support case has been updated:\n\n';
        }
        
        message += 'Case Number: ' + caseRecord.CaseNumber + '\n' +
                  'Subject: ' + caseRecord.Subject + '\n' +
                  'Status: ' + caseRecord.Status + '\n' +
                  'Description: ' + caseRecord.Description + '\n\n' +
                  'You can view and manage your cases in the IT Support Center: ' +
                  URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center';
        
        return message;
    }

    public static void sendNotificationToUser(Id userId, String title, String body, Id targetId) {
        try {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(body);
            notification.setNotificationTypeId('0MLW50000005y1xOAA');
            notification.setTargetId(targetId);
            notification.send(new Set<String>{userId});
        } catch (Exception e) {
            System.debug('Error sending Salesforce notification: ' + e.getMessage());
        }
    }

    // Slack Integration Methods
    @AuraEnabled
    public static void sendSlackDM(String userEmail, String subject, String message) {
        try {
            // First, find the Slack user by email
            String slackUserId = findSlackUserByEmail(userEmail);
           
            if (String.isBlank(slackUserId)) {
                throw new AuraHandledException('Slack user not found for email: ' + userEmail);
            }
            
            // Send DM to the user - handle empty subject gracefully
            String fullMessage = String.isBlank(subject) ? message : subject + '\n\n' + message;
            sendDirectMessage(slackUserId, fullMessage);
            
        } catch (Exception e) {
            System.debug('Error in sendSlackDM: ' + e.getMessage()+e.getLineNumber());
            throw new AuraHandledException('Failed to send Slack notification: ' + e.getMessage());
        }
    }
    
    @TestVisible
    private static String findSlackUserByEmail(String email) {
        try {
           
            String slackToken = getSlackBotToken();
            if (String.isBlank(slackToken)) {
                System.debug('ERROR: Slack bot token not configured');
                throw new AuraHandledException('Slack bot token not configured');
            }
          
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://slack.com/api/users.lookupByEmail');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + slackToken);
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            // Add email parameter
            String endpoint = 'https://slack.com/api/users.lookupByEmail?email=' + EncodingUtil.urlEncode(email, 'UTF-8');
            req.setEndpoint(endpoint);
         
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
                      
            if (response.getStatusCode() == 200) {

                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
               Boolean ok = (Boolean) responseBody.get('ok');
              
                if (ok) {
                   
                    Map<String, Object> user = (Map<String, Object>) responseBody.get('user');
                   
                    String userId = (String) user.get('id');
                     System.debug('userId--'+userId);
                    return userId;
                } else {
                    String error = (String) responseBody.get('error');
                  
                    return null;
                }
            } else {
                System.debug('HTTP error: ' + response.getStatusCode() + ' - ' + response.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Error finding Slack user: ' + e.getMessage());
            return null;
        }
    }
    
    private static void sendDirectMessage(String slackUserId, String message) {
        try {
         
            
            String slackToken = getSlackBotToken();
            if (String.isBlank(slackToken)) {
                throw new AuraHandledException('Slack bot token not configured');
            }
            
            // First, open a DM channel with the user
            String channelId = openDirectMessageChannel(slackUserId);
          
            if (String.isBlank(channelId)) {
                throw new AuraHandledException('Failed to open DM channel');
            }
          
            
            // Send the message to the DM channel
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://slack.com/api/chat.postMessage');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + slackToken);
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('channel', channelId);
            payload.put('text', message);
            payload.put('username', 'IT Support Center');
            payload.put('icon_emoji', ':computer:');
            
            String jsonPayload = JSON.serialize(payload);
            req.setBody(jsonPayload);
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
          
            
            if (response.getStatusCode() != 200) {
                throw new AuraHandledException('Failed to send Slack message');
            }
            
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Boolean ok = (Boolean) responseBody.get('ok');
            
            if (!ok) {
                String error = (String) responseBody.get('error');
                throw new AuraHandledException('Slack API error: ' + error);
            }
            
            
        } catch (Exception e) {
            System.debug('Error sending direct message: ' + e.getMessage());
            throw new AuraHandledException('Failed to send Slack DM: ' + e.getMessage());
        }
    }
    
 //   @TestVisible
    private static String openDirectMessageChannel(String slackUserId) {
        try {
            String slackToken = getSlackBotToken();
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://slack.com/api/conversations.open');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + slackToken);
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('users', slackUserId);
            
            String jsonPayload = JSON.serialize(payload);
            req.setBody(jsonPayload);
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
        
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Boolean ok = (Boolean) responseBody.get('ok');
                
                if (ok) {
                    Map<String, Object> channel = (Map<String, Object>) responseBody.get('channel');
                    String channelId = (String) channel.get('id');
                    return channelId;
                } else {
                    String error = (String) responseBody.get('error');
                    System.debug('Slack API error opening channel: ' + error);
                }
            }
            
            return null;
            
        } catch (Exception e) {
            System.debug('Error opening DM channel: ' + e.getMessage());
            return null;
        }
    }
    
    private static String getSlackBotToken() {
        // Retrieve token from Custom Metadata
        try {
            List<Slack_Integration__mdt> slackConfig = [
                SELECT Bot_Token__c 
                FROM Slack_Integration__mdt 
                WHERE DeveloperName = 'dinfamiliejurist_dk' 
                LIMIT 1
            ];
            
            if (!slackConfig.isEmpty() && String.isNotBlank(slackConfig[0].Bot_Token__c)) {
                return slackConfig[0].Bot_Token__c;
            }
        } catch (Exception e) {
            System.debug('Error retrieving Slack token from metadata: ' + e.getMessage());
        }
        
        // Fallback: Return null if not configured
        System.debug('Slack bot token not configured in Custom Metadata');
        return null;
    }

 //   @TestVisible
    private static String getSlackNotificationMessage(Case caseRecord) {
        String message = '';
        String itSupportCenterUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center';
        
        if (caseRecord.Status == 'New') {
            message = ':ticket: *Your IT support case has been created!*\n\n';
        } else if (caseRecord.Status == 'Closed') {
            message = ':ticket: *Your IT support case has been resolved!*\n\n';
        } else if (caseRecord.Status == 'Awaiting Reply') {
            message = ':clock10: *Your IT support case requires your attention:*\n\n';
        } else {
            message = ':arrows_counterclockwise: *Your IT support case has been updated:*\n\n';
        }
        
        // Convert HTML description to Slack markdown
        String cleanDescription = convertHtmlToSlackMarkdown(caseRecord.Description);
        
        message += '*Case Number:* ' + caseRecord.CaseNumber + '\n' +
                  '*Subject:* ' + caseRecord.Subject + '\n' +
                  '*Status:* ' + caseRecord.Status + '\n' +
                  '*Description:* ' + cleanDescription + '\n\n' +
                  'You can view and manage your cases in the <' + itSupportCenterUrl + '|IT Support Center>.';
        
        return message;
    }

    // Knowledge Search Methods
    @AuraEnabled(cacheable=false)
    public static List<KnowledgeSearchResult> searchKnowledgeArticles(String searchTerm, Integer limitCount) {
        List<KnowledgeSearchResult> results = new List<KnowledgeSearchResult>();
        
        try {
            if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
                return results;
            }
            
            // Clean and prepare search term
            String cleanSearchTerm = String.escapeSingleQuotes(searchTerm.trim());
            Integer searchLimit = limitCount != null && limitCount > 0 ? limitCount : 5;
            
            // SOSL search across knowledge articles
            String soslQuery = 'FIND \'' + cleanSearchTerm + '\' IN ALL FIELDS ' +
                              'RETURNING Knowledge__kav(' +
                              'Id, Title, Summary, Answer__c, RecordType.Name, ' +
                              'LastModifiedDate, PublishStatus, Language ' +
                              'WHERE PublishStatus = \'Online\' AND Language = \'en_US\' ' +
                              'ORDER BY LastModifiedDate DESC ' +
                              'LIMIT ' + searchLimit + ')';
      
            List<List<SObject>> searchResults = Search.query(soslQuery);
            if (!searchResults.isEmpty() && !searchResults[0].isEmpty()) {
                for (Knowledge__kav article : (List<Knowledge__kav>)searchResults[0]) {
                    KnowledgeSearchResult result = new KnowledgeSearchResult();
                    result.id = article.Id;
                    result.title = article.Title;
                    result.summary = article.Summary;
                    result.answer = stripHtmlTags(article.Answer__c);
                    result.recordTypeName = article.RecordType?.Name;
                    result.lastModified = article.LastModifiedDate;
                    result.relevanceScore = calculateEnhancedRelevanceScore(cleanSearchTerm, article);
                    
                    results.add(result);
                }
                
                // Sort by relevance score
                results.sort();
            }
            
            // If SOSL returns no results or few results, try enhanced SOQL fallback
            if (results.size() < 3) {
                List<KnowledgeSearchResult> soqlResults = performEnhancedSOQLKnowledgeSearch(cleanSearchTerm, searchLimit);
                
                // Merge results, avoiding duplicates
                Set<String> existingIds = new Set<String>();
                for (KnowledgeSearchResult existing : results) {
                    existingIds.add(existing.id);
                }
                
                for (KnowledgeSearchResult soqlResult : soqlResults) {
                    if (!existingIds.contains(soqlResult.id)) {
                        results.add(soqlResult);
                    }
                }
                
                // Sort combined results
                results.sort();
                
                // Limit to requested size
                if (results.size() > searchLimit) {
                    List<KnowledgeSearchResult> limitedResults = new List<KnowledgeSearchResult>();
                    for (Integer i = 0; i < searchLimit && i < results.size(); i++) {
                        limitedResults.add(results[i]);
                    }
                    results = limitedResults;
                }
            }
            
        } catch (Exception e) {
            System.debug('Error searching knowledge articles: ' + e.getMessage());
            // Return empty results rather than throwing exception for better UX
        }
        
        return results;
    }
    
  //  @TestVisible
    private static List<KnowledgeSearchResult> performEnhancedSOQLKnowledgeSearch(String searchTerm, Integer searchLimit) {
        List<KnowledgeSearchResult> results = new List<KnowledgeSearchResult>();
        
        try {
            // Tokenize search term for more flexible matching
            List<String> searchTokens = getSearchTokens(searchTerm);
            
            // Build dynamic SOQL with multiple LIKE conditions
            String baseQuery = 'SELECT Id, Title, Summary, Answer__c, RecordType.Name, LastModifiedDate ' +
                              'FROM Knowledge__kav ' +
                              'WHERE PublishStatus = \'Online\' AND Language = \'en_US\' AND (';
            
            List<String> conditions = new List<String>();
            List<String> bindVariables = new List<String>();
            
            // Add conditions for each token
            for (Integer i = 0; i < searchTokens.size(); i++) {
                String token = '%' + searchTokens[i] + '%';
                bindVariables.add(token);
                conditions.add('Title LIKE :token' + i);
                conditions.add('Summary LIKE :token' + i);
            }
            
            // Execute multiple queries with different token combinations
            Set<String> foundArticleIds = new Set<String>();
            
            // First: Search for exact phrase in title
            String exactPattern = '%' + searchTerm + '%';
            List<Knowledge__kav> exactMatches = Database.query(
                'SELECT Id, Title, Summary, Answer__c, RecordType.Name, LastModifiedDate ' +
                'FROM Knowledge__kav ' +
                'WHERE PublishStatus = \'Online\' AND Language = \'en_US\' ' +
                'AND Title LIKE :exactPattern ' +
                'ORDER BY LastModifiedDate DESC LIMIT ' + searchLimit
            );
            
            for (Knowledge__kav article : exactMatches) {
                if (!foundArticleIds.contains(article.Id)) {
                    foundArticleIds.add(article.Id);
                    results.add(createSearchResult(article, searchTerm, 150)); // Boost for exact title match
                }
            }
            
            if (results.size() < searchLimit && searchTokens.size() > 1) {
                for (String token : searchTokens) {
                    if (token.length() >= 3) { // Only search meaningful tokens
                        String tokenPattern = '%' + token + '%';
                        List<Knowledge__kav> tokenMatches = Database.query(
                            'SELECT Id, Title, Summary, Answer__c, RecordType.Name, LastModifiedDate ' +
                            'FROM Knowledge__kav ' +
                            'WHERE PublishStatus = \'Online\' AND Language = \'en_US\' ' +
                            'AND (Title LIKE :tokenPattern OR Summary LIKE :tokenPattern) ' +
                            'ORDER BY LastModifiedDate DESC LIMIT ' + (searchLimit * 2)
                        );
                        
                        for (Knowledge__kav article : tokenMatches) {
                            if (!foundArticleIds.contains(article.Id) && results.size() < searchLimit) {
                                foundArticleIds.add(article.Id);
                                results.add(createSearchResult(article, searchTerm, 75)); // Lower boost for token match
                            }
                        }
                    }
                }
            }
            
            results.sort();
            
        } catch (Exception e) {
            System.debug('Error in enhanced SOQL knowledge search: ' + e.getMessage());
        }
        
        return results;
    }
    
  //  @TestVisible
    private static List<String> getSearchTokens(String searchTerm) {
        List<String> tokens = new List<String>();
        
        // Split by spaces and common words, filter out stop words
        Set<String> stopWords = new Set<String>{
            'the', 'is', 'at', 'which', 'on', 'a', 'an', 'and', 'or', 'but', 'in', 'with', 'to', 'for', 'of', 'as', 'by',
            'my', 'i', 'me', 'we', 'you', 'they', 'them', 'this', 'that', 'these', 'those', 'am', 'are', 'was', 'were',
            'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
            'not', 'no', 'can', 'cannot', 'cant', 'wont', 'dont', 'doesnt', 'didnt', 'isnt', 'arent', 'wasnt', 'werent'
        };
        
        String[] words = searchTerm.toLowerCase().split('\\s+');
        
        for (String word : words) {
            // Remove punctuation and clean the word
            String cleanWord = word.replaceAll('[^a-zA-Z0-9]', '');
            
            // Add meaningful words (not stop words and length >= 2)
            if (cleanWord.length() >= 2 && !stopWords.contains(cleanWord)) {
                tokens.add(cleanWord);
            }
        }
        
        return tokens;
    }
    
  //  @TestVisible
    private static KnowledgeSearchResult createSearchResult(Knowledge__kav article, String searchTerm, Integer baseScore) {
        KnowledgeSearchResult result = new KnowledgeSearchResult();
        result.id = article.Id;
        result.title = article.Title;
        result.summary = article.Summary;
        result.answer = stripHtmlTags(article.Answer__c);
        result.recordTypeName = article.RecordType?.Name;
        result.lastModified = article.LastModifiedDate;
        result.relevanceScore = calculateEnhancedRelevanceScore(searchTerm, article) + baseScore;
        
        return result;
    }
    
    private static Integer calculateEnhancedRelevanceScore(String searchTerm, Knowledge__kav article) {
        Integer score = 0;
        String lowerSearchTerm = searchTerm.toLowerCase();
        List<String> searchTokens = getSearchTokens(searchTerm);
        
        String lowerTitle = article.Title?.toLowerCase();
        String lowerSummary = article.Summary?.toLowerCase();
        String lowerAnswer = stripHtmlTags(article.Answer__c)?.toLowerCase();
        
        // Exact title match gets highest score
        if (String.isNotBlank(lowerTitle) && lowerTitle.contains(lowerSearchTerm)) {
            score += 100;
        }
        
        // Exact summary match gets high score
        if (String.isNotBlank(lowerSummary) && lowerSummary.contains(lowerSearchTerm)) {
            score += 75;
        }
        
        // Answer match gets medium score
        if (String.isNotBlank(lowerAnswer) && lowerAnswer.contains(lowerSearchTerm)) {
            score += 50;
        }
        
        // Token matching in title
        for (String token : searchTokens) {
            if (String.isNotBlank(lowerTitle) && lowerTitle.contains(token)) {
                score += 30;
            }
            if (String.isNotBlank(lowerSummary) && lowerSummary.contains(token)) {
                score += 20;
            }
            if (String.isNotBlank(lowerAnswer) && lowerAnswer.contains(token)) {
                score += 10;
            }
        }
        
        // Boost for exact title match
        if (String.isNotBlank(lowerTitle) && lowerTitle.equals(lowerSearchTerm)) {
            score += 150;
        }
        
        return score;
    }
    
    @AuraEnabled(cacheable=true)
    public static KnowledgeArticleDetail getKnowledgeArticleDetail(String articleId) {
        try {
            Knowledge__kav article = [
                SELECT Id, Title, Summary, Answer__c, RecordType.Name, 
                       LastModifiedDate, CreatedDate, KnowledgeArticleId
                FROM Knowledge__kav 
                WHERE Id = :articleId 
                AND PublishStatus = 'Online'
                LIMIT 1
            ];
            
            KnowledgeArticleDetail detail = new KnowledgeArticleDetail();
            detail.id = article.Id;
            detail.title = article.Title;
            detail.summary = article.Summary;
            detail.answer = article.Answer__c;
            detail.recordTypeName = article.RecordType?.Name;
            detail.lastModified = article.LastModifiedDate;
            detail.created = article.CreatedDate;
            detail.knowledgeArticleId = article.KnowledgeArticleId;
            detail.articleUrl = buildKnowledgeArticleUrl(article.KnowledgeArticleId);
            
            return detail;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving knowledge article: ' + e.getMessage());
        }
    }
    
    private static String buildKnowledgeArticleUrl(String knowledgeArticleId) {
        try {
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            return baseUrl + '/lightning/r/Knowledge__kav/' + knowledgeArticleId + '/view';
        } catch (Exception e) {
            System.debug('Error building knowledge article URL: ' + e.getMessage());
            return null;
        }
    }
    
    private static String stripHtmlTags(String htmlText) {
        if (String.isBlank(htmlText)) {
            return '';
        }
        return htmlText.replaceAll('<[^>]*>', '').trim();
    }
    
    // Wrapper classes for knowledge search
    public class KnowledgeSearchResult implements Comparable {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String summary { get; set; }
        @AuraEnabled public String answer { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
        @AuraEnabled public DateTime lastModified { get; set; }
        @AuraEnabled public Integer relevanceScore { get; set; }
        
        public Integer compareTo(Object compareTo) {
            KnowledgeSearchResult other = (KnowledgeSearchResult)compareTo;
            if (this.relevanceScore > other.relevanceScore) {
                return -1;
            } else if (this.relevanceScore < other.relevanceScore) {
                return 1;
            } else {
                return 0;
            }
        }
    }
    
    public class KnowledgeArticleDetail {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String summary { get; set; }
        @AuraEnabled public String answer { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
        @AuraEnabled public DateTime lastModified { get; set; }
        @AuraEnabled public DateTime created { get; set; }
        @AuraEnabled public String knowledgeArticleId { get; set; }
        @AuraEnabled public String articleUrl { get; set; }
    }

    // Mark Case as Solved functionality
    @AuraEnabled
    public static void markCaseAsSolved(Id caseId) {
        try {
            if (caseId == null) {
                throw new AuraHandledException('Case ID is required');
            }

            Id currentUserId = UserInfo.getUserId();
            
            // Get case details and verify the current user is the case creator
            Case caseRecord = [
                SELECT Id, Subject, Status, CreatedById, Notification_Preferences__c, CaseNumber
                FROM Case 
                WHERE Id = :caseId 
                LIMIT 1
            ];
            System.debug('caseRecord-->'+caseRecord);
            if (caseRecord == null) {
                throw new AuraHandledException('Case not found');
            }
            
            // Only allow case creator to mark their own case as solved
            if (caseRecord.CreatedById != currentUserId) {
                throw new AuraHandledException('You can only mark your own cases as solved');
            }
            
            // Don't allow marking already closed cases as solved
            if (caseRecord.Status == 'Closed') {
                throw new AuraHandledException('This case is already closed');
            }

            // Update the case with the required fields
            caseRecord.Status = 'Closed';
            caseRecord.Was_Closed_by_Submitter__c = true;
            // Note: Closed_By__c field might not exist, keeping it commented
            // caseRecord.Closed_By__c = currentUserId;
            
          //  update caseRecord;    //  added by kajal (shifted insert after callout)
            // Add a case comment to track that user closed it themselves
            CaseComment closureComment = new CaseComment(
                ParentId = caseId,
                CommentBody = 'Case marked as solved by the case submitter via IT Support Center.',
                IsPublished = true
            );
        //    insert closureComment;   //  added by kajal (shifted insert after callout)
         //   System.debug('inserted successfullt');
         //   System.debug(' closureComment--'+ closureComment);
            // Send confirmation notification to user
            User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :currentUserId LIMIT 1];
            // Send notification based on case preferences
           
            if (String.isNotBlank(caseRecord.Notification_Preferences__c)) {
                List<String> notificationTypes = caseRecord.Notification_Preferences__c.split(';');
                
                for (String notificationType : notificationTypes) {
                    switch on notificationType {
                        when 'Email' {
                            try {
                                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                mail.setToAddresses(new String[]{currentUser.Email});
                                mail.setSubject('Case Closed: ' + caseRecord.CaseNumber);
                                mail.setPlainTextBody(
                                    'Your IT support case has been marked as solved.\n\n' +
                                    'Case Number: ' + caseRecord.CaseNumber + '\n' +
                                    'Subject: ' + caseRecord.Subject + '\n' +
                                    'Status: Closed\n\n' +
                                    'Thank you for using the IT Support Center. If you need further assistance, please create a new case.'
                                );
                                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                            } catch (Exception e) {
                                System.debug('Error sending email confirmation: ' + e.getMessage());
                            }
                        }
                        when 'Slack' {
                            try {
                                String slackMessage = '✅ *Your IT support case has been marked as solved*\n\n' +
                                                    '*Case Number:* ' + caseRecord.CaseNumber + '\n' +
                                                    '*Subject:* ' + caseRecord.Subject + '\n' +
                                                    '*Status:* Closed\n\n' +
                                                    '_Thank you for using the IT Support Center! If you need further assistance, please create a new case._';
                                
                                sendSlackDM(
                                    currentUser.Email,
                                    '',
                                    slackMessage
                                );
                            } catch (Exception e) {
                                System.debug('Error sending Slack confirmation: ' + e.getMessage());
                            }
                        }
                        when 'Salesforce' {
                            try {
                                sendNotificationToUser(
                                    currentUserId,
                                    'Case Marked as Solved',
                                    'Your case "' + caseRecord.Subject + '" has been marked as solved and closed.',
                                    caseId
                                );
                            } catch (Exception e) {
                                System.debug('Error sending Salesforce notification: ' + e.getMessage());
                            }
                        }
                    }
                }
                update caseRecord;

                 insert closureComment;

            } else {
                // Default to email notification if no preferences set
                try {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[]{currentUser.Email});
                    mail.setSubject('Case Closed: ' + caseRecord.CaseNumber);
                    mail.setPlainTextBody(
                        'Your IT support case has been marked as solved.\n\n' +
                        'Case Number: ' + caseRecord.CaseNumber + '\n' +
                        'Subject: ' + caseRecord.Subject + '\n' +
                        'Status: Closed\n\n' +
                        'Thank you for using the IT Support Center. If you need further assistance, please create a new case.'
                    );
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                } catch (Exception e) {
                    System.debug('Error sending default email confirmation: ' + e.getMessage());
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in markCaseAsSolved: ' + e.getMessage() +e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    // IT Support Response functionality
    @AuraEnabled
    public static void sendSupportResponse(Id caseId, String responseMessage, List<String> fileIds) {
        try {
            System.debug('=== sendSupportResponse START ===');
            System.debug('Case ID: ' + caseId);
            System.debug('Response Message: ' + responseMessage);
            System.debug('File IDs: ' + fileIds);
            
            if (caseId == null) {
                throw new AuraHandledException('Case ID is required');
            }
            
            if (String.isBlank(responseMessage)) {
                throw new AuraHandledException('Response message is required');
            }

            // Get case details and case creator information
            Case caseRecord = [
                SELECT Id, Subject, Status, CreatedById, Notification_Preferences__c, CaseNumber
                FROM Case 
                WHERE Id = :caseId 
                LIMIT 1
            ];
            
            System.debug('Case found: ' + caseRecord);
            System.debug('Case Notification Preferences: ' + caseRecord.Notification_Preferences__c);
            
            if (caseRecord == null) {
                throw new AuraHandledException('Case not found');
            }

            // Get case creator details
            User caseCreator = [
                SELECT Id, Name, Email 
                FROM User 
                WHERE Id = :caseRecord.CreatedById 
                LIMIT 1
            ];
            
            System.debug('Case Creator: ' + caseCreator.Name + ' (' + caseCreator.Email + ')');

            // Get current user (IT Support person) details
            User currentUser = [
                SELECT Id, Name, Email 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
            
            System.debug('Current User (IT Support): ' + currentUser.Name + ' (' + currentUser.Email + ')');

            // IMPORTANT: Send Slack notification BEFORE doing any DML operations
            // to avoid "uncommitted work pending" error
            Boolean slackNotificationSent = false;
            String slackError = null;
            Boolean hasAttachments = fileIds != null && !fileIds.isEmpty();
            
            if (String.isNotBlank(caseRecord.Notification_Preferences__c)) {
                List<String> notificationTypes = caseRecord.Notification_Preferences__c.split(';');
                System.debug('Notification types to process: ' + notificationTypes);
                
                // First pass: Send Slack notifications (before DML)
                for (String notificationType : notificationTypes) {
                    if (notificationType == 'Slack') {
                        try {
                            System.debug('=== SENDING SLACK NOTIFICATION (BEFORE DML) ===');
                            System.debug('To Email: ' + caseCreator.Email);
                            
                            String plainTextMessage = stripHtmlForPlainText(responseMessage);
                            String truncatedMessage = plainTextMessage.length() > 200 ? plainTextMessage.substring(0, 200) + '...' : plainTextMessage;
                            
                            // Convert to Slack markdown format
                            String slackFormattedMessage = convertHtmlToSlackMarkdown(responseMessage);
                            if (slackFormattedMessage.length() > 200) {
                                slackFormattedMessage = slackFormattedMessage.substring(0, 200) + '...';
                            }
                            
                            String slackMessage = '💬 *New comment on your IT support case*\n\n' +
                                                '*From:* ' + currentUser.Name + '\n' +
                                                '*Case:* ' + caseRecord.Subject + ' (' + caseRecord.CaseNumber + ')\n' +
                                                '*Status:* ' + caseRecord.Status + '\n\n' +
                                                '*Response:*\n' + slackFormattedMessage;
                            
                            if (hasAttachments) {
                                slackMessage += '\n\n📎 *Files attached* - ';
                            }
                            
                            if (plainTextMessage.length() > 200 || hasAttachments) {
                                slackMessage += '\n\n_Full response and any attachments available in the <' + 
                                              URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center|IT Support Center>._';
                            } else {
                                slackMessage += '\n\n_View your case in the <' + 
                                              URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center|IT Support Center>._';
                            }
                            
                            System.debug('Slack message content: ' + slackMessage);
                            
                            // Send Slack DM
                            sendSlackDM(
                                caseCreator.Email,
                                '',
                                slackMessage
                            );
                            
                            slackNotificationSent = true;
                            System.debug('✅ Slack notification sent successfully');
                        } catch (Exception e) {
                            slackError = e.getMessage();
                            System.debug('❌ ERROR sending Slack notification: ' + e.getMessage());
                            System.debug('Stack trace: ' + e.getStackTraceString());
                        }
                        break; // Only process Slack once
                    }
                }
            }

            // Now do the DML operation - create FeedItem with attachments
            FeedItem post = new FeedItem(
                ParentId = caseId,
                Body = responseMessage,
                IsRichText = true,
                Type = 'TextPost'
            );
            insert post;
                            System.debug('insertion');

            System.debug('FeedItem created: ' + post.Id);
            
            // Link files to the FeedItem if any were uploaded
            if (hasAttachments) {
                List<FeedAttachment> attachments = new List<FeedAttachment>();
                for (String fileId : fileIds) {
                    FeedAttachment fa = new FeedAttachment(
                        FeedEntityId = post.Id,
                        RecordId = fileId,
                        Type = 'Content'
                    );
                    attachments.add(fa);
                }
                insert attachments;
                System.debug('insertion');
                System.debug('File attachments linked to FeedItem');
            }

            // Create a case comment as well for legacy support
            CaseComment supportComment = new CaseComment(
                ParentId = caseId,
                CommentBody = 'IT Support Response: ' + stripHtmlForPlainText(responseMessage) + 
                             (hasAttachments ? '\n[Files attached - view in IT Support Center]' : ''),
                IsPublished = true
            );
            insert supportComment;
            System.debug('insertion');
            System.debug('Case comment created: ' + supportComment.Id);

            // Second pass: Send other notifications (after DML)
            if (String.isNotBlank(caseRecord.Notification_Preferences__c)) {
                List<String> notificationTypes = caseRecord.Notification_Preferences__c.split(';');
                
                for (String notificationType : notificationTypes) {
                    System.debug('Processing notification type (after DML): ' + notificationType);
                    
                    switch on notificationType {
                        when 'Salesforce' {
                            System.debug('Sending Salesforce notification...');
                            sendNotificationToUser(
                                caseRecord.CreatedById,
                                'New Comment on Your Case',
                                'A new comment has been added to your case "' + caseRecord.Subject + '" by ' + currentUser.Name + '.',
                                caseId
                            );
                            System.debug('Salesforce notification sent');
                        }
                        when 'Email' {
                            try {
                                System.debug('Sending Email notification to: ' + caseCreator.Email);
                                String plainTextMessage = stripHtmlForPlainText(responseMessage);
                                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                mail.setToAddresses(new String[]{caseCreator.Email});
                                mail.setSubject('New Comment on Case: ' + caseRecord.CaseNumber);
                                mail.setPlainTextBody(
                                    'There is a new comment on your IT support case from ' + currentUser.Name + ':\n\n' +
                                    'Case Number: ' + caseRecord.CaseNumber + '\n' +
                                    'Subject: ' + caseRecord.Subject + '\n' +
                                    'Status: ' + caseRecord.Status + '\n\n' +
                                    'Response:\n' + plainTextMessage + '\n\n' +
                                    (hasAttachments ? 'Note: Files have been attached to this response.\n\n' : '') +
                                    'You can view and respond to your case in the IT Support Center: ' +
                                    URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center'
                                );
                                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                                System.debug('Email notification sent successfully');
                            } catch (Exception e) {
                                System.debug('Error sending email notification for IT support response: ' + e.getMessage());
                            }
                        }
                        when 'Slack' {
                            // Already processed before DML
                            if (!slackNotificationSent && slackError != null) {
                                System.debug('Slack notification was attempted but failed: ' + slackError);
                            }
                        }
                    }
                }
            } else {
                System.debug('No notification preferences set, sending default email');
                // Default to email notification if no preferences set
                try {
                    String plainTextMessage = stripHtmlForPlainText(responseMessage);
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[]{caseCreator.Email});
                    mail.setSubject('New Comment on Case: ' + caseRecord.CaseNumber);
                    mail.setPlainTextBody(
                        'There is a new comment on your IT support case from ' + currentUser.Name + ':\n\n' +
                        'Case Number: ' + caseRecord.CaseNumber + '\n' +
                        'Subject: ' + caseRecord.Subject + '\n' +
                        'Status: ' + caseRecord.Status + '\n\n' +
                        'Response:\n' + plainTextMessage + '\n\n' +
                        (hasAttachments ? 'Note: Files have been attached to this response.\n\n' : '') +
                        'You can view and respond to your case in the IT Support Center: ' +
                        URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center'
                    );
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                } catch (Exception e) {
                    System.debug('Error sending default email notification for IT support response: ' + e.getMessage());
                }
            }
            
            System.debug('=== sendSupportResponse COMPLETE ===');
            
        } catch (Exception e) {
            System.debug('=== ERROR in sendSupportResponse ===');
            System.debug('Error message: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Debug method for testing Slack integration
    @AuraEnabled
    public static String testSlackIntegration(String testEmail) {
        try {
            System.debug('=== TESTING SLACK INTEGRATION ===');
            System.debug('Test email: ' + testEmail);
            
            // Test 1: Token validation
            String token = getSlackBotToken();
            System.debug('Token retrieved: ' + (String.isNotBlank(token) ? 'SUCCESS' : 'FAILED'));
            if (String.isBlank(token)) {
                return 'ERROR: No Slack token configured';
            }
            
            // Test 2: User lookup
            String userId = findSlackUserByEmail(testEmail);
            System.debug('User lookup result: ' + (String.isNotBlank(userId) ? 'SUCCESS - ' + userId : 'FAILED'));
            if (String.isBlank(userId)) {
                return 'ERROR: Could not find Slack user for email: ' + testEmail;
            }
            
            // Test 3: Send test message
            String testMessage = '🔧 *Test message from IT Support Center*\n\nThis is a test message to verify Slack integration is working correctly.';
            sendSlackDM(testEmail, 'IT Support Center Test', testMessage);
            
            System.debug('=== SLACK INTEGRATION TEST COMPLETED SUCCESSFULLY ===');
            return 'SUCCESS: Test message sent to ' + testEmail;
            
        } catch (Exception e) {
            System.debug('=== SLACK INTEGRATION TEST FAILED ===');
            System.debug('Error: ' + e.getMessage());
            return 'ERROR: ' + e.getMessage();
        }
    }

    // Verify Slack Recipient
    @AuraEnabled
    public static SlackVerificationResult verifySlackRecipient(String email) {
        SlackVerificationResult result = new SlackVerificationResult();
        
        try {
            if (String.isBlank(email)) {
                result.success = false;
                result.errorMessage = 'Email address is required';
                return result;
            }
            
            System.debug('=== Verifying Slack Recipient ===');
            System.debug('Email: ' + email);
            
            // Use the existing findSlackUserByEmail method
            String slackUserId = findSlackUserByEmail(email);
            
            if (String.isNotBlank(slackUserId)) {
                result.success = true;
                result.slackUserId = slackUserId;
                System.debug('✅ Slack user found: ' + slackUserId);
            } else {
                result.success = false;
                result.errorMessage = 'No Slack user found for email: ' + email;
                System.debug('⚠️ No Slack user found for email: ' + email);
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error verifying Slack user: ' + e.getMessage();
            System.debug('❌ Error verifying Slack recipient: ' + e.getMessage());
        }
        
        return result;
    }
    
    // Wrapper class for Slack verification result
    public class SlackVerificationResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String slackUserId { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        
        public SlackVerificationResult() {
            this.success = false;
        }
    }

    // Chatter Feed Methods for Rich Text Support
    @AuraEnabled
    public static FeedItem createChatterPost(Id caseId, String richTextBody) {
        try {
            if (caseId == null || String.isBlank(richTextBody)) {
                throw new AuraHandledException('Case ID and message are required');
            }

            // Create a FeedItem (Chatter post) on the Case
            FeedItem post = new FeedItem(
                ParentId = caseId,
                Body = stripHtmlForPlainText(richTextBody), // Plain text version for Body field
                IsRichText = true
            );
            
            // Set the rich text content
            post.Body = richTextBody;
            
         //   insert post;
            System.debug('insertion');
            // Send notifications if post is from someone other than the case creator
            Case caseRecord = [SELECT Id, Subject, CreatedById, Notification_Preferences__c, CaseNumber FROM Case WHERE Id = :caseId];
            
            if (UserInfo.getUserId() != caseRecord.CreatedById) {
                handleCommentNotifications(caseRecord, richTextBody);
            }
			insert post; //Added By Kajal to remove error
            // Return the created post with full details
            return [
                SELECT Id, ParentId, Body, CreatedDate, CreatedById, CreatedBy.Name, 
                       IsRichText, Type, Visibility
                FROM FeedItem
                WHERE Id = :post.Id
                LIMIT 1
            ];
            
        } catch (Exception e) {
            System.debug('Error creating Chatter post: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static List<ChatterFeedWrapper> getChatterFeed(Id caseId) {
        try {
            if (caseId == null) {
                throw new AuraHandledException('Case ID is required');
            }
            
            List<ChatterFeedWrapper> feedItems = new List<ChatterFeedWrapper>();
            
            // Get FeedItems for the case
            List<FeedItem> posts = [
                SELECT Id, ParentId, Body, CreatedDate, CreatedById, CreatedBy.Name, 
                       IsRichText, Type, Visibility
                FROM FeedItem
                WHERE ParentId = :caseId
                AND Type = 'TextPost'
                ORDER BY CreatedDate DESC
            ];
            
            for (FeedItem post : posts) {
                ChatterFeedWrapper wrapper = new ChatterFeedWrapper();
                wrapper.id = post.Id;
                wrapper.body = post.Body;
                wrapper.createdDate = post.CreatedDate;
                wrapper.createdById = post.CreatedById;
                wrapper.createdByName = post.CreatedBy.Name;
                // Generate the standard Salesforce user photo URL
                wrapper.createdByPhotoUrl = URL.getOrgDomainUrl().toExternalForm() + '/profilephoto/005/T/' + post.CreatedById;
                wrapper.isRichText = post.IsRichText;
                
                feedItems.add(wrapper);
            }
            
            return feedItems;
            
        } catch (Exception e) {
            System.debug('Error getting Chatter feed: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Helper method to strip HTML tags for plain text version
    private static String stripHtmlForPlainText(String htmlText) {
        if (String.isBlank(htmlText)) {
            return '';
        }
        
        // Remove HTML tags
        String plainText = htmlText.replaceAll('<[^>]*>', '');
        
        // Replace common HTML entities
        plainText = plainText.replaceAll('&nbsp;', ' ');
        plainText = plainText.replaceAll('&amp;', '&');
        plainText = plainText.replaceAll('&lt;', '<');
        plainText = plainText.replaceAll('&gt;', '>');
        plainText = plainText.replaceAll('&quot;', '"');
        plainText = plainText.replaceAll('&#39;', '\'');
        
        // Remove excessive whitespace
        plainText = plainText.replaceAll('\\s+', ' ').trim();
        
        return plainText;
    }
    
    // Helper method to convert HTML to Slack markdown
    private static String convertHtmlToSlackMarkdown(String htmlText) {
        if (String.isBlank(htmlText)) {
            return '';
        }
        
        String markdown = htmlText;
        
        // Convert bold
        markdown = markdown.replaceAll('<b>', '*');
        markdown = markdown.replaceAll('</b>', '*');
        markdown = markdown.replaceAll('<strong>', '*');
        markdown = markdown.replaceAll('</strong>', '*');
        
        // Convert italic
        markdown = markdown.replaceAll('<i>', '_');
        markdown = markdown.replaceAll('</i>', '_');
        markdown = markdown.replaceAll('<em>', '_');
        markdown = markdown.replaceAll('</em>', '_');
        
        // Convert line breaks
        markdown = markdown.replaceAll('<br\\s*/?>', '\n');
        markdown = markdown.replaceAll('</p>', '\n\n');
        markdown = markdown.replaceAll('<p>', '');
        
        // Convert lists
        markdown = markdown.replaceAll('<li>', '• ');
        markdown = markdown.replaceAll('</li>', '\n');
        markdown = markdown.replaceAll('<ul>', '');
        markdown = markdown.replaceAll('</ul>', '\n');
        markdown = markdown.replaceAll('<ol>', '');
        markdown = markdown.replaceAll('</ol>', '\n');
        
        // Remove any remaining HTML tags
        markdown = markdown.replaceAll('<[^>]*>', '');
        
        // Replace HTML entities
        markdown = markdown.replaceAll('&nbsp;', ' ');
        markdown = markdown.replaceAll('&amp;', '&');
        markdown = markdown.replaceAll('&lt;', '<');
        markdown = markdown.replaceAll('&gt;', '>');
        markdown = markdown.replaceAll('&quot;', '"');
        markdown = markdown.replaceAll('&#39;', '\'');
        
        // Clean up excessive newlines and spaces
        markdown = markdown.replaceAll('\n{3,}', '\n\n');
        markdown = markdown.replaceAll(' +', ' ');
        
        return markdown.trim();
    }
    
    // Wrapper class for Chatter feed items
    public class ChatterFeedWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String body { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public String createdById { get; set; }
        @AuraEnabled public String createdByName { get; set; }
        @AuraEnabled public String createdByPhotoUrl { get; set; }
        @AuraEnabled public Boolean isRichText { get; set; }
    }
    
    // Helper class for handling rich text case creation
    @AuraEnabled
    public static String processRichTextForCaseDescription(String richTextContent) {
        try {
            // For case descriptions, we need to convert to plain text
            // since the Description field on Case object is plain text
            return stripHtmlForPlainText(richTextContent);
        } catch (Exception e) {
            System.debug('Error processing rich text: ' + e.getMessage());
            return richTextContent; // Return original if processing fails
        }
    }

    // Enhanced Chatter Feed with File Support
    @AuraEnabled
    public static FeedItem createChatterPostWithFiles(Id caseId, String richTextBody, List<String> fileIds) {
        try {
            if (caseId == null || String.isBlank(richTextBody)) {
                throw new AuraHandledException('Case ID and message are required');
            }
// Handle notifications (same as before)
            Case caseRecord = [SELECT Id, Subject, CreatedById, Notification_Preferences__c, CaseNumber FROM Case WHERE Id = :caseId];
            
            if (UserInfo.getUserId() != caseRecord.CreatedById) {
                handleCommentNotifications(caseRecord, richTextBody);
            }
            // Create the FeedItem
            FeedItem post = new FeedItem(
                ParentId = caseId,
                Body = richTextBody,
                IsRichText = true,
                Type = 'TextPost'
            );
            
            insert post;
                            System.debug('insertion');

            // Link files to the FeedItem if any were uploaded
            if (fileIds != null && !fileIds.isEmpty()) {
                List<FeedAttachment> attachments = new List<FeedAttachment>();
                for (String fileId : fileIds) {
                    FeedAttachment fa = new FeedAttachment(
                        FeedEntityId = post.Id,
                        RecordId = fileId,
                        Type = 'Content'
                    );
                    attachments.add(fa);
                }
                insert attachments;
                                System.debug('insertion');

            }
            
            // Handle notifications (same as before)
         /*   Case caseRecord = [SELECT Id, Subject, CreatedById, Notification_Preferences__c, CaseNumber FROM Case WHERE Id = :caseId];
            
            if (UserInfo.getUserId() != caseRecord.CreatedById) {
                handleCommentNotifications(caseRecord, richTextBody);
            }
*/ //Shifted before DML due to salesforce exception By Kajal
            // Return the created post with full details
            return [
                SELECT Id, ParentId, Body, CreatedDate, CreatedById, CreatedBy.Name, 
                       IsRichText, Type, Visibility
                FROM FeedItem
                WHERE Id = :post.Id
                LIMIT 1
            ];
            
        } catch (Exception e) {
            System.debug('Error creating Chatter post with files: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Get enhanced feed with file attachments
    @AuraEnabled(cacheable=false)
    public static List<EnhancedFeedWrapper> getEnhancedChatterFeed(Id caseId) {
        try {
            if (caseId == null) {
                throw new AuraHandledException('Case ID is required');
            }
            
            List<EnhancedFeedWrapper> feedItems = new List<EnhancedFeedWrapper>();
            
            // Get FeedItems with their attachments
            List<FeedItem> posts = [
                SELECT Id, ParentId, Body, CreatedDate, CreatedById, CreatedBy.Name, 
                       IsRichText, Type, Visibility,
                       (SELECT Id, RecordId, Type FROM FeedAttachments WHERE Type = 'Content')
                FROM FeedItem
                WHERE ParentId = :caseId
                AND Type = 'TextPost'
                ORDER BY CreatedDate DESC
            ];
            System.debug('posts-->'+posts);
            // Get all ContentDocumentIds from the attachments
            Set<Id> contentDocumentIds = new Set<Id>();
            Map<Id, List<Id>> feedToContentMap = new Map<Id, List<Id>>();
            
            for (FeedItem post : posts) {
                List<Id> postContentIds = new List<Id>();
                for (FeedAttachment fa : post.FeedAttachments) {
                    if (fa.Type == 'Content' && fa.RecordId != null) {
                        contentDocumentIds.add(fa.RecordId);
                        postContentIds.add(fa.RecordId);
                    }
                }
                if (!postContentIds.isEmpty()) {
                    feedToContentMap.put(post.Id, postContentIds);
                }
            }
            
            // Get ContentDocument details
            Map<Id, ContentDocument> contentDocMap = new Map<Id, ContentDocument>();
            if (!contentDocumentIds.isEmpty()) {
                for (ContentDocument cd : [
                    SELECT Id, Title, FileType, FileExtension, ContentSize, LatestPublishedVersionId
                    FROM ContentDocument
                    WHERE Id IN :contentDocumentIds
                ]) {
                    contentDocMap.put(cd.Id, cd);
                }
            }
            
            // Build the enhanced feed wrappers
            for (FeedItem post : posts) {
                EnhancedFeedWrapper wrapper = new EnhancedFeedWrapper();
                wrapper.id = post.Id;
                wrapper.body = post.Body;
                wrapper.createdDate = post.CreatedDate;
                wrapper.createdById = post.CreatedById;
                wrapper.createdByName = post.CreatedBy.Name;
                wrapper.createdByPhotoUrl = URL.getOrgDomainUrl().toExternalForm() + '/profilephoto/005/T/' + post.CreatedById;
                wrapper.isRichText = post.IsRichText;
                wrapper.files = new List<FileWrapper>();
                
                // Add file information
                if (feedToContentMap.containsKey(post.Id)) {
                    for (Id contentId : feedToContentMap.get(post.Id)) {
                        if (contentDocMap.containsKey(contentId)) {
                            ContentDocument cd = contentDocMap.get(contentId);
                            FileWrapper fw = new FileWrapper();
                            fw.id = cd.Id;
                            fw.name = cd.Title;
                            fw.fileType = cd.FileType;
                            fw.fileExtension = cd.FileExtension;
                            fw.size = formatFileSize(cd.ContentSize);
                            fw.versionId = cd.LatestPublishedVersionId;
                            fw.downloadUrl = '/sfc/servlet.shepherd/document/download/' + cd.Id;
                            fw.isImage = isImageFile(cd.FileExtension);
                            
                            wrapper.files.add(fw);
                        }
                    }
                }
                
                feedItems.add(wrapper);
            }
            
            return feedItems;
            
        } catch (Exception e) {
            System.debug('Error getting enhanced Chatter feed: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Helper method to check if file is an imageest
  //  @TestVisible
    private static Boolean isImageFile(String fileExtension) {
        if (String.isBlank(fileExtension)) return false;
        Set<String> imageExtensions = new Set<String>{'jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp'};
        return imageExtensions.contains(fileExtension.toLowerCase());
    }
    
    // Helper method to format file size
  //  @TestVisible
    private static String formatFileSize(Integer bytes) {
        if (bytes == null || bytes == 0) return '0 Bytes';
        
        List<String> sizes = new List<String>{'Bytes', 'KB', 'MB', 'GB'};
        Integer i = (Integer)Math.floor(Math.log(bytes) / Math.log(1024));
        Decimal size = bytes / Math.pow(1024, i);
        
        return size.setScale(2, RoundingMode.HALF_UP) + ' ' + sizes[i];
    }
    
    // Extract notification handling to reusable method
 //   @TestVisible
    private static void handleCommentNotifications(Case caseRecord, String richTextBody) {
        User caseCreator = [SELECT Id, Name, Email FROM User WHERE Id = :caseRecord.CreatedById];
        User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
        
        if (String.isNotBlank(caseRecord.Notification_Preferences__c)) {
            List<String> notificationTypes = caseRecord.Notification_Preferences__c.split(';');
            
            // First pass: Send Slack notifications (before any additional DML)
            for (String notificationType : notificationTypes) {
                if (notificationType == 'Slack') {
                    try {
                        String plainTextMessage = stripHtmlForPlainText(richTextBody);
                        String truncatedMessage = plainTextMessage.length() > 200 ? plainTextMessage.substring(0, 200) + '...' : plainTextMessage;
                        
                        String slackFormattedMessage = convertHtmlToSlackMarkdown(richTextBody);
                        if (slackFormattedMessage.length() > 200) {
                            slackFormattedMessage = slackFormattedMessage.substring(0, 200) + '...';
                        }
                        
                        String slackMessage = '💬 *New comment on your IT support case*\n\n' +
                                            '*From:* ' + currentUser.Name + '\n' +
                                            '*Case:* ' + caseRecord.Subject + ' (' + caseRecord.CaseNumber + ')\n\n' +
                                            '*Comment:*\n' + slackFormattedMessage;
                        
                        if (plainTextMessage.length() > 200) {
                            slackMessage += '\n\n_Full comment and any attachments available in the <' + 
                                          URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center|IT Support Center>._';
                        } else {
                            slackMessage += '\n\n_View your case in the <' + 
                                          URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center|IT Support Center>._';
                        }
                        
                        sendSlackDM(caseCreator.Email, 'New Comment on Case: ' + caseRecord.CaseNumber, slackMessage);
                    } catch (Exception e) {
                        System.debug('Error sending Slack notification: ' + e.getMessage());
                    }
                    break;
                }
            }
            
            // Second pass: Other notifications
            for (String notificationType : notificationTypes) {
                switch on notificationType {
                    when 'Salesforce' {
                        sendNotificationToUser(
                            caseRecord.CreatedById,
                            'New Comment on Your Case',
                            'A new comment has been added to case: ' + caseRecord.Subject,
                            caseRecord.Id
                        );
                    }
                    when 'Email' {
                        try {
                            String plainTextMessage = stripHtmlForPlainText(richTextBody);
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            mail.setToAddresses(new String[]{caseCreator.Email});
                            mail.setSubject('New Comment on Case: ' + caseRecord.Subject);
                            mail.setPlainTextBody('A new comment has been added to your IT support case:\n\n' +
                                                'Case: ' + caseRecord.Subject + '\n' +
                                                'From: ' + currentUser.Name + '\n' +
                                                'Comment: ' + plainTextMessage + '\n\n' +
                                                'Note: Any file attachments can be viewed in the IT Support Center.\n\n' +
                                                'Please check the IT Support Center for details: ' +
                                                URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/IT_Support_Center');
                            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                        } catch (Exception e) {
                            System.debug('Error sending email notification: ' + e.getMessage());
                        }
                    }
                }
            }
        }
    }
    
    // Wrapper classes for enhanced feed
    public class EnhancedFeedWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String body { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public String createdById { get; set; }
        @AuraEnabled public String createdByName { get; set; }
        @AuraEnabled public String createdByPhotoUrl { get; set; }
        @AuraEnabled public Boolean isRichText { get; set; }
        @AuraEnabled public List<FileWrapper> files { get; set; }
    }
    
    public class FileWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String fileType { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public String size { get; set; }
        @AuraEnabled public String versionId { get; set; }
        @AuraEnabled public String downloadUrl { get; set; }
        @AuraEnabled public Boolean isImage { get; set; }
    }

    /**
     * Creates a case with initial ChatMessage using UnifiedChat integration
     * @param caseData Map containing case field values
     * @param initialMessage Initial message content for the case
     * @param attachmentFiles List of file attachments for the initial message
     * @return Map containing the created case ID and initial chat message result
     */
    @AuraEnabled
    public static Map<String, Object> createCaseWithChatMessage(Map<String, Object> caseData, String initialMessage, List<Map<String, Object>> attachmentFiles) {
        try {
            // Validate inputs
            if (caseData == null || caseData.isEmpty()) {
                throw new AuraHandledException('Case data is required');
            }
            if (String.isBlank(initialMessage)) {
                throw new AuraHandledException('Initial message is required');
            }

            // Create the Case record
            Case newCase = new Case();
            
            // Set case fields from the provided data
            if (caseData.containsKey('Subject')) {
                newCase.Subject = (String) caseData.get('Subject');
            }
            if (caseData.containsKey('Description')) {
                // For Description field, convert rich text to plain text
                String description = (String) caseData.get('Description');
                newCase.Description = processRichTextForCaseDescription(description);
            }
            if (caseData.containsKey('Category__c')) {
                newCase.Category__c = (String) caseData.get('Category__c');
            }
            if (caseData.containsKey('Severity__c')) {
                newCase.Severity__c = (String) caseData.get('Severity__c');
            }
            if (caseData.containsKey('Notification_Preferences__c')) {
                newCase.Notification_Preferences__c = (String) caseData.get('Notification_Preferences__c');
            }
            if (caseData.containsKey('RecordTypeId')) {
                newCase.RecordTypeId = (String) caseData.get('RecordTypeId');
            }
            
            // Set default values
            newCase.Origin = 'IT Support Center';
            newCase.Status = 'New';
            
            insert newCase;
                            System.debug('insertion');

            
            // Send case creation notification via UnifiedChat service (handles Slack or Email internally)
            try {
                System.debug('Calling ChatService.sendCaseCreationNotification for case: ' + newCase.Id + ' with prefs: ' + newCase.Notification_Preferences__c);
                ChatService.sendCaseCreationNotification(newCase.Id);
            } catch (Exception notifEx) {
                System.debug('Error sending case-creation notification: ' + notifEx.getMessage());
            }
            
            // Create initial ChatMessage for case creation
            ChatService.ChatMessageResult messageResult = ChatService.createMessage(
                initialMessage,
                String.valueOf(newCase.Id),
                attachmentFiles
            );
            
            // Notification is already handled by ChatService.sendCaseCreationNotification above
            // No need for duplicate notifications
            
            // Return both case and message information
            Map<String, Object> result = new Map<String, Object>();
            result.put('caseId', newCase.Id);
            result.put('caseNumber', newCase.CaseNumber);
            result.put('messageResult', messageResult);
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error'+e.getMessage()+e.getLineNumber());
            throw new AuraHandledException('Error creating case with chat message: ' + e.getMessage());
        }
    }
    
    /**
     * Adds a comment to a case using UnifiedChat integration
     * This replaces the traditional createCaseComment for unified workflow
     * @param caseId ID of the case
     * @param commentBody Rich text content of the comment
     * @param attachmentFiles List of file attachments
     * @return ChatMessageResult containing the created message
     */
    @AuraEnabled
    public static ChatService.ChatMessageResult addCaseCommentViaChatMessage(Id caseId, String commentBody, List<Map<String, Object>> attachmentFiles) {
        try {
            if (caseId == null) {
                throw new AuraHandledException('Case ID is required');
            }
            if (String.isBlank(commentBody)) {
                throw new AuraHandledException('Comment body is required');
            }
            
            // Create ChatMessage via UnifiedChat integration
            return ChatService.createMessage(
                commentBody,
                String.valueOf(caseId),
                attachmentFiles
            );
            
        } catch (Exception e) {
            throw new AuraHandledException('Error adding case comment via chat message: ' + e.getMessage());
        }
    }
    
    /**
     * Enhanced method to send support response using UnifiedChat integration
     * This replaces the traditional sendSupportResponse for unified workflow
     * @param caseId ID of the case
     * @param responseMessage Rich text response content
     * @param attachmentFiles List of file attachments
     * @return ChatMessageResult containing the created message
     */
    @AuraEnabled
    public static ChatService.ChatMessageResult sendSupportResponseViaChatMessage(Id caseId, String responseMessage, List<Map<String, Object>> attachmentFiles) {
        try {
            if (caseId == null) {
                throw new AuraHandledException('Case ID is required');
            }
            if (String.isBlank(responseMessage)) {
                throw new AuraHandledException('Response message is required');
            }
            
            // Create ChatMessage for IT Support response
            return ChatService.createMessage(
                responseMessage,
                String.valueOf(caseId),
                attachmentFiles
            );
            
        } catch (Exception e) {
            throw new AuraHandledException('Error sending support response via chat message: ' + e.getMessage());
        }
    }
    
    /**
     * Gets chat messages for a case (integrates with existing conversation history)
     * @param caseId ID of the case
     * @return List of ChatMessageResult objects
     */
    @AuraEnabled(cacheable=true)
    public static List<ChatService.ChatMessageResult> getCaseChatMessages(Id caseId) {
        try {
            if (caseId == null) {
                throw new AuraHandledException('Case ID is required');
            }
            
            // Use ChatService to get conversation history - convert Id to String
            return ChatService.getConversationHistory(String.valueOf(caseId));
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting case chat messages: ' + e.getMessage());
        }
    }
    
    /**
     * Helper method to determine if a case should use UnifiedChat integration
     * @return Boolean indicating if UnifiedChat should be used
     */
    @AuraEnabled(cacheable=true)
    public static Boolean shouldUseChatIntegration() {
        // For now, return true to enable chat integration
        // In the future, this could be configurable via Custom Metadata or Org settings
        return true;
    }
    
    /**
     * Migrates existing case comments to ChatMessage records (one-time migration utility)
     * @param caseId ID of the case to migrate
     * @return Number of comments migrated
     */
    @AuraEnabled
    public static Integer migrateCaseCommentsToChat(Id caseId) {
        try {
            if (caseId == null) {
                throw new AuraHandledException('Case ID is required');
            }
            
            // Get existing case comments that haven't been migrated
            List<CaseComment> comments = [
                SELECT Id, CommentBody, CreatedDate, CreatedById, CreatedBy.Name
                FROM CaseComment 
                WHERE ParentId = :caseId 
                AND IsPublished = true
                ORDER BY CreatedDate ASC
            ];
            
            Integer migratedCount = 0;
            
            for (CaseComment comment : comments) {
                try {
                    // Check if a ChatMessage already exists for this comment
                    List<ChatMessage__c> existingMessages = [
                        SELECT Id 
                        FROM ChatMessage__c 
                        WHERE Parent_Record__c = :caseId 
                        AND CreatedDate = :comment.CreatedDate
                        AND CreatedById = :comment.CreatedById
                        LIMIT 1
                    ];
                    
                    if (existingMessages.isEmpty()) {
                        // Create ChatMessage for this comment
                        ChatMessage__c message = new ChatMessage__c(
                            Body__c = comment.CommentBody,
                            Parent_Record__c = caseId,
                            Has_Attachments__c = false,
                            Attachment_Count__c = 0
                            // Note: Message_Type__c field would need to be created if needed
                        );
                        
                        // Preserve original created date and user (if possible)
                        // Note: This might require special permissions or custom field setup
                        insert message;
                                        System.debug('insertion');

                        migratedCount++;
                    }
                    
                } catch (Exception e) {
                    System.debug('Error migrating comment ' + comment.Id + ': ' + e.getMessage());
                }
            }
            
            return migratedCount;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error migrating case comments: ' + e.getMessage());
        }
    }
}