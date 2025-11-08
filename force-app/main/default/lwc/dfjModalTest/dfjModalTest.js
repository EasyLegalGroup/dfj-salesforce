import { LightningElement,api,track} from 'lwc';

export default class DfjModalTest extends LightningElement {
    @api heading = '';
    @api containsPicklist = false;
    @track displayModal = false;

    @api showModal(){
        this.displayModal = true;
    }

    @api hideModal(){
        this.displayModal = false;
    }

    closeModal(){
        this.hideModal();
        this.dispatchEvent(new CustomEvent('modalclose'));
    }

    get modalContainerStyle(){
        return `slds-modal__content slds-p-around_medium ${this.containsPicklist ? `picklistOverflowCss` : ``}`;
    }

}