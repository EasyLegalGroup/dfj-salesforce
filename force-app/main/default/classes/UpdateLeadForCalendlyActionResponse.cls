global class UpdateLeadForCalendlyActionResponse {
    
	@InvocableMethod(label='UpdateLeadForCalendlyActionResponseAction')
    global static void updateLeadRec(List<UpdateLeadActionRequest> requestList){
        try{
        Map<String,String> customQuesVsCustomResponseMap = new Map<String,String>();
        
        System.debug('UpdateLeadActionRequest-->'+requestList[0].leadRecord);
        System.debug('UpdateLeadActionRequest-->'+requestList[0].calendlyRecord);
        // UpdateLeadForCalendlyActionResponse.UpdateLeadActionRequest apexActionInstance= new UpdateLeadForCalendlyActionResponse.UpdateLeadActionRequest();
        // apexActionInstance
		
        Calendly__CalendlyAction__c calendlyActionRecord = requestList[0].calendlyRecord;
        String leadRecordId = requestList[0].leadRecord;

        Lead leadToUpdate = new Lead(Id = leadRecordId);
        system.debug('leadToUpdate-->'+leadToUpdate);
		List<Calendly_Lead_Field_Configuration__mdt> calendlyFormConfigurationRecord = new List<Calendly_Lead_Field_Configuration__mdt>(); 
            calendlyFormConfigurationRecord = [SELECT Id, DeveloperName, Multiselect_Lead_Mapping__c, Slug__c, Question_Response_Mapping__c FROM Calendly_Lead_Field_Configuration__mdt WHERE Slug__c =: calendlyActionRecord.Calendly__EventTypeSlug__c];

        if (!String.isBlank(leadRecordId) && !calendlyFormConfigurationRecord.isEmpty()) {
           // List<Calendly_Lead_Field_Configuration__mdt> calendlyFormConfigurationRecord = new List<Calendly_Lead_Field_Configuration__mdt>(); 
          //  calendlyFormConfigurationRecord = [SELECT Id, DeveloperName, Multiselect_Lead_Mapping__c, Slug__c, Question_Response_Mapping__c FROM Calendly_Lead_Field_Configuration__mdt WHERE Slug__c =: calendlyActionRecord.Calendly__EventTypeSlug__c];
system.debug('>>>calendlyFormConfigurationRecord>'+calendlyFormConfigurationRecord);
            Map<String, Object> questionFieldVsMetaInfo = (Map<String, Object>) JSON.deserializeUntyped(calendlyFormConfigurationRecord[0].Question_Response_Mapping__c);
            Map<String, Object> multiSelectOptionVsLeadField = (Map<String, Object>) JSON.deserializeUntyped(calendlyFormConfigurationRecord[0].Multiselect_Lead_Mapping__c);

            Set<String> questionFileds = new Set<String>();
            questionFileds = questionFieldVsMetaInfo.keySet();

            for (String questionFieldName : questionFileds) {
    				 System.debug('questionFieldName '+questionFieldName );
       				 Map<String, Object> questionData = (Map<String, Object>) questionFieldVsMetaInfo.get(questionFieldName);
 					 System.debug('questionData '+questionData );
      			 	 String type = (String) questionData.get('type');
               if(type!='MULTISELECT'){
                     String leadField = (String) questionData.get('leadTargetField');
                     System.debug('leadField '+leadField );
                     System.debug('Question Field: ' + questionData.get('responseField'));
                         			 String response = (String) questionData.get('responseField');
                    System.debug('Kommentarer_Calendly__c: ' + calendlyActionRecord.Calendly__CustomResponse3__c);

                	leadToUpdate.put(leadField,calendlyActionRecord.get(response) ) ;
                    system.debug('.leadToUpdate..'+leadToUpdate);
               }else if(type.equalsIgnoreCase('MULTISELECT')){
                  String response2 = (String) questionData.get('responseField');
                   String response = (String)calendlyActionRecord.get(response2);
                   
                    leadToUpdate.put('Undg_at_staten_bliver_min_v_rge__c',response.contains('Jeg vil undgå at staten bliver min værge, i tilfælde af alvorlig sygdom') ? true : false) ;
                    leadToUpdate.put('Undg_at_b_rns_risiko_for_50_mindre_arv__c',response.contains('Særeje til børn, så de ikke mister halvdelen af arven') ? true : false) ;
                    leadToUpdate.put('Undg_en_sk_vfordeling_af_arven__c',response.contains('Undgå skævfordeling af arven') ? true : false) ;
                    leadToUpdate.put('Selv_bestemme_hvem_der_skal_arve_mig__c',response.contains('Selv styre arvefordeling, penge, genstande og værdier') ? true : false) ;
                    leadToUpdate.put('Undg_at_b_rn_f_r_arv_udbetalt_for_tidli__c',response.contains('Børn skal ikke "misbruge" arven som 18 årig (Båndlæggelse af arv)') ? true : false) ;
                    leadToUpdate.put('Sikre_min_partner_gtef_lle_mest_muligt__c',response.contains('Sikre min partner/ægtefælle mest muligt, ved min bortgang') ? true : false) ;
                    leadToUpdate.put('Undg_at_partner_skal_betale_ved_min_d_d__c',response.contains('Undgå at min partner/ægtefælle skal betale en stor sum penge, ved min død') ? true : false) ;
                    leadToUpdate.put('Undg_arveafgift_til_arvinger__c',response.contains('Jeg vil gerne undgå arveafgift til mine arvinger, mest muligt') ? true : false) ;

				}
 
               }
               update leadToUpdate;
            }
            
            system.debug('leadToUpdate00>'+leadToUpdate);
        
    
        }catch(exception e){
            system.debug('>>Line number>>'+e.getLineNumber() + 'message>>'+e.getMessage());
        }
    }
    
    global class UpdateLeadActionRequest {
    @InvocableVariable(required=true)
    global Calendly__CalendlyAction__c calendlyRecord;

    @InvocableVariable(required=true)
    global String leadRecord;
    }

    public class calendlyQuestionResponseWrapper {
        public String type;
        public String responseField;
        public String leadTargetField;
    }

}