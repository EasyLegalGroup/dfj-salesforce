@isTest
private class UpdateLeadForCalendlyActionResponseTest {
    
    @isTest
    static void testUpdateLeadRec() {
        Calendly__CalendlyAction__c calInstance = new Calendly__CalendlyAction__c();
        calInstance.Calendly__EventCreatedAt__c = system.today();
        calInstance.Calendly__EventEndTime__c = system.today();
        calInstance.Calendly__EventPrimaryPublisherEmail__c = 'abc@abc.com';
        calInstance.Calendly__EventPrimaryPublisherName__c = 'abc';
        calInstance.Calendly__EventStartTime__c = system.today();
        calInstance.Calendly__EventSubject__c = 'abc';
        calInstance.Calendly__EventTypeDuration__c = 11.58;
        calInstance.Calendly__EventTypeKind__c = 'abc';
        calInstance.Calendly__EventTypeName__c = 'abc';
        calInstance.Calendly__EventTypeSlug__c = 'tm-foredrag-book-raadgivning';
        calInstance.Calendly__EventUuid__c = '1234';
        calInstance.Calendly__InviteeCreatedAt__c =  system.today();
        calInstance.Calendly__InviteeEmail__c ='abc@abc.com';
        calInstance.Calendly__InviteeUuid__c = '123';
        calInstance.Calendly__RequestId__c = '1234';
        insert calInstance;
        
        
        // Create a Lead record
        Lead leadRecord = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Provider_id__c = 'test'
        );
        insert leadRecord;
        
        List<UpdateLeadForCalendlyActionResponse.UpdateLeadActionRequest> requestList = new List<UpdateLeadForCalendlyActionResponse.UpdateLeadActionRequest>();
        UpdateLeadForCalendlyActionResponse.UpdateLeadActionRequest request = new UpdateLeadForCalendlyActionResponse.UpdateLeadActionRequest();
        request.calendlyRecord = calInstance;
        request.leadRecord = leadRecord.Id;
        requestList.add(request);
        
        Test.startTest();
        UpdateLeadForCalendlyActionResponse.updateLeadRec(requestList);
        Test.stopTest();
        
        Lead updatedLeadRecord = [SELECT Id FROM Lead WHERE Id = :leadRecord.Id];
        
        //  System.assertEquals('Expected Value for LeadField1__c', updatedLeadRecord.LeadField1__c, 'Assertion failed for LeadField1__c');
        // System.assertEquals(true, updatedLeadRecord.LeadField2__c, 'Assertion failed for LeadField2__c');
        //System.assertEquals(false, updatedLeadRecord.LeadField3__c, 'Assertion failed for LeadField3__c');
        
    }
  
}