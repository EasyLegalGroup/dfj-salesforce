import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import Id from '@salesforce/user/Id';
import createMessage from '@salesforce/apex/ChatService.createMessage';
import getConversationHistory from '@salesforce/apex/ChatService.getConversationHistory';
import sendMessageAndUpdateStatus from '@salesforce/apex/ChatService.sendMessageAndUpdateStatus';
import sendMessageAndCloseCase from '@salesforce/apex/ChatService.sendMessageAndCloseCase';

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB
const RICH_TEXT_FORMATS = [
    'font', 'size', 'bold', 'italic', 'underline', 'strike',
    'list', 'indent', 'align', 'link', 'color', 'background', 'image'
];

// Real-time configuration
const REFRESH_INTERVAL = 5000; // 5 seconds
const TYPING_TIMEOUT = 3000; // 3 seconds

export default class UnifiedChat extends LightningElement {
    @api recordId; // Parent record ID to associate messages with
    @api height = '500px'; // Configurable height
    @api maxWidth = '680px'; // Maximum width - defaults to full width
    @api enableRealTime = false; // Enable real-time features
    @api placeholder = 'Type a message...';
    @api emptyStateTitle = 'Start a conversation';
    @api emptyStateMessage = 'Send a message to begin the conversation.';

    // Message data
    @track messages = [];
    @track isLoading = false;
    @track isSending = false;
    @track messageBody = '';
    @track uploadedFiles = [];
    @track refreshKey = 0;
    
    // Composer state
    @track composerValue = '';
    @track selectedFiles = [];
    @track isComposerValid = true;
    
    // Modal state
    @track showImageModal = false;
    @track modalImageUrl = '';
    @track modalImageTitle = '';
    
    // Real-time state
    @track showTypingIndicator = false;
    @track isTyping = false;
    @track lastMessageCount = 0;
    
    // Wired conversation history
    wiredMessagesResult;
    
    // Internal properties
    refreshIntervalId;
    typingTimeoutId;
    lastRefreshTime = Date.now();
    realTimeInterval;

    @wire(getConversationHistory, { parentRecordId: '$recordId', $refresh: '$refreshKey' })
    wiredMessages(result) {
        this.wiredMessagesResult = result;
        if (result.data) {
            this.messages = this.processMessages(result.data);
            this.isLoading = false;
            this.checkForNewMessages(this.messages);
            // Scroll to bottom after data loads
            setTimeout(() => this.scrollToBottom(), 100);
        } else if (result.error) {
            this.isLoading = false;
            this.showToast('Error', 'Error loading messages: ' + result.error.body?.message, 'error');
        }
    }

    // Lifecycle methods
    connectedCallback() {
        if (this.enableRealTime) {
            this.startRealTimeUpdates();
        }
        // Add paste event listener for image handling
        this.addPasteListener();
        // Add click listeners for embedded images
        this.addEmbeddedImageListeners();
    }

    disconnectedCallback() {
        this.stopRealTimeUpdates();
        this.clearTypingTimeout();
        this.removePasteListener();
    }

    renderedCallback() {
        // Re-add image click listeners after DOM updates
        this.addEmbeddedImageListeners();
    }

    addEmbeddedImageListeners() {
        // Add click handlers to embedded images in messages
        setTimeout(() => {
            const embeddedImages = this.template.querySelectorAll('.message-body lightning-formatted-rich-text img');
            embeddedImages.forEach(img => {
                img.removeEventListener('click', this.handleEmbeddedImageClick.bind(this));
                img.addEventListener('click', this.handleEmbeddedImageClick.bind(this));
            });
        }, 100);
    }

    handleEmbeddedImageClick(event) {
        const img = event.target;
        this.modalImageUrl = img.src;
        this.modalImageTitle = img.alt || 'Embedded Image';
        this.showImageModal = true;
    }

    // Getters
    get hasMessages() {
        return this.messages && this.messages.length > 0;
    }

    get hasSelectedFiles() {
        return this.selectedFiles && this.selectedFiles.length > 0;
    }

    get hasUploadedFiles() {
        return this.uploadedFiles && this.uploadedFiles.length > 0;
    }

    get isSendDisabled() {
        return this.isSending || 
               (!this.messageBody?.trim() && !this.hasSelectedFiles) ||
               this.selectedFiles.some(file => file.size > MAX_FILE_SIZE);
    }

    get richTextFormats() {
        return RICH_TEXT_FORMATS;
    }

    get heightStyle() {
        return `height: ${this.height}; max-width: ${this.maxWidth};`;
    }

    @api showSupportButtons; // undefined / true by default

    get isOnCaseRecord() {
        // Show support buttons only if allowed and this is a Case record
        const disallow = this.showSupportButtons === false || this.showSupportButtons === 'false';
        return !disallow && this.recordId && this.recordId.startsWith('500');
    }

    get acceptedFileFormats() {
        return ['.jpg', '.jpeg', '.png', '.gif', '.pdf', '.doc', '.docx', '.txt', '.xls', '.xlsx'];
    }

    get isSubmitDisabled() {
        return this.isSending || !this.messageBody?.trim();
    }

    get isRequestReplyDisabled() {
        return this.isSending || !this.messageBody?.trim() || !this.isOnCaseRecord;
    }

    get isCloseCaseDisabled() {
        return this.isSending || !this.messageBody?.trim() || !this.isOnCaseRecord;
    }

    // Event handlers
    handleMessageChange(event) {
        this.messageBody = event.target.value;
    }

    handleFileUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        uploadedFiles.forEach(file => {
            this.uploadedFiles.push({
                name: file.name,
                documentId: file.documentId, // Store the Salesforce document ID
                size: file.size,
                contentVersionId: file.contentVersionId // Also store content version ID
            });
        });
        this.showToast('Success', `${uploadedFiles.length} file(s) uploaded successfully`, 'success');
    }

    handleComposerChange(event) {
        this.composerValue = event.target.value;
        this.isComposerValid = true;
        
        // Handle typing indicator
        if (this.enableRealTime) {
            this.handleTypingStart();
        }
    }

    handleFileChange(event) {
        const files = event.target.files;
        if (files && files.length > 0) {
            this.processSelectedFiles(files);
        }
    }

    handleRemoveFile(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.selectedFiles = this.selectedFiles.filter((_, i) => i !== index);
    }

    handleRemoveUploadedFile(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.uploadedFiles = this.uploadedFiles.filter((_, i) => i !== index);
    }

    handleImageClick(event) {
        this.modalImageUrl = event.target.dataset.url;
        this.modalImageTitle = event.target.dataset.title;
        this.showImageModal = true;
    }

    closeImageModal() {
        this.showImageModal = false;
        this.modalImageUrl = '';
        this.modalImageTitle = '';
    }

    async handleSendMessage() {
        await this.sendMessage(false, null);
    }

    async handleSendAndRequestReply() {
        await this.sendMessage(true, 'Waiting for Reply');
    }

    async handleSendAndCloseCase() {
        await this.sendMessage(true, 'Closed');
    }

    // Real-time methods
    startRealTimeUpdates() {
        this.realTimeInterval = setInterval(() => {
            this.refreshMessages();
        }, REFRESH_INTERVAL);
    }

    stopRealTimeUpdates() {
        if (this.realTimeInterval) {
            clearInterval(this.realTimeInterval);
        }
    }

    handleTypingStart() {
        this.isTyping = true;
        this.clearTypingTimeout();
        
        // Set timeout to clear typing indicator
        this.typingTimeoutId = setTimeout(() => {
            this.isTyping = false;
        }, TYPING_TIMEOUT);
    }

    clearTypingTimeout() {
        if (this.typingTimeoutId) {
            clearTimeout(this.typingTimeoutId);
            this.typingTimeoutId = null;
        }
    }

    clearTypingIndicator() {
        this.isTyping = false;
        this.clearTypingTimeout();
    }

    checkForNewMessages(newMessages) {
        const newCount = newMessages ? newMessages.length : 0;
        
        if (this.lastMessageCount > 0 && newCount > this.lastMessageCount) {
            // New messages detected - no notification needed
            // The message count tracking is still maintained for functionality
        }
        
        this.lastMessageCount = newCount;
    }

    fireMessageSentEvent(messageResult) {
        // Fire custom event that can be listened to by parent components
        const messageEvent = new CustomEvent('messagesent', {
            detail: {
                message: messageResult.message,
                attachments: messageResult.attachments,
                parentRecordId: this.recordId
            },
            bubbles: true,
            composed: true
        });
        
        this.dispatchEvent(messageEvent);
    }

    // Helper methods
    processMessages(messageResults) {
        return messageResults.map(messageResult => {
            const userInitials = messageResult.message.CreatedBy.Name
                .split(' ')
                .map(name => name.charAt(0))
                .join('')
                .substring(0, 2);

            return {
                message: messageResult.message,
                attachments: messageResult.attachments || [],
                userInitials,
                relativeTimestamp: this.formatRelativeTime(messageResult.message.CreatedDate),
                cssClass: this.getMessageCssClass(messageResult)
            };
        });
    }

    getMessageCssClass(messageResult) {
        // Get current user ID for comparison
        const currentUserId = this.getCurrentUserId();
        const messageUserId = messageResult.message.CreatedById;
        
        if (currentUserId === messageUserId) {
            return 'message-item current-user';
        } else {
            return 'message-item other-user';
        }
    }

    getCurrentUserId() {
        return Id; // Returns the current user's ID
    }

    processSelectedFiles(files) {
        const fileArray = Array.from(files);
        const processedFiles = fileArray.map(file => ({
            name: file.name,
            size: file.size,
            type: file.type,
            file: file,
            formattedSize: this.formatFileSize(file.size),
            isValid: file.size <= MAX_FILE_SIZE
        }));

        // Check for oversized files
        const oversizedFiles = processedFiles.filter(f => !f.isValid);
        if (oversizedFiles.length > 0) {
            this.showToast('Error', `Maximum file size is ${this.formatFileSize(MAX_FILE_SIZE)}. ` +
                `Please remove: ${oversizedFiles.map(f => f.name).join(', ')}`, 'error');
        }

        this.selectedFiles = [...this.selectedFiles, ...processedFiles];
    }

    async prepareAttachments() {
        if (!this.hasSelectedFiles) return null;

        const validFiles = this.selectedFiles.filter(f => f.isValid);
        const fileDataList = await Promise.all(
            validFiles.map(async (fileInfo) => {
                const base64Data = await this.fileToBase64(fileInfo.file);
                return {
                    name: fileInfo.name,
                    base64Data: base64Data,
                    size: fileInfo.size,
                    type: fileInfo.type
                };
            })
        );

        return fileDataList;
    }

    fileToBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                // Remove data URL prefix (data:type;base64,)
                const base64 = reader.result.split(',')[1];
                resolve(base64);
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        
        const units = ['B', 'KB', 'MB', 'GB'];
        let unitIndex = 0;
        let size = bytes;
        
        while (size >= 1024 && unitIndex < units.length - 1) {
            size /= 1024;
            unitIndex++;
        }
        
        return `${Math.round(size * 100) / 100} ${units[unitIndex]}`;
    }

    addMessageToList(messageResult) {
        const processedMessage = {
            ...messageResult,
            cssClass: this.getMessageCssClass(messageResult),
            hasAttachments: messageResult.attachments && messageResult.attachments.length > 0
        };
        
        // Add to the beginning of the array since newest messages are first
        this.messages = [processedMessage, ...this.messages];
    }

    clearComposer() {
        this.composerValue = '';
        this.selectedFiles = [];
        this.clearTypingIndicator();
        
        // Clear file input
        const fileInput = this.template.querySelector('lightning-input[type="file"]');
        if (fileInput) {
            fileInput.value = '';
        }
    }

    async refreshMessages() {
        try {
            this.refreshKey = Date.now();
            await refreshApex(this.wiredMessagesResult);
        } catch (error) {
            console.error('Error refreshing messages:', error);
        }
    }

    scrollToBottom() {
        setTimeout(() => {
            const messageContainer = this.template.querySelector('.message-container');
            if (messageContainer) {
                messageContainer.scrollTop = messageContainer.scrollHeight;
            }
        }, 100);
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

    // Public API methods for external control
    @api
    async sendExternalMessage(messageText) {
        this.messageBody = messageText;
        await this.handleSendMessage();
    }

    @api
    async clearMessages() {
        this.messages = [];
        this.lastMessageCount = 0;
    }

    @api
    async refreshConversation() {
        await this.refreshMessages();
    }

    @api
    setRealTimeEnabled(enabled) {
        this.enableRealTime = enabled;
        if (enabled) {
            this.startRealTimeUpdates();
        } else {
            this.stopRealTimeUpdates();
        }
    }

    // Image paste handling methods
    addPasteListener() {
        // Add event listener to the component container and rich text editor
        setTimeout(() => {
            const container = this.template.querySelector('.unified-chat-container');
            const richTextEditor = this.template.querySelector('lightning-input-rich-text');
            
            if (container) {
                container.addEventListener('paste', this.handlePaste.bind(this));
            }
            
            // Add specific handling for rich text editor
            if (richTextEditor) {
                this.addRichTextPasteListener(richTextEditor);
            }
        }, 100);
    }

    addRichTextPasteListener(richTextEditor) {
        // Find the actual editor iframe or div
        const editorElement = richTextEditor.querySelector('[contenteditable="true"]') || 
                             richTextEditor.querySelector('iframe');
        
        if (editorElement) {
            if (editorElement.tagName === 'IFRAME') {
                // Handle iframe-based editor
                editorElement.onload = () => {
                    const iframeDoc = editorElement.contentDocument || editorElement.contentWindow.document;
                    iframeDoc.addEventListener('paste', this.handleRichTextPaste.bind(this));
                };
            } else {
                // Handle div-based editor
                editorElement.addEventListener('paste', this.handleRichTextPaste.bind(this));
            }
        }
    }

    removePasteListener() {
        const container = this.template.querySelector('.unified-chat-container');
        if (container) {
            container.removeEventListener('paste', this.handlePaste.bind(this));
        }
        
        // Rich text editor cleanup is handled automatically when component is destroyed
    }

    async handlePaste(event) {
        const clipboardData = event.clipboardData || window.clipboardData;
        if (!clipboardData) return;

        const items = clipboardData.items;
        const imageFiles = [];

        // Check for pasted images
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (item.type.indexOf('image') !== -1) {
                event.preventDefault(); // Prevent default paste behavior for images
                const file = item.getAsFile();
                if (file) {
                    imageFiles.push(file);
                }
            }
        }

        if (imageFiles.length > 0) {
            await this.processPastedImages(imageFiles);
        }
    }

    async processPastedImages(imageFiles) {
        try {
            // Convert File objects to the format expected by processSelectedFiles
            const processedFiles = imageFiles.map(file => {
                // Generate a filename if not provided
                const timestamp = new Date().getTime();
                const extension = file.type.split('/')[1] || 'png';
                const fileName = file.name || `pasted-image-${timestamp}.${extension}`;
                
                return new File([file], fileName, { type: file.type });
            });

            // Process the pasted images as if they were selected files
            this.processSelectedFiles(processedFiles);
            
            // Show notification
            const fileCount = imageFiles.length;
            if (fileCount === 1) {
                this.showToast('Success', 'Image pasted and ready to send', 'success');
            } else {
                this.showToast('Success', `${fileCount} images pasted and ready to send`, 'success');
            }
        } catch (error) {
            this.showToast('Error', 'Error processing pasted images', 'error');
        }
    }

    async handleRichTextPaste(event) {
        const clipboardData = event.clipboardData || window.clipboardData;
        if (!clipboardData) return;

        const items = clipboardData.items;
        let hasImages = false;

        // Check for pasted images
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (item.type.indexOf('image') !== -1) {
                event.preventDefault(); // Prevent default paste behavior
                hasImages = true;
                
                const file = item.getAsFile();
                if (file) {
                    await this.embedImageInRichText(file, event);
                }
            }
        }

        if (hasImages) {
            this.showToast('Success', 'Image(s) embedded in message', 'success');
        }
    }

    async embedImageInRichText(file, pasteEvent) {
        try {
            // Convert image to data URL for immediate embedding
            const dataUrl = await this.fileToDataUrl(file);
            
            // Get the current rich text content
            const currentContent = this.composerValue || '';
            
            // Create an img tag with the data URL
            const imgTag = `<img src="${dataUrl}" alt="Pasted image" style="max-width: 300px; height: auto; margin: 5px;" />`;
            
            // Insert the image at the cursor position or append to content
            const updatedContent = this.insertImageIntoContent(currentContent, imgTag, pasteEvent);
            
            // Update the composer value
            this.composerValue = updatedContent;
            
            // Trigger change event to update the rich text editor
            const richTextEditor = this.template.querySelector('lightning-input-rich-text');
            if (richTextEditor) {
                richTextEditor.value = this.composerValue;
                // Dispatch a change event
                richTextEditor.dispatchEvent(new CustomEvent('change', {
                    detail: { value: this.composerValue }
                }));
            }
            
        } catch (error) {
            this.showToast('Error', 'Error embedding image', 'error');
        }
    }

    insertImageIntoContent(currentContent, imgTag, pasteEvent) {
        // For now, append the image to the existing content
        // In a more advanced implementation, you could track cursor position
        if (currentContent.trim()) {
            return currentContent + '<br>' + imgTag;
        } else {
            return imgTag;
        }
    }

    fileToDataUrl(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                resolve(reader.result); // This includes the data: prefix
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    getFileIcon(extension) {
        if (!extension) return 'utility:file';
        
        const ext = extension.toLowerCase();
        const iconMap = {
            'jpg': 'utility:image',
            'jpeg': 'utility:image', 
            'png': 'utility:image',
            'gif': 'utility:image',
            'pdf': 'utility:pdf_ext',
            'doc': 'utility:word_doc',
            'docx': 'utility:word_doc',
            'xls': 'utility:excel_doc',
            'xlsx': 'utility:excel_doc',
            'txt': 'utility:txt'
        };
        
        return iconMap[ext] || 'utility:file';
    }

    // Core send message logic
    async sendMessage(updateStatus = false, newStatus = null) {
        if (!this.messageBody?.trim()) {
            this.showToast('Error', 'Please enter a message', 'error');
            return;
        }

        try {
            this.isSending = true;

            let result;
            
            if (updateStatus && newStatus) {
                // Use dual-action methods
                if (newStatus === 'Waiting for Reply') {
                    result = await sendMessageAndUpdateStatus({
                        body: this.messageBody,
                        parentRecordId: this.recordId,
                        attachmentFiles: this.uploadedFiles,
                        newStatus: newStatus
                    });
                } else if (newStatus === 'Closed') {
                    result = await sendMessageAndCloseCase({
                        body: this.messageBody,
                        parentRecordId: this.recordId,
                        attachmentFiles: this.uploadedFiles
                    });
                }
            } else {
                // Standard message creation
                result = await createMessage({
                    body: this.messageBody,
                    parentRecordId: this.recordId,
                    attachmentFiles: this.uploadedFiles
                });
            }

            // Reset form
            this.messageBody = '';
            this.uploadedFiles = [];
            
            // Clear rich text editor
            const richTextElement = this.template.querySelector('lightning-input-rich-text');
            if (richTextElement) {
                richTextElement.value = '';
            }

            // Show success message
            let successMessage = 'Message sent successfully';
            if (updateStatus) {
                successMessage += ` and case status updated to ${newStatus}`;
            }
            this.showToast('Success', successMessage, 'success');

            // Refresh messages
            await this.refreshMessages();

            // Fire custom event
            this.dispatchEvent(new CustomEvent('messagesent', {
                detail: {
                    message: result,
                    statusChanged: updateStatus,
                    newStatus: newStatus
                }
            }));

        } catch (error) {
            console.error('Error sending message:', error);
            this.showToast('Error', 'Error sending message: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isSending = false;
        }
    }

    formatRelativeTime(dateTimeString) {
        const messageDate = new Date(dateTimeString);
        const now = new Date();
        const diffInMinutes = Math.floor((now - messageDate) / (1000 * 60));
        
        if (diffInMinutes < 1) return 'Just now';
        if (diffInMinutes < 60) return `${diffInMinutes}m ago`;
        
        const diffInHours = Math.floor(diffInMinutes / 60);
        if (diffInHours < 24) return `${diffInHours}h ago`;
        
        const diffInDays = Math.floor(diffInHours / 24);
        if (diffInDays < 7) return `${diffInDays}d ago`;
        
        // For older messages, show the actual date
        return messageDate.toLocaleDateString();
    }
}