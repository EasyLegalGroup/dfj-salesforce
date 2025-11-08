import {LightningElement, api} from 'lwc';
import getConsolidatedData from '@salesforce/apex/DFJ_ShowHistory_Apex.getConsolidatedData';

import {subscribe, unsubscribe, createMessageContext} from 'lightning/messageService';
import DATATOACCOUNTHISTORY from '@salesforce/messageChannel/data_to_Account_History_Message_Channel__c';

export default class DFJ_ShowHistoryComponent extends LightningElement {
    @api recordId;

    @api objectApiName;

    titleTextToShowAboveCurrentRecordHistory = null;
    currentRecordHistoryData = [];

    contactsWithHistoryData = [];

    context = createMessageContext();

    headingText = '';


    get isContactsWithHistoryDataEmpty() {
        return !this.isContactsWithHistoryDataAvailable;
    }

    get isContactsWithHistoryDataAvailable() {
        return this.contactsWithHistoryData && this.contactsWithHistoryData.length > 0;
    }

    get isCurrentRecordHistoryDataEmpty() {
        return !this.isCurrentRecordHistoryDataAvailable
    }

    get isCurrentRecordHistoryDataAvailable() {
        return this.currentRecordHistoryData && this.currentRecordHistoryData.length > 0;
    }


    connectedCallback() {
        this.titleTextToShowAboveCurrentRecordHistory = 'History Associated With ' + this.objectApiName;
        if (this.recordId && this.objectApiName === 'Account') {
            this.headingText = ' ( Demo ) Account History';
            this.getHistoryData();
        }

        this.subscription = subscribe(
            this.context,
            DATATOACCOUNTHISTORY,
            () => {
                this.getHistoryData();
            }
        );
    }

    disconnectedCallback() {
// Unsubscribe when the component is disconnected
        unsubscribe(this.subscription);
    }

    getHistoryData() {

        getConsolidatedData({
            recordId: this.recordId,
            objectName: this.objectApiName
        })
            .then(result => {
                if (result) {


                    this.currentRecordHistoryData = this.makeSobjectNameIdentifiersAndAddFormattedDateInHistoryDataAndSort(result.currentRecordHistoryData);

                    this.contactsWithHistoryData = this.makeSObjectNameIdentifiersInContactHistoryData(result.contactsWithHistoryData);

                }
            })
            .catch(error => {
                console.error("🚀️ ~ DFJ_ShowHistoryOnAccount ~ getHistoryData ~ error:", JSON.stringify(error.message));
            });
    }

    sortHistoryDataInDescendingOrder(listOfDataToShowInHistory) {

        return listOfDataToShowInHistory.sort((a, b) => {
            const dateA = new Date(a.record.CreatedDate);
            const dateB = new Date(b.record.CreatedDate);
            return dateB - dateA;
        });
    }

    makeSObjectNameIdentifiersInContactHistoryData(contactsWithHistoryData) {


        return contactsWithHistoryData.map(
            contactWithHistoryData => {
                let newContactWithHistoryData = JSON.parse(JSON.stringify(contactWithHistoryData));


                newContactWithHistoryData.listOfDataToShowInHistory = this.makeSobjectNameIdentifiersAndAddFormattedDateInHistoryDataAndSort(newContactWithHistoryData.listOfDataToShowInHistory)

                return newContactWithHistoryData;
            }
        )
    }

    makeSobjectNameIdentifiersAndAddFormattedDateInHistoryDataAndSort(listOfDataToShowInHistory) {
        let newListOfDataToShowInHistory = listOfDataToShowInHistory.map(
            item => {
                let formattedDateValue = this.getFormattedDate(item.record.CreatedDate);

                return {
                    ...item,
                    isExpanded: false,
                    isNote: item.sobjectName === 'Note',

                    isEventHistory: item.sobjectName === 'EventHistory',
                    isFieldHistory: item.sobjectName === 'FieldHistory',

                    fieldHistoryIconName: item.sobjectName === 'FieldHistory' ?
                        item.record.NewValue === 'Not Interested' ? 'standard:campaign' :
                            item.record.NewValue === 'Don\'t have time right now' ? 'standard:recent'
                                : item.record.NewValue === 'No answer or voicemail' ? 'standard:loop' : item.record.NewValue === 'Number busy' ? 'standard:operating_hours' : item.record.NewValue === 'Got appointment' ? 'standard:task2' :
                                    item.record.NewValue === 'Unqualified' ? 'standard:first_non_empty' : 'standard:sales_path' : 'standard:sales_path',

                    isCallHistory: item.sobjectName === 'telegenta__Telegenta_Call_History__c',

                    isOutbound: item.sobjectName === 'telegenta__Telegenta_Call_History__c' && (item.record.telegenta__Direction__c === 'OUTBOUND' || item.record.telegenta__Direction__c === 'OUTGOING'),

                    isInbound: item.sobjectName === 'telegenta__Telegenta_Call_History__c' && (item.record.telegenta__Direction__c === 'INBOUND' || item.record.telegenta__Direction__c === 'INCOMING'),

                    isCallCampaignStateHistory: item.sobjectName === 'telegenta__Call_Campaign_State__History',
                    isCallCampaignNewValueEmpty: item.sobjectName === 'telegenta__Call_Campaign_State__History' && (item.record.OldValue === '' || item.record.NewValue === ''),
                    record: {
                        ...item.record,
                        formattedDate: formattedDateValue,
                        StartDateTime: this.getFormattedDate(item.record.StartDateTime),
                        EndDateTime: this.getFormattedDate(item.record.EndDateTime),
                        telegenta__Active_Duration__c: this.convertDurationToReadableFormat((item.record.telegenta__Active_Duration__c) * 1000)
                    }
                }
            }
        );

        return this.sortHistoryDataInDescendingOrder(newListOfDataToShowInHistory);
    }

    convertDurationToReadableFormat( milliSeconds ){
        try {
            let finalStr = '';
            if (milliSeconds && milliSeconds > 0) {
                let seconds = Math.floor(milliSeconds / 1000);

                let hour = Math.floor(seconds / 3600);

                seconds = seconds % 3600;

                let minutes = Math.floor((seconds % 3600) / 60);

                seconds = seconds % 60;

                finalStr += (hour === 0 ? '00' + ':' : (hour >= 10 ? hour + ':' : '0' + hour + ':'));

                finalStr += (minutes === 0 ? '00' + ':' : (minutes >= 10 ? minutes + ':' : '0' + minutes + ':'));

                finalStr += (seconds >= 10 ? seconds : '0' + seconds);
            } else {
                finalStr = '00:00:00';
            }
            return finalStr;
        } catch (e) {
            console.error("🚀️ Error in ~ DFJ_ShowHistoryComponent ~ convertDurationToReadableFormat() :", JSON.stringify(e.message));
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

    handleToggleDetails(event) {
        const itemIndex = parseInt(event.target.dataset.indexofcurrenthistorydata);
        if (itemIndex !== -1) {

            this.currentRecordHistoryData = this.currentRecordHistoryData.map((value, index) => {
                if (index === itemIndex) {

                    return {
                        ...value,
                        isExpanded: !(value.isExpanded)
                    }
                }

                return value;
            })

        }
    }

    handleIsExpandedToggleForHistoryDataOfChildObject(event) {
        const itemIndex = parseInt(event.target.dataset.indexofcurrenthistorydata);
        if (itemIndex !== -1) {

            this.contactsWithHistoryData = this.contactsWithHistoryData.map((value) => {
                let newListOfDataToShowInHistory = value.listOfDataToShowInHistory;

                newListOfDataToShowInHistory = newListOfDataToShowInHistory.map(
                    (value, index) => {
                        if (index === itemIndex) {
                            return {
                                ...value,
                                isExpanded: !(value.isExpanded)
                            }
                        }
                        return value;
                    }
                )

                value.listOfDataToShowInHistory = newListOfDataToShowInHistory;

                return value;
            })

        }
    }
}