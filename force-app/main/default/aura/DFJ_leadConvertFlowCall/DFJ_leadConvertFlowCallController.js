/**
 * Created by shubh on 18-07-2019.
 */
({

    init: function(c, e, h) {
        h.init_helper(c, e, h);
        h.getPicklistValues_helper(c, e, h);
    },

    openConversion: function(c, e, h) {
        c.set("v.isConversionWindowOpen", !c.get("v.isConversionWindowOpen"));
        // Find the component whose aura:id is "flowData"
        var flow = c.find("flowData");
        var inputVariables = [
            { name: "LEADID", type: "String", value: c.get("v.recordId") },
            // Changes for ticket : DIN-167 Subscription feature
            // Start  
            //Changes DIN-377
            // { name: "isMember", type: "Boolean", value: c.get("v.isMember") },
            // End
            { name: "paymentMethodVar", type: "String", value: c.get("v.paymentMethod") },
            { name: "paymentTypeVar", type: "String", value: c.get("v.paymentType") },
            { name: "Paymentordernumber", type: "String", value: c.get("v.PaymentOrderNumber") }
        ];

        // In that component, start your flow. Reference the flow's Unique Name.
        flow.startFlow("Lead_Convert_Process", inputVariables);
    },

})