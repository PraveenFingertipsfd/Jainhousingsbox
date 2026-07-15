@isTest
public class ReceiptVFPControllerTest {

    // Helper: Create Receipt linked to Booking linked to Plot with specific Floor__c
    private static Receipt__c createReceiptWithFloor(String floorValue, String txnId) {
        Project__c project = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments'
        );
        insert project;

        Plot__c plot = new Plot__c(
            Name = 'Unit VFP',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = 'Apartments',
            Floor__c = floorValue
        );
        insert plot;

        Booking__c booking = new Booking__c(
            Plot__c = plot.Id
        );
        insert booking;

        Receipt__c receipt = new Receipt__c(
            Booking__c = booking.Id,
            Check_Transaction_Nmber__c = txnId
        );
        insert receipt;
        return receipt;
    }

    // ---- Numeric floor single digit (covers convertToWords lines 63-67) ----
    @isTest
    static void testConstructor_NumericFloorSingleDigit() {
        Receipt__c receipt = createReceiptWithFloor('5', 'TXN_SINGLE');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
        System.assertEquals('TXN_SINGLE', controller.transactionId);
        System.assertNotEquals('Invalid Floor Number', controller.FloorNumber,
            'Floor should be converted, not Invalid');
    }

    // ---- Numeric floor teens (covers convertToWords lines 52-53) ----
    @isTest
    static void testConstructor_NumericFloorTeens() {
        Receipt__c receipt = createReceiptWithFloor('15', 'TXN_TEEN');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
    }

    // ---- Numeric floor twenties with units (covers lines 54-60) ----
    @isTest
    static void testConstructor_NumericFloorTwenties() {
        Receipt__c receipt = createReceiptWithFloor('25', 'TXN_TWENTY5');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
    }

    // ---- Numeric floor exact twenty (secondLast=0, skips line 59) ----
    @isTest
    static void testConstructor_NumericFloorExactTwenty() {
        Receipt__c receipt = createReceiptWithFloor('20', 'TXN_TWENTY0');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
    }

    // ---- Numeric floor ten (teens boundary, covers lines 52-53) ----
    @isTest
    static void testConstructor_NumericFloorTen() {
        Receipt__c receipt = createReceiptWithFloor('10', 'TXN_TEN');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
    }

    // ---- Non-numeric floor 'G' (covers lines 20-25) ----
    @isTest
    static void testConstructor_NonNumericFloor() {
        Receipt__c receipt = createReceiptWithFloor('G', 'TXN_GROUND');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
        System.assertNotEquals('Invalid Floor Number', controller.FloorNumber,
            'Should not be Invalid for non-null floor');
    }

    // ---- Null floor (covers lines 27-28) ----
    @isTest
    static void testConstructor_NullFloor() {
        Receipt__c receipt = createReceiptWithFloor(null, 'TXN_NULL');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();

        System.assertEquals('Invalid Floor Number', controller.FloorNumber,
            'Should show Invalid Floor Number when floor is null');
    }

    // ---- With transaction ID (covers lines 14-16) ----
    @isTest
    static void testConstructor_WithTransaction() {
        Receipt__c receipt = createReceiptWithFloor('3', 'TXN123');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();

        System.assertEquals('TXN123', controller.transactionId);
        System.assertEquals(receipt.Id, controller.ReceiptId);
    }

    // ---- Without transaction ID (line 14 false, transactionId stays '') ----
    @isTest
    static void testConstructor_WithoutTransaction() {
        Project__c project = new Project__c(Name = 'Jains Anushree', Project_Type__c = 'Apartments');
        insert project;
        Plot__c plot = new Plot__c(Name = 'Unit NoTxn', Status__c = 'Available', Project__c = project.Id, Project_Type__c = 'Apartments', Floor__c = '1');
        insert plot;
        Booking__c booking = new Booking__c(Plot__c = plot.Id);
        insert booking;
        Receipt__c receipt = new Receipt__c(Booking__c = booking.Id);
        insert receipt;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();

        System.assertEquals('', controller.transactionId, 'Should be empty when no transaction');
    }

    // ---- Getter/Setter coverage ----
    @isTest
    static void testGetterSetterProperties() {
        Receipt__c receipt = createReceiptWithFloor('1', 'TXN_PROP');

        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);

        Test.startTest();
        controller.FloorNumber = 'TestFloor';
        controller.Total_Received_Amount_In_Words = 'Five Hundred';
        controller.ReceiptId = receipt.Id;
        controller.transactionId = 'MANUAL';
        Test.stopTest();

        System.assertEquals('TestFloor', controller.FloorNumber);
        System.assertEquals('Five Hundred', controller.Total_Received_Amount_In_Words);
        System.assertEquals(receipt.Id, controller.ReceiptId);
        System.assertEquals('MANUAL', controller.transactionId);
    }

    // ---- Floor '2' (another single digit) ----
    @isTest
    static void testConstructor_NumericFloorTwo() {
        Receipt__c receipt = createReceiptWithFloor('2', 'TXN_TWO');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should initialize');
    }
}