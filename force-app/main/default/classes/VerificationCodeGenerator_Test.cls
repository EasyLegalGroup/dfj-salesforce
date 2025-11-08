@isTest
private class VerificationCodeGenerator_Test {
    @isTest static void testGenerateVerificationCode() {
        // Invoke with one dummy input to get one response
        List<String> dummyInput = new List<String>{'x'};
        
        Test.startTest();
        List<VerificationCodeGenerator.VerificationResponse> responses =
            VerificationCodeGenerator.generate(dummyInput);
        Test.stopTest();
        
        // One response returned
        System.assertEquals(1, responses.size());
        VerificationCodeGenerator.VerificationResponse resp = responses[0];
        
        // Auth key non-null, decodes to 16 bytes
        System.assertNotEquals(null, resp.AuthenticationKey);
        Blob decoded = EncodingUtil.base64Decode(resp.AuthenticationKey);
        System.assertEquals(16, decoded.size());
        
        // OTP is 6 digits, numeric, and non-negative
        System.assertNotEquals(null, resp.OTP);
        System.assertEquals(6, resp.OTP.length());
        for (Integer i = 0; i < 6; i++) {
            String ch = resp.OTP.substring(i, i+1);
            System.assert(ch >= '0' && ch <= '9');
        }
    }
}