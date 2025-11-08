import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import getAppointmentConfigurations from '@salesforce/apex/DFJ_AppointmentController_Apex.getAppointmentConfigurations';
import saveAccountAndEventInformation from '@salesforce/apex/DFJ_AppointmentController_Apex.saveAccountAndEventInformation';
import LOCALE from "@salesforce/i18n/locale";
import TIMEZONE from "@salesforce/i18n/timeZone";


const accountFieldsToReset = {
    Id: '',
    Meeting_Type__c: '',
    Sales_meeting__c: '',
    Legal_assistance__c: '',
    Send_SMS_Reminders__c: 'No',
    Service_call__c: ''
};
const eventFieldsToReset = {
    StartDateTime: '',
    Subject: '',
    Journal__c: '',
    OwnerId: '',
    WhatId: '',
    EndDateTime: '',
    Account__c: ''
};
export default class AccountAppointmentSetup extends LightningElement {
    accountFields = {
        Id: this.recordId,
        Meeting_Type__c: '',
        Sales_meeting__c: '',
        Legal_assistance__c: '',
        Send_SMS_Reminders__c: '',
        Service_call__c: ''
    };
    eventFields = {
        StartDateTime: '',
        Subject: '',
        Journal__c: '',
        OwnerId: '',
        WhatId: '',
        EndDateTime: '',
        Account__c: ''
    }

    Eventsdata = {}
    meetingTypeOptions = [];
    legalAssistanceOptions = [];
    salesMeetingOptions = [];
    serviceCallOptions = [];
    sendSMSReminderOptions = [];
    startTimehour;
    @track currentuserId = Id;
    @track smsValue = 'No';
    @track appointmentdata = [];
    crrUserValue;
    dateTimevalue;
    descriptionvalue;
    @track timeDuration = 30;
    @api recordId;
    showAppointmentButton = false;
    showNextButton = true;
    formattedDate;
    timeZone;
    inputStartdate;
    @track appointmentOptions = [
        {
            label: '10',
            value: 10
        },
        {
            label: '20',
            value: 20
        },
        {
            label: '30',
            value: 30
        },
        {
            label: '40',
            value: 40
        },
        {
            label: '50',
            value: 50
        },
        {
            label: '60',
            value: 60
        },
        {
            label: '90',
            value: 90
        }
    ];
    accountFieldString = {};
    meetingTypeSelectedValue = '';
    legalAssistanceTypeSelectedValue = '';
    serviceTypeSelectedValue = '';
    salesTypeSelectedValue = '';
    smsReminderSelectedValue = '';
    showLegalAssistanceTypePicklist = false;
    showServiceTypePicklist = false;
    showSalesTypePicklist = false;
    showQuestions = false;
    showAppointmentModal = false;
    userOptions = [];
    @track accountToUpdate = { 'Id': this.recordId, 'Send_SMS_Reminders__c': this.smsValue, 'Meeting_Type__c': '' };


    connectedCallback() {
        this.showQuestions = true;
        this.getAppointmentConfigurationsHelper();
    }

    async getAppointmentConfigurationsHelper() {
        await getAppointmentConfigurations().then(result => {
            if (result) {
                this.meetingTypeOptions = result.meetingTypeOptions;
                this.legalAssistanceOptions = result.legalAssistanceOptions;
                this.salesMeetingOptions = result.salesMeetingOptions;
                this.serviceCallOptions = result.serviceCallOptions;
                this.sendSMSReminderOptions = result.sendSMSReminderOptions;
                result.UserList.forEach(element => {
                    this.userOptions.push({ label: element.Name, value: element.Id });
                    if (element.Id === this.currentuserId) {
                        this.crrUserValue = element.Id;
                        this.eventFields.OwnerId = this.currentuserId;
                    }
                });
                this.userOptions?.sort((a, b) =>
                    a.label.localeCompare(b.label));
            }
        })
    }

    handleButtonClick() {
        this.template.querySelector('[id*=test-modal]').showModal();
    }

    closeModal() {
        this.template.querySelector('[id*=test-modal]').hideModal();
        this.resetValues();
        this.handleEventReset();
    }


    handlePicklistChange(event) {
        const selectedPickList = event.target.name;
        const selectedValue = event.target.value;
        this.accountFields[selectedPickList] = selectedValue;
        this.accountToUpdate[selectedPickList] = selectedValue;
        if (this.accountFields['Meeting_Type__c'] === 'Sales meeting') {
            this.hideShowBasedOnMeetingType(true, false, false);
        } else if (this.accountFields.Meeting_Type__c === 'Service call') {
            this.hideShowBasedOnMeetingType(false, true, false);
        } else if (this.accountFields.Meeting_Type__c === 'Legal assistance') {
            this.hideShowBasedOnMeetingType(false, false, true);
        }
        this.accountFields['Id'] = this.recordId;
    }


    hideShowBasedOnMeetingType(showSales, showService, showLegalAssistance) {
        this.showServiceTypePicklist = showService;
        this.showSalesTypePicklist = showSales;
        this.showLegalAssistanceTypePicklist = showLegalAssistance;
    }

    handleAppointmentModalChange(event) {
        let selectedField = event.target.name;
        let selectedValue = event.target.value;
        if (selectedField === 'appointmentSelect') {
            this.timeDuration = parseInt(selectedValue);
        } else {
            this.eventFields[selectedField] = selectedValue;
        }
    }

    handleChange(event) {
        this.crrUserValue = event.target.value;
        const selectedPickList = event.target.name;
        const selectedValue = event.target.value;
        this.Eventsdata.OwnerId = selectedValue;
    }
    navigateToNextWindow() {
        try {
            if (this.accountFields.Meeting_Type__c === '' || (this.accountFields.Sales_meeting__c === '' && this.accountFields.Service_call__c === '' && this.accountFields.Legal_assistance__c === '')) {
                this.showToast('Error', 'Please populate the required values', 'Error');
                return;
            }
            this.showAppointmentButton = true;
            this.showNextButton = false;
            let accountFieldString = {};
            this.accountFieldString = accountFieldString;
            this.showQuestions = false;
            this.showAppointmentModal = true;
            this.handleEventReset();
        } catch (error) {
            console.log(error);
        }
    }

    resetValues() {
        this.accountFields = accountFieldsToReset;
        this.showLegalAssistanceTypePicklist = false;
        this.showServiceTypePicklist = false;
        this.showSalesTypePicklist = false;
    }

    handleDateChange(event) {
      try {
        
        if(event.target.name == 'startDate'){
            this.dateTimevalue = event.target.value;
            let startDate = event.target.value;
            this.inputStartdate = startDate;
        }else if(event.target.name == 'StartTime'){
            let startTime = event.target.value;
            this.startTimehour = startTime; 
        }
      } catch (error) {
        console.error('error :: ', error);
      }
             
    }
    DescriptionChange(event) {
        this.descriptionvalue = event.target.value;
        this.Eventsdata.Subject = this.descriptionvalue;
    }
    handleDuration(event) {
        try {

            const selectedValue = event.target.value;
            this.timeDuration = parseInt(selectedValue);
        } catch (error) {
            console.error('error :: ', error);
        }
    }


    handleDurationHandler(event) {
        // const selectedPickList = event.target.name;
        try {

            const selectedValue = event.target.value;
            this.timeDuration = parseInt(selectedValue);
        } catch (error) {
            console.error('error :: ', error);
        }
    }

    handleSave() {
        if (!this.accountToUpdate.Meeting_Type__c && (!this.accountToUpdate.Sales_meeting__c || !this.accountToUpdate.Service_call__c || !this.accountToUpdate.Legal_assistance__c)||(!this.startTimehour)||(!this.inputStartdate)) {
            this.showToast('Error', 'Please populate the required values', 'Error');
            return;
        }

        saveAccountAndEventInformation({ accountData: JSON.stringify(this.accountToUpdate), eventData: JSON.stringify(this.Eventsdata), accountId: this.recordId, timeDuration: this.timeDuration, startTime: this.Eventsdata.StartDateTime, startHours: this.startTimehour ,inputStartdate: this.inputStartdate})
            .then(result => {
                this.Eventsdata = {};
                this.accountToUpdate = Object.assign({}, { 'Id': this.recordId, 'Meeting_Type__c': '', 'Send_SMS_Reminders__c': 'No' });
                this.showToast('Success', 'Event added successfully', 'Success');
                this.showNextButton = true;
                this.showAppointmentButton = false;
                this.showQuestions = true;
                this.showAppointmentModal = false;
                this.resetValues();
                this.handleEventReset();
                const temp = [];
                this.appointmentdata=[...temp];
            })
            .catch(error => {
                this.error = error.message;
                console.error('error ::: ', error.message);
            });
        this.template.querySelector('[id*=test-modal]').hideModal();
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
    handleEventReset(){
        this.template.querySelectorAll('lightning-input[data-id="reset"]').forEach(element => {
            element.value = null;
        });
        this.template.querySelectorAll('lightning-combobox[data-id="reset"]').forEach(element => {
            element.value = null;
        });
        this.template.querySelectorAll('lightning-textarea[data-id="reset"]').forEach(element => {
            element.value = null;
        });
    }
}