({
    handlesalesDocumentCreations: function(c, e, h) {
        h.handlesalesDocumentCreations_helper(c, e, h);
    },
    closeModal: function(c, e, h) {
        c.set("v.openConfirmationModel", false);
    },
    openModel: function(c, e, h) {
        c.set("v.openConfirmationModel", true);
    },
})