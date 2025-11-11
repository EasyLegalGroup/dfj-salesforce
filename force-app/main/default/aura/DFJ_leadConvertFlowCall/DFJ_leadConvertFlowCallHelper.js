({
    init_helper: function(c, e, h) {
        try {
            let action = c.get("c.getSelectedProductData_Apex");
            let recordId = c.get("v.recordId");
            action.setParams({
                'leadRecordId': recordId
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    let result = response.getReturnValue();
                    c.set("v.defaultCurrencyIsoCode", result.DefaultCurrencyIsoCode);
                    c.set("v.LeadProducts", result.leadProducts);
                    c.set("v.leadFixedDiscount", result.relatedLead.Fixed_discount_Type__c);

                    h.changeQuantity_helper(c, e, h);
                } else {
                    let errors = result.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.info('Error message' + errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action);
        } catch (ex) {
            console.info("Error" + ex);
        }
    },

    getPicklistValues_helper: function(c, e, h) {
        try {
            let action = c.get("c.getPicklistValues_Apex");
            action.setParams({
                'objectName': 'Order',
                'fieldsNames': 'Payment_method__c,Payment_type__c'
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    let result = response.getReturnValue();

                    let allPicklistValue = {};
                    let paymentMethodPicklistArray = [];
                    let paymentTypePicklistArray = [];
                    result.forEach(function(ele) {
                        if (ele.fieldName === 'Payment_method__c') {
                            ele.multiplepicklist.forEach(function(ele) {
                                let paymentMethodPicklistObject = {};
                                paymentMethodPicklistObject.label = ele.Label;
                                paymentMethodPicklistObject.value = ele.value;
                                paymentMethodPicklistArray.push(paymentMethodPicklistObject);
                            });
                        } else if (ele.fieldName === 'Payment_type__c') {
                            ele.multiplepicklist.forEach(function(ele) {
                                let paymentTypePicklistObject = {};
                                paymentTypePicklistObject.label = ele.Label;
                                paymentTypePicklistObject.value = ele.value;
                                paymentTypePicklistArray.push(paymentTypePicklistObject);
                            });
                        }
                    });

                    allPicklistValue.paymentMethodPicklistArray = paymentMethodPicklistArray;
                    allPicklistValue.paymentTypePicklistArray = paymentTypePicklistArray;
                    c.set("v.allPicklistValue", allPicklistValue);
                } else {
                    let errors = result.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.info('Error message' + errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action);
        } catch (ex) {
            console.info("Error" + ex);
        }
    },

    changeQuantity_helper: function(c, e, h) {
        try {
            let totalPrice = 0;
            let newProductList = c.get('v.LeadProducts');
            newProductList.forEach(function(ele) {
                // Check if the smaller than 0 change it to 1
                ele.Quantity__c = parseInt(ele.Quantity__c);
                if (ele.Quantity__c <= 0) {
                    ele.Quantity__c = 1;
                } else if (ele.Quantity__c >= 999) {
                    ele.Quantity__c = 999;
                }

                //ele.Discount__c = parseInt(ele.Discount__c);
                if (ele.Discount__c <= 0) {
                    ele.Discount__c = 0;
                } else if (ele.Discount__c >= 100) {
                    ele.Discount__c = 100;
                }
                // changes for DIN-249 : Allow fractional numbers on lead products discount
                // Start
                let discountedValue = parseFloat((ele.Discount__c / 100) * (ele.Item_Price__c)).toFixed(2);
                // End
                ele.totalPrice = parseFloat((parseFloat(ele.Item_Price__c).toFixed(2) - parseFloat(discountedValue).toFixed(2)) * ele.Quantity__c).toFixed(2);
                totalPrice = parseFloat(totalPrice) + parseFloat(ele.totalPrice);
            });
            let leadFixedDiscount = c.get("v.leadFixedDiscount");
            c.set("v.subTotalAmount", totalPrice);
            totalPrice = totalPrice >= leadFixedDiscount ? totalPrice - leadFixedDiscount : 0;
            c.set("v.total", totalPrice.toFixed(2));
            c.set("v.LeadProducts", newProductList);
            c.set("v.subTotalAmount", subTotalAmount);

        } catch (ex) {
            console.info("Error:-->" + ex.message);
        }
    },
})