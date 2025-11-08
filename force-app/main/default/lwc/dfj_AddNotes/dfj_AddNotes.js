import {LightningElement, track, api, wire} from 'lwc';
import saveNotesForAddNotes from '@salesforce/apex/DFJ_AddNotes_Apex.saveNotesForAddNotes';

import saveNotesAndRelateToAccount from '@salesforce/apex/DFJ_AddNotes_Apex.saveNotesAndRelateToAccount'; // DFJ - 298

//import getCaseRecord from '@salesforce/apex/DFJ_AddNotes_Apex.getCaseRecord';
import getCaseRecord from '@salesforce/apex/DFJ_AddNotes_Apex.getCaseRecord';

import {publish, createMessageContext} from 'lightning/messageService';
import DATATOACCOUNTHISTORY from '@salesforce/messageChannel/data_to_Account_History_Message_Channel__c';


import {ShowToastEvent} from 'lightning/platformShowToastEvent';


export default class Dfj_AddNotes extends LightningElement {
    @track noteContent = '';
    @track showNotes = false;
    @track notesList = [];

    @api recordId;
    @api objectApiName; // DFJ - 298

    @track isNotesVisible = false;
    @track caseHasAccount = false;
    context = createMessageContext();


    handleNoteChange(event) {
        this.noteContent = event.target.value;
        // console.log(' this.noteContent--->'+ this.noteContent);
    }

    connectedCallback() {
        this.loadCaseRecord();
    }

    loadCaseRecord() {
        getCaseRecord({recId: this.recordId})
            .then(result => {
                this.caseHasAccount = result.caseHasAccount;
                // console.log('data-->' + result);
            })
            .catch(error => {
                console.log('error-->' + error);
            });
    }

    async saveNote() {
        try {
            let notesData = this.noteContent
            if (!notesData || notesData.trim() === '') {
                const event = new ShowToastEvent({
                    title: 'Error Message',
                    message: 'Note data is empty',
                    variant: 'error',
                });
                this.dispatchEvent(event);
            }
                // DFJ - 298
            // Start
            else if (this.objectApiName === 'Account') {
                // getting result in the same way as it was done before for the case
                let result = await saveNotesAndRelateToAccount({recId: this.recordId, notesData: notesData});

                if (result) {
                    this.noteContent = '';
                    const event = new ShowToastEvent({
                        title: 'Success!',
                        message: 'Note has been added successfully.',
                        variant: 'success',
                    });
                    this.dispatchEvent(event);


                    const message = {
                        sourceSystem: "Note Inserted'"
                    };

                    publish(this.context, DATATOACCOUNTHISTORY, message);

                } else {
                    console.error('saveNotesForAddNotes() did not return a proper result.');
                }
            }
            // End


            else if (this.caseHasAccount === false) {
                const event = new ShowToastEvent({
                    title: 'Error Message',
                    message: 'Populate Account to this Case',
                    variant: 'error',
                });
                this.dispatchEvent(event);
            } else {
                // console.log('this.notesData-->'+notesData);
                let result = await saveNotesForAddNotes({recId: this.recordId, notesData: notesData});
                // console.log('result-->'+JSON.stringify(result));
                if (result) {
                    this.noteContent = '';
                    const event = new ShowToastEvent({
                        title: 'Success!',
                        message: 'Note has been added successfully.',
                        variant: 'success',
                    });
                    this.dispatchEvent(event);
                    const noteCreatedEvent = new CustomEvent('notecreated', {
                        detail: {
                            noteData: result,
                        },
                    });
                    this.dispatchEvent(noteCreatedEvent);
                    const message = {
                        sourceSystem: "Note Inserted'"
                    };

                    publish(this.context, DATATOACCOUNTHISTORY, message);

                } else {
                    console.error('ERROR-->');
                }

            }
        } catch (ex) {
            console.error('Error-->' + ex);
        }
    }

}