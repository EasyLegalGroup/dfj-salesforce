({
    handlesalesDocumentCreations_helper: function(c, e, h) {
        try {
            c.set("v.buttonLabel", 'Running...');
            c.set("v.disableOkButton", true);

            let action = c.get("c.CreateSalesDocumentAndDeleteDraft_Apex");
            action.setParams({ 'recordId': c.get("v.recordId") });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    let result = response.getReturnValue();
                    if (result && !result.includes("Error")) {
                        h.showErrorToast(c, e, h, 'Sales document has been created successfully.', 'Success');
                        h.navigateToRecordPage_helper(c, e, h, result);
                    } else {
                        h.showErrorToast(c, e, h, result, 'Error');
                    }
                } else {
                    let errors = result.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.info('Error message' + errors[0].message);
                        }
                    }
                }
                c.set("v.disableOkButton", false);
                c.set("v.buttonLabel", 'Ok');
                c.set("v.openConfirmationModel", false);
            });
            $A.enqueueAction(action);
        } catch (err) {
            console.log(err);
        }
    },

    navigateToRecordPage_helper: function(c, e, h, navigateToId) {
        try {
            let navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": navigateToId,
                "slideDevName": "related"
            });
            navEvt.fire();
        } catch (err) {
            console.log(err);
        }
    },

    showErrorToast: function(c, e, h, message, title) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            messageTemplate: message,
            duration: '5000',
            type: title
        });
        toastEvent.fire();
    },
})