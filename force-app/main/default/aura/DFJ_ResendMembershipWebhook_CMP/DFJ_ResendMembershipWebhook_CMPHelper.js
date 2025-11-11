({
    doInit_helper: function(c, e, h) {
        try {
            let action = c.get("c.CheckUserProfile");
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse) {
                        c.set('v.isUserAdmin', true);
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
            let dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
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
                    if (storedResponse && storedResponse.includes('Updated the membership records')) {
                        h.showToast(c, e, h, storedResponse, 'Success');
                    } else {
                        h.showToast(c, e, h, storedResponse, 'Error');
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
                    h.showToast(c, e, h, 'Somthing went wrong.', 'Error');
                }

                c.set('v.runProcessscriptLable', 'Ok');
                c.set('v.disableButton', false);
                let dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();

            });
            $A.enqueueAction(action);
        } catch (err) {
            console.error(err);
        }
    },

    showToast: function(component, event, helper, message, title) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            messageTemplate: '',
            duration: ' 5000',
            key: 'info_alt',
            type: title,
            mode: 'pester'
        });
        toastEvent.fire();
    },
})