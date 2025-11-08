import { LightningElement,track,api } from 'lwc';
import fetchConsolidatedViewDataForLead from '@salesforce/apex/AccountHistoryOnCase_Apex.fetchConsolidatedViewDataForLead';
import { subscribe, unsubscribe, createMessageContext } from 'lightning/messageService';
import DATATOLEADHISTORY from '@salesforce/messageChannel/notesDataToLeadHistory_OnCase__c';

export default class Dfj_LeadHistoryOnCase extends LightningElement {
@track headingText;
@api recordId;
@api objectApiName;
@track consolidatedData = [];
@track ifHasconsolidatedData = false;
@track noHistoryOnLead = false;
@track isEventHistory = false;
@track isTaskkHistory = false;
@track isCallHistory = false;
@track isEmailHistory = false;
@track isFieldsHistory = false;
@track fieldsHistoryIconName = '';
@track isNoteHistory = false;
@track isCallCampaignState = false;
//@track isCallCampaignNewValueEmpty = false;
context = createMessageContext();

connectedCallback(){
if(this.recordId!=null && this.objectApiName=='Case'){

this.headingText = 'Lead History';
this.getLeadHistory();
}
this.subscription = subscribe(
this.context,
DATATOLEADHISTORY,
(dataMessage) => {
// Function to execute on account insertion
    console.log("message>>"+JSON.stringify(dataMessage));
this.getLeadHistory();            }
);
}
disconnectedCallback() {
// Unsubscribe when the component is destroyed
unsubscribe(this.subscription);
}


getLeadHistory() {
fetchConsolidatedViewDataForLead({ recId: this.recordId })
    .then(result => {
        //  this.ifHasconsolidatedData= true;
        console.log('d  ' + JSON.stringify(result));
        if (Object.keys(result).length === 0) {
            this.noHistoryOnLead= true;
        }else{
            this.ifHasconsolidatedData= true;
            this.noHistoryOnLead= false;
    //    console.log('this.ifHasconsolidatedData-->'+this.ifHasconsolidatedData);
        this.consolidatedData = result.map(item => ({
            ...item,
            formattedDate: this.getFormattedDate(item.objectData.CreatedDate),
                            isExpanded: false,

            objectData: {
                                ...item.objectData,
                                telegenta__Active_Duration__c: this.convertMilsecToReadableFormat(item.objectData.telegenta__Active_Duration__c * 1000),
                                StartDateTime: this.getFormattedDate(item.objectData.StartDateTime),
                                EndDateTime: this.getFormattedDate(item.objectData.EndDateTime),
                            },                   
            isEventHistory: item.sobjectName === 'EventHistory',
            isCallCampaignState: item.sobjectName === 'telegenta__Call_Campaign_State__c',
            isNoteHistory: item.sobjectName === 'NoteHistory',
            isFieldsHistory: item.sobjectName === 'FieldsHistory',
            isCallCampaignNewValueEmpty : item.sobjectName === 'telegenta__Call_Campaign_State__c' && ( item.objectData.OldValue==='' || item.objectData.NewValue===''),
            // isEmailHistory: item.sobjectName === 'EmailHistory',
            fieldsHistoryIconName :  item.sobjectName === 'FieldsHistory' ? item.objectData.NewValue === 'Not Interested' ? 'standard:campaign' : item.objectData.NewValue === 'Don\'t have time right now' ? 'standard:recent' : item.objectData.NewValue === 'No answer or voicemail' ? 'standard:loop'  : item.objectData.NewValue === 'Number busy' ? 'standard:operating_hours': item.objectData.NewValue === 'Got appointment' ? 'standard:task2': item.objectData.NewValue === 'Unqualified' ? 'standard:first_non_empty':'standard:sales_path' :'standard:sales_path',
            isCallHistory: item.sobjectName === 'CallHistory',
            isOutbound: item.sobjectName === 'CallHistory' && (item.objectData.telegenta__Direction__c === 'OUTBOUND' || item.objectData.telegenta__Direction__c === 'OUTGOING'),
            isInbound: item.sobjectName === 'CallHistory' && (item.objectData.telegenta__Direction__c === 'INBOUND' || item.objectData.telegenta__Direction__c === 'INCOMING'),
            //isTaskkHistory: item.sobjectName === 'TaskHistory'
        }));
console.log('isCallCampaignState-->'+JSON.stringify(this.consolidatedData));


        // Sort the consolidatedData array based on formattedDate in descending order
        this.consolidatedData.sort((a, b) => {
            // Convert formattedDate to Date objects for comparison
            const dateA = new Date(a.objectData.CreatedDate);
            const dateB = new Date(b.objectData.CreatedDate);

            // Compare dates in descending order
            return dateB - dateA;
        });

    }

    })
    .catch(error => {
        console.log('error-->' + JSON.stringify(error));
    });
}
handleToggleDetails(event) {
const id = event.target.dataset.id;
const itemIndex = this.consolidatedData.findIndex(item => item.objectData.Id === id);
if (itemIndex !== -1) {
    this.consolidatedData[itemIndex].isExpanded = !this.consolidatedData[itemIndex].isExpanded;
}
}


//Method to convert the DateTime format
getFormattedDate(createdDate) {
const date = new Date(createdDate);
const options = {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
    timeZone: 'Europe/Paris', // Set the desired time zone
};
return date.toLocaleString('en-US', options).replace(/(\d{2})\/(\d{2})\/(\d{4}), (\d{2}:\d{2}:\d{2})/, '$2-$1-$3 $4');
}

//Method to convert the Time format
convertMilsecToReadableFormat(milliSeconds) {
try {
    let finalStr = '';
    if (milliSeconds && milliSeconds > 0) { 
        let seconds = Math.floor(milliSeconds / 1000);
        let hour = Math.floor(seconds / 3600);
        seconds = seconds % 3600;
        let minutes = Math.floor((seconds % 3600) / 60);
        seconds = seconds % 60;

        finalStr += (hour = 0 ? '00:' : (hour >= 10 ? hour + ':' : '0' + hour + ':'));
        finalStr += (minutes = 0 ? '00:' : (minutes >= 10 ? minutes + ':' : '0' + minutes + ':'));
        finalStr += (seconds >= 10 ? seconds : '0' + seconds);
    } else {
        finalStr = '00:00:00';
    }
    return finalStr;
} catch (ex) {
    console.error(ex);
}
}

}