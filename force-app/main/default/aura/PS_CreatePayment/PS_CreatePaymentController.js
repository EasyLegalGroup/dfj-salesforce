({
    handlePaymentRecordCreation: function(c, e, h) {
        h.handlePaymentRecordCreation_helper(c, e, h);
    },
    closeModal: function(c, e, h) {
        c.set("v.openConfirmationModel", false);
    },
    openModel: function(c, e, h) {
        c.set("v.openConfirmationModel", true);
    },
    calloutChangesHandler: function(c, e, h) {
        console.log('changes done to attribute');
        let makeCallout = c.get("v.makeCallout");
        if (makeCallout) {
            h.handleCallouts_helper(c,e,h);
        }
    },
})