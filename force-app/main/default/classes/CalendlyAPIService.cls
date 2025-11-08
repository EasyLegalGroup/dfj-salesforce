public with sharing class CalendlyAPIService {
    @InvocableMethod
    public static List<String> fetchEventDetails(List<String> eventURIs) {
        List<String> responses = new List<String>();
        for (String eventURI : eventURIs) {
            String url = 'https://api.calendly.com/scheduled_events/' + eventURI;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer YOUR_API_KEY'); // Replace YOUR_API_KEY with your actual API key
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                responses.add(response.getBody());
            } else {
                responses.add('Error: ' + response.getStatusCode() + ' ' + response.getStatus());
            }
        }
        return responses;
    }
}