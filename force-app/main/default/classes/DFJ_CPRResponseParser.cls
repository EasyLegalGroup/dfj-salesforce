public class DFJ_CPRResponseParser {
    public static DFJ_CPRService.CprResponseWrapper parseCprResponse(String xmlResponse) {
        DFJ_CPRService.CprResponseWrapper responseWrapper = new DFJ_CPRService.CprResponseWrapper();
        // Parse the XML string
        try{
            Dom.Document doc = new Dom.Document();
            if(String.isNotBlank(xmlResponse)){
                
            
            doc.load(xmlResponse);
            
            // Navigate to the root node
            Dom.XmlNode rootNode = doc.getRootElement();
            
            // Get the 'CprData' node by traversing down the XML structure
            Dom.XmlNode cprDataNode = rootNode.getChildElement('Gctp', rootNode.getNamespace())
                .getChildElement('System', rootNode.getNamespace())
                .getChildElement('Service', rootNode.getNamespace())
                .getChildElement('CprData', rootNode.getNamespace());
            if(cprDataNode!=null){
                // Get the 'Rolle' node and then the 'Praes' node
                Dom.XmlNode praesNode = cprDataNode.getChildElement('Rolle', rootNode.getNamespace())
                    .getChildElement('Praes', rootNode.getNamespace());
                
                // Get all 'Field' elements from the 'Praes' node
                List<Dom.XmlNode> fieldNodes = praesNode.getChildElements();
                
                // Iterate through all child nodes and check if they are 'Field' elements
                for (Dom.XmlNode field : fieldNodes) {
                    if (field.getName() == 'Field') {
                        String fieldType = field.getAttribute('r', null); 
                        String fieldValue = field.getAttribute('v', null); 
                        String fieldText = field.getAttribute('t', null);  
                        // Map field values to responseWrapper based on fieldType
                        if (fieldType == 'ADRNVN') {
                            responseWrapper.name = fieldText;
                        } else if (fieldType == 'KOEN') {
                            responseWrapper.gender = fieldValue;
                        } else if (fieldType == 'KOMKOD') {
                            responseWrapper.city = fieldText;
                        } else if (fieldType == 'STADR') {
                            responseWrapper.address = fieldValue;
                        } else if (fieldType == 'POSTNR') {
                            responseWrapper.postalCode = fieldValue + ' '+ fieldText;
                        }
                    }
                }
                responseWrapper.statusCode = '200';
            }else{
                responseWrapper.statusCode = 'Wrong CPR Number';
            }
            }
        }catch (Exception ex) {
            responseWrapper.errorMessage = 'Error in Line '+String.valueOf(ex.getLineNumber()) +' ' + ex.getMessage();
            DFJ_ErrorLogController.addErrorLogs('', 'Process DFJ_CPRResponseParser', ex.getMessage(), 'Error', 'DFJ_CPRResponseParser.parseCprResponse', '', String.valueOf(ex.getLineNumber()));
        }
        return responseWrapper;
    }
}