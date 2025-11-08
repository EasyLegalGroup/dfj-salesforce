import { LightningElement , api, track, wire} from 'lwc';
import handleCancelEvent from '@salesforce/apex/DFJ_HandleEventCampaignStatus.handleCancelEvent';
import handleRescheduleEvent from '@salesforce/apex/DFJ_HandleEventCampaignStatus.handleRescheduleEvent';
import getAllHosts from '@salesforce/apex/DFJ_HandleEventCampaignStatus.getAllHosts';
import hostLocationChange from '@salesforce/apex/DFJ_HandleEventCampaignStatus.hostLocationChange';
//DFJ-159 Changes
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import CAMPAIGN_OBJECT from '@salesforce/schema/Campaign';
import REASON_FOR_CANCELLATION_FIELD from '@salesforce/schema/Campaign.Reason_for_Cancellation__c';
//End
//DFJ-176
import REASON_FOR_CANCELLATION_INPUT from '@salesforce/schema/Campaign.Reason_for_Cancellation_Input__c';
import REASON_FOR_LOCATION_CHANGE_INPUT from '@salesforce/schema/Campaign.Reason_for_Location_Change_Input__c';
import REASON_FOR_RESCHEDULING_INPUT from '@salesforce/schema/Campaign.Reason_for_Rescheduling_Input__c';
import REASON_FOR_RESCHEDULING_FIELD from '@salesforce/schema/Campaign.Reason_for_Rescheduling__c';
import REASON_FOR_LOCATION_CHANGE_FIELD from '@salesforce/schema/Campaign.Reason_for_Location_Change__c';
import getCurrentHostsEmail from '@salesforce/apex/DFJ_HandleEventCampaignStatus.getCurrentHostsEmail';
import name from '@salesforce/schema/Hosts__c.Name';
import Address from '@salesforce/schema/Hosts__c.Address__c';
import City from '@salesforce/schema/Hosts__c.City__c';
import Zip_Code from '@salesforce/schema/Hosts__c.Zip_Code__c';
import Country from '@salesforce/schema/Hosts__c.Country__c';
import Phone from '@salesforce/schema/Hosts__c.Phone__c';
import Email from '@salesforce/schema/Hosts__c.Email__c';
import Website from '@salesforce/schema/Hosts__c.Website__c';
import Capacity from '@salesforce/schema/Hosts__c.Capacity__c';
import Standard_Venue_Rental_Cost from '@salesforce/schema/Hosts__c.Standard_Venue_Rental_Cost__c';
import Standard_Price_Per_Cover from '@salesforce/schema/Hosts__c.Standard_Price_Per_Cover__c';
//DFJ-176 Changes
import Default_Invoicing_Agreement from '@salesforce/schema/Hosts__c.Default_Invoicing_Agreement__c';


import { FlowNavigationNextEvent } from 'lightning/flowSupport';
export default class Dfj_HandleEventAndCampaignStatus extends LightningElement {
    @api recordId;
    @track cancelConfirmationModal = false;
    @track rescheduleConfirmationModal = false;
    @api buttonClicked;
    @track changeLocationModal = false;
    @track hostOptions = [];
    @track selectedHostId;
    @track searchResults;
    @track filteredHostOptions = [];
    @track selectedSearchResult;
    @track handleNewHostModal = false;
    @track rescheduleTime = '';
    @track rescheduleDate ='';
    rescheduleDateTime = '';
    isHostSelected = false;
    displayMessage = '';
    buttonLabelOnDisplayMessage = '';
    @api objectApiName = 'Hosts__c';
    nameField = name;
    addressField = Address;
    cityField = City;
    zipCodeField = Zip_Code
    countryField = Country;
    phoneField = Phone; 
    emailField = Email;
    websiteField = Website; 
    capacityField = Capacity; 
    standardVenueCostField = Standard_Venue_Rental_Cost ;
    standardPriceCoverField = Standard_Price_Per_Cover; 
    //DFJ-176 Changes
    defaultInvoicingAgreementField = Default_Invoicing_Agreement; 
    //End
    @track hostsId;
    @track gethostId;
    //DFJ-159 Changes
    @track selectedReasonValue = '';
    @track reasonForCancelletionOptions = [];
    //End
     //DFJ-176 Changes
    currentHostEmail = '';
    reasonForReschedulingOptions = [];
    reasonForLocationChangeOptions = [];
    isNotifyHostChangeModal = false;
    notifyUsers = [];
    isNotifyHosts = false;
    isNotifyAttendees = false;
    notifyHosts = '';
    notifyAttendees = '';
    notifyNone = '';//Changes for notifyNone
    isNotifyNone = false;//Changes for notifyNone
    reasonForCancellationInput = false;
    reasonForCancellation = false;
    cancellationInputOptions = [];
    inputValue = '';
    writeTextCheckbox = false;
    selectFromPicklist = false;
    reschedulingInputOptions = [];
    locationChangeInputOptions = [];
    writeTextValue = '';
    @api flowInputNotifyAttendees = false;
    @api flowInputNotifyHosts = false;
    newHostId = '';
    @track disableButtons = true;
    @track campaignsCurrentHostEmail='';
    showToastMessage = false;
    //Optimise
    @track picklistFieldReason = {};  //Optimise
    @track picklistFieldInput = {};  //Optimise
    @track disableCheckBoxGroup= false;
    @track isCheckedNotifyNone = false;
    @track allowSendingEmail = false;
    @track disableNoneCheckBox = false;    
     //End
    connectedCallback() {
      // Get the buttonClicked parameter from the URL
      const urlParams = new URLSearchParams(window.location.search);     
      this.buttonClicked = urlParams.get('buttonClicked');
      this.notifyHosts = this.buttonClicked ==='Cancel_Event' ? 'Notify Host of Cancellation': this.buttonClicked ==='Reschedule_Event' ? 'Notify Host of Rescheduling' :this.buttonClicked ==='Change_Location' ? 'Notify Host of Location Change' : '';
      this.notifyAttendees = this.buttonClicked ==='Cancel_Event' ? 'Notify Attendees of Cancellation': this.buttonClicked ==='Reschedule_Event' ? 'Notify Attendees of Rescheduling' :this.buttonClicked ==='Change_Location' ? 'Notify Attendees of Location Change' : '';
      this.notifyNone = 'Do Not Notify';

      if(this.buttonClicked =='Cancel_Event'){
        //DFJ-176 Changes
       // this.notifyHosts = 'Notify Host of Cancellation';
     //   this.notifyAttendees = 'Notify Attendees of Cancellation';
       // this.notifyNone = 'None of the Above';//Changes for notifyNone
        this.picklistFieldReason = REASON_FOR_CANCELLATION_FIELD;  //Optimise
        this.picklistFieldInput = REASON_FOR_CANCELLATION_INPUT;  //Optimise
        //End
          this.cancelConfirmationModal = true;
      }else if(this.buttonClicked =='Reschedule_Event'){
        //DFJ-176 Changes
       // this.notifyHosts = 'Notify Host of Rescheduling';
      //  this.notifyAttendees = 'Notify Attendees of Rescheduling';
      //  this.notifyNone = 'None of the Above';//Changes for notifyNone
        this.picklistFieldReason = REASON_FOR_RESCHEDULING_FIELD;  //Optimise
        this.picklistFieldInput = REASON_FOR_RESCHEDULING_INPUT;  //Optimise
        //End
          this.rescheduleConfirmationModal = true;
      }else if(this.buttonClicked =='Change_Location'){
        //DFJ-176 Changes
       // this.notifyHosts = 'Notify Host of Location Change';
      //  this.notifyAttendees = 'Notify Attendees of Location Change';
     //   this.notifyNone = 'None of the Above';//Changes for notifyNone
        this.picklistFieldReason = REASON_FOR_LOCATION_CHANGE_FIELD;  //Optimise
        this.picklistFieldInput = REASON_FOR_LOCATION_CHANGE_INPUT;  //Optimise
        //End
          this.changeLocationModal = true;
          this.loadHostOptions();
      }
  }

  //DFJ-176 Changes


    get options() {
        return [
            { label: this.notifyHosts , value: 'notifyHosts' },
            { label: this.notifyAttendees , value: 'notifyAttendees' },
        ];
    }

    get selectedValues() {
        return this.notifyUsers.join(',');
    }
    handleCheckboxChange(event){
      this.isCheckedNotifyNone = event.detail.checked;
      if(this.isCheckedNotifyNone==true){
        this.notifyUsers = [];
        this.disableCheckBoxGroup = true;
        this.reasonForCancellationInput = true;
      }else{
        this.disableCheckBoxGroup = false;
      }
      this.updateButtonsState();
    }

    handleCheckboxGroupChange(event) {
        this.notifyUsers = event.detail.value;
        this.disableCheckBoxGroup = false;
        if(this.notifyUsers.length!=0){
          this.reasonForCancellationInput = true;
          if(this.campaignsCurrentHostEmail==='' && this.notifyUsers.includes('notifyHosts') ){
            this.showToastMessage = true;
          //  this.showToast('Alert','You cannot select “Notify Host" via email, since there\'s no email on the Host\'s contact','Warning');
          }else{
            this.showToastMessage = false;
          }
        }else{
          this.reasonForCancellationInput = false;
          this.showToastMessage = false;
        }
        this.updateButtonsState();
    }
  //End

//DFJ-159 Changes
  @wire(getObjectInfo, { objectApiName: CAMPAIGN_OBJECT })
    campaignObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$campaignObjectInfo.data.defaultRecordTypeId', fieldApiName: '$picklistFieldReason' })
    leadStatusPicklistValues({ data, error }) {
        if (data) {
          try {
            this.reasonForCancelletionOptions = data.values.map(item => ({
              label: item.label,
              value: item.value
          }));
        } catch(e){
            //error when handling result
        }
            
        } else if (error) {
            console.error('error--> '+error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$campaignObjectInfo.data.defaultRecordTypeId', fieldApiName: '$picklistFieldInput' })
    cancellationInputPicklistValues({ data, error }) {
        if (data) {
            this.cancellationInputOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('error--> '+error);
        }
    }



    //DFJ-176 Added methods to get picklist field values from Campaign Object.
    @wire(getCurrentHostsEmail, { campId: '$recordId' })
    wiredData({error, data}){
      if(data){
        if(data.campList!=null){
          this.campaignsCurrentHostEmail = data.campList.Email;
        }
        this.allowSendingEmail = data.allowSendingEmail;
        if(this.allowSendingEmail===false){
          this.disableCheckBoxGroup = true;
          this.disableNoneCheckBox = true;
          this.reasonForCancellationInput = true;
        }

      }else if(error){
        console.error('error--> '+error);
      }
    }
    //campaignsCurrentHostEmail;

    handleCancelReasonSelected(event) {
      this.inputValue = event.detail.value;
      if(this.inputValue === 'Select from picklist'){
        this.writeTextCheckbox = false;
        this.noReasonAdded = false;
        this.selectFromPicklist = true;
       // this.updateButtonsState();
      }else if(this.inputValue === 'Write text' ){
        this.selectFromPicklist = false;
        this.noReasonAdded = false;
        this.writeTextCheckbox = true;
       // this.updateButtonsState();

      }else if(this.inputValue === 'Don\'t add a reason'){
        this.selectFromPicklist = false;
        this.writeTextCheckbox = false;
        this.noReasonAdded = true;
       // this.updateButtonsState();       
      }
      this.updateButtonsState();
    }
    handleTextInput(event){
      this.writeTextValue = '';
      this.writeTextValue = event.target.value;
      this.selectedReasonValue='';
      this.updateButtonsState();

    }
    //End

handleReasonSelected(event) {
  this.selectedReasonValue = '';
  this.selectedReasonValue = event.detail.value;
  this.writeTextValue='';
  this.updateButtonsState();
}
//End

  //Host Change Button
  handleSuccess(event) {
      this.gethostId = event.detail.id;
      //changes DFJ-176 Changed the method execution
      this.isNotifyHostChangeModal = true;
      this.handleNewHostModal = false;
      
     // this.handleEventLocationChange();
    //  this.handleNewHostModal = false;
      // const navigateFinishEvent = new FlowNavigationFinishEvent();
      //     this.dispatchEvent(navigateFinishEvent);
  }

  updateButtonsState() {
   // this.disableButtons = ((this.writeTextValue!='' && this.writeTextCheckbox===true) || (this.selectedReasonValue!='' && this.selectFromPicklist===true));
    if(this.writeTextValue!='' && this.writeTextCheckbox==true && this.showToastMessage==false){
      this.disableButtons  = false;
     }else if(this.inputValue=='Don\'t add a reason' && this.reasonForCancellationInput ==true && this.showToastMessage==false){
      this.disableButtons  = false;
     }else if(this.selectedReasonValue!='' && this.selectFromPicklist ==true && this.showToastMessage==false){
      this.disableButtons  = false;
     }else{
      this.disableButtons  = true;
     }
}

  handleUpdateLocation(){
      
      if(this.buttonLabelOnDisplayMessage == 'Back'){
        this.handleBack();
        this.buttonLabelOnDisplayMessage = '';
      }else{
        this.gethostId = this.selectedSearchResult.value;
        this.isNotifyHostChangeModal = true;
        //this.updateButtonsState();
        //this.handleEventLocationChange();
      }
      
    }
//DFJ-176 Changes
    handleisNotifyHostChangeModal(){
        //this.gethostId = this.selectedSearchResult.value;
        this.handleEventLocationChange();
    }
//End
    handleEventLocationChange(){
      //DFJ-176 Changes Added params selectedReason in apex class
  this.selectedInputs.noReason = this.noReasonAdded;
  this.selectedInputs.reasonFromPickList = this.selectedReasonValue;
  this.selectedInputs.writeText = this.writeTextValue;
  this.selectedInputs.inputSelection = this.inputValue;
      hostLocationChange({campId :this.recordId, hostId : this.gethostId,selectedReason :this.selectedInputs}).then(result=>{
          if(result!=null || result.campList.length != 0){
              this.cancelConfirmationModal = false;
              this.rescheduleConfirmationModal = false;
              this.isNotifyHostChangeModal = false;
              //DFJ-176 Changes
              this.flowInputNotifyHosts = this.notifyUsers.includes('notifyHosts') ? true : false;
              this.flowInputNotifyAttendees = this.notifyUsers.includes('notifyAttendees') ? true : false;
//DFJ-176 added flow navigation
const navigateNextEvent = new FlowNavigationNextEvent();
this.dispatchEvent(navigateNextEvent);
              /*const navigateFinishEvent = new FlowNavigationFinishEvent();
              this.dispatchEvent(navigateFinishEvent);*/
          }
      })

    }
    handleBack(){
      this.isUpdateHostModal = false;
      this.changeLocationModal = true;
      
    }

    handleIsUpdateHostModal(){
      this.changeLocationModal = false;
      if(this.isHostSelected == true){
        this.isUpdateHostModal = true;
        this.displayMessage = 'Are you sure that you want to move this event to a new Host? ';
        this.buttonLabelOnDisplayMessage = 'Update Location';
      }else if(this.isHostSelected == false){
        this.isUpdateHostModal = true;
        this.displayMessage = 'Please Select a Host';
        this.buttonLabelOnDisplayMessage = 'Back';
      }       
    }

  get selectedValue() {
      return this.selectedSearchResult ? this.selectedSearchResult.label : null;
    }

  loadHostOptions(){
      getAllHosts()
      .then(result => {
          this.hostOptions = result.map(host => ({
              label: host.Name,
              value: host.Id,
              hostId: host.Host_ID__c
          }));
          this.filteredHostOptions = this.hostOptions;
          this.searchResults  = this.hostOptions;

      })
      .catch(error => {
          console.error('Error loading accounts:', error);
      });
      
  }

  search(event) {
    this.selectedSearchResult = null;
      const input = event.detail.value.toLowerCase();
      const result = this.hostOptions.filter((picklistOption) =>
        picklistOption.label.toLowerCase().includes(input)
      );
      
      this.searchResults = result;
      if(this.searchResults.length!=0 && this.selectedSearchResult!=null){
        this.isHostSelected = true;
      }else if(this.selectedSearchResult==null){
        this.isHostSelected = false;

      }

    }

    selectSearchResult(event) {
      const selectedValue = event.currentTarget.dataset.value;
      this.selectedSearchResult = this.hostOptions.find(
        (picklistOption) => picklistOption.value === selectedValue
      );
     
     if(this.selectedSearchResult){
      this.isHostSelected = true;
    }else if(!this.selectedSearchResult){
      this.isHostSelected = false;
    }
    this.clearSearchResults();
    }
  
    clearSearchResults() {
      this.searchResults = null;
    }
  
  showPicklistOptions() {
      if (!this.searchResults) {
        this.searchResults = this.hostOptions;
      }
    }

  handleCreateNewHost(){
      this.handleNewHostModal = true;
      this.changeLocationModal = false;
      this.gethostId = this.hostsId;
     // this.handleEventLocationChange();

    }
    handleOpenNewHostModal(){
      this.handleNewHostModal = false;
      //DFJ-176 added flow navigation
const navigateNextEvent = new FlowNavigationNextEvent();
this.dispatchEvent(navigateNextEvent);
     /* const navigateFinishEvent = new FlowNavigationFinishEvent();
          this.dispatchEvent(navigateFinishEvent);*/
    }

  closeModal() {
      this.cancelConfirmationModal = false;
      this.rescheduleConfirmationModal = false;

      this.changeLocationModal = false;
      this.isUpdateHostModal = false;
     //DFJ-176 added flow navigation
const navigateNextEvent = new FlowNavigationNextEvent();
this.dispatchEvent(navigateNextEvent);
     /* const navigateFinishEvent = new FlowNavigationFinishEvent();
          this.dispatchEvent(navigateFinishEvent);*/
  }
  //End

//Cancel Event Button

  handleCancelEvent() {
    //DFJ-176
    this.selectedInputs.noReason = this.noReasonAdded;
    this.selectedInputs.reasonFromPickList = this.selectedReasonValue;
    this.selectedInputs.writeText = this.writeTextValue;
    this.selectedInputs.inputSelection = this.inputValue;
    //End
  
    //DFJ-159 Changes added selectedReasonValue in class param
          handleCancelEvent({campId :this.recordId, selectedReason :this.selectedInputs}).then(result=>{
              if(result){
                  this.cancelConfirmationModal = false;
                  //DFJ-176 Changes
                  this.flowInputNotifyHosts = this.notifyUsers.includes('notifyHosts') ? true : false;
                  this.flowInputNotifyAttendees = this.notifyUsers.includes('notifyAttendees') ? true : false;
                  //DFJ-176 added flow navigation
              const navigateNextEvent = new FlowNavigationNextEvent();
              this.dispatchEvent(navigateNextEvent);
                /*  const navigateFinishEvent = new FlowNavigationFinishEvent();
                  this.dispatchEvent(navigateFinishEvent);*/

              }
          })
  } catch (error) {
      console.error('error console-->'+error);
  }

  //End

//Reschedule Event
handleRescheduleEvent() {
  //DFJ-176 Changes Added params selectedReason in apex class
  this.selectedInputs.noReason = this.noReasonAdded;
    this.selectedInputs.reasonFromPickList = this.selectedReasonValue;
    this.selectedInputs.writeText = this.writeTextValue;
    this.selectedInputs.inputSelection = this.inputValue;
      handleRescheduleEvent({campId :this.recordId, rescheduledateTime : this.rescheduleDateTime, selectedReason :this.selectedInputs}).then(result=>{
          if(result!=null || result.campList.length != 0 || result.eventList.length != 0 ){
              this.rescheduleConfirmationModal = false;
              //DFJ-176 Changes
              this.flowInputNotifyHosts = this.notifyUsers.includes('notifyHosts') ? true : false;
              this.flowInputNotifyAttendees = this.notifyUsers.includes('notifyAttendees') ? true : false;
              //DFJ-176 added flow navigation
              const navigateNextEvent = new FlowNavigationNextEvent();
                  this.dispatchEvent(navigateNextEvent);
              /*const navigateFinishEvent = new FlowNavigationFinishEvent();
              this.dispatchEvent(navigateFinishEvent);*/
          }
      })
} catch (error) {
  console.error('error console-->'+error);
}

handleDate(event){
  this.rescheduleDate = event.target.value;
}
handleTime(event){
  this.rescheduleTime = event.target.value;
}

handleDateTime(){
  this.rescheduleDateTime = this.rescheduleDate +' ' +this.rescheduleTime;
  this.handleRescheduleEvent();
}

//DFJ-176
selectedInputs = {
  "noReason" : false,
  "reasonFromPickList" : "",
  "writeText" : "",
  "inputSelection" : "",
}
//End
}