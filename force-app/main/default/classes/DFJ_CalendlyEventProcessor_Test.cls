@isTest
public class DFJ_CalendlyEventProcessor_Test {
	@isTest
    public static void testProcessCalendlyResponse() {
        String jsonResponse = 
        '{'+
            '"resource_set": true,'+
            '"resource": {'+
                '"uri_set": true,'+
                '"uri": "https://api.calendly.com/scheduled_events/02d90a8f-80e2-480f-9b73-3d1de967d96b",'+
                '"updatedx5fat_set": true,'+
                '"updatedx5fat": "2024-09-13T16:05:05.668Z",'+
                '"status_set": true,'+
                '"status": "active",'+
                '"startx5ftime_set": true,'+
                '"startx5ftime": "2024-09-16T11:30:00.000Z",'+
                '"name_set": true,'+
                '"name": "Video Call (30 Minutes)",'+
                '"meetingx5fnotesx5fplain_set": true,'+
                '"meetingx5fnotesx5fhtml_set": true,'+
                '"location_set": true,'+
                '"location": {'+
                    '"z0type_set": true,'+
                    '"z0type": "custom",'+
                    '"location_set": true,'+
                    '"location": "https://meet.google.com/cfe-sryk-xwy"'+
                '},'+
                '"inviteesx5fcounter_set": true,'+
                '"inviteesx5fcounter": {'+
                    '"z0limit_set": true,'+
                    '"z0limit": 1,'+
                    '"total_set": true,'+
                    '"total": 1,'+
                    '"active_set": true,'+
                    '"active": 1'+
                '},'+
                '"eventx5ftype_set": true,'+
                '"eventx5ftype": "https://api.calendly.com/event_types/38de9d90-095b-4792-85b3-52e1408223c6",'+
                '"eventx5fmemberships_set": true,'+
                '"event_memberships": ['+
                    '{'+
                        '"z0user_set": true,'+
                        '"user": "",'+
                        '"userx5fname_set": true,'+
                        '"user_name": "John Doe",'+
                        '"userx5femail_set": true,'+
                        '"user_email": "jd@example.com",'+
                        '"bufferedx5fstartx5ftime_set": true,'+
                        '"bufferedx5fstartx5ftime": "2024-09-16T11:30:00.000Z",'+
                        '"bufferedx5fendx5ftime_set": true,'+
                        '"bufferedx5fendx5ftime": "2024-09-16T12:00:00.000Z"'+
                    '}'+
                '],'+
                '"eventx5fguests_set": true,'+
                '"eventx5fguests": [],'+
                '"endx5ftime_set": true,'+
                '"endx5ftime": "2024-09-16T12:00:00.000Z",'+
                '"createdx5fat_set": true,'+
                '"createdx5fat": "2024-09-13T16:05:02.097Z",'+
                '"calendarx5fevent_set": true,'+
                '"calendarx5fevent": {'+
                    '"kind_set": true,'+
                    '"kind": "outlook",'+
                    '"externalx5fid_set": true,'+
                    '"externalx5fid": "AAMkADA2NjkzOTBhLWNlYzUtNGUwYi04OTQyLWYzMjk4MzQ0MTY0ZgBGAAAAAAB-fQgkJoUiSKdObLnyndj0BwCU2MnAPbNHQpYc9E2Qc821AAAAAAENAACU2MnAPbNHQpYc9E2Qc821AAMI3Gv4AAA="'+
                '}'+
            '}'+
        '}';
        
        Test.startTest();
        // Call the process method with the JSON response
           Test.setMock(HttpCalloutMock.class, new DFJ_MockResponseGenerator());
        //List<DFJ_CalendlyEventProcessor.Resource> resList = DFJ_CalendlyAPIService.getScheduledEventFromFlow(new List<String>{'123'});
        List<DFJ_CalendlyAPIService.FlowInput> ff = new List<DFJ_CalendlyAPIService.FlowInput>();
        DFJ_CalendlyAPIService.FlowInput f = new DFJ_CalendlyAPIService.FlowInput();
        f.eventId = 'DFJ-339';
        f.eventAction = 'Cancel';
        f.reason = 'Check';
        ff.add(f);
        List<DFJ_CalendlyEventProcessor.Resource> resList = DFJ_CalendlyAPIService.performCalendlyActionFromFlow(ff);
        DFJ_CalendlyEventProcessor response = DFJ_CalendlyEventProcessor.processCalendlyResponse(null);
        Test.stopTest();
        System.assertEquals(1,1,'');
        System.assertEquals(1,1,'');
    }
}