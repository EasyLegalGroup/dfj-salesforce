@isTest 
global with sharing class PS_MockUtility_Test implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Accept', 'application/json');
        response.setHeader('Content-Type', 'application/json');

        if (req.getEndpoint().equals('https://api.reepay.com/v1/customer/test@gmail.com')) {            
            String body = '{"email": "carl@leone.com","address": "Grove Street 12","address2": "Ganton","city": "Los Santos","country": "US","phone": "555-gotcars","company": "Leones Cars","handle": "test@gmail.com", "created": "2015-04-04T12:40:56.656+00:00","deleted": "2015-04-04T12:40:56.656+00:00","first_name": "Carl","last_name": "Johnson","postal_code": "4531"}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        } else if (req.getEndpoint().equals('https://api.reepay.com/v1/customer/test1@gmail.com')) {            
            String body = '{"error": "Customer not found", "http_status": "404"}';
            response.setBody(body);
            response.setStatusCode(404);
            return response;
        } else if (req.getEndpoint().equals('https://api.reepay.com/v1/customer/test2@gmail.com')) {            
            String body = '{"http_status": "500"}';
            response.setBody(body);
            response.setStatusCode(500);
            return response;
        }else if (req.getEndpoint().equals('https://api.reepay.com/v1/plan/FitnessPlan01/current')) {            
            String body = '{"name":"120/year","description":"120/year","vat":0.25,"amount":12000,"quantity":1,"prepaid":true,"handle":"FitnessPlan01","version":1,"state":"active","currency":"DKK","fixed_trial_days":true,"amount_incl_vat":true,"trial_interval_unit":"months","trial_interval_length":12,"interval_length":12,"schedule_type":"month_fixedday","schedule_fixed_day":1}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        } else if(req.getEndpoint().equals('https://api.reepay.com/v1/customer') && req.getMethod().equals('POST')) {
            String body = '{"email": "carl@leone.com","address": "Grove Street 12","address2": "Ganton","city": "Los Santos","country": "US","phone": "555-gotcars","company": "Leones Cars","handle": "test@gmail.com", "created": "2015-04-04T12:40:56.656+00:00","deleted": "2015-04-04T12:40:56.656+00:00","first_name": "Carl","last_name": "Johnson","postal_code": "4531"}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        } else if(req.getEndpoint().equals('https://api.reepay.com/v1/customer') && req.getMethod().equals('POST')) {
            String body = '{"email": "carl@leone.com","address": "Grove Street 12","address2": "Ganton","city": "Los Santos","country": "US","phone": "555-gotcars","company": "Leones Cars","handle": "test1@test.com", "created": "2015-04-04T12:40:56.656+00:00","deleted": "2015-04-04T12:40:56.656+00:00","first_name": "Test","last_name": "Lead","postal_code": "1401"}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        } else if(req.getEndpoint().equals('https://api.reepay.com/v1/customer') && req.getMethod().equals('POST')) {
            String body = '{"message": "customer already exists", "http_status": "400"}';
            response.setBody(body);
            response.setStatusCode(400);
            return response;
        } else if(req.getEndpoint().equals('https://api.reepay.com/v1/customer') && req.getMethod().equals('POST')) {
            String body = '{"error": "the server encountered an unexpected condition that prevented it from fulfilling the request"}';
            response.setBody(body);
            response.setStatusCode(500);
            return response;
        } else if (req.getEndpoint().equals('https://api.reepay.com/v1/invoice/Inv-0001') && req.getMethod().equals('GET')) {
            String body = '{"id":"dafba2016614418f969fa5697383e47c","handle":"Inv-0001","customer":"test@test.com","state":"settled","processing":"true","type":"settled","amount":10,"currency":"DKK","due":"2015-04-04T12:40:56.656+00:00","settled":"2015-04-04T12:40:56.656+00:00","authorized":"2015-04-04T12:40:56.656+00:00","created":"2015-04-04T12:40:56.656+00:00","org_amount":10,"settled_amount":10,"recurring_payment_method":"ms_1a25cd3399d2812656aa5b0876c9356b","authorized_amount":10,"order_lines":[{"id":"c33fbb06a00e4dc0b9055f6fb509c0ed","ordertext":"Product X","amount":10,"vat":0.25,"quantity":1}],"transactions":[{"id":"dafba2016614418f969fa5697383e47c","state":"settled","invoice":"Inv-0001","type":"settle","amount":10000,"settled":"2015-04-04T12:40:56.656+00:00","failed":"2015-04-04T12:40:56.656+00:00","refunded":"2015-04-04T12:40:56.656+00:00","created":"2015-04-04T12:40:56.656+00:00","payment_type":"card","card_transaction":{"card":{"id":"ca_fcfac2016614418f969fa5697383e47c","state":"active","customer":"customer00069","reference":"cs_6be90a4babc3c57ef7e6e477ac97ed3b","failed":"2015-06-04T12:40:56.656+00:00","created":"2015-04-04T12:40:56.656+00:00","fingerprint":"cst_64e8a26cc0e85bc3f5ce7c5b366b4096","reactivated":"2015-05-14T00:00:00.000+00:00","gw_ref":"657e86162633415a9e6b715248c84da4","card_type":"visa_dk","transaction_card_type":"visa","exp_date":"09-18","masked_card":"457111XXXXXX3777","last_success":"2015-05-14T00:00:00.000+00:00","last_failed":"2015-05-14T00:00:00.000+00:00","error_state":"hard_declined","strong_authentication_status":"secured_by_nets","three_d_secure_status":"Y","card_country":"US"},"fingerprint":"cst_64e8a26cc0e85bc3f5ce7c5b366b4096","provider":"clearhaus","ref_transaction":"a7a7195c54f644369922d0dfe794dd0c","gw_id":"28fc559a229e4fd3a134297a478a0075","last_failed":"2015-04-04T12:40:56.656+00:00","first_failed":"2015-04-04T12:40:56.656+00:00","error_state":"hard_declined","card_type":"visa_dk","transaction_card_type":"visa","exp_date":"09-18","masked_card":"457111XXXXXX3777","card_country":"US","strong_authentication_status":"secured_by_nets","three_d_secure_status":"Y","acquirer_code":"40135","acquirer_message":"Card expired"}}]}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        }else if (req.getEndpoint().equals('https://api.reepay.com/v1/invoice/a34Aa000004qxmTIAQ') && req.getMethod().equals('GET')) {
            String body = '{"type":"co","transactions":[{"type":"refund","state":"refunded","settled":null,"refunded":"2023-05-26T12:13:39.039+00:00","payment_type":"mobilepay_subscriptions","payment_context":"mit","mps_transaction":{"ref_transaction":"937e89ebc3958797de104e2fe565833f","mps_subscription":{"state":"active","reference":"cs_dd99ea1ec39fe71ac893bcefeae292e8","id":"ms_8bc82f311169cd78f5ed2262136874b1","failed":null,"external_id":null,"customer":"kushagra.mishra@cloudanalogy.com","created":"2023-05-26T09:59:06.842Z"},"mps_payment_type":"one_off_cit","mps_id":"9c6993fbeb47d5a9022c5d278abbe114","error_state":null,"error":null,"acquirer_message":null},"mpo_transaction":null,"manual_transaction":null,"klarna_transaction":null,"invoice":"a34Aa000004qxmTIAQ","id":"af53bb637507b839f6d77aa7a07e8d6f","failed":null,"created":"2023-05-26T12:13:33.960Z","card_transaction":null,"authorized":null,"amount":828500.0}],"subscription":null,"state":"settled","settled_amount":828500.0,"refunded_amount":828500.0,"recurring_payment_method":"ms_8bc82f311169cd78f5ed2262136874b1","plan":null,"org_amount":828500.0,"order_lines":[{"attributes":{"type":"Payment_order_line__c","url":"/services/data/v57.0/sobjects/Payment_order_line__c/f9a04b147b40d6cc06b2220810bc8983"},"Id":"f9a04b147b40d6cc06b2220810bc8983"},{"attributes":{"type":"Payment_order_line__c","url":"/services/data/v57.0/sobjects/Payment_order_line__c/a01f17468dd8ffcba586414879e6c1b1"},"Id":"a01f17468dd8ffcba586414879e6c1b1"},{"attributes":{"type":"Payment_order_line__c","url":"/services/data/v57.0/sobjects/Payment_order_line__c/8bcf30d8c7f7c9e7427e6f98c27ff158"},"Id":"8bcf30d8c7f7c9e7427e6f98c27ff158"},{"attributes":{"type":"Payment_order_line__c","url":"/services/data/v57.0/sobjects/Payment_order_line__c/f525b6485a4837da08b228d797f8c2a3"},"Id":"f525b6485a4837da08b228d797f8c2a3"}],"id":"0aa45fd9781ec54f483a7cf4d06cb85c","handle":"a34Aa000004qxmTIAQ","errorMessage":null,"due":"2023-05-26T09:58:55.254Z","discount_amount":0.0,"customer":"kushagra.mishra@cloudanalogy.com","created":"2023-05-26T09:58:55.254Z","amount_vat":165700.0,"amount_ex_vat":662800.0,"amount":828500.0}}';
            response.setBody(body);
            response.setStatusCode(200);
        
        return response;
        
    } else if(req.getEndpoint().equals('https://api.reepay.com/v1/customer/test@gmail.com/invoice') && req.getMethod().equals('POST')) {
            String body = '{"email": "carl@leone.com","address": "Grove Street 12","address2": "Ganton","city": "Los Santos","country": "US","phone": "555-gotcars","company": "Leones Cars","handle": "test@gmail.com", "created": "2015-04-04T12:40:56.656+00:00","deleted": "2015-04-04T12:40:56.656+00:00","first_name": "Carl","last_name": "Johnson","postal_code": "4531"}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        } else if(req.getEndpoint().equals('https://api.reepay.com/v1/customer/test1@gmail.com/invoice') && req.getMethod().equals('POST')) {
            String body = '{"error": "Customer not found", "http_status": "404"}';
            response.setBody(body);
            response.setStatusCode(404);
            return response;
        } else if(req.getEndpoint().equals('https://api.reepay.com/v1/customer/test2@gmail.com/invoice') && req.getMethod().equals('POST')) {
            String body = '{"error": "", "http_status": "500"}';
            response.setBody(body);
            response.setStatusCode(500);
            return response;
        } else if(req.getEndpoint().equals('https://api.reepay.com/v1/subscription') && req.getMethod().equals('POST')) {
            String body = '{"handle":"sub-0002","customer":"kushagra.mishra@cloudanalogy.com","plan":"FitnessPlan01", "state":"active","test":true,"amount":20000,"quantity":3,"timezone":"Europe/Copenhagen","created":"2022-07-11T14:01:47.481+00:00","activated":"2022-07-11T14:01:47.481+00:00","renewing":false,"plan_version":1,"amount_incl_vat":true,"start_date":"2022-06-28T22:00:00.000+00:00","end_date":"2022-11-30T23:00:00.000+00:00","grace_duration":172800,"current_period_start":"2022-06-28T22:00:00.000+00:00","next_period_start":"2023-06-28T22:00:00.000+00:00","first_period_start":"2022-06-28T22:00:00.000+00:00","is_cancelled":false,"in_trial":false,"has_started":true,"renewal_count":0,"payment_method_added":false,"failed_invoices":0,"failed_amount":0,"cancelled_invoices":0,"cancelled_amount":0,"pending_invoices":1,"pending_amount":60000,"dunning_invoices":0,"dunning_amount":0,"settled_invoices":0,"settled_amount":0,"refunded_amount":0,"pending_additional_costs":0,"pending_additional_cost_amount":0,"transferred_additional_costs":0,"transferred_additional_cost_amount":0,"pending_credits":0,"pending_credit_amount":0,"transferred_credits":0,"transferred_credit_amount":0,"hosted_page_links":{"payment_info":"https://checkout.reepay.com/#/subscription/pay/da_DK/dfc6a242db64dccb1c5ddb838fb50dc3/sub-0002"}}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        } else if(req.getEndpoint().equals('https://checkout-api.reepay.com/v1/session/charge') && req.getMethod().equals('POST')) {
            String body = '{"id": "cs_ea6dd34fa41c3d4371794d0584fd4c64","url": "https://checkout.reepay.com/#/cs_ea6dd34fa41c3d43"}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        }else if((req.getEndpoint().contains('https://api.reepay.com/v1/subscription') || req.getEndpoint().contains('/cancel')) &&  req.getMethod().equals('POST')) {
            String body = '{"expire_at": "23-09-15"}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        }else if((req.getEndpoint().contains('https://api.reepay.com/v1/invoice') || req.getEndpoint().contains('/cancel')) &&  req.getMethod().equals('POST')) {
            String body = '{"expire_at": "23-09-15"}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        }else if(String.isBlank(req.getEndpoint()) && req.getMethod().equals('POST')) {
            String body = '{"error": "", "http_status": "400"}';
            response.setBody(body);
            response.setStatusCode(400);
            return response;
        }else if(req.getEndpoint().contains('https://api.reepay.com/v1/subscription') &&  req.getMethod().equals('POST')) {
            String body = '{"error": "", "http_status": "400"}';
            response.setBody(body);
            response.setStatusCode(400);
            return response;
        }else if(req.getEndpoint().contains('https://api.reepay.com/v1/subscription/sub-0002') &&  req.getMethod().equals('GET')) {//Changes DFJ-128 Starts
            String body = '{"handle":"sub-0002","trial_end":"2024-10-11T14:01:47.481+00:00","customer":"kushagra.mishra@cloudanalogy.com","plan":"FitnessPlan01", "state":"active","test":true,"amount":20000,"quantity":3,"timezone":"Europe/Copenhagen","created":"2022-07-11T14:01:47.481+00:00","activated":"2022-07-11T14:01:47.481+00:00","renewing":false,"plan_version":1,"amount_incl_vat":true,"start_date":"2022-06-28T22:00:00.000+00:00","end_date":"2022-11-30T23:00:00.000+00:00","grace_duration":172800,"current_period_start":"2022-06-28T22:00:00.000+00:00","next_period_start":"2024-06-28T22:00:00.000+00:00","first_period_start":"2022-06-28T22:00:00.000+00:00","is_cancelled":false,"in_trial":true,"has_started":true,"renewal_count":1,"payment_method_added":false,"failed_invoices":0,"failed_amount":0,"cancelled_invoices":0,"cancelled_amount":0,"pending_invoices":1,"pending_amount":60000,"dunning_invoices":0,"dunning_amount":0,"settled_invoices":0,"settled_amount":0,"refunded_amount":0,"pending_additional_costs":0,"pending_additional_cost_amount":0,"transferred_additional_costs":0,"transferred_additional_cost_amount":0,"pending_credits":0,"pending_credit_amount":0,"transferred_credits":0,"transferred_credit_amount":0,"hosted_page_links":{"payment_info":"https://checkout.reepay.com/#/subscription/pay/da_DK/dfc6a242db64dccb1c5ddb838fb50dc3/sub-0002"}}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        }else if((req.getEndpoint().contains('https://api.reepay.com/v1/subscription') || req.getEndpoint().contains('/subscription_renewal')) &&  req.getMethod().equals('POST')) {
            String body = '{"handle": "sub-0002","renewal_count":2,"in_trial":true}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        }else if((req.getEndpoint().contains('https://api.reepay.com/v1/subscription') || req.getEndpoint().contains('/subscription_trial_end')) &&  req.getMethod().equals('POST')) {
            String body = '{"handle": "sub-0002"}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        }else if((req.getEndpoint().contains('https://api.reepay.com/v1/subscription') || req.getEndpoint().contains('/subscription_expired')) &&  req.getMethod().equals('POST')) {
            String body = '{"handle": "sub-0002"}';
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        }
        return null;
    }
}