({
    handlePaymentRecordCreation_helper: function(c, e, h) {
        try {
            c.set("v.buttonLabel", 'Running...');
            c.set("v.disableOkButton", true);

            let action = c.get("c.createPaymentRecord");
            action.setParams({ 'recordId': c.get("v.recordId") });
            action.setCallback(this, function(response) {
                let state = response.getState();
                // Changed the result
                let result = response.getReturnValue();
                if (state === 'SUCCESS') {                    
                        if (result && result.successMessage && !result.errorMessage) {
                            c.set("v.payment",result.payment);
                            c.set("v.paymentOrderLines",result.paymentOrderLines);
                            c.set("v.subscriptionLeadProducts",result.subscriptionLeadProducts);
                            c.set("v.subscriptionOrderItemProducts",result.subscriptionOrderItemProducts);
                            c.set("v.makeCallout", true);                            
                            h.showToast(c,e,h,result.successMessage,'Success');
                        }else{
                            h.showToast(c,e,h,result.errorMessage,'Error');
                        }
                } else {
                    let errors = result.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.info('Error message' + errors[0].message);
                        }
                        h.showToast(c,e,h,errors[0].message,'Error');
                    }
                }
                c.set("v.disableOkButton", false);
                c.set("v.buttonLabel", 'Ok');
                c.set("v.openConfirmationModel", false);
            });
            $A.enqueueAction(action);
        } catch (err) {
            console.log('Error ::: ',err);
        }
    },

    handleCallouts_helper : function (c,e,h) {
        try {            
            const payment = c.get("v.payment");
            const paymentOrderLines = c.get("v.paymentOrderLines");
            const subscriptionLeadProducts = c.get("v.subscriptionLeadProducts").length <= 0 ? c.get("v.subscriptionOrderItemProducts") : c.get("v.subscriptionLeadProducts");
            // console.log('c.get("v.sObjectName") >>> '+c.get("v.SObjectName"));
            c.set("v.buttonLabel", 'Running...');
            c.set("v.disableOkButton", true);

            let action = c.get("c.makeCalloutToCreateCustomerInvoice");
            action.setParams({ 'recordId': c.get("v.recordId"),'payment' : JSON.stringify(payment), 'paymentOrderLines' : JSON.stringify(paymentOrderLines),'subscriptionLeadProducts': subscriptionLeadProducts  });
            action.setCallback(this, function(response) {
                try {
                let state = response.getState();
                let result = response.getReturnValue();
                
                if (state === 'SUCCESS') {
                    
                    if (result && result.successMessage && !result.errorMessage) {
                        h.showToast(c,e,h,result.successMessage,'Success');
                        c.set("v.showCreatePaymentButton",false);
                    }else{
                        h.showToast(c,e,h,result.errorMessage,'Error');
                    }                    
                } else {
                    let errors = result.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.info('Error message' + errors[0].message);
                        }
                        h.showToast(c,e,h,errors[0].message,'Error');
                    }
                }
                c.get("v.makeCallout",false);
                c.set("v.disableOkButton", false);
                c.set("v.buttonLabel", 'Ok');
                c.set("v.openConfirmationModel", false);

            } catch (error) {
                    console.error('Error >>> ',error);
            }
            });
            $A.enqueueAction(action);
        } catch (error) {
            console.log('Error >>>',err);
        }
    },

    showToast: function(c, e, h, message, title) {
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