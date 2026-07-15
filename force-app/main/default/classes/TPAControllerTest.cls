@isTest
public class TPAControllerTest {

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Apartments'
        );
        insert project;

        Plot__c plot = new Plot__c(
            Name = 'Test Unit',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = 'Apartments'
        );
        insert plot;

        // Booking with TPA date and loan amount (writable fields only)
        // Total__c, Pending_Amount__c, Total_received_Amount__c, Amount_By_Customer__c are formula/rollup fields
        Booking__c booking = new Booking__c(
            Loan_Sanctioned_Amount__c = 3000000,
            TPA_Agreement_Date__c = Date.newInstance(2025, 3, 15)
        );
        insert booking;

        // Booking without optional fields
        Booking__c bookingNoDate = new Booking__c();
        insert bookingNoDate;
    }

    @isTest
    static void testConstructorWithAllFields() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE TPA_Agreement_Date__c != null LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);

        Test.startTest();
        TPAController controller = new TPAController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller.loanAmout, 'Loan amount in words should be set');
        System.assertNotEquals(null, controller.TPA_Agreement_Date, 'TPA date should be formatted');
        System.assertNotEquals(null, controller.duedate, 'Due date should be set');
    }

    @isTest
    static void testConstructorWithoutOptionalFields() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE TPA_Agreement_Date__c = null LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);

        Test.startTest();
        TPAController controller = new TPAController(sc);
        Test.stopTest();

        System.assertEquals(null, controller.TPA_Agreement_Date, 'TPA date should be null when not set');
        System.assertEquals(null, controller.loanAmout, 'Loan amount should be null when not set');
    }

    @isTest
    static void testFormatDate() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE TPA_Agreement_Date__c != null LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        TPAController controller = new TPAController(sc);

        Test.startTest();
        String result1 = controller.formatDate(Date.newInstance(2025, 1, 1));
        System.assert(result1.contains('1st'), 'Day 1 should have st suffix: ' + result1);
        System.assert(result1.contains('January'), 'Month should be January: ' + result1);

        String result2 = controller.formatDate(Date.newInstance(2025, 2, 2));
        System.assert(result2.contains('2nd'), 'Day 2 should have nd suffix: ' + result2);

        String result3 = controller.formatDate(Date.newInstance(2025, 3, 3));
        System.assert(result3.contains('3rd'), 'Day 3 should have rd suffix: ' + result3);

        String result4 = controller.formatDate(Date.newInstance(2025, 4, 4));
        System.assert(result4.contains('4th'), 'Day 4 should have th suffix: ' + result4);

        String result21 = controller.formatDate(Date.newInstance(2025, 5, 21));
        System.assert(result21.contains('21st'), 'Day 21 should have st suffix: ' + result21);

        String result31 = controller.formatDate(Date.newInstance(2025, 12, 31));
        System.assert(result31.contains('31st'), 'Day 31 should have st suffix: ' + result31);
        Test.stopTest();
    }

    @isTest
    static void testConvertYearToWords() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE TPA_Agreement_Date__c != null LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        TPAController controller = new TPAController(sc);

        Test.startTest();
        String result2025 = controller.convertYearToWords(2025);
        System.assert(result2025.contains('thousand'), 'Should contain thousand: ' + result2025);

        String result2000 = controller.convertYearToWords(2000);
        System.assertNotEquals(null, result2000, 'Should handle year 2000');

        String resultNull = controller.convertYearToWords(null);
        System.assertEquals('', resultNull, 'Null year should return empty string');
        Test.stopTest();
    }

    @isTest
    static void testGetFormattedDate() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE TPA_Agreement_Date__c != null LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        TPAController controller = new TPAController(sc);

        Test.startTest();
        String result = controller.getFormattedDate(Date.newInstance(2025, 6, 15));
        Test.stopTest();

        System.assertNotEquals(null, result, 'Formatted date should not be null');
        System.assert(result.contains('June'), 'Should contain month name');
    }
}