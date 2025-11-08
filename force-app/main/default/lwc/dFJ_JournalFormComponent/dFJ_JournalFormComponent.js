import {api, LightningElement, wire} from 'lwc';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import LEAD_FIELD from '@salesforce/schema/Journal__c.Lead__c';

import getJournalData_Apex from '@salesforce/apex/DFJ_JournalForm.getJournalData_Apex'

export default class DFJ_JournalFormComponent extends LightningElement {

    @api recordId;
    @api objectApiName;
    isJournalFormClicked = true;
    docFabFormUrl;

    isShowFormInModal = false;

    @wire(getRecord,{
        recordId:'$recordId',
        fields:[LEAD_FIELD]
    }) fieldsData(value){

        const {data} = value;
        if(data){
            this.relatedLeadId = getFieldValue(data, LEAD_FIELD);

            if(this.relatedLeadId){
                this.handleGetJournalData().then().catch(
                    error => {
                        console.error("🚀️ Error in ~ DFJ_JournalFormComponent ~ fieldsData() ~ handleGetJournalData :", JSON.stringify(error.message));
                    }
                );
            }
        }
    };

    async handleOpenJournalFormButtonClick(){
        this.handleModalOpen();
    }

    handleModalOpen(){
        if (this.docFabFormUrl){
            this.isShowFormInModal = true;
        }
    }

    handleCloseModal(){
        this.isShowFormInModal = false;
    }

    async handleGetJournalData(){

        getJournalData_Apex({
            JournalId: this.recordId,
            leadId:this.relatedLeadId,
            objectName: this.objectApiName,
            journlaFormClicked: this.isJournalFormClicked,
        }).then( response => {
            this.docFabFormUrl = response.docFabUrl;
        }).catch(
            error => {
                console.error("🚀️ ~ DFJ_JournalFormComponent ~ handleGetJournalData ~ error:", error);
            }
        )
    }


}