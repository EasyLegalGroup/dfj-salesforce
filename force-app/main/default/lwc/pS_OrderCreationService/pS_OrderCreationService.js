import { LightningElement, api, track, wire} from 'lwc';
import createOrderRecord from '@salesforce/apex/PS_OrderCreationController.createOrderRecord';
import createOrderAndOrderItems from '@salesforce/apex/PS_OrderCreationController.createOrderAndOrderItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//DFJ-80
import getUpdatedPayment from '@salesforce/apex/PS_PaymentController.getUpdatedPayment';

// DFJ-330 changes start
import fetchPriceBookAndEntries from '@salesforce/apex/PS_OrderCreationController.fetchPriceBookAndEntries';
// DFJ-330 changes end

export default class PS_OrderCreationService extends LightningElement {

    @api recordId;
    @track isAddProductModalOpen = false;
    @track selectedPriceBookName;
    @track currentProductList = [];
    @track isConfirmModalOpen = false;
    @track isRelateJournal = false;
    @track orderProducts = [];
    @track totalValues = 0;
    @track total = 0;
    @track orderRecord = {};
    @track editOrderProductList = [];
    @track isEditable =  false;
    @track insertOrderItemsList =  [];
    @track selectedPriceBookId ;
    @track accountMarketUnit;
    @track leadId;
    @track orderTotal = 0;
//Changes Starts DFJ-77
    @track associatedJournals;
    @track journalList;
    @track selectedJournal = '';
    // @track journalName = '';
    // @track journalStates = '';
    @track confirmJournalOnAccount = false;
    // @track orderConfirmationToLinkJournal = '';
    @track showJournalLinkingCOnfirmationModel = false;

//End
//DFJ-101
@track campaignList = [];
@track relatedEventId = '';
//End
//DFJ-80
showPaymentModal = false;
handleCustomerPaidConfirmationModal = false;
paymentList = [];
@api objectApiName;
@api orderFixedDiscount = 0;
updatedPayment = [];
billingInfo = '';
subscriptionInfo = '';
subscriptionStatus = '';
orderValue = '';
paymentStatus = '';
paymentLink = '';
showUpdatedPaymentModal = false;
checkCreatePayment = true;


    // DFJ-330 changes start
    retrievedPricebooksWithItsEntriesData;
    selectedPriceBookIdUsingCombobox;
    priceBookOptionsForCombobox=[];


    @wire(fetchPriceBookAndEntries,{
        actRecordId : '$recordId'
    }) wiredFetchPriceBookAndEntries(response){

        const {data,error} = response;
        if (data){
            this.retrievedPricebooksWithItsEntriesData = data;


            this.priceBookOptionsForCombobox = this.retrievedPricebooksWithItsEntriesData.map(item => {
               return {
                    value:item.pricebookRecord?.Id,
                    label:item.pricebookRecord?.Name
                }
            });

            if (this.priceBookOptionsForCombobox.length === 1) {
                this.selectedPriceBookIdUsingCombobox = this.priceBookOptionsForCombobox[0].value;

                if (Array.isArray(this.retrievedPricebooksWithItsEntriesData) && this.retrievedPricebooksWithItsEntriesData.length > 0) {
                    this.currentProductList = this.retrievedPricebooksWithItsEntriesData[0]?.pricebookEntries.map(
                        item =>{
                            return {
                                ...item,
                                quantity : 0,
                                isEditable : false
                            }
                        }
                    );
                    this.selectedPriceBookName = this.retrievedPricebooksWithItsEntriesData[0]?.pricebookRecord?.Name;
                }

                this.selectedPriceBookId = this.selectedPriceBookIdUsingCombobox;
            }
        }
        if (error){
            console.error('Error in wiredFetchPriceBookAndEntries.');
        }
    }

    get isPricebookSelectionDisabled(){
        return this.priceBookOptionsForCombobox.length === 1;
    }

    handleSelectionOfPricebook(event){
        this.selectedPriceBookIdUsingCombobox = event.target.value;

        // Find the label for the selected value
        const selectedOption = this.priceBookOptionsForCombobox.find(opt => opt.value === this.selectedPriceBookIdUsingCombobox);
        this.selectedPriceBookName = selectedOption ? selectedOption.label : '';
        this.selectedPriceBookId = this.selectedPriceBookIdUsingCombobox;

        this.retrievedPricebooksWithItsEntriesData.forEach(ele => {
            if (this.selectedPriceBookIdUsingCombobox === ele.pricebookRecord?.Id) {
                this.currentProductList = ele?.pricebookEntries.map(
                    item =>{
                        return {
                            ...item,
                            quantity : 0,
                            isEditable : false
                        }
                    }
                );
            }
        });
    }

    get isShowProductsInAddProductModal(){
        return Array.isArray(this.currentProductList) &&this.currentProductList.length > 0;
    }
    // DFJ-330 changes end

    // get checkIfJournalNotLinked(){
    //     return this.orderConfirmationToLinkJournal ? false : true;
    // }
    //Changes Starts DFJ-77

    handleJournalSelect(event) {
       this.selectedJournal = event.detail.value;
    //    this.orderConfirmationToLinkJournal = !this.selectedJournal ? 'Are you sure you want to create the order without relating a journal?' : '';
    }

    //End

    async handleCreateOrderService(){
        await createOrderRecord({recordId : this.recordId}).then(result=>{
            if(result && !result.errorMessage && result.selectedPriceBook && result.selectedPriceBookEnteries){


                this.accountMarketUnit = result.marketUnit;
                this.leadId = result.accountRecordInstance.Lead__c;
                //Changes DFJ-101
                this.campaignList = result.campaignRecordInstance;
                this.relatedEventId = result.accountRecordInstance.Related_Event_ID__c;
                //End
                //Changes DFJ-77 Starts
                this.journalList = result.relatedJournals;
                let options=[];
                options.push({label: '--None--', value: ''})
                for(var key in this.journalList){
                 options.push({label: this.journalList[key].Name + ' : State - ' + this.journalList[key].Journal_States__c, value: this.journalList[key].Id})
                }
                this.associatedJournals = options;
                //console.log('data-->'+ JSON.stringify(this.journalList));
                //End

                this.isAddProductModalOpen = true;



            }else{
                this.ShowToastEvent(result && result.errorMessage ? result.errorMessage : 'Something went wrong','Error');
            }
        })

        // DFJ-330 changes start
        if ( this.isAddProductModalOpen && Array.isArray(this.priceBookOptionsForCombobox) && this.priceBookOptionsForCombobox.length > 1) {
            this.selectedPriceBookIdUsingCombobox = null;
            this.selectedPriceBookId = null;
            this.selectedPriceBookName = null;
            this.currentProductList = [];
        }
        // DFJ-330 changes end
    }


     /**method used for increase and decrease the value of Amount */
     increaseDecreaseButton(event){

        try {
            let productsList = this.currentProductList;
            let tabIndex = event.target.dataset.index;

            let buttonName = event.target.name;
            if (productsList[tabIndex].quantity < 0 ) {

                productsList[tabIndex].quantity = 0;
            }
            if (buttonName === 'add') {
                productsList[tabIndex].quantity = parseInt(productsList[tabIndex].quantity) + 1;

            } else if (buttonName === 'subtract') {
                if (!productsList[tabIndex].quantity < 1) {
                    productsList[tabIndex].quantity = parseInt(productsList[tabIndex].quantity) - 1;
                }
            }

            this.currentProductList =  productsList;
        } catch (error) {
            console.error(error);
        }


    }

    changeIntValue(event){

        try {
            let currentProductList = this.currentProductList;
            let tabIndex = event.target.name;

            currentProductList[tabIndex].quantity = parseInt(currentProductList[tabIndex].quantity);
            if (currentProductList[tabIndex].quantity <= 0) {
                currentProductList[tabIndex].quantity = 1;
            } else if (currentProductList[tabIndex].quantity >= 999) {
                currentProductList[tabIndex].quantity = 999;
            }
            this.currentProductList =  currentProductList;
        } catch (ex) {
            console.error('Exception in changing quantity--' + ex);
        }
    }
    async closeModal(){

         // DFJ-330 changes start
        this.currentProductList.forEach(item =>{
            item.quantity = 0
        })

        // DFJ-330 changes end

        this.isAddProductModalOpen = false;
        this.isConfirmModalOpen = false;
        this.editOrderProductList =  [];
        this.orderProducts = [];
        this.isRelateJournal= false;
        this.selectedJournal = '';
        this.confirmJournalOnAccount = false;
        this.showPaymentModal = false;
        this.showJournalLinkingCOnfirmationModel = false;
        this.showUpdatedPaymentModal = false;
        //console.log('this.selectedJournal'+this.selectedJournal);

    }

    handleNext(){
        this.isRelateJournal= true;
        this.isConfirmModalOpen = false;
    }

    addProductsToOrderItems(){
        try {

            let productList = this.currentProductList;
            let selectedProductList = [];
            productList.forEach(element => {
                if(element.quantity > 0){
                    selectedProductList.push(element);
                }
            });

            if(selectedProductList.length > 0){

                this.isRelateJournal= false;
                this.isConfirmModalOpen = true;
                this.isAddProductModalOpen = false;
                this.addProducts();
                this.orderRecord.Fixed_discount_Type__c = 0;
                this.handlerFixedDiscountChange();
            }else{
                this.ShowToastEvent('Please add the products','Error');
            }

        } catch (error) {
            console.error(error);
        }
    }

    addProducts(){

        let productsList = [...this.currentProductList];

        let orderProducts = [...this.orderProducts]; // To insert all the lead products

       // let OrderProductIdList = []; // To insert all the lead products

        if (orderProducts  && orderProducts.length === 0) {
            productsList.forEach(ele=> {
                if ((parseInt(ele.quantity) > 0)) {

                    let productInstance = {};
                    productInstance.Discount__c = 0;
                    productInstance.UnitPrice = ele.UnitPrice;
                    productInstance.Pricebook_Id__c = ele.Pricebook2Id;
                    productInstance.Product2Id = ele.Product2Id;
                    productInstance.PricebookEntryId = ele.Id;
                    productInstance.Product_Name__c = ele.Name;
                    productInstance.Name = ele.Name;
                    productInstance.Partner_Provision_Value__c = ele.Partner_provision_value__c;
                    productInstance.Partner_Sales_Value__c = ele.Partner_sales_value__c;
                    productInstance.Provision_Base__c = ele.Provision_base__c;
                    productInstance.Quantity = ele.quantity;
                    productInstance.CurrencyIsoCode = ele.Pricebook2.CurrencyIsoCode;
                    productInstance.Plan_handle__c = ele.Product2.Plan__c;
                    productInstance.Is_subscription__c = ele.Product2.Is_subscription__c;

                    orderProducts.push(productInstance);

                }
            });
        }

        this.orderProducts =  orderProducts;
        this.insertOrderItemsList = orderProducts;
        this.orderRecord.Fixed_discount_Type__c  = 0;
        this.handlerChangeQuantity();
    }

    handlerChangeQuantity(){
        try {
            let totalPrice = 0;
            let totalProvisionBase = 0.00;
            let totalPartnerSalesValue = 0.00;
            let totalPartnerProvisionValue = 0.00;

            let newProductList = this.orderProducts;
            newProductList.forEach(function(ele) {
                // Check if the smaller than 0 change it to 1
                ele.Quantity = parseInt(ele.Quantity);
                if (ele.Quantity <= 0) {
                    ele.Quantity = 1;
                } else if (ele.Quantity >= 999) {
                    ele.Quantity = 999;
                }
                if (!ele.Discount__c || ele.Discount__c === NaN || ele.Discount__c < 0) {
                    ele.Discount__c = 0;
                } else if (ele.Discount__c >= 100) {
                    ele.Discount__c = 100;
                }
                let discountedValue = parseFloat((ele.Discount__c / 100) * (ele.UnitPrice)).toFixed(2);


                ele.totalPrice = parseFloat((parseFloat(ele.UnitPrice).toFixed(2) - parseFloat(discountedValue).toFixed(2)) * ele.Quantity).toFixed(2);
                totalPrice = parseFloat(totalPrice) + parseFloat(ele.totalPrice);

                if (ele.Partner_Provision_Value__c  || ele.Partner_Provision_Value__c === NaN) {
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
            this.totalValues  = totalValues;
            this.total = totalPrice.toFixed(2);
            this.orderTotal = this.total;
            this.orderProducts = newProductList;
        } catch (ex) {
            console.info("Error:-->" + ex.message);
        }
    }

    handlerFixedDiscountInput(event){
        try {
        let value = event.target.value;
           this.orderRecord.Fixed_discount_Type__c = !value ? '' : value;
           // if(value===null || value ===''){
              //  if(!value){
            if(value <= 0){
                value = 0;
                // console.log('check00>');
                this.orderRecord.Fixed_discount_Type__c = 0;
            }else{
              this.orderRecord.Fixed_discount_Type__c = value;
            //   console.log('checkelse0>');
            }
            this.handlerFixedDiscountChange();
        } catch (error) {
            console.error(error);
        }

    }

    confirmJournal(){
        this.confirmJournalOnAccount = true;
    }

    handlerFixedDiscountChange(){
        try {
        //DFJ-86 changes starts
        let number = this.orderRecord.Fixed_discount_Type__c;
        // console.log('number-->'+number);
        if((number - Math.floor(number) )<0  ){
            let sepreatednumber = number.toString().replace(".", ",");
            // console.log('sepreatednumber-->'+sepreatednumber);
            this.orderRecord.Fixed_discount_Type__c = sepreatednumber;
            // console.log(' this.orderRecord.Fixed_discount_Type__c-->'+ this.orderRecord.Fixed_discount_Type__c);
        }
        // console.log('this.orderRecord.Fixed_discount_Type__c;-->'+this.orderRecord.Fixed_discount_Type__c);

        let orderTotal = 0;
        let totalValue = this.total;
        // console.log('totalValue-->'+totalValue);
        let fixedDiscount = this.orderRecord.Fixed_discount_Type__c;

        //End
        orderTotal = parseFloat((parseFloat(totalValue).toFixed(2) - parseFloat(fixedDiscount).toFixed(2))).toFixed(2);
        this.orderTotal = orderTotal;
        this.orderFixedDiscount = this.orderRecord.Fixed_discount_Type__c;
        // console.log(' this.orderTotal else-->'+orderTotal);
        } catch (error) {
            console.error(error);
        }
    }

    ShowToastEvent(message , title)
    {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            messageTemplate: message,
            variant: title,
            mode: 'pester',
            duration : 5000
        });
        this.dispatchEvent(evt);
    }

    editButtonClicked(event){
        let buttonLabel =  event.target.name;
        let orderProduct = this.orderProducts;

        let selectedIndex = event.target.dataset.index;
        if(buttonLabel === 'Edit'){
        this.editTabIndex = selectedIndex;
        orderProduct[selectedIndex].isEditable = true;
        this.editOrderProductList = orderProduct[selectedIndex];
        }else if(buttonLabel === 'Save'){
            orderProduct[selectedIndex].isEditable = false;
            this.editOrderProductList = orderProduct[selectedIndex];
        }
        this.handlerChangeQuantity();
        this.handlerFixedDiscountChange();
    }

    changeQuantity(event){
        let totalPrice = 0.00;
           try{
            if(event.target.name == 'quantity'){
                this.editOrderProductList.Quantity = !event.target.value ? 0 : event.target.value;
                //console.log('editquantity',this.editOrderProductList.Quantity);
                this.editOrderProductList.Quantity = parseInt(this.editOrderProductList.Quantity);
                if(event.target.value <= 0){
                    this.editOrderProductList.Quantity = 1;
                    event.target.value = 0;
                } else if(event.target.value >= 999){
                    this.editOrderProductList.Quantity = 999;
                    event.target.value = 999;
                }
            }else{
                this.editOrderProductList.Discount__c = !event.target.value ? 0 : event.target.value;
            }

            if (!this.editOrderProductList.Discount__c || this.editOrderProductList.Discount__c === NaN || this.editOrderProductList.Discount__c < 0) {
                this.editOrderProductList.Discount__c = 0;
            }else if (this.editOrderProductList.Discount__c >= 100) {
                this.editOrderProductList.Discount__c = 100;
            }

            let discountedValue = parseFloat((this.editOrderProductList.Discount__c / 100) * (this.editOrderProductList.UnitPrice)).toFixed(2);
            this.editOrderProductList.totalPrice = parseFloat((parseFloat(this.editOrderProductList.UnitPrice).toFixed(2) - parseFloat(discountedValue).toFixed(2)) * this.editOrderProductList.Quantity).toFixed(2);
            totalPrice = parseFloat(totalPrice) + parseFloat(this.editOrderProductList.totalPrice);
            this.editOrderProductList.totalPrice = totalPrice.toFixed(2);

        } catch (error) {
            console.error(error);
        }
    }

    checkandCreateOrderOnAccount(event){
        if (!this.selectedJournal) {
            this.isRelateJournal = false;
            this.showJournalLinkingCOnfirmationModel = true;
            this.showPaymentModal = false;
            this.createOrder();
            return;
        }
        if(this.orderTotal > 0){
            this.isRelateJournal = false;
            this.createOrder();
            this.showPaymentModal = true;
        }else if(this.orderTotal == 0){
            this.createOrder();
            this.checkCreatePayment = false;
            this.createOrderOnAccount();

        }else{
            this.createOrder();
            this.createOrderOnAccount();

        }

    }

    createOrderOnAccount(event){


        let orderItemsList =  this.orderProducts;

        const updatedOrderItemsList = orderItemsList.map((obj) => {
        const { isEditable, totalPrice, ...orderItems } = obj;
        return orderItems;
        });

        try {
            /*this.orderRecord.AccountId = this.recordId;
            this.orderRecord.Pricebook2Id = this.selectedPriceBookId;
            this.orderRecord.Status = 'Draft';
            this.orderRecord.EffectiveDate = new Date();
            this.orderRecord.Market_Unit__c = this.accountMarketUnit;
            this.orderRecord.Lead__c =  this.leadId;
            //DFJ-101
            console.log('this.orderRecord.Campaign__c-INNN->'+this.campaignList);
            this.orderRecord.Campaign__c = this.campaignList.length ? this.campaignList[0].Id : null;
            this.orderRecord.Related_Event_ID__c = this.campaignList.length ? this.campaignList[0].Related_Event_ID__c : '';
            console.log('this.orderRecord.Campaign__c-->'+this.orderRecord.Campaign__c);
            console.log('this.orderRecord.Related_Event_ID__c-->'+this.orderRecord.Related_Event_ID__c);
            //End
            this.orderRecord.CurrencyIsoCode = this.accountMarketUnit == 'FA_SE' || this.accountMarketUnit == 'Testamente_SV' ? 'SEK' : 'DKK';
            console.log(' this.orderRecord-->'+ JSON.stringify(this.orderRecord));
            //Changes Starts DFJ-77 Added a param selected Journal to link order with journal
            if(this.selectedJournal!==null){
                //console.log('this.selectedJournalin--> '+this.selectedJournal);
                this.orderRecord.Journal__c = this.selectedJournal;
            }else{
                //console.log('this.selectedJournal is empty');
                // Set Journal__c to null if this.selectedJournal is empty
                this.orderRecord.Journal__c = null;
            }*/
            //End
            //console.log('this.selectedJournalout--> '+this.selectedJournal);

            //DFJ-80 Changes
            let recId = this.recordId;
            if(this.checkCreatePayment == false){
                recId = '';
            }
            //End
            createOrderAndOrderItems({OrderItemsProduct :JSON.stringify(updatedOrderItemsList),orderRecord : this.orderRecord, recId : recId}).then(result=>{
                if(result && result.includes(" Successfully")){
                    this.isConfirmModalOpen = false;

                    this.ShowToastEvent(result,'Success');
                    eval("$A.get('e.force:refreshView').fire()");
                }else{
                    this.isConfirmModalOpen = false;
                    this.ShowToastEvent(result,'Error');
                    eval("$A.get('e.force:refreshView').fire()");
                }
                this.selectedJournal = '';
                this.isRelateJournal = false;
                this.isAddProductModalOpen = false;
                this.isConfirmModalOpen = false;
                this.showJournalLinkingCOnfirmationModel = false;
                this.showPaymentModal = false;
                this.handleCustomerPaidConfirmationModal = false;


            })
        } catch (error) {
            console.error(error);
        }
    }
    //Changes DFJ-80
    updateMessage(event) {
        this.updatedPayment = event.detail;
        this.showPaymentModal = false;
        this.showUpdatedPaymentModal = true;
            this.billingInfo = 'Billing Information: ';
            this.subscriptionInfo = 'Subscription Information: ';
            this.subscriptionStatus = 'Subscription status: ';
            this.orderValue = 'Order value: ';
            this.paymentStatus = 'Payment Status:';
            this.paymentLink = 'Payment Link';
            this.paymentUpdatedStatus = 'Payment Status';

            //this.createOrderOnAccount();

    }
    createOrder(){
        this.orderRecord.AccountId = this.recordId;
            this.orderRecord.Pricebook2Id = this.selectedPriceBookId;
            this.orderRecord.Status = 'Draft';
            this.orderRecord.EffectiveDate = new Date();
            this.orderRecord.Market_Unit__c = this.accountMarketUnit;
            this.orderRecord.Lead__c =  this.leadId;
            //DFJ-101
            this.orderRecord.Campaign__c = this.campaignList.length ? this.campaignList[0].Id : null;
            this.orderRecord.Related_Event_ID__c = this.campaignList.length ? this.campaignList[0].Related_Event_ID__c : '';
            //End
            this.orderRecord.CurrencyIsoCode = this.accountMarketUnit == 'FA_SE' || this.accountMarketUnit == 'Testamente_SV' ? 'SEK' : 'DKK';
            //Changes Starts DFJ-77 Added a param selected Journal to link order with journal
            if(this.selectedJournal!==null){
                //console.log('this.selectedJournalin--> '+this.selectedJournal);
                this.orderRecord.Journal__c = this.selectedJournal;
            }else{
                //console.log('this.selectedJournal is empty');
                // Set Journal__c to null if this.selectedJournal is empty
                this.orderRecord.Journal__c = null;
            }
    }
    //End


    goBackToProductModal(){
        this.orderProducts = [];
        this.isConfirmModalOpen = false;
        this.isRelateJournal = false;
        this.isAddProductModalOpen = true;
        this.showPaymentModal = false;


        addProducts();

    }
    goBackToRelateJournalModal(){
        //this.orderProducts = [];
        this.isConfirmModalOpen = true;
        this.isRelateJournal = false;
        this.isAddProductModalOpen = false;
        this.showPaymentModal = false;


    }

    showModelToRelateJournal(){
        this.showJournalLinkingCOnfirmationModel = false;
        this.isRelateJournal = true;
        this.showPaymentModal = false;

    }

    //DFJ-80
    handleJournalLinkingNext(){
       // this.showPaymentModal = true;
        this.showJournalLinkingCOnfirmationModel= false;
        if(this.orderTotal > 0){
            this.showPaymentModal = true;
        }else{
            this.checkCreatePayment = false;
            this.createOrderOnAccount();
        }
        // try{
        //     createPaymentRecord({accId: this.recordId}).then(result=>{
        //         if(result){
        //             console.log('result-->'+JSON.stringify(result));
        //             this.paymentList = result;
        //         }
        //         eval("$A.get('e.force:refreshView').fire()");
        //     })
        // }catch(error){
        //         console.error(error);
        //     }
    }

    showJournalLinkingModal(){
        this.showJournalLinkingCOnfirmationModel = false;
        this.isRelateJournal = true;
        this.showPaymentModal = false;
    }
    handleCustomerPaid(){
        this.checkCreatePayment = false;
        this.showUpdatedPaymentModal = false;
        this.showJournalLinkingCOnfirmationModel = false;
        this.handleCustomerPaidConfirmationModal = false;
        this.createOrderOnAccount();

    }
    handleCustomerPaidConfirmation(){
        this.checkCreatePayment = false;
        this.showUpdatedPaymentModal = false;
        this.showJournalLinkingCOnfirmationModel = false;
        this.handleCustomerPaidConfirmationModal = true;
        this.showPaymentModal = false;
    }
    showCreatePaymentModal(){
        this.showPaymentModal = true;
        this.showUpdatedPaymentModal = false;
        this.showJournalLinkingCOnfirmationModel = false;
        this.handleCustomerPaidConfirmationModal = false;
    }
    handleRefresh(){
        getUpdatedPayment({recordId : this.updatedPayment.Id}).then(result=>{
                if(result && !result.errorMessage){
                  this.updatedPayment = result.payment;
                }else{
                    this.ShowToastEvent(result && result.errorMessage ? result.errorMessage : 'Something went wrong','Error');
                }
            })
        }
    get getSubscriptionStyle(){
            return `color: ${this.updatedPayment.Subscription_status__c === 'Accepted' ? 'green' : 'black'}`;
        }
    get getPaymentStyle(){
            return `color: ${this.updatedPayment.Status__c === 'Settled' ? 'green' : 'black'}`;
        }
    openLink() {
            if(!String.isBlank(this.updatedPayment.Payment_link__c)){
                window.open(this.updatedPayment.Payment_link__c, '_blank');

            }
        }
    //End
}