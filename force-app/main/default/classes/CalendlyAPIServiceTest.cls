@isTest
public class CalendlyAPIServiceTest {
    @isTest
    static void testFetchEventDetails() {
        // Set up the mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Test the fetchEventDetails method
        List<String> eventURIs = new List<String>{'/scheduled_events/test-event-uri'};
        List<String> responses = CalendlyAPIService.fetchEventDetails(eventURIs);

        // Assert that the response is as expected
        System.assertEquals(1, responses.size());
        System.assert(responses[0].contains('Test Event'));
    }
}