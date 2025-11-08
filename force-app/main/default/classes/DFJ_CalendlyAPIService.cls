public class DFJ_CalendlyAPIService {
    
    public static final String CANCEL_PATH = 'cancellation';
    public static final String PATH_SEPARATOR = '/';
    public static final String BASE_ENDPOINT = 'callout:CalendlyAPI/scheduled_events/';
 //  public static final String BASE_ENDPOINT = 'https://api.calendly.com/scheduled_events/';
    public static final String REQUEST_METHOD_GET = 'GET';
    public static final String REQUEST_METHOD_POST = 'POST';
    public static final String CONTENT_TYPE = 'application/json';
  //change  
    // public static final String AUTH_HEADER = 'Authorization';
//public static final String API_KEY = 'eyJraWQiOiIxY2UxZTEzNjE3ZGNmNzY2YjNjZWJjY2Y4ZGM1YmFmYThhNjVlNjg0MDIzZjdjMzJiZTgzNDliMjM4MDEzNWI0IiwidHlwIjoiUEFUIiwiYWxnIjoiRVMyNTYifQ.eyJpc3MiOiJodHRwczovL2F1dGguY2FsZW5kbHkuY29tIiwiaWF0IjoxNzI1NzM1NDgyLCJqdGkiOiI2MjhhNzk3Mi01YjVkLTQzZDYtOWY4YS0zYzM5NGJkYTFmMzIiLCJ1c2VyX3V1aWQiOiJHRUdHWU9BNVNMVzJRUEFHIn0.xcqCbM_QRtEzUfmg5x961-PdVpLFMEyq97GXbKnu6T7PHTf6vdB1lNdmCYrmid1MUUXfUHuTSMs5OnqTRL3rxw';

    
    
    @InvocableMethod(callout=true label='Get/Cancel Scheduled Event' description='Call the Calendly API to perform calendly events')
    public static List<DFJ_CalendlyEventProcessor.Resource> performCalendlyActionFromFlow(List<FlowInput> flowInputs) {
        try {
            
            List<DFJ_CalendlyEventProcessor.Resource> response = new List<DFJ_CalendlyEventProcessor.Resource>();
            
            FlowInput input = flowInputs[0]; // DFJ-339
            if (String.isBlank(input.eventId) || String.isBlank(input.eventAction)) {
            throw new IllegalArgumentException('Event ID and Event Action is required.');
        }
            String requestMethod = REQUEST_METHOD_GET;
            String endpoint = BASE_ENDPOINT + input.eventId;
            String body = null;
            // DFJ-339 Changes start 
            if (input.eventAction == 'Cancel') {
                requestMethod = REQUEST_METHOD_POST;
                endpoint += PATH_SEPARATOR + CANCEL_PATH;
            }
            
            if (String.isNotBlank(input.reason)) {
                Map<String, Object> requestBodyMap = new Map<String, Object>();
                requestBodyMap.put('reason', input.reason);
                body = JSON.serialize(requestBodyMap);
            }
            // DFJ-339 Changes End
            HttpRequest req = new HttpRequest();
            req.setMethod(requestMethod);
            req.setEndpoint(endpoint);
            req.setHeader('Content-Type', CONTENT_TYPE);
          //  req.setHeader(AUTH_HEADER, 'Bearer ' + API_KEY);//change
            if (body != null) { 
                req.setBody(body);
            }
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if ((input.eventAction == 'Cancel' || input.eventAction == 'Get')  && (res.getStatusCode() == 201 || res.getStatusCode() == 200)) {
                response.add((DFJ_CalendlyEventProcessor.processCalendlyResponse(res.getBody())).Resource);
            } else {
                // Log API error with input details and endpoint
               String inputDetails = 'eventId: ' + input.eventId + ', eventAction: ' + input.eventAction + ', reason: ' + input.reason + ', endpoint: ' + endpoint;
                  DFJ_ErrorLogController.addErrorLogs('','Process DFJ_CalendlyAPIService','API Error: Status Code ' + res.getStatusCode() + ', Response: ' + res.getBody() + 
                    ', Inputs: ' + inputDetails + ', Endpoint: ' + endpoint,'API Error','DFJ_CalendlyAPIService.performCalendlyActionFromFlow','','-1');
            }
            return response;
        } catch (Exception ex) {
            // Handle any exceptions
            DFJ_ErrorLogController.addErrorLogs('','Process DFJ_CalendlyAPIService',ex.getMessage(),'Error','DFJ_CalendlyAPIService.performCalendlyActionFromFlow','', 
                                                String.valueOf(ex.getLineNumber()));
            return null;
        }
    }
    
    public class FlowInput {
        @InvocableVariable(label='Event Id' required=true)
        public String eventId;
        
        @InvocableVariable(label='Event Action' required=true)
        public String eventAction;
        
        @InvocableVariable(label='Cancellation reason' required=false)
        public String reason;
    }
}