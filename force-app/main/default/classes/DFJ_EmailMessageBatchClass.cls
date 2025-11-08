public class DFJ_EmailMessageBatchClass implements Database.Batchable<SObject>, Database.Stateful, DFJ_EmailMessageArchiver {
    
    private Set<Id> successfulInsertIds = new Set<Id>();
    private String dateFilter;
    private DFJ_EmailMessageArchiver archiver;   
    private Set<Id> failedIds = new Set<Id>();
   
    public DFJ_EmailMessageBatchClass(String filter) {
        this.archiver = this;  
        this.dateFilter = filter;
    } 
    
    public DFJ_EmailMessageBatchClass(DFJ_EmailMessageArchiver archiver, String filter) {
        this.archiver = archiver;
        this.dateFilter = filter;
    } 
 
    public Database.SaveResult[] insertRecords(List<Email_Message__b> records) {
        if (!records.isEmpty() && !Test.isRunningTest()) {
            return Database.insertImmediate(records);
        }
        return new List<Database.SaveResult>();
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id,Name,ActivityId,CcAddress,ClientThreadIdentifier,CreatedDate,EmailRoutingAddressId ' +
            ',EmailTemplateId,FirstOpenedDate,FromAddress,FromId,FromName,Headers,HtmlBody,Incoming,IsBounced,IsOpened,IsTracked,' +
            'LastOpenedDate,MessageDate,MessageIdentifier,RelatedToId,ReplyToEmailMessageId,Source,Status,Subject,TextBody,' +
            'ThreadIdentifier ,ToAddress,ValidatedFromAddress ' +
            'FROM EmailMessage WHERE ' + dateFilter
        );
    }
    
   public void execute(Database.BatchableContext bc, List<SObject> scope) {
   if (scope != null && !scope.isEmpty()) {    
        List<Email_Message__b> emailMessageToInsert = new List<Email_Message__b>();
        for (SObject sObj : scope) {
            EmailMessage emailMessage = (EmailMessage) sObj; 
            Email_Message__b emailMessageRecord = new Email_Message__b();
            emailMessageRecord.ActivityId__c = (emailMessage.ActivityId!= null) ? String.valueOf(emailMessage.ActivityId) : null;
            emailMessageRecord.CcAddress__c = emailMessage.CcAddress != null ? emailMessage.CcAddress : ' ';
            emailMessageRecord.ClientThreadIdentifier__c = emailMessage.ClientThreadIdentifier != null ? emailMessage.ClientThreadIdentifier : ' ';
            emailMessageRecord.CreatedDate__c = emailMessage.CreatedDate;
            emailMessageRecord.FirstOpenedDate__c = emailMessage.FirstOpenedDate != null ? emailMessage.FirstOpenedDate : null;
            emailMessageRecord.FromAddress__c = emailMessage.FromAddress != null ? emailMessage.FromAddress : ' ';
            emailMessageRecord.FromId__c = (emailMessage.FromId != null) ? String.valueOf(emailMessage.FromId) : null;
            emailMessageRecord.FromName__c = emailMessage.FromName != null ? emailMessage.FromName : ' ';
            emailMessageRecord.Headers__c = emailMessage.Headers != null ? emailMessage.Headers : ' ';
            emailMessageRecord.HtmlBody__c = emailMessage.HtmlBody != null ? emailMessage.HtmlBody : ' ';   
            emailMessageRecord.IsBounced__c = (emailMessage.IsBounced == true) ? 'True' : 'False';
            emailMessageRecord.Incoming__c = (emailMessage.Incoming == true) ? 'True' : 'False';
            emailMessageRecord.IsOpened__c = (emailMessage.IsOpened == true) ? 'True' : 'False';
            emailMessageRecord.IsTracked__c = (emailMessage.IsTracked == true) ? 'True' : 'False';              
            emailMessageRecord.LastOpenedDate__c = emailMessage.LastOpenedDate != null ? emailMessage.LastOpenedDate : null;
            emailMessageRecord.MessageDate__c = emailMessage.MessageDate != null ? emailMessage.MessageDate : null;
            emailMessageRecord.MessageIdentifier__c = emailMessage.MessageIdentifier != null ? emailMessage.MessageIdentifier : ' ';
            emailMessageRecord.Name__c = emailMessage.Name != null ? emailMessage.Name : ' ';
            emailMessageRecord.RelatedToId__c = (emailMessage.RelatedToId != null) ? String.valueOf(emailMessage.RelatedToId) : null;
            emailMessageRecord.ID__c = emailMessage.Id;
            emailMessageRecord.Source__c = emailMessage.Source != null ? emailMessage.Source : ' ';
            emailMessageRecord.Status__c = emailMessage.Status != null ? emailMessage.Status : ' ';
            emailMessageRecord.Subject__c = emailMessage.Subject != null ? emailMessage.Subject : ' ';
            emailMessageRecord.TextBody__c = emailMessage.TextBody != null ? emailMessage.TextBody : ' ';
            emailMessageRecord.ThreadIdentifier__c = emailMessage.ThreadIdentifier != null ? emailMessage.ThreadIdentifier : ' ';
            emailMessageRecord.ToAddress__c = emailMessage.ToAddress != null ? emailMessage.ToAddress : ' ';
            emailMessageRecord.ValidatedFromAddress__c = emailMessage.ValidatedFromAddress != null ? emailMessage.ValidatedFromAddress : ' ';
            emailMessageRecord.EmailRoutingAddressId__c = (emailMessage.EmailRoutingAddressId != null) ? String.valueOf(emailMessage.EmailRoutingAddressId) : null;
            emailMessageRecord.EmailTemplateId__c= (emailMessage.EmailTemplateId != null) ? String.valueOf(emailMessage.EmailTemplateId) : null;
            emailMessageRecord.ReplyToEmailMessageId__c = (emailMessage.ReplyToEmailMessageId != null) ? String.valueOf(emailMessage.ReplyToEmailMessageId) : null;
            emailMessageToInsert.add(emailMessageRecord);
        }
        if (!emailMessageToInsert.isEmpty()) {
            try {
                Database.SaveResult[] results = archiver.insertRecords(emailMessageToInsert); 
               for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult sr = results[i]; 
                    String recordIdentifier = emailMessageToInsert[i].ID__c; 
                    if (!sr.isSuccess()) {
                        failedIds.add(recordIdentifier);
                    } else {
                        successfulInsertIds.add(recordIdentifier);   
                    }
                }   
            } catch (Exception e) {
               System.debug('error:-->'+ e.getMessage()+ 'on line No-->'+ e.getLineNumber());
            }
        }
    } 
}
 
    public void finish(Database.BatchableContext bc) {
        System.debug('failedIds: ' + failedIds);
        if (!successfulInsertIds.isEmpty()) {
            Database.executeBatch(new DFJ_DeleteRecords(successfulInsertIds, 'EmailMessage'), 2000);
        } 
    }
    
    public class BatchParams {
        @InvocableVariable(required=false) public Date startDate;
        @InvocableVariable(required=true) public Date endDate;
    }
    
    @InvocableMethod(label='Run Email Message Batch')
    public static void runBatch(List<BatchParams> paramsList) {
        BatchParams params = (paramsList != null && !paramsList.isEmpty()) ? paramsList[0] : new BatchParams();
        String filter; 
        Date endDate = params.endDate;
        Date startDate = params.startDate;
        DateTime endDT = DateTime.newInstance(endDate, Time.newInstance(23, 59, 59, 0));
        if (startDate != null) {
            DateTime startDT = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            filter = 'CreatedDate >= ' + startDT.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' AND CreatedDate <= ' + endDT.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        } else {
            filter = 'CreatedDate <= ' + endDT.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        }        
        Database.executeBatch(new DFJ_EmailMessageBatchClass(filter), 2000);
    }
}