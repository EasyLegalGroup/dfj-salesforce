/*
   * @ Version : 1.0
   * @ Created Date : 2022-02-01
   * @Description : PS - Payment System apex class which handle the salesdocuments.
*/
public with sharing class PS_SalesDocumentHelper {
    /*
    * @Description  method to create the new sales document record and delete draft salesdocumen.
    * @Param        leadId
    * @Return       CampaignWrapper
    */
   @AuraEnabled
    public static String CreateSalesDocumentAndDeleteDraft_Apex(String recordId){
       /*  try {
            if (String.isBlank(recordId)) {
                return 'Error, Got recordId empty.';
            }
            // Lead related query
            String whereClause = 'Id=\''+recordId+'\'';
            String query = PS_Utility.QueryToFetchLeads(whereClause, 'LIMIT 1');
            List<Lead> leadList = new List<Lead>();
            leadList = Database.query(query);

            if (leadList.isEmpty()) {
                return 'Error, Lead not found.';
            }

            // sales document related query
            whereClause = 'bt_stripe__Status__c=\'Draft\' AND bt_stripe__Bill_To_Lead__c=\''+recordId+'\'';
            query = PS_Utility.QueryToFetchSalesDocument(whereClause, 'LIMIT 10000');
            List<bt_stripe__Sales_Document__c> salesDocumentList = new List<bt_stripe__Sales_Document__c>();

            salesDocumentList = Database.query(query);

            Set<Id> salesDocumentIds = new Set<Id>();
            
            for (bt_stripe__Sales_Document__c salesDocumentLoop : salesDocumentList) {
                salesDocumentIds.add(salesDocumentLoop.Id);
            }
            if (!salesDocumentIds.isEmpty()) {
                List<bt_stripe__Line_Item__c> lineItemToDelete = new List<bt_stripe__Line_Item__c>();
                lineItemToDelete = [SELECT Id,bt_stripe__Sales_Document__c FROM bt_stripe__Line_Item__c Where bt_stripe__Sales_Document__c IN: salesDocumentIds LIMIT 10000];

                if (!lineItemToDelete.isEmpty()) {
                    delete lineItemToDelete;
                }
                delete salesDocumentList;
            }
            

            // Get companyinfo, documentLinkTemplate and location metadata records
            // Start
            PS_RecordConfigurator__mdt companyInfoMetadatarecord = (leadList[0].Market_Unit__c == 'DFJ_DK' || leadList[0].Market_Unit__c == 'Testamente_DK') ? PS_RecordConfigurator__mdt.getInstance('CompanyInfo_DFJ_DK_Testamente_DK') : PS_RecordConfigurator__mdt.getInstance('CompanyInfo_FA_SE_Testamente_SV');
            PS_RecordConfigurator__mdt locationMetadatarecord = (leadList[0].Market_Unit__c == 'DFJ_DK' || leadList[0].Market_Unit__c == 'Testamente_DK') ? PS_RecordConfigurator__mdt.getInstance('Location_DFJ_DK_Testamente_DK') : PS_RecordConfigurator__mdt.getInstance('Location_FA_SE_Testamente_SV');
            PS_RecordConfigurator__mdt documentLinkTemplateMetadatarecord = (leadList[0].Market_Unit__c == 'DFJ_DK' || leadList[0].Market_Unit__c == 'Testamente_DK') ? PS_RecordConfigurator__mdt.getInstance('DcumentLinkTemplate_DFJ_DK_Testamente_DK') : PS_RecordConfigurator__mdt.getInstance('DcumentLinkTemplate_FA_SE_Testamente_SV');
            
            if (companyInfoMetadatarecord == null || locationMetadatarecord == null || documentLinkTemplateMetadatarecord == null) {
                return 'Error, Configuration record not found.';
            }
            // End

            // Create sales document
            bt_stripe__Sales_Document__c salesDocumentInstance = new bt_stripe__Sales_Document__c();
            // Populate fields on the base of market unit like - country/CompanyInfo
            // Start
            if (!Test.isRunningTest()) {
            salesDocumentInstance.bt_stripe__Bill_To_Lead__c = leadList[0].Id;
            salesDocumentInstance.bt_stripe__Currency_ISO__c = leadList[0].Market_Unit__c == 'DFJ_DK' || leadList[0].Market_Unit__c == 'Testamente_DK' ? 'DKK' :'SEK';
            salesDocumentInstance.bt_stripe__Company__c = companyInfoMetadatarecord.Configured_Record_Id__c;
            salesDocumentInstance.bt_stripe__Location__c = locationMetadatarecord.Configured_Record_Id__c;
            
                salesDocumentInstance.bt_stripe__DocumentLink_Template__c = documentLinkTemplateMetadatarecord.Configured_Record_Id__c;
            }
            // End
            insert salesDocumentInstance;

            // lead produt related query
            whereClause = 'Lead__c=\''+recordId+'\'';
            query = PS_Utility.QueryToFetchLeadProducts(whereClause, 'LIMIT 10000');

            List<LeadProducts__c> leadProductList = new List<LeadProducts__c>();
            leadProductList = Database.query(query);

            List<bt_stripe__Line_Item__c> lineItemList = new List<bt_stripe__Line_Item__c>();
            if (!leadProductList.isEmpty()) {
                for (LeadProducts__c leadProductLoop : leadProductList) {
                    bt_stripe__Line_Item__c lineItemInstance = new bt_stripe__Line_Item__c();
                    lineItemInstance.bt_stripe__Additional_Discount_Percentage__c = leadProductLoop.Discount__c;
                    lineItemInstance.bt_stripe__Quantity__c = leadProductLoop.Quantity__c;
                    lineItemInstance.bt_stripe__Item_Name__c = leadProductLoop.Product_Name__c;
                    lineItemInstance.bt_stripe__Unit_Price__c = leadProductLoop.Item_Price__c;
                    lineItemInstance.bt_stripe__Total_Amount__c = leadProductLoop.Sub_Total__c;
                    lineItemInstance.bt_stripe__Sales_Document__c = salesDocumentInstance.Id;
                    lineItemList.add(lineItemInstance);
                }
            }
            if (!lineItemList.isEmpty()) {
                insert lineItemList;
            }

            return salesDocumentInstance.Id;*/
     /*   } catch (Exception ex) {
            DFJ_ErrorController.addErrorLogs('', 'Getting Membership related data.', ex.getMessage(), 'Error', 'DFJ_MembershipWebhook.GetMembershipRelatedData apex class.', String.valueOf(ex.getLineNumber()));
        }*/
        return 'Error, Something went wrong.';
    }
}