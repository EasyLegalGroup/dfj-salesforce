import {api, LightningElement, track, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getAllThePricebooksAndOpportunityProducts_Apex
    from '@salesforce/apex/DFJ_ProductSelectorForOpportunity_Apex.getAllThePricebooksAndOpportunityProducts_Apex';
import updateRecords_Apex from '@salesforce/apex/DFJ_ProductSelectorForOpportunity_Apex.updateRecords_Apex';
import deleteRecords_Apex from '@salesforce/apex/DFJ_ProductSelectorForOpportunity_Apex.deleteRecords_Apex';
import insertRecords_Apex from '@salesforce/apex/DFJ_ProductSelectorForOpportunity_Apex.insertRecords_Apex';
import updateOpportunity from '@salesforce/apex/DFJ_ProductSelectorForOpportunity_Apex.updateOpportunity';
import getOrderCategorySize from '@salesforce/apex/DFJ_ProductSelectorForOpportunity_Apex.getOrderCategorySize';
import { createMessageContext, releaseMessageContext, publish,subscribe, MessageContext } from 'lightning/messageService';
import Payment_Message_Channel from '@salesforce/messageChannel/PaymentEnableMessage__c';


import Update_Availability_Status_Of_Payment_Record
    from '@salesforce/messageChannel/Update_Availability_Status_Of_Payment_Record__c';

export default class Dfj_ProductSelectorForOpportunity extends LightningElement {
    @api recordId;

    @track priceBooks = []; //PriceBook2
    @track oppProducts = [];
    @track fullProductData = [];
    @track currentProductList = [];
    @track isAddProductModalOpen = false;
    @track isDeleteConfirmationModalOpen = false;
    @track currentPriceBook;
    @track deleteTabIndex;
    @track editTabIndex;
    @track selectedPriceBookName;
    @track total = 0.00;
    @track totalValues = {};
    @track isoCode;
    @track orderTotal = 0;
    @track isEditModalOpen = false;
    @track editProducts = [];
    @track passEditButtonVariable;
    @track discountValue;
    @track leadRecord = {};
    @track isProductEmpty = false;
    @track isleadProductComboboxdisplay = true;
    @track isShowOrderTotal = false;
    @track disableButton = true;
    @track isLoadedSpinner = false;
    @track leadProducts1 = [];
    @track callProductBundleFlow = false;//DFJ-347
    @track includeBundleDiscount = false;//DFJ-347
    @api disablePaymentButton;//DFJ-347
    addedDiscount = 0;
    potentialValueOfAddedDiscount;


    @wire(MessageContext) messageContext;

    subscription = null;
    paymentAvailableInPaymentComponent;

    connectedCallback() {
        this.getProductsData();
        this.subscribeToMessageChannel();
        this.getOrderCategorySize(); //DFJ-347
    }
//DFJ-347 changes start
    get disablePaymentButtonDetailsToPublish(){
        return {
            disablePaymentButton: this.disablePaymentButton
           };
    }

     get flowInputVariables() {
         return [ {
            name: "recordId",
            type: "String",
            value: this.recordId
         } ];
    }
//DFJ-347 changes end

    // return true if payment record is available
    get isPaymentRecordAvailable() {
        if (this.paymentAvailableInPaymentComponent) {
            return true;
        }
        return false;
    }

    // get subtotal value of selected products
    get subTotalValue() {
        let result = 0.00;
        for (let oppProduct of this.oppProducts) {
            result = result + parseFloat(oppProduct.Net_Total_Price__c)
        }

        return result;
    }

    // get order total value after adding discount
    get orderTotalValue() {

        if (this.addedDiscount >= 0) {
            return this.subTotalValue - this.addedDiscount;
        }
        return this.subTotalValue;
    }

    // get min value for fixed discount input
    get minValueForFixedDiscountInput() {
        return 0;
    }

    // get max value for fixed discount input
    get maxValueForFixedDiscountInput() {
        let val = this.subTotalValue;
        if (val) {
            return val;
        }
        return 0;
    }

    // used to handle enabling or disabling the apply button
    get isApplyButtonForAddDiscountDisable() {
        if (this.potentialValueOfAddedDiscount) {
            return false;
        }
        return true;
    }

   

    // subscribe to message channel to get payment record availability status
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                Update_Availability_Status_Of_Payment_Record,
                (message) => this.handleMessageFromPaymentComponent(message)
            );
        }
    }

    // handle received message from payment component
    handleMessageFromPaymentComponent(message) {
        try {
            if (message) {

                if (message.isPaymentRecordAvailableInPaymentComponent) {
                    this.paymentAvailableInPaymentComponent = true;
                } else {
                    this.paymentAvailableInPaymentComponent = false;
                }

                this.getProductsData();
            }
        } catch (e) {
            console.log("🚀️ Error in ~ Dfj_ProductSelectorForOpportunity ~ handleMessageFromPaymentComponent() :", JSON.stringify(e.message));
        }
    }

    // update order total in opportunity
    async updateOrderTotalInOpportunity() {
        try {

            if (this.orderTotalValue >= 0) {
                let idOpp = this.recordId;
                let Order_Total__c = this.orderTotalValue;
                let fixedDiscountAmount = this.addedDiscount;

                updateOpportunity({opportunityId:idOpp,orderTotal:Order_Total__c,fixedDiscount:fixedDiscountAmount}).then().catch(e=>{
                    console.log("🚀️ Error in ~ Dfj_ProductSelectorForOpportunity ~ updateOrderTotalInOpportunity() ~ updateOpportunity :", JSON.stringify(e.message));
                });
            }
           // await this.getProductsData();

        } catch (e) {
            console.log("🚀️ Error in ~ Dfj_ProductSelectorForOpportunity ~ updateOrderTotalInOpportunity() :", JSON.stringify(e.message));
        }
    }


    // get products data
    async getProductsData() {
        await getAllThePricebooksAndOpportunityProducts_Apex({recordId: this.recordId}).then(result => {
            try {
                if (result) {
                    let priceBooks = [];
                    result.productData.forEach(element => {
                        element.pbeList.forEach(elein => {
                            elein.quantity = 0;
                        })
                        priceBooks.push(element.pb2);
                    })

                    this.priceBooks = priceBooks;
                    this.fullProductData = result.productData;

                    this.oppProducts = result.opportunityProductsData;
                    this.refreshOpportunityProducts();//DFJ-347
                                                
                    this.isoCode = result.DefaultCurrencyIsoCode;
                    if (result.opportunityProductsData && result.opportunityProductsData.length <= 0) {
                        this.disableButton = true;
                    }

                    let priceBookId = '';
                    if (result.opportunityProductsData && result.opportunityProductsData.length > 0) {
                        this.disableButton = false;
                        this.isProductEmpty = true;
                        this.isShowOrderTotal = true;
                        priceBookId = result.opportunityProductsData[0].Pricebook_Id__c;
                        let fullProductData = this.fullProductData;

                        fullProductData.forEach(ele => {
                            if (priceBookId === ele.pb2.Id) {
                                this.currentProductList = ele.pbeList;
                                this.selectedPriceBookName = ele.pb2.Name;
                            }
                        });


                        this.currentProductList = result.opportunityProductsData;

                        this.handlerChangeQuantity();
                    } else {
                        this.isProductEmpty = false;
                    }
                    //Chnages Start DFJ-43
                    let fullProductData = [...this.fullProductData];
                    fullProductData.forEach(element => {
                        if (result.currencyAccordingMarketUnit === element.pb2.CurrencyIsoCode) {
                            this.currentProductList = element.pbeList;
                            this.selectedPriceBookName = element.pb2.Name;
                        }
                    })



                    this.updateOrderTotalInOpportunity();
                }

            } catch (error) {
                console.error(error.stack);
            }

        })


    }

    /**Used method for Open Modal popUp on Pencil Icon and Edit Fields(Amount , Discount) */

    editButtonClicked(event) {
        let oppProduct = this.oppProducts;
        this.isEditModalOpen = true;
        let selectedIndex = event.target.dataset.index;
        this.editTabIndex = selectedIndex;
        oppProduct[selectedIndex];
        this.editProducts = oppProduct[selectedIndex];

    }

    // used to handle change in quantity
    handlerDiscountValueChange(event) {
        let totalPrice = 0.00;
        try {
            if (event.target.name === 'quantity') {
                this.editProducts.Quantity = !event.target.value ? 0 : event.target.value;
                this.editProducts.Quantity = parseInt(this.editProducts.Quantity);
                if (event.target.value <= 0) {
                    this.editProducts.Quantity = 1;
                    event.target.value = 0;
                } else if (event.target.value >= 999) {
                    this.editProducts.Quantity = 999;
                    event.target.value = 999;
                }
            } else {
                this.editProducts.Discount = !event.target.value ? 0 : event.target.value;
            }

            if (!this.editProducts.Discount || Number.isNaN(this.editProducts.Discount) || this.editProducts.Discount < 0) {
                this.editProducts.Discount = 0;
            } else if (this.editProducts.Discount >= 100) {
                this.editProducts.Discount = 100;
            }

            let discountedValue = parseFloat((this.editProducts.Discount / 100) * (this.editProducts.ListPrice)).toFixed(2);
            this.editProducts.TotalPrice = parseFloat((parseFloat(this.editProducts.ListPrice).toFixed(2) - parseFloat(discountedValue).toFixed(2)) * this.editProducts.Quantity).toFixed(2);
            totalPrice = parseFloat(totalPrice) + parseFloat(this.editProducts.TotalPrice);
            // this.editProducts.TotalPrice = totalPrice.toFixed(2);


        } catch (error) {
            console.error(error);
        }

    }

    //Used for save the value of discount on click of save button of the edit modal Pop
    async saveButtonClicked() {
        try {

            let listPrice = this.editProducts.ListPrice;

            let changedDiscount = JSON.parse(JSON.stringify(this.editProducts)); // make a deep clone of this.editProducts

            changedDiscount.UnitPrice = listPrice;

            delete changedDiscount.TotalPrice; // As we Cannot change both 'UnitPrice' and 'TotalPrice' in update call, so deleting changedDiscount.TotalPrice

            changedDiscount.Discount = parseFloat(changedDiscount.Discount);
            updateRecords_Apex({changedDiscount: changedDiscount}).then(result => {

                this.isEditModalOpen = false;
                this.handlerChangeQuantity();
                this.handlerFixedDiscountChange();
                this.showSuccessToast();
            })
                .catch((error) => {
                    console.log("some error in code:", JSON.stringify(error));
                });
            eval("$A.get('e.force:refreshView').fire()");

            this.oppProducts.forEach(element => {
                if (element.Id === changedDiscount.Id) {
                    element = changedDiscount;
                }
            });
            this.oppProducts = [...this.oppProducts];

            this.handleRecalculationOfOrderInformation();
        } catch (e) {
            console.log("🚀️ Error in ~ Dfj_ProductSelectorForOpportunity ~ saveButtonClicked() :", JSON.stringify(e.message));
        }

    }

    // handler recalculation of order information
    async handleRecalculationOfOrderInformation() {

        this.resetAddedDiscountValueValue();

        // wait for order total calculation and then proceed to update opportunity total in database
        await this.handleOrderTotalCalculation();
         this.updateOrderTotalInOpportunity();
         

    }

    // reset added discount value
    resetAddedDiscountValueValue() {
        this.potentialValueOfAddedDiscount = null;
    }

    /**Used for Delete Record when Click on Delete Action Icon Button */
    deleteRecord(event) {
        let index = event.target.dataset.index;
        this.deleteTabIndex = index;
        this.isDeleteConfirmationModalOpen = true;

    }
    // handler to delete record when button clicked
   async deleteRecordWhenButtonClicked(event) {
        try {
            this.handlerChangeQuantity();
            await this.getProductsData();//DFJ-347
            let productList = this.oppProducts;
            this.isDeleteConfirmationModalOpen = false;
            let tabindex = this.deleteTabIndex;
            let productId = productList[tabindex].Id;

          await  deleteRecords_Apex({productId: productId, recId: this.recordId}).then(result => {
                if (result) {
                    this.oppProducts = result;
                    this.handlerChangeQuantity();
                    this.currentPriceBook = '';
                    if (productList.length === 0) {
                        this.currentProductList = [];
                    }
                    this.handlerFixedDiscountChange();
                    this.showSuccessToast();
                }
                
                if (this.oppProducts.length === 0) {
                    this.handlerRefershView();
                }

            })
            
            // recalculate Order Information
            this.handleRecalculationOfOrderInformation();
            //DFJ-347 changes start
            this.disablePaymentButton = true; 
            
          publish(this.messageContext, Payment_Message_Channel, this.disablePaymentButtonDetailsToPublish);
          //DFJ-347 changes end
            this.getProductsData();
            eval("$A.get('e.force:refreshView').fire()"); // this will only refresh the standard UI Components, not custom LWC Components
        } catch (error) {
            console.error(error);
        }

    }

    /**Used for close Modal Pop Click on Pencil Icon Button */
    closeModal(event) {
        try {
            this.isEditModalOpen = false;
            if (event.target.name == 'cancelDiscount') {
                this.getProductsData();
            }
            this.isDeleteConfirmationModalOpen = false;
            this.isAddProductModalOpen = false;
        } catch (error) {
            console.error(error);
        }

    }

    /**Used for Open Modal POP up on Click on Add Payment button */
    addProductModal() {

        try {
            this.isAddProductModalOpen = true;

        } catch (e) {
            console.log("🚀️ Error in ~ Dfj_ProductSelectorForOpportunity ~ addProductModal() :", JSON.stringify(e.message));
        }
    }



    addProducts() {
        try {

            let productsList = this.currentProductList;


            this.isAddProductModalOpen = false;
            this.isLoadedSpinner = true;


            let oppProducts = [...this.oppProducts];


            let oppProductIdList = [];

            if (oppProducts && oppProducts.length > 0) {
                oppProducts.forEach(ele => {
                    oppProductIdList.push(ele.Product2Id);
                });
            }


            let oppIdToAssociateProductsWith = this.recordId;

            if (oppProducts && oppProducts.length === 0) {


                productsList.forEach(ele => {
                    if ((parseInt(ele.quantity) > 0)) {


                        let productInstance = {};

                        productInstance.OpportunityId = oppIdToAssociateProductsWith;
                        productInstance.PricebookEntryId = ele.Id;
                        productInstance.Quantity = ele.quantity;

                        // Product2
                        productInstance.Product2 = ele.Product2

                        // make UnitPrice, ListPrice of OppLineItem equals UnitPrice of priceBookEntry
                        productInstance.UnitPrice = ele.UnitPrice;
                        productInstance.ListPrice = ele.UnitPrice;

                        productInstance.Discount = 0;
                        productInstance.Pricebook_Id__c = ele.Pricebook2Id;
                        productInstance.PricebookEntry_Id__c = ele.Id;
                        productInstance.Name = ele.Name;
                        productInstance.Partner_Provision_Value__c = ele.Partner_provision_value__c;
                        productInstance.Partner_Sales_Value__c = ele.Partner_sales_value__c;
                        productInstance.Provision_Base__c = ele.Provision_base__c;
                        productInstance.Quantity = ele.quantity;
                        productInstance.CurrencyIsoCode = ele.Pricebook2.CurrencyIsoCode;
                        productInstance.Plan_handle__c = ele.Product2.Plan__c;
                        productInstance.Is_subscription__c = ele.Product2.Is_subscription__c;

                        oppProducts.push(productInstance);

                    }
                });
            } else {
                productsList.forEach(ele => {


                    if ((parseInt(ele.quantity) > 0)) {



                        if (oppProductIdList.includes(ele.Product2Id)) {


                            oppProducts.forEach(eleLp => {
                                if (eleLp.Product2Id === ele.Product2Id) {

                                    eleLp.Quantity = parseInt(ele.quantity) + parseInt(eleLp.Quantity);

                                }
                            });


                        } else {


                            let productInstance = {};

                            productInstance.OpportunityId = oppIdToAssociateProductsWith;
                            productInstance.PricebookEntryId = ele.Id;
                            productInstance.Quantity = ele.quantity;

                            // Product2
                            productInstance.Product2 = ele.Product2


                            // make UnitPrice, ListPrice of OppLineItem equals UnitPrice of priceBookEntry
                            productInstance.UnitPrice = ele.UnitPrice;
                            productInstance.ListPrice = ele.UnitPrice;


                            productInstance.Discount = 0;
                            productInstance.Pricebook_Id__c = ele.Pricebook2Id;
                            productInstance.PricebookEntry_Id__c = ele.Id;
                            productInstance.Name = ele.Name;
                            productInstance.Partner_Provision_Value__c = ele.Partner_provision_value__c;
                            productInstance.Partner_Sales_Value__c = ele.Partner_sales_value__c;
                            productInstance.Provision_Base__c = ele.Provision_base__c;
                            productInstance.Quantity = ele.quantity;
                            productInstance.CurrencyIsoCode = ele.Pricebook2.CurrencyIsoCode;
                            productInstance.Plan_handle__c = ele.Product2.Plan__c;
                            productInstance.Is_subscription__c = ele.Product2.Is_subscription__c;


                            oppProducts.push(productInstance);
                        }
                    }
                });
            }


            this.oppProducts = oppProducts;


            this.handlerChangeQuantity();
            let fullProductData = this.fullProductData;
            fullProductData.forEach(ele => {
                if (this.oppProducts[0].Pricebook_Id__c === ele.Id) {
                    this.selectedPriceBookName = ele.Name;
                    this.isleadProductComboboxdisplay = false;
                }
            });

            this.oppProducts.map((curRecord) => {
                curRecord.OpportunityId = oppIdToAssociateProductsWith;

                delete curRecord.TotalPrice;
            });


            insertRecords_Apex({newProductList: this.oppProducts}).then(result => {
                if (result) {


                    this.isLoadedSpinner = false;
                    this.oppProducts = result;
                    this.isProductEmpty = true;
                    this.isShowOrderTotal = true;
                    this.disableButton = false;

                    try {
                        this.getProductsData();
                    } catch (e) {
                        console.log("🚀️ Error in ~ Dfj_ProductSelectorForOpportunity ~ addProducts() insertRecords_Apex result? try :", JSON.stringify(e.message));
                    }
                }
                eval("$A.get('e.force:refreshView').fire()");


            })

            this.updateOrderTotalInOpportunity();
            //DFJ-347 changes start
            this.disablePaymentButton = true;
            publish(this.messageContext, Payment_Message_Channel, this.disablePaymentButtonDetailsToPublish);
            //DFJ-347 changes end
            this.showSuccessToast('', 'Success');
        } catch (e) {
            console.log("🚀️ Error in ~ Dfj_ProductSelectorForOpportunity ~ addProducts() :", JSON.stringify(e.message));
        }

    }

    handlerFixedDiscountInput(event) {
        try {
            let val = event.target.value;
            if (val && !Number.isNaN(val)) {

                let floatValueOfInputAddedDiscountValue = parseFloat(val);


                if (floatValueOfInputAddedDiscountValue < parseFloat('0') || floatValueOfInputAddedDiscountValue > this.subTotalValue) {
                    this.potentialValueOfAddedDiscount = null;
                } else {
                    this.potentialValueOfAddedDiscount = floatValueOfInputAddedDiscountValue;
                }

            } else {
                this.potentialValueOfAddedDiscount = null;
            }
        } catch (error) {
            console.error(error);
        }

    }

    handlerFixedDiscountChange() {
        try {
            let orderTotal = 0;
            let totalValue = this.total;
            let fixedDiscount = this.leadRecord.Fixed_discount_Type__c;
            if (totalValue <= fixedDiscount) {
                this.ordertotal = orderTotal;
            } else {
                orderTotal = parseFloat((parseFloat(totalValue).toFixed(2) - parseFloat(fixedDiscount).toFixed(2))).toFixed(2);
            }

            this.orderTotal = orderTotal;
        } catch (error) {
            console.error(error);
        }

    }

    handlerFixedDiscount() {
        try {
            this.leadRecord.Id = this.recordId;

            let number = this.leadRecord.Fixed_discount_Type__c;
            if (number - Math.floor(number) > 0) {
                let sepreatednumber = number.toString().replace(".", ",");
                this.leadRecord.Fixed_discount_Type__c = sepreatednumber;
            }
            insertFixedDiscountinLead_Apex({leadRecord: this.leadRecord}).then(result => {
                if (result) {
                    this.leadRecord.Fixed_discount_Type__c = result.Fixed_discount_Type__c;

                    this.handlerFixedDiscountChange();
                    this.showSuccessToast();
                    eval("$A.get('e.force:refreshView').fire()");
                }
            }).catch((error) => {
                console.log("some error in code:", error);
            });


        } catch (error) {
            console.error(error);
        }

    }

    handlerApplyButtonClickForOrderTotalCalculation() {
        try {
            this.handleOrderTotalCalculation();
        } catch (e) {
            console.log("🚀️ Error in ~ Dfj_ProductSelectorForOpportunity ~ handlerApplyButtonClickForOrderTotalCalculation() :", JSON.stringify(e.message));
        }
    }

    async handleOrderTotalCalculation() {
        try {

            if (this.potentialValueOfAddedDiscount) {

                this.addedDiscount = parseFloat(this.potentialValueOfAddedDiscount);
            } else {
                this.addedDiscount = 0;
            }

            await this.updateOrderTotalInOpportunity();
            //DFJ-347 changes start
            this.disablePaymentButton = true;
            
        publish(this.messageContext, Payment_Message_Channel, this.disablePaymentButtonDetailsToPublish);
            this.showSuccessToast('Updated.', 'Success.');
            //DFJ-347 end

        } catch (e) {
            console.log("🚀️ Error in ~ Dfj_ProductSelectorForOpportunity ~ handleOrderTotalCalculation() :", JSON.stringify(e.message));
        }
    }


    /**method used for increase and decrease the value of Amount */
    increaseDecreaseButton(event) {
        try {
            let productsList = this.currentProductList;
            let tabIndex = event.target.dataset.index;
            let buttonName = event.target.name;
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
            this.currentProductList = productsList;
        } catch (error) {
            console.error(error);
        }


    }

    changeIntValue(event) {
        try {
            let currentProductList = this.currentProductList;
            let tabIndex = event.target.name;
            currentProductList[tabIndex].quantity = parseInt(currentProductList[tabIndex].quantity);
            if (currentProductList[tabIndex].quantity <= 0) {
                currentProductList[tabIndex].quantity = 1;
            } else if (currentProductList[tabIndex].quantity >= 999) {
                currentProductList[tabIndex].quantity = 999;
            }
            this.currentProductList = currentProductList;

        } catch (ex) {
            console.log('Exception in changing quantity--' + ex);
        }
    }


    handlerChangeQuantity() {
        try {
            let totalProvisionBase = 0.00;
            let totalPartnerSalesValue = 0.00;
            let totalPartnerProvisionValue = 0.00;

            let newProductList = this.oppProducts;


            newProductList.forEach(function (ele) {

                let parseIntQuantity = parseInt(ele.Quantity);

                if (parseIntQuantity <= 0) {
                    ele.Quantity = 0;
                } else if (parseIntQuantity >= 999) {
                    ele.Quantity = 999;
                }


                if (!ele.Discount || isNaN(ele.Discount) || ele.Discount < 0) {
                    ele.Discount = 0;
                } else if (ele.Discount >= 100) {
                    ele.Discount = 100;
                }


                let discountPercent = parseFloat(ele.Discount) / 100;

                if (ele.ListPrice) {
                    ele.UnitPrice = ele.ListPrice;


                }


                let totalPriceBeforeDiscount = parseFloat(ele.Quantity) * parseFloat(ele.ListPrice);

                let totalPriceAfterDiscount = (parseFloat(1) - discountPercent) * totalPriceBeforeDiscount;


                ele.TotalPrice = totalPriceAfterDiscount;

                if (ele.Partner_Provision_Value__c || ele.Partner_Provision_Value__c === NaN) {
                    ele.Partner_Provision_Value__c = 0;
                }
                totalPartnerProvisionValue = parseFloat(totalPartnerProvisionValue) + parseFloat(ele.Partner_Provision_Value__c);

                /*checking whether the provision base is null or undefined or Nan*/
                if (ele.Provision_Base__c || ele.Provision_Base__c === NaN) {
                    ele.Provision_Base__c = 0;
                }
                totalProvisionBase = parseFloat(totalProvisionBase) + parseFloat(ele.Provision_Base__c);

                /*checking whether the partner sales value is null or undefined or Nan*/
                if (ele.Partner_Sales_Value__c || ele.Partner_Sales_Value__c === NaN) {
                    ele.Partner_Sales_Value__c = 0;
                }
                totalPartnerSalesValue = parseFloat(totalPartnerSalesValue) + parseFloat(ele.Partner_Sales_Value__c);

            });

            let totalValues = {};
            totalValues.totalProvisionBase = totalProvisionBase;
            totalValues.totalPartnerSalesValue = totalPartnerSalesValue;
            totalValues.totalPartnerProvisionValue = totalPartnerProvisionValue;
            this.totalValues = totalValues;
            this.oppProducts = newProductList;

        } catch (ex) {
            console.info("Error in handlerChangeQuantity -->" + JSON.stringify(ex.message), 'at line number:', JSON.stringify(ex.lineNumber));
        }
    }
//DFJ-347 changes start
    getOrderCategorySize(){
        getOrderCategorySize({oppId : this.recordId}).then((data) => {
            if(data > 0){
                this.includeBundleDiscount = true;
                this.disablePaymentButton = true;
                
        publish(this.messageContext, Payment_Message_Channel, this.disablePaymentButtonDetailsToPublish);
            }
        }).catch((error) => {
            console.error('Error fetching Order category definitions ' + error);
        });
    }
    handleCalculateBundle() {
        this.callProductBundleFlow = true;
    }
   async handleStatusChange(event) {
        if(event.detail.status === 'FINISHED'){
            this.template.querySelector('c-d-f-j_-payment-creator-for-opportunity').disableCreatePayment = false;
            await this.getProductsData();
            this.callProductBundleFlow = false;
            
            this.disablePaymentButton = false;
            
        publish(this.messageContext, Payment_Message_Channel, this.disablePaymentButtonDetailsToPublish);
        }
    }
     refreshOpportunityProducts() {
            this.oppProducts.sort((a, b) => {
            const aIsPositive = a.Net_Total_Price__c >= 0;
            const bIsPositive = b.Net_Total_Price__c >= 0;
            if (aIsPositive && !bIsPositive) return -1;
            if (!aIsPositive && bIsPositive) return 1;
            return a.Product2.Name.localeCompare(b.Product2.Name);
        });
    }
//DFJ-347 changes end
    

    handlerRefershView() {
        this.isProductEmpty = false;
        this.isShowOrderTotal = false;
        this.isleadProductComboboxdisplay = true;
        this.disableButton = true;
    }

    showSuccessToast(message, title) {
        const evt = new ShowToastEvent({
            title: 'Updated', message: 'Success', variant: 'success', mode: 'pester',
        });
        this.dispatchEvent(evt);
    }
}