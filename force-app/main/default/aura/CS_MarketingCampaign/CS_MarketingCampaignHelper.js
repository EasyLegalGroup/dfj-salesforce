({
    doInit_helper: function(c, e, h) {
        try {
            h.showSpinner_Helper(c, e);
            let action = c.get("c.GetAllTheMarketingCampaign_Apex");
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse) {
                        if (storedResponse.marketingCampaignList && storedResponse.marketingCampaignList.length > 0) {
                            c.set('v.campaignList', storedResponse.marketingCampaignList);
                        } else {
                            c.set('v.campaignList', []);
                        }
                        c.set('v.picklistOptions', storedResponse.picklistOptions);
                        let spendPeriodList = storedResponse.spendPeriodList && storedResponse.spendPeriodList.length > 0 ? storedResponse.spendPeriodList : [];
                        c.set('v.spendPeriodList', spendPeriodList);

                    } else {

                        c.set('v.campaignList', []);
                    }
                    h.hideSpinner_Helper(c, e);
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
                    h.hideSpinner_Helper(c, e);
                }
            });
            $A.enqueueAction(action);
        } catch (err) {
            console.error(err);
        }
    },

    checkValidation_helper: function(c, e, h) {
        try {
            let campaignInstance = c.get('v.campaignInstance');
            if (!campaignInstance.Name || !campaignInstance.Cost_Category__c) {
                h.showToast(c, e, h, 'Please fill the required fields.', 'error');
                return;
            } else {
                h.saveCampaign_helper(c, e, h);
            }
        } catch (error) {

        }
    },

    saveCampaign_helper: function(c, e, h) {
        try {
            let campaignInstance = c.get('v.campaignInstance');
            let campaignList = c.get('v.campaignList');
            h.showSpinner_Helper(c, e);

            let action = c.get('c.SaveMarketingCampaign');
            action.setParams({
                'marketingCampaignInstance': JSON.stringify(campaignInstance)
            });
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse) {
                        c.set('v.createCampaign', false);
                        // Checking campaign is edited if not edited just pushing the instance in list else updating in existing marketing campaign instance.
                        if (!c.get('v.isEditing')) {
                            campaignInstance.Id = storedResponse;
                            campaignList = [campaignInstance, ...campaignList]; //.push(campaignInstance);
                            h.showToast(c, e, h, 'Successfully created marketing campaign.', 'success');

                        } else {
                            let index = campaignList.findIndex((element) => element.Id === campaignInstance.Id);
                            if (index >= 0) {
                                campaignList[index].Name = campaignInstance.Name;
                                campaignList[index].UTM_Source__c = campaignInstance.UTM_Source__c;
                                campaignList[index].UTM_Campaign__c = campaignInstance.UTM_Campaign__c;
                                campaignList[index].UTM_Medium__c = campaignInstance.UTM_Medium__c;
                                campaignList[index].UTM_Term__c = campaignInstance.UTM_Term__c;
                                campaignList[index].UTM_Content__c = campaignInstance.UTM_Content__c;
                                campaignList[index].Cost_Category__c = campaignInstance.Cost_Category__c;
                            }
                            h.showToast(c, e, h, 'Successfully updated marketing campaign.', 'success');

                        }
                        c.set('v.campaignList', campaignList);
                        c.set('v.isEditing', false);

                    } else {
                        h.showToast(c, e, h, 'Error on saving a campaign', 'error');
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
                }
                h.hideSpinner_Helper(c, e);
            });
            $A.enqueueAction(action);
            // } else {
            //     h.showErrorToast(c, e, h, 'Please fill the required fields.');
            // }

        } catch (ex) {
            console.error(`Error----${ex}`);

        }
    },

    enableDeleteModal_helper: function(c, e, h) {
        try {

            let tabIndex = e.getSource().get('v.tabindex');
            let campaignList = c.get('v.campaignList');
            let campaignIdToBeDeleted = c.get('v.campaignIdToBeDeleted');
            campaignIdToBeDeleted = campaignList[tabIndex].Id;
            c.set('v.campaignIdToBeDeleted', campaignIdToBeDeleted);
            c.set('v.openDeleteModal', true);
        } catch (ex) {
            console.error(`Error----${ex}`);
        }
    },

    deleteCampaign_helper: function(c, e, h) {
        try {
            h.showSpinner_Helper(c, e);
            let campaignList = c.get('v.campaignList');
            let campaignIdToBeDeleted = c.get('v.campaignIdToBeDeleted');
            let action = c.get('c.DeleteMarketingCampaign');
            action.setParams({
                'campaignIdToBeDeleted': campaignIdToBeDeleted
            });
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse) {
                        let filtered = campaignList.filter(function(value) {
                            return value.Id !== campaignIdToBeDeleted;
                        });
                        c.set('v.campaignList', filtered);
                        h.showToast(c, e, h, 'Successfully deleted marketing campaign.', 'success');
                        h.hideSpinner_Helper(c, e);
                    } else {
                        h.hideSpinner_Helper(c, e);
                        h.showToast(c, e, h, 'Failed to delete campagin', 'error');
                    }
                    c.set('v.openDeleteModal', false);
                    c.set('v.campaignIdToBeDeleted', '');

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
                }
            });
            $A.enqueueAction(action);
        } catch (ex) {
            console.error(`Error----${ex}`);
        }
    },

    editMarketingCampaign_helper: function(c, e, h) {
        try {

            h.showSpinner_Helper(c, e);
            let tabIndex = e.getSource().get('v.tabindex');
            c.set('v.selectedIndex', tabIndex);

            let campaignList = c.get('v.campaignList');

            let campaignInstance = Object.assign({}, campaignList[tabIndex]);
            let spendPeriodList = c.get('v.spendPeriodList');
            let filteredSpendPeriodList = spendPeriodList && spendPeriodList.length > 0 ? spendPeriodList.filter(spendPeriodElement => spendPeriodElement.Marketing_Campaign__c == campaignInstance.Id) : [];
            c.set('v.campaignInstance', campaignInstance);
            c.set('v.filteredSpendPeriodList', filteredSpendPeriodList);
            c.set('v.isEditing', true);
            h.hideSpinner_Helper(c, e);
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

    showSpinner_Helper: function(c, e) {
        c.set("v.isSpinnerOpen", true);
        window.setTimeout(
            $A.getCallback(function() {
                c.set("v.isSpinnerOpen", false);
            }), 4500
        );
    },

    hideSpinner_Helper: function(c, e) {
        c.set("v.isSpinnerOpen", false);
    },

    reprocessLeads_helper: function(c, e, h) {
        try {
            h.showSpinner_Helper(c, e);
            let toDate = c.get('v.toDate');
            let fromDate = c.get('v.fromDate');
            c.set('v.buttonLabel', 'Running...');
            if (!toDate || !fromDate || toDate <= fromDate) {
                h.hideSpinner_Helper(c, e);
                c.set('v.buttonLabel', 'Reprocess');
                h.showToast(c, e, h, 'Please fill the date time correctly.', 'Error');
                return;
            }
            let processperiod = {};
            processperiod.fromDate = fromDate.toString();
            processperiod.toDate = toDate.toString();
            let campaignList = c.get('v.campaignList');
            let campaignIndex = c.get('v.selectedIndex');

            let action = c.get("c.ReprocessUnprocessedLeads");
            action.setParams({
                'marketingCampaignId': campaignList[campaignIndex].Id,
                'processPeriod': JSON.stringify(processperiod)
            });
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse && storedResponse.message === 'success') {
                        let leadList = storedResponse.leadList;
                        let spendPeriodList = storedResponse.spendPeriodList;
                        let accountList = storedResponse.accountList;

                        let spendIdVsLeadListMap = new Map();
                        spendPeriodList.forEach(element => {
                            let filteredleadList = leadList.filter(leadElement => leadElement.CreatedDate > element.Period_start_time__c && leadElement.CreatedDate < element.Period_end_time__c);

                            spendIdVsLeadListMap.set(element.Id, filteredleadList);

                        });
                        let costLedgerList = [];
                        let leadToupdateList = [];
                        spendIdVsLeadListMap.forEach((value, key, map) => {
                            let leads = [];
                            leads = value;

                            let spendPeriod = spendPeriodList.filter(spElement => spElement.Id == key);
                            if (spendPeriod && leads && spendPeriod.length > 0 && leads.length > 0) {
                                let spendPerLead = spendPeriod[0].Total_spend__c / leads.length;
                                leads.forEach(ele => {
                                    let costLedger = {};
                                    costLedger.Cost_type__c = campaignList[campaignIndex].Cost_Category__c;
                                    costLedger.Amount_of_cost__c = spendPerLead;
                                    costLedger.Lead__c = ele.Id;
                                    costLedger.Time_of_cost__c = ele.CreatedDate;
                                    costLedger.Marketing_campaign__c = campaignList[campaignIndex].Id;
                                    costLedger.Marketing_Spend__c = spendPeriod[0].Id;
                                    if (ele.IsConverted) {
                                        let convertedLeadAccount = accountList && accountList.length > 0 ? accountList.filter(accEle => accEle.Lead__c == ele.Id) : [];
                                        if (convertedLeadAccount && convertedLeadAccount.length > 0 && convertedLeadAccount[0].Id) {
                                            costLedger.Account__c = convertedLeadAccount[0].Id;
                                        }
                                    }

                                    costLedgerList.push(costLedger);
                                    ele.Marketing_campaign__c = campaignList[campaignIndex].Id;
                                    let present = false;
                                    leadToupdateList.forEach(element => {
                                        if (element.Id === ele.Id) {
                                            present = true;
                                        }

                                    });
                                    if (!present) {
                                        leadToupdateList.push(ele);
                                    }

                                });
                            }
                        });
                        try {
                            h.reprocessLeadsCreateledgers_helper(c, e, h, costLedgerList, leadToupdateList);
                        } catch (err1) {
                            console.error(err1);
                        }

                    } else {
                        h.showToast(c, e, h, storedResponse.message, 'Error');
                        c.set('v.fromDate', null);
                        c.set('v.buttonLabel', 'Reprocess');
                        c.set('v.openUnprocessedModal', false);
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
                    h.hideSpinner_Helper(c, e);
                }
            });
            $A.enqueueAction(action);
        } catch (err) {
            console.error(err);
        }
    },

    reprocessLeadsCreateledgers_helper: function(c, e, h, costLedgerList, leadToupdateList) {
        try {
            if (costLedgerList && costLedgerList.length === 0) {
                c.set('v.openUnprocessedModal', false);
                c.set('v.fromDate', null);
                c.set('v.buttonLabel', 'Reprocess');
                h.showToast(c, e, h, 'leads not comes under the spend period or no leads to process for this time period.', 'Error');
                return;
            }
            let action = c.get("c.CreateCostLedgerForUnprocessedLeads");
            action.setParams({
                'costLedgerList': JSON.stringify(costLedgerList),
                'leadToupdateList': JSON.stringify(leadToupdateList)
            });
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse && !storedResponse.includes('wrong')) {
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
                }
                c.set('v.buttonLabel', 'Reprocess');
                c.set('v.fromDate', null);

                c.set('v.openUnprocessedModal', false);
            });
            $A.enqueueAction(action);
        } catch (err) {
            console.error(err);
        }
    },


})