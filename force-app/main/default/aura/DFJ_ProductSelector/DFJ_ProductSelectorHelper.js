/**
 * Created by Shubham Sharma on 12-07-2019.
 */
({

    doInit_Helper: function(c, e, h) {
        try {
            let action = c.get("c.getAllThePricebooksAndLeadProducts_Apex");
            action.setParams({ 'leadId': c.get("v.recordId") });
            action.setCallback(this, function(response) {
                console.log('resposnse products >>> ',JSON.stringify(response));
                let state = response.getState();
                if (state === 'SUCCESS') {
                    let result = response.getReturnValue();
                    if (result != null && result != undefined && result != '') {
                        let priceBooks = [];
                        result.productData.forEach(function(ele) {
                            ele.pbeList.forEach(function(elein) {
                                elein.quantity = 0;
                            });
                            priceBooks.push(ele.pb2);
                        });
                        if (!$A.util.isEmpty(result.leadProducts)) {
                            result.leadProducts.forEach(function(ele) {
                                ele.isEditable = false;
                            });
                        }
                        c.set("v.priceBooks", priceBooks);
                        c.set("v.fullProductData", result.productData);
                        c.set("v.LeadProducts", result.leadProducts);
                        c.set("v.isoCode", result.DefaultCurrencyIsoCode);

                        let priceBookId = '';
                        if (!$A.util.isEmpty(result.leadProducts)) {
                            priceBookId = result.leadProducts[0].Pricebook_Id__c;
                            let fullProductData = c.get("v.fullProductData");
                            fullProductData.forEach(function(ele) {
                                if (priceBookId === ele.pb2.Id) {
                                    c.set("v.currentProductList", ele.pbeList);
                                    c.set("v.SelectedPriceBookName", ele.pb2.Name);
                                }
                            });
                            h.changeQuantity_helper(c, e, h);
                        }

                    } else {

                    }
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
            console.info('Error==>' + ex.message);
        }
    },
    increaseDecreaseButton_helper: function(c, e, h) {
        try {
            let productsList = c.get("v.currentProductList");
            let tabIndex = e.getSource().get("v.tabindex");
            let buttonName = e.getSource().get("v.name");

            if (productsList[tabIndex].quantity < 0) {
                productsList[tabIndex].quantity = 0;
            }
            if (buttonName === 'add') {
                productsList[tabIndex].quantity = parseInt(productsList[tabIndex].quantity) + 1;
            } else if (buttonName === 'subtract') {
                if (!productsList[tabIndex].quantity < 1) {
                    productsList[tabIndex].quantity = parseInt(productsList[tabIndex].quantity) - 1;
                }
            }
            c.set("v.currentProductList", productsList);
        } catch (ex) {
            console.info("Error==>" + ex.message);
        }
    },

    addProductNew_Helper: function(c, e, h) {
        let productsList = c.get('v.currentProductList');
        let total = c.get("v.total");
        let LeadProducts = c.get("v.LeadProducts"); // To insert all the lead products
        let leadProductIdList = []; // To insert all the lead products

        if (!$A.util.isEmpty(LeadProducts)) {
            LeadProducts.forEach(function(ele) {
                leadProductIdList.push(ele.Product_Id__c);
            });
        }

        if ($A.util.isEmpty(LeadProducts)) {
            productsList.forEach(function(ele) {
                if ((parseInt(ele.quantity) > 0)) {
                    let productInstance = {};
                    productInstance.Discount__c = 0;
                    productInstance.Item_Price__c = ele.UnitPrice;
                    productInstance.Pricebook_Id__c = ele.Pricebook2Id;
                    productInstance.Product_Id__c = ele.Product2Id;
                    productInstance.PricebookEntry_Id__c = ele.Id;
                    productInstance.Lead__c = c.get("v.recordId");
                    productInstance.Product_Name__c = ele.Name;
                    productInstance.Name = ele.Name;
                    productInstance.Partner_Provision_Value__c = ele.Partner_provision_value__c;
                    productInstance.Partner_Sales_Value__c = ele.Partner_sales_value__c;
                    productInstance.Provision_Base__c = ele.Provision_base__c;
                    productInstance.Quantity__c = ele.quantity;
                    productInstance.CurrencyIsoCode = ele.Product2.CurrencyIsoCode;
                    productInstance.Plan_handle__c = ele.Product2.Plan__c;
                    productInstance.Is_subscription__c = ele.Product2.Is_subscription__c;

                    LeadProducts.push(productInstance);

                }
            });
        } else {
            productsList.forEach(function(ele) {
                let flag = 0;
                if ((parseInt(ele.quantity) > 0)) {
                    if (leadProductIdList.includes(ele.Product2Id)) {
                        LeadProducts.forEach(function(eleLp) {
                            if (eleLp.Product_Id__c === ele.Product2Id) {
                                eleLp.Quantity__c = parseInt(ele.quantity) + parseInt(eleLp.Quantity__c);
                            }
                        });
                    } else {
                        leadProductIdList.push(ele.Product2Id);
                        let productInstance = {};
                        productInstance.Discount__c = 0;
                        productInstance.Item_Price__c = ele.UnitPrice;
                        productInstance.Pricebook_Id__c = ele.Pricebook2Id;
                        productInstance.Product_Id__c = ele.Product2Id;
                        productInstance.PricebookEntry_Id__c = ele.Id;
                        productInstance.Lead__c = c.get("v.recordId");
                        productInstance.Product_Name__c = ele.Name;
                        productInstance.Name = ele.Name;
                        productInstance.Partner_Provision_Value__c = ele.Pricebook2.partner_provision_value__c;
                        productInstance.Partner_Sales_Value__c = ele.Pricebook2.partner_sales_value__c;
                        productInstance.Provision_Base__c = ele.Pricebook2.Provision_base__c;
                        productInstance.Quantity__c = ele.quantity;
                        productInstance.CurrencyIsoCode = ele.Product2.CurrencyIsoCode;
                        productInstance.Plan_handle__c = ele.Product2.Plan__c;
                        productInstance.Is_subscription__c = ele.Product2.Is_subscription__c;
                        LeadProducts.push(productInstance);
                    }
                }
            });
        }
        c.set("v.LeadProducts", LeadProducts);
        h.changeQuantity_helper(c, e, h);
        let fullProductData = c.get("v.fullProductData");
        fullProductData.forEach(function(ele) {
            if (LeadProducts[0].Pricebook_Id__c === ele.pb2.Id) {
                c.set("v.SelectedPriceBookName", ele.pb2.Name);
            }
        });
        console.log('leadProducts before insert >>> ',JSON.stringify(LeadProducts));
        let newProductList = c.get("v.LeadProducts");
        let action = c.get("c.insertRecords_Apex");
        action.setParams({
            "newProductList": LeadProducts,
            "leadId": c.get("v.recordId"),
            'total': c.get("v.total")
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === 'SUCCESS') {
                let storeResponse = response.getReturnValue();
                if (!$A.util.isUndefinedOrNull(storeResponse) && !$A.util.isEmpty(storeResponse)) {
                    c.set("v.LeadProducts", storeResponse);
                    h.changeQuantity_helper(c, e, h);
                    h.changeTotalvalue_Helper(c, e, h);
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                let errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.info('Error message' + errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },

    changeQuantity_helper: function(c, e, h) {
        try {
            let totalPrice = 0;
            let totalProvisionBase = 0.00;
            let totalPartnerSalesValue = 0.00;
            let totalPartnerProvisionValue = 0.00;
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
                // Changes for ticket DIN-249 : Allow fractional numbers on lead products discount.
                // Description : Removing = from check so value like 0.5 could be considered
                // Start
                if (!ele.Discount__c || ele.Discount__c === NaN || ele.Discount__c < 0) {
                    ele.Discount__c = 0;
                } else if (ele.Discount__c >= 100) {
                    ele.Discount__c = 100;
                }
                // End

                // Changes for ticket DIN-249 : Allow fractional numbers on lead products discount.
                // Description : calculating the discount value and then parse to float.
                // Start
                let discountedValue = parseFloat((ele.Discount__c / 100) * (ele.Item_Price__c)).toFixed(2);
                // End

                ele.totalPrice = parseFloat((parseFloat(ele.Item_Price__c).toFixed(2) - parseFloat(discountedValue).toFixed(2)) * ele.Quantity__c).toFixed(2);
                totalPrice = parseFloat(totalPrice) + parseFloat(ele.totalPrice);
                /*New changes*/
                /*checking whether the partner provision value is null or undefined or Nan*/
                if (ele.Partner_Provision_Value__c === null || ele.Partner_Provision_Value__c === undefined || ele.Partner_Provision_Value__c === NaN) {
                    ele.Partner_Provision_Value__c = 0;
                }
                totalPartnerProvisionValue = parseFloat(totalPartnerProvisionValue) + parseFloat(ele.Partner_Provision_Value__c);

                /*checking whether the provision base is null or undefined or Nan*/
                if (ele.Provision_Base__c === null || ele.Provision_Base__c === undefined || ele.Provision_Base__c === NaN) {
                    ele.Provision_Base__c = 0;
                }
                totalProvisionBase = parseFloat(totalProvisionBase) + parseFloat(ele.Provision_Base__c);

                /*checking whether the partner sales value is null or undefined or Nan*/
                if (ele.Partner_Sales_Value__c === null || ele.Partner_Sales_Value__c === undefined || ele.Partner_Sales_Value__c === NaN) {
                    ele.Partner_Sales_Value__c = 0;
                }
                totalPartnerSalesValue = parseFloat(totalPartnerSalesValue) + parseFloat(ele.Partner_Sales_Value__c);

            });

            let totalValues = {};
            totalValues.totalProvisionBase = totalProvisionBase;
            totalValues.totalPartnerSalesValue = totalPartnerSalesValue;
            totalValues.totalPartnerProvisionValue = totalPartnerProvisionValue;
            c.set("v.totalValues", totalValues);
            c.set("v.total", totalPrice.toFixed(2));
            c.set("v.LeadProducts", newProductList);


        } catch (ex) {
            console.info("Error:-->" + ex.message);
        }
    },

    editButtonClicked_helper: function(c, e, h) {
        try {
            let selectedProduct = c.get("v.LeadProducts");
            let selectedButton = e.getSource().get("v.title");
            let selectedIndex = e.getSource().get("v.tabindex");
            if (selectedButton === 'Edit') {
                selectedProduct[selectedIndex].isEditable = !selectedProduct[selectedIndex].isEditable;
            }
            if (selectedButton === 'Save') {
                selectedProduct[selectedIndex].isEditable = false;
                let changedDiscount = selectedProduct[selectedIndex];
                // Changes for DIN-249 : Allow fractional numbers on lead products discount
                // Start
                changedDiscount.Discount__c = parseFloat(changedDiscount.Discount__c);
                // End
                let action = c.get("c.updateRecordOfLeadProduct_Apex");
                action.setParams({
                    'changedDiscount': changedDiscount
                });
                action.setCallback(this, function(response) {
                    if (response.getState() === 'SUCCESS') {
                        h.changeTotalvalue_Helper(c, e, h);

                        let storedResponse = response.getReturnValue();
                        if (!$A.util.isUndefinedOrNull(storedResponse) && !$A.util.isEmpty(storedResponse)) {
                            storedResponse.forEach(function(ele) {
                                ele.isEditable = false;
                            });
                        }
                    } else if (state === 'ERROR') {
                        let errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.info('Error message' + errors[0].message);
                            }
                        }
                    }
                });
                $A.enqueueAction(action);
            }
            c.set("v.LeadProducts", selectedProduct);
        } catch (ex) {
            console.info("Error::--->" + ex.message);
        }
    },

    deleteRecordWhenButtonClicked_helper: function(c, e, h) {
        try {
            h.changeQuantity_helper(c, e, h);
            let productList = c.get("v.LeadProducts");
            let selectedIndex = c.get("v.deleteTabIndex");
            let productId = productList[selectedIndex].Id;
            let action = c.get("c.deleteRecordOfLeadProduct_Apex");
            let total = c.get("v.total");
            action.setParams({
                'productId': productId,
                'leadId': c.get("v.recordId")
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === "SUCCESS") {
                    let storeResponse = response.getReturnValue();
                    h.showSuccessToast(c, e, h);
                    c.set("v.LeadProducts", storeResponse);
                    h.changeQuantity_helper(c, e, h);
                    c.set("v.total", c.get("v.total"));

                    c.set("v.CurrentPricebook", '');
                    if (productList.length === 0) {
                        c.set("v.currentProductList", []);
                    }
                    h.changeTotalvalue_Helper(c, e, h);
                } else if (state === "ERROR") {
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.info('Error message' + errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action);
            $A.get('e.force:refreshView').fire();
            let newProductList = c.get("v.LeadProducts");
            c.set("v.LeadProducts", newProductList);


        } catch (ex) {
            console.info("Error::-->" + ex.message);
        }
    },

    changeTotalvalue_Helper: function(c, e, h) {
        let action = c.get("c.changeTotalSalesValue_Apex");
        action.setParams({
            'leadId': c.get("v.recordId"),
            'total': c.get("v.total")
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let storeResponse = response.getReturnValue();
                if (storeResponse) {
                    $A.get('e.force:refreshView').fire();
                }
                //e.force
            } else if (state === "ERROR") {
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.info('Error message' + errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
        $A.get('e.force:refreshView').fire();
    },

    showSuccessToast: function(c, e, h) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: 'Success',
            message: 'Product deleted successfully.',
            messageTemplate: 'Product deleted successfully.',
            duration: ' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();
    },

    changeIntValue_Helper: function(c, e, h) {
        try {
            let currentProductList = c.get("v.currentProductList");
            let tabIndex = e.getSource().get("v.name");
            currentProductList[tabIndex].quantity = parseInt(currentProductList[tabIndex].quantity);
            if (currentProductList[tabIndex].quantity <= 0) {
                currentProductList[tabIndex].quantity = 1;
            } else if (currentProductList[tabIndex].quantity >= 999) {
                currentProductList[tabIndex].quantity = 999;
            }
            c.set("v.currentProductList", currentProductList);
        } catch (ex) {
            console.log('Exception in changing quantity--' + ex);
        }
    }

})