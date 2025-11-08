public class DFJ_HandleEventCampaignStatus {
    @AuraEnabled
    public static ResponseWrapper  handleCancelEvent( String campId, selectedInputWrapper selectedReason) {//DFJ-159 Changes added reason in class param
        ResponseWrapper result = new ResponseWrapper();
        try{
             //DFJ-159 Changes
            List<Lead> getLeadList = new List<Lead>();
            List<Lead> updateLeadsList = new List<Lead>();
            List<Campaign> campToUpdateList  = new List<Campaign>();
            //DFJ-176 Changes
            List<Contact> contactToUpdate  = new List<Contact>();
            //End
           
            List<Campaign> campaignList = [SELECT Id,Market_Unit__c,Start__c,End__c, Reason_for_Cancellation_Text__c,Reason_for_Cancellation_Input__c,Reason_for_Cancellation__c,Status,Host__r.Contact__c,Related_Event_ID__c,Host__c FROM Campaign WHERE Id =:campId AND Related_Event_ID__c!=null LIMIT 1];
            if(!campaignList.isEmpty()){
                Campaign updateCampaign = new Campaign();
                 
                updateCampaign.Id = campaignList[0].Id;
                updateCampaign.Status = 'Cancelled';
                updateCampaign.Cancelled__c = true;
                updateCampaign.Date_Of_Cancellation__c = System.now();
                //DFJ-176 Changes Added reason for cancellations fields 
                updateCampaign.Reason_for_Cancellation_Text__c = !String.isBlank(selectedReason.writeText) ? selectedReason.writeText : !String.isBlank(campaignList[0].Reason_for_Cancellation_Text__c) ? campaignList[0].Reason_for_Cancellation_Text__c : null;
                updateCampaign.Reason_for_Cancellation__c =  !String.isBlank(selectedReason.reasonFromPickList) ? selectedReason.reasonFromPickList : !String.isBlank(campaignList[0].Reason_for_Cancellation__c) ? campaignList[0].Reason_for_Cancellation__c : null;
                updateCampaign.Reason_for_Cancellation_Input__c = !String.isBlank(selectedReason.inputSelection) ? selectedReason.inputSelection : !String.isBlank(campaignList[0].Reason_for_Cancellation_Input__c) ? campaignList[0].Reason_for_Cancellation_Input__c : null;
                
                //DFJ-159 Changes
                updateCampaign.Open_for_Bookings__c = false;
                campToUpdateList.add(updateCampaign);
            }
            
            //Changes DFJ-176
                List<Contact> getContactRecord = [SELECT Id,Cancel_Reschedule_LocationChange_Event__c FROM Contact WHERE Id =: campaignList[0].Host__r.Contact__c LIMIT 1];
                if(!getContactRecord.isEmpty()){
                    Contact contactRecord = new Contact();
                    contactRecord.Id = getContactRecord[0].Id;
                   // contactRecord.Cancel_Reschedule_LocationChange_Event__c = !String.isBlank(selectedReason.writeText) ? selectedReason.writeText : !String.isBlank(selectedReason.reasonFromPickList) ? selectedReason.reasonFromPickList : !String.isBlank(getContactRecord[0].Cancel_Reschedule_LocationChange_Event__c) ? getContactRecord[0].Cancel_Reschedule_LocationChange_Event__c : null ;
                    //DFJ-237
                    if(!String.isBlank(selectedReason.writeText)){
                        contactRecord.Cancel_Reschedule_LocationChange_Event__c = selectedReason.writeText;
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (campaignList[0].Market_Unit__c.equals('DFJ_DK') ||campaignList[0].Market_Unit__c.equals('Testamente_DK')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'for få tilmeldte';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (campaignList[0].Market_Unit__c.equals('FA_SE') ||campaignList[0].Market_Unit__c.equals('Testamente_SV')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'för få anmälda';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (campaignList[0].Market_Unit__c.equals('FA_SE') ||campaignList[0].Market_Unit__c.equals('Testamente_SV')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'sjukdom';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (campaignList[0].Market_Unit__c.equals('DFJ_DK') ||campaignList[0].Market_Unit__c.equals('Testamente_DK')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'sygdom';
                    }
                    contactRecord.Campaign_Current_Start_Time__c =  campaignList[0].Start__c != null ? campaignList[0].Start__c : null;
                  //  contactRecord.Campaign_Previous_Start_Time__c = campaignList[0].End__c != null ? campaignList[0].End__c : null;
                    contactToUpdate.add(contactRecord);
                }
            //End
            
            List<CampaignMember> campaignMemberList = [SELECT Id, Event_Status__c FROM CampaignMember WHERE CampaignId =:campId AND Related_Event_ID__c!=null];
            List<CampaignMember> campMemberToUpdateList  = new List<CampaignMember>();
            if(!campaignMemberList.isEmpty()){
                for(CampaignMember memberInst:campaignMemberList ){
                    CampaignMember member = new CampaignMember();
                    member.Id = memberInst.Id;
                    member.Event_Status__c = 'Cancelled';
                    campMemberToUpdateList.add(member);
                }
            }            
            //DFJ-159 Changes
                getLeadList = [SELECT Id,Reason_for_Lecture_Cancellation__c,Cancel_Reschedule_LocationChange_Event__c FROM Lead WHERE Related_Event_ID__c =: campaignList[0].Related_Event_ID__c LIMIT 10000];
            if(!getLeadList.isEmpty()){
                for(Lead record:getLeadList){
                    Lead leadInstance = new Lead();
                    leadInstance.Id = record.Id;
                    leadInstance.Reason_for_Lecture_Cancellation__c = !String.isBlank(selectedReason.reasonFromPickList) ? selectedReason.reasonFromPickList : !String.isBlank(getLeadList[0].Reason_for_Lecture_Cancellation__c) ? getLeadList[0].Reason_for_Lecture_Cancellation__c : null ;
                    leadInstance.Event_Status__c = 'Cancelled';
                    //DFJ-176 Changes
                   // leadInstance.Cancel_Reschedule_LocationChange_Event__c = !String.isBlank(selectedReason.writeText) ? selectedReason.writeText : !String.isBlank(selectedReason.reasonFromPickList) ? selectedReason.reasonFromPickList : !String.isBlank(getLeadList[0].Cancel_Reschedule_LocationChange_Event__c) ? getLeadList[0].Cancel_Reschedule_LocationChange_Event__c : null ;
                   //End
                   // DFJ-237 Cancel_Reschedule_LocationChange_Event__c
                   	 if(!String.isBlank(selectedReason.writeText)){
                        leadInstance.Cancel_Reschedule_LocationChange_Event__c = selectedReason.writeText;
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (campaignList[0].Market_Unit__c.equals('DFJ_DK') ||campaignList[0].Market_Unit__c.equals('Testamente_DK')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'for få tilmeldte';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (campaignList[0].Market_Unit__c.equals('FA_SE') ||campaignList[0].Market_Unit__c.equals('Testamente_SV')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'för få anmälda';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (campaignList[0].Market_Unit__c.equals('FA_SE') ||campaignList[0].Market_Unit__c.equals('Testamente_SV')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'sjukdom';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (campaignList[0].Market_Unit__c.equals('DFJ_DK') ||campaignList[0].Market_Unit__c.equals('Testamente_DK')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'sygdom';
                    }
                   	leadInstance.Campaign_Current_Start_Time__c =  campaignList[0].Start__c != null ? campaignList[0].Start__c : null;
                  //  leadInstance.Campaign_Previous_Start_Time__c = campaignList[0].End__c != null ? campaignList[0].End__c : null;
                    updateLeadsList.add(leadInstance);
                }
            }
            //End
            List<Event> eventList = [SELECT Id ,Event_Status__c,Related_Event_ID__c FROM Event WHERE Related_Event_ID__c =:campaignList[0].Related_Event_ID__c LIMIT 1 ];
            List<Event> eventToUpdateList  = new List<Event>();
            if(!eventList.isEmpty() && eventList[0].Event_Status__c!='Cancelled'){
                Event updateEventStatus = new Event();
                updateEventStatus.Id = eventList[0].Id;
                updateEventStatus.Cancelled__c = true;
                updateEventStatus.Event_Status__c = 'Cancelled';
                updateEventStatus.Date_Of_Cancellation__c = System.now();
                eventToUpdateList.add(updateEventStatus);   
            }
            if(!campToUpdateList.isEmpty()){
                update campToUpdateList;
                result.campList = campToUpdateList;
                System.debug('campToUpdateList-->'+campToUpdateList);
            }//DFJ-159
            if(!updateLeadsList.isEmpty()){
                update updateLeadsList;
                result.leadList = updateLeadsList;
                System.debug('updateLeadsList-->'+updateLeadsList);
            }//End
            //DFJ-176 Changes
            if(!contactToUpdate.isEmpty()){
                update contactToUpdate;
                System.debug('contactToUpdate-->'+contactToUpdate);
            }
            //End
            if(!eventToUpdateList.isEmpty()){
                update eventToUpdateList;
                result.eventList = eventToUpdateList;
                System.debug('eventToUpdateList-->'+eventToUpdateList);
            }
            if(!campMemberToUpdateList.isEmpty()){
                update campMemberToUpdateList;
                result.campaignMemberList = campMemberToUpdateList;
                System.debug('campMemberToUpdateList-->'+campMemberToUpdateList);
            }
            
            
        }catch(Exception ex){
            DFJ_ErrorLogController.addErrorLogs('', 'Creating Order record.', ex.getMessage(), 'Error', 'DFJ_HandleEventCampaignStatus.handleCancelEvent', '', String.valueOf(ex.getLineNumber()));
        }
        return result;
    }
    
    @AuraEnabled
    public static ResponseWrapper  handleRescheduleEvent ( String campId,String rescheduledateTime,selectedInputWrapper selectedReason) {
        ResponseWrapper result = new ResponseWrapper();
        try{
            List<Campaign> campToUpdateList  = new List<Campaign>();
            //DFJ-176 Changes
            List<Lead> updateLeadsList = new List<Lead>();
            List<Contact> contactToUpdate  = new List<Contact>();
            //End
             DateTime dateValue;
            String dateValueFormatted;
            if(!String.isBlank(rescheduledateTime)){
                dateValue = DateTime.valueOf(rescheduledateTime);
                dateValue = DateTime.valueOfGmt(rescheduleDateTime);
				dateValueFormatted = dateValue.format('dd-MM-yyyy');
            }
            System.debug('dateValueFormatted-->'+dateValueFormatted);
            List<Campaign> campaignList = [SELECT Id,Market_Unit__c,Start__c,Host__r.Name, End__c,Reason_for_Rescheduling_Text__c,Reason_for_Rescheduling_Input__c,Reason_for_Rescheduling__c,Original_date_time__c, Host__r.Contact__c,Status,Related_Event_ID__c FROM Campaign WHERE Id =:campId AND Related_Event_ID__c!=null LIMIT 1];
            
            if(!campaignList.isEmpty()){
                Campaign updateCampaign = new Campaign();
                updateCampaign.Id = campaignList[0].Id;
                //DFJ-237 added name
                updateCampaign.Name = !String.isBlank(campaignList[0].Host__r.Name) ? campaignList[0].Host__r.Name+' - ' + dateValueFormatted : campaignList[0].Host__r.Name;
                System.debug('updateCampaign.Name-->'+updateCampaign.Name);
                updateCampaign.Status = campaignList[0].Status!='Scheduled' ? 'Scheduled' : campaignList[0].Status ;
             //   Update Original_date_time__c to have values when the record if rescheduled first time.
                updateCampaign.Original_date_time__c = campaignList[0].Original_date_time__c == null ? campaignList[0].Start__c : campaignList[0].Original_date_time__c ;
                //DFJ-176 Changes Added reason for cancellations fields 
                //DFJ-237 -2h hrs in Start__c and add Start__c in to trigger the flow.
                updateCampaign.Start__c = !String.isBlank(rescheduledateTime) ? dateValue.addHours(-2) : System.now();
                updateCampaign.End__c = !String.isBlank(rescheduledateTime) ? dateValue.addHours(1) : System.now();
               // updateCampaign.Start__c = !String.isBlank(rescheduledateTime) ? dateValue.addHours(2) : System.now();
                updateCampaign.Reason_for_Rescheduling_Text__c = !String.isBlank(selectedReason.writeText) ? selectedReason.writeText : !String.isBlank(campaignList[0].Reason_for_Rescheduling_Text__c) ? campaignList[0].Reason_for_Rescheduling_Text__c : null;
                updateCampaign.Reason_for_Rescheduling__c =  !String.isBlank(selectedReason.reasonFromPickList) ? selectedReason.reasonFromPickList : !String.isBlank(campaignList[0].Reason_for_Rescheduling__c) ? campaignList[0].Reason_for_Rescheduling__c : null ;
                updateCampaign.Reason_for_Rescheduling_Input__c = !String.isBlank(selectedReason.inputSelection) ? selectedReason.inputSelection :!String.isBlank(campaignList[0].Reason_for_Rescheduling_Input__c) ? campaignList[0].Reason_for_Rescheduling_Input__c : null;
                campToUpdateList.add(updateCampaign);
            }
            //Changes DFJ-176
                List<Contact> getContactRecord = [SELECT Id FROM Contact WHERE Id =: campaignList[0].Host__r.Contact__c LIMIT 1];
                if(!getContactRecord.isEmpty()){
                    Contact contactRecord = new Contact();
                    contactRecord.Id = getContactRecord[0].Id;
                  //  contactRecord.Cancel_Reschedule_LocationChange_Event__c = !String.isBlank(selectedReason.writeText) ? selectedReason.writeText : !String.isBlank(selectedReason.reasonFromPickList) ? selectedReason.reasonFromPickList : '';
                    //DFJ-237 -2hrs + Cancel_Reschedule_LocationChange_Event__c
                    if(!String.isBlank(selectedReason.writeText)){
                        contactRecord.Cancel_Reschedule_LocationChange_Event__c = selectedReason.writeText;
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (campaignList[0].Market_Unit__c.equals('DFJ_DK') ||campaignList[0].Market_Unit__c.equals('Testamente_DK')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'for få tilmeldte';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (campaignList[0].Market_Unit__c.equals('FA_SE') ||campaignList[0].Market_Unit__c.equals('Testamente_SV')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'för få anmälda';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (campaignList[0].Market_Unit__c.equals('FA_SE') ||campaignList[0].Market_Unit__c.equals('Testamente_SV')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'sjukdom';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (campaignList[0].Market_Unit__c.equals('DFJ_DK') ||campaignList[0].Market_Unit__c.equals('Testamente_DK')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'sygdom';
                    }
                    contactRecord.Campaign_Current_Start_Time__c =  !String.isBlank(rescheduledateTime) ? dateValue.addHours(-2) : null;
                    //contactRecord.Campaign_Current_Start_Time__c =  !String.isBlank(rescheduledateTime) ? dateValue.addHours(-2) : null;
                    contactRecord.Campaign_Previous_Start_Time__c = campaignList[0].Start__c != null ? campaignList[0].Start__c : null;
                    contactToUpdate.add(contactRecord);
                }
                List<Lead> getLeadList = [SELECT Id FROM Lead WHERE Related_Event_ID__c =: campaignList[0].Related_Event_ID__c LIMIT 10000];
            if(!getLeadList.isEmpty()){
                for(Lead record:getLeadList){
                    Lead leadInstance = new Lead();
                    leadInstance.Id = record.Id;
                   // leadInstance.Cancel_Reschedule_LocationChange_Event__c = !String.isBlank(selectedReason.writeText) ? selectedReason.writeText : !String.isBlank(selectedReason.reasonFromPickList) ? selectedReason.reasonFromPickList : '';
                    //DFJ-237 -2hrs +Cancel_Reschedule_LocationChange_Event__c
                    if(!String.isBlank(selectedReason.writeText)){
                        leadInstance.Cancel_Reschedule_LocationChange_Event__c = selectedReason.writeText;
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (campaignList[0].Market_Unit__c.equals('DFJ_DK') ||campaignList[0].Market_Unit__c.equals('Testamente_DK')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'for få tilmeldte';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (campaignList[0].Market_Unit__c.equals('FA_SE') ||campaignList[0].Market_Unit__c.equals('Testamente_SV')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'för få anmälda';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (campaignList[0].Market_Unit__c.equals('FA_SE') ||campaignList[0].Market_Unit__c.equals('Testamente_SV')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'sjukdom';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (campaignList[0].Market_Unit__c.equals('DFJ_DK') ||campaignList[0].Market_Unit__c.equals('Testamente_DK')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'sygdom';
                    }
                    System.debug('check-->'+ selectedReason.reasonFromPickList.equals('Too few bookings'));
                    leadInstance.Event_DateTime__c = !String.isBlank(rescheduledateTime) ? dateValue.addHours(-2) : System.now();
                    //leadInstance.Event_DateTime__c = !String.isBlank(rescheduledateTime) ? dateValue : System.now();
                    leadInstance.Campaign_Current_Start_Time__c =  !String.isBlank(rescheduledateTime) ? dateValue.addHours(-2) : null;
                    leadInstance.Campaign_Previous_Start_Time__c = campaignList[0].Start__c != null ? campaignList[0].Start__c : null;
                    updateLeadsList.add(leadInstance);
                }
            }
            //End
            List<Event> eventList = [SELECT Id ,Subject,Event_Status__c,Related_Event_ID__c FROM Event WHERE Related_Event_ID__c =:campaignList[0].Related_Event_ID__c LIMIT 1 ];
           
            List<Event> eventToUpdateList  = new List<Event>();
            if(!eventList.isEmpty()){
                Event updateEventStatus = new Event();
                updateEventStatus.Id = eventList[0].Id;
                updateEventStatus.Rescheduled__c = true;
                updateEventStatus.Event_Status__c = 'Rescheduled';
                updateEventStatus.Date_of_rescheduling__c = System.now();
                //DFJ-237 Update the value StartDateTime to have -2 in the selected time +Subject
                updateEventStatus.Subject = !String.isBlank(campaignList[0].Host__r.Name) ? campaignList[0].Host__r.Name+' - ' + dateValueFormatted : eventList[0].Subject;
                updateEventStatus.StartDateTime = !String.isBlank(rescheduledateTime) ? dateValue.addHours(-2) : System.now();
                updateEventStatus.EndDateTime = !String.isBlank(rescheduledateTime) ? dateValue.addHours(1) : System.now();
               // updateEventStatus.EndDateTime = !String.isBlank(rescheduledateTime) ?  dateValue.addHours(1) : System.now().addHours(1);
                system.debug('updateEventStatus'+updateEventStatus);
                eventToUpdateList.add(updateEventStatus);        
            }
            //DFJ-176 Changes
            if(!contactToUpdate.isEmpty()){
                update contactToUpdate;
                System.debug('contactToUpdate-->'+contactToUpdate);
			}
            if(!updateLeadsList.isEmpty()){
                update updateLeadsList;
                result.leadList = updateLeadsList;
                System.debug('leadList-->'+updateLeadsList);
            }//End
            if(!campToUpdateList.isEmpty()){
                update campToUpdateList;
                result.campList = campToUpdateList;
                System.debug('campList-->'+campToUpdateList);
            }
            if(!eventToUpdateList.isEmpty()){
                update eventToUpdateList;
                result.eventList = eventToUpdateList;
                System.debug('eventList-->'+eventToUpdateList);
            }
            
        }catch(Exception ex){
            DFJ_ErrorLogController.addErrorLogs('', 'Creating Order record.', ex.getMessage(), 'Error', 'DFJ_HandleEventCampaignStatus.handleRescheduleEvent', '', String.valueOf(ex.getLineNumber()));
            // System.debug('msg-->'+e.getMessage()+' in line -->'+e.getLineNumber());
        }
        return result;
        
    }

    @AuraEnabled
    public static List<Hosts__c>  getAllHosts() {
        try{
            List<Hosts__c> getAllHostList= [SELECT Id, Host_ID__c,Name FROM Hosts__c];
            return getAllHostList;
        }catch(Exception ex){
            DFJ_ErrorLogController.addErrorLogs('', 'Creating Order record.', ex.getMessage(), 'Error', 'DFJ_HandleEventCampaignStatus.getAllHosts', '', String.valueOf(ex.getLineNumber()));
            // System.debug('msg-->'+e.getMessage()+' in line -->'+e.getLineNumber());
            return null;
        }
        
    }
    //DFJ-176
      @AuraEnabled(cacheable=true)
    public static ResponseWrapper getCurrentHostsEmail(String campId) {
        ResponseWrapper result = new ResponseWrapper();
        try{
            List<Campaign> getCurrentCampaign = [SELECT Id, Host__r.Contact__r.Email FROM Campaign WHERE Id=:campId LIMIT 1];
            DFJ_Send_Email_To_Host_Or_Attendees__c sendEmailConfigurations = DFJ_Send_Email_To_Host_Or_Attendees__c.getOrgDefaults();
            if(!getCurrentCampaign.isEmpty() && getCurrentCampaign[0].Host__r.Contact__r.Email!=null){
                result.campList = getCurrentCampaign;
            }
            result.allowSendingEmail = sendEmailConfigurations.Allow_Sending_Emails__c;
            return result;
          //  return getCurrentCampaign[0].Host__r.Contact__r.Email;
        }catch(Exception ex){
            DFJ_ErrorLogController.addErrorLogs('', 'Getting Campaign record.', ex.getMessage(), 'Error', 'DFJ_HandleEventCampaignStatus.getCurrentHostsEmail', '', String.valueOf(ex.getLineNumber()));
            // System.debug('msg-->'+e.getMessage()+' in line -->'+e.getLineNumber());
            return null;
        }
        
    }
//End
    @AuraEnabled
    public static ResponseWrapper  hostLocationChange(String campId,String hostId,selectedInputWrapper selectedReason ) {
        ResponseWrapper result = new ResponseWrapper();
        try{
            List<Campaign> campToUpdate = new List<Campaign>();
            List<Contact> contactToUpdate = new List<Contact>();
            //DFJ-176 Changes
            List<Lead> updateLeadsList = new List<Lead>();
            //End
            List<Event> eventToUpdate = new List<Event>();
            if(!String.isBlank(campId) && !String.isBlank(hostId)){
                List<Campaign> getCampaign= [SELECT Id,Start__c,Market_Unit__c, Name,Venue__c,Host__c,Host_ID__c,Related_Event_ID__c FROM Campaign WHERE Id =:campId AND Related_Event_ID__c!=null LIMIT 1];
                List<Hosts__c> getRelatedHost= [SELECT Id,Address__c, Zip_Code__c, City__c, County__c, Projector__c, Projector_Screen__c, Capacity__c,Notes__c, Name_of_Contact__c, Contact__c, Phone__c, Email__c, Standard_Venue_Rental_Cost__c, Standard_Price_Per_Cover__c, Host_ID__c,Name FROM Hosts__c WHERE Id =:hostId LIMIT 1];
                List<Event> getRelatedEvent = [SELECT Id FROM Event WHERE Related_Event_ID__c =:getCampaign[0].Related_Event_ID__c LIMIT 1];
                //Changes DFJ-176
                List<Contact> getContactRecord = [SELECT Id,Campaign_Current_Start_Time__c FROM Contact WHERE Id =: getRelatedHost[0].Contact__c LIMIT 1];
                if(!getContactRecord.isEmpty()){
                    Contact contactRecord = new Contact();
                    contactRecord.Id = getContactRecord[0].Id;
                   // contactRecord.Cancel_Reschedule_LocationChange_Event__c = !String.isBlank(selectedReason.writeText) ? selectedReason.writeText : !String.isBlank(selectedReason.reasonFromPickList) ? selectedReason.reasonFromPickList : '';
                    //DFJ-237 changes
                    if(!String.isBlank(selectedReason.writeText)){
                        contactRecord.Cancel_Reschedule_LocationChange_Event__c = selectedReason.writeText;
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (getCampaign[0].Market_Unit__c.equals('DFJ_DK') ||getCampaign[0].Market_Unit__c.equals('Testamente_DK')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'for få tilmeldte';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (getCampaign[0].Market_Unit__c.equals('FA_SE') ||getCampaign[0].Market_Unit__c.equals('Testamente_SV')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'för få anmälda';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (getCampaign[0].Market_Unit__c.equals('FA_SE') ||getCampaign[0].Market_Unit__c.equals('Testamente_SV')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'sjukdom';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (getCampaign[0].Market_Unit__c.equals('DFJ_DK') ||getCampaign[0].Market_Unit__c.equals('Testamente_DK')) ){
                         contactRecord.Cancel_Reschedule_LocationChange_Event__c = 'sygdom';
                    }
                    //contactRecord.Campaign_Current_Start_Time__c =  getCampaign[0].Start__c != null ? getCampaign[0].Start__c : null;
                    contactToUpdate.add(contactRecord);
                }
              List<Lead>  getLeadList = [SELECT Id,Campaign_Current_Start_Time__c FROM Lead WHERE Related_Event_ID__c =: getCampaign[0].Related_Event_ID__c LIMIT 10000];
            
            if(!getLeadList.isEmpty()){
                for(Lead record:getLeadList){
                    Lead leadInstance = new Lead();
                    leadInstance.Id = record.Id;
                   // leadInstance.Cancel_Reschedule_LocationChange_Event__c = !String.isBlank(selectedReason.writeText) ? selectedReason.writeText : !String.isBlank(selectedReason.reasonFromPickList) ? selectedReason.reasonFromPickList : '';
                    //DFJ-237 Changes
                    if(!String.isBlank(selectedReason.writeText)){
                        leadInstance.Cancel_Reschedule_LocationChange_Event__c = selectedReason.writeText;
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (getCampaign[0].Market_Unit__c.equals('DFJ_DK') ||getCampaign[0].Market_Unit__c.equals('Testamente_DK')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'for få tilmeldte';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Too few bookings') && (getCampaign[0].Market_Unit__c.equals('FA_SE') ||getCampaign[0].Market_Unit__c.equals('Testamente_SV')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'för få anmälda';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (getCampaign[0].Market_Unit__c.equals('FA_SE') ||getCampaign[0].Market_Unit__c.equals('Testamente_SV')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'sjukdom';
                    }else if(!String.isBlank(selectedReason.reasonFromPickList) && selectedReason.reasonFromPickList.equals('Illness') && (getCampaign[0].Market_Unit__c.equals('DFJ_DK') ||getCampaign[0].Market_Unit__c.equals('Testamente_DK')) ){
                         leadInstance.Cancel_Reschedule_LocationChange_Event__c = 'sygdom';
                    }
                    leadInstance.Event_Venue__c = getRelatedHost[0].Name;
                    //leadInstance.Campaign_Current_Start_Time__c =  getCampaign[0].Start__c != null ? getCampaign[0].Start__c : null;
                    updateLeadsList.add(leadInstance);
                }
            }
            //End
               // String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
                String baseUrl = URL.getOrgDomainURL().toExternalForm();

        // Construct the complete record URL
                String recordUrl = baseUrl + '/' + getCampaign[0].Host__c;
                if(!getCampaign.isEmpty()){
                    Campaign updateCamp = new Campaign();
                    updateCamp.Id = getCampaign[0].Id;
                    //DFJ-237 +Name
                    System.debug('getRelatedHost[0].Name-->'+getRelatedHost[0].Name);
                    System.debug('getCampaign[0].Start__c-->'+getCampaign[0].Start__c);
                    updateCamp.Location_Changed__c = true;
                    updateCamp.Name = getRelatedHost[0].Name +' - ' + getCampaign[0].Start__c.format('dd-MM-yyyy') ;
                    
                    updateCamp.Date_of_Location_Change__c = System.now();
                    updateCamp.Venue__c = getRelatedHost[0].Name;
                    updateCamp.Host_ID__c = getRelatedHost[0].Host_ID__c;
                    updateCamp.Host__c = getRelatedHost[0].Id;
                    updateCamp.Original_Host__c = getCampaign[0].Host__c;
                    updateCamp.Original_Venue__c = getCampaign[0].Host__c;
                    updateCamp.Original_Host_ID__c = getCampaign[0].Host_ID__c;
                    updateCamp.Address__c = getRelatedHost[0].Address__c;
                    updateCamp.Zip_Code__c = getRelatedHost[0].Zip_Code__c;
                    updateCamp.City__c = getRelatedHost[0].City__c;
                    updateCamp.County__c = getRelatedHost[0].County__c;
                    updateCamp.Projector__c = getRelatedHost[0].Projector__c;
                    updateCamp.Projector_Screen__c = getRelatedHost[0].Projector_Screen__c;
                    updateCamp.Capacity__c = getRelatedHost[0].Capacity__c;
                    updateCamp.Notes__c = getRelatedHost[0].Notes__c;
                    updateCamp.Name_of_Contact__c = getRelatedHost[0].Name_of_Contact__c;
                    updateCamp.Contact__c = getRelatedHost[0].Contact__c;
                    updateCamp.Phone__c = getRelatedHost[0].Phone__c;
                    updateCamp.Email__c = getRelatedHost[0].Email__c;
                    updateCamp.Venue_Rental_Cost__c = getRelatedHost[0].Standard_Venue_Rental_Cost__c;
                    updateCamp.Price_Per_Cover__c = getRelatedHost[0].Standard_Price_Per_Cover__c;
                     //DFJ-176 Changes Added reason for cancellations fields 
                	updateCamp.Reason_for_Location_Change_Text__c = !String.isBlank(selectedReason.writeText) ? selectedReason.writeText : null;
                	updateCamp.Reason_for_Location_Change__c =  !String.isBlank(selectedReason.reasonFromPickList) ? selectedReason.reasonFromPickList : null;
                	updateCamp.Reason_for_Location_Change_Input__c = !String.isBlank(selectedReason.inputSelection) ? selectedReason.inputSelection : null;
                    campToUpdate.add(updateCamp);
                }
                if(!getRelatedEvent.isEmpty()){
                    Event updateEvent = new Event();
                    updateEvent.Id = getRelatedEvent[0].Id;
                    //DFJ-237 +Subject
                     updateEvent.Subject = getRelatedHost[0].Name +' - ' + getCampaign[0].Start__c.format('dd-MM-yyyy') ;
                    updateEvent.Location_Changed__c = true;
                    updateEvent.Date_of_Location_Change__c = System.now();
                    updateEvent.Venue__c = getRelatedHost[0].Name;
                    updateEvent.location = getRelatedHost[0].Name;
                  //  updateEvent.Host_ID__c = getRelatedHost[0].Host_ID__c;
                  //  updateEvent.Host__c = getRelatedHost[0].Id;
                    updateEvent.Original_Host__c = recordUrl;
                    updateEvent.Original_Venue__c = recordUrl;
                    updateEvent.Original_Host_ID__c = getCampaign[0].Host_ID__c;
                    eventToUpdate.add(updateEvent);
                }

            }
            //DFJ-176 Changes
            if(!contactToUpdate.isEmpty()){
                update contactToUpdate;
            }
            if(!updateLeadsList.isEmpty()){
                update updateLeadsList;
                result.leadList = updateLeadsList;
            }//End
            if(!campToUpdate.isEmpty()){
                update campToUpdate;
                result.campList = campToUpdate;
            }
            if(!eventToUpdate.isEmpty()){
                update eventToUpdate;
                result.eventList = eventToUpdate;
            }
            
        }catch(Exception ex){
            System.debug('ex.getMessage()-->'+ex.getMessage()+'--------'+String.valueOf(ex.getLineNumber()));
            DFJ_ErrorLogController.addErrorLogs('', 'Changing Host Location', ex.getMessage(), 'Error', 'DFJ_HandleEventCampaignStatus.hostLocationChange', '', String.valueOf(ex.getLineNumber()));
            return null;
        }
        return result;
        
    }

    public class ResponseWrapper {
        @AuraEnabled
        public List<Campaign> campList;
        @AuraEnabled
        public Boolean allowSendingEmail;
        //DFJ-159
        @AuraEnabled
        public List<Lead> leadList;
        //End
        @AuraEnabled
        public List<Event> eventList;
        @AuraEnabled
        public List<CampaignMember> campaignMemberList;
    }
    //DFJ-176 Changes
    public class selectedInputWrapper{
         @AuraEnabled
       public Boolean noReason{get;set;}
        @AuraEnabled
       public String reasonFromPickList{get;set;}
		 @AuraEnabled
       public String writeText{get;set;}  
        @AuraEnabled
       public String inputSelection{get;set;} 
        
    }
//End
}