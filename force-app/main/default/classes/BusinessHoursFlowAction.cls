public with sharing class BusinessHoursFlowAction {
    
    @InvocableMethod(
        label='Get Business & Total Hours Difference' 
        description='Calculate both business-hours and total elapsed hours between two DateTimes.'
    )
    public static List<Response> getHoursDiff(List<Request> requests) {
        // Get the default Business Hours record
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        List<Response> results = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            
            // Calculate Business Hours Difference
            Long msDiff = BusinessHours.diff(bh.Id, req.startDateTime, req.endDateTime);
            res.businessHours = (msDiff != null) ? msDiff / (1000.0 * 60.0 * 60.0) : 0.0;
            
            // Calculate Total Time Difference (ignoring business hours)
            Long totalMsDiff = req.endDateTime.getTime() - req.startDateTime.getTime();
            res.totalHours = totalMsDiff / (1000.0 * 60.0 * 60.0);
            
            results.add(res);
        }
        
        return results;
    }

    // Request class for Flow input
    public class Request {
        @InvocableVariable(required=true description='Start DateTime')
        public Datetime startDateTime;
        
        @InvocableVariable(required=true description='End DateTime')
        public Datetime endDateTime;
    }

    // Response class for Flow output
    public class Response {
        @InvocableVariable(description='Business Hours Difference')
        public Double businessHours;
        
        @InvocableVariable(description='Total Hours Difference')
        public Double totalHours;
    }
}