import {api, LightningElement, wire} from 'lwc';
import dFJ_ModalToShowListOfEmailTemplates from "c/dFJ_ModalToShowListOfEmailTemplates"

import getSMSRecords from "@salesforce/apex/DFJ_ChatComponent_Apex.getSMSRecords"

import createOutgoingSMSRecord from "@salesforce/apex/DFJ_ChatComponent_Apex.createOutgoingSMSRecord"


import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import CHAT_COMPONENT_HEADER_LOGO from '@salesforce/resourceUrl/chat_Component_Header_Logo'


import getSMSDetails from '@salesforce/apex/DFJ_ChatComponent_Apex.getSMSDetails'
import getCustomerName from '@salesforce/apex/DFJ_ChatComponent_Apex.getCustomerName'
import markSMSAsRead from '@salesforce/apex/DFJ_ChatComponent_Apex.markSMSAsRead'
import getFieldValue from '@salesforce/apex/DFJ_ChatComponent_Apex.getFieldValue'


export default class DFJ_ChatComponent extends LightningElement {

    @api recordId;

    @api fieldNameFromWhichSendToDropdownValueIsSet;
    
    @api relatedRecordIdField = 'Id';
    
    @api additionalSmsLookupField; // Optional: API name of lookup field to fetch additional SMS records
    
    @api customerNameField = 'Name';

    sObjectName;
    headerLogoUrl = CHAT_COMPONENT_HEADER_LOGO;
    chatTextInputBoxValue = '';

    // variable to store SMS Object Records
    allSmsRecords = []; // Store all fetched SMS records
    smsRecordsToShow = []; // Filtered SMS records to display
    alphanumericSenderId;
    
    // Phone number filter modal
    showFilterModal = false;
    selectedPhoneFilter = 'All'; // Default to show all
    phoneFilterOptions = []; // Will be populated with unique phone numbers
    phoneFilterOptionsWithUnread = []; // Options with unread counts
    totalUnreadCount = 0; // Total unread messages across all numbers

    sendToOptionLabelsAndValues;
    defaultValueOfSendToOption;
    valueOfSendToOption;

    retrievedAlphanumericSenderId;
    valueOfSendFromOption;
    defaultValueOfSendFromOption;
    
    marketUnit;
    countryIsoCode;
    
    customerName = '';
    
    isLoading = false;

    get isShowMessageToNotifyOfNoExistingConversation() {
        return !this.isSmsRecordsToShowAvailable;
    }

    get isSmsRecordsToShowAvailable() {
        return this.smsRecordsToShow && this.smsRecordsToShow.length > 0;
    }

    get optionsForSendFromDropdown() {
        let temp = this.defaultValueOfSendFromOption;
        let retrievedAlphanumericSenderId = this.retrievedAlphanumericSenderId;
        return [
            {label: temp, value: temp},
            {label: retrievedAlphanumericSenderId, value: retrievedAlphanumericSenderId}
        ]
    };

    get optionsForSendToDropdown() {
        let res = [];

        let sendToOptionLabelsAndValues = this.sendToOptionLabelsAndValues;
        if (sendToOptionLabelsAndValues) {
            for (const label in sendToOptionLabelsAndValues) {
                res.push(
                    {
                        label: label + " ( " + sendToOptionLabelsAndValues[label] + " ) ",
                        value: sendToOptionLabelsAndValues[label]
                    }
                );
            }

            return res;
        }

        return null;
    }

    get isSendButtonDisabled() {
        return (!this.chatTextInputBoxValue || this.chatTextInputBoxValue === '' || this.isValueOfSendToOptionEqualsNull)
    }
    
    get sendButtonClass() {
        return this.isSendButtonDisabled ? 'send-btn disabled' : 'send-btn enabled';
    }

    get isValueOfSendToOptionEqualsNull() {
        return !this.valueOfSendToOption;
    }
    
    get filterStatusText() {
        if (this.selectedPhoneFilter === 'All') {
            return 'Showing all messages';
        } else {
            return `Filtered by ${this.selectedPhoneFilter}`;
        }
    }


    connectedCallback() {
    }

    renderedCallback() {
        this.scrollToTheBottomOfChatContainer();
    }

    @wire(getSMSDetails, {
        recordId: "$recordId",
        fieldName: "$fieldNameFromWhichSendToDropdownValueIsSet"
    }) wiredGetSMSDetails(value) {


        const {data, error} = value;
        if (data) {

            let smsRecords = data.smsRecords;
            this.allSmsRecords = smsRecords; // Store all records
            
            // Set sObjectName FIRST before any other operations that need it
            this.sObjectName = data.sObjectName;

            this.defaultValueOfSendFromOption = data.sendFromPhoneNumber;
            // initially set valueOfSendFromOption to defaultValueOfSendFromOption
            this.valueOfSendFromOption = this.defaultValueOfSendFromOption;

            this.defaultValueOfSendToOption = data.sendToOptionDefaultValue;
            this.valueOfSendToOption = this.defaultValueOfSendToOption;

            this.sendToOptionLabelsAndValues = data.sendToOptionLabelsAndValues;

            this.retrievedAlphanumericSenderId = data.alphanumericSenderId;
            
            this.marketUnit = data.marketUnit;
            this.countryIsoCode = data.countryIsoCode;
            
            // If this is a PersonAccount and relatedRecordIdField is still default, set to PersonContactId
            if (data.isPersonAccount && data.personContactId && this.relatedRecordIdField === 'Id') {
                this.relatedRecordIdField = 'PersonContactId';
            }
            
            // If additionalSmsLookupField is specified, fetch additional SMS records
            // (Must be called AFTER sObjectName is set)
            if (this.additionalSmsLookupField) {
                this.fetchAdditionalSmsRecords();
            } else {
                this.buildPhoneFilterOptions(smsRecords);
                this.updateSmsRecordsToShow(smsRecords);
            }
            
            // Load customer name
            this.loadCustomerName();

        }
        if (error) {
            console.error("🚀️ ~ DFJ_ChatComponent ~ wiredGetSMSDetails ~ error:", JSON.stringify(error));
        }
    }
    
    async loadCustomerName() {
        try {
            this.isLoading = true;
            const name = await getCustomerName({
                recordId: this.recordId,
                sObjectName: this.sObjectName,
                fieldName: this.customerNameField
            });
            this.customerName = name || 'Customer';
            this.isLoading = false;
        } catch (error) {
            console.error('Error loading customer name:', error);
            this.customerName = 'Customer';
            this.isLoading = false;
        }
    }
    
    async fetchAdditionalSmsRecords() {
        try {
            // Get the value of the lookup field
            const additionalRecordId = await getFieldValue({
                recordId: this.recordId,
                sObjectName: this.sObjectName,
                fieldName: this.additionalSmsLookupField
            });
            
            console.log(`Additional SMS Lookup Field: ${this.additionalSmsLookupField}, Value: ${additionalRecordId}`);
            
            if (additionalRecordId && additionalRecordId !== 'null' && additionalRecordId.length >= 15) {
                // Determine the sObject type from the additional record ID prefix
                const additionalSObjectName = this.getSObjectTypeFromId(additionalRecordId);
                
                console.log(`Fetching SMS from ${additionalSObjectName} (${additionalRecordId})`);
                
                // Fetch SMS records for the additional record
                const additionalSmsRecords = await getSMSRecords({
                    recordId: additionalRecordId,
                    sObjectName: additionalSObjectName
                });
                
                console.log(`Fetched ${additionalSmsRecords.length} SMS records from ${additionalSObjectName}`);
                
                // Merge with existing SMS records (avoid duplicates)
                const existingIds = new Set(this.allSmsRecords.map(sms => sms.Id));
                const newRecords = additionalSmsRecords.filter(sms => !existingIds.has(sms.Id));
                
                console.log(`Adding ${newRecords.length} new unique SMS records`);
                
                // FIXED: Merge records THEN sort by CreatedDate
                this.allSmsRecords = [...this.allSmsRecords, ...newRecords];
                this.sortSmsRecordsByCreatedDate();
            } else {
                console.log('No additional record ID found or field is empty/invalid');
            }
            
            // Now build filter options and update display
            this.buildPhoneFilterOptions(this.allSmsRecords);
            this.updateSmsRecordsToShow(this.allSmsRecords);
        } catch (error) {
            console.error('Error fetching additional SMS records:', error);
            // Continue with existing records even if additional fetch fails
            this.buildPhoneFilterOptions(this.allSmsRecords);
            this.updateSmsRecordsToShow(this.allSmsRecords);
        }
    }
    
    /**
     * Sort all SMS records by CreatedDate (oldest to newest)
     */
    sortSmsRecordsByCreatedDate() {
        this.allSmsRecords.sort((a, b) => {
            const dateA = new Date(a.CreatedDate);
            const dateB = new Date(b.CreatedDate);
            return dateA - dateB; // Ascending order (oldest first)
        });
    }
    
    /**
     * Helper method to determine sObject type from record ID prefix
     * @param {String} recordId - The Salesforce record ID
     * @return {String} The sObject API name (e.g., 'Account', 'Lead', 'Contact')
     */
    getSObjectTypeFromId(recordId) {
        if (!recordId || recordId.length < 3) {
            return null;
        }
        
        // Salesforce record ID prefixes
        const prefixMap = {
            '001': 'Account',
            '003': 'Contact',
            '00Q': 'Lead',
            '006': 'Opportunity',
            '500': 'Case',
            // Add more as needed
        };
        
        const prefix = recordId.substring(0, 3);
        return prefixMap[prefix] || 'Unknown';
    }
    
    buildPhoneFilterOptions(smsRecords) {
        // Get our own phone numbers to exclude them
        const ourNumbers = new Set();
        if (this.defaultValueOfSendFromOption) {
            ourNumbers.add(this.defaultValueOfSendFromOption);
        }
        if (this.retrievedAlphanumericSenderId) {
            ourNumbers.add(this.retrievedAlphanumericSenderId);
        }
        
        // Extract unique customer phone numbers and count unread messages
        const phoneStats = new Map(); // Map of phone -> { unreadCount, totalCount }
        
        for (const sms of smsRecords) {
            let customerPhone = null;
            
            if (sms.Direction__c === 'Outgoing' && sms.To_Phone__c) {
                customerPhone = sms.To_Phone__c;
            } else if (sms.Direction__c === 'Incoming' && sms.From_Phone__c) {
                customerPhone = sms.From_Phone__c;
            }
            
            // Only process if it's not our own number
            if (customerPhone && !ourNumbers.has(customerPhone)) {
                if (!phoneStats.has(customerPhone)) {
                    phoneStats.set(customerPhone, { unreadCount: 0, totalCount: 0 });
                }
                const stats = phoneStats.get(customerPhone);
                stats.totalCount++;
                if (sms.Is_Read__c === false) {
                    stats.unreadCount++;
                }
            }
        }
        
        // Calculate total unread across all numbers (excluding current filter)
        let totalUnread = 0;
        phoneStats.forEach((stats, phone) => {
            if (phone !== this.selectedPhoneFilter) {
                totalUnread += stats.unreadCount;
            }
        });
        this.totalUnreadCount = totalUnread;
        
        // Build options array
        const options = [{ label: 'Show all messages', value: 'All' }];
        
        phoneStats.forEach((stats, phone) => {
            options.push({ 
                label: phone, 
                value: phone,
                unreadCount: stats.unreadCount
            });
        });
        
        this.phoneFilterOptions = options;
        this.buildPhoneFilterOptionsWithUnread();
    }
    
    buildPhoneFilterOptionsWithUnread() {
        // Build options with unread counts and selected state for modal
        this.phoneFilterOptionsWithUnread = this.phoneFilterOptions.map(option => {
            const isSelected = option.value === this.selectedPhoneFilter;
            return {
                ...option,
                iconClass: isSelected ? 'filter-option-icon-selected' : 'filter-option-icon-hidden',
                unreadCount: option.unreadCount || 0
            };
        });
    }
    
    handleFilterIconClick() {
        this.buildPhoneFilterOptionsWithUnread(); // Refresh options before showing modal
        this.showFilterModal = true;
    }
    
    handleCloseFilterModal() {
        this.showFilterModal = false;
    }
    
    handleFilterOptionSelect(event) {
        const selectedValue = event.currentTarget.dataset.value;
        this.selectedPhoneFilter = selectedValue;
        this.applyPhoneFilter();
        this.showFilterModal = false;
    }
    
    async handleRefreshIconClick() {
        try {
            this.isLoading = true;
            await this.retrieveSMSRecordsFromDatabaseAndUpdateSmsRecordsToShow();
            this.scrollToTheBottomOfChatContainer();
            this.isLoading = false;
        } catch (error) {
            console.error('Error refreshing messages:', error);
            this.isLoading = false;
        }
    }

    async retrieveSMSRecordsFromDatabaseAndUpdateSmsRecordsToShow() {
        // Fetch main records
        let smsRecords = await this.handleGetSMSRecords();
        
        this.allSmsRecords = smsRecords; // Store all records
        
        // FIXED: If additional lookup field is configured, fetch those records too
        if (this.additionalSmsLookupField) {
            try {
                const additionalRecordId = await getFieldValue({
                    recordId: this.recordId,
                    sObjectName: this.sObjectName,
                    fieldName: this.additionalSmsLookupField
                });
                
                if (additionalRecordId && additionalRecordId !== 'null' && additionalRecordId.length >= 15) {
                    const additionalSObjectName = this.getSObjectTypeFromId(additionalRecordId);
                    
                    const additionalSmsRecords = await getSMSRecords({
                        recordId: additionalRecordId,
                        sObjectName: additionalSObjectName
                    });
                    
                    // Merge and remove duplicates
                    const existingIds = new Set(this.allSmsRecords.map(sms => sms.Id));
                    const newRecords = additionalSmsRecords.filter(sms => !existingIds.has(sms.Id));
                    
                    this.allSmsRecords = [...this.allSmsRecords, ...newRecords];
                    
                    // Sort merged records by CreatedDate
                    this.sortSmsRecordsByCreatedDate();
                }
            } catch (error) {
                console.error('Error fetching additional SMS during refresh:', error);
            }
        }
        
        this.buildPhoneFilterOptions(this.allSmsRecords); // Rebuild filter options
        this.applyPhoneFilter(); // Apply current filter
    }

    async handleGetSMSRecords() {
        let smsRecords = [];

        await getSMSRecords({
            recordId: this.recordId,
            sObjectName: this.sObjectName
        }).then(res => {
            smsRecords = res;
        }).catch(e => {
            console.error("🚀️ Error in ~ DFJ_ChatComponent ~ handleGetSMSRecords() :", JSON.stringify(e.message));
        })

        return smsRecords;
    }

    handleChangeOfSendFromDropdown(event) {
        this.valueOfSendFromOption = event.target.value;
    }
    
    applyPhoneFilter() {
        let filteredRecords = [];
        
        if (this.selectedPhoneFilter === 'All') {
            filteredRecords = this.allSmsRecords;
        } else {
            // Filter to show only messages to/from the selected phone number
            filteredRecords = this.allSmsRecords.filter(sms => {
                let customerPhone = null;
                
                if (sms.Direction__c === 'Outgoing' && sms.To_Phone__c) {
                    customerPhone = sms.To_Phone__c;
                } else if (sms.Direction__c === 'Incoming' && sms.From_Phone__c) {
                    customerPhone = sms.From_Phone__c;
                }
                
                // Trim and compare to handle any whitespace issues
                return customerPhone && customerPhone.trim() === this.selectedPhoneFilter.trim();
            });
        }
        
        console.log('Filter:', this.selectedPhoneFilter, 'Filtered records:', filteredRecords.length);
        
        this.updateSmsRecordsToShow(filteredRecords);
        
        // Mark displayed messages as read
        this.markDisplayedMessagesAsRead(filteredRecords);
    }

    handleChangeInTextInput(event) {
        this.chatTextInputBoxValue = event.target.value;
        
        // Auto-resize textarea like iPhone - only when content needs it
        const textarea = event.target;
        
        // Reset to single line first to get accurate scrollHeight
        textarea.style.height = '20px';
        
        // Check if content needs more than one line
        const scrollHeight = textarea.scrollHeight;
        const singleLineHeight = 20; // Our base height
        
        if (scrollHeight > singleLineHeight) {
            // Content needs more space, expand up to max
            const maxHeight = 100;
            const newHeight = Math.min(scrollHeight, maxHeight);
            textarea.style.height = newHeight + 'px';
        }
        // If scrollHeight <= singleLineHeight, keep it at 20px (already set above)
    }

    updateSmsRecordsToShow(SmsRecords) {
        let res = [];
        for (const currentSmsRecord of SmsRecords) {
            if (currentSmsRecord.Message__c) {

                let directionOfCurrentSmsRecord = currentSmsRecord.Direction__c;

                if (directionOfCurrentSmsRecord) {
                    let isIncoming = directionOfCurrentSmsRecord === "Incoming";
                    let isOutgoing = !isIncoming;

                    let createdDateToShowOnUI = this.formatDateTime(currentSmsRecord.CreatedDate);

                    res.push({
                        ...currentSmsRecord,
                        isIncoming: isIncoming,
                        isOutgoing: isOutgoing,
                        createdDateToShowOnUI: createdDateToShowOnUI
                    });
                }
            }
        }

        this.smsRecordsToShow = res;

    }

    formatDateTime(dateString) {
        const date = new Date(dateString);

        const day = String(date.getDate()).padStart(2, '0'); // Get day with leading zero
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const month = monthNames[date.getMonth()]; // Get month name
        const year = date.getFullYear(); // Get year

        // Get hours and minutes
        let hours = date.getHours();
        const minutes = String(date.getMinutes()).padStart(2, '0'); // Get minutes with leading zero
        const ampm = hours >= 12 ? 'PM' : 'AM'; // Determine AM/PM
        hours = hours % 12; // Convert to 12-hour format
        hours = (hours ? String(hours) : '12'); // If hour is 0, set to 12
        hours = hours.padStart(2, '0');

        return `${month} ${day} ${year} at ${hours}:${minutes} ${ampm}`;
    }

    handleChangeOfSendToDropdown(event) {
        this.valueOfSendToOption = event.target.value;
    }

    handleFileIconClickBelowChatInterface() {

        this.handleOpenModalToShowListOfEmailTemplates().then();
    }

    async handleOpenModalToShowListOfEmailTemplates() {

        await dFJ_ModalToShowListOfEmailTemplates.open({
            recordId: this.recordId // Pass recordId to modal for merge field parsing
        }).then(res => {
            // res now contains the fully parsed template text, not the template ID
            if (res) {
                // Update the reactive property
                this.chatTextInputBoxValue = res;
                
                // Wait for DOM to update, then update the textarea element and resize
                setTimeout(() => {
                    const textarea = this.template.querySelector('.message-input');
                    if (textarea) {
                        // Explicitly set the textarea value
                        textarea.value = res;
                        
                        // Trigger input event to ensure any listeners are notified
                        textarea.dispatchEvent(new Event('input', { bubbles: true }));
                        
                        // Reset to base height first
                        textarea.style.height = '20px';
                        // Calculate needed height
                        const scrollHeight = textarea.scrollHeight;
                        const singleLineHeight = 20;
                        if (scrollHeight > singleLineHeight) {
                            const maxHeight = 100;
                            const newHeight = Math.min(scrollHeight, maxHeight);
                            textarea.style.height = newHeight + 'px';
                        }
                    }
                }, 50);
            }
        }).catch(e => {
            console.error("🚀️ Error in ~ DFJ_ChatComponent ~ handleOpenModalToShowListOfEmailTemplates() :", JSON.stringify(e.message));
        });

        this.setFocusToChatInputTextArea();
    }

    setFocusToChatInputTextArea() {
    }

    async handleSendButtonClick() {
        try {
            if (this.isSendButtonDisabled) {
                return; // Don't send if disabled
            }
            
            if (!this.defaultValueOfSendFromOption) {
                this.showErrorToast("Error.", "Unable to fetch the Sender detail.")
            } else if (!this.valueOfSendToOption) {
                this.showErrorToast("Error.", "Unable to fetch the Recipient detail.")
            } else {
                // Show loading
                this.isLoading = true;
                
                // render value to plain text as its value is in html format
                const messageToSend = this.chatTextInputBoxValue.replace(/<[^>]*>/g, '');

                // Clear the input field BEFORE sending
                this.chatTextInputBoxValue = '';
                
                // Reset textarea to single line
                const textarea = this.template.querySelector('.message-input');
                if (textarea) {
                    textarea.value = '';
                    textarea.style.height = 'auto';
                }
                
                // Store message temporarily since we cleared the field
                const tempMessage = messageToSend;
                
                // Create SMS with the stored message
                await this.handleSMSRecordCreationWithMessage(tempMessage);
                
                // Refresh the display
                await this.retrieveSMSRecordsFromDatabaseAndUpdateSmsRecordsToShow();

                this.scrollToTheBottomOfChatContainer();
                
                // Hide loading
                this.isLoading = false;
            }
        } catch (e) {
            console.error("🚀️ Error in ~ DFJ_ChatComponent ~ handleRightArrowIconClick() :", JSON.stringify(e.message));
            this.isLoading = false;
        }
    }
    
    async handleSMSRecordCreationWithMessage(message) {
        if (this.defaultValueOfSendFromOption && this.valueOfSendToOption) {
            await createOutgoingSMSRecord({
                recordId: this.recordId,
                relatedRecordIdField: this.relatedRecordIdField,
                sendFromSelection: this.valueOfSendFromOption,
                toIdentifier: this.valueOfSendToOption,
                message: message,
                marketUnit: this.marketUnit,
                countryIsoCode: this.countryIsoCode
            });
        } else {
            console.error('Either this.defaultValueOfSendFromOption or this.valueOfSendToOption is null or undefined.');
        }
    }

    showErrorToast(title, message) {
        const event = new ShowToastEvent({
            message: message,
            mode: "dismissable",
            title: title,
            variant: "error"
        });

        dispatchEvent(event);
    }

    scrollToTheBottomOfChatContainer() {

        const chatContainer = this.template.querySelector('.messages-container');

        if (chatContainer) {
            chatContainer.scrollTop = chatContainer.scrollHeight;
        }
    }
    
    async markDisplayedMessagesAsRead(smsRecords) {
        try {
            // Get IDs of unread messages
            const unreadIds = smsRecords
                .filter(sms => sms.Is_Read__c === false)
                .map(sms => sms.Id);
            
            if (unreadIds.length > 0) {
                await markSMSAsRead({ smsIds: unreadIds });
                
                // Update local records to reflect read status
                this.allSmsRecords = this.allSmsRecords.map(sms => {
                    if (unreadIds.includes(sms.Id)) {
                        return { ...sms, Is_Read__c: true };
                    }
                    return sms;
                });
            }
        } catch (error) {
            console.error('Error marking messages as read:', error);
        }
    }
}