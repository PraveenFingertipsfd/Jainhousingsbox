@isTest
public class BookingApprovalCtrlTest {

    @TestSetup
    static void setupData() {
        // Create bookings with different stages for various test scenarios
        List<Booking__c> bookings = new List<Booking__c>();
        bookings.add(new Booking__c(Stage__c = 'Sale Agreement Execution Completed'));
        bookings.add(new Booking__c(Stage__c = 'Registration'));
        bookings.add(new Booking__c(Stage__c = 'Reservation'));
        insert bookings;
    }

    private static Booking__c getBookingByStage(String stage) {
        return [SELECT Id, Stage__c, Cancellation_Charges__c FROM Booking__c WHERE Stage__c = :stage LIMIT 1];
    }

    // ---- Constructor Tests ----

    @isTest
    static void testConstructor_SAECStage_NoApprovalSteps() {
        Booking__c b = getBookingByStage('Sale Agreement Execution Completed');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);
        Test.stopTest();

        System.assertNotEquals(null, ctrl.booking, 'Booking should be populated from constructor');
        System.assertEquals('Sale Agreement Execution Completed', ctrl.booking.Stage__c,
            'Stage should be fetched from database');
        // No approval steps => approvedCount != 1 => false
        System.assertEquals(false, ctrl.showCancellation,
            'showCancellation should be false when no approval steps exist');
    }

    @isTest
    static void testConstructor_RegistrationStage_NoApprovalSteps() {
        Booking__c b = getBookingByStage('Registration');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);
        Test.stopTest();

        System.assertEquals('Registration', ctrl.booking.Stage__c,
            'Stage should match Registration');
        System.assertEquals(false, ctrl.showCancellation,
            'showCancellation should be false with no approval steps even for Registration stage');
    }

    @isTest
    static void testConstructor_InvalidStage_ReturnsFalseImmediately() {
        // Stage not in validStages list => shouldShowCancellation returns false immediately
        Booking__c b = getBookingByStage('Reservation');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);
        Test.stopTest();

        System.assertEquals(false, ctrl.showCancellation,
            'showCancellation should be false for non-valid stage like Reservation');
        System.assertEquals('Reservation', ctrl.booking.Stage__c,
            'Stage should remain Reservation');
    }



    @isTest
    static void testSave_ValidStageNoApprovalSteps_ClearsChargesSinceNotInSecondStep() {
        // Valid stage but no approval steps => shouldShowCancellation returns false in save()
        // => clears cancellation charges
        Booking__c b = getBookingByStage('Sale Agreement Execution Completed');
        b.Cancellation_Charges__c = 2000;
        update b;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);
        PageReference result = ctrl.save();
        Test.stopTest();

        System.assertEquals(null, result, 'save() should return null');
        Booking__c updated = [SELECT Cancellation_Charges__c FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals(null, updated.Cancellation_Charges__c,
            'Charges cleared because shouldShowCancellation is false (no approval steps with exactly 1 approved)');
        System.assert(ApexPages.hasMessages(), 'Should have page messages after save');
    }

    @isTest
    static void testSave_ValidStageMissingCancellationCharge_NullCharges() {
        // Even though stage is valid, shouldShowCancellation is false (no approval steps),
        // so it falls into the !validStage branch and clears charges
        Booking__c b = getBookingByStage('Sale Agreement Execution Completed');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);
        ctrl.booking.Cancellation_Charges__c = null;
        PageReference result = ctrl.save();
        Test.stopTest();

        System.assertEquals(null, result, 'save() should return null');
        System.assert(ApexPages.hasMessages(), 'Should have page messages');
    }




    @isTest
    static void testCancel_ReturnsPageReference() {
        Booking__c b = getBookingByStage('Registration');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);
        PageReference ref = ctrl.cancel();
        Test.stopTest();

        System.assertNotEquals(null, ref, 'cancel() should return a PageReference from standard controller');
    }

    @isTest
    static void testCancel_DifferentStage() {
        Booking__c b = getBookingByStage('Reservation');

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);
        PageReference ref = ctrl.cancel();
        Test.stopTest();

        System.assertNotEquals(null, ref, 'cancel() should return a PageReference regardless of stage');
    }

    // ---- approvalComments property test ----

    @isTest
    static void testApprovalCommentsProperty_GetterSetter() {
        Booking__c b = getBookingByStage('Registration');

        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);

        Test.startTest();
        System.assertEquals(null, ctrl.approvalComments,
            'approvalComments should be null initially');
        ctrl.approvalComments = 'Test comments for approval';
        Test.stopTest();

        System.assertEquals('Test comments for approval', ctrl.approvalComments,
            'approvalComments getter/setter should work');
    }

    // ---- showCancellation property test ----

    @isTest
    static void testShowCancellationProperty() {
        Booking__c b = getBookingByStage('Sale Agreement Execution Completed');

        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);

        Test.startTest();
        // Default should be false due to no approval steps
        System.assertEquals(false, ctrl.showCancellation,
            'showCancellation should default to false without approval steps');
        // Test setter
        ctrl.showCancellation = true;
        System.assertEquals(true, ctrl.showCancellation,
            'showCancellation setter should work');
        Test.stopTest();
    }

    // ---- Bulk test: Multiple bookings through constructor ----

    @isTest
    static void testConstructor_BulkBookings() {
        List<Booking__c> bookings = new List<Booking__c>();
        for (Integer i = 0; i < 50; i++) {
            bookings.add(new Booking__c(Stage__c = 'Reservation'));
        }
        insert bookings;

        Test.startTest();
        for (Booking__c bk : bookings) {
            ApexPages.StandardController sc = new ApexPages.StandardController(bk);
            BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);
            System.assertNotEquals(null, ctrl.booking, 'Booking should not be null');
            System.assertEquals(false, ctrl.showCancellation, 'showCancellation should be false for Reservation');
        }
        Test.stopTest();
    }

    // ---- Multiple stages save in sequence ----

    @isTest
    static void testSave_AllThreeStages() {
        // Test save() across all three different stages to cover all branches
        List<String> stages = new List<String>{
            'Sale Agreement Execution Completed', 'Registration', 'Reservation'
        };

        Test.startTest();
        for (String stage : stages) {
            Booking__c b = getBookingByStage(stage);
            ApexPages.StandardController sc = new ApexPages.StandardController(b);
            BookingApprovalCtrl ctrl = new BookingApprovalCtrl(sc);
            PageReference result = ctrl.save();
            System.assertEquals(null, result, 'save() should return null for stage: ' + stage);
        }
        Test.stopTest();

        System.assert(ApexPages.hasMessages(), 'Should have accumulated page messages');
    }
}