import { LightningElement,track,api} from 'lwc';
import fetchConsolidatedViewData from '@salesforce/apex/AccountHistoryOnCase_Apex.fetchConsolidatedViewData';
import { subscribe, unsubscribe, createMessageContext } from 'lightning/messageService';
import DATATOACCOUNTHISTORY from '@salesforce/messageChannel/data_to_Account_History_Message_Channel__c';
export default class dfj_AccountHistoryOnCase extends LightningElement {
@track headingText;
@api recordId;
@api objectApiName;
@track consolidatedData = [];
@track ifHasconsolidatedData = false;
@track noHistoryOnAccount = false;
@track isEventHistory = false;
@track isTaskkHistory = false;
@track isCallHistory = false;
@track isEmailHistory = false;
@track isFieldsHistory = false;
@track isNoteHistory = false;
@track isCallCampaignState = false;
context = createMessageContext();

connectedCallback(){
if(this.recordId!=null && this.objectApiName=='Case'){

this.headingText = 'Account History';
this.getAccHistory();
}
this.subscription = subscribe(
this.context,
DATATOACCOUNTHISTORY,
(message) => {
    // Function to execute on account insertion
    // console.log("message>>"+message);
    this.getAccHistory();            }
);
}
disconnectedCallback() {
// Unsubscribe when the component is destroyed
unsubscribe(this.subscription);
}


getAccHistory() {
    fetchConsolidatedViewData({ recId: this.recordId })
        .then(result => {
          //  this.ifHasconsolidatedData= true;
            // console.log('d  ' + JSON.stringify(result));
            if (Object.keys(result).length === 0) {
                this.noHistoryOnAccount= true;
                // console.log('this.ifHasconsolidatedData= false;-->'+this.ifHasconsolidatedData);
            }else{
                this.ifHasconsolidatedData= true;
                this.noHistoryOnAccount= false;
        //    console.log('this.ifHasconsolidatedData-->'+this.ifHasconsolidatedData);
            this.consolidatedData = result.map(item => ({
                ...item,
                formattedDate: this.getFormattedDate(item.objectData.CreatedDate),
                isExpanded: false,
                objectData: {
                                    ...item.objectData,
                                    telegenta__Active_Duration__c: this.convertMilsecToReadableFormat(item.objectData.telegenta__Active_Duration__c * 1000),
                                },                   
              //  isEventHistory: item.sobjectName === 'EventHistory',
              //  isCallCampaignState: item.sobjectName === 'telegenta__Call_Campaign_State__c',
                isNoteHistory: item.sobjectName === 'NoteHistory',
               // isFieldsHistory: item.sobjectName === 'FieldsHistory',
               // isEmailHistory: item.sobjectName === 'EmailHistory',
                isCallHistory: item.sobjectName === 'CallHistory',
                isOutbound: item.sobjectName === 'CallHistory' && (item.objectData.telegenta__Direction__c === 'OUTBOUND' || item.objectData.telegenta__Direction__c === 'OUTGOING'),
                isInbound: item.sobjectName === 'CallHistory' && (item.objectData.telegenta__Direction__c === 'INBOUND' || item.objectData.telegenta__Direction__c === 'INCOMING'),
               // isTaskkHistory: item.sobjectName === 'TaskHistory'
            }));


            // Sort the consolidatedData array based on formattedDate in descending order
            this.consolidatedData.sort((a, b) => {
                // Convert formattedDate to Date objects for comparison
                const dateA = new Date(a.objectData.CreatedDate);
                const dateB = new Date(b.objectData.CreatedDate);

                // Compare dates in descending order
                return dateB - dateA;
            });

            // Access other properties similarly
            // console.log('datas   >>>' + JSON.stringify(this.consolidatedData));
            // console.log('this.dropDownData' + this.dropDownData); 
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