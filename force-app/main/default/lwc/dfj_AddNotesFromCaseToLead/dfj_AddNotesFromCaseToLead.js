import { LightningElement,track,api } from 'lwc';
import saveLeadNotesFromCase from '@salesforce/apex/DFJ_AddNotes_Apex.saveLeadNotesFromCase';
import getCaseRecord from '@salesforce/apex/DFJ_AddNotes_Apex.getCaseRecord';
import { publish, createMessageContext } from 'lightning/messageService';
import DATATOLEADHISTORY from '@salesforce/messageChannel/notesDataToLeadHistory_OnCase__c';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Dfj_AddNotesFromCaseToLead extends LightningElement {
    @track noteContent = '';
    @track showNotes = false;
    @track notesList = [];
    @api recordId;
    @track isNotesVisible = false;
    @track caseHasLead = false;
        context = createMessageContext();


    handleNoteChange(event) {
        this.noteContent = event.target.value;
        // console.log(' this.noteContent--->'+ this.noteContent);
    }
    
    connectedCallback() {
        this.loadCaseRecord();
    }

    loadCaseRecord() {
        getCaseRecord({ recId: this.recordId })
            .then(result => {
                this.caseHasLead = result.caseHasLead;
                console.log('data-->' + JSON.stringify(result));
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
            }else if(this.caseHasLead ===false){
                const event = new ShowToastEvent({
                    title: 'Error Message',
                    message: 'Populate Lead to this Case',
                    variant: 'error',
                });
                this.dispatchEvent(event);
            }else {
                // console.log('this.notesData-->'+notesData);
                let result = await saveLeadNotesFromCase({recId :this.recordId ,notesData: notesData });
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
                            const dataMessage = {
            sourceSystem: "Note Inserted'"
        };

publish(this.context, DATATOLEADHISTORY, dataMessage);

                } else{
                    console.error('ERROR-->');
                }

            }
        }catch (ex) {
            console.error('Error-->' + ex);
        }
    }
}