/**
 * Created by Shubham Sharma on 12-07-2019.
 */
({

    doInit : function (c,e,h) {
        h.doInit_Helper(c,e,h);
    },
    /*Controller for the 'Add Product' button on the tab containing the table of lead products*/
    addProductModal : function (c,e,h) {
        let LeadProducts = c.get("v.LeadProducts");
        c.set("v.isAddProductModalOpen",!c.get("v.isAddProductModalOpen"));
        if(LeadProducts.length === 0){
            c.set("v.currentProductList",[]);
        }
    },

    addProductToList : function (c,e,h) {
        let fullProductData = c.get("v.fullProductData");
        let currentPricebook = c.get("v.CurrentPricebook");
        fullProductData.forEach(function (ele) {
            if (c.get("v.CurrentPricebook") === ele.pb2.Id){
                c.set("v.currentProductList",ele.pbeList);
            }else if(c.get("v.CurrentPricebook") === ''){
                c.set("v.currentProductList",[]);
            }
        });
    },

    increaseDecreaseButton :function (c,e,h) {
        h.increaseDecreaseButton_helper(c,e,h);
    },

    editButtonClicked: function (c, e, h) {
        h.editButtonClicked_helper(c, e, h);
    },

    /*Controller for the button on the model which inserts the products in the lead products*/
    addProductsToLeadProducts : function (c,e,h) {
        //h.addProductsToLeadProducts_helper(c,e,h);
        c.set("v.isAddProductModalOpen",false);
        h.addProductNew_Helper(c,e,h);
    },

    changeQuantity: function (c, e, h) {
        h.changeQuantity_helper(c, e, h);
    },

    deleteRecord: function (c, e, h) {
        let selectedIndex = e.getSource().get("v.tabindex");
        c.set("v.deleteTabIndex",selectedIndex);
        c.set("v.isDeleteConfirmationModalOpen",!c.get("v.isDeleteConfirmationModalOpen"));
    },

    closeDeleteModal : function (c,e,h) {
        c.set("v.isDeleteConfirmationModalOpen",false);
    },

    deleteRecordWhenButtonClicked : function(c,e,h){
        c.set("v.isDeleteConfirmationModalOpen",false);
        h.deleteRecordWhenButtonClicked_helper(c,e,h);
    },

    changeIntValue : function (c,e,h) {
        h.changeIntValue_Helper(c,e,h);
    },

})