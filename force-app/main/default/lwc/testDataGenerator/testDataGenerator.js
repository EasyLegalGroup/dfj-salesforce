import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateTestData from '@salesforce/apex/TestDataGeneratorService.generateTestData';

export default class TestDataGenerator extends LightningElement {
    @track isGenerating = false;
    @track showResults = false;
    @track resultMessage = '';
    @track leadCount = 0;
    @track accountCount = 0;
    @track orderCount = 0;
    @track journalCount = 0;
    @track errorDetails = '';

    handleGenerateTestData() {
        this.isGenerating = true;
        this.showResults = false;
        this.errorDetails = '';

        // Call Apex method (no parameters needed)
        generateTestData()
            .then(results => {
                this.isGenerating = false;
                
                if (results && results.length > 0) {
                    const result = results[0];
                    
                    if (result.success) {
                        this.showResults = true;
                        this.resultMessage = result.message;
                        this.leadCount = result.leadCount;
                        this.accountCount = result.accountCount;
                        this.orderCount = result.orderCount;
                        this.journalCount = result.journalCount;
                        
                        // Show success toast
                        this.showToast('Success', 'Test data generated successfully!', 'success');
                    } else {
                        this.showResults = true;
                        this.resultMessage = result.message;
                        this.errorDetails = result.errorDetails;
                        
                        // Show error toast
                        this.showToast('Error', result.message, 'error');
                    }
                }
            })
            .catch(error => {
                this.isGenerating = false;
                this.showResults = true;
                this.resultMessage = 'Error generating test data';
                this.errorDetails = error.body ? error.body.message : error.message;
                
                // Show error toast
                this.showToast('Error', 'Failed to generate test data', 'error');
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    get isSuccess() {
        return this.showResults && !this.errorDetails;
    }

    get isError() {
        return this.showResults && this.errorDetails;
    }
}
