({
	doInit_Helper : function (c,e,h) {
        //console.log(c.get("v.DurationRange"));
        try {
            h.showSpinner_Helper(c,e);
            if(c.get("v.DurationRange") != 'Custom Range'){
                c.set("v.customRange",false);
                let action = c.get("c.fetchReportData_Apex");
                action.setParams({'DurationRange':c.get("v.DurationRange")});
                action.setCallback(this, function (r) {
                    if (r.getState() === 'SUCCESS') {
                        let storedResponse = r.getReturnValue();
                        console.log(JSON.stringify(storedResponse));
                        if (storedResponse !== null && storedResponse !== undefined && storedResponse !== ''){
                            storedResponse.forEach(function (ele) {
                                ele.TalkTime = h.createDurationString(ele.TalkTime);
                                ele.EffectiveTalkTime = h.createDurationString(ele.EffectiveTalkTime);
                                if (ele.Converted === 0 || ele.Reject === 0){
                                    ele.Hitrate = 0;
                                } else {
                                    ele.Hitrate = (parseFloat((parseInt(ele.Converted) / (parseInt(ele.Reject) + parseInt(ele.Converted))))*100).toFixed(2);
                                }
                                if (ele.Converted === 0 || ele.salesValue === 0){
                                    ele.AVGSales = 0;
                                } else {
                                    ele.AVGSales = parseFloat(parseInt(ele.salesValue) / parseInt(ele.Converted)).toFixed(2);
                                }

                            });
                            c.set("v.reportData",storedResponse);
                            c.set("v.StartDate",null);
                            c.set("v.EndDate",null);
                        }
                        h.hideSpinner_Helper(c,e);
                    } else {
                        console.log('ERROR');
                        console.log(r.getError());
                        h.hideSpinner_Helper(c,e);
                    }
                });
                $A.enqueueAction(action);
            }else{
                c.set("v.customRange",true);
                h.hideSpinner_Helper(c,e);
            }
        } catch (e) {
            console.log('Error in fetching the user ---' + e);
            h.hideSpinner_Helper(c,e);
        }
    },

    showSpinner_Helper: function (c, e) {
        c.set("v.isSpinnerOpen",true);
        window.setTimeout(
            $A.getCallback(function () {
                c.set("v.isSpinnerOpen",false);
            }), 2500
        );
    },
    hideSpinner_Helper: function (c, e) {
        c.set("v.isSpinnerOpen",false);
    },

    ApplyCustomRange_Helper: function (c, e, h){
        try{

            let StartDate = c.get("v.StartDate");
            let EndDate = c.get("v.EndDate");
            console.log('EndDate:: '+EndDate);
            console.log('StartDate:: '+StartDate);
            if(StartDate <= EndDate && !$A.util.isUndefinedOrNull(StartDate) && !$A.util.isUndefinedOrNull(EndDate)){
                h.showSpinner_Helper(c,e);
                let action = c.get("c.fetchReportData_Apex");
                action.setParams({'StartDate':StartDate , 'EndDate' : EndDate});
                action.setCallback(this, function (r) {
                    if (r.getState() === 'SUCCESS') {
                        let storedResponse = r.getReturnValue();
                        console.log(JSON.stringify(storedResponse));
                        if (storedResponse !== null && storedResponse !== undefined && storedResponse !== ''){
                            storedResponse.forEach(function (ele) {
                                ele.TalkTime = h.createDurationString(ele.TalkTime);
                                ele.EffectiveTalkTime = h.createDurationString(ele.EffectiveTalkTime);
                                if (ele.Converted === 0 || ele.Reject === 0){
                                    ele.Hitrate = 0;
                                } else {
                                    ele.Hitrate = (parseFloat((parseInt(ele.Converted) / (parseInt(ele.Reject) + parseInt(ele.Converted))))*100).toFixed(2);
                                }
                                if (ele.Converted === 0 || ele.salesValue === 0){
                                    ele.AVGSales = 0;
                                } else {
                                    ele.AVGSales = parseFloat(parseInt(ele.salesValue) / parseInt(ele.Converted)).toFixed(2);
                                }

                            });
                            c.set("v.reportData",storedResponse);
                        }
                        h.hideSpinner_Helper(c,e);
                    } else {
                        console.log('ERROR :: '+r.getState());
                        console.log(r.getError());
                        h.hideSpinner_Helper(c,e);
                    }
                });
                $A.enqueueAction(action);
            }else if($A.util.isUndefinedOrNull(StartDate)){
                c.find("StartDate").focus();
                //input.focus();
                let toastEvent = $A.get("e.force:showToast"); // Fire the toast if the Email is successfully sent.
                toastEvent.setParams({
                    title : "Error",
                    message : "StartDate can not be empty",
                    duration :' 1500',
                    key: 'info_alt',
                    type: 'Error',
                    mode: 'pester'
                });
                toastEvent.fire();
            }else if ( $A.util.isUndefinedOrNull(EndDate)){
                c.find("EndDate").focus();
                /*let input = c.find("EndDate").getElement();
                input.focus();*/
                let toastEvent = $A.get("e.force:showToast"); // Fire the toast if the Email is successfully sent.
                toastEvent.setParams({
                    title : "Error",
                    message : "EndDate can not be empty",
                    duration :' 1500',
                    key: 'info_alt',
                    type: 'Error',
                    mode: 'pester'
                });
                toastEvent.fire();
            }else if(StartDate > EndDate){
                c.find("EndDate").focus();
                /*let input = c.find("EndDate").getElement();
                input.focus();*/
                let toastEvent = $A.get("e.force:showToast"); // Fire the toast if the Email is successfully sent.
                    toastEvent.setParams({
                    title : "Error",
                    message : "End date should be greater then or equal to start date",
                    duration :' 1500',
                    key: 'info_alt',
                    type: 'Error',
                    mode: 'pester'
                });
                toastEvent.fire();
            }
        }catch (ex) {
            console.log('Error in fetching the user ---' + ex);
            h.hideSpinner_Helper(c,e);
        }
    },

    createDurationString : function(milliSeconds) {
        const seconds = Math.floor(milliSeconds / 1000);

        let s = '';
        // Not so DRY but without momentjs dependency

        // Days
        if (seconds / 86400 >= 1) {
            s = s + Math.floor(seconds / 86400) + 'd ';
        }
        // Hour
        if (seconds / 3600 >= 1) {
            s = s + Math.floor(seconds / 3600) % 24 + 'h ';
        }

        // Seconds
        if (seconds >= 0) {
            s = s + ("00" + Math.floor(seconds / 60) % 60).slice(-2) + ':';
            s = s + ("00" + (seconds % 60)).slice(-2);
        } else {
            s = '00:00';
        }

        return s;

    },
})