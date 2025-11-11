/**
 * Created by shubh on 17-07-2019.
 */
({
    invoke : function(component, event, helper) {
        try {
            console.log("AccountId"+component.get("v.accountId"));
            // Get the record ID attribute
            var accountId = component.get("v.accountId");
            let sObjectEvent = $A.get("e.force:navigateToSObject");
            sObjectEvent.setParams({
                "recordId": accountId,
                "slideDevName": "detail"
            });
            sObjectEvent.fire();
        } catch (ex) {
            console.log('Error in send the data'+ex)
        }
    }

})