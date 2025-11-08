public class DFJ_CalendlyEventProcessor {
    public Boolean resource_set;
    
    @InvocableVariable
    public Resource resource;
    
    public class Resource {
        @InvocableVariable
        public String uri;
        @InvocableVariable
        public String name;
        @InvocableVariable
        public String meeting_notes_plain;
        @InvocableVariable
        public String meeting_notes_html;
        @InvocableVariable
        public String status;
        @InvocableVariable
        public String booking_method;
        @InvocableVariable
        public String start_time;
        @InvocableVariable
        public String end_time;
        @InvocableVariable
        public String event_type;
        @InvocableVariable
        public Location location;
        @InvocableVariable
        public InviteesCounter invitees_counter;
        @InvocableVariable
        public String created_at;
        @InvocableVariable
        public String updated_at;
        @InvocableVariable
        public String hostName;
        @InvocableVariable
        public String hostEmail;
        @InvocableVariable
        public String user;
        @InvocableVariable
        public String canceled_by;//DFJ-339
        @InvocableVariable
        public String reason;//DFJ-339
        @InvocableVariable
        public String canceler_type;//DFJ-339
        public EventMembership[] event_memberships;
        @InvocableVariable
        public List<EventGuest> event_guests;
        @InvocableVariable
        public CalendarEvent calendar_event;
    }
    
    public class Location {
        @InvocableVariable
        public String type;
        @InvocableVariable
        public String location;
        @InvocableVariable
        public String additional_info;
    }
    
    public class InviteesCounter {
        @InvocableVariable
        public Integer total;
        @InvocableVariable
        public Integer active;
        
    }
    
    public class EventMembership {
        @InvocableVariable
        public String user;
        @InvocableVariable
        public String user_email;
        @InvocableVariable
        public String user_name;
        @InvocableVariable
        public String buffered_end_time;
        @InvocableVariable
        public String buffered_start_time;
    }
    
    public class EventGuest {
        @InvocableVariable
        public String email;
        @InvocableVariable
        public String created_at;
        @InvocableVariable
        public String updated_at;
    }
    
    public class CalendarEvent {
        @InvocableVariable
        public String kind;
        @InvocableVariable
        public String external_id;
    }
    
    public static DFJ_CalendlyEventProcessor processCalendlyResponse(String jsonResponse) {
        try{
            DFJ_CalendlyEventProcessor response = (DFJ_CalendlyEventProcessor) JSON.deserialize(jsonResponse, DFJ_CalendlyEventProcessor.class);
            if (response.resource.event_memberships != null ) {
                for (EventMembership membership : response.resource.event_memberships) {
                    response.resource.hostEmail = membership.user_email;
                    response.resource.hostName = membership.user_name;
                }
            } 
            return response;
        }
        catch(Exception ex){
             DFJ_ErrorLogController.addErrorLogs('', 'Process Calendly Response', ex.getMessage(), 'Error', 'DFJ_CalendlyEventProcessor.processCalendlyResponse', '', String.valueOf(ex.getLineNumber()));
            return null;
        }
    }
}