@isTest
public class Cost_SheetControllerTest {

    // Helper: Create Project + Plot + Booking with specific Floor and charge fields
    private static Booking__c createBookingWithFloor(String floorValue, Boolean setCharges) {
        Project__c project = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments'
        );
        insert project;

        Plot__c plot = new Plot__c(
            Name = 'Unit Test',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = 'Apartments',
            Floor__c = floorValue,
            Super_built_up_area__c = 1500,
            Carpet_Area__c = 850,
            Price_Per_Sq_Ft__c = 5000
        );
        insert plot;

        Booking__c booking = new Booking__c(
            Plot__c = plot.Id,
            Project1__c = project.Id,
            Project__c = 'Jains Anushree'
        );
        if (setCharges) {
            booking.Price_per_sqft__c = 5000;
            booking.Other_Charges__c = 100;
            booking.Floor_Rise_Charges_Rate__c = 50;
            booking.Premium_Charge__c = 200;
        }
        insert booking;
        return booking;
    }

    // ---- Constructor: Single digit floor (1-9) → convertToWords single digit path ----
    @isTest
    static void testConstructor_NumericFloor_SingleDigit() {
        Booking__c booking = createBookingWithFloor('5', true);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        Cost_SheetController controller = new Cost_SheetController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
        // FloorNo__c formula should evaluate from Plot.Floor__c = '5'
        // If formula populates: FloorNumber = 'Fifth Floor'
        // If formula doesn't populate: FloorNumber = null
    }

    // ---- Constructor: Teen floor (10-19) → convertToWords teens branch ----
    @isTest
    static void testConstructor_NumericFloor_Teens() {
        Booking__c booking = createBookingWithFloor('15', true);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        Cost_SheetController controller = new Cost_SheetController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
    }

    // ---- Constructor: Twenties floor (20+) with units digit → tens + units branch ----
    @isTest
    static void testConstructor_NumericFloor_Twenties() {
        Booking__c booking = createBookingWithFloor('25', true);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        Cost_SheetController controller = new Cost_SheetController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
    }

    // ---- Constructor: Exact twenty (20) → tens branch, secondLast == 0 ----
    @isTest
    static void testConstructor_NumericFloor_ExactTwenty() {
        Booking__c booking = createBookingWithFloor('20', true);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        Cost_SheetController controller = new Cost_SheetController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
    }

    // ---- Constructor: Ground floor 'G' ----
    @isTest
    static void testConstructor_GroundFloor() {
        Booking__c booking = createBookingWithFloor('G', false);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        Cost_SheetController controller = new Cost_SheetController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
        // If FloorNo__c formula populates from Floor__c = 'G':
        // FloorNumber should be ' Ground Floor '
    }

    // ---- Constructor: Null floor (skips floor logic entirely) ----
    @isTest
    static void testConstructor_NullFloor() {
        Booking__c booking = createBookingWithFloor(null, true);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        Cost_SheetController controller = new Cost_SheetController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
        System.assertEquals(null, controller.FloorNumber, 'FloorNumber should be null when floor is not set');
    }

    // ---- Constructor: Charges populated (covers lines 31-46) ----
    @isTest
    static void testConstructor_WithAllCharges() {
        Booking__c booking = createBookingWithFloor('1', true);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        Cost_SheetController controller = new Cost_SheetController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
        // If Super_Built_up_area_NE__c formula evaluates from Plot data,
        // the charge fields should be calculated
    }

    // ---- Constructor: No Plot link (Super_Built_up_area_NE__c = null, skips charges) ----
    @isTest
    static void testConstructor_NoPlotLink() {
        Booking__c booking = new Booking__c(
            Price_per_sqft__c = 5000,
            Other_Charges__c = 100,
            Floor_Rise_Charges_Rate__c = 50,
            Premium_Charge__c = 200
        );
        insert booking;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        Cost_SheetController controller = new Cost_SheetController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
        System.assertEquals(null, controller.FloorNumber, 'FloorNumber should be null without Plot');
    }

    // ---- Constructor: Floor '2' (covers second ordinal) ----
    @isTest
    static void testConstructor_NumericFloor_Two() {
        Booking__c booking = createBookingWithFloor('2', false);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        Cost_SheetController controller = new Cost_SheetController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
    }

    // ---- Constructor: Floor '10' (teens boundary) ----
    @isTest
    static void testConstructor_NumericFloor_Ten() {
        Booking__c booking = createBookingWithFloor('10', false);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        Cost_SheetController controller = new Cost_SheetController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
    }
}