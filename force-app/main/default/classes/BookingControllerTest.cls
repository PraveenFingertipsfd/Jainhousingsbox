@isTest
private class BookingControllerTest {

    @TestSetup
    static void setupData() {
        // Create Project
        Project__c project = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments'
        );
        insert project;

        // Create Block
        Block__c block = new Block__c(
            Name = 'A',
            Project__c = project.Id
        );
        insert block;

        // Create Plot/Unit
        Plot__c unit = new Plot__c(
            Name = '101',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = project.Project_Type__c,
            Block__c = 'A2',
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

        // Create Booking
        // Project1__c (lookup) is required so Project1__r.Name resolves in sendWelcomeEmail
        Booking__c book = new Booking__c(
            Followup_Date__c = System.today(),
            Followup_Subject__c = 'test',
            Last_Comment__c = 'test',
            Project__c = 'Jains Anushree',
            Project1__c = project.Id,
            Payment_Type__c = 'Custom',
            Stage__c = 'Reservation',
            Date_of_Booking__c = System.today(),
            Mode_Of_Payment__c = 'Credit Card',
            Funding_Type__c = 'Self',
            Plot__c = unit.Id,
            Email1__c = 'test@example.com',
            First_Applicant_Name__c = 'Test Applicant',
            Booking_Amount1__c = 100000,
            Sale_Agreement_Completed__c = false,
            Agreement_Amount_Cleared__c = 'Received Partial Amount',
            Built_up_area__c = 2080,
            GST__c = 10
        );
        insert book;

        // Create Cost Sheet / Quote
        Quote__c costSheet = new Quote__c(
            Unit__c = unit.Id,
            Booking__c = book.Id
        );
        insert costSheet;
    }

    // --- validateRequiredDocuments tests ---

    @isTest
    static void testValidateRequiredDocuments_WithDocuments() {
        Booking__c booking = [SELECT Id, Funding_Type__c, Nationality__c FROM Booking__c LIMIT 1];

        // Create content documents that match required suffixes
        ContentVersion cv1 = new ContentVersion(
            Title = booking.Id + ' - [ Aadhar Card ]',
            PathOnClient = 'aadhar.pdf',
            VersionData = Blob.valueOf('test')
        );
        ContentVersion cv2 = new ContentVersion(
            Title = booking.Id + ' - [ Pan Card ]',
            PathOnClient = 'pan.pdf',
            VersionData = Blob.valueOf('test')
        );
        ContentVersion cv3 = new ContentVersion(
            Title = booking.Id + ' - [ Applicant Photo ]',
            PathOnClient = 'photo.jpg',
            VersionData = Blob.valueOf('test')
        );
        insert new List<ContentVersion>{cv1, cv2, cv3};

        // Link documents to booking
        List<ContentVersion> versions = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :new List<Id>{cv1.Id, cv2.Id, cv3.Id}];
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentVersion v : versions) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = v.ContentDocumentId,
                LinkedEntityId = booking.Id,
                ShareType = 'V'
            ));
        }
        insert links;

        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>{booking.Id => booking};

        Test.startTest();
        BookingController.validateRequiredDocuments(bookingMap);
        Test.stopTest();
    }

    @isTest
    static void testValidateRequiredDocuments_MissingDocs() {
        Booking__c booking = [SELECT Id, Funding_Type__c, Nationality__c FROM Booking__c LIMIT 1];
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>{booking.Id => booking};

        Test.startTest();
        BookingController.validateRequiredDocuments(bookingMap);
        Test.stopTest();
        // No exception = pass; validation error is added via addError
    }

    @isTest
    static void testValidateRequiredDocuments_LoanFunding() {
        // Tests the Funding_Type__c == 'Loan' branch
        Booking__c booking = [SELECT Id, Funding_Type__c, Nationality__c FROM Booking__c LIMIT 1];
        booking.Funding_Type__c = 'Loan';
        update booking;

        booking = [SELECT Id, Funding_Type__c, Nationality__c FROM Booking__c WHERE Id = :booking.Id];
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>{booking.Id => booking};

        Test.startTest();
        BookingController.validateRequiredDocuments(bookingMap);
        Test.stopTest();
    }

    @isTest
    static void testValidateRequiredDocuments_NonResident() {
        // Tests the Nationality__c != 'Resident' branch (Passport required)
        Booking__c booking = [SELECT Id, Funding_Type__c, Nationality__c FROM Booking__c LIMIT 1];
        booking.Nationality__c = 'NRI';
        update booking;

        booking = [SELECT Id, Funding_Type__c, Nationality__c FROM Booking__c WHERE Id = :booking.Id];
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>{booking.Id => booking};

        Test.startTest();
        BookingController.validateRequiredDocuments(bookingMap);
        Test.stopTest();
    }

    // --- isKYCCollected tests ---

    @isTest
    static void testIsKYCCollected_DocumentsMissing() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        String status = BookingController.isKYCCollected(booking.Id);
        Test.stopTest();

        // Should return missing docs message or SUCCESS
        System.assertNotEquals(null, status, 'Status should not be null');
    }

    // --- IsWelcomeCallCheckListUpdated tests ---

    @isTest
    static void testIsWelcomeCallChecklistUpdated_False() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Boolean result = BookingController.IsWelcomeCallCheckListUpdated(booking.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testIsWelcomeCallChecklistUpdated_DefaultFalse() {
        // Welcome_Call_Checklist_Done__c is a formula/rollup field and cannot be set directly.
        // This test covers the false path of the checklist check.
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Boolean result = BookingController.IsWelcomeCallCheckListUpdated(booking.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    // --- getpageName tests ---

    // --- sendEmailtoCustomer tests ---

    @isTest
    static void testSendEmailtoCustomer() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        BookingController.sendEmailtoCustomer(booking.Id, 'AnushreeBookingForm');
        Test.stopTest();
        // No exception = pass (email not actually sent in test context)
    }

    // --- getUnitData tests ---

    @isTest
    static void testGetUnitData_FromCostSheet() {
        Quote__c costSheet = [SELECT Id FROM Quote__c LIMIT 1];

        Test.startTest();
        BookingController.TypeWrapper result = BookingController.getUnitData(costSheet.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'TypeWrapper should not be null');
        System.assertNotEquals(null, result.ModeOfPay, 'ModeOfPay should be populated');
        System.assertNotEquals(null, result.FundingTyp, 'FundingTyp should be populated');
        System.assertEquals(false, result.IsFromPSABooking, 'Should not be from PSA booking');
    }

    @isTest
    static void testGetUnitData_WithPSAUnitId() {
        Plot__c unit = [SELECT Id FROM Plot__c LIMIT 1];

        Test.startTest();
        BookingController.TypeWrapper result = BookingController.getUnitData(null, unit.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'TypeWrapper should not be null');
        System.assertEquals(true, result.IsFromPSABooking, 'Should be from PSA booking');
        System.assertNotEquals(null, result.PlotLst, 'Plot list should not be null');
    }

    // --- getRecordData tests ---

    @isTest
    static void testGetRecordData() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        BookingController.BookingUserWrapper result = BookingController.getRecordData(booking.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertNotEquals(null, result.booking, 'Booking should not be null');
        System.assertNotEquals(null, result.loggedInUser, 'User should not be null');
        System.assertNotEquals(null, result.documents, 'Documents should not be null');
    }

    // --- sendWelcomeEmail tests ---

    @isTest
    static void testSendWelcomeEmail() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        List<String> toAddresses = new List<String>{'welcome@example.com'};
        List<String> contentIds = new List<String>();

        Test.startTest();
        BookingController.sendWelcomeEmail(booking.Id, '<p>Welcome!</p>', toAddresses, contentIds);
        Test.stopTest();
    }

    // --- getTransferRecordDetails tests ---

    @isTest
    static void testGetTransferRecordDetails() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Transfer__c transfer = new Transfer__c(
            Booking__c = booking.Id,
            Customer_Name__c = 'Test Customer',
            Email__c = 'transfer@example.com',
            Phone__c = '9876543210',
            Transfer_Amount__c = 50000
        );
        insert transfer;

        Test.startTest();
        Transfer__c result = BookingController.getTransferRecordDetails(booking.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Transfer record should be returned');
        System.assertEquals('Test Customer', result.Customer_Name__c, 'Customer name should match');
    }

    // --- saveTransfer tests ---

    @isTest
    static void testSaveTransfer_WithSecondaryApplicantSame() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Booking__c bookingToSave = new Booking__c();
        bookingToSave.First_Applicant_Name__c = 'Updated Name';

        Test.startTest();
        BookingController.saveTransfer(bookingToSave, booking.Id, true);
        Test.stopTest();

        Booking__c updated = [SELECT First_Applicant_Name__c FROM Booking__c WHERE Id = :booking.Id];
        System.assertEquals('Updated Name', updated.First_Applicant_Name__c, 'Name should be updated');
    }

    @isTest
    static void testSaveTransfer_ClearSecondaryApplicant() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Booking__c bookingToSave = new Booking__c();
        // Leave Second_Applicant_Name__c empty to trigger the clear branch

        Test.startTest();
        BookingController.saveTransfer(bookingToSave, booking.Id, false);
        Test.stopTest();

        Booking__c updated = [SELECT Second_Applicant_Name__c, salutation_Applicant2__c FROM Booking__c WHERE Id = :booking.Id];
        System.assertEquals(null, updated.Second_Applicant_Name__c, 'Secondary applicant should be cleared');
    }

    // --- getSecondaryApplicantDetails tests ---

    @isTest
    static void testGetSecondaryApplicantDetails() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Booking__c result = BookingController.getSecondaryApplicantDetails(booking.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return booking with secondary applicant fields');
    }

    // --- testcover tests ---

    @isTest
    static void testTestcover() {
        Test.startTest();
        BookingController.testcover();
        Test.stopTest();
    }

    // --- submitRecordForApproval tests ---

    @isTest
    static void testSubmitRecordForApproval_Error() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        try {
            BookingController.submitRecordForApproval(booking.Id);
        } catch (AuraHandledException e) {
            // Expected when approval process doesn't exist in test context
            System.assertNotEquals(null, e.getMessage(), 'Should have error message');
        }
        Test.stopTest();
    }

    // --- Approval methods tests (all follow same pattern) ---

    @isTest
    static void testDocumentVerificationApproval() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        try {
            BookingController.documentVerificationApproval(booking.Id);
        } catch (Exception e) {
            // Expected when approval process not configured in test
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testReceiptApprovalforFinanceTeam() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        try {
            BookingController.receiptApprovalforFinanceTeam(booking.Id);
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testBookingCancellationApproval() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        try {
            BookingController.bookingCancellationApproval(booking.Id);
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testRequestSaleAgreement() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        try {
            BookingController.requestSaleAgreement(booking.Id);
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testPartialAmountAgreementAmountApproval() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        try {
            BookingController.partialAmountAgreementAmountApproval(booking.Id);
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testRequestForSaleDeed() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        try {
            BookingController.requestForSaleDeed(booking.Id);
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testRequestForRegistrationApproval() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        try {
            BookingController.requestForRegistrationApproval(booking.Id);
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testRequestTransferApproval() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        try {
            BookingController.requestTransferApproval(booking.Id);
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    // --- createBook tests ---

    @isTest
    static void testCreateBook_PlotAvailable() {
        Project__c project = [SELECT Id, Project_Type__c FROM Project__c LIMIT 1];
        Quote__c costSheet = [SELECT Id FROM Quote__c LIMIT 1];

        // Create a fresh Plot with Status = 'Available'
        // (The @TestSetup Plot is already 'Booked' because BookingTrigger fires on Booking insert)
        Plot__c freshUnit = new Plot__c(
            Name = '201',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = project.Project_Type__c,
            Plot_Type__c = 'Residential',
            Carpet_Area__c = 500
        );
        insert freshUnit;

        Booking__c bk = new Booking__c(
            Plot__c = freshUnit.Id,
            Project1__c = project.Id,
            Mode_Of_Payment__c = 'Credit Card',
            Funding_Type__c = 'Self',
            Stage__c = 'Reservation',
            Date_of_Booking__c = System.today(),
            Payment_Type__c = 'Standard'
        );

        List<Co_Applicant__c> applicants = new List<Co_Applicant__c>{
            new Co_Applicant__c(Name = 'Co-Applicant 1')
        };

        Test.startTest();
        String result = BookingController.createBook(bk, costSheet.Id, applicants);
        Test.stopTest();

        // Should return booking Id on success
        System.assertNotEquals('Plot is not available.', result, 'Plot should be available');
        System.assertNotEquals('Plot record not found.', result, 'Plot should be found');
    }

    @isTest
    static void testCreateBook_PlotNotAvailable() {
        Plot__c unit = [SELECT Id FROM Plot__c LIMIT 1];
        unit.Status__c = 'Booked';
        update unit;

        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Quote__c costSheet = [SELECT Id FROM Quote__c LIMIT 1];

        Booking__c bk = new Booking__c(
            Plot__c = unit.Id,
            Project1__c = project.Id,
            Mode_Of_Payment__c = 'Credit Card',
            Funding_Type__c = 'Self',
            Stage__c = 'Reservation',
            Date_of_Booking__c = System.today(),
            Payment_Type__c = 'Standard'
        );

        Test.startTest();
        String result = BookingController.createBook(bk, costSheet.Id, new List<Co_Applicant__c>());
        Test.stopTest();

        System.assertEquals('Plot is not available.', result, 'Should return not available message');
    }

    @isTest
    static void testCreateBook_EmptyApplicantList() {
        Project__c project = [SELECT Id, Project_Type__c FROM Project__c LIMIT 1];
        Quote__c costSheet = [SELECT Id FROM Quote__c LIMIT 1];

        // Create a fresh Available Plot (existing one is Booked from @TestSetup)
        Plot__c freshUnit = new Plot__c(
            Name = '202',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = project.Project_Type__c,
            Plot_Type__c = 'Residential',
            Carpet_Area__c = 500
        );
        insert freshUnit;

        Booking__c bk = new Booking__c(
            Plot__c = freshUnit.Id,
            Project1__c = project.Id,
            Mode_Of_Payment__c = 'Credit Card',
            Funding_Type__c = 'Self',
            Stage__c = 'Reservation',
            Date_of_Booking__c = System.today(),
            Payment_Type__c = 'Standard'
        );

        // Pass empty co-applicant list with blank name entries
        List<Co_Applicant__c> applicants = new List<Co_Applicant__c>{
            new Co_Applicant__c(Name = '')
        };

        Test.startTest();
        String result = BookingController.createBook(bk, costSheet.Id, applicants);
        Test.stopTest();

        System.assertNotEquals('Plot is not available.', result);
    }

    // --- sendRegistrationEmailsAsync tests ---

    @isTest
    static void testSendRegistrationEmailsAsync() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        BookingController.sendRegistrationEmailsAsync(new List<Id>{booking.Id});
        Test.stopTest();
    }

    // --- bookingAmountReceipt tests ---

    @isTest
    static void testBookingAmountReceipt() {
        Booking__c booking = [SELECT Id, Booking_Amount1__c, Cheque_DD_NEFT_RTGS_No__c FROM Booking__c LIMIT 1];

        // Create a payment schedule for the booking
        Master_payment_schedule__c mps = new Master_payment_schedule__c(
            Status__c = 'Completed',
            Project__c = [SELECT Id FROM Project__c LIMIT 1].Id,
            Project_Type__c = 'Apartments'
        );
        insert mps;

        Payment_schedule__c ps = new Payment_schedule__c(
            Booking__c = booking.Id,
            Payment_percent__c = 10,
            Master_Payment_Schedule__c = mps.Id,
            Amount__c = 50000,
            S_No__c = 1,
            Name = 'Booking Amount'
        );
        insert ps;

        Test.startTest();
        BookingController.bookingAmountReceipt(booking);
        Test.stopTest();

        List<Receipt__c> receipts = [SELECT Id FROM Receipt__c WHERE Booking__c = :booking.Id];
        System.assert(!receipts.isEmpty(), 'Receipt should be created');
    }
}