@isTest
private class KnowledgeArticleSearchAction_AllTests {

    // Test for an empty search query returns no results.
    static testMethod void testEmptyQuery() {
        KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest req = 
            new KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest();
        req.searchQuery = '';
        List<KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest> reqList = 
            new List<KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest>{ req };
        
        Test.startTest();
        List<KnowledgeArticleSearchAction.KnowledgeArticleResult> results = 
            KnowledgeArticleSearchAction.searchArticles(reqList);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Expected no results for an empty search query.');
    }
    
    // Test for an empty input list returns no results.
    static testMethod void testEmptyRequestList() {
        Test.startTest();
        List<KnowledgeArticleSearchAction.KnowledgeArticleResult> results = 
            KnowledgeArticleSearchAction.searchArticles(new List<KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest>());
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Expected no results for an empty request list.');
    }
    
    // Test the SOSL branch. This simulates a SOSL search that returns a record.
    static testMethod void testSOSLBranch() {
        // Insert a test Knowledge article record with the required UrlName.
        Knowledge__kav art1 = new Knowledge__kav(
            Title = 'Test Article',
            Summary = 'Summary for art1',
            Answer__c = 'Answer for art1',
            UrlName = 'test-article'
        );
        insert art1;
        
        // Force the SOSL query to return art1.
        Test.setFixedSearchResults(new List<Id>{ art1.Id });
        
        KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest req = 
            new KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest();
        req.searchQuery = 'Test Article';
        List<KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest> reqList = 
            new List<KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest>{ req };
        
        Test.startTest();
        List<KnowledgeArticleSearchAction.KnowledgeArticleResult> results = 
            KnowledgeArticleSearchAction.searchArticles(reqList);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result from the SOSL branch.');
        System.assertEquals(art1.Id, results[0].articleId, 'Expected the fixed SOSL result to return art1.');
    }
    
    // Test the Topic branch using seeAllData.
    // We remove the testMethod keyword and rely on @isTest(seeAllData=true) for method-level config.
    @isTest(seeAllData=true)
    static void testTopicBranch() {
        // Insert a test Knowledge article record with the required UrlName.
        Knowledge__kav art2 = new Knowledge__kav(
            Title = 'Topic Test Article',
            Summary = 'Summary for topic',
            Answer__c = 'Answer for topic',
            UrlName = 'topic-test-article'
        );
        insert art2;
        
        // Force the SOSL branch to return no results.
        Test.setFixedSearchResults(new List<Id>());
        
        // Query an existing Topic record (requires seeAllData).
        List<Topic> topics = [SELECT Id, Name FROM Topic LIMIT 1];
        System.assert(!topics.isEmpty(), 'There should be at least one Topic in the org.');
        String topicName = topics[0].Name;
        
        // Create a TopicAssignment linking the test article to the Topic.
        TopicAssignment ta = new TopicAssignment();
        ta.EntityId = art2.Id;
        ta.TopicId = topics[0].Id;
        insert ta;
        
        // Use the topic's name as the search query.
        KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest req = 
            new KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest();
        req.searchQuery = topicName;
        List<KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest> reqList = 
            new List<KnowledgeArticleSearchAction.KnowledgeArticleSearchRequest>{ req };
        
        Test.startTest();
        List<KnowledgeArticleSearchAction.KnowledgeArticleResult> results = 
            KnowledgeArticleSearchAction.searchArticles(reqList);
        Test.stopTest();
        
        // Verify that art2 was returned by the Topic branch.
        Set<Id> returnedIds = new Set<Id>();
        for (KnowledgeArticleSearchAction.KnowledgeArticleResult res : results) {
            returnedIds.add(res.articleId);
        }
        System.assert(returnedIds.contains(art2.Id), 'Expected art2 to be returned by the Topic branch.');
        System.assert(results.size() > 0, 'Expected at least one result from the Topic branch.');
    }
}