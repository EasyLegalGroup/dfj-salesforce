({
    doInit_helper: function(c, e, h, callingFromDoinit) {
        try {
            h.showSpinner_Helper(c, e);
            let spendPeriodList = c.get('v.spendPeriodList');
            // let totalRecountCount = c.get('v.totalRecountCount');
            let pageSize = c.get('v.pageSize');
            //let endingRecord = c.get('v.endingRecord');

            let totalRecountCount = spendPeriodList && spendPeriodList.length > 0 ? spendPeriodList.length : 0;
            c.set('v.totalRecountCount', totalRecountCount);

            let totalPage = Math.ceil(totalRecountCount / pageSize); //here it is 10
            c.set('v.totalPage', totalPage);
            let pageNumber = totalRecountCount > 0 ? 1 : 0;
            c.set('v.pageNumber', pageNumber);
            let data = spendPeriodList.length > 0 ? spendPeriodList.slice(0, pageSize) : [];
            let endingRecord = totalRecountCount > pageSize ? pageSize : totalRecountCount;
            c.set('v.endingRecord', endingRecord);
            c.set('v.data', data);
            if (callingFromDoinit) {
                c.set('v.originalSpendPeriodList', spendPeriodList);
            }
            h.hideSpinner_Helper(c, e);
        } catch (err) {
            console.error(err);
        }
    },
    editMarketingSpendPeriod: function(c, e, h) {
        try {
            let tabIndex = e.getSource().get('v.tabindex');

            let spendPeriods = c.get('v.data');
            let spendPeriodInstance = Object.assign({}, spendPeriods[tabIndex]);
            c.set('v.spendPeriodInstance', spendPeriodInstance);
            c.set('v.selectedIndex', tabIndex);
            c.set('v.isEditingSpendPeriod', true);
            c.set('v.createSpendPeriod', true);
        } catch (err) {
            console.error(err);
        }
    },
    saveSpendPeriod_helper: function(c, e, h) {
        try {
            h.showSpinner_Helper(c, e);
            let spendPeriodInstance = c.get('v.spendPeriodInstance');

            if (spendPeriodInstance && spendPeriodInstance.Period_start_time__c && spendPeriodInstance.Period_end_time__c && spendPeriodInstance.Total_spend__c && spendPeriodInstance.Period_start_time__c < spendPeriodInstance.Period_end_time__c) {
                let StartDate = new Date(spendPeriodInstance.Period_start_time__c);
                let EndDate = new Date(spendPeriodInstance.Period_end_time__c);
                let differenceInDays = (EndDate.getTime() - StartDate.getTime()) / (1000 * 3600 * 24);
                if (differenceInDays > 35) {
                    h.showToast(c, e, h, 'Interval length is greater than 35 days.', 'Error');
                    h.hideSpinner_Helper(c, e);
                    return;
                }
            } else {
                h.showToast(c, e, h, 'Enter the required fields correctly.', 'Error');
                h.hideSpinner_Helper(c, e);
                return;
            }

            h.checkOverlappingOfInterval_helper(c, e, h);

        } catch (err) {
            console.error(err);
        }
    },
    saveSpendPeriodToList_helper: function(c, e, h) {
        try {
            let spendPeriodInstance = c.get('v.spendPeriodInstance');
            let spendPeriodList = c.get('v.spendPeriodList');
            let isEditingSpendPeriod = c.get('v.isEditingSpendPeriod');
            let spendPeriodToSave = c.get('v.spendPeriodToSave');

            if (spendPeriodInstance) {
                if (!isEditingSpendPeriod) {
                    spendPeriodInstance.Lead_Processed__c = 0;
                    spendPeriodList.unshift(spendPeriodInstance);
                    spendPeriodList.sort((a, b) => (a.Period_start_time__c < b.Period_start_time__c) ? 1 : ((b.Period_start_time__c < a.Period_start_time__c) ? -1 : 0));
                    c.set('v.spendPeriodList', spendPeriodList);
                    spendPeriodToSave.push(spendPeriodInstance);
                    // Pagination
                    h.doInit_helper(c, e, h, false);
                    // pagination end
                } else {
                    // pagination
                    let selectedIndex = c.get('v.selectedIndex');
                    let startingRecord = c.get('v.startingRecord');
                    let endingRecord = c.get('v.endingRecord');
                    let pageSize = c.get('v.pageSize');
                    let data = c.get('v.data');
                    if (data[selectedIndex]) {
                        data[selectedIndex].Total_spend__c = spendPeriodInstance.Total_spend__c;
                        data[selectedIndex].Period_start_time__c = spendPeriodInstance.Period_start_time__c;
                        data[selectedIndex].Period_end_time__c = spendPeriodInstance.Period_end_time__c;
                    }
                    spendPeriodToSave.push(spendPeriodInstance);
                    let spliced = spendPeriodList.splice(startingRecord - 1, endingRecord - (startingRecord - 1), ...data);
                    spendPeriodList.sort((a, b) => (a.Period_start_time__c < b.Period_start_time__c) ? 1 : ((b.Period_start_time__c < a.Period_start_time__c) ? -1 : 0));
                    c.set('v.spendPeriodList', spendPeriodList);

                    h.doInit_helper(c, e, h, false);
                    // pagination
                }

            }
            c.set('v.openModelToSaveSpendPeriod', false);
            c.set('v.isOverlappingSpendPeriod', false);
            c.set('v.startAndEndMatchNotFound', false);
            c.set('v.createSpendPeriod', false);
            c.set('v.isEditingSpendPeriod', false);


            h.hideSpinner_Helper(c, e);
        } catch (err) {
            console.error(err);
        }
    },
    checkOverlappingOfInterval_helper: function(c, e, h) {
        try {
            let overlapListFound = [];
            let spendPeriodInstance = c.get('v.spendPeriodInstance');
            let spendPeriodList = c.get('v.spendPeriodList');
            let isEditingSpendPeriod = c.get('v.isEditingSpendPeriod');
            let selectedIndex = c.get('v.selectedIndex');
            let startingRecord = c.get('v.startingRecord');
            let endingRecord = c.get('v.endingRecord');
            let data = c.get('v.data');

            if (spendPeriodInstance && spendPeriodInstance.Period_start_time__c && spendPeriodInstance.Period_end_time__c) {

                let matchFromSpendPeriodList = [];

                let dataToCmp = [];
                dataToCmp = dataToCmp.concat(data);

                dataToCmp.splice(selectedIndex, 1);
                matchFromSpendPeriodList = matchFromSpendPeriodList.concat(spendPeriodList);
                if (isEditingSpendPeriod) {
                    matchFromSpendPeriodList.splice(startingRecord - 1, endingRecord - (startingRecord - 1), ...dataToCmp);
                }
                // overlapListFound = matchFromSpendPeriodList && matchFromSpendPeriodList.length > 0 ? matchFromSpendPeriodList.filter(SPElement => (spendPeriodInstance.Period_start_time__c < SPElement.Period_end_time__c && spendPeriodInstance.Period_end_time__c >= SPElement.Period_end_time__c) || (spendPeriodInstance.Period_start_time__c == SPElement.Period_start_time__c && spendPeriodInstance.Period_end_time__c == SPElement.Period_end_time__c)) : [];

                overlapListFound = matchFromSpendPeriodList && matchFromSpendPeriodList.length > 0 ? matchFromSpendPeriodList.filter(SPElement => (spendPeriodInstance.Period_start_time__c <= SPElement.Period_start_time__c && SPElement.Period_start_time__c < spendPeriodInstance.Period_end_time__c) || (spendPeriodInstance.Period_start_time__c < SPElement.Period_end_time__c && SPElement.Period_end_time__c <= spendPeriodInstance.Period_end_time__c) || (SPElement.Period_start_time__c < spendPeriodInstance.Period_start_time__c && spendPeriodInstance.Period_end_time__c < SPElement.Period_end_time__c)) : [];

            }
            if (overlapListFound && overlapListFound.length > 0) {
                c.set('v.openModelToSaveSpendPeriod', true);
                c.set('v.isOverlappingSpendPeriod', true);
                c.set('v.createSpendPeriod', false);
                return;
            } else {
                h.checkSpendPeriodDateEqualsAnotherSpendPeriod_helper(c, e, h);
            }
        } catch (err) {
            console.error(err);
        }
    },
    checkSpendPeriodDateEqualsAnotherSpendPeriod_helper: function(c, e, h) {
        try {
            let spendPeriodInstance = c.get('v.spendPeriodInstance');
            let spendPeriodList = c.get('v.spendPeriodList');
            let isEditingSpendPeriod = c.get('v.isEditingSpendPeriod');
            let selectedIndex = c.get('v.selectedIndex');
            let matchFound = [];
            let matchFromSpendPeriodList = [];
            if (spendPeriodInstance && spendPeriodInstance.Period_start_time__c && spendPeriodInstance.Period_end_time__c) {
                matchFromSpendPeriodList = matchFromSpendPeriodList.concat(spendPeriodList);
                if (isEditingSpendPeriod) {
                    let startingRecord = c.get('v.startingRecord');
                    let endingRecord = c.get('v.endingRecord');
                    let data = c.get('v.data');
                    let dataToCmp = [];
                    dataToCmp = dataToCmp.concat(data);

                    dataToCmp.splice(selectedIndex, 1);

                    matchFromSpendPeriodList.splice(startingRecord - 1, endingRecord - (startingRecord - 1), ...dataToCmp);
                }
                matchFound = matchFromSpendPeriodList.filter(SPElement => spendPeriodInstance.Period_start_time__c == SPElement.Period_end_time__c);
            }
            if (matchFromSpendPeriodList && matchFromSpendPeriodList.length > 0 && matchFound && matchFound.length === 0) {
                c.set('v.openModelToSaveSpendPeriod', true);
                c.set('v.startAndEndMatchNotFound', true);
                c.set('v.createSpendPeriod', false);

                return;
            } else if ((matchFromSpendPeriodList && matchFromSpendPeriodList.length === 0) || (matchFound && matchFound.length > 0)) {
                h.saveSpendPeriodToList_helper(c, e, h);
            }
        } catch (err) {
            console.error(err);
        }
    },

    saveCampaignsAndSpendPeriods_helper: function(c, e, h) {
        try {
            h.showSpinner_Helper(c, e);
            let spendPeriodToSave = c.get('v.spendPeriodToSave');
            let spendPeriodList = c.get('v.spendPeriodList');
            spendPeriodToSave = spendPeriodToSave.length > 0 ? spendPeriodList : [];
            let spendPeriodToDelete = c.get('v.spendPeriodToDelete');
            let campaignInstanceToSave = c.get('v.campaignInstance');
            if (campaignInstanceToSave && (!campaignInstanceToSave.Name || campaignInstanceToSave.Name.trim() === '' || !campaignInstanceToSave.Cost_Category__c)) {
                h.showToast(c, e, h, 'Name and cost category should not be empty.', 'Error');
                h.hideSpinner_Helper(c, e);
                return;
            }
            let action = c.get('c.UpdateCampaignWithUpdatedPeriods');
            action.setParams({
                'campaignInstanceToSave': JSON.stringify(campaignInstanceToSave),
                'spendPeriodToSave': JSON.stringify(spendPeriodToSave),
                'spendPeriodToDelete': JSON.stringify(spendPeriodToDelete),
            });
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse && storedResponse.marketingCampaignList && storedResponse.marketingCampaignList.length > 0) {
                        h.showToast(c, e, h, 'Successfully saved.', 'Success');
                        c.set('v.isEditing', false);
                        h.hideSpinner_Helper(c, e);
                        $A.get('e.force:refreshView').fire();
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

    deleteSpendPeriodFromUI_helper: function(c, e, h) {
        try {
            h.showSpinner_Helper(c, e);
            let selectedIndex = c.get('v.selectedIndex');
            // pagination -> data
            let spendPeriodList = c.get('v.data');
            let spendPeriodToDelete = c.get('v.spendPeriodToDelete');
            if (spendPeriodList && spendPeriodList.length > 0) {
                if (spendPeriodList[selectedIndex] && !spendPeriodList[selectedIndex].Id) {
                    let deleted = spendPeriodList.splice(selectedIndex, 1);
                } else {
                    spendPeriodToDelete.push(spendPeriodList[selectedIndex]);
                    let deleted = spendPeriodList.splice(selectedIndex, 1);

                }
                c.set('v.spendPeriodToDelete', spendPeriodToDelete);
                // pagination
                let startingRecord = c.get('v.startingRecord');
                let endingRecord = c.get('v.endingRecord');
                let data = c.get('v.spendPeriodList');

                let spliced = data.splice(startingRecord - 1, endingRecord - (startingRecord - 1), ...spendPeriodList);

                c.set('v.spendPeriodList', data);

                h.doInit_helper(c, e, h, false);
                // pagination

            }
            h.hideSpinner_Helper(c, e);
            c.set('v.openDeleteConfirmationModel', false);

        } catch (err) {
            console.error(err);
        }
    },
    runProcessScript_helper: function(c, e, h, page) {
        try {
            h.showSpinner_Helper(c, e);

            c.set('v.runProcessscriptLable', 'Running...');
            c.set('v.disableButton', true);

            let selectedIndex = c.get('v.selectedIndex');
            let spendPeriodList = c.get('v.spendPeriodList');

            let action = c.get("c.CalculateSpendPerLead");
            action.setParams({
                spendPeriodId: spendPeriodList[selectedIndex].Id
            });
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    let storedResponse = response.getReturnValue();
                    if (storedResponse.includes("leads processed")) {
                        h.showToast(c, e, h, storedResponse.toString(), 'Success');
                        $A.get('e.force:refreshView').fire();
                    } else {
                        h.showToast(c, e, h, storedResponse, 'Error');
                        if (storedResponse.includes('lead records not found for this spend period.')) {
                            $A.get('e.force:refreshView').fire();
                        }

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
                c.set('v.openScriptProcessModel', false);
                h.hideSpinner_Helper(c, e);

            });
            $A.enqueueAction(action);
        } catch (err) {
            console.error(err);
        }
    },
    displayRecordPerPage: function(c, e, h, page) {
        try {
            let pageSize = c.get('v.pageSize');
            let totalRecountCount = c.get('v.totalRecountCount');
            let spendPeriodList = c.get('v.spendPeriodList');

            let startingRecord = ((page - 1) * pageSize);
            let endingRecord = (pageSize * page);

            endingRecord = (endingRecord > totalRecountCount) ? totalRecountCount : endingRecord;

            let data = spendPeriodList.slice(startingRecord, endingRecord);
            c.set('v.data', data);
            startingRecord = startingRecord + 1;
            c.set('v.endingRecord', endingRecord);

            c.set('v.startingRecord', startingRecord);

        } catch (err) {
            console.error(err);
        }
    },

    showToast: function(c, e, h, message, title) {
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
})