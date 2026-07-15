@IsTest
public class AdditionalChargesControllerTest {

    // Helper method: creates Booking__c with required Finance User
    private static Booking__c createBookingWithFinanceUser() {
        User financeUser = new User(
            Username = 'finance_' + System.currentTimeMillis() + '@test.com',
            LastName = 'Finance',
            Email = 'finance@test.com',
            Alias = 'finu',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert financeUser;

        Booking__c booking = new Booking__c(
            Finance_User__c = financeUser.Id
        );
        insert booking;
        return booking;
    }

    @IsTest
    static void test_MainFlow_WithValue() {
        Booking__c booking = createBookingWithFinanceUser();

        Additional_Charges__c addCharge = new Additional_Charges__c(
            Booking__c = booking.Id
        );
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);

        Test.startTest();
        AdditionalChargesController controller = new AdditionalChargesController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller.totalcharge, 'totalcharge should be set');
    }

    @IsTest
    static void test_NullTotalCharge() {
        Booking__c booking = createBookingWithFinanceUser();

        Additional_Charges__c addCharge = new Additional_Charges__c(
            Booking__c = booking.Id
        );
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        System.assertNotEquals(null, controller.additionChargeId, 'Id should be set');
    }

    @IsTest
    static void test_getFormattedDate_1stSuffix() {
        Booking__c booking = createBookingWithFinanceUser();

        Additional_Charges__c addCharge = new Additional_Charges__c(
            Booking__c = booking.Id
        );
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        Test.startTest();
        String result = controller.getFormattedDate(Date.newInstance(2025, 1, 1));
        Test.stopTest();

        System.assert(result.contains('st'), 'Day 1 should have "st" suffix');
        System.assert(result.contains('January'), 'Should contain January');
    }

    @IsTest
    static void test_getFormattedDate_2ndSuffix() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        String result = controller.getFormattedDate(Date.newInstance(2025, 2, 2));
        System.assert(result.contains('nd'), 'Day 2 should have "nd" suffix');
        System.assert(result.contains('February'), 'Should contain February');
    }

    @IsTest
    static void test_getFormattedDate_3rdSuffix() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        String result = controller.getFormattedDate(Date.newInstance(2025, 3, 3));
        System.assert(result.contains('rd'), 'Day 3 should have "rd" suffix');
    }

    @IsTest
    static void test_getFormattedDate_thSuffix() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        // Day 15 uses default 'th' suffix
        String result = controller.getFormattedDate(Date.newInstance(2025, 10, 15));
        System.assert(result.contains('th'), 'Day 15 should have "th" suffix');
        System.assert(result.contains('October'), 'Should contain October');
    }

    @IsTest
    static void test_getFormattedDate_21stSuffix() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        String result = controller.getFormattedDate(Date.newInstance(2025, 6, 21));
        System.assert(result.contains('st'), 'Day 21 should have "st" suffix');
    }

    @IsTest
    static void test_getFormattedDate_22ndSuffix() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        String result = controller.getFormattedDate(Date.newInstance(2025, 7, 22));
        System.assert(result.contains('nd'), 'Day 22 should have "nd" suffix');
    }

    @IsTest
    static void test_getFormattedDate_23rdSuffix() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        String result = controller.getFormattedDate(Date.newInstance(2025, 8, 23));
        System.assert(result.contains('rd'), 'Day 23 should have "rd" suffix');
    }

    @IsTest
    static void test_getFormattedDate_31stSuffix() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        String result = controller.getFormattedDate(Date.newInstance(2025, 12, 31));
        System.assert(result.contains('st'), 'Day 31 should have "st" suffix');
    }

    @IsTest
    static void test_convertYearToWords_Year2020() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        // Year 2020: firstPart==20, lastPart==20 (>= 20)
        String result = controller.getFormattedDate(Date.newInstance(2020, 6, 10));
        System.assert(result.contains('twenty'), 'Year 2020 should contain "twenty"');
    }

    @IsTest
    static void test_convertYearToWords_Year2021() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        // Year 2021: firstPart==20, lastPart==21 (>= 20, units[1]='one')
        String result = controller.getFormattedDate(Date.newInstance(2021, 6, 10));
        System.assertNotEquals(null, result, 'Should format year 2021');
    }

    @IsTest
    static void test_convertYearToWords_Year2022() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        // Year 2022: firstPart==22
        String result = controller.getFormattedDate(Date.newInstance(2022, 6, 10));
        System.assertNotEquals(null, result, 'Should format year 2022');
    }

    @IsTest
    static void test_convertYearToWords_TeenYear() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        // Year 2015: lastPart==15 (teens range 10-19)
        String result = controller.getFormattedDate(Date.newInstance(2015, 6, 10));
        System.assert(result.contains('fifteen'), 'Year 2015 should contain "fifteen"');
    }

    @IsTest
    static void test_convertYearToWords_Year2100() {
        Booking__c booking = createBookingWithFinanceUser();
        Additional_Charges__c addCharge = new Additional_Charges__c(Booking__c = booking.Id);
        insert addCharge;

        ApexPages.StandardController sc = new ApexPages.StandardController(addCharge);
        AdditionalChargesController controller = new AdditionalChargesController(sc);

        // Year 2100: firstPart==21, lastPart==00
        String result = controller.getFormattedDate(Date.newInstance(2100, 1, 1));
        System.assertNotEquals(null, result, 'Should format year 2100');
    }
}