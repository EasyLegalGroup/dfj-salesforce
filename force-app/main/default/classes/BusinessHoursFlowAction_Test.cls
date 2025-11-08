@isTest
private class BusinessHoursFlowAction_Test {
    
    @isTest
    static void testBusinessHoursDiff() {
        // Create a test Business Hours record (only needed if none exists)
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        // Set a known case creation and closure time within business hours
        Datetime startDT = Datetime.newInstance(2025, 3, 10, 10, 0, 0); // Monday 10:00 AM
        Datetime endDT = Datetime.newInstance(2025, 3, 10, 12, 30, 0); // Monday 12:30 PM

        // Create test request
        List<BusinessHoursFlowAction.Request> requests = new List<BusinessHoursFlowAction.Request>();
        BusinessHoursFlowAction.Request req = new BusinessHoursFlowAction.Request();
        req.startDateTime = startDT;
        req.endDateTime = endDT;
        requests.add(req);

        // Call the method
        List<BusinessHoursFlowAction.Response> results = BusinessHoursFlowAction.getHoursDiff(requests);
        
        // Assertions
        System.assertNotEquals(null, results);
        System.assertEquals(1, results.size()); // Ensure one response is returned
        System.assert(results[0].businessHours > 0, 'Business hours should be greater than zero');
        System.assert(results[0].totalHours == 2.5, 'Total hours should be exactly 2.5');
    }
}