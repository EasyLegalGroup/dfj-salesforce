global class GEN_RecordDeletionBatch implements Database.Batchable<sObject> , Database.Stateful, Schedulable  {
      
    global String query;
    global String objectName;
    global String csvColumnHeader;
    global List<String> csvRowValues = new List<String>();
    global List<String> toAddresses = new List<String>();
  
    global GEN_RecordDeletionBatch (String queryToExecute, String objName, List<String> toMailAddresses){
        this.query = queryToExecute;
        this.objectName = objName;
        this.toAddresses = toMailAddresses;
    }
    
    global Database.QueryLocator start(Database.BatchableContext btc){
        return Database.getQueryLocator(query);
    }
    
    global void Execute (Database.BatchableContext btc , List<sObject> scope ){
        Record_Deletion_Batch_Configuration__c batchConfiguration = Record_Deletion_Batch_Configuration__c.getOrgDefaults();
        if(objectName == 'telegenta__Telegenta_Call_Recording__c' && batchConfiguration.Is_active__c && !scope.isEmpty()){
            for(sObject callRecording: scope)
                {
                    String recordString = callRecording.get('Id')+','+callRecording.get('Name')+','+callRecording.get('telegenta__Telegenta_Call_History__c')+','+
                        callRecording.get('telegenta__Media_URL__c') +','+DateTime.valueOf(callRecording.get('telegenta__Start_Time__c')).format('M/d/yyyy h:mm:ss a z')+','+
                        DateTime.valueOf(callRecording.get('telegenta__Recording_Delete_Date__c')).format('M/d/yyyy h:mm:ss a z')+','+
                        callRecording.get('telegenta__Recording_Id__c') + ','+callRecording.get('telegenta__Length__c')+','+
                        callRecording.get('telegenta__Size__c');
                    csvRowValues.add(recordString);
                }
        }
        if(!scope.isEmpty()){
            System.debug('Deleting records >>> '+JSON.serialize(scope));
            delete scope;
        }
    }
    
    global void finish (Database.BatchableContext btc){
        Record_Deletion_Batch_Configuration__c batchConfiguration = Record_Deletion_Batch_Configuration__c.getOrgDefaults();
        csvColumnHeader = 'Id, Name , telegenta__Telegenta_Call_History__c, telegenta__Media_URL__c, telegenta__Start_Time__c, telegenta__Recording_Delete_Date__c, telegenta__Recording_Id__c, telegenta__Length__c, telegenta__Size__c \n';
        System.debug('csvRowValues'+csvRowValues);
        String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
        System.debug('csvFile'+csvFile);

        if(objectName == 'telegenta__Telegenta_Call_Recording__c' && batchConfiguration.Is_active__c && !csvRowValues.isEmpty())
        {
            List<String> emailToValidate = String.isBlank(batchConfiguration.Email_addresses__c.replace('\r\n', ' ').replace('\n', ' ').replace('\r', ' ')) ? toAddresses : batchConfiguration.Email_addresses__c.replace('\r\n', ' ').replace('\n', ' ').replace('\r', ' ').trim().split(',');
            String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
            
            System.debug('emailToValidate'+emailToValidate);
            List<String> emailAddresses = new List<String>();
            for (String email : emailToValidate) {
                Pattern MyPattern = Pattern.compile(emailRegex);
                Matcher MyMatcher = MyPattern.matcher(email);
                if (!MyMatcher.matches()) {
                    DFJ_ErrorLogController.addErrorLogs('', 'Validating email', 'Email pattern not matched. Email : '+email, 'Info', 'GEN_RecordDeletionBatch.finish', '', '');
                }else{
                    emailAddresses.add(email);
                }
            }

            if (!emailAddresses.isEmpty()) {
                System.debug('emailAddresses '+emailAddresses);
                Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                blob csvBlob = Blob.valueOf(csvFile);
                string csvname= 'telegenta__Telegenta_Call_Recording__c.csv';
                csvAttc.setFileName(csvname);
                csvAttc.setBody(csvBlob);
                Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
                String[] toAddresses = emailAddresses;
                System.debug('toAddresses '+toAddresses);
                String subject ='telegenta__Telegenta_Call_Recording__c CSV';
                email.setSubject(subject);
                email.setToAddresses( toAddresses );
                email.setPlainTextBody('Delete Records Of telegenta__Telegenta_Call_Recording__c');
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
                Messaging.SendEmailResult [] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                DFJ_ErrorLogController.addErrorLogs('', 'Sending email from batch.', String.valueOf(results), '', 'GEN_RecordDeletionBatch.finish', '', '');
            }
        }
    }
    
    global void execute (SchedulableContext sdx){
        System.debug('query >>> '+ query);
        System.debug('objectName >>> '+ objectName);
        GEN_RecordDeletionBatch obj = new GEN_RecordDeletionBatch(query, objectName, toAddresses);
        Database.executeBatch(obj);

    }
    
    global static void start(String cronExp,String query,String objName, String jobName, List<String> toMailAddresses){
         //string jobName = 'job name';
        if (String.isBlank(cronExp)) {
            database.executebatch(new GEN_RecordDeletionBatch(query,objName,toMailAddresses));
        } else{        
	     jobName = jobName += ' - ' + datetime.now().format();
	     system.schedule(jobName, cronExp, new GEN_RecordDeletionBatch(query,objName,toMailAddresses));
	 	}
	}
}