import { LightningElement,track,wire,api } from 'lwc';
import getAllRelatedEvents from '@salesforce/apex/DFJ_EventController.getAllRelatedEvents';
const columnList = [
    {label: 'TIME', fieldName: 'TIMEE'},
    {label: 'EVENT', fieldName: 'EVENTE'},
];
export default class CalenderAppointments extends LightningElement {
    @track accountList;
    @track columnList = columnList;
    @track error;
    @api appointmentdata = [];
    @api currentuserId;
    @api recordId;
    @api changeduserid;
    @track _selectedUser;
    _selectedDateTime;
    activityTime;
    eventOwner;

    connectedCallback(){
        // console.log('variable:21selectedUser',this._selectedUser);
    }

    getAllEvents(){
        if (this.selectedDateTime && this.selectedUser) {
            getAllRelatedEvents({selectedDateTime : this.selectedDateTime,selectedUserId: this.selectedUser})
            .then(result =>{
                
                const eventDataToShow = [];
                result.forEach(element => {
                    eventDataToShow.push({'EVENTE': element.eventName , 'TIMEE': ` ${element.eventStartTime.split(' ')[1].split(':')[0]}.${element.eventStartTime.split(' ')[1].split(':')[1]} - ${element.eventEndTime.split(' ')[1].split(':')[0]}.${element.eventEndTime.split(' ')[1].split(':')[1]}`})
                });

                this.appointmentdata = eventDataToShow;

            })
        }
    }
    @api get selectedDateTime(){
        return this._selectedDateTime;
    }

    get dataNotPresent(){
        return !this.appointmentdata.length > 0
    }

   set selectedDateTime(value){
        let tempValue = value;
        this._selectedDateTime = tempValue;
        this.activityTime  = tempValue;
        this.getAllEvents();
        //this.handleDateChange(tempValue);
    }

    @api get selectedUser(){
        return this._selectedUser;
    }

    set selectedUser(value){
        let tempValue = value;
        this._selectedUser = tempValue;
        this.eventOwner = this._selectedUser; 
        this.getAllEvents();
        //this.handleDateChange(tempValue);
    }
    handleDateChange(){
        // console.log('variable:>>>>>');
        // console.log('selectedDateTime>>>>'+JSON.stringify(this.activityTime));
        // console.log('selectedUser>>>>'+JSON.stringify(this.eventOwner));
       
    }
}