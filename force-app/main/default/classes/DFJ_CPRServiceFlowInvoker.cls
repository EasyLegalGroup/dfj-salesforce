/**
 * @description Invocable wrapper so the CPR check can be called from Flows.
 * Accepts a list of requests and returns a list of responses to support bulk usage.
 */
public with sharing class DFJ_CPRServiceFlowInvoker {

    public class Request {
        @InvocableVariable(required=true)
        public String cprNumber;

        @InvocableVariable
        public String recordId;
    }

    public class Response {
        @InvocableVariable
        public String statusCode;

        @InvocableVariable
        public String name;

        @InvocableVariable
        public String gender;

        @InvocableVariable
        public String city;

        @InvocableVariable
        public String address;

        @InvocableVariable
        public String postalCode;

        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod
    public static List<Response> invoke(List<Request> requests) {
        List<Response> outputs = new List<Response>();
        if (requests == null) return outputs;

        for (Request r : requests) {
            DFJ_CPRService.CprResponseWrapper svcResp = DFJ_CPRService.getCPRData(r.recordId, r.cprNumber);

            Response out = new Response();
            out.statusCode = svcResp.statusCode;
            out.name = svcResp.name;
            out.gender = svcResp.gender;
            out.city = svcResp.city;
            out.address = svcResp.address;
            out.postalCode = svcResp.postalCode;
            out.errorMessage = svcResp.errorMessage;

            outputs.add(out);
        }

        return outputs;
    }
}