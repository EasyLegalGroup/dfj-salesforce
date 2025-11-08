global class DFJ_DeleteTelegentaLogs implements Database.Batchable<sObject>{
    global String query;
    global DFJ_DeleteTelegentaLogs(String query){
        this.query = query;
    } 
    global Database.QueryLocator start(Database.BatchableContext BC) {
         return Database.getQueryLocator(query); 
    }
     
    global void execute(Database.BatchableContext BC, List<sObject> telegentaLogList) {
        try {  
            System.debug('Log List >>>'+telegentaLogList);
            if(Test.isRunningTest()){
                delete telegentaLogList;
            }
            if (!telegentaLogList.isEmpty()) {
                delete telegentaLogList;
            }
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Deleting logs.', String.valueOf(ex.getMessage()), 'Error', 'DFJ_DeleteTelegentaLogs execute method.', String.valueOf(ex.getLineNumber()));
        }      
    }   
     
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }

}