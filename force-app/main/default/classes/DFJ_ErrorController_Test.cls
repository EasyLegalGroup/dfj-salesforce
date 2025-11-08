@isTest
public class DFJ_ErrorController_Test {
	@isTest
    public static void addErrorLogs_Test(){
        telegenta__Phone_Group_User__c phoneusergp = new telegenta__Phone_Group_User__c(Name='123',telegenta__Debug_Log__c=true,telegenta__User__c=UserInfo.getUserId());
        insert phoneusergp;
        Test.startTest();
        DFJ_ErrorController.addErrorLogs('TestRecord','TestEvent','TestMessage','Error','TestSource','12');
        Test.stopTest();
        System.assertEquals([SELECT count() FROM Log__c], 1);
    }
}