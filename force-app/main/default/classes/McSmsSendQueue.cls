public class McSmsSendQueue implements Queueable, Database.AllowsCallouts {
    @TestVisible static Integer MAX_OVERRIDE;

    private Set<Id> ids;
    public McSmsSendQueue(Set<Id> ids) { this.ids = ids; }

    public void execute(QueueableContext qc) {
        List<Id> all = new List<Id>(ids);
        Integer MAX = (MAX_OVERRIDE == null ? 90 : MAX_OVERRIDE);

        List<Id> now   = new List<Id>();
        List<Id> later = new List<Id>();
        for (Integer i = 0; i < all.size(); i++) {
            if (i < MAX) now.add(all[i]); else later.add(all[i]);
        }
        if (now.isEmpty()) {
            if (!later.isEmpty()) System.enqueueJob(new McSmsSendQueue(new Set<Id>(later)));
            return;
        }

        List<SMS__c> rows = [
            SELECT Id, To_Number__c, From_Number__c, Direction__c, Status__c,
                   Is_Synced_to_Marketing_Cloud__c, External_ID__c, Message__c, Record_ID__c,
                   CurrencyIsoCode, Send_From_Alphanumeric_Sender_ID__c
            FROM SMS__c
            WHERE Id IN :now
            FOR UPDATE
        ];

        Set<Id> leadIds = new Set<Id>(), contactIds = new Set<Id>();
        for (SMS__c s : rows) {
            try {
                if (!String.isBlank(s.Record_ID__c) && s.Record_ID__c.length() == 18) {
                    Id rid = (Id) s.Record_ID__c;
                    if (rid.getSObjectType() == Lead.SObjectType) leadIds.add(rid);
                    else if (rid.getSObjectType() == Contact.SObjectType) contactIds.add(rid);
                }
            } catch (Exception ignore) {}
        }
        Map<Id, Lead> leads = leadIds.isEmpty() ? new Map<Id, Lead>()
            : new Map<Id, Lead>([SELECT Id, FirstName, MobilePhone, Phone FROM Lead WHERE Id IN :leadIds]);
        Map<Id, Contact> contacts = contactIds.isEmpty() ? new Map<Id, Contact>()
            : new Map<Id, Contact>([SELECT Id, FirstName, MobilePhone, Phone FROM Contact WHERE Id IN :contactIds]);

        List<SMS__c> updates = new List<SMS__c>();

        for (SMS__c s : rows) {
            if (s.Direction__c != 'Outgoing' || s.Is_Synced_to_Marketing_Cloud__c) continue;

            try {
                // ---------- NEW ORDER: resolve def key first ----------
                String defKey = McSmsRouting.resolveDefinitionKey(s);
                String iso2   = inferCountryIso2FromDefKey(defKey); // 'DK' / 'SE' (falls back to DK)

                // Get number (SMS__c or related record), but DON'T country-normalize yet
                String rawTo = s.To_Number__c;
                String firstName = null;

                if (String.isBlank(rawTo) && !String.isBlank(s.Record_ID__c) && s.Record_ID__c.length() == 18) {
                    Id rid = (Id) s.Record_ID__c;
                    if (rid.getSObjectType() == Lead.SObjectType && leads.containsKey(rid)) {
                        Lead l = leads.get(rid);
                        rawTo = String.isNotBlank(l.MobilePhone) ? l.MobilePhone : l.Phone;
                        firstName = l.FirstName;
                    } else if (rid.getSObjectType() == Contact.SObjectType && contacts.containsKey(rid)) {
                        Contact c = contacts.get(rid);
                        rawTo = String.isNotBlank(c.MobilePhone) ? c.MobilePhone : c.Phone;
                        firstName = c.FirstName;
                    }
                }

                McPhone.Norm norm = McPhone.normalize(rawTo, iso2);
                if (norm.warning != null) System.debug(LoggingLevel.WARN, iso2 + ' sanity warning for ['+rawTo+']: ' + norm.warning);

                if (String.isBlank(norm.digits)) {
                    s.Status_Code__c = 'NO_NUMBER';
                    s.Response_Body__c = 'No phone number on SMS__c or related record';
                    s.Sent_Received_Time__c = System.now();
                    updates.add(s);
                    continue;
                }

                Map<String,Object> attrs = new Map<String,Object>();
                if (String.isNotBlank(firstName)) attrs.put('FirstName', firstName);

                Boolean wantAlpha = (s.Send_From_Alphanumeric_Sender_ID__c == true);
                if (wantAlpha && !attrs.containsKey('FromName')) {
                    attrs.put('FromName', 'FamJurist');
                }

                String contactKey = !String.isBlank(s.Record_ID__c) ? s.Record_ID__c : norm.digits;
                String messageKey = !String.isBlank(s.External_ID__c) ? s.External_ID__c : (String) s.Id;

                McRestClient.Result res = McRestClient.sendSmsWithKey(defKey, norm.digits, contactKey, attrs, messageKey);

                s.Is_Synced_to_Marketing_Cloud__c = (res.status == 202);
                s.Status_Code__c = String.valueOf(res.status);
                s.Response_Body__c = res.body;
                s.Sent_Received_Time__c = System.now();

                if (String.isBlank(s.External_ID__c)) s.External_ID__c = messageKey;
                updates.add(s);

            } catch (Exception ex) {
                s.Is_Synced_to_Marketing_Cloud__c = false;
                s.Status_Code__c = 'EX';
                s.Response_Body__c = ex.getTypeName() + ': ' + ex.getMessage();
                s.Sent_Received_Time__c = System.now();
                updates.add(s);
            }
        }

        if (!updates.isEmpty()) update updates;

        if (!later.isEmpty()) {
            System.enqueueJob(new McSmsSendQueue(new Set<Id>(later)));
        }
    }

    // ---------- NEW helper: infer country from definition key ----------
    @TestVisible
    private static String inferCountryIso2FromDefKey(String defKey) {
        String k = (defKey == null ? '' : defKey.toUpperCase());
        if (k.contains('_SE') || k.endsWith('SE') || k.startsWith('SE') || k.contains('SE_')) return 'SE';
        // default to DK (your current footprint)
        return 'DK';
    }
}