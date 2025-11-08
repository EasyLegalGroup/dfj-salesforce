@IsTest
private class McPhone_Test {

    @IsTest
    static void test_dk_normalizer_happy_paths() {
        McPhone.Norm a = McPhone.normalizeDK('+4542455150');
        System.assertEquals('4542455150', a.digits);
        System.assertEquals(true, a.dkOk);
        System.assertEquals(null, a.warning);

        McPhone.Norm b = McPhone.normalizeDK('004542455150');
        System.assertEquals('4542455150', b.digits);
        System.assertEquals(true, b.dkOk);
        System.assertEquals(null, b.warning);

        McPhone.Norm c = McPhone.normalizeDK('42455150');
        System.assertEquals('4542455150', c.digits);
        System.assertEquals(true, c.dkOk);
        System.assertEquals(null, c.warning);

        McPhone.Norm d = McPhone.normalizeDK('(+45) 42-45-51-50');
        System.assertEquals('4542455150', d.digits);
        System.assertEquals(true, d.dkOk);
        System.assertEquals(null, d.warning);
    }

    @IsTest
    static void test_dk_normalizer_unhappy_paths() {
        McPhone.Norm shorty = McPhone.normalizeDK('123');
        System.assertEquals('123', shorty.digits);
        System.assertEquals(false, shorty.dkOk);
        System.assertNotEquals(null, shorty.warning);

        McPhone.Norm blank = McPhone.normalizeDK(null);
        System.assertEquals(null, blank.digits);
        System.assertEquals(false, blank.dkOk);
        System.assertEquals('Blank input', blank.warning);

        McPhone.Norm nodigits = McPhone.normalizeDK('(+xx) abc');
        System.assertEquals(null, nodigits.digits);
        System.assertEquals(false, nodigits.dkOk);
        System.assertEquals('No digits found', nodigits.warning);
    }

    @IsTest
    static void test_generic_normalize_non_dk() {
        McPhone.Norm fr = McPhone.normalize(' +33 (0)6 12 34 56 78 ', 'FR');
        System.assertEquals('330612345678', fr.digits);
        System.assertEquals(true, fr.dkOk);
        System.assertEquals('FR', fr.country);
        System.assertEquals(null, fr.warning);

        McPhone.Norm blank = McPhone.normalize('', 'SE');
        System.assertEquals(null, blank.digits);
        System.assertEquals(false, blank.dkOk);
        System.assertEquals('Blank input', blank.warning);
    }

    @IsTest
    static void test_se_normalizer_paths() {
        // +46… -> digits only 46…
        McPhone.Norm a = McPhone.normalizeSE('+46701234567');
        System.assertEquals('46701234567', a.digits);
        System.assertEquals(true, a.dkOk);
        System.assertEquals('SE', a.country);

        // 0046… -> 46…
        McPhone.Norm b = McPhone.normalizeSE('0046701234567');
        System.assertEquals('46701234567', b.digits);
        System.assertEquals(true, b.dkOk);

        // local 070… -> 46 + drop leading 0
        McPhone.Norm c = McPhone.normalizeSE('0701234567');
        System.assertEquals('46701234567', c.digits);
        System.assertEquals(true, c.dkOk);

        // messy formatting
        McPhone.Norm d = McPhone.normalize(' (0)70-123 45 67 ', 'SE');
        System.assertEquals('46701234567', d.digits);
        System.assertEquals(true, d.dkOk);
    }

    @IsTest
    static void test_ie_normalizer_paths() {
        // +353… -> digits only 353…
        McPhone.Norm a = McPhone.normalizeIE('+353871234567');
        System.assertEquals('353871234567', a.digits);
        System.assertEquals(true, a.dkOk);
        System.assertEquals('IE', a.country);

        // 00353… -> 353…
        McPhone.Norm b = McPhone.normalizeIE('00353871234567');
        System.assertEquals('353871234567', b.digits);
        System.assertEquals(true, b.dkOk);

        // local 087… -> 353 + drop leading 0
        McPhone.Norm c = McPhone.normalizeIE('0871234567');
        System.assertEquals('353871234567', c.digits);
        System.assertEquals(true, c.dkOk);

        // messy formatting
        McPhone.Norm d = McPhone.normalize(' (+353) 87-123 45 67 ', 'IE');
        System.assertEquals('353871234567', d.digits);
        System.assertEquals(true, d.dkOk);

        // short number should fail
        McPhone.Norm e = McPhone.normalizeIE('353123');
        System.assertEquals('353123', e.digits);
        System.assertEquals(false, e.dkOk);
        System.assertNotEquals(null, e.warning);
    }
}