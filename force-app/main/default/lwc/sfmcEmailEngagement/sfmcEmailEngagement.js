import { LightningElement, track, api } from 'lwc';

export default class SfmcEmailEngagement extends LightningElement {
    @api recordId;
    @api testRecordId;
    @track sentCount = 0;
    @track openCount = 0;
    @track clickCount = 0;
    @track isLoading = true;
    @track hasData = false;
    @track error;

    get effectiveRecordId() {
        // Use the record ID if available, otherwise use test ID, finally fallback to hardcoded ID
        const id = this.recordId || this.testRecordId || '00QW500000Kmh5ZMAR';
        console.log('Using record ID:', id, 'recordId:', this.recordId, 'testRecordId:', this.testRecordId);
        return id;
    }

    connectedCallback() {
        this.loadEmailMetrics();
    }

    async loadEmailMetrics() {
        try {
            this.isLoading = true;
            this.error = undefined;
            console.log('Loading metrics for ID:', this.effectiveRecordId);

            // Updated to v62.0 to match component version
            const mcUrl = `/services/data/v62.0/connect/marketing-cloud/activity?subscriberKey=${this.effectiveRecordId}`;
            const response = await fetch(mcUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`Failed to fetch Marketing Cloud data: ${response.status} ${response.statusText}`);
            }

            const result = await response.json();
            console.log('MC Data:', result);

            // Process the results
            this.sentCount = 0;
            this.openCount = 0;
            this.clickCount = 0;

            if (result && result.length > 0) {
                result.forEach(activity => {
                    if (activity.subscriberKey === this.effectiveRecordId) {
                        this.sentCount++;
                        if (activity.opened) this.openCount++;
                        if (activity.clicked) this.clickCount++;
                    }
                });
                this.hasData = this.sentCount > 0;
            } else {
                console.log('No data found for subscriber key:', this.effectiveRecordId);
                this.hasData = false;
            }

        } catch (error) {
            console.error('Error loading email metrics:', error);
            this.error = error.message || 'Unknown error occurred while fetching metrics';
            this.hasData = false;
        } finally {
            this.isLoading = false;
        }
    }
}