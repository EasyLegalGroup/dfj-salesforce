import {api, wire, LightningElement} from 'lwc';
import handleExpireOfSubscription from '@salesforce/apex/PS_PaymentService.handleExpireOfSubscription';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import SUBSCRIPTION_STATUS_FIELD from "@salesforce/schema/Subscriptions__c.Subscriptions_Status__c";
import confirmationModal from "c/dfJ_ConfirmationModal";

export default class Dfj_ExpireSubscriptionButton extends LightningElement {

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

    get isShowExpireButton(){
        return !this.isExpirationSuccessful && this.subscriptionStatus && ( this.subscriptionStatus.toString().toLowerCase() === 'active' ||
        this.subscriptionStatus.toString().toLowerCase() === 'trial' ||
        this.subscriptionStatus.toString().toLowerCase() === 'cancelled' );
    }

    handleExpireButtonHandler(){
        confirmationModal.open({
            label : 'Expire Subscription',
            messageToShow : "The customer's subscription will be immediately terminated."
        }).then( result => {

                if(result.toString() === 'true'){
                    this.handleExpireSubscription();
                }
            }
        );
    }

    isExpirationSuccessful = false;

    handleExpireSubscription(){
        handleExpireOfSubscription({recordId: this.recordId,objectApiName: this.objectApiName}).then(
            data => {
                if (data === "200") {
                    this.isExpirationSuccessful = true;
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

    customShowToastHelper(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant, title: title, message: message
        });

        this.dispatchEvent(event);
    }

}