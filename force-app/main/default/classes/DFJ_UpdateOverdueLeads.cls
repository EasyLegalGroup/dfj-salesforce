/* 
   * @ Version : 1.0
   * @ Created Date : 2021-01-19
   * @Description : This class will be as schedulable class, This class will update the over due leads to leads with status new and
   *  assign the respective queue id according to the market unit of lead to the lead owner */
global class DFJ_UpdateOverdueLeads Implements Schedulable {

    /* 
    * @Description  This method invokes the method which perform the functionality to correct over due leads
    * @Param		SchedulableContext - sc instance
    * @Return       void 

    */
    
    global void execute(SchedulableContext sc)
        {
            try{
                UpdateOverdueLeads_Apex();
            }
            
            catch(Exception ex){
                //System.debug('Error----'+ex.getMessage()+' at line number -----'+ex.getLineNumber());
                addErrorLogs('No record id available','Executing the apex.',JSON.serialize(ex.getMessage()),'Error','DFJ_UpdateOverdueLeads');
            }
            
        }

    /* 
    * @Description  This Method will update the over due leads to leads with status new and
    *  assign the respective queue id according to the market unit of lead to the lead owner
    * @Param		no param
    * @Return       Boolean 
    */

    public static Boolean UpdateOverdueLeads_Apex(){
        try{

            List<Group> queuelist = new List<Group>();
            Map<String,Id> MarketUnitVsQueueName = new Map<String,Id>();
            
            // Calling a method to get map between market unit of lead and queue id
            MarketUnitVsQueueName = FetchAllQueues();  
            
            String status = 'Working';
            List<Sobject> recordList = new List<Sobject>();
            String mainQuery = 'SELECT Name,Market_Unit__c,Status,OwnerId,telegenta__Last_Contact_State__c FROM Lead WHERE isConverted = false AND Status = \''+status+'\' AND telegenta__Next_Call_Time__c < LAST_N_DAYS:2 LIMIT 10000';
            recordList = Database.query(mainQuery);

            System.debug('recordList (UpdateOverdueLeads_Apex) ----'+recordList);

            if(!recordList.isEmpty()){
                for(Sobject recordLoop : recordList){
                    if(MarketUnitVsQueueName.containskey(String.valueOf(recordLoop.get('Market_Unit__c')))){
                        recordLoop.put('Status','New');
                        recordLoop.put('telegenta__Last_Contact_State__c','Released');
                        recordLoop.put('OwnerId',MarketUnitVsQueueName.get(String.valueOf(recordLoop.get('Market_Unit__c'))));
                    }
                    
                }
            }
            //System.debug('recordList--updated with queue id assigned (UpdateOverdueLeads_Apex) ----'+recordList);
            // updating the recordList with update queue id according to the market unit
            update recordList;
        }
        catch(Exception ex){
            //System.debug('Error----'+ex.getMessage()+' at line number -----'+ex.getLineNumber());
            addErrorLogs('No record id available','Updating overdue leads.',JSON.serialize(ex.getMessage()),'Error','DFJ_UpdateOverdueLeads.UpdateOverdueLeads_Apex');
        }
        return null;

    }

    /* 
    * @Description  This Method to get all the queues in the org.
    * @Param		no params
    * @Return       Map<String,Id> - Between market unit of lead and queue id
    */
        public static Map<String,Id> FetchAllQueues(){
            try{
                List<Group> queuelist = new List<Group>();
                Map<String,Id> MarketUnitVsQueueName = new Map<String,Id>(); 
                queuelist = [select Id,Name from Group where  Type = 'Queue'];  
                   
               //system.debug('queuelist (FetchAllQueues)=====>'+queuelist);
                if(!queueList.isEmpty()){
                    if(!queueList.isEmpty()){
                        for(Group queueLoop : queuelist){
                            if(queueLoop.Name == 'DFJ Leads'){
                                MarketUnitVsQueueName.put('DFJ_DK',queueLoop.Id);
                            } else if(queueLoop.Name == 'Sweden Leads'){
                                MarketUnitVsQueueName.put('FA_SE',queueLoop.Id);
                            } 
                            else if(queueLoop.Name == 'Testamente_dk'){
                                MarketUnitVsQueueName.put('Testamente_DK',queueLoop.Id);
                            } 
                        }
                        //system.debug('MarketUnitVsQueueName (FetchAllQueues)=====>'+MarketUnitVsQueueName);
                    }
                    return MarketUnitVsQueueName;
                }
                else{
                    //addErrorLogs('No record id available','Getting queues','No queue found.','Error','DR_DialerRulesUtilities.FetchAllQueues');
                    return null;
                }
            }catch(Exception ex){
                //System.debug('Error----'+ex.getMessage()+' at line number----'+ex.getLineNumber());
                addErrorLogs('No record id available','Getting queues',JSON.serialize(ex.getMessage()),'Error','DR_DialerRulesUtilities.FetchAllQueues');
            }
            return null;
        }


    /* 
    * @Description  This Method to get all the queues in the org.
    * @Param		String - Cron Expression
    * @Return       String - JobId 
    */
        global static String scheduleUpdateOverdueLeads(String cronExpression) {       
            try{
                DFJ_UpdateOverdueLeads SC = new DFJ_UpdateOverdueLeads(); 
                return System.schedule('scheduleUpdateOverdueLeads', cronExpression, SC);
            }   catch(Exception ex){
                //System.debug('Error----'+ex.getMessage()+' at line number----'+ex.getLineNumber());
                addErrorLogs('No record id available','Scheduling the apex.',JSON.serialize(ex.getMessage()),'Error','DFJ_UpdateOverdueLeads.scheduleUpdateOverdueLeads');
            }
            return null;


        }

    /* 
    * @Description  This method will insert error logs .
    * @Param		String - recordId, 
                    String - event, 
                    String - message, 
                    String - severnity, 
                    String - source
    * @Return       void
    */
        public static void addErrorLogs(String recordId, String event, String message, String severnity,String source){
            telegenta__Log__c logObj = new telegenta__Log__c();
            logObj.telegenta__Affected_record__c = recordId;
            logObj.telegenta__Event__c = event;
            logObj.telegenta__Message__c = message;
            logObj.telegenta__Severity__c = severnity;
            logObj.telegenta__Source__c = source;
            insert logObj;
        }
}