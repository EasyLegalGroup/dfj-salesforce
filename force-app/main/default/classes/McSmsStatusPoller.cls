global class McSmsStatusPoller implements Schedulable, Database.AllowsCallouts {
    global void execute(SchedulableContext sc) {
        Integer MAX = 90;
        List<SMS__c> rows = [
            SELECT Id, External_ID__c, Status__c, Direction__c, Is_Synced_to_Marketing_Cloud__c
            FROM SMS__c
            WHERE Direction__c = 'Outgoing'
              AND Is_Synced_to_Marketing_Cloud__c = true
              AND External_ID__c != null
              AND (Status__c = 'Pending' OR Status__c = 'Queued')
            LIMIT :MAX
            FOR UPDATE
        ];

        List<SMS__c> updates = new List<SMS__c>();
        for (SMS__c s : rows) {
            try {
                McRestClient.Result r = McRestClient.getMessage(s.External_ID__c);
                s.Status_Code__c = String.valueOf(r.status);
                s.Response_Body__c = r.body;

                if (r.status == 200 && String.isNotBlank(r.body)) {
                    Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r.body);
                    String evt = (String) m.get('eventCategoryType');

                    // ▼ Updated mapping block
                    if (evt != null) {
                        if (evt.contains('Delivered')) {
                            s.Status__c = 'Delivered';
                        } else if (evt.contains('Failed') || evt.contains('Undeliverable') || evt.contains('Error') || evt.contains('NotSent')) {
                            s.Status__c = 'Failed';
                        } else if (evt.contains('Queued') || evt.contains('Sending')) {
                            s.Status__c = 'Queued';
                        }
                    }
                }

                s.Sent_Received_Time__c = System.now();
                updates.add(s);
            } catch (Exception ex) {
                s.Status_Code__c = 'EX';
                s.Response_Body__c = ex.getTypeName() + ': ' + ex.getMessage();
                s.Sent_Received_Time__c = System.now();
                updates.add(s);
            }
        }
        if (!updates.isEmpty()) update updates;
    }
}