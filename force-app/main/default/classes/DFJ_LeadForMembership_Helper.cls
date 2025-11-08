/*
   * @ Version : 1.0
   * @ Created Date : 2021-12-14
   * @Description : Helper class to create membership record after lead creation.
*/
public with sharing class DFJ_LeadForMembership_Helper {
    /*
    * @Description  method to create the membership record on creation of Lead record.
    * @Return       Boolean
    */
    public static Boolean CreateMembership_Apex(List<Lead> leadList){
        try {
            
            List<Membership__c> memberListInstance = new List<Membership__c>();
            if (!leadList.isEmpty()) {            
                for (Lead leadLoop : leadList) {
                    if (leadLoop.Har_accepteret_medlemsbetingelser__c != null && (leadLoop.Har_accepteret_medlemsbetingelser__c.equals('true') || leadLoop.Har_accepteret_medlemsbetingelser__c.equals('JA') || leadLoop.Har_accepteret_medlemsbetingelser__c.contains('1'))) {
                        memberListInstance.add(new membership__c(Lead__c=leadLoop.Id,Name=(String.isBlank(leadLoop.FirstName) ? leadLoop.LastName : leadLoop.FirstName+' '+leadLoop.LastName),First_Name__c=leadLoop.FirstName,Last_Name__c=leadLoop.Lastname,Email__c=leadLoop.Email,Is_customer__c=false,Phone__c=leadLoop.Phone,Sign_up_Date__c=System.Today()));
                    }
                    
                }
            }
            if (!memberListInstance.isEmpty()) {
                insert memberListInstance;
                return true;
            }
            
        } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Inserting membership on lead creation.', ex.getMessage(), 'Error', 'DFJ_LeadForMembership_Helper.CreateMembership_Apex', String.valueOf(ex.getLineNumber()));
        }
        return false;
    }
}