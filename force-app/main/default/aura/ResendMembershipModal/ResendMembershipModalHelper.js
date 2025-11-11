({
    doInit_helper: function(c, e, h) {
        try {
            let action = c.get("c.CheckUserProfile");
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse && storedResponse.isAdmin) {
                        c.set('v.isUserAdmin', true);
                        c.set('v.numberOfMembership', storedResponse.noOfMembership);
                    } else {
                        c.set('v.disableButton', true);
                    }
                } else if (response.getState() === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    c.set('v.disableButton', true);

                }

            });
            $A.enqueueAction(action);

        } catch (err) {
            console.error(err);
        }
    },

    closeModal_helper: function(c, e, h) {
        try {
            h.navEvent_helper(c, e, h);
        } catch (err) {
            console.error(err);
        }
    },

    navEvent_helper: function(c, e, h) {
        try {
            let navigator = $A.get("$Label.c.DFJ_MembershipListviewNavigator");
            window.location.href = navigator;
        } catch (err) {
            console.error(err);
        }
    },

    resendWebhook_helper: function(c, e, h) {
        try {
            c.set('v.runProcessscriptLable', 'Running...');
            c.set('v.disableButton', true);
            let action = c.get("c.ResendmembershipWebhook");
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                } else if (response.getState() === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.error("Error message: " +
                                errors[0].message);
                        }
                    } else {
                        console.error("Unknown error");
                    }
                    console.log('failed');
                }

                c.set('v.runProcessscriptLable', 'Ok');
                c.set('v.disableButton', false);
                h.navEvent_helper(c, e, h);

            });
            $A.enqueueAction(action);
        } catch (err) {
            console.error(err);
        }
    },

})