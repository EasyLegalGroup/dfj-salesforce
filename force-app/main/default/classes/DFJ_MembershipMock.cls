/*
   * @Version : 1.0
   * @Created Date : 2021-09-29
   * @Description : This Mock class will be used for mocking membership response.
*/
@isTest
global class DFJ_MembershipMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        String responseBody = '';
        if(req.getMethod().equals('POST')){
            if(req.getEndpoint().equals('https://dfj.dev-evocode.net/wp-json/dfj/user/invite')){

                if(req.getBody().contains('Test1')){
                    res.setBody(responseBody);
                    res.setStatusCode(100);
                }else{
                    responseBody = '{'+
                    '"Status": "Success",'+
                    '"ProfileLink": "https://dinfamiljejurist.nu/admin/users/idxyz",'+
                    '"ProfilId": 123123'+
                    '}';
                    res.setBody(responseBody);
                    res.setStatusCode(200);
                }

            }
        }
        return res;
    }
}