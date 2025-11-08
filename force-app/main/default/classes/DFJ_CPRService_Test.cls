/**
 * @description This is test class for DFJ_CPRService
 */
@isTest
public class DFJ_CPRService_Test {
    @isTest
    static void testCallPNRApiService() {
        // Mocking HTTP callout for DFJ_CPRResponseService
        Test.startTest();
        DFJ_CPRResponseServiceMock_Test mock = new DFJ_CPRResponseServiceMock_Test();
        test.setMock(HttpCalloutMock.class, mock);
        DFJ_CPRService.CprResponseWrapper responsetest = new DFJ_CPRService.CprResponseWrapper();
        responsetest.token = 'testToken';
        String cprNumber = '2307922749';
        DFJ_CPRService.CprResponseWrapper response = DFJ_CPRResponseService.callPNRApiService(responsetest, cprNumber);
        // Asserting expected response
        System.assertNotEquals(null, response, 'Response should not be null.');
        System.assertEquals('200', response.statusCode, 'Response code should be 200.');
        
        System.assertEquals('Schwaan Theoder', response.name, 'Name should be Schwaan Theoder.');
        System.assertEquals('V', response.gender, 'Gender should be V.');
        System.assertEquals('Kilimnjaro', response.city, 'City should be Kilimnjaro.');
        
        System.assertEquals('Hagrid Mxavier 94, st. bt', response.address, 'Address should be Hagrid Mxavier 94, st. bt.');
        Test.stopTest();
    }
    
    @isTest
    static void testGetCPRData() {
        // Mocking both token and PNR API calls
        Test.startTest();
        DFJ_CPRTokenServiceMock_Test tokenMock = new DFJ_CPRTokenServiceMock_Test();
        test.setMock(HttpCalloutMock.class, tokenMock);
        String recId = '123';
        String cprNumber = '2307922749';
        DFJ_CPRService.CprResponseWrapper response = DFJ_CPRService.getCPRData(recId,cprNumber);
        // Assert the response from service
        System.assertNotEquals(null, response, 'Response should not be null.');
        Test.stopTest();
    }
    
}