public class NoteTriggerHandler {
    
    /**
     * Handles after-insert and after-update Note events.
     *  - If the Note’s parent is an Account, update that Account’s most recently created Journal.
     *  - If the Note’s parent is a Journal__c, update that specific Journal.
     */
    public static void handleNoteInsertUpdate(List<Note> newNotes) {
        try {
            // Separate notes by parent type
            Set<Id> accountIds = new Set<Id>();
            Map<Id, Note> latestNoteByAccount = new Map<Id, Note>();

            Set<Id> journalIds = new Set<Id>();
            Map<Id, Note> latestNoteByJournal = new Map<Id, Note>();

            // Identify which Notes belong to Accounts vs. Journals
            for (Note n : newNotes) {
                if (n.ParentId != null) {
                    // Parent is an Account
                    if (n.ParentId.getSObjectType() == Account.sObjectType) {
                        // Only store the latest note by CreatedDate
                        if (!latestNoteByAccount.containsKey(n.ParentId) 
                            || latestNoteByAccount.get(n.ParentId).CreatedDate < n.CreatedDate) {
                            latestNoteByAccount.put(n.ParentId, n);
                        }
                        accountIds.add(n.ParentId);

                    // Parent is a Journal__c
                    } else if (n.ParentId.getSObjectType() == Journal__c.sObjectType) {
                        if (!latestNoteByJournal.containsKey(n.ParentId) 
                            || latestNoteByJournal.get(n.ParentId).CreatedDate < n.CreatedDate) {
                            latestNoteByJournal.put(n.ParentId, n);
                        }
                        journalIds.add(n.ParentId);
                    }
                }
            }

            // -------------------------
            // 1) Update the latest Journal for each Account
            // -------------------------
            if (!accountIds.isEmpty()) {
                // Query Journals for those Accounts
                List<Journal__c> journalList = [
                    SELECT Id, Account__c, Latest_Note_on_Account__c
                    FROM Journal__c
                    WHERE Account__c IN :accountIds
                    ORDER BY CreatedDate DESC
                    LIMIT 10000
                ];

                // Map each Account to its single "latest" Journal
                Map<Id, Journal__c> accountIdToJournal = new Map<Id, Journal__c>();
                for (Journal__c jrnl : journalList) {
                    if (!accountIdToJournal.containsKey(jrnl.Account__c)) {
                        accountIdToJournal.put(jrnl.Account__c, jrnl);
                    }
                }

                List<Journal__c> journalsToUpdate = new List<Journal__c>();
                // Update the Journal with the latest Note’s Body (without updating the time stamp)
                for (Id accId : accountIdToJournal.keySet()) {
                    Note noteInst = latestNoteByAccount.get(accId);
                    if (noteInst != null) {
                        Journal__c jToUpdate = new Journal__c(
                            Id = accountIdToJournal.get(accId).Id
                        );
                        if (noteInst.Body != null && noteInst.Body.length() > 255) {
                            jToUpdate.Latest_Note_on_Account__c = noteInst.Body.substring(0, 252) + '...';
                        } else {
                            jToUpdate.Latest_Note_on_Account__c = noteInst.Body;
                        }
                        journalsToUpdate.add(jToUpdate);
                    }
                }

                if (!journalsToUpdate.isEmpty()) {
                    update journalsToUpdate;
                }
            }

            // -------------------------
            // 2) Update a Journal directly if the Note’s parent is that Journal
            // -------------------------
            if (!journalIds.isEmpty()) {
                // Query the Journals
                Map<Id, Journal__c> journalsMap = new Map<Id, Journal__c>(
                    [SELECT Id, Latest_Note_on_Account__c FROM Journal__c WHERE Id IN :journalIds]
                );

                List<Journal__c> journalsToUpdate = new List<Journal__c>();
                for (Id jId : latestNoteByJournal.keySet()) {
                    Journal__c existingJournal = journalsMap.get(jId);
                    if (existingJournal != null) {
                        Note noteInst = latestNoteByJournal.get(jId);
                        Journal__c jToUpdate = new Journal__c(Id = existingJournal.Id);
                        if (noteInst.Body != null && noteInst.Body.length() > 255) {
                            jToUpdate.Latest_Note_on_Account__c = noteInst.Body.substring(0, 252) + '...';
                        } else {
                            jToUpdate.Latest_Note_on_Account__c = noteInst.Body;
                        }
                        journalsToUpdate.add(jToUpdate);
                    }
                }
                if (!journalsToUpdate.isEmpty()) {
                    update journalsToUpdate;
                }
            }

        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs(
                '',
                'Error in handleNoteInsertUpdate',
                ex.getMessage(),
                'Error',
                'NoteTriggerHandler.handleNoteInsertUpdate',
                '',
                String.valueOf(ex.getLineNumber())
            );
        }
    }

    /**
     * Handles after-update Journal events.
     * If the Journal’s Internal_notes__c field changes, copy that into Latest_Note_on_Account__c.
     */
    public static void handleJournalUpdate(List<Journal__c> newList, Map<Id, Journal__c> oldMap) {
        try {
            List<Journal__c> journalsToUpdate = new List<Journal__c>();
            for (Journal__c jrnl : newList) {
                Journal__c oldJ = oldMap.get(jrnl.Id);
                if (jrnl.Internal_notes__c != oldJ.Internal_notes__c) {
                    Journal__c jToUpdate = new Journal__c(Id = jrnl.Id);
                    if (jrnl.Internal_notes__c != null && jrnl.Internal_notes__c.length() > 255) {
                        jToUpdate.Latest_Note_on_Account__c = jrnl.Internal_notes__c.substring(0, 252) + '...';
                    } else {
                        jToUpdate.Latest_Note_on_Account__c = jrnl.Internal_notes__c;
                    }
                    journalsToUpdate.add(jToUpdate);
                }
            }

            if (!journalsToUpdate.isEmpty()) {
                update journalsToUpdate;
            }

        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs(
                '',
                'Error in handleJournalUpdate',
                ex.getMessage(),
                'Error',
                'NoteTriggerHandler.handleJournalUpdate',
                '',
                String.valueOf(ex.getLineNumber())
            );
        }
    }
}