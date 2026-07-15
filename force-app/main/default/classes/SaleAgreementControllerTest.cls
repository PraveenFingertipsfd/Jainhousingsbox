@isTest
public class SaleAgreementControllerTest {
    @testSetup
    static void setupData() {
        // Create Project with required Project_Type__c
        Project__c project = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments'

        );
        insert project;

        // Create Block with Project lookup
        Block__c block = new Block__c(
            Name = 'A',
            Project__c = project.Id
        );
        insert block;

        // Create Plot/Unit with exact matching Project_Type__c
        Plot__c unit = new Plot__c(
            Name = '101',
            Status__c = 'Available',
            Project__c = project.Id,               // Master-detail lookup to Project
            Project_Type__c = project.Project_Type__c, // Must match Project
            Block__c ='A2 ',                   // Lookup to Block
            Plot_Type__c = 'Residential',
            Carpet_Area__c = 850,
            Balcony_Sq_mts__c = 20,
            Balcony_Area__c = 100,
            BHK_Type__c = '3 BHK + 2T',
            Premium_Status__c = 'Premium',
            Floor__c = '1',
            Share__c = 'MHPL',
            Facing__c = 'EAST',
            Carpet_Sq_mts__c = 80,
            CA__c = 75,
            Built_up_area__c = 1200,
            UDS__c = 300,
            UDS_Sq_mts__c = 50,
            Super_built_up_area__c = 1500,
            Price_Per_Sq_Ft__c = 5000,
            Floor_Rise__c = 200,
            Premium_Charge__c = 100000,
            Covered_Park_Parking__c = 50000,
            Other_Charges__c = 20000,
            Solar_Charges__c = 15000,
            GST1__c = 18
        );
        insert unit;

        // Create Booking linked to above unit and project
        Booking__c book = new Booking__c(
            Followup_Date__c = system.today(),
            Followup_Subject__c = 'test22',
            Last_Comment__c = 'test22',
            Project__c ='Jains Anushree' ,
            Payment_Type__c = 'Custom',
            Sale_Agreement_Completed__c = false,
            Agreement_Amount_Cleared__c = 'Received Partial Amount',
            Stage__c = 'Reservation',
            Demand_Number__c = '12345',
            Date_of_Booking__c = Date.newInstance(2025, 1, 1),
            Mode_Of_Payment__c = 'Credit Card',
            Funding_Type__c = 'Self',
            Plot__c = unit.Id,
            Loan_Sanction_Confirmed__c = true,
            Loan_Sanctioned_Amount__c = 10000,
            Sale_Agreement_Date__c = Date.newInstance(2025, 3, 21),
            Built_up_area__c = 2080,
            Premium_Charge__c = 50000,
            Other_Charges__c = 30000,
            Covered_Park_Parking__c = 300000,
            GST__c = 10
        );
        insert book;

        // Create Master Payment Schedule & link to Project
        Master_payment_schedule__c mpy = new Master_payment_schedule__c(
            Status__c = 'Completed',
            Project__c = project.Id,
            Project_Type__c = project.Project_Type__c
        );
        insert mpy;

        // Create Payment Schedule & link to Booking/Master Payment
        Payment_schedule__c pay = new Payment_schedule__c(
            Booking__c = book.Id,
            Payment_percent__c = 20,
            Master_Payment_Schedule__c = mpy.Id,
            Amount__c = 10000,
            S_No__c = 2,
            Name = 'Test'
        );
        insert pay;
    }

    @isTest
    static void testConstructorWithAllFields() {
        // Tests constructor with fully populated booking (Date_of_Booking, Sale_Agreement_Date, amounts, FloorNo)
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        // Verify date formatting was applied
        System.assertNotEquals(null, controller.Date_of_Booking, 'Date_of_Booking should be formatted');
        System.assertNotEquals(null, controller.Date_of_SaleAgreement, 'Date_of_SaleAgreement should be formatted');
        // Verify payment schedule was queried
        System.assertNotEquals(null, controller.paymentSchedule, 'Payment schedule should be populated');
    }

    @isTest
    static void testConstructorWithNumericFloor() {
        // Tests the numeric FloorNo__c path -> convertToWords for single digit
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];
        Plot__c unit = [SELECT Id, Floor__c FROM Plot__c LIMIT 1];
        unit.Floor__c = '5';
        update unit;

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        // Single digit floor returns ordinal from units list (e.g., 'Fifth')
        System.assertNotEquals(null, controller.FloorNumber, 'FloorNumber should be set for numeric floor');
    }

    @isTest
    static void testConstructorWithTwoDigitFloorTeens() {
        // Tests convertToWords for teen numbers (10-19)
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];
        Plot__c unit = [SELECT Id, Floor__c FROM Plot__c LIMIT 1];
        unit.Floor__c = '15';
        update unit;

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        System.assert(controller.FloorNumber != null, 'FloorNumber should handle teen numbers');
    }

    @isTest
    static void testConstructorWithTwoDigitFloorTwenties() {
        // Tests convertToWords for numbers >= 20 (e.g., 25 -> 'twentyFifthth')
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];
        Plot__c unit = [SELECT Id, Floor__c FROM Plot__c LIMIT 1];
        unit.Floor__c = '25';
        update unit;

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller.FloorNumber, 'FloorNumber should handle 20+ numbers');
    }

    @isTest
    static void testConstructorWithTwoDigitFloorExactTwenty() {
        // Tests convertToWords for exact tens (20) where secondLast == 0
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];
        Plot__c unit = [SELECT Id, Floor__c FROM Plot__c LIMIT 1];
        unit.Floor__c = '20';
        update unit;

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller.FloorNumber, 'FloorNumber should handle exact tens');
    }

    @isTest
    static void testConstructorWithGroundFloor() {
        // Tests the FloorNo__c == 'G' path
        Booking__c book = [SELECT Id, Plot__c FROM Booking__c LIMIT 1];
        Plot__c unit = [SELECT Id, Floor__c FROM Plot__c LIMIT 1];
        unit.Floor__c = 'G';
        update unit;

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        System.assertEquals('Ground ', controller.FloorNumber, 'Ground floor should return "Ground "');
    }


    @isTest
    static void testDateFormattingWithDaySuffixes() {
        // Tests formatDate with dates that have special suffixes (1st, 2nd, 3rd, 21st, 22nd, 23rd, 31st)
        // and default 'th' suffix
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];

        // Set booking date to 2nd (nd suffix) and sale agreement to 23rd (rd suffix)
        book.Date_of_Booking__c = Date.newInstance(2025, 6, 2);
        book.Sale_Agreement_Date__c = Date.newInstance(2025, 7, 23);
        update book;

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        System.assert(controller.Date_of_Booking.contains('nd'), 'Day 2 should have "nd" suffix');
        System.assert(controller.Date_of_SaleAgreement.contains('rd'), 'Day 23 should have "rd" suffix');
    }

    @isTest
    static void testDateFormattingDefaultThSuffix() {
        // Tests formatDate with a date that uses default 'th' suffix (e.g., 15th)
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];

        book.Date_of_Booking__c = Date.newInstance(2025, 8, 15);
        book.Sale_Agreement_Date__c = Date.newInstance(2025, 12, 31);
        update book;

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        System.assert(controller.Date_of_Booking.contains('th'), 'Day 15 should have "th" suffix');
        System.assert(controller.Date_of_SaleAgreement.contains('st'), 'Day 31 should have "st" suffix');
    }

    @isTest
    static void testConvertYearToWordsWithTeens() {
        // Tests convertYearToWords for year with teen last two digits (e.g., 2015)
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];

        book.Date_of_Booking__c = Date.newInstance(2015, 5, 10);
        update book;

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        // Year 2015 -> "Two thousand fifteen"
        System.assert(controller.Date_of_Booking.contains('fifteen'), 'Year 2015 should contain "fifteen"');
    }

    @isTest
    static void testConvertYearToWordsWithTwenties() {
        // Tests convertYearToWords for year 20xx where last part >= 20 (e.g., 2025)
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];

        book.Date_of_Booking__c = Date.newInstance(2025, 3, 1);
        update book;

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        System.assert(controller.Date_of_Booking.contains('twenty'), 'Year 2025 should contain "twenty"');
    }

    @isTest
    static void testGetFormattedDateDirectly() {
        // Directly test the public getFormattedDate method
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];

        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);

        Test.startTest();
        String result = controller.getFormattedDate(Date.newInstance(2024, 1, 1));
        Test.stopTest();

        System.assert(result.contains('st'), 'Day 1 should have "st" suffix');
        System.assert(result.contains('January'), 'Should contain month name "January"');
    }

    @isTest
    static void testConstructorWithNullAmountFields() {
        // Tests null-check branches for amount fields
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];

        // Clear amount fields to test null branches
        book.Date_of_Booking__c = null;
        book.Sale_Agreement_Date__c = null;
        update book;

        // Clear floor to test null FloorNo__c
        Plot__c unit = [SELECT Id FROM Plot__c LIMIT 1];
        unit.Floor__c = null;
        update unit;

        Test.startTest();
        PageReference testPage = Page.SALE_AGREEMENT_AARYA;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(book.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        SaleAgreementController controller = new SaleAgreementController(sc);
        Test.stopTest();

        System.assertEquals(null, controller.Date_of_Booking, 'Date_of_Booking should be null when not set');
        System.assertEquals(null, controller.Date_of_SaleAgreement, 'Date_of_SaleAgreement should be null when not set');
        System.assertEquals(null, controller.FloorNumber, 'FloorNumber should be null when floor not set');
    }
}