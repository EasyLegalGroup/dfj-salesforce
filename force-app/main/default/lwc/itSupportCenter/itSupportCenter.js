import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getUserInfo from '@salesforce/apex/ITSupportCenterController.getUserInfo';
import getCases from '@salesforce/apex/ITSupportCenterController.getCases';
import getCaseComments from '@salesforce/apex/ITSupportCenterController.getCaseComments';
import createCaseComment from '@salesforce/apex/ITSupportCenterController.createCaseComment';
import getITSupportRecordTypeId from '@salesforce/apex/ITSupportCenterController.getITSupportRecordTypeId';
import getLastUsedNotificationPreferences from '@salesforce/apex/ITSupportCenterController.getLastUsedNotificationPreferences';
import sendNotifications from '@salesforce/apex/ITSupportCenterController.sendNotifications';
import searchKnowledgeArticles from '@salesforce/apex/ITSupportCenterController.searchKnowledgeArticles';
import getKnowledgeArticleDetail from '@salesforce/apex/ITSupportCenterController.getKnowledgeArticleDetail';
import markCaseAsSolved from '@salesforce/apex/ITSupportCenterController.markCaseAsSolved';
import createChatterPost from '@salesforce/apex/ITSupportCenterController.createChatterPost';
import createChatterPostWithFiles from '@salesforce/apex/ITSupportCenterController.createChatterPostWithFiles';
import getChatterFeed from '@salesforce/apex/ITSupportCenterController.getChatterFeed';
import getEnhancedChatterFeed from '@salesforce/apex/ITSupportCenterController.getEnhancedChatterFeed';
import processRichTextForCaseDescription from '@salesforce/apex/ITSupportCenterController.processRichTextForCaseDescription';

// New UnifiedChat integration methods
import createCaseWithChatMessage from '@salesforce/apex/ITSupportCenterController.createCaseWithChatMessage';
import addCaseCommentViaChatMessage from '@salesforce/apex/ITSupportCenterController.addCaseCommentViaChatMessage';
import getCaseChatMessages from '@salesforce/apex/ITSupportCenterController.getCaseChatMessages';
import shouldUseChatIntegration from '@salesforce/apex/ITSupportCenterController.shouldUseChatIntegration';
import createMessage from '@salesforce/apex/ChatService.createMessage';

export default class ItSupportCenter extends NavigationMixin(LightningElement) {
    @api recordId;
    @track currentUserInfo;
    @track recordTypeId;
    @track newCase = {
        Subject: '',
        Description: '',
        Category__c: '',
        Severity__c: '',
        Notification_Preferences__c: 'Email'
    };
    @track selectedCaseId;
    @track selectedCase;
    @track viewState = 'NEW_TICKET';
    @track isLoading = false;
    @track chatterFeed = [];
    @track newComment = '';
    @track uploadedFileIds = [];
    @track caseUploadedFileIds = [];
    @track showOpenCases = true;
    @track currentCaseView = 'awaiting'; // Default to awaiting reply
    @track selectedNotificationPreference = 'Email'; // Default to Email

    // UnifiedChat integration properties
    @track useChatIntegration = true;
    @track showUnifiedChatForCase = false;
    @track caseChatMessages = [];

    // Knowledge Search Properties
    @track knowledgeSearchResults = [];
    @track isKnowledgeSearching = false;
    @track showKnowledgeResults = false;
    @track selectedKnowledgeArticle = null;
    @track showKnowledgeDetail = false;
    @track isSubmittingForm = false;
    @track allUserCases = []; // To store raw case data from server
    @track openCases = []; // Add missing property declaration
    @track closedCases = []; // Add missing property declaration
    searchTimeout;
    lastSearchTerm = '';

    // Accepted file formats
    acceptedFileFormats = ['.jpg', '.jpeg', '.png', '.gif', '.pdf', '.doc', '.docx', '.txt', '.xls', '.xlsx'];

    richTextFormats = [
        'font', 'size', 'bold', 'italic', 'underline', 'strike',
        'list', 'indent', 'align', 'link', 'image', 'clean', 'table', 
        'header', 'color', 'background', 'code', 'code-block', 'script',
        'blockquote', 'direction'
    ];

    categoryOptions = [
        { label: 'Customer Service', value: 'Customer Service' },
        { label: 'Technical Issue', value: 'Technical Issue' },
        { label: 'Refund Request', value: 'Refund Request' }
    ];

    severityOptions = [
        { 
            label: 'Severity 1: Critical production issue - business completely stopped or revenue impacted',
            value: 'Severity 1: Critical production issue - business completely stopped or revenue impacted'
        },
        { 
            label: 'Severity 2: Major functionality impacted and time-sensitive',
            value: 'Severity 2: Major functionality impacted and time-sensitive'
        },
        { 
            label: 'Severity 3: Minor functionality impacted and time-sensitive',
            value: 'Severity 3: Minor functionality impacted and time-sensitive'
        },
        { 
            label: 'Severity 4: General inquiry, how-to, or routine technical issue',
            value: 'Severity 4: General inquiry, how-to, or routine technical issue'
        }
    ];

    notificationOptions = [
        { label: 'Email Notifications', value: 'Email' },
        { label: 'Slack DM Notifications', value: 'Slack' }
    ];

    // Computed properties for tab styling
    get newTicketTabClass() {
        return this.viewState === 'NEW_TICKET' ? 'slds-tabs_scoped__link slds-is-active' : 'slds-tabs_scoped__link';
    }

    get myTicketsTabClass() {
        return this.viewState === 'MY_TICKETS' ? 'slds-tabs_scoped__link slds-is-active' : 'slds-tabs_scoped__link';
    }

    // View state getters
    get isNewTicketView() {
        return this.viewState === 'NEW_TICKET';
    }

    get isMyTicketsView() {
        return this.viewState === 'MY_TICKETS';
    }

    get isCaseDetailView() {
        return this.viewState === 'CASE_DETAIL';
    }

    // Button variants for case view toggle
    get awaitingReplyVariant() {
        return this.currentCaseView === 'awaiting' ? 'brand' : 'neutral';
    }

    get openCasesVariant() {
        return this.currentCaseView === 'open' ? 'brand' : 'neutral';
    }

    get closedCasesVariant() {
        return this.currentCaseView === 'closed' ? 'brand' : 'neutral';
    }

    // Case view display logic - These getters will now control which list is shown in the template
    get showAwaitingCasesView() {
        return this.currentCaseView === 'awaiting';
    }

    get showOpenCasesView() {
        return this.currentCaseView === 'open';
    }

    get showClosedCasesView() {
        return this.currentCaseView === 'closed';
    }

    // Combined getter for the list to display - Optimize to reduce calls
    get currentCaseListToDisplay() {
        switch (this.currentCaseView) {
            case 'awaiting':
                return this.processedAwaitingCases;
            case 'open':
                return this.processedOpenCases;
            case 'closed':
                return this.processedClosedCases;
            default:
                return [];
        }
    }

    get noCasesMessage() {
        if (this.currentCaseView === 'awaiting') return 'No cases awaiting reply';
        if (this.currentCaseView === 'open') return 'No open cases';
        if (this.currentCaseView === 'closed') return 'No closed cases';
        return '';
    }

    // Get filtered case arrays - Add caching to prevent excessive recalculation
    get awaitingCases() {
        if (!this.openCases || this.openCases.length === 0) {
            return [];
        }
        
        const awaiting = this.openCases.filter(c => {
            const status = c.Status ? c.Status.trim().toLowerCase() : '';
            return status === 'waiting for reply' || status === 'waiting for customer';
        });
        
        return awaiting;
    }

    get allOpenCases() {
        // Show ALL non-closed cases (this includes awaiting reply cases)
        return this.openCases || [];
    }

    // Computed properties for processed cases - Simplify to reduce getter calls
    get processedAwaitingCases() {
        return this.awaitingCases.map(ticket => ({
            ...ticket,
            statusClass: this.getCaseStatusClass(ticket.Status)
        }));
    }

    get processedOpenCases() {
        return this.allOpenCases.map(ticket => ({
            ...ticket,
            statusClass: this.getCaseStatusClass(ticket.Status)
        }));
    }

    get processedClosedCases() {
        return (this.closedCases || []).map(ticket => ({
            ...ticket,
            statusClass: 'case-status'
        }));
    }

    get formattedCreatedDate() {
        return this.selectedCase?.CreatedDate ? this.formatDate(this.selectedCase.CreatedDate) : '';
    }

    get formattedClosedDate() {
        return this.selectedCase?.Status === 'Closed' && this.selectedCase.LastModifiedDate 
            ? this.formatDate(this.selectedCase.LastModifiedDate) : '';
    }

    get showClosedDate() {
        return this.selectedCase?.Status === 'Closed';
    }

    get isSubmitDisabled() {
        return !this.newCase.Subject || 
               !this.newCase.Description || 
               !this.newCase.Category__c || 
               !this.newCase.Severity__c ||
               !this.newCase.Notification_Preferences__c ||
               this.isSubmittingForm ||
               this.isLoading;
    }

    get isAddCommentDisabled() {
        return !this.newComment?.trim();
    }

    get isMarkAsSolvedDisabled() {
        return !this.selectedCase || this.selectedCase.Status === 'Closed';
    }

    get showMarkAsSolvedButton() {
        return this.selectedCase && this.selectedCase.Status !== 'Closed';
    }

    get getSalesforceNotificationVariant() {
        return this.newCase.Notification_Preferences__c === 'Salesforce' ? 'brand' : 'neutral';
    }

    get getEmailNotificationVariant() {
        return this.newCase.Notification_Preferences__c === 'Email' ? 'brand' : 'neutral';
    }

    get getSlackNotificationVariant() {
        return this.newCase.Notification_Preferences__c === 'Slack' ? 'brand' : 'neutral';
    }

    // Computed properties for counters
    get waitingForReplyCount() {
        return this.openCases.filter(c => c.Status === 'Waiting for Reply').length;
    }

    get openCasesCount() {
        return this.openCases.length;
    }

    get closedCasesCount() {
        return this.closedCases.length;
    }

    get myTicketsLabel() {
        const waitingCount = this.waitingForReplyCount;
        return waitingCount > 0 ? `My Tickets (${waitingCount})` : 'My Tickets';
    }

    get awaitingReplyLabel() {
        const count = this.waitingForReplyCount;
        return count > 0 ? `Awaiting Reply (${count})` : 'Awaiting Reply';
    }

    get openCasesLabel() {
        const count = this.openCasesCount;
        return count > 0 ? `Open Cases (${count})` : 'Open Cases';
    }

    get closedCasesLabel() {
        const count = this.closedCasesCount;
        return count > 0 ? `Closed Cases (${count})` : 'Closed Cases';
    }

    // Computed properties for UnifiedChat integration
    get shouldShowUnifiedChatForCase() {
        return this.useChatIntegration && this.showUnifiedChatForCase && this.selectedCaseId;
    }

    get chatHeight() {
        return this.isCaseDetailView ? '800px' : '300px';
    }

    async connectedCallback() {
        await this.loadInitialData();
        
        // Check chat integration eligibility
        try {
            this.useChatIntegration = await shouldUseChatIntegration(null);
        } catch (error) {
            console.error('Error checking chat integration:', error);
            this.useChatIntegration = true; // Default to true
        }
    }

    renderedCallback() {
        if (this.showKnowledgeDetail && this.selectedKnowledgeArticle && this.selectedKnowledgeArticle.answer) {
            const container = this.template.querySelector('.knowledge-answer-content');
            if (container && container.innerHTML !== this.selectedKnowledgeArticle.answer) {
                container.innerHTML = this.selectedKnowledgeArticle.answer;
            }
        }
        
        // Render rich text content for Chatter posts
        if (this.chatterFeed && this.chatterFeed.length > 0) {
            this.chatterFeed.forEach(post => {
                if (post.isRichText) {
                    const richTextDiv = this.template.querySelector(`[data-postid="${post.id}"]`);
                    if (richTextDiv && richTextDiv.innerHTML !== post.body) {
                        richTextDiv.innerHTML = post.body;
                    }
                }
                
                // Add icon names to files
                if (post.files && post.files.length > 0) {
                    post.files.forEach(file => {
                        file.iconName = this.getFileIcon(file.fileExtension);
                    });
                }
            });
        }
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleString('en-GB', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
        }).replace(',', '');
    }

    async loadInitialData() {
        try {
            this.isLoading = true;
            await Promise.all([
                this.loadCases(),
                this.loadRecordTypeId(),
                this.loadUserInfo(),
                this.loadLastUsedPreferences()
            ]);
        } catch (error) {
            console.error('Error loading initial data:', error);
            this.showToast('Error', 'Error loading initial data', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadUserInfo() {
        try {
            this.currentUserInfo = await getUserInfo();
        } catch (error) {
            this.showToast('Error', 'Error loading user information', 'error');
        }
    }

    async loadRecordTypeId() {
        try {
            this.recordTypeId = await getITSupportRecordTypeId();
            if (!this.recordTypeId) {
                console.warn('No Record Type ID was returned');
            }
        } catch (error) {
            console.error('Error loading record type ID:', error);
            this.recordTypeId = null;
        }
    }

    async loadCases() {
        try {
            this.isLoading = true;
            const result = await getCases();
            this.allUserCases = result; // Store raw data
            
            // Use IsClosed field for open/closed filtering
            this.openCases = this.allUserCases.filter(c => !c.IsClosed);
            this.closedCases = this.allUserCases.filter(c => c.IsClosed);
            
            // Ensure awaitingCases getter is called and its internal logs run
            const currentAwaitingCases = this.awaitingCases; 
            // Log the state of awaitingCases as perceived immediately after data loading
            console.log('Post-load awaitingCases check:', {
                count: currentAwaitingCases.length,
                statuses: [...new Set(currentAwaitingCases.map(c=> c.Status))]
            });
            
            console.log('Loaded cases (Using IsClosed field):', {
                total: this.allUserCases.length,
                open: this.openCases.length,
                closed: this.closedCases.length,
                openStatusesFromOpenCases: [...new Set(this.openCases.map(c => c.Status))],
                closedStatusesFromClosedCases: [...new Set(this.closedCases.map(c => c.Status))],
                awaitingCountFromGetterDirect: currentAwaitingCases.length,
                statusesInAwaitingCasesFromGetterDirect: [...new Set(currentAwaitingCases.map(c=> c.Status))]
            });
            
        } catch (error) {
            console.error('Error in loadCases:', error);
            this.showToast('Error', 'Error loading cases', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async refreshData() {
        try {
            this.isLoading = true;
            if (this.viewState === 'MY_TICKETS') {
                await this.loadCases();
            } else if (this.viewState === 'CASE_DETAIL' && this.selectedCaseId) {
                await this.loadChatterFeed();
            }
            this.showToast('Success', 'Data refreshed successfully', 'success');
        } catch (error) {
            console.error('Error refreshing data:', error);
            this.showToast('Error', 'Error refreshing data', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadChatterFeed() {
        if (!this.selectedCaseId) return;
        try {
            this.chatterFeed = await getEnhancedChatterFeed({ caseId: this.selectedCaseId });
        } catch (error) {
            this.showToast('Error', 'Error loading case comments', 'error');
        }
    }

    async loadLastUsedPreferences() {
        try {
            const preferences = await getLastUsedNotificationPreferences();
            // Since we're now using single selection, take the first preference or default to Email
            const preferenceValue = Array.isArray(preferences) && preferences.length > 0 ? preferences[0] : 'Email';
            // Remove Salesforce option - default to Email if it was Salesforce
            const finalPreference = preferenceValue === 'Salesforce' ? 'Email' : preferenceValue;
            
            this.selectedNotificationPreference = finalPreference;
            this.newCase = {
                ...this.newCase,
                Notification_Preferences__c: finalPreference
            };
        } catch (error) {
            console.error('Error loading last used preferences:', error);
            this.selectedNotificationPreference = 'Email';
            this.newCase = {
                ...this.newCase,
                Notification_Preferences__c: 'Email'
            };
        }
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this.newCase = { ...this.newCase, [field]: value };
        
        // Trigger knowledge search for Subject field
        if (field === 'Subject') {
            this.handleKnowledgeSearch(value);
        }
    }

    handleCommentChange(event) {
        this.newComment = event.target.value;
    }

    handleNotificationChange(event) {
        const selectedValue = event.detail.value;
        this.selectedNotificationPreference = selectedValue;
        this.newCase.Notification_Preferences__c = selectedValue;
    }

    handleNotificationButtonClick(event) {
        const value = event.target.dataset.value;
        this.newCase.Notification_Preferences__c = value;
    }

    // File upload handlers
    handleFileUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        uploadedFiles.forEach(file => {
            this.uploadedFileIds.push(file.documentId);
        });
        this.showToast('Success', `${uploadedFiles.length} file(s) uploaded successfully`, 'success');
    }

    handleCaseFileUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        uploadedFiles.forEach(file => {
            this.caseUploadedFileIds.push({
                documentId: file.documentId,
                name: file.name
            });
        });
        this.showToast('Success', `${uploadedFiles.length} file(s) uploaded successfully`, 'success');
    }

    async handleSubmit() {
        if (!this.validateForm()) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        // Prevent multiple submissions
        if (this.isSubmittingForm || this.isLoading) {
            return;
        }

        try {
            this.isSubmittingForm = true;
            this.isLoading = true;

            // Use simplified case creation - just use the Description field
            await this.handleSubmitSimplified();

            this.resetForm();
            this.showToast('Success', 'Your case has been created successfully!', 'success');

            // Navigate to My Tickets view
            this.viewState = 'MY_TICKETS';
            await this.loadCases();

        } catch (error) {
            console.error('Error submitting case:', error);
            this.showToast('Error', 'Error creating case: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isSubmittingForm = false;
            this.isLoading = false;
        }
    }

    async handleSubmitSimplified() {
        try {
            if (this.useChatIntegration && this.newCase.Description && this.newCase.Description.trim()) {
                // Use integrated case and chat message creation
                console.log('Creating case with ChatMessage using integrated method');
                
                const caseData = {
                    Subject: this.newCase.Subject,
                    Description: this.newCase.Description,
                    Category__c: this.newCase.Category__c,
                    Severity__c: this.newCase.Severity__c,
                    Notification_Preferences__c: this.newCase.Notification_Preferences__c,
                    Origin: 'IT Support Center',
                    Status: 'New',
                    Type: this.getTypeForCategory(this.newCase.Category__c)
                };

                if (this.recordTypeId) {
                    caseData.RecordTypeId = this.recordTypeId;
                }

                const result = await createCaseWithChatMessage({
                    caseData: caseData,
                    initialMessage: this.newCase.Description,
                    attachmentFiles: this.caseUploadedFileIds && this.caseUploadedFileIds.length > 0 ? this.caseUploadedFileIds : null
                });

                console.log('Case and ChatMessage created successfully:', result);
            } else {
                // Fallback to standard case creation without ChatMessage
                console.log('Using standard case creation (no chat integration)');
                
                const caseFields = {
                    Subject: this.newCase.Subject,
                    Description: this.newCase.Description,
                    Category__c: this.newCase.Category__c,
                    Severity__c: this.newCase.Severity__c,
                    Notification_Preferences__c: this.newCase.Notification_Preferences__c,
                    Origin: 'IT Support Center',
                    Status: 'New',
                    Type: this.getTypeForCategory(this.newCase.Category__c)
                };

                if (this.recordTypeId) {
                    caseFields.RecordTypeId = this.recordTypeId;
                }

                const caseRecord = await createRecord({
                    apiName: 'Case',
                    fields: caseFields
                });

                console.log('Case created (standard method):', caseRecord.id);

                // Send notifications
                await sendNotifications({
                    request: {
                        caseId: caseRecord.id,
                        notificationTypes: [this.newCase.Notification_Preferences__c]
                    }
                });
            }

        } catch (error) {
            console.error('Error in simplified case creation:', error);
            throw error;
        }
    }

    // Handle message sent events from UnifiedChat
    handleUnifiedChatMessageSent(event) {
        console.log('UnifiedChat message sent:', event.detail);
        
        // UnifiedChat component handles its own message refreshing
        // No need to manually reload chat messages
        
        // Show success message
        this.showToast('Success', 'Message sent successfully', 'success');
    }

    // Load chat messages for case detail view
    async loadCaseChatMessages() {
        if (!this.selectedCaseId || !this.useChatIntegration) return;

        try {
            console.log('Loading chat messages for case:', this.selectedCaseId);
            this.caseChatMessages = await getCaseChatMessages(this.selectedCaseId);
            console.log('Chat messages loaded successfully:', this.caseChatMessages?.length || 0);
        } catch (error) {
            console.error('Error loading case chat messages:', error);
            
            // Only show error toast if it's a real blocking error
            // Since UnifiedChat component handles message loading via wire service,
            // this error might be non-critical
            if (error?.message && !error.message.includes('Class Cast Exception')) {
                console.warn('Non-critical error loading chat messages (UnifiedChat handles message loading):', error.message);
            } else {
                console.error('Critical error loading chat messages:', error);
                this.showToast('Warning', 'Some chat features may be limited. Messages should still load in the chat component.', 'warning');
            }
        }
    }

    async handleAddComment() {
        if (!this.newComment?.trim()) {
            this.showToast('Error', 'Please enter a comment', 'error');
            return;
        }

        try {
            this.isLoading = true;

            if (this.useChatIntegration) {
                // Use UnifiedChat integration
                await addCaseCommentViaChatMessage({
                    caseId: this.selectedCaseId,
                    commentBody: this.newComment,
                    attachmentFiles: null // File handling can be enhanced later
                });
            } else {
                // Use legacy method
                await createCaseComment({
                    caseId: this.selectedCaseId,
                    commentBody: this.newComment
                });
            }

            this.newComment = '';
            this.showToast('Success', 'Comment added successfully', 'success');

            // Refresh data
            if (this.useChatIntegration) {
                // UnifiedChat component will automatically refresh via wire service
                console.log('UnifiedChat will handle message refresh automatically');
            } else {
                await this.loadChatterFeed();
            }

        } catch (error) {
            console.error('Error adding comment:', error);
            this.showToast('Error', 'Error adding comment: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleMarkAsSolved() {
        if (!this.selectedCaseId) {
            this.showToast('Error', 'No case selected', 'error');
            return;
        }

        try {
            this.isLoading = true;
            
            await markCaseAsSolved({ caseId: this.selectedCaseId });
            
            this.showToast('Success', 'Case marked as solved successfully', 'success');
            
            // Refresh the case data and navigate back to tickets
            await this.loadCases();
            this.handleBackToTickets();
            
        } catch (error) {
            console.error('Error marking case as solved:', error);
            this.showToast('Error', 'Error marking case as solved: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleViewCase(event) {
        const caseId = event.currentTarget.dataset.caseId;
        this.navigateToCase(caseId);
    }

    async navigateToCase(caseId) {
        if (!caseId) {
            this.showToast('Error', 'Invalid case ID', 'error');
            return;
        }

        try {
            this.isLoading = true;
            this.selectedCaseId = caseId;
            
            console.log('Navigating to case:', caseId);
            console.log('Available cases:', this.allUserCases?.length || 0);
            
            // Ensure cases are loaded
            if (!this.allUserCases || this.allUserCases.length === 0) {
                console.log('No cases loaded, loading cases first...');
                await this.loadCases();
            }
            
            // Find the case from our loaded cases
            let foundCase = this.allUserCases.find(c => c.Id === caseId);
            
            if (!foundCase) {
                console.error('Case not found in allUserCases:', caseId);
                console.log('Available case IDs:', this.allUserCases.map(c => c.Id));
                this.showToast('Error', 'Case not found. Please refresh and try again.', 'error');
                return;
            }
            
            console.log('Found case:', foundCase.Subject);
            this.selectedCase = foundCase;
            this.viewState = 'CASE_DETAIL';
            
            // Check if we should use chat integration for this specific case
            try {
                const shouldUseChat = await shouldUseChatIntegration(caseId);
                this.showUnifiedChatForCase = shouldUseChat;
                console.log('Chat integration enabled for case:', shouldUseChat);
            } catch (error) {
                console.error('Error checking chat integration for case:', error);
                this.showUnifiedChatForCase = true; // Default to showing chat
            }
            
            // Since we've removed legacy comments, UnifiedChat handles all message loading
            console.log('Using UnifiedChat integration - messages will load via wire service');
        } catch (error) {
            console.error('Error navigating to case:', error);
            this.showToast('Error', 'Error loading case details: ' + error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    getTypeForCategory(category) {
        switch (category) {
            case 'Technical Issue':
                return 'Problem';
            case 'Customer Service':
                return 'Question';
            case 'Refund Request':
                return 'Feature Request';
            default:
                return 'Question';
        }
    }

    resetForm() {
        this.newCase = {
            Subject: '',
            Description: '',
            Category__c: '',
            Severity__c: '',
            Notification_Preferences__c: this.selectedNotificationPreference
        };
        this.caseUploadedFileIds = [];
        // Clear knowledge search state
        this.hideKnowledgeResults();
        this.isSubmittingForm = false;
    }

    validateForm() {
        if (this.isSubmitDisabled) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return false;
        }
        if (!this.newCase.Notification_Preferences__c) {
            this.showToast('Error', 'Please select a notification type', 'error');
            return false;
        }
        return true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    getCaseStatusClass(status) {
        switch(status) {
            case 'New':
                return 'case-status new';
            case 'Waiting for Reply':
                return 'case-status waiting';
            case 'In Progress':
                return 'case-status in-progress';
            default:
                return 'case-status';
        }
    }

    // Knowledge Search Methods
    handleKnowledgeSearch(searchTerm) {
        // Don't search if form is being submitted
        if (this.isSubmittingForm) {
            return;
        }
        
        // Clear previous timeout
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }
        
        // Don't search for very short terms
        if (!searchTerm || searchTerm.length < 2) {
            this.hideKnowledgeResults();
            return;
        }
        
        // Don't search if term hasn't changed
        if (searchTerm === this.lastSearchTerm) {
            return;
        }
        
        this.lastSearchTerm = searchTerm;
        
        // Debounce the search - wait 300ms after user stops typing
        this.searchTimeout = setTimeout(() => {
            this.performKnowledgeSearch(searchTerm);
        }, 300);
    }
    
    async performKnowledgeSearch(searchTerm) {
        try {
            this.isKnowledgeSearching = true;
            this.showKnowledgeResults = true;
            
            const results = await searchKnowledgeArticles({
                searchTerm: searchTerm,
                limitCount: 5
            });
            
            this.knowledgeSearchResults = results || [];
            
        } catch (error) {
            console.error('Error searching knowledge articles:', error);
            this.knowledgeSearchResults = [];
        } finally {
            this.isKnowledgeSearching = false;
        }
    }
    
    hideKnowledgeResults() {
        this.showKnowledgeResults = false;
        this.knowledgeSearchResults = [];
        this.lastSearchTerm = '';
    }
    
    async handleKnowledgeArticleClick(event) {
        const articleId = event.currentTarget.dataset.articleid;
        
        try {
            this.isKnowledgeSearching = true;
            
            const articleDetail = await getKnowledgeArticleDetail({
                articleId: articleId
            });
            
            this.selectedKnowledgeArticle = articleDetail;
            this.showKnowledgeDetail = true;
            
        } catch (error) {
            console.error('Error loading knowledge article:', error);
            this.showToast('Error', 'Failed to load knowledge article', 'error');
        } finally {
            this.isKnowledgeSearching = false;
        }
    }
    
    handleCloseKnowledgeDetail() {
        this.showKnowledgeDetail = false;
        this.selectedKnowledgeArticle = null;
    }
    
    handleOpenInNewTab() {
        if (this.selectedKnowledgeArticle && this.selectedKnowledgeArticle.articleUrl) {
            window.open(this.selectedKnowledgeArticle.articleUrl, '_blank');
        }
    }
    
    stripHtmlTags(htmlText) {
        if (!htmlText) return '';
        const div = document.createElement('div');
        div.innerHTML = htmlText;
        return div.textContent || div.innerText || '';
    }
    
    // Computed property for knowledge search results display
    get hasKnowledgeResults() {
        return this.knowledgeSearchResults && this.knowledgeSearchResults.length > 0;
    }
    
    get knowledgeResultsLabel() {
        const count = this.knowledgeSearchResults?.length || 0;
        return count === 1 ? '1 knowledge article found' : `${count} knowledge articles found`;
    }
    
    get knowledgeSearchPreview() {
        // Use summary if available, otherwise fallback to answer
        return (article) => {
            if (article.summary) {
                return article.summary.length > 100 ? article.summary.substring(0, 100) + '...' : article.summary;
            } else if (article.answer) {
                const cleanAnswer = this.stripHtmlTags(article.answer);
                return cleanAnswer.length > 100 ? cleanAnswer.substring(0, 100) + '...' : cleanAnswer;
            }
            return 'No preview available';
        };
    }

    getFileIcon(extension) {
        if (!extension) return 'utility:file';
        
        const ext = extension.toLowerCase();
        const iconMap = {
            'jpg': 'utility:image',
            'jpeg': 'utility:image', 
            'png': 'utility:image',
            'gif': 'utility:image',
            'bmp': 'utility:image',
            'svg': 'utility:image',
            'pdf': 'utility:pdf_ext',
            'doc': 'utility:word_doc',
            'docx': 'utility:word_doc',
            'xls': 'utility:excel_doc',
            'xlsx': 'utility:excel_doc',
            'txt': 'utility:txt',
            'zip': 'utility:zip'
        };
        
        return iconMap[ext] || 'utility:file';
    }

    // Tab navigation handlers
    handleNewTicketTabClick() {
        if (this.isLoading || this.isSubmittingForm) return;
        this.viewState = 'NEW_TICKET';
    }

    handleMyTicketsTabClick() {
        if (this.isLoading || this.isSubmittingForm) return;
        this.viewState = 'MY_TICKETS';
        this.loadCases(); // Refresh cases when switching to this tab
    }

    // Case view toggle handlers
    handleAwaitingReplyClick() {
        if (this.isLoading) return;
        this.currentCaseView = 'awaiting';
    }

    handleOpenCasesClick() {
        if (this.isLoading) return;
        this.currentCaseView = 'open';
    }

    handleClosedCasesClick() {
        if (this.isLoading) return;
        this.currentCaseView = 'closed';
    }

    // Back navigation handler
    handleBackToTickets() {
        if (this.isLoading) return;
        this.viewState = 'MY_TICKETS';
        this.selectedCase = null;
        this.selectedCaseId = null;
        this.showUnifiedChatForCase = false;
    }

    get hasCaseUploadedFiles() {
        return this.caseUploadedFileIds && this.caseUploadedFileIds.length > 0;
    }

    handleRemoveCaseUploadedFile(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.caseUploadedFileIds = this.caseUploadedFileIds.filter((_, i) => i !== index);
    }
}