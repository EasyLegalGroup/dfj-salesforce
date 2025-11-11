({
    submitDetails: function(c, e, h) {
        console.log('submitted details');
    },
    doInit: function(c, e, h) {
        h.doInit_helper(c, e, h);
    },

    closeModel: function(c, e, h) {
        h.closeModal_helper(c, e, h);
    },

    resendWebhook: function(c, e, h) {
        h.resendWebhook_helper(c, e, h);
    },
})