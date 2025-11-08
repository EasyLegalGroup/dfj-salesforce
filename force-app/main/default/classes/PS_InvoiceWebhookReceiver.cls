/**
 * Apex rest resource class to receive invoice updates
 * Full URL : https://dinsweden-dfj.cs162.force.com/invoice/services/apexrest/updates
 * https://docfab-dfj.cs89.force.com/docfab/services/apexrest/v1/metadata/
 */
@RestResource(urlMapping='/updates')
global without sharing class PS_InvoiceWebhookReceiver {

    @HttpPost
    global static void invoiceUpdatesHandler() {
        RestRequest request = RestContext.request;
        RestResponse responseToSend = RestContext.response;
        try {
            PS_InvoiceWebhookHelper.parseWebhookData(request.requestBody.toString());
            responseToSend.statusCode = 200;
        } catch (Exception ex) {
            responseToSend.statusCode = 400;
            System.debug('request >>> '+ex.getMessage() + '::: Line number >>> '+ ex.getLineNumber());
            DFJ_ErrorLogController.addErrorLogs('', 'Handling the webhook received', ex.getMessage(), 'Error', 'PS_InvoiceWebhookReceiver.invoiceUpdatesHandler', '', String.valueOf(ex.getLineNumber()));
        }
    }
}