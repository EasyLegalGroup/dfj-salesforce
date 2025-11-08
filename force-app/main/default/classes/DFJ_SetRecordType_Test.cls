@isTest
private class DFJ_SetRecordType_Test {

    // helper to get the Id of a Lead record-type by DeveloperName
    private static Id rtId(String devName) {
        Map<String, Schema.RecordTypeInfo> mapInfo =
            Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName();
        return mapInfo.containsKey(devName)
             ? mapInfo.get(devName).getRecordTypeId()
             : null;
    }

    @isTest
    static void setRecordType_Apex_Test() {

        Id hostRT = rtId('Host');
        Id dfjRT  = rtId('DFJ_DK');

        System.assertNotEquals(null, hostRT,
            'Host record-type must exist in the org (setup issue if null)');
        System.assertNotEquals(null, dfjRT,
            'DFJ_DK record-type must exist in the org (setup issue if null)');

        /* ----------  build test data  ---------- */
        List<Lead> leads = new List<Lead>{
            // Should be switched to DFJ_DK record-type
            new Lead(
                FirstName      = 'DKLead',
                LastName       = 'Tester',
                Company        = 'TestCo',
                Market_Unit__c = 'DFJ_DK'
            ),
            // Already Host – must stay Host
            new Lead(
                FirstName      = 'HostLead',
                LastName       = 'Tester',
                Company        = 'HostCo',
                Market_Unit__c = 'DFJ_DK',
                RecordTypeId   = hostRT
            )
        };

        Test.startTest();
        // simulate BEFORE-INSERT logic
        DFJ_SetRecordType.setRecordType_Apex(leads, null);
        insert leads;
        Test.stopTest();

        /* ----------  assertions  ---------- */
        System.assertEquals(dfjRT, leads[0].RecordTypeId,
            'DFJ_DK record-type should be set on DKLead');
        System.assertEquals(hostRT, leads[1].RecordTypeId,
            'Host record-type should remain on HostLead');
    }
}