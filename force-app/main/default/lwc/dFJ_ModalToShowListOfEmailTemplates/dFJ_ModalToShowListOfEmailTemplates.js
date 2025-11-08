import LightningModal from 'lightning/modal';
import getEmailTemplatesByFolderName from '@salesforce/apex/DFJ_ChatComponent_Apex.getEmailTemplatesByFolderName';
import getRenderedEmailTemplate from '@salesforce/apex/DFJ_ChatComponent_Apex.getRenderedEmailTemplate';
import {api, wire} from "lwc";

export default class DFJ_ModalToShowListOfEmailTemplates extends LightningModal {
    folderName = "SMS Templates";

    @api recordId; // Record ID passed from parent component

    listOfEmailTemplates;

    selectedEmailTemplateId;
    selectedTemplatePreview = '';
    renderedTemplateText = ''; // Stores the fully parsed template text

    @wire(getEmailTemplatesByFolderName) wiredListOfEmailTemplates({error, data}){
        if (data){
            this.listOfEmailTemplates = data;
        }
    }

    get isOptionsForEmailTemplateSelectionAvailable(){
        if (this.optionsForEmailTemplateSelection){
            return true;
        }
        return false;
    }

    get optionsForEmailTemplateSelection(){


        if (this.listOfEmailTemplates){
            let result=[];

            for (const currentEmailTemplate of this.listOfEmailTemplates) {
                let option = {};
                
                // Just show template name in the radio button
                option.label = currentEmailTemplate.Name;
                option.value = currentEmailTemplate.Id;

                result.push(option);
            }


            return result;
        }
        else {
            return null;
        }
    }

    async logSelectedEmailTemplateValue(event){
        this.selectedEmailTemplateId = event.target.value;
        
        // Fetch the rendered (parsed) template with merge fields resolved
        if (this.selectedEmailTemplateId && this.recordId) {
            try {
                const renderedText = await getRenderedEmailTemplate({
                    emailTemplateId: this.selectedEmailTemplateId,
                    recordId: this.recordId
                });
                
                if (renderedText) {
                    this.renderedTemplateText = renderedText;
                    this.selectedTemplatePreview = renderedText;
                } else {
                    this.selectedTemplatePreview = '';
                    this.renderedTemplateText = '';
                }
            } catch (error) {
                console.error('Error rendering template:', error);
                this.selectedTemplatePreview = 'Error loading template preview';
                this.renderedTemplateText = '';
            }
        } else {
            this.selectedTemplatePreview = '';
            this.renderedTemplateText = '';
        }
    }

    handleOkay() {
        // Return the rendered (parsed) template text instead of just the template ID
        this.close(this.renderedTemplateText);
    }
}