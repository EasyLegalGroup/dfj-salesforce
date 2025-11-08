import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class DfJ_ConfirmationModal extends LightningModal {
    @api label;
    @api messageToShow;


    handleCancel(){
        this.close("false");
    }

    handleOkay() {
        this.close("true");
    }
}