({

    runProcessScript_helper: function(c, e, h) {
        try {
            c.set('v.runProcessscriptLable', 'Running...');
            c.set('v.disableButton', true);
            let action = c.get("c.CalculateSpendPerLead");
            action.setParams({
                spendPeriodId: c.get('v.recordId')
            });
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse.includes("leads processed")) {
                        h.showToast(c, e, h, storedResponse.toString(), 'Success');
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

                    h.showToast(c, e, h, 'Unable to run Script.', 'Error');
                }
                c.set('v.runProcessscriptLable', 'Yes');
                c.set('v.disableButton', false);
                let dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();

            });
            $A.enqueueAction(action);
        } catch (err) {
            console.error(err);
        }
    },

    closeDeleteModal_helper: function(c, e, h) {
        try {
            let dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
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