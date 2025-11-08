global class KnowledgeArticleSearchAction {

    global class KnowledgeArticleSearchRequest {
        @InvocableVariable(required=true)
        global String searchQuery;
    }
    
    global class KnowledgeArticleResult {
        @InvocableVariable
        global Id articleId;
        @InvocableVariable
        global String title;
        @InvocableVariable
        global String summary;
        @InvocableVariable
        global String answer;
    }
    
    @InvocableMethod(label='Search Knowledge Articles' description='Returns a list of knowledge articles based on search criteria')
    global static List<KnowledgeArticleResult> searchArticles(List<KnowledgeArticleSearchRequest> requestList) {
        String queryTerm = '';
        if (requestList != null && !requestList.isEmpty()) {
            queryTerm = requestList[0].searchQuery;
        }
        if (String.isBlank(queryTerm)) {
            return new List<KnowledgeArticleResult>();
        }
        
        List<KnowledgeArticleResult> results = new List<KnowledgeArticleResult>();
        Set<Id> articleIds = new Set<Id>();
        
        List<List<SObject>> searchResults = [
            FIND :queryTerm IN ALL FIELDS 
            RETURNING Knowledge__kav(Id, Title, Summary, Answer__c LIMIT 50)
        ];
        if (!searchResults.isEmpty() && !searchResults[0].isEmpty()) {
            for (SObject obj : searchResults[0]) {
                Knowledge__kav article = (Knowledge__kav)obj;
                articleIds.add(article.Id);
                KnowledgeArticleResult kar = new KnowledgeArticleResult();
                kar.articleId = article.Id;
                kar.title = article.Title;
                kar.summary = article.Summary;
                kar.answer = article.Answer__c;
                results.add(kar);
            }
        }
        
        List<TopicAssignment> topicAssignments = [
            SELECT EntityId 
            FROM TopicAssignment 
            WHERE Topic.Name LIKE :('%' + queryTerm + '%')
        ];
        Set<Id> topicArticleIds = new Set<Id>();
        for (TopicAssignment ta : topicAssignments) {
            topicArticleIds.add(ta.EntityId);
        }
        topicArticleIds.removeAll(articleIds);
        
        if (!topicArticleIds.isEmpty()) {
            List<Knowledge__kav> topicArticles = [
                SELECT Id, Title, Summary, Answer__c 
                FROM Knowledge__kav 
                WHERE Id IN :topicArticleIds
            ];
            for (Knowledge__kav article : topicArticles) {
                KnowledgeArticleResult kar = new KnowledgeArticleResult();
                kar.articleId = article.Id;
                kar.title = article.Title;
                kar.summary = article.Summary;
                kar.answer = article.Answer__c;
                results.add(kar);
            }
        }
        
        return results;
    }
}