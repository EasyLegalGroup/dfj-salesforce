@isTest
public class DFJ_HandleEventCampaignStatusTest {
    @TestSetup
    static void createTestData() {
        
        Contact conRecord = new Contact();
        conRecord.LastName = 'TestContact';
        insert conRecord;
           
        Hosts__c hostInst = new Hosts__c();
        hostInst.Name = 'Test Host';
        hostInst.Country__c = 'testCountry';
        hostInst.Contact__c = conRecord.Id;
        hostInst.Default_Invoicing_Agreement__c = 'Per Booked Seat';
        hostInst.Market_Unit__c = 'Testamente_DK';
        insert hostInst;
        
        Campaign campInst = new Campaign();
        campInst.Status = 'In Progress';
        campInst.Name = 'Test Camp';
        campInst.Start__c = System.now();
        campInst.Related_Event_ID__c = '1234caTest';
        campInst.Market_Unit__c = 'Testamente_DK';
        campInst.Host__c = hostInst.Id;
        insert campInst;
        
        Lead leadInst = new Lead();
        leadInst.provider_Id__c = 'testId';
        leadInst.LastName = 'TestLeadName';
		leadInst.Related_Event_ID__c =  '1234caTest';    
        insert leadInst;
        
        Event eventInst = new Event();
        eventInst.ActivityDateTime = DateTime.now();
        eventInst.DurationInMinutes = 12;
        eventInst.Related_Event_ID__c = '1234caTest';
        insert eventInst;
        
 		/*CampaignMember campMemberInst= new CampaignMember();
        campMemberInst.campaignId = campInst.Id;
        campMemberInst.leadId = leadInst.Id;
        insert campMemberInst;
        system.debug('campMemberInst-->'+campMemberInst);*/
    }
    
    @isTest
    private static void handleCancelEvent_Test(){
        DFJ_HandleEventCampaignStatus.selectedInputWrapper testWrapper = new DFJ_HandleEventCampaignStatus.selectedInputWrapper();
        testWrapper.noReason=false;
        List<Campaign> campList = [SELECT Id FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];
        Test.startTest();
        DFJ_HandleEventCampaignStatus.handleCancelEvent(campList[0].Id,testWrapper);
        Test.stopTest();
        List<Campaign> campList2 = [SELECT Id,Status FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];
		System.assertEquals('Cancelled', campList2[0].Status);
    }
    //DFJ-159 Changes
    @isTest
    private static void handleCancelEvent_Test2(){
        DFJ_HandleEventCampaignStatus.selectedInputWrapper testWrapper = new DFJ_HandleEventCampaignStatus.selectedInputWrapper();
        testWrapper.reasonFromPickList='Too few bookings';
        List<Campaign> campList = [SELECT Id FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];
        Test.startTest();
        DFJ_HandleEventCampaignStatus.handleCancelEvent(campList[0].Id,testWrapper);
        Test.stopTest();
        List<Campaign> campList2 = [SELECT Id,Status FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];
		System.assertEquals('Cancelled', campList2[0].Status);
    }
    @isTest
    private static void handleCancelEvent_Test3(){
        DFJ_HandleEventCampaignStatus.selectedInputWrapper testWrapper = new DFJ_HandleEventCampaignStatus.selectedInputWrapper();
        testWrapper.reasonFromPickList='Illness';
        List<Campaign> campList = [SELECT Id FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];
        Test.startTest();
        DFJ_HandleEventCampaignStatus.handleCancelEvent(campList[0].Id,testWrapper);
        Test.stopTest();
        List<Campaign> campList2 = [SELECT Id,Status FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];
		System.assertEquals('Cancelled', campList2[0].Status);
    }
   //End 
    @isTest
    private static void handleRescheduleEvent_Test(){
         DFJ_HandleEventCampaignStatus.selectedInputWrapper testWrapper = new DFJ_HandleEventCampaignStatus.selectedInputWrapper();
        testWrapper.reasonFromPickList='Too few bookings';
        List<Campaign> campList = [SELECT Id FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];
        String dateTimeString = '2023-10-10 00:45:00.000';
        Test.startTest();
        DFJ_HandleEventCampaignStatus.handleRescheduleEvent(campList[0].Id,dateTimeString,testWrapper);
        Test.stopTest();
        List<Event> eventList2 = [SELECT Id,Event_Status__c FROM Event WHERE Related_Event_ID__c = '1234caTest'];
		System.assertEquals('Rescheduled', eventList2[0].Event_Status__c);
    }
     @isTest
    private static void handleRescheduleEvent_Test2(){
         DFJ_HandleEventCampaignStatus.selectedInputWrapper testWrapper = new DFJ_HandleEventCampaignStatus.selectedInputWrapper();
        testWrapper.reasonFromPickList='Illness';
        List<Campaign> campList = [SELECT Id FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];
        String dateTimeString = '2023-10-10 00:45:00.000';
        Test.startTest();
        DFJ_HandleEventCampaignStatus.handleRescheduleEvent(campList[0].Id,dateTimeString,testWrapper);
        Test.stopTest();
        List<Event> eventList2 = [SELECT Id,Event_Status__c FROM Event WHERE Related_Event_ID__c = '1234caTest'];
		System.assertEquals('Rescheduled', eventList2[0].Event_Status__c);
    }
    
    @isTest
    private static void getAllHosts_Test(){
        Test.startTest();
        DFJ_HandleEventCampaignStatus.getAllHosts();
        Test.stopTest();
        List<Hosts__c> getAllHostList= [SELECT Id,Name FROM Hosts__c];
        System.assertEquals(1, getAllHostList.size());

    }
    
    @isTest
    private static void hostLocationChange_Test(){
        DFJ_HandleEventCampaignStatus.selectedInputWrapper testWrapper = new DFJ_HandleEventCampaignStatus.selectedInputWrapper();
        testWrapper.reasonFromPickList='Too few bookings';
        List<Hosts__c> hostList = [SELECT Id,Name FROM Hosts__c WHERE Name='Test Host'];
        List<Campaign> campList = [SELECT Id,Start__c FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];

        Test.startTest();
        DFJ_HandleEventCampaignStatus.hostLocationChange(campList[0].Id, hostList[0].Id,testWrapper);
        Test.stopTest();
        List<Hosts__c> getAllHostList= [SELECT Id FROM Hosts__c WHERE Name ='Test Host' ];
        List<Campaign> campList2 = [SELECT Id,Host__c FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];
        System.assertEquals(campList2[0].Host__c, getAllHostList[0].Id);
    }
     @isTest
    private static void hostLocationChange_Test2(){
        DFJ_HandleEventCampaignStatus.selectedInputWrapper testWrapper = new DFJ_HandleEventCampaignStatus.selectedInputWrapper();
        testWrapper.reasonFromPickList='Illness';
        List<Hosts__c> hostList = [SELECT Id,Name FROM Hosts__c WHERE Name='Test Host'];
        List<Campaign> campList = [SELECT Id,Start__c FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];

        Test.startTest();
        DFJ_HandleEventCampaignStatus.hostLocationChange(campList[0].Id, hostList[0].Id,testWrapper);
        Test.stopTest();
        List<Hosts__c> getAllHostList= [SELECT Id FROM Hosts__c WHERE Name ='Test Host' ];
        List<Campaign> campList2 = [SELECT Id,Host__c FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];
        System.assertEquals(campList2[0].Host__c, getAllHostList[0].Id);
    }
    @isTest
    private static void getCurrentHostsEmail_Test(){
        List<Campaign> campList = [SELECT Id,Start__c FROM Campaign WHERE Related_Event_ID__c = '1234caTest'];

        Test.startTest();
        DFJ_HandleEventCampaignStatus.getCurrentHostsEmail(campList[0].Id);
        Test.stopTest();
        
    }
    
  
}