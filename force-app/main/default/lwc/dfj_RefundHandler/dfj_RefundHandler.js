import { api, LightningElement, wire } from 'lwc';

import getPaymentInfo from "@salesforce/apex/PS_PaymentService.getPaymentInfo";
import refundHandler from "@salesforce/apex/PS_PaymentService.refundHandler";
import getPlanInfo from "@salesforce/apex/PS_PaymentService.getPlanInfo";

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Dfj_RefundHandler extends LightningElement {

    @api recordId;
    @api objectApiName;
    invoiceUniqueHandle;
    isOpenProductSelectionModal;
    totalFetchedPaymentAmount;
    totalPaymentAmountCalculated;
    amountAvailableForRefund;
    paymentOrderLines;
    currencyIsoCode;
    paymentType;
    showPlanInfo = false;//DFJ-318-V2
    planInfo;//DFJ-318-V2
    planName;
    planAmount;
    greaterCalculatedAmountMsg = "Refund amount exceeds amount available for refund.";

    get defaultValueOfPaymentDate() {
        const dt = new Date();
        return dt.toISOString().slice(0, 10)
    }

    responseReturnedFromGetPaymentInfo;
    paymentMethodForManualRefund;
    dateInputForManualRefund = this.defaultValueOfPaymentDate;
    commentRelatedToManualRefund;
    referenceInputRelatedToManualRefund;

    defaultValueOfMethodForManualRefund = "bank_transfer";
    optionsForMethodOfManualRefund = [{
        label: "Bank Transfer", value: "bank_transfer"
    }];

    connectedCallback() {
        this.paymentMethodForManualRefund = this.defaultValueOfMethodForManualRefund;

    }

    get isPaymentTypeManual() {
        return this.objectApiName === 'Payments__c' && this.paymentType === 'manual';
    }

    get initialValueOfCheckbox() {
        return this.isPaymentTypeManual || this.hasUserOptedForManualRefund
    }

    get isConfirmButtonDisabled() {
        return this.greaterCalculatedAmount;
    }

    get greaterCalculatedAmount() {
        return this.totalPaymentAmountCalculated > this.amountAvailableForRefund
    }

    @wire(getPaymentInfo, {
        myRecordId: '$recordId', myObjectApiName: '$objectApiName'
    }) wiredGetPaymentInfo(response) {

        this.responseReturnedFromGetPaymentInfo = response;

        const { data, error } = response;
        if (data) {

            this.currencyIsoCode = data.currencyIsoCode;
            this.invoiceUniqueHandle = data.invoiceUniqueHandle;
            this.paymentType = data.paymentType;

            if (this.paymentType === 'manual') {
                this.hasUserOptedForManualRefund = true;
            }

            this.totalFetchedPaymentAmount = data.totalPaymentAmount;
            this.paymentOrderLines = data.paymentOrderLines;
            this.amountAvailableForRefund = this.totalFetchedPaymentAmount - data.refundedAmount;
            this.addSubtotalAndFurtherProcessing();
            //DFJ-318-V2 start
            if (data.subscriptionStatus == 'Activated' && data.type == 'Subscription' && data.status == 'Settled') {
                this.showPlanInfo = true;
                this.getPlanData();
            }
            //DFJ-318-V2 end
        } else if (error) {
            console.error('Error in wire.' + JSON.stringify(error));
        }
    }

    //DFJ-318-V2 starts
    getPlanData() {
        getPlanInfo({ recordId: this.recordId })
            .then((data) => {
                this.planName = data.Subscriptions__r.Plan_Name__c;
                this.planAmount = data.Subscriptions__r.Plan_Amount__c;
                this.totalPaymentAmountCalculated = this.planAmount;
            })
            .catch((error) => {
                console.error('Error in getting plan info ' + error);
            })
    }

    handlePlanInputChange(event) {
        try {
            const field = event.target.dataset.field;
            const value = event.detail.value;
            if (field == 'Name') {
                this.planName = value;
            }
            else if (field == 'amount') {
                this.planAmount = value;
            }
            this.calculateTotalPaymentAmount();
        }
        catch (error) {
            console.error('error ' + error);
        }
    }
    //DFJ-318-V2 ends

    hasUserOptedForManualRefund;
    handleToggleInputForManualRefund(event) {
        this.hasUserOptedForManualRefund = event.target.checked;
    }

    handleCommentInputForManualRefund(event) {
        this.commentRelatedToManualRefund = event.target.value;
    }

    handleReferenceInputForManualRefund(event) {
        this.referenceInputRelatedToManualRefund = event.target.value;
    }

    handleConfirmButtonClickForManualRefund() {

        let note_linesValue;
        if (this.paymentOrderLines) {
            note_linesValue = this.paymentOrderLines.filter(line => line.Quantity__c > 0 && line.UnitPrice > 0);
            note_linesValue = note_linesValue.map(item => {
                return {
                    amount: parseFloat(item.UnitPrice) * 100, text: item.Description, quantity: parseFloat(item.Quantity__c)
                }
            })
        }
        if (this.showPlanInfo) {
            note_linesValue = [{ amount: parseFloat(this.planAmount) * 100, text: this.planName, quantity: 1 }];
        }

        let manual_transferValue = {
            method: this.paymentMethodForManualRefund,
            comment: this.commentRelatedToManualRefund,
            reference: this.referenceInputRelatedToManualRefund,
            payment_date: this.dateInputForManualRefund
        }

        let bodyOfRefundCallout = {
            invoice: this.invoiceUniqueHandle, note_lines: note_linesValue, manual_transfer: manual_transferValue
        }


        this.handleApexCallForRefund(bodyOfRefundCallout);
    }


    handleConfirmButtonClick() {
        this.makeCalloutBodyAndCallApexMethod();
    }

    makeCalloutBodyAndCallApexMethod() {
        let note_linesValue;
        if (this.paymentOrderLines) {
            note_linesValue = this.paymentOrderLines.filter(line => line.Quantity__c > 0 && line.UnitPrice > 0);
            note_linesValue = note_linesValue.map(item => {
                return {
                    amount: parseFloat(item.UnitPrice) * 100, text: item.Description, quantity: parseFloat(item.Quantity__c)
                }
            });
        }
        if (this.showPlanInfo) {
            note_linesValue = [{ amount: parseFloat(this.planAmount) * 100, text: this.planName, quantity: 1 }];
        }
        let bodyOfRefundCallout = {
            invoice: this.invoiceUniqueHandle, note_lines: note_linesValue
        }

        this.handleApexCallForRefund(bodyOfRefundCallout);
    }

    handleApexCallForRefund(bodyOfRefundCallout) {

        refundHandler({
            currencyIsoCode: this.currencyIsoCode, calloutBody: JSON.stringify(bodyOfRefundCallout),
        }).then(response => {

            try {
                if (response === "200") {

                    this.showToast('success', 'Success', 'Refund successful.');

                    this.amountAvailableForRefund = parseFloat(this.amountAvailableForRefund) - parseFloat(this.totalPaymentAmountCalculated);

                    this.isOpenProductSelectionModal = false;
                } else {
                    this.showToast('error', 'Error', 'An error occurred while creating the refund.');
                }
            } catch {
                this.showToast('error', 'Error', 'An error occurred while creating the refund.');
            }


        }).catch(error => {
            console.error("🚀️ ~ RefundHandler ~  ~ error:", JSON.stringify(error));
        })
    }

    showToast(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant, title: title, message: message
        });

        this.dispatchEvent(event);
    }


    addSubtotalAndFurtherProcessing() {
        if (this.paymentOrderLines) {
            this.paymentOrderLines = this.paymentOrderLines.map(item => {
                let unitPriceValue = item.Amount__c;
                let subTotalValue = item.Quantity__c * item.Amount__c;
                let descriptionValue = item.Name;
                return {
                    ...item, "Description": descriptionValue, "UnitPrice": unitPriceValue, "Subtotal": subTotalValue
                }
            });
        }

        this.calculateTotalPaymentAmount();
    }

    handleRefundButtonClick() {
        this.isOpenProductSelectionModal = true;

    }

    handleCancelButtonClick() {
        this.isOpenProductSelectionModal = false;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const id = event.target.dataset.id;
        const value = event.target.value;

        this.paymentOrderLines = this.paymentOrderLines.map(line => {
            if (line.Id === id) {
                line[field] = value;
                if (field === "Quantity__c" || field === "UnitPrice") {
                    line.Subtotal = line.Quantity__c * line.UnitPrice;
                }
            }

            return line;
        });


        this.calculateTotalPaymentAmount();
    }

    calculateTotalPaymentAmount() {
        if (this.showPlanInfo) {
            this.totalPaymentAmountCalculated = this.planAmount;
        } else if (this.paymentOrderLines) {
            this.totalPaymentAmountCalculated = this.paymentOrderLines.reduce((total, line) => total + line.Subtotal, 0);
        }
    }

    handleDeleteRow(event) {
        const rowId = event.target.dataset.id;

        // Remove the row from the paymentOrderLines array
        this.paymentOrderLines = this.paymentOrderLines.filter(line => line.Id !== rowId);
        this.calculateTotalPaymentAmount();
    }

}