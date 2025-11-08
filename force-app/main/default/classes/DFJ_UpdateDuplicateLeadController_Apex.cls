public class DFJ_UpdateDuplicateLeadController_Apex {
	@AuraEnabled
	public static Integer DFJ_UpdateDuplicateLead(String DurationRange , Datetime StartDate , Date EndDate) {
		try{
			Integer count = 0;
			System.debug('DurationRange---' + DurationRange);

			String DurationQuery = '';
			if (DurationRange == 'Today' && DurationRange != null) {
				DurationQuery = ' CreatedDate = TODAY LIMIT 10000';
			}  else if (DurationRange == 'Last 7 Days' && DurationRange != null) {
				DurationQuery = ' CreatedDate >= N_DAYS_AGO:7 LIMIT 10000';
			} else if (DurationRange == 'Last 30 Days' && DurationRange != null) {
				DurationQuery = ' CreatedDate >= N_DAYS_AGO:30 LIMIT 10000';
			} else if (DurationRange == 'Last 3 Months' && DurationRange != null) {
				DurationQuery = ' CreatedDate >= N_DAYS_AGO:90 LIMIT 10000';
			}  else if (StartDate != null && EndDate != null) {
				// add 23 hours and 59 minutes and 59 seconds to the endDate. because it take the time 12.00 AM of that date.
				Datetime EndDate1 = Datetime.newInstance(EndDate, Time.newInstance(23, 59, 59, 999));

				DurationQuery = ' CreatedDate >=: StartDate AND CreatedDate <=: EndDate1  LIMIT 10000';
			}
			if(DurationQuery != null && DurationQuery != ''){

				Set<String> phoneSet = new Set<String>();
				Set<String> PublisherSet = new Set<String>();
				List<lead> leadList1 = new List<Lead>();
				List<lead> leadList2 = new List<Lead>();
				List<lead> LeadListToupdate = new List<Lead>();
				// Fetch the lead to update.
				String QueryString ='SELECT Id,Name,Phone,Phone2__c,Phone3__c,Duplicate_of__c,Publisher_name__c,CreatedDate FROM Lead WHERE'+DurationQuery;
				leadList1 = Database.query(QueryString);
				if(leadList1 != null){
					if(leadList1.size() > 0){
						for(Lead leadObj : leadList1){
							// Creating phoneSet and Publisher Name Set. used to fetch the duplicate leads from the org.
							if(leadObj.Phone != null){
								phoneSet.add(leadObj.Phone);
							}
							if(leadObj.Phone2__c != null){
								phoneSet.add(leadObj.Phone2__c);
							}
							if(leadObj.Phone3__c != null){
								phoneSet.add(leadObj.Phone3__c);
							}
							if(leadObj.Publisher_name__c != null){
								PublisherSet.add(leadObj.Publisher_name__c);
							}
						}
					}
				}
				if(phoneSet != null && PublisherSet != null){
					if(phoneSet.size() > 0 && PublisherSet.size() > 0){
						// fetching the all possible duplicate leads from the ORG.
						leadList2 = [SELECT Id,Name,Phone,Phone2__c,Phone3__c,Duplicate_of__c,Publisher_name__c,CreatedDate FROM
									Lead WHERE Publisher_name__c IN: PublisherSet
									AND (Phone IN: phoneSet OR Phone2__c IN: phoneSet OR Phone3__c IN: phoneSet) ORDER BY CreatedDate ASC LIMIT 10000];
					}
				}

				if(leadList1 != null && leadList2 != null){
					if(leadList1.size() >0 && leadList2.size()>0){

					}
				}
				for(lead leadObj1 : leadList1){ // loop on the list of lead to update.

					for(lead leadObj2 : leadList2) { //loop for to check the duplicate lead in org.
						Boolean isDuplicate = false; // variable used to update the lead.
						if(leadObj1.Id != leadObj2.Id && leadObj1.Duplicate_of__c == null) { // check the Id of the lead to update and lead to check duplicate is not same.
							List<String> phnList = new List<String>();
							if (leadObj1.Publisher_name__c != null && leadObj1.Publisher_name__c == leadObj2.Publisher_name__c){ // check the publisher name of the lead is empty or not if the publisher name is empty then no need to go further or check the phones.
								// Creating the phone list of the phones of the lead to check.
								phnList.add(leadObj2.Phone);
								phnList.add(leadObj2.Phone2__c);
								phnList.add(leadObj2.Phone3__c);
								// check the phone of lead to update are present or not in the lead to check if the phone is present then assign isDuplicate to true
								if(leadObj1.Phone != null && phnList.contains(leadObj1.Phone)){
									isDuplicate = true;
								}
								if(leadObj1.Phone2__c != null && phnList.contains(leadObj1.Phone2__c)){
									isDuplicate = true;
								}
								if(leadObj1.Phone3__c != null && phnList.contains(leadObj1.Phone3__c)){
									isDuplicate = true;
								}

								if(isDuplicate == true) {
									if(leadObj1.CreatedDate > leadObj2.CreatedDate) { // check the lead created date if created is greater then the lead to check then Duplicate_of__c of lead to update is not update
										// update the Duplicate_of__c field of the Lead with the id of the lead to check.
										leadObj1.Duplicate_of__c = leadObj2.Id;
										LeadListToupdate.add(leadObj1);
										count ++; // variable to return the no of lead updated.
										// Break the statement that the lead is updated with the oldest lead.
										break;
									}
								}
							}
						}
					}
				}
				System.debug('LeadListToupdate :: '+LeadListToupdate);
				if (LeadListToupdate.size() > 0) {
					update LeadListToupdate;
				}
			}
			return count;

		}catch (Exception ex) {
			throw new AuraHandledException('ERROR :: '+ex.getMessage() +' Line number :: '+ex.getLineNumber());
		}
	}
}