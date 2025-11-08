public without sharing class AgentReport_Controller {
    @AuraEnabled
    public static List<reportWrapper> fetchReportData_Apex(String DurationRange,Date StartDate , Date EndDate) {
        try {
            System.debug('DurationRange---' + DurationRange);

            String DurationQuery = '';
            if (DurationRange == 'Today' && DurationRange != null) {
                DurationQuery = ' AND CreatedDate = TODAY LIMIT 50000';
            } else if (DurationRange == 'Yesterday' && DurationRange != null) {
                DurationQuery = ' AND CreatedDate = YESTERDAY LIMIT 50000';
            } else if (DurationRange == 'Last 7 Days' +
                    '' +
                    '' && DurationRange != null) {
                DurationQuery = ' AND CreatedDate >= N_DAYS_AGO:7 LIMIT 50000';
            } else if (DurationRange == 'Last 30 Days' && DurationRange != null) {
                DurationQuery = ' AND CreatedDate >= N_DAYS_AGO:30 LIMIT 50000';
            } else if (DurationRange == 'THIS WEEK' && DurationRange != null) {
                DurationQuery = ' AND CreatedDate = THIS_WEEK LIMIT 50000';
            } else if (DurationRange == 'LAST WEEK' && DurationRange != null) {
                DurationQuery = ' AND CreatedDate = LAST_WEEK LIMIT 50000';
            } else if (DurationRange == 'THIS MONTH' && DurationRange != null) {
                DurationQuery = ' AND CreatedDate = THIS_MONTH LIMIT 50000';
            } else if (DurationRange == 'LAST MONTH' && DurationRange != null) {
                DurationQuery = ' AND CreatedDate = LAST_MONTH LIMIT 50000';
            } else if (StartDate != null && EndDate != null) {
                DurationQuery = ' AND ( CreatedDate >=: StartDate AND CreatedDate <=: EndDate ) LIMIT 50000';
            }
            if (DurationQuery != null && DurationQuery != '') {

                List<Profile> profilesList = new List<Profile>();
                profilesList = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' OR Name = 'Standard User' OR Name = 'Systemadministrator' OR Name = 'Standardbruger'];
                System.debug('profilesList---' + profilesList);

                Set<Id> ProfileIdSet = new Set<Id>();
                for (Profile proId : profilesList) {
                    ProfileIdSet.add(proId.Id);
                }

                List<User> usersList = new List<User>();
                usersList = [SELECT Id, Name FROM User WHERE IsActive = true AND ProfileId IN : ProfileIdSet LIMIT 1000];
                System.debug('usersList---' + usersList);

                Map<Id, reportWrapper> reportMap = new Map<Id, reportWrapper>();

                Set<Id> UsersIdSet = new Set<Id>();
                for (User userLoop : usersList) {
                    System.debug('userLoop---' + userLoop);
                    UsersIdSet.add(userLoop.Id);
                    if (!reportMap.containsKey(userLoop.Id)) {
                        reportMap.put(userLoop.Id, new reportWrapper());
                    }
                }

                List<reportWrapper> reportWrappersList = new List<reportWrapper>();
                reportWrapper reportWrapperInstance = new reportWrapper();

                List<telegenta__Telegenta_Call_History__c> callHistories =
                        new List<telegenta__Telegenta_Call_History__c>();
                String callHistoryQuery =
                        'SELECT Id,telegenta__Active_Duration__c,telegenta__Total_Duration__c,telegenta__Disposition__c,CreatedDate,OwnerId FROM telegenta__Telegenta_Call_History__c WHERE OwnerId In : UsersIdSet '+ DurationQuery;
                System.debug('callHistoryQuery---' + callHistoryQuery);
                callHistories = Database.query(callHistoryQuery);
                System.debug('callHistories---' + callHistories);

                for (telegenta__Telegenta_Call_History__c call_historyLoop : callHistories) {
                    reportWrapperInstance = reportMap.get(call_historyLoop.OwnerId);
                    System.debug('call_historyLoop.telegenta__Disposition__c---'+call_historyLoop.telegenta__Disposition__c);
                    if (call_historyLoop.telegenta__Disposition__c != 'VOICEMAIL' && call_historyLoop.telegenta__Disposition__c != 'NO ANSWER' && call_historyLoop.telegenta__Disposition__c != 'NO_ANSWER') {
                        reportWrapperInstance.EffectiveCalls = reportWrapperInstance.EffectiveCalls + 1;
                        if (call_historyLoop.telegenta__Active_Duration__c != null) {
                            reportWrapperInstance.EffectiveTalkTime = reportWrapperInstance.EffectiveTalkTime + call_historyLoop.telegenta__Active_Duration__c;
                        }
                    }
                        reportWrapperInstance.Calls = reportWrapperInstance.Calls + 1;
                        if (call_historyLoop.telegenta__Active_Duration__c != null) {
                            reportWrapperInstance.TalkTime = reportWrapperInstance.TalkTime + call_historyLoop.telegenta__Active_Duration__c;
                        }
                    reportMap.put(call_historyLoop.OwnerId, reportWrapperInstance);
                }

                List<LeadHistory> leadHistories = new List<LeadHistory>();
                String fieldHistoryQuery =
                        'SELECT Id,Field,LeadId,OldValue,NewValue,CreatedById,CreatedDate FROM LeadHistory WHERE Field = \'' +
                        'telegenta__Last_Contact_State__c' + '\' AND CreatedById  IN : UsersIdSet ' + DurationQuery;
                leadHistories = Database.query(fieldHistoryQuery);
                for (LeadHistory leadHistoryLoop : leadHistories) {
                    reportWrapperInstance = reportMap.get(leadHistoryLoop.CreatedById);
                    if (leadHistoryLoop.NewValue == 'Not Interested') {
                        reportWrapperInstance.Reject = reportWrapperInstance.Reject + 1;
                    } else if (leadHistoryLoop.NewValue == 'Got appointment') {
                        reportWrapperInstance.Appointment = reportWrapperInstance.Appointment + 1;
                    } else if (leadHistoryLoop.NewValue == 'Unqualified') {
                        reportWrapperInstance.Invalid = reportWrapperInstance.Invalid + 1;
                    }
                    reportMap.put(leadHistoryLoop.CreatedById, reportWrapperInstance);
                }

                List<Account> accountsList = new List<Account>();
                //String accountQuery = 'SELECT Id,Name,Sales_value__c,OwnerId FROM Account WHERE IsPersonAccount = true AND OwnerId IN : UsersIdSet '+ DurationQuery;
                String accountQuery =
                        'SELECT Id,Name,Sales_value__c,OwnerId FROM Account WHERE OwnerId IN : UsersIdSet ' +
                        DurationQuery;
                accountsList = Database.query(accountQuery);

                for (Account accLoop : accountsList) {
                    reportWrapperInstance = reportMap.get(accLoop.OwnerId);
                    reportWrapperInstance.Converted = reportWrapperInstance.Converted + 1;
                    if (accLoop.Sales_value__c != null) {
                        reportWrapperInstance.salesValue = reportWrapperInstance.salesValue + accLoop.Sales_value__c;
                    }
                    reportMap.put(accLoop.OwnerId, reportWrapperInstance);
                }

                /*List<Order> orders = new List<Order>();
                String orderQueryString = 'SELECT Id,Name,Order_Price__c,OwnerId FROM Order WHERE OwnerId IN : UsersIdSet ' + DurationQuery;
                orders = Database.query(orderQueryString);
                for (Order forOrder : orders) {
                    reportWrapperInstance = reportMap.get(forOrder.OwnerId);
                    if (forOrder.Order_Price__c != null) {
                        //reportWrapperInstance.salesValue = reportWrapperInstance.salesValue + forOrder.Order_Price__c;
                    }
                    reportMap.put(forOrder.OwnerId, reportWrapperInstance);
                }*/

                reportWrapper totalValuesInstance = new reportWrapper(); // To get the total for the report
                totalValuesInstance.UserName = 'Total';

                for (User userLoop : usersList) {
                    totalValuesInstance.TalkTime = totalValuesInstance.TalkTime + reportMap.get(userLoop.Id).TalkTime;
                    totalValuesInstance.Calls = totalValuesInstance.Calls + reportMap.get(userLoop.Id).Calls;
                    totalValuesInstance.EffectiveCalls = totalValuesInstance.EffectiveCalls + reportMap.get(userLoop.Id).EffectiveCalls;
                    totalValuesInstance.EffectiveTalkTime = totalValuesInstance.EffectiveTalkTime + reportMap.get(userLoop.Id).EffectiveTalkTime;
                    totalValuesInstance.Appointment = totalValuesInstance.Appointment + reportMap.get(userLoop.Id).Appointment;
                    totalValuesInstance.Reject = totalValuesInstance.Reject + reportMap.get(userLoop.Id).Reject;
                    totalValuesInstance.Invalid = totalValuesInstance.Invalid + reportMap.get(userLoop.Id).Invalid;
                    totalValuesInstance.Converted = totalValuesInstance.Converted + reportMap.get(userLoop.Id).Converted;
                    totalValuesInstance.salesValue = totalValuesInstance.salesValue + reportMap.get(userLoop.Id).salesValue;

                    reportWrapperInstance = reportMap.get(userLoop.Id);
                    reportWrapperInstance.UserName = userLoop.Name;
                    reportWrapperInstance.UserId = userLoop.Id;
                    reportWrappersList.add(reportMap.get(userLoop.Id));
                }
                reportWrappersList.add(totalValuesInstance);

                System.debug('reportWrappersList----' + JSON.serialize(reportWrappersList));

                return reportWrappersList;
            }
            else{
                return null;
            }
        }catch (Exception ex) {
            throw new AuraHandledException('Error Line number :: '+ex.getLineNumber()+' Error Message :: '+ex.getMessage());
        }
    }


    public class reportWrapper {
        @AuraEnabled public String UserId;
        @AuraEnabled public String UserName;
        @AuraEnabled public Integer Calls;
        @AuraEnabled public Decimal TalkTime;
        @AuraEnabled public Integer EffectiveCalls;
        @AuraEnabled public Decimal EffectiveTalkTime;
        @AuraEnabled public Integer Appointment;
        @AuraEnabled public Integer Reject;
        @AuraEnabled public Integer Invalid;
        @AuraEnabled public Integer Converted;
        @AuraEnabled public Decimal salesValue;

        public reportWrapper() {
            this.Calls = 0;
            this.TalkTime = 0;
            this.Appointment = 0;
            this.EffectiveCalls = 0;
            this.EffectiveTalkTime = 0;
            this.Reject = 0;
            this.Invalid = 0;
            this.Converted = 0;
            this.salesValue = 0;
        }
    }
}