public with sharing class McSmsStatusTools {

    public class PollInput {
        @InvocableVariable(required=true) public String messageKey;
    }
    public class PollOutput {
        @InvocableVariable public String messageKey;
        @InvocableVariable public Integer httpStatus;
        @InvocableVariable public String eventCategoryType;
        @InvocableVariable public String statusCode;       // as string for Flow mapping
        @InvocableVariable public String statusMessage;
        @InvocableVariable public String infoTo;           // what MC reports we sent to
        @InvocableVariable public String timestamp;
        @InvocableVariable public String codeName;         // e.g., 46 -> MessageRenderFailure
    }

    /** Minimal mapping for common codes (extend as needed). */
    public static final Map<String,String> COMMON_CODES = new Map<String,String>{
        '46' => 'MessageRenderFailure'
    };

    @InvocableMethod(label='Poll SMS Status (SFMC Transactional API)')
    public static List<PollOutput> poll(List<PollInput> inputs) {
        List<PollOutput> out = new List<PollOutput>();
        if (inputs == null || inputs.isEmpty()) return out;

        Integer MAX = 90; // headroom under 100 callouts

        Integer n = Math.min(inputs.size(), MAX);
        for (Integer i = 0; i < n; i++) {
            PollInput pi = inputs[i];
            PollOutput po = new PollOutput();
            po.messageKey = (pi == null ? null : pi.messageKey);

            try {
                McRestClient.Result r = McRestClient.getMessage(pi.messageKey);
                po.httpStatus = r.status;

                if (r.status == 200 && String.isNotBlank(r.body)) {
                    Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r.body);
                    po.eventCategoryType = (String) m.get('eventCategoryType');
                    po.timestamp         = (String) m.get('timestamp');

                    Object sc = m.get('statusCode');
                    if (sc != null) po.statusCode = String.valueOf(sc);
                    po.statusMessage = (String) m.get('statusMessage');

                    Map<String, Object> info = (Map<String, Object>) m.get('info');
                    if (info != null) {
                        Object to = info.get('to');
                        if (to != null) po.infoTo = String.valueOf(to);
                    }

                    if (po.statusCode != null && COMMON_CODES.containsKey(po.statusCode)) {
                        po.codeName = COMMON_CODES.get(po.statusCode);
                    }
                }
            } catch (Exception ex) {
                po.httpStatus = null;
                po.statusMessage = ex.getTypeName() + ': ' + ex.getMessage();
            }

            out.add(po);
        }
        return out;
    }
}