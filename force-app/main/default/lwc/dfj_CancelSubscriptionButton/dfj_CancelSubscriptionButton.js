import {api, LightningElement, wire} from 'lwc';
import handleCancellationOfSubscription from '@salesforce/apex/PS_PaymentService.handleCancellationOfSubscription';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import SUBSCRIPTION_STATUS_FIELD from "@salesforce/schema/Subscriptions__c.Subscriptions_Status__c";
import confirmationModal from "c/dfJ_ConfirmationModal";

export default class Dfj_CancelSubscriptionButton extends LightningElement {

    @api recordId;
    @api objectApiName;
    @api subscriptionStatus; 

    @wire(getRecord, {
       recordId: "$recordId",
        fields: [SUBSCRIPTION_STATUS_FIELD],
      })
      wiredSubscriptionRecord({data}){
        if(data){
            this.subscriptionStatus = getFieldValue(data, SUBSCRIPTION_STATUS_FIELD);
        }
      }



    handleCancelButtonHandler(){

        confirmationModal.open({
            label : 'Cancel Subscription',
            messageToShow : "The customer\'s subscription will end, after the current period finishes."
        }).then( result => {

                if(result.toString() === 'true'){
                    this.handleCancelSubscription();
                }
            }
        );

        
    }

    isCancellationSuccessful = false;

    handleCancelSubscription(){
        handleCancellationOfSubscription({recordId: this.recordId,objectApiName: this.objectApiName}).then(
            data => {
                if (data === "200") {
                    this.isCancellationSuccessful = true;
                    this.customShowToastHelper('success', 'Success', 'Success.');
                } else {
                    this.customShowToastHelper('error', 'Error', 'Error.');
                }

            }
        ).catch(
            e =>{
                this.customShowToastHelper('error', 'Error', 'Error.');
            }
        );
    }

    get isShowCancelButton(){
        return !this.isCancellationSuccessful && this.subscriptionStatus && ( this.subscriptionStatus.toString().toLowerCase() === 'active' || this.subscriptionStatus.toString().toLowerCase() === 'trial' );
    }

    customShowToastHelper(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant, title: title, message: message
        });

        this.dispatchEvent(event);
    }

}