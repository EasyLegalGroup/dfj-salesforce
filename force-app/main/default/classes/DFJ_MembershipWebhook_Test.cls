/*
   * @ Created Date : 2021-09-30
   * @Description : This class is to test 
*/
@IsTest
public with sharing class DFJ_MembershipWebhook_Test {
    @isTest static void UnauthorizedAccessForGet_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());

        List<Relative__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccoutntAndRelatives(1,1,1);
        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Membership__c+'/relatives/'+relative[0].Id;
        request.httpMethod = 'GET';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        System.assertEquals('"Unauthorized Access."', response.responseBody.toString());
    }

    @isTest static void GetMembershipData_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());

        List<Membership__c> members = DFJ_TestDataFactory.CreateMembershipsWithAccounts(1,1);
        request.requestURI = '/services/apexrest/v1/membership/'+ members[0].Id;
        request.httpMethod = 'GET';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        System.assert(response.responseBody.toString().contains('DK'));
    }

    @isTest static void ListEmptyForGetMembershipData_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/v1/membership/abcd';
        request.httpMethod = 'GET';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        System.assertEquals(404,response.statusCode);
    }

    @isTest static void GetRelativeData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());

        List<Relative__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccoutntAndRelatives(1,1,1);
        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Membership__c+'/relatives/'+relative[0].Id;
        request.httpMethod = 'GET';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        System.assert(response.responseBody.toString().contains('Dummy Relative'));
    }

    @isTest static void ListEmptyForGetRelativeData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());

        List<Membership__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccounts(1,1);
        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Id+'/relatives/abcd';
        request.httpMethod = 'GET';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        System.assertEquals(404, response.statusCode);
    }

    @isTest static void GetRelativesData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());

        List<Relative__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccoutntAndRelatives(1,1,2);
        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Membership__c+'/relatives';
        request.httpMethod = 'GET';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        List <Relative__c> relativeList = (List<Relative__c>) JSON.deserialize(response.responseBody.toString(),List<Relative__c>.class);
        System.assertEquals(relativeList.size(), relative.size());
        
    }

    @isTest static void ListEmptyForGetRelativesData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());

        List<Membership__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccounts(1,1);
        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Id+'/relatives';
        request.httpMethod = 'GET';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        System.assertEquals(404, response.statusCode);
    }

    @isTest static void UnauthorizedAccessForDelete_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());

        List<Relative__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccoutntAndRelatives(1,1,1);
        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Membership__c+'/relatives/'+relative[0].Id;
        request.httpMethod = 'Delete';
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.DeleteMembershipRelatedData();
        System.assertEquals('"Unauthorized Access."', response.responseBody.toString());
    }

    @isTest static void DeleteRelativeData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());
        List<Relative__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccoutntAndRelatives(1,1,1);
        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Membership__c+'/relatives/'+relative[0].Id;
        request.httpMethod = 'DELETE';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.DeleteMembershipRelatedData();
        List<Relative__c> deletedMembership = [SELECT Id,Name FROM Relative__c WHERE Id=:relative[0].Id LIMIT 1];
        System.assertEquals(0, deletedMembership.size());
    }

    @isTest static void DeleteMembershipData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());
        List<Membership__c> members = DFJ_TestDataFactory.CreateMembershipsWithAccounts(1,1);
        request.requestURI = '/services/apexrest/v1/membership/'+ members[0].Id;
        request.httpMethod = 'DELETE';
        request.remoteAddress = '101.53.164.8';
        Request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.DeleteMembershipRelatedData();
        List<Membership__c> deletedMembership = [SELECT Id,Name FROM Membership__c WHERE Id=:members[0].Id LIMIT 1];
        System.assertEquals(0, deletedMembership.size());
    }
// today
    @isTest static void UnauthorizedAccessForPost_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());

        List<Relative__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccoutntAndRelatives(1,1,1);
        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Membership__c+'/relatives/'+relative[0].Id;
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.CreateMembershipRelatedData();
        System.assertEquals('"Unauthorized Access."', response.responseBody.toString());
    }

    @isTest static void CreateRelativeData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());
        List<Membership__c> members = DFJ_TestDataFactory.CreateMembershipsWithAccounts(1,1);

        request.requestURI = '/services/apexrest/v1/membership/'+ members[0].Id+'/relatives';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"name":"Test","email":"test@test.com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.CreateMembershipRelatedData();
        List<DFJ_Utility.RelativeWrapper> relative = (List<DFJ_Utility.RelativeWrapper>) JSON.deserialize(response.responseBody.toString(), List<DFJ_Utility.RelativeWrapper>.class);
        List<Relative__c> relativeRec = [SELECT Id,Name FROM Relative__c WHERE Id=:relative[0].relativeObjectId LIMIT 1];
        System.assertEquals('Test', relativeRec[0].Name);
    }

    @isTest static void NotFoundCreateRelativeData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 

        request.requestURI = '/services/apexrest/v1/membership/abcd/relatives';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"name":"Test","email":"test@test.com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.CreateMembershipRelatedData();
        System.assertEquals(404, response.statusCode);
    }

    @isTest static void BadRequestForCreateRelativeData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 

        request.requestURI = '/services/apexrest/v1/membership/ /relatives';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"name":"Test","email":"test@test.com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.CreateMembershipRelatedData();
        // Verify results
        System.assertEquals(400, response.statusCode);
    }

    @isTest static void CreateRelativesData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());
        List<Membership__c> members = DFJ_TestDataFactory.CreateMembershipsWithAccounts(1,1);

        request.requestURI = '/services/apexrest/v1/membership/'+ members[0].Id+'/relatives';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('[{"name":"Test","email":"test@test.com"}]');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.CreateMembershipRelatedData();
        List<DFJ_Utility.RelativeWrapper> relative = (List<DFJ_Utility.RelativeWrapper>) JSON.deserialize(response.responseBody.toString(), List<DFJ_Utility.RelativeWrapper>.class);
        List<Relative__c> relativeRec = [SELECT Id,Name FROM Relative__c WHERE Id=:relative[0].relativeObjectId LIMIT 1];
        System.assertEquals('Test', relativeRec[0].Name);
    }

    @isTest static void BadRequestCreateRelativesData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());
        List<Membership__c> members = DFJ_TestDataFactory.CreateMembershipsWithAccounts(1,1);

        request.requestURI = '/services/apexrest/v1/membership/'+ members[0].Id+'/relatives';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('[]');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.CreateMembershipRelatedData();
        System.assertEquals('Bad request.', response.responseBody.toString());
    }

    @isTest static void BadRequestCreateEmptyRelativesData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());
        List<Membership__c> members = DFJ_TestDataFactory.CreateMembershipsWithAccounts(1,1);

        request.requestURI = '/services/apexrest/v1/membership/'+ members[0].Id+'/relatives';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('["{}"]');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.CreateMembershipRelatedData();
        System.assertEquals('Server error.', response.responseBody.toString());
    }

    @isTest static void UnauthorizedAccessForPut_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());

        List<Relative__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccoutntAndRelatives(1,1,1);
        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Membership__c+'/relatives/'+relative[0].Id;
        request.httpMethod = 'PUT';
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.UpdateMembershipRelatedData();
        System.assertEquals('"Unauthorized Access."', response.responseBody.toString());
    }

    @isTest static void UpdateMembershipData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());
        List<Membership__c> members = DFJ_TestDataFactory.CreateMembershipsWithAccounts(1,1);

        request.requestURI = '/services/apexrest/v1/membership/'+ members[0].Id;
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('{"name":"Test","email":"test@test.com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.UpdateMembershipRelatedData();
        List<Membership__c> membershipRec = [SELECT Id,Name FROM Membership__c WHERE Id=:members[0].Id LIMIT 1];
        System.assertEquals('Dummy Account Membership 0', membershipRec[0].Name);
    }

    @isTest static void BadRequestForUpdateMembershipData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 

        request.requestURI = '/services/apexrest/v1/membership/ /';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('{"name":"Test","email":"test@test.com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.UpdateMembershipRelatedData();
        System.assertEquals(400, response.statusCode);
    }

    @isTest static void NotFoundForUpdateMembershipData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 

        request.requestURI = '/services/apexrest/v1/membership/abcd';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('{"name":"Test","email":"test@test.com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.UpdateMembershipRelatedData();
        System.assertEquals(404, response.statusCode);
    }

    @isTest static void UpdateRelativeData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());
        List<Relative__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccoutntAndRelatives(1,1,1);

        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Membership__c+'/relatives/'+relative[0].Id;
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('{"name":"Test","email":"test@test.com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.UpdateMembershipRelatedData();
        List<Relative__c> membershipRec = [SELECT Id,Name FROM Relative__c WHERE Id=:relative[0].Id LIMIT 1];
        System.assertEquals('Test', membershipRec[0].Name);
    }

    @isTest static void badRequestForUpdateRelativeData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 

        request.requestURI = '/services/apexrest/v1/membership/ /relatives/ /';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('{"name":"Test","email":"test@test.com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.UpdateMembershipRelatedData();
        System.assertEquals(400, response.statusCode);
    }

    @isTest static void NotFoundForUpdateRelativeData_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 

        request.requestURI = '/services/apexrest/v1/membership/abcd/relatives/abcd';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('{"name":"Test","email":"test@test.com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.UpdateMembershipRelatedData();
        System.assertEquals(404, response.statusCode);
    }

    @isTest static void BadRequestOnGetMembership_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/v1/membership/ /';
        request.httpMethod = 'GET';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        System.assertEquals('Bad request.', response.responseBody.toString());
    }

    @isTest static void BadRequestOnGetRelative_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/v1/membership/ /relatives/ /';
        request.httpMethod = 'GET';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        System.assertEquals('Bad request.', response.responseBody.toString());
    }

    @isTest static void BadRequestOnGetRelatives_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/v1/membership/ /relatives';
        request.httpMethod = 'GET';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        System.assertEquals('Bad request.', response.responseBody.toString());
    }

    @isTest static void BadRequestOnDeleteMembership_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/v1/membership/ /';
        request.httpMethod = 'DELETE';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.DeleteMembershipRelatedData();
        System.assertEquals('Bad request.', response.responseBody.toString());
    }

    @isTest static void BadRequestOnDeleteRelative_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/v1/membership/ /relatives/ /';
        request.httpMethod = 'DELETE';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.DeleteMembershipRelatedData();
        System.assertEquals('Bad request.', response.responseBody.toString());
    }

    @isTest static void ServerErrorOnDeleteRelative_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = null;
        request.httpMethod = 'DELETE';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.DeleteMembershipRelatedData();
        System.assertEquals('Server error.', response.responseBody.toString());
    }

    @isTest static void ServerErrorOnGetRelative_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = null;
        request.httpMethod = 'DELETE';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.GetMembershipRelatedData();
        System.assertEquals('Server error.', response.responseBody.toString());
    }
    
    @isTest static void ServerErrorOnCreateRelative_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = null;
        request.httpMethod = 'DELETE';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.CreateMembershipRelatedData();
        System.assertEquals('Server error.', response.responseBody.toString());
    }

    @isTest static void ServerErrorOnUpdateRelative_Test() {
        // Set up a test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = null;
        request.httpMethod = 'DELETE';
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.UpdateMembershipRelatedData();
        System.assertEquals('Server error.', response.responseBody.toString());
    }

    @isTest static void UpdateRelativeDataToupdateRelative_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());
        List<Relative__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccoutntAndRelatives(1,1,1);

        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Membership__c+'/relatives/'+relative[0].Id;
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('{"name":"Test","email":"test@test".com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.UpdateMembershipRelatedData();
        System.assertEquals('Server error.', response.responseBody.toString());
    }

    @isTest static void UpdateRelativeDataToupdateMembershipError_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new DFJ_MembershipMock());
        List<Relative__c> relative = DFJ_TestDataFactory.CreateMembershipsWithAccoutntAndRelatives(1,1,1);

        request.requestURI = '/services/apexrest/v1/membership/'+ relative[0].Membership__c;
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('{"email":"test@test".com"}');
        request.remoteAddress = '101.53.164.8';
        request.addHeader('X-Provider-token', 'aa11bb22cc33');
        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        DFJ_MembershipWebhook.UpdateMembershipRelatedData();
        System.assertEquals('Server error.', response.responseBody.toString());
    }
}