public without sharing class PS_InvoiceWebhookHelper {
    public static final String getInvoiceURL = 'https://api.reepay.com/v1/invoice/';
    public static final String createSubscriptionURL = 'https://api.reepay.com/v1/subscription';
    public static final String getSubscriptionURL = 'https://api.reepay.com/v1/subscription/';



    /*
* @Description  parse the webhook data to get the invoice.
* @Param        invoicewebhookRequestBody
* @Return       boolean
*/


    public static Boolean parseWebhookData(String invoicewebhookRequestBody) {
        try {
            PS_PaymentUtility.InvoiceWebhookWrapper invoiceWebhookWrapperInstance = new PS_PaymentUtility.InvoiceWebhookWrapper();
            invoiceWebhookWrapperInstance = (PS_PaymentUtility.InvoiceWebhookWrapper) JSON.deserialize(invoicewebhookRequestBody, PS_PaymentUtility.InvoiceWebhookWrapper.class);

            if (invoiceWebhookWrapperInstance.event_type.equals('invoice_settled') || invoiceWebhookWrapperInstance.event_type.equals('invoice_authorized') || invoiceWebhookWrapperInstance.event_type.equals('invoice_cancelled') || invoiceWebhookWrapperInstance.event_type.equals('invoice_failed') || invoiceWebhookWrapperInstance.event_type.equals('invoice_cancelled') || invoiceWebhookWrapperInstance.event_type.equals('invoice_refund')) {

                updateInvoiceByHandleSubscription(invoiceWebhookWrapperInstance.invoice, invoiceWebhookWrapperInstance.subscription, invoiceWebhookWrapperInstance.event_type);


            } else if (invoiceWebhookWrapperInstance.event_type.equals('invoice_created') && String.isNotBlank(invoiceWebhookWrapperInstance.invoice) && String.isNotBlank(invoiceWebhookWrapperInstance.subscription)) {
                createInvoiceBySubscription(invoiceWebhookWrapperInstance.invoice, invoiceWebhookWrapperInstance.subscription, invoiceWebhookWrapperInstance.event_type);
            } else if (invoiceWebhookWrapperInstance.event_type.equals('subscription_payment_method_added')) {
                // find payment where subscription='leadproductId'
                // find subscription payment
                updateSubscriptionStatus(invoiceWebhookWrapperInstance.subscription, invoiceWebhookWrapperInstance.event_type);
                // Update the statusmethodForCreateSubscription
            } else if (invoiceWebhookWrapperInstance.event_type.equals('subscription_reactivated') || invoiceWebhookWrapperInstance.event_type.equals('subscription_on_hold') || invoiceWebhookWrapperInstance.event_type.equals('subscription_uncancelled') || invoiceWebhookWrapperInstance.event_type.equals('subscription_changed') || invoiceWebhookWrapperInstance.event_type.equals('subscription_expired') || invoiceWebhookWrapperInstance.event_type.equals('subscription_trial_end') || invoiceWebhookWrapperInstance.event_type.equals('subscription_renewal') || invoiceWebhookWrapperInstance.event_type.equals('subscription_cancelled')) {//DFJ-128 Changes
                updateRelatedSubscription(invoiceWebhookWrapperInstance.subscription, invoiceWebhookWrapperInstance.event_type);
                // Update the status
            }
            return true;
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Received payment webhook', ex.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.parseWebhookData', '', String.valueOf(ex.getLineNumber()));
        }
        return false;
    }


    /*
* @Description  helper method to create the payment when subscription and invoice is there.
* @Param        invoicesubscription, invoicehandle
* @Return       Boolean
*/
    public static Boolean createInvoiceBySubscription(String invoicehandle, String invoicesubscription, String eventType) {
        // Get main invoice using subscription and get currency
        List<Payments__c> paymentRecordList = new List<Payments__c>();
        String paymentCondition = 'Subscription_id__c = \'' + invoicesubscription + '\'';

        paymentRecordList = fetchPaymentByCondition(paymentCondition);
        if (!paymentRecordList.isEmpty()) {
            //DFJ-191 Changes added a condition to check if subscription plan has trial or not.
            List<Subscriptions__c> getSubscriptionsList = [SELECT Id, Plan_Has_Trial__c, Is_First_Invoice__c, Renewals__c FROM Subscriptions__c WHERE Subscription_handle__c = :invoicesubscription LIMIT 1];
            if (!getSubscriptionsList.isEmpty() && getSubscriptionsList[0].Plan_Has_Trial__c == false && getSubscriptionsList[0].Is_First_Invoice__c == true) {
                getSubscriptionsList[0].Is_First_Invoice__c = false;
                update getSubscriptionsList;
                // update paymentRecordList;
                return true;
            } else {
                makeGetCalloutToGetInvoice(paymentRecordList, invoicehandle, eventType, invoicesubscription);
            }
            //End

        }
        return true;
    }

    /*
* @Description  make a get request to get the invoice using the invoice handle or Subscription
* @Param        recordId
* @Return       String
*/
    public static Boolean updateInvoiceByHandleSubscription(String invoicehandle, String invoicesubscription, String invoiceEventType) {//,String invoiceCustomer,
        Boolean isSubscritpion = false;
        // String endpointUrl = getInvoiceURL + invoicehandle;
        List<Payments__c> paymentRecordList = new List<Payments__c>();
        //DFJ-80 Added Account in paymentFieldList
        List<String> paymentFieldList = new List<String>{
                'CurrencyISOCode', 'Opportunity__c', 'Check_Payment_On_Account__c', 'Account__c', 'Subscription_id__c', 'Invoice_unique_handle__c', 'Id', 'Name', 'Status__c', 'Type__c', 'Lead__c', 'Order__c', 'Invoice_created__c', 'Amount__c', 'BillingStreet__c', 'BillingState__c', 'Billing_PostalCode__c', 'BillingCity__c', 'BillingCountry__c'
        };
        String paymentCondition = '';
        if (String.isNotBlank(invoicesubscription)) {
            isSubscritpion = true;
        }

        if (!isSubscritpion && String.isNotBlank(invoicehandle)) {
            paymentCondition = 'Invoice_unique_handle__c = \'' + invoicehandle + '\'';

            // paymentRecordList = fetchRecordsDynamically(paymentCondition, paymentFieldList, 'Payments__c');
        } else if (String.isNotBlank(invoicehandle) && String.isNotBlank(invoicesubscription)) {
            paymentCondition = 'Invoice_unique_handle__c = \'' + invoicehandle + '\' AND Subscription_id__c =\'' + invoicesubscription + '\'';
        }

        paymentRecordList = fetchRecordsDynamically(paymentCondition, paymentFieldList, 'Payments__c');
        if (!paymentRecordList.isEmpty()) {
            makeGetCalloutToGetInvoice(paymentRecordList, invoicehandle, invoiceEventType.equals('invoice_created') ? '' : invoiceEventType, invoicesubscription);
        }
        return true;
    }

    /*
* @Description  update the invoice record from the webhook
* @Param        recordId
* @Return       String
*/
    public static Boolean makeGetCalloutToGetInvoice(List<Payments__c> paymentRecordList, String invoicehandle, String eventType, String subscriptionhandle) {
        try{
        Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(paymentRecordList[0].CurrencyISOCode);
        if (Test.isRunningTest()) {
            reepayConfigurationSetting = Reepay_configuration__mdt.getInstance('Test');
        }
        String endpointUrl = getInvoiceURL + invoicehandle;
        HttpRequest request = new HttpRequest();
        //String requestBody = PS_PaymentUtility.buildCustomerRequestBody(currentLead);
        request.setEndpoint(endpointUrl);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);

        Http http = new Http();
        HttpResponse response = http.send(request);
        if ((response.getStatusCode() == 200 && !String.isBlank(response.getBody()))) {
            PS_PaymentUtility.GetInvoiceWrapper getInvoiceWrapperInstance = PS_PaymentUtility.parseReepayInvoice(response.getBody());
            //Changes DFJ-191
            List<Subscriptions__c> getSubscriptionsList = [SELECT Id FROM Subscriptions__c WHERE Subscription_handle__c = :subscriptionhandle LIMIT 1];

            //End
            if (String.isNotBlank(eventType) && eventType.equals('invoice_created')) {//DFJ-191 Added !getSubscriptionsList.isEmpty()
                // find accountID using subscription handle
                List<LeadProducts__c> selectedLeadProduct = getAccountIdBySubscriptionHandle(subscriptionhandle);
                List<OrderItem> selectedOrderItem = getOrderItemFromSubscriptionHandle(subscriptionhandle);

                // Changes for DFJ-273
                // Start
                List<OpportunityLineItem> selectedOpportunityLineItem = getOpportunityLineItemFromSubscriptionHandle(subscriptionhandle);

                // End


                // Create order from accountId child of account
                //Changes Start TCS-35

                if (selectedLeadProduct.isEmpty() && String.isNotBlank(paymentRecordList[0].Lead__c) && paymentRecordList[0].Lead__r.ConvertedAccountId != null) {
                    selectedLeadProduct = [
                            SELECT Id, Sub_Total__c, Discount__c, Is_subscription__c, Plan_handle__c, Item_Price__c, Lead__c, Name, Pricebook_Id__c, CurrencyIsoCode, PricebookEntry_Id__c, Product_Id__c, Product_Name__c, Quantity__c, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c, Lead__r.ConvertedAccountId, Lead__r.Market_Unit__c, Captured_Charge_Count__c, Open_Charges__c, Open_Charge_Count__c, Refunded_Charges__c, Refunded_Charge_Count__c, Retained_Charge_Count__c, Retained_Charges__c, Captured_Charges__c, Completed_Payout_Count__c, Completed_Payouts__c, Open_Payouts__c, Open_Payout_Count__c, Captured_Transfers__c, Retained_Transfer_Count__c, Reversed_Transfer_Count__c, Retained_Transfers__c, Open_Transfers__c, Captured_Transfer_Count__c, Reversed_Transfers__c, Open_Transfer_Count__c, Lead__r.Street, Lead__r.State, Lead__r.City, Lead__r.PostalCode, Lead__r.Country, Lead__r.Name, Lead__r.Email
                            FROM LeadProducts__c
                            WHERE Lead__c = :paymentRecordList[0].Lead__c AND Is_subscription__c = TRUE
                            LIMIT 1
                    ];
                    if (!selectedLeadProduct.isEmpty()) {
                        selectedLeadProduct[0].Id = subscriptionhandle;
                    }
                } else if (selectedLeadProduct.isEmpty() && selectedOrderItem.isEmpty() && String.isNotBlank(paymentRecordList[0].Order__c)) {
                    selectedOrderItem = [SELECT Id, Product2Id, IsDeleted, OrderId, PricebookEntryId, OriginalOrderItemId, QuoteLineItemId, AvailableQuantity, Quantity, CurrencyIsoCode, UnitPrice, ListPrice, TotalPrice, Discount__c, Effective_price__c, Partner_provision_value__c, Partner_sales_value__c, Provision_base__c, DiscountGiven__c, Effective_Provision_Base__c, DiscountGivenProductLine__c, Effective_Partner_Provision_Value__c, Effective_Partner_Sales_Value__c, Effective_Provision_Base_Product_Line__c, ProvisionCheck__c, Product_Name__c, Plan_handle__c, Is_subscription__c, Order.AccountId, Order.Market_Unit__c, Order.BillingStreet, Order.BillingState, Order.BillingCity, Order.BillingPostalCode, Order.Lead__c, Order.currencyIsoCode, Order.Account.Name, Order.Account.PersonEmail, Order.Pricebook2Id FROM OrderItem WHERE OrderId = :paymentRecordList[0].Order__c AND Is_subscription__c = TRUE LIMIT 1];
                    if (!selectedOrderItem.isEmpty()) {
                        selectedOrderItem[0].Id = subscriptionhandle;
                    }
                }

                // Changes for DFJ-273
                // Start
                else if (selectedOpportunityLineItem.isEmpty() && selectedLeadProduct.isEmpty() && selectedOrderItem.isEmpty() && String.isNotBlank(paymentRecordList[0].Opportunity__c)) {
                    selectedOpportunityLineItem = [
                            SELECT
                                    Id, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c, Discount, Product2Id, PricebookEntryId, Name, Quantity, Opportunity.AccountId,
                                    Opportunity.Account.Market_Unit__c, UnitPrice, ListPrice, TotalPrice, Opportunity.Account.BillingStreet, Opportunity.Account.BillingState, Opportunity.Account.BillingCity,
                                    Opportunity.Account.BillingPostalCode, Opportunity.Account.CurrencyIsoCode, Opportunity.Account.Name, Opportunity.Account.PersonEmail, PricebookEntry.Pricebook2Id
                            FROM OpportunityLineItem
                            WHERE
                                    OpportunityId = :paymentRecordList[0].Opportunity__c AND
                                    Is_subscription__c = TRUE

                            LIMIT 1
                    ];

                    if (!selectedOpportunityLineItem.isEmpty()) {

                        selectedOpportunityLineItem[0].Id = subscriptionhandle;

                    }
                }

                // End


                //End
                if (!selectedLeadProduct.isEmpty() && selectedLeadProduct[0].Lead__r.ConvertedAccountId != null) {
                    createOrderAndPayment(getInvoiceWrapperInstance, selectedLeadProduct, selectedOrderItem, selectedOpportunityLineItem);
                } else if (!selectedOrderItem.isEmpty()) {
                    createOrderAndPayment(getInvoiceWrapperInstance, selectedLeadProduct, selectedOrderItem, selectedOpportunityLineItem);
                } else if (!selectedOpportunityLineItem.isEmpty()) {
                    createOrderAndPayment(getInvoiceWrapperInstance, selectedLeadProduct, selectedOrderItem, selectedOpportunityLineItem);
                }
            }

            else {

                updateInvoiceByWebhook(getInvoiceWrapperInstance, paymentRecordList);

                //    DFJ-318 changes start
                if ( eventType.equals('invoice_refund') || eventType.equals('invoice_settled')){

                    if (!getInvoiceWrapperInstance.transactions.isEmpty()) {
                                PS_PaymentUtility.PS_transactions retrievedLatestTransaction = getInvoiceWrapperInstance.transactions.get(getInvoiceWrapperInstance.transactions.size()-1);
                        if (retrievedLatestTransaction.state.equals('refunded') || retrievedLatestTransaction.state.equals('settled')) {
                            Transaction__c transactionRecord = new Transaction__c(
                                    //Payment__c = Id.valueOf(invoicehandle),
                                    Payment__c = paymentRecordList[0].id,//DFJ-318-V2
                                    Amount__c = (retrievedLatestTransaction.amount)/100,
                                    Type__c = retrievedLatestTransaction.type,
                                    Payment_Type__c = retrievedLatestTransaction.payment_type

                            );

                            if (retrievedLatestTransaction.manual_transaction != null) {
                                transactionRecord.Method__c = retrievedLatestTransaction.manual_transaction.method;
                                transactionRecord.Comment__c = retrievedLatestTransaction.manual_transaction.comment;
                                transactionRecord.Reference__c = retrievedLatestTransaction.manual_transaction.reference;
                                transactionRecord.Payment_Date__c = retrievedLatestTransaction.manual_transaction.payment_date;
                            }
                            if(transactionRecord != null){
                            insert transactionRecord;
                            }


                            if (transactionRecord.Id != null && eventType.equals('invoice_refund')) {
                                PS_PaymentUtility.CreditNoteWrapper retrievedLatestCreditNote = getInvoiceWrapperInstance.credit_notes.get(getInvoiceWrapperInstance.credit_notes.size()-1);

                                if ( retrievedLatestCreditNote.id.equals(retrievedLatestTransaction.id) && !retrievedLatestCreditNote.credit_note_lines.isEmpty() ) {
                                        List<RefundAndCredits__c> listOfRefundAndCreditsToInsert = new List<RefundAndCredits__c>();

                                        for (PS_PaymentUtility.CreditNoteLineWrapper item : retrievedLatestCreditNote.credit_note_lines) {
                                            RefundAndCredits__c refundAndCreditsRecord = new RefundAndCredits__c(
                                                    Payment__c = paymentRecordList[0].id,//DFJ-318-V2
                                                    Description__c = item.text,
                                                    Amount__c = item.amount / 100,
                                                    Quantity__c = item.quantity,
                                                    Transaction__c = transactionRecord.Id
                                            );

                                            listOfRefundAndCreditsToInsert.add(refundAndCreditsRecord);
                                        }
                                        if(!listOfRefundAndCreditsToInsert.isEmpty()){
                                            insert listOfRefundAndCreditsToInsert;
                                        } 
                                }
                            }
                        }


                    }

                }


            //    DFJ-318 changes end
            }

            return true;
        }
        return false;
        }
        catch(exception ex){
           DFJ_ErrorLogController.addErrorLogs('', 'Make callout to get Invoice : making callout', ex.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.makeGetCalloutToGetInvoice', 'stackTrace', String.valueOf(ex.getLineNumber()));
        }
        return false;
    }

    // Changes for DFJ-273
    // Start

    /*
* @Description  get OpportunityLineItem by subscription handle
* @Param        subscriptionHandle
* @Return       List<OpportunityLineItem>
*/
    public static List<OpportunityLineItem> getOpportunityLineItemFromSubscriptionHandle(String subscriptionHandle) {


        List<OpportunityLineItem> opportunityLineItem = [
                SELECT
                        Id, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c, Discount, Product2Id, PricebookEntryId, Name, Quantity, Opportunity.AccountId,
                        Opportunity.Account.Market_Unit__c, UnitPrice, ListPrice, TotalPrice, Opportunity.Account.BillingStreet, Opportunity.Account.BillingState, Opportunity.Account.BillingCity,
                        Opportunity.Account.BillingPostalCode, Opportunity.Account.CurrencyIsoCode, Opportunity.Account.Name, Opportunity.Account.PersonEmail, PricebookEntry.Pricebook2Id
                FROM OpportunityLineItem
                WHERE Id = :subscriptionHandle
                LIMIT 1
        ];


        return opportunityLineItem;

    }

    // End

    /*
* @Description  get accountId by subscription handle to lokup for the account to create the order.
* @Param        recordId
* @Return       String
*/
    public static List<LeadProducts__c> getAccountIdBySubscriptionHandle(String subscriptionHandle) {
        List<LeadProducts__c> leadproduct = new List<LeadProducts__c>();
        String leadCondition = 'Id = \'' + subscriptionHandle + '\'';
        List<String> leadProductFields = new List<String>{
                'Lead__r.ConvertedAccountId', 'Lead__r.Market_Unit__c', 'Discount__c', 'Item_Price__c', 'Lead__c', 'PricebookEntry_Id__c', 'Pricebook_Id__c', 'Product_Id__c', 'Product_Name__c', 'Quantity__c', 'Sub_Total__c', 'Partner_Provision_Value__c', 'Partner_Sales_Value__c', 'Provision_Base__c', 'Captured_Charge_Count__c', 'Open_Charges__c', 'Open_Charge_Count__c', 'Refunded_Charges__c', 'Refunded_Charge_Count__c', 'Retained_Charge_Count__c', 'Retained_Charges__c', 'Captured_Charges__c', 'Completed_Payout_Count__c', 'Completed_Payouts__c', 'Open_Payouts__c', 'Open_Payout_Count__c', 'Captured_Transfers__c', 'Retained_Transfer_Count__c', 'Reversed_Transfer_Count__c', 'Retained_Transfers__c', 'Open_Transfers__c', 'Captured_Transfer_Count__c', 'Reversed_Transfers__c', 'Open_Transfer_Count__c', 'Is_subscription__c', 'Plan_handle__c', 'Id', 'Name', 'CurrencyIsoCode', 'Lead__r.Street', 'Lead__r.State', 'Lead__r.City', 'Lead__r.PostalCode', 'Lead__r.Country', 'Lead__r.Name', 'Lead__r.Email'
        };
        leadproduct = fetchRecordsDynamically(leadCondition, leadProductFields, 'LeadProducts__c');
        return leadproduct;
    }

    /*
* @Description  create order and payment when we get create invoice event.
* @Param        recordId
* @Return       String
*/
    public static Boolean createOrderAndPayment(PS_PaymentUtility.GetInvoiceWrapper getInvoiceWrapperInstance, List<LeadProducts__c> selectedLeadProduct, List<OrderItem> selectedOrderItem, List<OpportunityLineItem> selectedOpportunityLineItem) {

        //Changes TCS-16
        //Start
        //Changes DFJ-168
        List<Subscriptions__c> getSubscriptions = [SELECT Id FROM Subscriptions__c WHERE Subscription_handle__c = :getInvoiceWrapperInstance.subscription LIMIT 1];
        //End
        Order orderRecord = new Order();

        if (!selectedOpportunityLineItem.isEmpty()) {
            Id oliId = selectedOpportunityLineItem[0].Id;

            selectedOpportunityLineItem[0] = [
                    SELECT Id, Name, OpportunityId,
                            Opportunity.AccountId,
                            PricebookEntry.Pricebook2Id,
                            Opportunity.Account.BillingStreet,
                            Opportunity.Account.BillingState,
                            Opportunity.Account.BillingPostalCode,
                            Opportunity.Account.BillingCity,
                            Opportunity.Account.Market_Unit__c,
                            Opportunity.Account.CurrencyIsoCode,
                            PricebookEntryId, Product2Id, Discount, Quantity, UnitPrice,
                            Partner_Sales_Value__c, Provision_Base__c, Partner_Provision_Value__c,
                            Opportunity.Account.Name, Opportunity.Account.PersonEmail

                    FROM
                            OpportunityLineItem
                    WHERE
                            Id = :oliId
                    LIMIT 1
            ];
        }

        orderRecord.AccountId = (
                !selectedLeadProduct.isEmpty() ?
                        selectedLeadProduct[0].Lead__r.ConvertedAccountId :
                        (!selectedOrderItem.isEmpty() ?
                                selectedOrderItem[0].Order.AccountId :
                                (!selectedOpportunityLineItem.isEmpty() ?
                                        selectedOpportunityLineItem[0].Opportunity.AccountId :
                                        null)
                        ));


        orderRecord.Pricebook2Id = (
                !selectedLeadProduct.isEmpty() ?
                        selectedLeadProduct[0].Pricebook_Id__c :
                        (!selectedOrderItem.isEmpty() ?
                                selectedOrderItem[0].Order.Pricebook2Id :
                                (!selectedOpportunityLineItem.isEmpty() ?
                                        selectedOpportunityLineItem[0].PricebookEntry.Pricebook2Id :
                                        null)
                        ));

        orderRecord.Status = 'Draft';
        //DFJ-168 Changes
        orderRecord.Subscription_Renewal__c = true;
        // orderRecord.Subscriptions__c = getSubscriptions[0].Id;
        //End

        orderRecord.BillingStreet = (
                !selectedLeadProduct.isEmpty() ?
                        selectedLeadProduct[0].Lead__r.Street :
                        !selectedOrderItem.isEmpty() ?
                                selectedOrderItem[0].Order.BillingStreet :
                                !selectedOpportunityLineItem.isEmpty() ?
                                        selectedOpportunityLineItem[0].Opportunity.Account.BillingStreet :
                                        null
        );

        orderRecord.BillingState = (!selectedLeadProduct.isEmpty() ?
                selectedLeadProduct[0].Lead__r.State :
                !selectedOrderItem.isEmpty() ?
                        selectedOrderItem[0].Order.BillingState :
                        !selectedOpportunityLineItem.isEmpty() ?
                                selectedOpportunityLineItem[0].Opportunity.Account.BillingState :
                                null
        );


        orderRecord.BillingPostalCode = (!selectedLeadProduct.isEmpty() ?
                selectedLeadProduct[0].Lead__r.PostalCode :
                !selectedOrderItem.isEmpty() ?
                        selectedOrderItem[0].Order.BillingPostalCode :
                        !selectedOpportunityLineItem.isEmpty() ?
                                selectedOpportunityLineItem[0].Opportunity.Account.BillingPostalCode :
                                null
        );
        orderRecord.BillingCity = (!selectedLeadProduct.isEmpty() ?
                selectedLeadProduct[0].Lead__r.City :
                !selectedOrderItem.isEmpty() ?
                        selectedOrderItem[0].Order.BillingCity :
                        !selectedOpportunityLineItem.isEmpty() ?
                                selectedOpportunityLineItem[0].Opportunity.Account.BillingCity :
                                null
        );

        orderRecord.Market_Unit__c = (!selectedLeadProduct.isEmpty() ?
                selectedLeadProduct[0].Lead__r.Market_Unit__c :
                !selectedOrderItem.isEmpty() ?
                        selectedOrderItem[0].Order.Market_Unit__c :
                        !selectedOpportunityLineItem.isEmpty() ?
                                selectedOpportunityLineItem[0].Opportunity.Account.Market_Unit__c :
                                null
        );

        orderRecord.Lead__c = (!selectedLeadProduct.isEmpty() ?
                selectedLeadProduct[0].Lead__c :
                !selectedOrderItem.isEmpty() ?
                        selectedOrderItem[0].Order.Lead__c :
                        null
        );

        if (!selectedOpportunityLineItem.isEmpty()) {
            orderRecord.Opportunity__c = selectedOpportunityLineItem[0].OpportunityId;
        }

        orderRecord.CurrencyIsoCode = (!selectedLeadProduct.isEmpty() ?
                selectedLeadProduct[0].CurrencyIsoCode :
                !selectedOrderItem.isEmpty() ?
                        selectedOrderItem[0].Order.CurrencyIsoCode :
                        !selectedOpportunityLineItem.isEmpty() ?
                                selectedOpportunityLineItem[0].Opportunity.Account.CurrencyIsoCode :
                                null
        );

        orderRecord.EffectiveDate = Date.today();


        insert orderRecord;

        List<OrderItem> orderItemList = new List<OrderItem>();
        if (!selectedLeadProduct.isEmpty()) {
            for (LeadProducts__c leadProduct : selectedLeadProduct) {
                OrderItem orderLineItem = new OrderItem();
                orderLineItem.OrderId = orderRecord.Id;
                orderLineItem.PricebookEntryId = selectedLeadProduct[0].PricebookEntry_Id__c;
                orderLineItem.Product2Id = selectedLeadProduct[0].Product_Id__c;
                orderLineItem.Discount__c = selectedLeadProduct[0].Discount__c;
                orderLineItem.Quantity = selectedLeadProduct[0].Quantity__c;
                orderLineItem.UnitPrice = selectedLeadProduct[0].Item_Price__c;
                orderLineItem.Partner_provision_value__c = selectedLeadProduct[0].Partner_Provision_Value__c;
                orderLineItem.Partner_sales_value__c = selectedLeadProduct[0].Partner_Sales_Value__c;
                orderLineItem.Provision_base__c = selectedLeadProduct[0].Provision_Base__c;

                orderItemList.add(orderLineItem);
            }
        } else if (!selectedOrderItem.isEmpty()) {
            for (OrderItem leadProduct : selectedOrderItem) {
                OrderItem orderLineItem = new OrderItem();
                orderLineItem.OrderId = orderRecord.Id;
                orderLineItem.PricebookEntryId = selectedOrderItem[0].PricebookEntryId;
                orderLineItem.Product2Id = selectedOrderItem[0].Product2Id;
                orderLineItem.Discount__c = selectedOrderItem[0].Discount__c;
                orderLineItem.Quantity = selectedOrderItem[0].Quantity;
                orderLineItem.UnitPrice = selectedOrderItem[0].UnitPrice;
                orderLineItem.Partner_provision_value__c = selectedOrderItem[0].Partner_provision_value__c;
                orderLineItem.Partner_sales_value__c = selectedOrderItem[0].Partner_sales_value__c;
                orderLineItem.Provision_base__c = selectedOrderItem[0].Provision_base__c;

                orderItemList.add(orderLineItem);
            }
        } else if (!selectedOpportunityLineItem.isEmpty()) {
            for (OpportunityLineItem oli : selectedOpportunityLineItem) {
                OrderItem orderLineItem = new OrderItem();

                orderLineItem.OrderId = orderRecord.Id;
                orderLineItem.PricebookEntryId = oli.PricebookEntryId;
                orderLineItem.Product2Id = oli.Product2Id;
                orderLineItem.Discount__c = oli.Discount;
                orderLineItem.Quantity = oli.Quantity;
                orderLineItem.UnitPrice = oli.UnitPrice;
                orderLineItem.Partner_provision_value__c = oli.Partner_Provision_Value__c;
                orderLineItem.Partner_sales_value__c = oli.Partner_Sales_Value__c;
                orderLineItem.Provision_base__c = oli.Provision_Base__c;

                orderItemList.add(orderLineItem);
            }
        }

        if (orderItemList != null && !orderItemList.isEmpty()) {
            insert orderItemList;
        }


        // Create payment

        Payments__c paymentRecord = new Payments__c();
        paymentRecord.Order__c = orderRecord.Id;
        paymentRecord.Amount__c = getInvoiceWrapperInstance.amount / 100;
        paymentRecord.CurrencyIsoCode = orderRecord.CurrencyIsoCode ;
        paymentRecord.BillingStreet__c = orderRecord.BillingStreet;
        paymentRecord.BillingState__c = orderRecord.BillingState;
        paymentRecord.Billing_PostalCode__c = orderRecord.BillingPostalCode;
        paymentRecord.BillingCity__c = orderRecord.BillingCity;


        paymentRecord.Billing_name__c = (
                !selectedLeadProduct.isEmpty() ?
                        selectedLeadProduct[0].Lead__r.Name :
                        !selectedOrderItem.isEmpty() ?
                                selectedOrderItem[0].Order.Account.Name :
                                !selectedOpportunityLineItem.isEmpty() ?
                                        selectedOpportunityLineItem[0].Opportunity.Account.Name :
                                        null
        );

        paymentRecord.Billing_email__c = (
                !selectedLeadProduct.isEmpty() ?
                        selectedLeadProduct[0].Lead__r.Email :
                        !selectedOrderItem.isEmpty() ?
                                selectedOrderItem[0].Order.Account.PersonEmail :
                                !selectedOpportunityLineItem.isEmpty() ?
                                        selectedOpportunityLineItem[0].Opportunity.Account.PersonEmail :
                                        null
        );

        paymentRecord.Invoice_unique_handle__c = Test.isRunningTest() ? (getInvoiceWrapperInstance.handle + '0') : getInvoiceWrapperInstance.handle ;
        paymentRecord.Status__c = getInvoiceWrapperInstance.state;
        paymentRecord.Invoice_id__c = getInvoiceWrapperInstance.id;
        paymentRecord.Subscription_status__c = 'Activated';
        paymentRecord.Type__c = 'Subscription';

        paymentRecord.Subscription_id__c = (
                !selectedLeadProduct.isEmpty() ?
                        selectedLeadProduct[0].Id :
                        !selectedOrderItem.isEmpty() ?
                                selectedOrderItem[0].Id :
                                !selectedOpportunityLineItem.isEmpty() ?
                                        selectedOpportunityLineItem[0].Id :
                                        null
        );

        //DFJ-168 Changes

        paymentRecord.Account__c = (
                !selectedLeadProduct.isEmpty() ?
                        selectedLeadProduct[0].Lead__r.ConvertedAccountId :
                        !selectedOrderItem.isEmpty() ?
                                selectedOrderItem[0].Order.AccountId :
                                !selectedOpportunityLineItem.isEmpty() ?
                                        selectedOpportunityLineItem[0].Opportunity.AccountId :
                                        null
        );

        paymentRecord.Subscriptions__c = !getSubscriptions.isEmpty() ? getSubscriptions[0].Id : null;
        //End
        insert paymentRecord;

        return true;
        //End
    }

    /*
* @Description  update the invoice record from the webhook
* @Param        recordId
* @Return       String
*/
    public static Boolean updateInvoiceByWebhook(PS_PaymentUtility.GetInvoiceWrapper invoiceWrapperInstance, List<Payments__c> paymentRecordList) {
        try {


            if (String.isBlank(invoiceWrapperInstance.errorMessage)) {
                PS_PaymentUtility.PS_SubscriptionWrapper responseWrapperIns = new PS_PaymentUtility.PS_SubscriptionWrapper();
                List<PS_PaymentUtility.PS_transactions> transactions = new List<PS_PaymentUtility.PS_transactions>();
                PS_PaymentUtility.PS_card_transaction cardTransaction = new PS_PaymentUtility.PS_card_transaction();
                PS_PaymentUtility.PS_mps_transaction mpsTransaction = new PS_PaymentUtility.PS_mps_transaction();
                PS_PaymentUtility.PS_mpo_transaction mpoTransaction = new PS_PaymentUtility.PS_mpo_transaction();
                PS_PaymentUtility.PS_manual_transaction manualTransaction = new PS_PaymentUtility.PS_manual_transaction();
                PS_PaymentUtility.PS_klarna_transaction klarnaTransaction = new PS_PaymentUtility.PS_klarna_transaction();
                Integer settledIndex = -1;
                String refundedString = '';
                String paymentRecordId = '';
                transactions = invoiceWrapperInstance.transactions;

                // DFJ-318 changes start
                Integer indexOfSettledTransaction = -1;
                // DFJ-318 changes end

                if (!transactions.isEmpty()) {
                    transactions = invoiceWrapperInstance.transactions;
                    for (Integer i = 0; i < transactions.size(); i++) {
                        //DIN-330 Changes
                        //start
                        if (transactions[i].state.equalsIgnoreCase('refunded')) {
                            refundedString = 'refunded';
                            settledIndex = i;
                        } else if (transactions[i].state.equalsIgnoreCase('settled')) {
                            // DFJ-318 changes start
                            indexOfSettledTransaction = i;
                            // DFJ-318 changes end

                            //refundIndex = i;
                            settledIndex = i;
                        }
                        //End
                        if (transactions[i].card_transaction != null) {
                            cardTransaction = transactions[i].card_transaction;
                            paymentRecordList[0].Transaction_error__c = String.isNotBlank(cardTransaction.error) ? cardTransaction.error : '';

                        } else if (transactions[i].manual_transaction != null) {
                            manualTransaction = transactions[i].manual_transaction;
                        } else if (transactions[i].mps_transaction != null) {
                            mpsTransaction = transactions[i].mps_transaction;
                            paymentRecordList[0].Transaction_error__c = String.isNotBlank(mpsTransaction.error) ? mpsTransaction.error : '';
                        } else if (transactions[i].mpo_transaction != null) {
                            mpoTransaction = transactions[i].mpo_transaction;
                            paymentRecordList[0].Transaction_error__c = String.isNotBlank(mpoTransaction.error) ? mpsTransaction.error : '';
                        }
                        //Changes Start TCS-36
                        else if (transactions[i].klarna_transaction != null) {
                            klarnaTransaction = transactions[i].klarna_transaction;
                            paymentRecordList[0].Transaction_error__c = String.isNotBlank(klarnaTransaction.error) ? klarnaTransaction.error : '';
                        }
                        //End
                        paymentRecordList[0].Transaction_id__c = transactions[i].id;
                        paymentRecordList[0].Payment_ID__c = String.isNotBlank(transactions[i].id) ? transactions[i].id : '';
                        paymentRecordList[0].Payment_type__c = String.isNotBlank(transactions[i].payment_type) ? transactions[i].payment_type : '';
                        paymentRecordList[0].Transaction_state__c = String.isNotBlank(transactions[i].state.capitalize()) ? transactions[i].state.capitalize() : '';
                    }

                    if (settledIndex > -1) {
                        if (transactions[settledIndex].card_transaction != null) {
                            cardTransaction = transactions[settledIndex].card_transaction;
                            paymentRecordList[0].Transaction_error__c = String.isNotBlank(cardTransaction.error) ? cardTransaction.error : '';
                        } else if (transactions[settledIndex].manual_transaction != null) {
                            manualTransaction = transactions[settledIndex].manual_transaction;
                        } else if (transactions[settledIndex].mps_transaction != null) {
                            mpsTransaction = transactions[settledIndex].mps_transaction;
                            paymentRecordList[0].Transaction_error__c = String.isNotBlank(mpsTransaction.error) ? mpsTransaction.error : '';
                        } else if (transactions[settledIndex].mpo_transaction != null) {
                            mpoTransaction = transactions[settledIndex].mpo_transaction;
                            paymentRecordList[0].Transaction_error__c = String.isNotBlank(mpoTransaction.error) ? mpsTransaction.error : '';
                        }  //Changes Start TCS-36
                        else if (transactions[settledIndex].klarna_transaction != null) {
                            klarnaTransaction = transactions[settledIndex].klarna_transaction;
                            paymentRecordList[0].Transaction_error__c = String.isNotBlank(klarnaTransaction.error) ? klarnaTransaction.error : '';
                        }
                        //End
                        paymentRecordList[0].Transaction_id__c = transactions[settledIndex].id;
                        paymentRecordList[0].Payment_ID__c = String.isNotBlank(transactions[settledIndex].id) ? transactions[settledIndex].id : '';
                        paymentRecordList[0].Payment_type__c = String.isNotBlank(transactions[settledIndex].payment_type) ? transactions[settledIndex].payment_type : '';
                        paymentRecordList[0].Transaction_state__c = String.isNotBlank(transactions[settledIndex].state) ? transactions[settledIndex].state : '';

                        if (!String.isBlank(transactions[settledIndex].settled)) {
                            paymentRecordList[0].Settle_date__c = convertStringToDatetime(transactions[settledIndex].settled);
                        } else {
                            paymentRecordList[0].Refunded_Date__c = convertStringToDatetime((transactions[settledIndex].refunded));
                        }
                    }
                }

                // DFJ-318 changes start
                if (indexOfSettledTransaction > -1) {
                    paymentRecordList[0].Payment_type__c = transactions[indexOfSettledTransaction].payment_type;
                }
                // DFJ-318 changes end

                paymentRecordList[0].Invoice_id__c = invoiceWrapperInstance.id;
                paymentRecordList[0].Invoice_unique_handle__c = invoiceWrapperInstance.handle;

                //TCS-16 Chnages
                //Start
                //End
                //DIN-330 Changes
                //Start
                if (refundedString == 'refunded') {
                    paymentRecordId = paymentRecordList[0].Id;

//                    DFJ-318 Changes Start
                    if (invoiceWrapperInstance.refunded_amount == invoiceWrapperInstance.settled_amount) {
                        paymentRecordList[0].Status__c = 'Refunded';
                    } else {
                        paymentRecordList[0].Status__c = 'Settled';
                    }
//                    DFJ-318 Changes End

                    paymentRecordList[0].Refunded_Amount__c = invoiceWrapperInstance.refunded_amount / 100;
                } else {
                    paymentRecordList[0].Status__c = invoiceWrapperInstance.state;
                    //DFJ-191
                    paymentRecordList[0].Amount__c = Decimal.valueOf(invoiceWrapperInstance.amount) / 100;
                    //End
                }
                //End
                //Changes TCS-16
                //Start
                if (!refundedString.equalsIgnoreCase('refunded') && String.isNotBlank(invoiceWrapperInstance.recurring_payment_method)) {
                    paymentRecordList[0].Payment_Method__c = invoiceWrapperInstance.recurring_payment_method;
                    createSubscriptionBasedonSavedPaymnetMethod(paymentRecordList, invoiceWrapperInstance.recurring_payment_method);
                } else if (!refundedString.equalsIgnoreCase('refunded') && String.isBlank(invoiceWrapperInstance.recurring_payment_method)) {//Changes DFJ-168
                    updateRelatedSubscription(paymentRecordList[0].Subscription_id__c, '');
                }
                //End
                update paymentRecordList;
                return true;
            } else {
                DFJ_ErrorLogController.addErrorLogs('', 'Received payment webhook', 'Got error in getting invoice from reepay Error : ' + invoiceWrapperInstance.errorMessage, 'Error', 'PS_InvoiceWebhookHelper.updateInvoiceByWebhook', '', '');
            }
        } catch (Exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Received payment webhook : Updating payment record', ex.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.updateInvoiceByWebhook', 'stackTrace', String.valueOf(ex.getLineNumber()));
            // DFJ_ErrorLogController.addErrorLogs('', event, message, severity, source, stackTrace, lineNumber);
        }
        return false;
    }

    /**
* @Description  Method to check the record is already present or not.
* @Param        parentObjectAPIName, parentObjDetails
* @Return       List<SObject>
*/
    public static List<SObject> fetchRecordsDynamically(String condition, List<String> fields, String objectName) {
        String query = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName + (!String.isBlank(condition) ? ' WHERE ' + condition : '') + ' LIMIT 1';
        return Database.query(query);
    }

    /**
* @Description  convert string to datetime
* @Param        datetimeString
* @Return       Datetime
*/
    public static Datetime convertStringToDatetime(String datetimeString) {
        List<String> datetimestr = datetimeString.split('\\.')[0].split('T');
        List<String> datestr = datetimestr[0].split('-');
        List<String> timestr = datetimestr[1].split(':');

        Datetime datetimeInstance = Datetime.newInstance(Integer.valueOf(datestr[0]), Integer.valueOf(datestr[1]), Integer.valueOf(datestr[2]), Integer.valueOf(timestr[0]), Integer.valueOf(timestr[1]), Integer.valueOf(timestr[2]));

        return datetimeInstance;
    }

    /*
* @Description  check and update the payment if subscription updated.
* @Param        subscription, event_type
* @Return       Boolean
*/
    public static Boolean updateSubscriptionStatus(String subscription, String event_type) {
        List<Payments__c> paymentRecordList = new List<Payments__c>();
        List<Subscriptions__c> updateSubscription = new List<Subscriptions__c>();
        updateSubscription = [SELECT Id, Lead__c, Account__c FROM Subscriptions__c WHERE Subscription_handle__c = :subscription LIMIT 1];
        String paymentCondition = 'Subscription_id__c =\'' + subscription + '\'';

        paymentRecordList = fetchPaymentByCondition(paymentCondition);
        if (!paymentRecordList.isEmpty()) {
            paymentRecordList[0].Subscription_status__c = 'Accepted';
            //DFJ-168 Changes
            paymentRecordList[0].Subscriptions__c = updateSubscription.isEmpty() == false ? updateSubscription[0].Id : null ;
            //End
        }

        //DFJ-128 Changes
        try {

            if (!updateSubscription.isEmpty() && updateSubscription[0].Account__c == null) {

                updateSubscription[0].Account__c = (paymentRecordList[0].Order__r.AccountId != null ? paymentRecordList[0].Order__r.AccountId : paymentRecordList[0].Lead__r.ConvertedAccountId != null ? paymentRecordList[0].Lead__r.ConvertedAccountId : null);
                //DFJ-168 Changes
                if (updateSubscription[0].Lead__c == null) {
                    updateSubscription[0].Lead__c = paymentRecordList[0].Order__r.Lead__c != null ? paymentRecordList[0].Order__r.Lead__c : null ;

                }
                //End
                update updateSubscription;

            }

        } catch (exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Updating subscription record for ' + updateSubscription[0].Id + ' ', ex.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.updateSubscriptionStatus', '', String.valueOf(ex.getLineNumber()));
        }//End
        update paymentRecordList;
        return true;
    }


    /*
* @Description  fetch payment record conditionaly.
* @Param        paymentCondition
* @Return       List<Payments__c>
*/
    public static List<Payments__c> fetchPaymentByCondition(String paymentCondition) {
        List<Payments__c> paymentRecordList = new List<Payments__c>();
        //DFJ-128 Changes added Order__r.AccountId  and Market_Unit__c in query 
        List<String> paymentFieldList = new List<String>{
                'Order__r.Lead__c', 'Opportunity__c', 'CurrencyISOCode', 'Subscriptions__c', 'Market_Unit__c', 'Order__r.AccountId', 'Id', 'Account__c', 'Check_Payment_On_Account__c', 'Subscription_id__c', 'Invoice_unique_handle__c', 'Name', 'Status__c', 'Type__c', 'Lead__c', 'Order__c', 'Invoice_created__c', 'Amount__c', 'BillingStreet__c', 'BillingState__c', 'Billing_PostalCode__c', 'BillingCity__c', 'BillingCountry__c', 'Lead__r.ConvertedAccountId'
        };  //Changes TCS-35 Check ConvertAccountId Incase of Lead Convert and get Membership Product Id
        paymentRecordList = fetchRecordsDynamically(paymentCondition, paymentFieldList, 'Payments__c');
        return paymentRecordList;
    }

    //Changes TCS-16
    //Start
    /*
* @Description  Create subscription using recurring_payment_method
* @Param        paymentRecordList , recurringPaymnetMethod
* @Return       PS_PaymentUtility.PS_SubscriptionWrapper
*/
    public static PS_PaymentUtility.PS_SubscriptionWrapper createSubscriptionBasedonSavedPaymnetMethod(List<Payments__c> paymentRecordsList, String recurringPaymentMethod) {

        PS_PaymentUtility.PS_SubscriptionWrapper subscriptionResponseWrapperIns = new PS_PaymentUtility.PS_SubscriptionWrapper();
        try {
            List<LeadProducts__c> leadProducts = new List<LeadProducts__c>();
            List<LeadProducts__c> leadProductsForSubscription = new List<LeadProducts__c>();
            List<OrderItem> orderItemForSubscription = new List<OrderItem>();
            List<OrderItem> orderItems = new List<OrderItem>();
            //DFJ-80
            List<Payment_order_line__c> paymentItemsOnAccount = new List<Payment_order_line__c>();
            List<Payment_order_line__c> paymentItemsForSubscription = new List<Payment_order_line__c>();
            //End

            // Changes for DFJ-273
            // Start
            List<OpportunityLineItem> oppProds = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oppProdsForSubscription = new List<OpportunityLineItem>();
            // End

            List<Payment_order_line__c> paymentOrderItems = new List<Payment_order_line__c>();
            paymentOrderItems = [SELECT Amount__c, Quantity__c, Vat__c, Name, Payments__c FROM Payment_order_line__c WHERE Payments__c = :paymentRecordsList[0].Id];

            if (!String.isBlank(paymentRecordsList[0].Lead__c) && !paymentRecordsList[0].Check_Payment_On_Account__c) {
                leadProducts = [SELECT Id, Sub_Total__c, Discount__c, Is_subscription__c, Plan_handle__c, Item_Price__c, Lead__c, Name, Pricebook_Id__c, CurrencyIsoCode, PricebookEntry_Id__c, Product_Id__c, Product_Name__c, Quantity__c, Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c FROM LeadProducts__c WHERE Lead__c = :paymentRecordsList[0].Lead__c];
                if (leadProducts.isEmpty()) {
                    subscriptionResponseWrapperIns.error = 'Please add the lead product first';
                    return subscriptionResponseWrapperIns;
                }
            } else if (!String.isBlank(paymentRecordsList[0].Order__c) && !paymentRecordsList[0].Check_Payment_On_Account__c) {
                orderItems = [SELECT Id, Effective_price__c, Quantity, Is_subscription__c, Plan_handle__c, UnitPrice, ListPrice, TotalPrice, Product_Name__c FROM OrderItem WHERE OrderId = :paymentRecordsList[0].Order__c];
                if (orderItems.isEmpty()) {
                    subscriptionResponseWrapperIns.error = 'Please add the order products first';
                    return subscriptionResponseWrapperIns;
                }
            } else if (!String.isBlank(paymentRecordsList[0].Account__c) && paymentRecordsList[0].Check_Payment_On_Account__c) {//DFJ-80
                paymentItemsOnAccount = [SELECT Id, Effective_price__c, Quantity__c, Is_subscription__c, Plan_handle__c, UnitPrice__c, Name FROM Payment_order_line__c WHERE Payments__c = :paymentRecordsList[0].Id];
                if (paymentItemsOnAccount.isEmpty()) {
                    subscriptionResponseWrapperIns.error = 'Please add the order products first';
                    return subscriptionResponseWrapperIns;
                }
            }

            // Changes for DFJ-273
            // Start
            else if (!String.isBlank(paymentRecordsList[0].Opportunity__c) && !paymentRecordsList[0].Check_Payment_On_Account__c) {
                oppProds = [
                        SELECT Id, Name,
                                Subtotal, Discount, Is_subscription__c, Plan_handle__c, ListPrice, UnitPrice, OpportunityId, Pricebook_Id__c, CurrencyIsoCode, PricebookEntry_Id__c, Product2Id, Quantity,
                                Partner_Provision_Value__c, Partner_Sales_Value__c, Provision_Base__c
                        FROM OpportunityLineItem
                        WHERE OpportunityId = :paymentRecordsList[0].Opportunity__c
                ];

                if (oppProds.isEmpty()) {
                    subscriptionResponseWrapperIns.error = 'Please add the opp products first';
                    return subscriptionResponseWrapperIns;
                }
            }

            // End

            //End
            if (!String.isBlank(paymentRecordsList[0].Lead__c) && !paymentRecordsList[0].Check_Payment_On_Account__c) {
                for (LeadProducts__c leadProductIteration : leadProducts) {
                    if (leadProductIteration.Is_subscription__c) {
                        leadProductsForSubscription.add(leadProductIteration);
                    }
                }
            }//DFJ-80
            if (!String.isBlank(paymentRecordsList[0].Account__c) && paymentRecordsList[0].Check_Payment_On_Account__c) {
                for (Payment_order_line__c paymentProductIteration : paymentItemsOnAccount) {
                    if (paymentProductIteration.Is_Subscription__c) {
                        paymentItemsForSubscription.add(paymentProductIteration);
                    }
                }
            }
            //End
            if (!String.isBlank(paymentRecordsList[0].Order__c) && !paymentRecordsList[0].Check_Payment_On_Account__c) {
                for (OrderItem orderLoop : orderItems) {
                    if (orderLoop.Is_subscription__c) {
                        orderItemForSubscription.add(orderLoop);
                    }
                }
            }

            // Changes for DFJ-273
            // Start
            if (!String.isBlank(paymentRecordsList[0].Opportunity__c) && !paymentRecordsList[0].Check_Payment_On_Account__c) {
                for (OpportunityLineItem oppProd : oppProds) {
                    if (oppProd.Is_subscription__c) {
                        oppProdsForSubscription.add(oppProd);
                    }
                }
            }
            // End

            if (!leadProductsForSubscription.isEmpty()) {
                subscriptionResponseWrapperIns = methodForCreateSubscription(paymentRecordsList, recurringPaymentMethod, leadProductsForSubscription);
            } else if (!orderItemForSubscription.isEmpty()) {
                subscriptionResponseWrapperIns = methodForCreateSubscription(paymentRecordsList, recurringPaymentMethod, orderItemForSubscription);
            } else if (!paymentItemsForSubscription.isEmpty()) {
                subscriptionResponseWrapperIns = methodForCreateSubscription(paymentRecordsList, recurringPaymentMethod, paymentItemsForSubscription);
            }

            // Changes for DFJ-273
            // Start
            else if (!oppProdsForSubscription.isEmpty()) {
                subscriptionResponseWrapperIns = methodForCreateSubscription(paymentRecordsList, recurringPaymentMethod, oppProdsForSubscription);
            }
            // End


            //End


            if (!leadProductsForSubscription.isEmpty() || !orderItemForSubscription.isEmpty() || !paymentItemsForSubscription.isEmpty() || !oppProdsForSubscription.isEmpty()) {
                if (String.isBlank(subscriptionResponseWrapperIns.error)) {
                    PS_PaymentUtility.PS_hosted_page_links hostedpageLink = new PS_PaymentUtility.PS_hosted_page_links();
                    hostedpageLink = subscriptionResponseWrapperIns.hosted_page_links;
                    paymentRecordsList[0].Subscription_link__c = hostedpageLink.payment_info;
                    paymentRecordsList[0].Subscription_status__c = 'Subscription created';
                    paymentRecordsList[0].Subscription_id__c = subscriptionResponseWrapperIns.handle;

                    if (paymentOrderItems.isEmpty()) {
                        subscriptionResponseWrapperIns.error = '';
                        //subscriptionResponseWrapperIns.message = 'Subscription created';
                    }
                } else {
                    paymentRecordsList[0].Subscription_status__c = 'Error in subscription.';
                }
            } else {
                paymentRecordsList[0].Subscription_status__c = 'No subscription included';
            }
            update paymentRecordsList;

            return subscriptionResponseWrapperIns;
        } catch (Exception ex) {
            subscriptionResponseWrapperIns.error = ex.getMessage();
            DFJ_ErrorLogController.addErrorLogs('', 'Creating create Subscription callout', ex.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.createSubscriptionBasedonSavedPaymnetMethod', '', String.valueOf(ex.getLineNumber()));
            return subscriptionResponseWrapperIns;
        }
        //return subscriptionResponseWrapperIns;

    }

    public static PS_PaymentUtility.PS_SubscriptionWrapper methodForCreateSubscription(List<Payments__c> paymentRecord, String recurringPaymentMethod, List<SObject> leadProductsForSubscriptions) {
        PS_PaymentUtility.PS_SubscriptionWrapper responseWrapperIns = new PS_PaymentUtility.PS_SubscriptionWrapper();
        try {

            Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(paymentRecord[0].CurrencyISOCode);
            HttpRequest request = new HttpRequest();

            String endpointUrl = createSubscriptionURL;
            //DFJ-128 Changes Added fields in query to create subscription Record.
            // DFJ-191 Changes Added fields Plan_Version__c, Plan_Amount__c, in query to create subscription Record.
            List<Payments__c> invoicePayment = [
                    SELECT
                            Id, Plan_Version__c, Plan_Amount__c, Order__c, Order__r.Lead__c, Plan_Name__c, OwnerId,
                            Lead__r.ConvertedAccountId, Lead__c, Order__r.AccountId, Billing_email__c,
                            Opportunity__c,
                            Opportunity__r.AccountId
                    FROM Payments__c
                    WHERE Id = :paymentRecord[0].Id
                    LIMIT 1
            ];
            String requestBody = PS_PaymentUtility.constructSubscriptionRequestBody(invoicePayment[0], leadProductsForSubscriptions, recurringPaymentMethod);

            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);
            request.setBody(requestBody);

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200 && !String.isBlank(response.getBody())) {

                responseWrapperIns = (PS_PaymentUtility.PS_SubscriptionWrapper) JSON.deserialize((response.getBody()), PS_PaymentUtility.PS_SubscriptionWrapper.class);
                //DFJ-128 Starts
                try {
                    // DFJ-191 Changes
                    List<Subscriptions__c> getSubscriptionsList = [SELECT Id FROM Subscriptions__c WHERE Subscription_handle__c = :responseWrapperIns.handle LIMIT 1];
                    if (getSubscriptionsList.isEmpty()) {//End
                        Subscriptions__c subRecord = new Subscriptions__c();
                        //subRecord.Payments__c = invoicePayment[0].Id != null ? invoicePayment[0].Id :null;
                        subRecord.OwnerId = invoicePayment[0].OwnerId;
                        subRecord.Account__c = (invoicePayment[0].Lead__r.ConvertedAccountId != null ?
                                invoicePayment[0].Lead__r.ConvertedAccountId :
                                invoicePayment[0].Order__r.AccountId != null ?
                                        invoicePayment[0].Order__r.AccountId :
                                        invoicePayment[0].Opportunity__r.AccountId != null ?
                                                invoicePayment[0].Opportunity__r.AccountId :
                                                null);

                        subRecord.Subscriptions_Status__c =
                                responseWrapperIns.in_trial == true ? 'Trial' : responseWrapperIns.state == 'active' ? 'Active' : responseWrapperIns.state == 'pending' ? 'Pending' : null ;//responseWrapperIns.state;
                        subRecord.Trial_Start_Date__c = responseWrapperIns.trial_start;
                        subRecord.Trial_End_Date__c = responseWrapperIns.trial_end;
                        subRecord.Plan_Name__c = invoicePayment[0].Plan_Name__c;
                        //DFJ-191 Changes
                        subRecord.Plan_Amount__c = invoicePayment[0].Plan_Amount__c != null ? invoicePayment[0].Plan_Amount__c : null;
                        subRecord.Plan_Version__c = invoicePayment[0].Plan_Version__c != null ? invoicePayment[0].Plan_Version__c : null;
                        subRecord.Current_Subscription_Period_Start__c = responseWrapperIns.current_period_start;//DFJ-191 Changes
                        subRecord.Plan_Has_Trial__c = responseWrapperIns.in_trial == true ? true : false;
                        subRecord.Is_First_Invoice__c = responseWrapperIns.in_trial == false ? responseWrapperIns.renewal_count == 1 ? true : false : false;
                        subRecord.Subscription_Created_Date__c = responseWrapperIns.created;
                        // End
                        subRecord.Plan_ID__c = String.valueOf(leadProductsForSubscriptions[0].get('Plan_handle__c'));
                        subRecord.Subscription_handle__c = responseWrapperIns.handle;
                        subRecord.Lead__c = invoicePayment[0].Lead__c != null ? invoicePayment[0].Lead__c : invoicePayment[0].Order__c != null ? invoicePayment[0].Order__r.Lead__c : null;

                        // Changes for DFJ-273
                        // Start
                        subRecord.Opportunity__c = invoicePayment[0].Opportunity__c;
                        // End

                        subRecord.Renewals__c = responseWrapperIns.renewal_count;
                        subRecord.Next_Renewal_Date__c = responseWrapperIns.next_period_start;//DFJ-168 changes
                        subRecord.Total_Subscription_Amount__c = Decimal.valueOf(responseWrapperIns.settled_amount) / 100;//DFJ-168 changes
                        insert subRecord;
                    }

                } catch (exception ex) {
                    DFJ_ErrorLogController.addErrorLogs('', 'Inserting subscription record for ' + paymentRecord[0].Id + ' ', ex.getMessage(), 'Error', 'PS_PaymentService.methodForCreateSubscription', '', String.valueOf(ex.getLineNumber()));
                }
                //End
            }
            //ChnagesDIN-330
            //Start
            else if (response.getStatusCode() == 400 && !String.isBlank(response.getBody())) {
                responseWrapperIns.error = 'Add new Subscription Lead Products';
            }
            //End
            // DFJ_ErrorLogController.addErrorLogs('', 'Creating create Subscription callout', response.getBody(), (response.getStatusCode() == 200 ? 'Info' :'Error'), 'PS_PaymentService.createSubscriptionWithFullDiscount', '', '');
        } catch (Exception ex) {
            responseWrapperIns.error = ex.getMessage();
            DFJ_ErrorLogController.addErrorLogs('', 'Creating create Subscription callout', ex.getMessage(), 'Error', 'PS_PaymentService.createSubscriptionWithFullDiscount', '', String.valueOf(ex.getLineNumber()));
        }
        return responseWrapperIns;

    }
    //DFJ-128 Changes
    //DFJ-168 Changes
    public static Boolean updateRelatedSubscription(String subscription, String event_type) {
        List<Subscriptions__c> getSubscription = new List<Subscriptions__c>();
        List<Order> orderList = new List<Order>();
        List<Payments__c> paymentRecordList = new List<Payments__c>();
        try {

            PS_PaymentUtility.PS_SubscriptionWrapper responseWrapperIns = new PS_PaymentUtility.PS_SubscriptionWrapper();
            String subscriptionCondition = 'Subscription_handle__c =\'' + subscription + '\'';
            getSubscription = fetchSubscriptionByCondition(subscriptionCondition);
            if (getSubscription.isEmpty()) {
                return true;
            }
            //String subscription = getSubscription[0].Subscription_handle__c;
            try {


                String paymentCondition = 'Subscription_id__c =\'' + subscription + '\' ORDER BY CreatedDate DESC' ;
                paymentRecordList = fetchPaymentByCondition(paymentCondition);
                if (paymentRecordList.isEmpty()) {
                    return true;
                }
                Reepay_configuration__mdt reepayConfigurationSetting = Reepay_configuration__mdt.getInstance(paymentRecordList[0].CurrencyIsoCode);
                HttpRequest request = new HttpRequest();
                String endpointUrl = getSubscriptionURL + subscription;
                request.setEndpoint(endpointUrl);
                request.setMethod('GET');
                request.setHeader('Authorization', 'Basic ' + reepayConfigurationSetting.Private_key__c);
                request.setHeader('Accept', 'application/json');
                request.setHeader('Content-Type', 'application/json');
                request.setTimeout(120000);

                Http http = new Http();
                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200 && !String.isBlank(response.getBody())) {
                    responseWrapperIns = (PS_PaymentUtility.PS_SubscriptionWrapper) JSON.deserialize((response.getBody()), PS_PaymentUtility.PS_SubscriptionWrapper.class);
                    if (event_type.equals('subscription_changed')) {
                        DateTime previousTrialEndDate = getSubscription[0].Trial_End_Date__c;
                        // DateTime newTrialExtendedDate = convertStringToDatetime(String.valueOf(responseWrapperIns.trial_end));
                        DateTime newTrialExtendedDate = responseWrapperIns.trial_end;
                        Integer daysDifference = previousTrialEndDate.date().daysBetween(newTrialExtendedDate.date());
                        getSubscription[0].Trial_Extended__c = true;
                        //getSubscription[0].Payments__c = paymentRecordList[0].Id;
                        getSubscription[0].Trial_Extended_Date__c = System.now();
                        getSubscription[0].Trial_End_Date__c = responseWrapperIns.trial_end;
                        getSubscription[0].Trial_Extended_By_Days__c = daysDifference;
                        getSubscription[0].Next_Renewal_Date__c = responseWrapperIns.next_period_start;
                        getSubscription[0].Current_Subscription_Period_Start__c = responseWrapperIns.current_period_start;//DFJ-191 Changes
                        getSubscription[0].Subscriptions_Status__c = responseWrapperIns.in_trial == true ? 'Trial' : responseWrapperIns.state == 'active' ? 'Active' : null ;
                        getSubscription[0].Total_Subscription_Amount__c = Decimal.valueOf(responseWrapperIns.settled_amount) / 100;
                    } else if (event_type.equals('subscription_renewal')) {
                        //DFJ-168 Changes 
                        getSubscription[0].Renewals__c = responseWrapperIns.renewal_count;
                        //End
                        //DFJ-191 Changes
                        getSubscription[0].Current_Subscription_Period_Start__c = responseWrapperIns.current_period_start;//DFJ-191 Changes
                        getSubscription[0].Total_Subscription_Amount__c = Decimal.valueOf(responseWrapperIns.settled_amount) / 100;
                        //End
                        getSubscription[0].Next_Renewal_Date__c = responseWrapperIns.next_period_start;
                        getSubscription[0].Subscriptions_Status__c = responseWrapperIns.in_trial == true ? 'Trial' : responseWrapperIns.state == 'active' ? 'Active' : null ;
                    } else if (event_type.equals('subscription_uncancelled')) {
                        getSubscription[0].Current_Subscription_Period_Start__c = responseWrapperIns.current_period_start;//DFJ-191 Changes
                        getSubscription[0].Uncancellation_Date__c = System.now();
                        getSubscription[0].Subscriptions_Status__c = responseWrapperIns.is_cancelled == true ? 'Cancelled' : responseWrapperIns.in_trial == true ? 'Trial' : responseWrapperIns.state == 'active' ? 'Active' : responseWrapperIns.state == 'expired' ? 'Expired' : responseWrapperIns.state == 'on_hold' ? 'On Hold' : null ;
                        getSubscription[0].Next_Renewal_Date__c = responseWrapperIns.next_period_start;
                    } else if (event_type.equals('subscription_expired')) {
                        getSubscription[0].Subscriptions_Status__c = 'Expired';
                        //DFJ-196 Changes
                        getSubscription[0].Expiration_Date__c = responseWrapperIns.expired_date;
                        //End
                    } else if (event_type.equals('subscription_cancelled')) {
                        getSubscription[0].Subscriptions_Status__c = 'Cancelled';
                        //DFJ-196 Changes
                        getSubscription[0].Cancellation_Date__c = responseWrapperIns.cancelled_date;
                        //End
                        //DFJ-262 Changes
                        getSubscription[0].Expiration_Date__c = responseWrapperIns.next_period_start;
                        //End
                    } else if (event_type.equals('subscription_trial_end')) {
                        getSubscription[0].Subscriptions_Status__c = 'Active' ;
                        getSubscription[0].Current_Subscription_Period_Start__c = responseWrapperIns.current_period_start;//DFJ-191 Changes
                        getSubscription[0].Next_Renewal_Date__c = responseWrapperIns.next_period_start;
                    } else if (event_type.equals('subscription_on_hold')) {
                        getSubscription[0].Subscriptions_Status__c = 'On Hold';
                    } else if (event_type.equals('subscription_reactivated')) {
                        getSubscription[0].Subscriptions_Status__c = 'Active';
                        //DFJ-196
                        // getSubscription[0].Reactivation_Date__c = responseWrapperIns.next_period_start;
                        //End
                    } else if (String.isBlank(event_type)) {
                        getSubscription[0].Total_Subscription_Amount__c = Decimal.valueOf(responseWrapperIns.settled_amount) / 100;
                    }
                    update getSubscription;

                    // return true;
                }
            } catch (Exception ex) {
                DFJ_ErrorLogController.addErrorLogs('', 'Updating subscription record for ' + subscription + ' ', ex.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.updatedSubscription', '', String.valueOf(ex.getLineNumber()));
            }
            return true;
        } catch (exception ex) {
            DFJ_ErrorLogController.addErrorLogs('', 'Updating subscription record for ' + getSubscription[0].Id + ' ', ex.getMessage(), 'Error', 'PS_InvoiceWebhookHelper.updateRelatedSubscription', '', String.valueOf(ex.getLineNumber()));
        }
        return true;
    }

    public static List<Subscriptions__c> fetchSubscriptionByCondition(String subscriptionCondition) {
        List<Subscriptions__c> subscriptionRecordList = new List<Subscriptions__c>();
        List<String> subscriptionFieldList = new List<String>{
                'Id', 'Lead__c', 'On_Hold_Date__c', 'Uncancellation_Date__c', 'Reactivation_Date__c', 'Is_First_Invoice__c', 'Cancellation_Date__c', 'Expiration_Date__c', 'Trial_Extended__c', 'Next_Renewal_Date__c', 'Total_Subscription_Amount__c', 'Subscription_handle__c', 'Trial_Extended_Date__c', 'Trial_End_Date__c', 'Renewals__c', 'Subscriptions_Status__c', 'Trial_Extended_By_Days__c'
        };
        subscriptionRecordList = fetchRecordsDynamically(subscriptionCondition, subscriptionFieldList, 'Subscriptions__c');
        return subscriptionRecordList;
    }


    //End

    /*
* @Description  get OrderItem by subscription handle to lokup for the Order
* @Param        subscriptionId
* @Return       List<OrderItem>
*/
    public static List<OrderItem> getOrderItemFromSubscriptionHandle(String subscriptionHandle) {
        List<OrderItem> orderproduct = new List<OrderItem>();
        String leadCondition = 'Id = \'' + subscriptionHandle + '\'';
        List<String> leadProductFields = new List<String>{
                'Id', 'Partner_provision_value__c', 'Partner_sales_value__c', 'Provision_base__c', 'Discount__c', 'Product2Id', 'PricebookEntryId', 'Effective_price__c', 'Product_Name__c', 'Quantity', 'Order.AccountId', 'Order.Market_Unit__c', 'UnitPrice', 'ListPrice', 'TotalPrice', 'Order.BillingStreet', 'Order.BillingState', 'Order.BillingCity', 'Order.BillingPostalCode', 'Order.Lead__c', 'Order.currencyIsoCode', 'Order.Account.Name', 'Order.Account.PersonEmail', 'Order.Pricebook2Id'
        };
        orderproduct = fetchRecordsDynamically(leadCondition, leadProductFields, 'OrderItem');
        return orderproduct;
    }
    //End

}