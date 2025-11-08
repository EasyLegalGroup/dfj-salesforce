public class DFJ_DeleteRecords implements Database.Batchable<SObject> {

    private Set<Id> recordIdsToDelete;
    private String sObjectType;
    private Set<String> failedMessages = new Set<String>();

    public DFJ_DeleteRecords(Set<Id> recordIds, String sObjectType) {
        this.recordIdsToDelete = recordIds;
        this.sObjectType = sObjectType;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM ' + sObjectType + ' WHERE Id IN :recordIdsToDelete';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (!scope.isEmpty()) {
            Database.DeleteResult[] results = Database.delete(scope, false);
            
            for (Database.DeleteResult result : results) {
                if (!result.isSuccess()) {
                    for(Database.Error err : result.getErrors() ){
                        failedMessages.add(err.getMessage());
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        system.debug('failed Messages-->'+ failedMessages);
    }
}