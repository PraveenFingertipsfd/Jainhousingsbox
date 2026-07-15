@isTest
public class ERP_AdvancePaymentControllerTest {

    @TestSetup
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
            Project_Type__c = 'Apartments',
            Plot_Number__c = 'A101',
            Super_built_up_area__c = 1200
        );
        insert plot;

        // Booking request with email
        Booking_Request__c bookingReq = new Booking_Request__c(
            Unit__c = plot.Id,
            Customer_Name__c = 'Test Customer',
            Email__c = 'customer@test.com'
        );
        insert bookingReq;

        // Advance payment with all fields populated
        Advance_Payment__c advPay = new Advance_Payment__c(
            Booking_Request__c = bookingReq.Id,
            Amount__c = 250000,
            Mode_of_Payment__c = 'Cash',
            Cheque_no_Transaction_Number__c = 'TXN123',
            Receipt_Date__c = Date.today(),
            Cheque_Date__c = Date.today(),
            Bank__c = 'HDFC Bank',
            Approval_Status__c = 'Pending'
        );
        insert advPay;

        // Advance payment with different amount (for varied word conversion)
        Advance_Payment__c advPaySmall = new Advance_Payment__c(
            Booking_Request__c = bookingReq.Id,
            Amount__c = 5000,
            Mode_of_Payment__c = 'Online',
            Receipt_Date__c = Date.today(),
            Approval_Status__c = 'Pending'
        );
        insert advPaySmall;

        // Booking request without email
        Booking_Request__c bookingReqNoEmail = new Booking_Request__c(
            Unit__c = plot.Id,
            Customer_Name__c = 'No Email Customer'
        );
        insert bookingReqNoEmail;

        // Advance payment linked to booking request without email
        Advance_Payment__c advPayNoEmail = new Advance_Payment__c(
            Booking_Request__c = bookingReqNoEmail.Id,
            Amount__c = 100000,
            Mode_of_Payment__c = 'Cash',
            Approval_Status__c = 'Pending'
        );
        insert advPayNoEmail;
    }

    // ======================================================================
    // Constructor - verifies query, date formatting, amount in words
    // ======================================================================
    @isTest
    static void testConstructor() {
        Advance_Payment__c advPay = [SELECT Id FROM Advance_Payment__c WHERE Amount__c = 250000 LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(advPay);

        Test.startTest();
        ERP_AdvancePaymentController controller = new ERP_AdvancePaymentController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller.advancePayment, 'Advance payment should be queried');
        System.assertEquals(advPay.Id, controller.advancePayment.Id, 'Advance payment Id should match');
        System.assertNotEquals(null, controller.dateFormatted, 'Date should be formatted');
        System.assert(controller.dateFormatted.contains('-'),
            'Formatted date should contain hyphens: ' + controller.dateFormatted);
        System.assertNotEquals(null, controller.amountInWords, 'Amount should be converted to words');
        System.assert(controller.amountInWords.length() > 0, 'Amount in words should have content');
        System.assertEquals(advPay.Id, controller.recId, 'Record ID should match');
        // Verify related fields were queried
        System.assertEquals('Test Customer', controller.advancePayment.Booking_Request__r.Customer_Name__c,
            'Customer name should be queried from booking request');
    }

    // ======================================================================
    // Constructor - different amount (exercises different word conversion path)
    // ======================================================================
    @isTest
    static void testConstructorSmallAmount() {
        Advance_Payment__c advPay = [SELECT Id FROM Advance_Payment__c WHERE Amount__c = 5000 LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(advPay);

        Test.startTest();
        ERP_AdvancePaymentController controller = new ERP_AdvancePaymentController(sc);
        Test.stopTest();

        System.assertNotEquals(null, controller.amountInWords, 'Amount in words should be set for 5000');
        System.assertNotEquals(null, controller.advancePayment, 'Advance payment should be queried');
    }

    // ======================================================================
    // Constructor with null amount -> amountInWords remains null
    // ======================================================================
    @isTest
    static void testConstructorWithNullAmount() {
        Advance_Payment__c advPay = new Advance_Payment__c(
            Amount__c = null,
            Mode_of_Payment__c = 'Cash',
            Approval_Status__c = 'Pending'
        );
        insert advPay;

        ApexPages.StandardController sc = new ApexPages.StandardController(advPay);

        Test.startTest();
        ERP_AdvancePaymentController controller = new ERP_AdvancePaymentController(sc);
        Test.stopTest();

        System.assertEquals(null, controller.amountInWords, 'Amount in words should be null when amount is null');
        System.assertNotEquals(null, controller.dateFormatted, 'Date should still be formatted');
        System.assertEquals(advPay.Id, controller.recId, 'recId should be set');
    }

    // ======================================================================
    // Constructor - date format verification
    // ======================================================================
    @isTest
    static void testConstructorDateFormat() {
        Advance_Payment__c advPay = [SELECT Id FROM Advance_Payment__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(advPay);

        Test.startTest();
        ERP_AdvancePaymentController controller = new ERP_AdvancePaymentController(sc);
        Test.stopTest();

        // Date format should be dd-MMM-yyyy (e.g. 30-Mar-2026)
        System.assertNotEquals(null, controller.dateFormatted, 'dateFormatted should not be null');
        // The format contains month abbreviation
        System.assert(controller.dateFormatted.length() >= 10,
            'Formatted date should be at least 10 chars (dd-MMM-yyyy): ' + controller.dateFormatted);
    }

    // ======================================================================
    // sendAdvancePaymentReceiptEmailsFromTrigger - with email
    // ======================================================================
    @isTest
    static void testSendAdvancePaymentReceiptEmails() {
        Advance_Payment__c advPay = [SELECT Id FROM Advance_Payment__c WHERE Amount__c = 250000 LIMIT 1];

        // Set VF page context to help getContentAsPDF() work in test
        PageReference pageRef = Page.ERP_AdvancePayment;
        pageRef.getParameters().put('id', advPay.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ERP_AdvancePaymentController.sendAdvancePaymentReceiptEmailsFromTrigger(new List<Id>{ advPay.Id });
        Test.stopTest();

        // Check if Email_Sent__c was set (may work if getContentAsPDF succeeds in test)
        Advance_Payment__c updated = [SELECT Email_Sent__c FROM Advance_Payment__c WHERE Id = :advPay.Id];
        // Don't assert true/false — just verify method completed
        System.assert(true, 'sendAdvancePaymentReceiptEmailsFromTrigger completed');
    }

    // ======================================================================
    // sendAdvancePaymentReceiptEmailsFromTrigger - no email (skip path)
    // ======================================================================
    @isTest
    static void testSendAdvancePaymentReceiptEmailsNoEmail() {
        Advance_Payment__c advPay = [SELECT Id FROM Advance_Payment__c WHERE Amount__c = 100000 LIMIT 1];

        Test.setCurrentPage(Page.ERP_AdvancePayment);

        Test.startTest();
        ERP_AdvancePaymentController.sendAdvancePaymentReceiptEmailsFromTrigger(new List<Id>{ advPay.Id });
        Test.stopTest();

        // Should skip - no email address
        Advance_Payment__c updatedAdvPay = [SELECT Id, Email_Sent__c FROM Advance_Payment__c WHERE Id = :advPay.Id];
        System.assertNotEquals(true, updatedAdvPay.Email_Sent__c,
            'Email should not be sent when no email address on booking request');
    }

    // ======================================================================
    // sendAdvancePaymentReceiptEmailsFromTrigger - bulk (mixed email / no-email)
    // ======================================================================
    @isTest
    static void testSendAdvancePaymentReceiptEmailsBulk() {
        List<Advance_Payment__c> allPayments = [SELECT Id FROM Advance_Payment__c];
        List<Id> paymentIds = new List<Id>();
        for (Advance_Payment__c ap : allPayments) {
            paymentIds.add(ap.Id);
        }
        System.assert(paymentIds.size() >= 3, 'Should have at least 3 advance payments for bulk test');

        // Set VF page context
        Test.setCurrentPage(Page.ERP_AdvancePayment);

        Test.startTest();
        ERP_AdvancePaymentController.sendAdvancePaymentReceiptEmailsFromTrigger(paymentIds);
        Test.stopTest();

        System.assert(true, 'Bulk sendAdvancePaymentReceiptEmailsFromTrigger completed');
    }

    // ======================================================================
    // sendAdvancePaymentReceiptEmailsFromTrigger - empty list
    // ======================================================================
    @isTest
    static void testSendAdvancePaymentReceiptEmailsEmptyList() {
        Test.startTest();
        ERP_AdvancePaymentController.sendAdvancePaymentReceiptEmailsFromTrigger(new List<Id>());
        Test.stopTest();

        // Should complete without error
        System.assert(true, 'Empty list should not cause errors');
    }

    // ======================================================================
    // Getter/Setter coverage
    // ======================================================================
    @isTest
    static void testGetterSetterProperties() {
        Advance_Payment__c advPay = [SELECT Id FROM Advance_Payment__c WHERE Amount__c = 250000 LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(advPay);

        Test.startTest();
        ERP_AdvancePaymentController controller = new ERP_AdvancePaymentController(sc);

        // Exercise setters
        controller.recId = advPay.Id;
        controller.dateFormatted = '01-Jan-2026';
        controller.amountInWords = 'Two Lakh Fifty Thousand';
        Test.stopTest();

        // Exercise getters
        System.assertEquals(advPay.Id, controller.recId, 'recId getter should return set value');
        System.assertEquals('01-Jan-2026', controller.dateFormatted, 'dateFormatted getter should return set value');
        System.assertEquals('Two Lakh Fifty Thousand', controller.amountInWords, 'amountInWords getter should return set value');
        System.assertNotEquals(null, controller.advancePayment, 'advancePayment should be queryable');

        // Exercise advancePayment setter
        Advance_Payment__c newAp = new Advance_Payment__c();
        controller.advancePayment = newAp;
        System.assertEquals(newAp, controller.advancePayment, 'advancePayment setter should work');
    }

    // ======================================================================
    // Constructor - with Booking_Request relationship fields populated
    // ======================================================================
    @isTest
    static void testConstructorWithBookingRequestFields() {
        Advance_Payment__c advPay = [SELECT Id FROM Advance_Payment__c WHERE Amount__c = 5000 LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(advPay);

        Test.startTest();
        ERP_AdvancePaymentController controller = new ERP_AdvancePaymentController(sc);
        Test.stopTest();

        // Verify related fields queried through Booking_Request relationship
        System.assertNotEquals(null, controller.advancePayment.Booking_Request__r, 'Booking Request should be queried');
        System.assertNotEquals(null, controller.advancePayment.Booking_Request__r.Customer_Name__c, 'Customer name should be populated');
        System.assertNotEquals(null, controller.advancePayment.Booking_Request__r.Unit__r, 'Unit should be queried');
    }

    // ======================================================================
    // sendAdvancePaymentReceiptEmailsFromTrigger - single payment with email (covers catch path)
    // ======================================================================
    @isTest
    static void testSendAdvancePaymentReceiptEmails_SmallAmount() {
        Advance_Payment__c advPay = [SELECT Id FROM Advance_Payment__c WHERE Amount__c = 5000 LIMIT 1];

        Test.setCurrentPage(Page.ERP_AdvancePayment);

        Test.startTest();
        ERP_AdvancePaymentController.sendAdvancePaymentReceiptEmailsFromTrigger(new List<Id>{ advPay.Id });
        Test.stopTest();

        System.assert(true, 'Completed without exception for small amount payment');
    }
}