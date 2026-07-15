@isTest
public class TestRaiseDemandController {

    @testSetup
    static void setupData() {
        // ---- Apartments project ----
        Project__c projectApt = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments'
        );
        insert projectApt;

        Block__c blockApt = new Block__c(
            Name = 'Block A',
            Project__c = projectApt.Id
        );
        insert blockApt;

        Plot__c unitApt = new Plot__c(
            Name = 'Unit 101',
            Status__c = 'Available',
            Project__c = projectApt.Id,
            Project_Type__c = 'Apartments',
            Block__c = 'A2',
            Block1__c = blockApt.Id,
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
        insert unitApt;

        // Quote for Custom payment
        Quote__c quoteCustom = new Quote__c(
            Payment_Type__c = 'Custom'
        );
        insert quoteCustom;

        // Quote for Standard payment
        Quote__c quoteStandard = new Quote__c(
            Payment_Type__c = 'Standard'
        );
        insert quoteStandard;

        // Booking - Custom payment (Apartments)
        Booking__c bookingCustom = new Booking__c(
            Project1__c = projectApt.Id,
            Project__c = 'Jains Anushree',
            Plot__c = unitApt.Id,
            Cost_Sheet__c = quoteCustom.Id,
            GST__c = 10,
            Date_of_Booking__c = System.today(),
            Stage__c = 'Reservation'
        );
        insert bookingCustom;

        // Booking - Standard payment (Apartments)
        Booking__c bookingStandard = new Booking__c(
            Project1__c = projectApt.Id,
            Project__c = 'Jains Anushree',
            Plot__c = unitApt.Id,
            Cost_Sheet__c = quoteStandard.Id,
            GST__c = 10,
            Date_of_Booking__c = System.today(),
            Stage__c = 'Reservation'
        );
        insert bookingStandard;

        // Master Payment Schedule - link Tower to blockApt so Standard path query matches
        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Name = 'Foundation',
            S_No__c = 1,
            Project__c = projectApt.Id,
            Project_Type__c = 'Apartments',
            Status__c = 'Completed',
            Payment_percent__c = 10,
            Tower__c = blockApt.Id
        );
        insert mps;

        Master_Payment_Schedule__c mps2 = new Master_Payment_Schedule__c(
            Name = 'Slab 1',
            S_No__c = 2,
            Project__c = projectApt.Id,
            Project_Type__c = 'Apartments',
            Status__c = 'Completed',
            Payment_percent__c = 15,
            Tower__c = blockApt.Id
        );
        insert mps2;

        // Payment Schedules for Custom booking (Status on the PS itself matters for Custom path)
        Payment_Schedule__c psCustom1 = new Payment_Schedule__c(
            Name = 'PS Custom 1',
            Booking__c = bookingCustom.Id,
            Master_Payment_Schedule__c = mps.Id,
            S_No__c = 1,
            Payment_percent__c = 10,
            Status__c = 'Completed',
            Amount__c = 50000,
            Cost_Sheet__c = quoteCustom.Id
        );
        insert psCustom1;

        Payment_Schedule__c psCustom2 = new Payment_Schedule__c(
            Name = 'PS Custom 2',
            Booking__c = bookingCustom.Id,
            Master_Payment_Schedule__c = mps2.Id,
            S_No__c = 2,
            Payment_percent__c = 15,
            Status__c = 'Completed',
            Amount__c = 75000,
            Cost_Sheet__c = quoteCustom.Id
        );
        insert psCustom2;

        // Payment Schedules for Standard booking (Master PS Status matters for Standard path)
        Payment_Schedule__c psStd1 = new Payment_Schedule__c(
            Name = 'PS Std 1',
            Booking__c = bookingStandard.Id,
            Master_Payment_Schedule__c = mps.Id,
            S_No__c = 1,
            Payment_percent__c = 10,
            Amount__c = 50000,
            Cost_Sheet__c = quoteStandard.Id
        );
        insert psStd1;

        Payment_Schedule__c psStd2 = new Payment_Schedule__c(
            Name = 'PS Std 2',
            Booking__c = bookingStandard.Id,
            Master_Payment_Schedule__c = mps2.Id,
            S_No__c = 2,
            Payment_percent__c = 15,
            Amount__c = 75000,
            Cost_Sheet__c = quoteStandard.Id
        );
        insert psStd2;

        // Receipt and line items for Custom booking (so Received_Amount1__c rollup has data)
        Receipt__c receiptCustom = new Receipt__c(
            Booking__c = bookingCustom.Id,
            Approval_status__c = 'Approved by Finance Team'
        );
        insert receiptCustom;

        Receipt_Line_Item__c rliCustom = new Receipt_Line_Item__c(
            Name = 'RLI Custom 1',
            Receipt__c = receiptCustom.Id,
            Booking__c = bookingCustom.Id,
            Amount__c = 20000,
            Payment_schedule__c = psCustom1.Id
        );
        insert rliCustom;

        // Receipt and line items for Standard booking
        Receipt__c receiptStd = new Receipt__c(
            Booking__c = bookingStandard.Id,
            Approval_status__c = 'Approved by Finance Team'
        );
        insert receiptStd;

        Receipt_Line_Item__c rliStd = new Receipt_Line_Item__c(
            Name = 'RLI Std 1',
            Receipt__c = receiptStd.Id,
            Booking__c = bookingStandard.Id,
            Amount__c = 20000,
            Payment_schedule__c = psStd1.Id
        );
        insert rliStd;

        // ---- Plots project (for unknown property type test) ----
        Project__c projectPlots = new Project__c(
            Name = 'Jain Plotter',
            Project_Type__c = 'Plots'
        );
        insert projectPlots;

        Plot__c unitPlots = new Plot__c(
            Name = 'Plot 201',
            Status__c = 'Available',
            Project__c = projectPlots.Id,
            Project_Type__c = 'Plots',
            Plot_Type__c = 'Residential',
            Carpet_Area__c = 500
        );
        insert unitPlots;

        Booking__c bookingPlots = new Booking__c(
            Project1__c = projectPlots.Id,
            Project__c = 'Jain Plotter',
            Plot__c = unitPlots.Id,
            GST__c = 5,
            Date_of_Booking__c = System.today(),
            Stage__c = 'Reservation'
        );
        insert bookingPlots;
    }

    // ---------------------------------------------------------------
    // 1. Custom Payment path (Apartments)
    // ---------------------------------------------------------------
    @isTest
    static void testConstructor_CustomPayment() {
        Booking__c booking = [
            SELECT Id FROM Booking__c
            WHERE Cost_Sheet__r.Payment_Type__c = 'Custom'
            LIMIT 1
        ];

        Test.setCurrentPageReference(new PageReference('/apex/TestPage'));
        ApexPages.currentPage().getParameters().put('Id', booking.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(booking);

        Test.startTest();
        RaiseDemandController ctrl = new RaiseDemandController(sc);
        Test.stopTest();

        // Constructor should have run the Custom branch and populated values
        System.assertNotEquals(null, ctrl.paymentBreakups, 'paymentBreakups list should be initialised');
        System.assert(ctrl.paymentBreakups.size() > 0, 'Should have at least one payment breakup record');
        System.assertNotEquals(null, ctrl.currentCompletedStage, 'currentCompletedStage should be set');
        System.assertNotEquals(null, ctrl.demandDueDate, 'demandDueDate should be set');
        System.assertEquals(System.today().addDays(7), ctrl.demandDueDate, 'demandDueDate should be today + 7');
        System.assert(ctrl.currentMilestonePaymentPercent != null, 'Milestone payment percent should be set');
        System.assertNotEquals(null, ctrl.currentMilestoneNumber, 'currentMilestoneNumber should be set');
        System.assert(ctrl.totalAmountPayable >= 0, 'totalAmountPayable should be non-negative');
        System.assertNotEquals(null, ctrl.totalAmountPayableInWords, 'Amount in words should be populated');
        System.assert(ctrl.TDSonePercentage != null, 'TDS percentage should be calculated');
    }

    // ---------------------------------------------------------------
    // 2. Standard Payment path (Apartments)
    // ---------------------------------------------------------------
    @isTest
    static void testConstructor_StandardPayment() {
        Booking__c booking = [
            SELECT Id FROM Booking__c
            WHERE Cost_Sheet__r.Payment_Type__c = 'Standard'
            LIMIT 1
        ];

        Test.setCurrentPageReference(new PageReference('/apex/TestPage'));
        ApexPages.currentPage().getParameters().put('Id', booking.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(booking);

        Test.startTest();
        RaiseDemandController ctrl = new RaiseDemandController(sc);
        Test.stopTest();

        // Standard branch should set properties via Master Payment Schedule
        System.assertNotEquals(null, ctrl.paymentBreakups, 'paymentBreakups should be initialised');
        System.assertNotEquals(null, ctrl.demandDueDate, 'demandDueDate should be set for Standard path');
        System.assert(ctrl.totalAmountPayable >= 0, 'totalAmountPayable should be non-negative');
        System.assertNotEquals(null, ctrl.totalAmountPayableInWords, 'Amount in words should be populated');
    }

    // ---------------------------------------------------------------
    // 3. Null Booking Id
    // ---------------------------------------------------------------
    @isTest
    static void testConstructor_NullBookingId() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        // Set page reference WITHOUT an 'id' parameter
        Test.setCurrentPageReference(new PageReference('/apex/TestPage'));

        ApexPages.StandardController sc = new ApexPages.StandardController(booking);

        Test.startTest();
        RaiseDemandController ctrl = new RaiseDemandController(sc);
        Test.stopTest();

        // Should have added an error message and returned early
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        Boolean foundNullError = false;
        for (ApexPages.Message msg : msgs) {
            if (msg.getDetail().contains('Booking record Id is null')) {
                foundNullError = true;
                break;
            }
        }
        System.assert(foundNullError, 'Error message about null booking Id should be present');
        // Properties should remain at initialised defaults
        System.assertEquals(0, ctrl.totAmtDueTillPrevMilestone, 'totAmtDueTillPrevMilestone should be 0 when no booking Id');
        System.assertEquals(0, ctrl.presentDue, 'presentDue should be 0 when no booking Id');
    }

    // ---------------------------------------------------------------
    // 4. Unknown Property Type (Plots — not Apartments or Villas)
    // ---------------------------------------------------------------
    @isTest
    static void testConstructor_UnknownPropertyType() {
        Booking__c booking = [
            SELECT Id FROM Booking__c
            WHERE Project1__r.Project_Type__c = 'Plots'
            LIMIT 1
        ];

        Test.setCurrentPageReference(new PageReference('/apex/TestPage'));
        ApexPages.currentPage().getParameters().put('Id', booking.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(booking);

        Test.startTest();
        RaiseDemandController ctrl = new RaiseDemandController(sc);
        Test.stopTest();

        // Should hit the else branch with error about no property type
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        Boolean foundPropertyError = false;
        for (ApexPages.Message msg : msgs) {
            if (msg.getDetail().contains('No "Property Type" selected')) {
                foundPropertyError = true;
                break;
            }
        }
        System.assert(foundPropertyError, 'Error message about missing property type should be present');
        System.assertEquals(0, ctrl.totalAmountPayable, 'totalAmountPayable should remain 0 for unknown property type');
    }

    // ---------------------------------------------------------------
    // 5. getMilestoneLabel — all ordinal suffix branches
    // ---------------------------------------------------------------
    @isTest
    static void testGetMilestoneLabel() {
        // 1st, 2nd, 3rd (special cases)
        System.assertEquals('1st', RaiseDemandController.getMilestoneLabel(1));
        System.assertEquals('2nd', RaiseDemandController.getMilestoneLabel(2));
        System.assertEquals('3rd', RaiseDemandController.getMilestoneLabel(3));

        // Generic 'th' suffix
        System.assertEquals('4th', RaiseDemandController.getMilestoneLabel(4));
        System.assertEquals('11th', RaiseDemandController.getMilestoneLabel(11));
        System.assertEquals('12th', RaiseDemandController.getMilestoneLabel(12));
        System.assertEquals('13th', RaiseDemandController.getMilestoneLabel(13));

        // 21st, 22nd, 23rd (repeat pattern)
        System.assertEquals('21st', RaiseDemandController.getMilestoneLabel(21));
        System.assertEquals('22nd', RaiseDemandController.getMilestoneLabel(22));
        System.assertEquals('23rd', RaiseDemandController.getMilestoneLabel(23));

        // 31st
        System.assertEquals('31st', RaiseDemandController.getMilestoneLabel(31));

        // Null input
        System.assertEquals('Invalid milestone', RaiseDemandController.getMilestoneLabel(null));
    }

    // ---------------------------------------------------------------
    // 6. PaymentBreakup inner class / wrapper
    // ---------------------------------------------------------------
    @isTest
    static void testPaymentBreakupWrapper() {
        RaiseDemandController.PaymentBreakup bp = new RaiseDemandController.PaymentBreakup();
        bp.scheduleNo = '1';
        bp.scheduleName = 'Foundation';
        bp.totalAmount = 100000;
        bp.paidAmount = 40000;
        bp.pendingAmount = 60000;
        bp.isCurrent = true;

        System.assertEquals('1', bp.scheduleNo, 'scheduleNo should match');
        System.assertEquals('Foundation', bp.scheduleName, 'scheduleName should match');
        System.assertEquals(100000, bp.totalAmount, 'totalAmount should match');
        System.assertEquals(40000, bp.paidAmount, 'paidAmount should match');
        System.assertEquals(60000, bp.pendingAmount, 'pendingAmount should match');
        System.assertEquals(true, bp.isCurrent, 'isCurrent should be true');

        // Second instance with different values
        RaiseDemandController.PaymentBreakup bp2 = new RaiseDemandController.PaymentBreakup();
        bp2.scheduleNo = '2';
        bp2.scheduleName = 'Slab Work';
        bp2.totalAmount = 200000;
        bp2.paidAmount = 0;
        bp2.pendingAmount = 200000;
        bp2.isCurrent = false;

        System.assertEquals('2', bp2.scheduleNo, 'Second breakup scheduleNo should match');
        System.assertEquals(false, bp2.isCurrent, 'Second breakup should not be current');
    }
}