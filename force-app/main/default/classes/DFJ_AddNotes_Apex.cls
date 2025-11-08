public class DFJ_AddNotes_Apex {
    // DFJ - 298
    // Start
    @AuraEnabled
    public static String saveNotesAndRelateToAccount(String recId, String notesData){
        try {
            Note noteInstance = new Note();
            noteInstance.Body = notesData;
            noteInstance.ParentId = recId;
            noteInstance.Title = UserInfo.getName() + ' ' + System.now();
            insert noteInstance;
            return JSON.serialize(noteInstance);
        } catch (Exception e) {
            DFJ_ErrorLogController.addErrorLogs('Save Notes and Relate to Account', '', e.getMessage(), 'Error', 'DFJ_AddNotes_Apex.saveNotesAndRelateToAccount', '', String.valueOf(e.getLineNumber()));
            return null;
        }
    }
    // End


    @AuraEnabled
    public static String saveNotesForAddNotes(String recId, String notesData){
        try{
            List<Case> getCaseRecord = [SELECT Id,
                    AccountId
            FROM Case
            WHERE Id =:recId];

            If(getCaseRecord.isEmpty() || (!getCaseRecord.isEmpty() && getCaseRecord[0].AccountId== null)){
                return null;
            }
            Note noteInstance = new Note();
            noteInstance.Body = notesData;
            noteInstance.ParentId = getCaseRecord[0].AccountId;
            noteInstance.Title = userInfo.getName()+' '+System.now();
            insert noteInstance;
            return JSON.serialize(noteInstance);
        }catch(Exception ex){
            DFJ_ErrorLogController.addErrorLogs('', 'Creating Notes record.', ex.getMessage(), 'Error', 'DFJ_AddNotes_Apex.saveNotesForAddNotes', '', String.valueOf(ex.getLineNumber()));
            return null;
        }
    }

    /*  @AuraEnabled
      public static Boolean getCaseRecord(String recId){
          Boolean result = false;
          try{
              List<Case> getCaseList = new List<Case>();
              if(String.isNotBlank(recId)){
                  getCaseList = [SELECT Id, AccountId FROM Case WHERE Id=:recId LIMIT 1];
                  if(!getCaseList.isEmpty() && getCaseList[0].AccountId!=null){
                      result  = true;
                  }
              }
              return result;
          }catch(Exception ex){
              DFJ_ErrorLogController.addErrorLogs('', 'Getting Case record.', ex.getMessage(), 'Error', 'DFJ_AddNotes_Apex.getCaseRecord', '', String.valueOf(ex.getLineNumber()));
              return result;
          }
      }*/
    //DFJ-207
    @AuraEnabled
    public static String saveLeadNotesFromCase(String recId, String notesData){
        try{
            List<Case> getCaseRecord = [SELECT Id, Lead__c FROM Case WHERE Id =:recId];
            If(getCaseRecord.isEmpty() || (!getCaseRecord.isEmpty() && getCaseRecord[0].Lead__c== null)){
                return null;
            }
            Note noteInstance = new Note();
            noteInstance.Body = notesData;
            noteInstance.ParentId = getCaseRecord[0].Lead__c;
            noteInstance.Title = userInfo.getName()+' '+System.now();
            insert noteInstance;
            return JSON.serialize(noteInstance);
        }catch(Exception ex){
            DFJ_ErrorLogController.addErrorLogs('', 'Creating Notes record.', ex.getMessage(), 'Error', 'DFJ_AddNotes_Apex.saveLeadNotesFromCase', '', String.valueOf(ex.getLineNumber()));
            return null;
        }
    }
    @AuraEnabled
    public static CaseRecordData getCaseRecord(String recId){
        CaseRecordData caseInstance = new CaseRecordData();
        caseInstance.caseHasLead = false;
        caseInstance.caseHasAccount = false;
        // Boolean result = false;
        try{
            List<Case> getCaseList = new List<Case>();
            if(String.isNotBlank(recId)){
                getCaseList = [SELECT Id, AccountId, Lead__c FROM Case WHERE Id=:recId LIMIT 1];
                if(!getCaseList.isEmpty() && getCaseList[0].Lead__c!=null){
                    //   result  = true;
                    caseInstance.caseHasLead = true;
                }
                if(!getCaseList.isEmpty() && getCaseList[0].AccountId!=null){
                    caseInstance.caseHasAccount = true;
                }
            }
            return caseInstance;
        }catch(Exception ex){
            DFJ_ErrorLogController.addErrorLogs('', 'Getting Case record.', ex.getMessage(), 'Error', 'DFJ_AddNotes_Apex.getCaseRecord', '', String.valueOf(ex.getLineNumber()));
            return caseInstance;
        }
    }
    public class CaseRecordData{
        @AuraEnabled public Boolean caseHasAccount { get; set; }
        @AuraEnabled public Boolean caseHasLead { get; set; }
    }
}