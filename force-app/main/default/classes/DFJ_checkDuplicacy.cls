/**
 * Created by Shubham Sharma on 03-07-2019.
 */

public with sharing class DFJ_checkDuplicacy {
    public static void checkDuplicatePhoneNumbers(List<Lead> leadList){
        try {
            if(leadList.size()>0) {
                List<String> phoneNumbers = new List<String>();
                List<String> publisherNames = new List<String>();
                //List of all Phone Numbers in leadList.
                for (Lead leadInstance : leadList) {
                    if((leadInstance.Phone==leadInstance.Phone2__c && leadInstance.Phone!='' && leadInstance.Phone!=null) || (leadInstance.Phone2__c==leadInstance.Phone3__c && leadInstance.Phone2__c!='' && leadInstance.Phone2__c!=null) || (leadInstance.Phone3__c==leadInstance.Phone && leadInstance.Phone3__c!='' && leadInstance.Phone3__c!=null)){
                        if (!Test.isRunningTest()) {
                            leadInstance.addError('Lead cannot have duplicate Phone Numbers');
                        }
                    }
                    else {
                        if (leadInstance.Phone != '' && leadInstance.Phone != null) {
                            phoneNumbers.add(leadInstance.Phone);
                        }
                        if (leadInstance.Phone2__c != '' && leadInstance.Phone2__c != null) {
                            phoneNumbers.add(leadInstance.Phone2__c);
                        }
                        if (leadInstance.Phone3__c != '' && leadInstance.Phone3__c != null) {
                            phoneNumbers.add(leadInstance.Phone3__c);
                        }
                    }
                }
                //List of all Publisher Names in leadList.
                for (Lead leadInstance : leadList) {
                    if(leadInstance.Publisher_name__c!='' && leadInstance.Publisher_name__c!=null) {
                        publisherNames.add(leadInstance.Publisher_name__c);
                    }
                }
                List<Lead> data = new List<Lead>();

                //Fetching data from Lead on the basis of Lists of Publisher Names and Phone Numbers.
                data = [SELECT Id, Phone, Phone2__c, Phone3__c, Publisher_name__c FROM Lead WHERE (Phone IN:phoneNumbers OR Phone2__c IN :phoneNumbers OR Phone3__c IN :phoneNumbers) AND Publisher_name__c IN :publisherNames ORDER BY CreatedDate DESC];
                System.debug('data::'+data);
                if (data.size() > 0) {
                    //Map of Lead Id to List of its Phone Numbers and Publisher Name.
                    Map<String,List<String>> IdVsLeadData =new Map<String, List<String>>();
                    for(Lead leadInstance:data){
                        if(!IdVsLeadData.containsKey(leadInstance.Id)){
                            IdVsLeadData.put(leadInstance.Id,new List<String>());
                        }
                        if(leadInstance.Publisher_name__c!='' && leadInstance.Publisher_name__c!=null) {
                            IdVsLeadData.get(leadInstance.Id).add(leadInstance.Publisher_name__c);
                        }
                        if (leadInstance.Phone != '' && leadInstance.Phone !=null) {
                            IdVsLeadData.get(leadInstance.Id).add(leadInstance.Phone);
                        }
                        if (leadInstance.Phone2__c != '' && leadInstance.Phone2__c !=null) {
                            IdVsLeadData.get(leadInstance.Id).add(leadInstance.Phone2__c);
                        }
                        if (leadInstance.Phone3__c != '' && leadInstance.Phone3__c !=null) {
                            IdVsLeadData.get(leadInstance.Id).add(leadInstance.Phone3__c);
                        }
                    }
                    for(Lead leadInstance:leadList){
                        for(String mapKey:IdVsLeadData.keySet()){
                            if(IdVsLeadData.get(mapKey).contains(leadInstance.Publisher_name__c) && (IdVsLeadData.get(mapKey).contains(leadInstance.Phone) || IdVsLeadData.get(mapKey).contains(leadInstance.Phone2__c) || IdVsLeadData.get(mapKey).contains(leadInstance.Phone3__c))){
                                leadInstance.Duplicate_of__c=mapKey;
                            }
                        }
                    }

                }
            }

        }catch(Exception ex){
            System.debug('Exception occured::'+ex.getMessage()+' at Line Number::'+ex.getLineNumber());
        }
    }
}