@IsTest
private class EnrichCustomerProfileTest {

    /* --- valid pick-list values in your org --- */
    private static final String COMM_RATING_EXISTING = '3';   // 1-5 global pick-list
    private static final String HAS_CHILDREN_OLD      = 'No';
    private static final String HAS_CHILDREN_NEW      = 'Yes';
    private static final String SOURCE_REQUIRED       = 'Customer Profiler';
    private static final String MARKET_UNIT_REQUIRED  = 'DFJ_DK';

    /* ---------- Positive path: non-null values overwrite, nulls don’t ---------- */
    @IsTest static void updatesOnlyWhenNotNull() {

        /* 1. Insert a Customer Profile (only its own fields) */
        Customer_Profile__c profile = new Customer_Profile__c(
            Has_Children__c         = HAS_CHILDREN_OLD,
            Communication_Rating__c = COMM_RATING_EXISTING
        );
        insert profile;

        /* 2. Form Submission that points to the profile and supplies required fields */
        Form_Submission__c sub = new Form_Submission__c(
            Customer_Profile__c     = profile.Id,
            Source__c               = SOURCE_REQUIRED,      // required on Form_Submission__c
            Market_Unit__c          = MARKET_UNIT_REQUIRED, // required on Form_Submission__c
            Has_Children__c         = HAS_CHILDREN_NEW,     // will overwrite
            Communication_Rating__c = null                  // null → keep existing
        );
        insert sub;

        /* 3. Call the invocable exactly as Flow will (single-Id list) */
        Test.startTest();
            EnrichCustomerProfile.enrich(new List<Id>{ sub.Id });
        Test.stopTest();

        /* 4. Assert results on the Customer Profile */
        profile = [
            SELECT Has_Children__c, Communication_Rating__c
            FROM   Customer_Profile__c
            WHERE  Id = :profile.Id
        ];
        System.assertEquals(HAS_CHILDREN_NEW, profile.Has_Children__c,
            'Non-null value from submission should overwrite.');
        System.assertEquals(COMM_RATING_EXISTING, profile.Communication_Rating__c,
            'Null in submission should leave existing data untouched.');
    }

    /* ---------- Negative path: lookup blank — method exits with no DML ---------- */
    @IsTest static void skipsWhenNoProfile() {

        /* Form Submission with required fields, but no Customer_Profile__c */
        Form_Submission__c sub = new Form_Submission__c(
            Source__c      = SOURCE_REQUIRED,
            Market_Unit__c = MARKET_UNIT_REQUIRED,
            Has_Children__c = HAS_CHILDREN_NEW
        );
        insert sub;

        /* Run the invocable – should finish silently with no errors */
        Test.startTest();
            EnrichCustomerProfile.enrich(new List<Id>{ sub.Id });
        Test.stopTest();

        /* No assert needed – test passes if no exception is thrown */
        System.assert(true);
    }
}