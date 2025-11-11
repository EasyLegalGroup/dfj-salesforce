({
    doInit_Helper: function(c, e, h) {
        //console.log(c.get("v.DurationRange"));
        try {
            console.log(c.get("v.DurationRange"));

            if (c.get("v.DurationRange") != "" && c.get("v.DurationRange") != "none") {

                if (c.get("v.DurationRange") != 'Custom Range') {
                    h.showSpinner_Helper(c, e);
                    c.set("v.customRange", false);
                    console.log(c.get("v.DurationRange"));
                    let action = c.get("c.DFJ_UpdateDuplicateLead");
                    action.setParams({
                        'DurationRange': c.get("v.DurationRange")
                    });
                    action.setCallback(this, function(r) {
                        if (r.getState() === 'SUCCESS') {
                            let storedResponse = r.getReturnValue();
                            console.log(JSON.stringify(storedResponse));
                            if (storedResponse !== null && storedResponse !== undefined && storedResponse !== '' && storedResponse != 0) {

                                c.set("v.StartDate", null);
                                c.set("v.EndDate", null);
                                let toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    title: "SUCCESS",
                                    message: storedResponse + " records are updated",
                                    duration: '1500',
                                    key: 'info_alt',
                                    type: 'SUCCESS',
                                    mode: 'pester'
                                });
                                toastEvent.fire();
                            } else {
                                c.set("v.StartDate", null);
                                c.set("v.EndDate", null);
                                let toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    title: "SUCCESS",
                                    message: "There is no record to update",
                                    duration: '1500',
                                    key: 'info_alt',
                                    type: 'SUCCESS',
                                    mode: 'pester'
                                });
                                toastEvent.fire();
                            }

                            h.hideSpinner_Helper(c, e);
                        } else {
                            console.log('ERROR');
                            console.log(r.getError());
                            h.hideSpinner_Helper(c, e);
                        }
                    });
                    $A.enqueueAction(action);

                } else if (c.get("v.DurationRange") == 'Custom Range' && c.get("v.customRange") == true) {

                    let StartDate = c.get("v.StartDate");
                    let EndDate = c.get("v.EndDate");
                    console.log('EndDate:: ' + EndDate);
                    console.log('StartDate:: ' + StartDate);
                    if (StartDate <= EndDate && !$A.util.isUndefinedOrNull(StartDate) && !$A.util.isUndefinedOrNull(EndDate)) {

                        h.showSpinner_Helper(c, e);
                        let action = c.get("c.DFJ_UpdateDuplicateLead");
                        action.setParams({
                            'StartDate': StartDate,
                            'EndDate': EndDate
                        });
                        action.setCallback(this, function(r) {
                            if (r.getState() === 'SUCCESS') {
                                let storedResponse = r.getReturnValue();
                                console.log(JSON.stringify(storedResponse));
                                if (storedResponse !== null && storedResponse !== undefined && storedResponse !== '' && storedResponse != 0) {
                                    c.set("v.StartDate", null);
                                    c.set("v.EndDate", null);
                                    let toastEvent = $A.get("e.force:showToast");
                                    toastEvent.setParams({
                                        title: "SUCCESS",
                                        message: storedResponse + " records are updated",
                                        duration: ' 1500',
                                        key: 'info_alt',
                                        type: 'SUCCESS',
                                        mode: 'pester'
                                    });
                                    toastEvent.fire();
                                } else {
                                    c.set("v.StartDate", null);
                                    c.set("v.EndDate", null);
                                    let toastEvent = $A.get("e.force:showToast");
                                    toastEvent.setParams({
                                        title: "SUCCESS",
                                        message: "There is no record to update",
                                        duration: '1500',
                                        key: 'info_alt',
                                        type: 'SUCCESS',
                                        mode: 'pester'
                                    });
                                    toastEvent.fire();
                                }
                                h.hideSpinner_Helper(c, e);
                            } else {
                                console.log('ERROR :: ' + r.getState());
                                console.log(r.getError());
                                h.hideSpinner_Helper(c, e);
                            }
                        });
                        $A.enqueueAction(action);
                    } else if ($A.util.isUndefinedOrNull(StartDate)) {
                        c.find("StartDate").focus();
                        //input.focus();
                        let toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: "Error",
                            message: "StartDate can not be empty",
                            duration: '1500',
                            key: 'info_alt',
                            type: 'Error',
                            mode: 'pester'
                        });
                        toastEvent.fire();
                    } else if ($A.util.isUndefinedOrNull(EndDate)) {
                        c.find("EndDate").focus();
                        /*let input = c.find("EndDate").getElement();
                        input.focus();*/
                        let toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: "Error",
                            message: "EndDate can not be empty",
                            duration: '1500',
                            key: 'info_alt',
                            type: 'Error',
                            mode: 'pester'
                        });
                        toastEvent.fire();
                    } else if (StartDate > EndDate) {
                        c.find("EndDate").focus();
                        /*let input = c.find("EndDate").getElement();
                        input.focus();*/
                        let toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: "Error",
                            message: "End date should be greater then or equal to start date",
                            duration: '1500',
                            key: 'info_alt',
                            type: 'Error',
                            mode: 'pester'
                        });
                        toastEvent.fire();
                    }
                } else {
                    c.set("v.customRange", true);
                    h.hideSpinner_Helper(c, e);
                }
            }
        } catch (e) {
            console.log('Error in fetching the user ---' + e);
            h.hideSpinner_Helper(c, e);
        }
    },
    onChange_Helper:function (c, e, h) {
        try{
            if (c.get("v.DurationRange") != "" && c.get("v.DurationRange") != "none") {
                c.set("v.IsApplyDisabled",false);
                if (c.get("v.DurationRange") != 'Custom Range') {
                    c.set("v.customRange", false);
                }else{
                    c.set("v.customRange", true);
                }
            }else{
                c.set("v.IsApplyDisabled",true);
                c.set("v.customRange", false);
            }
        }catch(ex){
            console.log('Error :: '+ex);
        }
    },
    showSpinner_Helper: function(c, e) {
        c.set("v.isSpinnerOpen", true);
        window.setTimeout(
            $A.getCallback(function() {
                c.set("v.isSpinnerOpen", false);
            }), 2500
        );
    },
    hideSpinner_Helper: function(c, e) {
        c.set("v.isSpinnerOpen", false);
    },

})