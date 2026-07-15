@isTest
private class NumberTOWordConvertionTest {
    static testMethod void testZero() {
        NumberTOWordConvertion obj = new NumberTOWordConvertion();
        String result = obj.getNumberTOWordConvertion(0.00);
        System.assertEquals('Zero Only', result);
    }

    static testMethod void testWholeRupeesOnly() {
        NumberTOWordConvertion obj = new NumberTOWordConvertion();
        String result = obj.getNumberTOWordConvertion(12345.00);
        System.assert(result.contains('Twelve Thousand Three Hundred Forty Five'));
        System.assert(!result.contains('Paise'));
        System.assert(result.endsWith('Only'));
    }

    static testMethod void testRupeesAndPaise() {
        NumberTOWordConvertion obj = new NumberTOWordConvertion();
        String result = obj.getNumberTOWordConvertion(98765.43);
        System.assert(result.contains('Ninety Eight Thousand Seven Hundred Sixty Five'));
        System.assert(result.contains('Forty Three Paise'));
        System.assert(result.endsWith('Only'));
    }

    static testMethod void testSmallNumbers() {
        NumberTOWordConvertion obj = new NumberTOWordConvertion();
        System.assertEquals('One Only', obj.getNumberTOWordConvertion(1.00));
        System.assertEquals('Nineteen Only', obj.getNumberTOWordConvertion(19.00));
        System.assertEquals('Twenty One Only', obj.getNumberTOWordConvertion(21.00));
    }

}