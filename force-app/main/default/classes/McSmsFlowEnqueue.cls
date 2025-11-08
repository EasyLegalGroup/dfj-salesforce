public with sharing class McSmsFlowEnqueue {
    public class Input {
        @InvocableVariable(required=true) public Id recordId; // SMS__c Id
    }

    @InvocableMethod(label='Enqueue MC SMS Send' description='Queues SMS__c records for send via Marketing Cloud')
    public static void enqueue(List<Input> inputs){
        Set<Id> ids = new Set<Id>();
        for (Input i : inputs) if (i != null && i.recordId != null) ids.add(i.recordId);
        if (!ids.isEmpty()) System.enqueueJob(new McSmsSendQueue(ids));
    }
}