public class SDCallCampaignStateCreation {
    public static List<telegenta__Call_Campaign_State__c> UpsertCallCampaignStateForRecord_Apex(){
        try{
            String commonFilterQuery = '';
            DateTime currentTime = DateTime.now();
            List<Lead> leadList = new List<Lead>();
            List<Lead> leadWithOutCCSList = new List<Lead>();
            List<telegenta__Call_Campaign_State__c> callCampaignStateList = new List<telegenta__Call_Campaign_State__c>();
            List<telegenta__Call_Campaign_State__c> callCampaignStateToUpsertList = new List<telegenta__Call_Campaign_State__c>();
            List<telegenta__Call_Campaign_State__c> callCampaignStateInstanceToUpsertList = new List<telegenta__Call_Campaign_State__c>();
            Map<Id,Lead> LeadIdVsLead = new Map<Id,Lead>();
            Set<String> LeadIdSet = new Set<String>();
            Map<String,List<Lead>> LeadGroupNameVsLeads = new Map<String,List<Lead>>();
            Map<String,String> LeadGroupNameVsCallCampaignId = new Map<String,String>();
            Map<Id,List<telegenta__Call_Campaign_State__c>> LeadIdVsCallCampaignStates = new Map<Id,List<telegenta__Call_Campaign_State__c>>();
            List<telegenta__Lead_group__c> leadGroupsList = new List<telegenta__Lead_group__c>();
            String outcomeId = '';
            commonFilterQuery = 'telegenta__Last_Contact_State__c = \''+'Got Appointment'+'\' AND telegenta__Next_Call_Time__c != null AND telegenta__Next_Call_Time__c > :currentTime';
            String query = 'SELECT Status,Name,Lead_Group_name__c,telegenta__Total_calls__c,telegenta__Phone_number_Id__c,telegenta__Phone_Number__c,telegenta__Next_Call_Time__c,telegenta__Last_Contact_State__c,telegenta__Unsuccessful_Calls__c,telegenta__Not_Interested_Reason__c,telegenta__Invalid_Reason__c FROM Lead WHERE '+commonFilterQuery+' LIMIT 50000';
            
            leadList = Database.query(query);
            List<telegenta__Outcome__c> outcomeList = new List<telegenta__Outcome__c>();
            outcomeList = [SELECT Id,Name FROM telegenta__Outcome__c WHERE Name = 'Appointment' LIMIT 1];
            if(!outcomeList.isEmpty()){
                outcomeId = outcomeList[0].Id;
            }
            if(!leadList.isEmpty()){
                                System.debug('leadList ====>>'+JSON.serialize(leadList));
                System.debug('leadList size====>>'+leadList.size());
                for(Lead leadLoop : leadList){
                    LeadIdVsLead.put(leadLoop.Id,leadLoop);
                }  
                callCampaignStateList = [SELECT Id, telegenta__Next_Call_Time__c,telegenta__Unsuccessful_calls__c,telegenta__Total_Unsucccessful_Call__c, telegenta__Total_Calls__c,telegenta__Last_Call_Time__c,telegenta__Lead__c, telegenta__Last_Outcome__c,telegenta__Has_appointment__c,telegenta__Call_Campaign__c FROM telegenta__Call_Campaign_State__c WHERE telegenta__Lead__c IN : LeadIdVsLead.keySet() LIMIT 10000];
                if(!callCampaignStateList.isEmpty()){
                    for(telegenta__Call_Campaign_State__c callCampaignStateLoop : callCampaignStateList){
                        if(!LeadIdVsCallCampaignStates.containsKey(callCampaignStateLoop.telegenta__Lead__c)){
                            LeadIdVsCallCampaignStates.put(callCampaignStateLoop.telegenta__Lead__c,new List<telegenta__Call_Campaign_State__c>());
                        }
                        if(callCampaignStateLoop.telegenta__Next_Call_Time__c != null){
                            if(LeadIdVsLead.get(callCampaignStateLoop.telegenta__Lead__c).telegenta__Next_Call_Time__c != callCampaignStateLoop.telegenta__Next_Call_Time__c){
                                LeadIdVsCallCampaignStates.get(callCampaignStateLoop.telegenta__Lead__c).add(callCampaignStateLoop);
                            }
                        } else{
                            LeadIdVsCallCampaignStates.get(callCampaignStateLoop.telegenta__Lead__c).add(callCampaignStateLoop);  
                        }            
                    }
                    leadWithOutCCSList = [SELECT Status, Name,Lead_Group_name__c,telegenta__Total_calls__c,telegenta__Phone_number_Id__c,telegenta__Phone_Number__c, telegenta__Next_Call_Time__c, telegenta__Not_Interested_Reason__c, telegenta__Invalid_Reason__c  FROM Lead WHERE Id NOT IN :LeadIdVsCallCampaignStates.keySet() AND Id IN : LeadIdVsLead.keySet() LIMIT 10000];            
                }
                System.debug('LeadIdVsCallCampaignStates ====>>'+JSON.serialize(LeadIdVsCallCampaignStates));
                System.debug('leadWithOutCCSList ====>>'+JSON.serialize(leadWithOutCCSList));
                System.debug('leadWithOutCCSList size====>>'+leadWithOutCCSList.size());
                if(!leadWithOutCCSList.isEmpty()){
                    for(Lead leadLoop : leadWithOutCCSList){
                        LeadIdSet.add(leadLoop.Id);
                        if(!LeadGroupNameVsLeads.containsKey(leadLoop.Lead_Group_name__c)){
                            LeadGroupNameVsLeads.put(leadLoop.Lead_Group_name__c,new List<Lead>());
                        }
                        LeadGroupNameVsLeads.get(leadLoop.Lead_Group_name__c).add(leadLoop); 
                        
                    }
                    for(String key : LeadGroupNameVsLeads.keySet()){
                        System.debug(key+' LeadGroupName has '+LeadGroupNameVsLeads.get(key).size()+' Leads');
                        if(key == 'Kampagne 1'){
                            LeadGroupNameVsLeads.put('DFJ - Kampagne 1',LeadGroupNameVsLeads.get(key));
                        } else if(key == 'TD Kampagne 1'){
                            LeadGroupNameVsLeads.put('TDK - Kampagne 1',LeadGroupNameVsLeads.get(key));
                        }            
                    }
                    
                    leadGroupsList = [SELECT Id,Name,telegenta__Call_Campaign__c FROM telegenta__Lead_group__c WHERE Name IN :LeadGroupNameVsLeads.keySet() LIMIT 10000];
                    if(!leadGroupsList.isEmpty()){
                        for(telegenta__Lead_group__c leadGroupInstance : leadGroupsList){
                            if(leadGroupInstance.telegenta__Call_Campaign__c != null){
                                if(leadGroupInstance.Name == 'DFJ - Kampagne 1'){
                                    LeadGroupNameVsCallCampaignId.put('Kampagne 1',leadGroupInstance.telegenta__Call_Campaign__c);                        
                                } else if(leadGroupInstance.Name == 'TDK - Kampagne 1'){
                                    LeadGroupNameVsCallCampaignId.put('TD Kampagne 1',leadGroupInstance.telegenta__Call_Campaign__c);     
                                }
                            }
                        }          
                    }
                }
                System.debug('LeadGroupNameVsCallCampaignId ====>>'+JSON.serialize(LeadGroupNameVsCallCampaignId));
                for(String leadInstance : LeadIdVsLead.keySet()){
                    telegenta__Call_Campaign_State__c callCampaignStateInstance = new telegenta__Call_Campaign_State__c();
                    if(LeadIdVsCallCampaignStates.containsKey(leadInstance)){ 
                        for(telegenta__Call_Campaign_State__c callCampaignStateLoop : LeadIdVsCallCampaignStates.get(leadInstance)){
                            callCampaignStateLoop.telegenta__Unsuccessful_calls__c = LeadIdVsLead.get(leadInstance).telegenta__Unsuccessful_Calls__c == null?0:LeadIdVsLead.get(leadInstance).telegenta__Unsuccessful_Calls__c;
                            callCampaignStateLoop.telegenta__Total_Unsucccessful_Call__c = LeadIdVsLead.get(leadInstance).telegenta__Unsuccessful_Calls__c == null?0:LeadIdVsLead.get(leadInstance).telegenta__Unsuccessful_Calls__c;
                            callCampaignStateLoop.telegenta__Total_Calls__c = LeadIdVsLead.get(leadInstance).telegenta__Total_Calls__c == null?0:LeadIdVsLead.get(leadInstance).telegenta__Total_Calls__c;
                            callCampaignStateLoop.telegenta__Last_Outcome__c = callCampaignStateInstance.telegenta__Last_Outcome__c == null ? outcomeId : callCampaignStateInstance.telegenta__Last_Outcome__c;
                            callCampaignStateLoop.telegenta__Has_appointment__c = true;  
                            callCampaignStateInstance.telegenta__Last_Call_Time__c = Datetime.now();
                            callCampaignStateLoop.telegenta__Next_Call_Time__c = LeadIdVsLead.get(leadInstance).telegenta__Next_Call_Time__c;     
                            callCampaignStateToUpsertList.add(callCampaignStateLoop);
                        }
                    } else{
                        if(LeadIdSet.contains(leadInstance)){
                            callCampaignStateInstance.telegenta__Unsuccessful_calls__c = LeadIdVsLead.get(leadInstance).telegenta__Unsuccessful_Calls__c == null?0:LeadIdVsLead.get(leadInstance).telegenta__Unsuccessful_Calls__c;
                            callCampaignStateInstance.telegenta__Total_Unsucccessful_Call__c = LeadIdVsLead.get(leadInstance).telegenta__Unsuccessful_Calls__c == null?0:LeadIdVsLead.get(leadInstance).telegenta__Unsuccessful_Calls__c;
                            callCampaignStateInstance.telegenta__Total_Calls__c = LeadIdVsLead.get(leadInstance).telegenta__Total_Calls__c == null?0:LeadIdVsLead.get(leadInstance).telegenta__Total_Calls__c;
                            callCampaignStateInstance.telegenta__Last_Call_Time__c = Datetime.now();
                            callCampaignStateInstance.telegenta__Lead__c = leadInstance;
                            callCampaignStateInstance.telegenta__Last_Outcome__c = outcomeId;
                            callCampaignStateInstance.telegenta__Has_appointment__c = true;
                            callCampaignStateInstance.telegenta__Next_Call_Time__c = LeadIdVsLead.get(leadInstance).telegenta__Next_Call_Time__c; 
                            if(LeadGroupNameVsCallCampaignId.containsKey(LeadIdVsLead.get(leadInstance).Lead_Group_name__c)){
                                callCampaignStateInstance.telegenta__Call_Campaign__c = LeadGroupNameVsCallCampaignId.get(LeadIdVsLead.get(leadInstance).Lead_Group_name__c);  
                            }                
                            callCampaignStateToUpsertList.add(callCampaignStateInstance); 
                        }
                    }
                }
                System.debug('callCampaignStateToUpsertList ====>>'+JSON.serialize(callCampaignStateToUpsertList));
                System.debug('callCampaignStateToUpsertList Size====>>'+callCampaignStateToUpsertList.size());
                
                for(telegenta__Call_Campaign_State__c campaignStateLoop : callCampaignStateToUpsertList){
                    if(campaignStateLoop.telegenta__Call_Campaign__c != null){
                        callCampaignStateInstanceToUpsertList.add(campaignStateLoop);
                    }
                    
                }
                System.debug('callCampaignStateInstanceToUpsertList ====>>'+JSON.serialize(callCampaignStateInstanceToUpsertList));
                System.debug('callCampaignStateInstanceToUpsertList Size====>>'+callCampaignStateInstanceToUpsertList.size());
                upsert callCampaignStateInstanceToUpsertList;
            }
        }catch(Exception ex){
            // DR_DialerRules.addErrorLogs('recordId','Inserting/updating call campaign state.',JSON.serialize(ex.getMessage()),'Error','DR_MigrationController.UpdateCallCampaignStateForRecord_Apex',ex.getStackTraceString(),String.valueOf(ex.getLineNumber()));
            System.debug('Error---------'+ex.getMessage()+' At line number'+ex.getLineNumber());
        }
        return null;
    }
}