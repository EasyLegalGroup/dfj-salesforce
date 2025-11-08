global with sharing class VerificationCodeGenerator {
    @InvocableMethod(label='Generate Verification Code')
    global static List<VerificationResponse> generate(List<String> dummy) {
        List<VerificationResponse> results = new List<VerificationResponse>();
        for (String unused : dummy) {
            VerificationResponse r = new VerificationResponse();
            // 128‑bit random key, Base64‑encoded
            Blob key = Crypto.generateAESKey(128);
            r.AuthenticationKey = EncodingUtil.base64Encode(key);
            
            // 6‑digit OTP (always positive)
            Integer rand = Crypto.getRandomInteger();
            Integer num = Math.mod(Math.abs(rand), 1000000);
            String otp = String.valueOf(num);
            while (otp.length() < 6) {
                otp = '0' + otp;
            }
            r.OTP = otp;
            
            results.add(r);
        }
        return results;
    }

    global class VerificationResponse {
        @InvocableVariable(label='Authentication Key')
        global String AuthenticationKey;
        
        @InvocableVariable(label='One‑Time PIN')
        global String OTP;
    }
}