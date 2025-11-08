@isTest
public class DFJ_UpdateOverdueLeads_Test {
    static testmethod void UpdateOverdueLeads_ApexTest(){
        DFJ_UpdateOverdueLeads sch = new DFJ_UpdateOverdueLeads();
        Lead leadInstance = new Lead();
        leadInstance.FirstName = 'Test';
        leadInstance.LastName = 'Lead';
        leadInstance.Company = 'CA';
        leadInstance.Status = 'Working';
        leadInstance.telegenta__Next_Call_Time__c  = DateTime.Now().addDays(-9);
        leadInstance.telegenta__Last_Contact_State__c   = 'Got appointment';
        leadInstance.Market_Unit__c = '	DFJ_DK';
        leadInstance.Provider_id__c = '	SDAD1111';
        insert leadInstance;

        Group queueInstance = new Group();
        queueInstance.Name = 'Sweden Leads';
        queueInstance.Type='Queue';
		insert queueInstance;

        String CRON_EXP = '0 0 23 1/1 * ? *' ;
        DFJ_UpdateOverdueLeads.scheduleUpdateOverdueLeads('set');

        sch.execute(null);
    }
    
    static testmethod void MethodName2(){
        Group queue2Instance = new Group();
        queue2Instance.Name = 'Sweden Leads';
        queue2Instance.Type='Regular';
		insert queue2Instance;
         DFJ_UpdateOverdueLeads sch = new DFJ_UpdateOverdueLeads();
		sch.execute(null);
    }

}