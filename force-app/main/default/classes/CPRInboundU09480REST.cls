@RestResource(urlMapping='/cpr/inbound/u09480')
global with sharing class CPRInboundU09480REST {
    global class Req {
        public Id contentVersionId;
        public Date fileDate;
        public Id fileRunId; // optional (for re-runs)
    }
    global class Res {
        public Id fileRunId;
        public Integer eventsCreated;
        public String message;
    }

    @HttpPost
    global static Res post() {
        RestRequest req = RestContext.request;
        Req inReq = (Req) JSON.deserialize(req.requestBody.toString(), Req.class);

        CPRIngestInvocable.Request inv = new CPRIngestInvocable.Request();
        inv.contentVersionId = inReq.contentVersionId;
        inv.fileDate         = inReq.fileDate;
        inv.fileRunId        = inReq.fileRunId;

        List<CPRIngestInvocable.Response> r =
            CPRIngestInvocable.run(new List<CPRIngestInvocable.Request>{ inv });

        Res out = new Res();
        if (!r.isEmpty()) {
            out.fileRunId      = r[0].fileRunId;
            out.eventsCreated  = r[0].eventsCreated;
            out.message        = r[0].message;
        } else {
            out.message = 'No response';
        }
        return out;
    }
}