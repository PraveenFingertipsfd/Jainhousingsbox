@isTest
private class CostSheetControllerTest {

    @TestSetup
    static void setupTestData() {
        // Project with master payment schedules
        Project__c project = new Project__c(Name = 'Test Project', Project_Type__c = 'Villas');
        insert project;

        // Master payment schedules with varied statuses
        List<Master_payment_schedule__c> mpsList = new List<Master_payment_schedule__c>();
        for (Integer i = 1; i <= 3; i++) {
            mpsList.add(new Master_payment_schedule__c(
                Project__c = project.Id,
                Name = 'Schedule ' + i,
                S_No__c = i,
                Payment_Percent__c = 10 * i,
                Project_Type__c = 'Villas',
                Status__c = (i == 1 ? 'Completed' : 'Not Started'),
                Due_Date__c = Date.today().addDays(30 * i)
            ));
        }
        insert mpsList;

        // Plot / Unit
        Plot__c plot = new Plot__c(
            Name = 'Unit-01',
            Project__c = project.Id,
            Project_Type__c = 'Villas'
        );
        insert plot;

        // Booking Request with email
        Booking_Request__c brWithEmail = new Booking_Request__c(
            Unit__c = plot.Id,
            Email__c = 'customer@example.com',
            Blocked_Price__c = 500000
        );
        insert brWithEmail;

        // Booking Request without email
        Booking_Request__c brNoEmail = new Booking_Request__c(
            Unit__c = plot.Id
        );
        insert brNoEmail;

        // Quote - Standard (linked to BR with email)
        Quote__c quoteStd = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = brWithEmail.Id
        );
        insert quoteStd;

        // Quote - Custom (linked to BR with email)
        Quote__c quoteCustom = new Quote__c(
            Payment_Type__c = 'Custom',
            Booking_Request__c = brWithEmail.Id
        );
        insert quoteCustom;

        // Quote with no booking request (for email failure path)
        Quote__c quoteNoBR = new Quote__c(
            Payment_Type__c = 'Standard'
        );
        insert quoteNoBR;

        // Quote linked to BR without email
        Quote__c quoteNoEmail = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = brNoEmail.Id
        );
        insert quoteNoEmail;
    }

    // ---- Helper methods ----
    private static Project__c getProject() {
        return [SELECT Id FROM Project__c LIMIT 1];
    }

    private static Plot__c getPlot() {
        return [SELECT Id FROM Plot__c LIMIT 1];
    }

    private static Booking_Request__c getBookingWithEmail() {
        return [SELECT Id, Unit__c FROM Booking_Request__c WHERE Email__c != null LIMIT 1];
    }

    private static Booking_Request__c getBookingWithoutEmail() {
        return [SELECT Id, Unit__c FROM Booking_Request__c WHERE Email__c = null LIMIT 1];
    }

    private static Quote__c getQuoteByType(String payType) {
        return [SELECT Id, Payment_Type__c, Booking_Request__c
                FROM Quote__c
                WHERE Payment_Type__c = :payType AND Booking_Request__c != null
                LIMIT 1];
    }

    // ======================================================================
    // getUnitDetailsFromBookingRequest
    // ======================================================================
    @isTest
    static void testGetUnitDetailsFromBookingRequest() {
        Booking_Request__c br = getBookingWithEmail();
        Plot__c expectedPlot = getPlot();

        Test.startTest();
        Plot__c result = CostSheetController.getUnitDetailsFromBookingRequest(br.Id);
        Test.stopTest();

        System.assertEquals(expectedPlot.Id, result.Id, 'Returned plot should match the booking request unit');
        System.assertNotEquals(null, result.Name, 'Plot name should be populated');
        System.assertNotEquals(null, result.Project__c, 'Project lookup should be populated');
    }

    // ======================================================================
    // insertQuote
    // ======================================================================
    @isTest
    static void testInsertQuote() {
        Quote__c quoteRec = new Quote__c(Payment_Type__c = 'Standard');

        Test.startTest();
        Id insertedId = CostSheetController.insertQuote(quoteRec);
        Test.stopTest();

        System.assertNotEquals(null, insertedId, 'Inserted quote should return a valid Id');
        Quote__c verify = [SELECT Id, Payment_Type__c FROM Quote__c WHERE Id = :insertedId];
        System.assertEquals('Standard', verify.Payment_Type__c, 'Payment type should persist');
    }

    // ======================================================================
    // getUnitFromBooking - explicit unitId branch
    // ======================================================================
    @isTest
    static void testGetUnitFromBookingWithUnitId() {
        Booking_Request__c br = getBookingWithEmail();
        Plot__c plot = getPlot();

        Test.startTest();
        CostSheetController.PlotWrapper result = CostSheetController.getUnitFromBooking(br.Id, plot.Id);
        Test.stopTest();

        System.assertEquals(plot.Id, result.plot.Id, 'Plot Id should match the explicit unitId');
        System.assertEquals(500000, result.blockedPrice, 'Blocked price should come from booking request');
        System.assertNotEquals(null, result.plot.Name, 'Plot name should be queried');
    }

    // ======================================================================
    // getUnitFromBooking - null unitId falls back to BR.Unit__c
    // ======================================================================
    @isTest
    static void testGetUnitFromBookingWithNullUnitId() {
        Booking_Request__c br = getBookingWithEmail();
        Plot__c expectedPlot = getPlot();

        Test.startTest();
        CostSheetController.PlotWrapper result = CostSheetController.getUnitFromBooking(br.Id, null);
        Test.stopTest();

        System.assertEquals(expectedPlot.Id, result.plot.Id, 'Should fall back to BR unit when unitId is null');
        System.assertEquals(500000, result.blockedPrice, 'Blocked price should be returned');
    }

    // ======================================================================
    // getUnitFromBooking - empty string unitId falls back to BR.Unit__c
    // ======================================================================
    @isTest
    static void testGetUnitFromBookingWithEmptyUnitId() {
        Booking_Request__c br = getBookingWithEmail();
        Plot__c expectedPlot = getPlot();

        Test.startTest();
        CostSheetController.PlotWrapper result = CostSheetController.getUnitFromBooking(br.Id, '');
        Test.stopTest();

        System.assertEquals(expectedPlot.Id, result.plot.Id, 'Should fall back to BR unit when unitId is empty string');
    }

    // ======================================================================
    // getPaymentSchedules (new method) - Standard
    // ======================================================================
    @isTest
    static void testGetPaymentSchedulesStandard() {
        Project__c project = getProject();

        Test.startTest();
        CostSheetController.databox db = CostSheetController.getPaymentSchedules('Standard', project.Id);
        Test.stopTest();

        System.assertNotEquals(null, db, 'Databox should not be null');
        System.assertNotEquals(null, db.payList, 'Pay list should not be null for Standard');
        System.assertEquals(3, db.payList.size(), 'Should return all 3 master payment schedules');
        System.assertEquals(0, db.paymentSum, 'Payment sum should be initialized to 0');
        System.assertEquals(0, db.totalPercent, 'Total percent should be initialized to 0');
        System.assertEquals(0, db.RecivedAmount, 'RecivedAmount should be initialized to 0');
        System.assertEquals(0, db.RecivedAmountTotal, 'RecivedAmountTotal should be initialized to 0');
        System.assertEquals(0, db.RecivedPercent, 'RecivedPercent should be initialized to 0');
        System.assertEquals(0, db.scheduledAmount, 'scheduledAmount should be initialized to 0');

        // Verify schedule data is populated from master
        for (Payment_schedule__c ps : db.payList) {
            System.assertNotEquals(null, ps.Name, 'Schedule name should be set from master');
            System.assertNotEquals(null, ps.Payment_percent__c, 'Payment percent should be set');
            System.assertNotEquals(null, ps.Master_Payment_Schedule__c, 'Master link should be set');
        }
    }

    // ======================================================================
    // getPaymentSchedules (new method) - Custom (same code path)
    // ======================================================================
    @isTest
    static void testGetPaymentSchedulesCustom() {
        Project__c project = getProject();

        Test.startTest();
        CostSheetController.databox db = CostSheetController.getPaymentSchedules('Custom', project.Id);
        Test.stopTest();

        System.assertNotEquals(null, db, 'Databox should not be null for Custom');
        System.assertEquals(3, db.payList.size(), 'Custom should also return master schedules');
        System.assertEquals(0, db.paymentSum, 'Payment sum should initialize to 0');
    }

    // ======================================================================
    // getPaymentSchedules1 - Standard branch
    // ======================================================================
    @isTest
    static void testGetPaymentSchedules1Standard() {
        Project__c project = getProject();

        Test.startTest();
        CostSheetController.databox db = CostSheetController.getPaymentSchedules1('Standard', project.Id);
        Test.stopTest();

        System.assertNotEquals(null, db, 'Databox should be returned');
        System.assertNotEquals(null, db.payList, 'Pay list should contain schedules');
        System.assertEquals(3, db.payList.size(), 'Standard should produce 3 payment schedule records');
        System.assertEquals(0, db.paymentSum, 'paymentSum should be 0');
        System.assertEquals(0, db.totalPercent, 'totalPercent should be 0');

        // Verify schedule data from master is populated
        Payment_schedule__c firstSchedule = db.payList[0];
        System.assertEquals('Completed', firstSchedule.status__c, 'First schedule status should be Completed');
        System.assertEquals(1, firstSchedule.S_No__c, 'First schedule S_No should be 1');
    }

    // ======================================================================
    // getPaymentSchedules1 - Custom with empty schedules list (else branch + null payList)
    // ======================================================================
    @isTest
    static void testGetPaymentSchedules1CustomEmpty() {
        Project__c project = getProject();

        Test.startTest();
        CostSheetController.databox db = CostSheetController.getPaymentSchedules1('Custom', project.Id);
        Test.stopTest();

        System.assertNotEquals(null, db, 'Databox should be returned for Custom');
        // Custom path with empty schedules list results in payList = null (size==0 check)
        System.assertEquals(null, db.payList, 'Custom with empty schedules should set payList to null');
        System.assertEquals(0, db.paymentSum, 'paymentSum should be 0');
        System.assertEquals(0, db.RecivedAmount, 'RecivedAmount should be 0');
    }

    // ======================================================================
    // getPaymentSchedules1 - unknown type hits else branch
    // ======================================================================
    @isTest
    static void testGetPaymentSchedules1ElseBranch() {
        Project__c project = getProject();

        Test.startTest();
        CostSheetController.databox db = CostSheetController.getPaymentSchedules1('Other', project.Id);
        Test.stopTest();

        System.assertNotEquals(null, db, 'Databox should be returned for Other type');
        System.assertEquals(null, db.payList, 'Other type with empty list should set payList to null');
        System.assertEquals(0, db.paymentSum, 'Payment sum initialized to 0');
        System.assertEquals(0, db.totalPercent, 'totalPercent initialized to 0');
        System.assertEquals(0, db.RecivedAmountTotal, 'RecivedAmountTotal initialized to 0');
    }

    // ======================================================================
    // insertSchedules - Standard branch
    // ======================================================================
    @isTest
    static void testInsertSchedulesStandard() {
        Quote__c quote = getQuoteByType('Standard');
        Master_payment_schedule__c mps = [SELECT Id FROM Master_payment_schedule__c LIMIT 1];

        List<Payment_schedule__c> payList = new List<Payment_schedule__c>();
        payList.add(new Payment_schedule__c(
            Name = 'Std Pay 1',
            Payment_Percent__c = 10,
            Payment_Due_Date__c = Date.today().addDays(30),
            Amount__c = 50000,
            Master_Payment_Schedule__c = mps.Id,
            Include_Interest__c = false,
            S_No__c = 1,
            Status__c = 'Completed'
        ));
        payList.add(new Payment_schedule__c(
            Name = 'Std Pay 2',
            Payment_Percent__c = 20,
            Payment_Due_Date__c = Date.today().addDays(60),
            Amount__c = 100000,
            Master_Payment_Schedule__c = mps.Id,
            Include_Interest__c = true,
            S_No__c = 2
        ));

        Test.startTest();
        CostSheetController.insertSchedules(payList, 150000, quote.Id);
        Test.stopTest();

        List<Payment_schedule__c> inserted = [SELECT Id, Name, Is_Custom__c, Status__c, S_No__c, Cost_Sheet__c
                                               FROM Payment_schedule__c
                                               WHERE Cost_Sheet__c = :quote.Id
                                               ORDER BY S_No__c];
        System.assertEquals(2, inserted.size(), 'Two standard schedules should be inserted');
        System.assertEquals(false, inserted[0].Is_Custom__c, 'Standard rows should have Is_Custom__c = false');
        System.assertEquals('Completed', inserted[0].Status__c, 'Completed status should carry over');
        System.assertEquals(1, inserted[0].S_No__c, 'S_No should be preserved');
        System.assertEquals(quote.Id, inserted[0].Cost_Sheet__c, 'Cost_Sheet__c should reference the quote');
    }

    // ======================================================================
    // insertSchedules - Custom branch (Is_Custom__c true vs false)
    // ======================================================================
    @isTest
    static void testInsertSchedulesCustom() {
        Quote__c quote = getQuoteByType('Custom');
        Master_payment_schedule__c mps = [SELECT Id FROM Master_payment_schedule__c LIMIT 1];

        List<Payment_schedule__c> payList = new List<Payment_schedule__c>();
        // Non-custom row (Is_Custom__c = false) -> should preserve Master_Payment_Schedule__c
        payList.add(new Payment_schedule__c(
            Name = 'Custom Pay 1',
            Payment_Percent__c = 25,
            Payment_Due_Date__c = Date.today().addDays(15),
            Amount__c = 75000,
            S_No__c = 1,
            Status__c = 'Completed',
            Is_Custom__c = false,
            Master_Payment_Schedule__c = mps.Id
        ));
        // Custom row (Is_Custom__c = true) -> should NOT set Master_Payment_Schedule__c
        payList.add(new Payment_schedule__c(
            Name = 'Custom Pay 2',
            Payment_Percent__c = 30,
            Payment_Due_Date__c = Date.today().addDays(45),
            Amount__c = 90000,
            S_No__c = 2,
            Is_Custom__c = true
        ));

        Test.startTest();
        CostSheetController.insertSchedules(payList, 165000, quote.Id);
        Test.stopTest();

        List<Payment_schedule__c> inserted = [SELECT Id, Name, Is_Custom__c, Master_Payment_Schedule__c, S_No__c, Status__c
                                               FROM Payment_schedule__c
                                               WHERE Cost_Sheet__c = :quote.Id
                                               ORDER BY S_No__c];
        System.assertEquals(2, inserted.size(), 'Two custom schedules should be inserted');
        // Non-custom row should have Master ref
        System.assertEquals(false, inserted[0].Is_Custom__c, 'First row should not be custom');
        System.assertEquals(mps.Id, inserted[0].Master_Payment_Schedule__c, 'Non-custom row should preserve Master ref');
        System.assertEquals('Completed', inserted[0].Status__c, 'Completed status should carry over for custom');
        // Custom row should have Is_Custom__c true and no Master ref
        System.assertEquals(true, inserted[1].Is_Custom__c, 'Second row should be custom');
        System.assertEquals(null, inserted[1].Master_Payment_Schedule__c, 'Custom row should not have Master ref');
    }

    // ======================================================================
    // insertSchedules1 - Standard branch
    // ======================================================================
    @isTest
    static void testInsertSchedules1Standard() {
        Quote__c quote = getQuoteByType('Standard');
        Master_payment_schedule__c mps = [SELECT Id FROM Master_payment_schedule__c LIMIT 1];

        List<Payment_schedule__c> payList = new List<Payment_schedule__c>{
            new Payment_schedule__c(
                Name = 'Test Payment',
                Payment_Percent__c = 10,
                Payment_Due_Date__c = Date.today(),
                Amount__c = 10000,
                Include_Interest__c = false,
                S_No__c = 1,
                Status__c = 'Completed',
                Master_Payment_Schedule__c = mps.Id
            ),
            new Payment_schedule__c(
                Name = 'Test Payment 2',
                Payment_Percent__c = 20,
                Payment_Due_Date__c = Date.today().addDays(30),
                Amount__c = 20000,
                Include_Interest__c = true,
                S_No__c = 2,
                Master_Payment_Schedule__c = mps.Id
            )
        };

        Test.startTest();
        CostSheetController.insertSchedules1(payList, 50000, quote.Id);
        Test.stopTest();

        List<Payment_schedule__c> inserted = [SELECT Id, Name, Cost_Sheet__c, Status__c, S_No__c
                                               FROM Payment_schedule__c
                                               WHERE Cost_Sheet__c = :quote.Id
                                               ORDER BY S_No__c];
        System.assertEquals(2, inserted.size(), 'Standard payment schedules should be inserted');
        System.assertEquals('Completed', inserted[0].Status__c, 'First schedule should be Completed');
        System.assertEquals(quote.Id, inserted[0].Cost_Sheet__c, 'Cost sheet reference should be set');
    }

    // ======================================================================
    // insertSchedules1 - Custom branch (auto-incrementing S_No)
    // ======================================================================
    @isTest
    static void testInsertSchedules1Custom() {
        Quote__c quote = getQuoteByType('Custom');

        List<Payment_schedule__c> payList = new List<Payment_schedule__c>{
            new Payment_schedule__c(
                Name = 'Custom Pay 1',
                Payment_Percent__c = 20,
                Payment_Due_Date__c = Date.today(),
                Amount__c = 20000,
                Status__c = 'Completed'
            ),
            new Payment_schedule__c(
                Name = 'Custom Pay 2',
                Payment_Percent__c = 30,
                Payment_Due_Date__c = Date.today().addDays(30),
                Amount__c = 30000
            )
        };

        Test.startTest();
        CostSheetController.insertSchedules1(payList, 100000, quote.Id);
        Test.stopTest();

        List<Payment_schedule__c> inserted = [SELECT Id, S_No__c, Name, Status__c
                                               FROM Payment_schedule__c
                                               WHERE Cost_Sheet__c = :quote.Id
                                               ORDER BY S_No__c];
        System.assertEquals(2, inserted.size(), 'Custom payment schedules should be inserted');
        System.assertEquals(1, inserted[0].S_No__c, 'First custom schedule should have S_No 1');
        System.assertEquals(2, inserted[1].S_No__c, 'Second custom schedule should have S_No 2');
        System.assertEquals('Completed', inserted[0].Status__c, 'Completed status should be set');
    }

    // ======================================================================
    // sendCostsheetEmailLink - success path
    // ======================================================================
    @isTest
    static void testSendCostsheetEmailLinkSuccess() {
        Quote__c quote = getQuoteByType('Standard');

        Test.startTest();
        Boolean result = CostSheetController.sendCostsheetEmailLink(quote.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Email should be sent successfully');
        Quote__c updated = [SELECT Email_Sent_Date_Time__c, Is_Form_Responded__c FROM Quote__c WHERE Id = :quote.Id];
        System.assertNotEquals(null, updated.Email_Sent_Date_Time__c, 'Email sent datetime should be set');
        System.assertEquals(false, updated.Is_Form_Responded__c, 'Form responded should be reset to false');
    }

    // ======================================================================
    // sendCostsheetEmailLink - no booking request (returns false)
    // ======================================================================
    @isTest
    static void testSendCostsheetEmailLinkNoBookingRequest() {
        Quote__c quoteNoBR = [SELECT Id FROM Quote__c WHERE Booking_Request__c = null LIMIT 1];

        Test.startTest();
        Boolean result = CostSheetController.sendCostsheetEmailLink(quoteNoBR.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false when no booking request');
        // Verify the quote was still updated with email timestamp
        Quote__c updated = [SELECT Email_Sent_Date_Time__c, Is_Form_Responded__c FROM Quote__c WHERE Id = :quoteNoBR.Id];
        System.assertNotEquals(null, updated.Email_Sent_Date_Time__c, 'Email sent datetime should still be set even on false return');
        System.assertEquals(false, updated.Is_Form_Responded__c, 'Is_Form_Responded should be set to false');
    }

    // ======================================================================
    // sendCostsheetEmailLink - no email on booking request
    // ======================================================================
    @isTest
    static void testSendCostsheetEmailLinkNoEmail() {
        Quote__c quoteNoEmail = [SELECT Id FROM Quote__c
                                  WHERE Booking_Request__r.Email__c = null
                                  AND Booking_Request__c != null
                                  LIMIT 1];

        Test.startTest();
        Boolean result = CostSheetController.sendCostsheetEmailLink(quoteNoEmail.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false when booking request has no email');
    }

    // ======================================================================
    // abandonCostSheet - success (no approval process active)
    // ======================================================================
    @isTest
    static void testAbandonCostSheetSuccess() {
        Quote__c quote = getQuoteByType('Standard');

        Test.startTest();
        CostSheetController.Result res = CostSheetController.abandonCostSheet(quote.Id);
        Test.stopTest();

        System.assertEquals(true, res.isSuccess, 'Abandon should succeed');
        System.assertEquals('', res.errorMessage, 'Error message should be empty on success');
        Quote__c updated = [SELECT Status__c, Cost_Sheet_Abandoned_Date__c FROM Quote__c WHERE Id = :quote.Id];
        System.assertEquals('Abandoned', updated.Status__c, 'Quote status should be Abandoned');
        System.assertNotEquals(null, updated.Cost_Sheet_Abandoned_Date__c, 'Abandoned date should be set');
    }

    // ======================================================================
    // abandonCostSheet - null Id triggers exception / catch block
    // ======================================================================
    @isTest
    static void testAbandonCostSheetException() {
        Test.startTest();
        CostSheetController.Result res = CostSheetController.abandonCostSheet(null);
        Test.stopTest();

        System.assertEquals(false, res.isSuccess, 'Should fail for null Id');
        System.assertNotEquals('', res.errorMessage, 'Error message should be populated');
        System.assert(res.errorMessage.length() > 0, 'Error message should have content describing the failure');
    }

    // ======================================================================
    // abandonCostSheet - verify Status__c and date fields are set correctly
    // ======================================================================
    @isTest
    static void testAbandonCostSheetSetsFieldsCorrectly() {
        Quote__c quote = getQuoteByType('Custom');
        Datetime beforeAbandon = System.now();

        Test.startTest();
        CostSheetController.Result res = CostSheetController.abandonCostSheet(quote.Id);
        Test.stopTest();

        System.assertEquals(true, res.isSuccess, 'Abandon should succeed for Custom quote');
        Quote__c updated = [SELECT Status__c, Cost_Sheet_Abandoned_Date__c FROM Quote__c WHERE Id = :quote.Id];
        System.assertEquals('Abandoned', updated.Status__c, 'Status should be Abandoned');
        System.assertNotEquals(null, updated.Cost_Sheet_Abandoned_Date__c,
            'Abandoned date should be populated');
    }

    // ======================================================================
    // submitRecordForApproval - exercises try/catch (approval process may not exist in test)
    // ======================================================================
    @isTest
    static void testSubmitRecordForApproval() {
        Quote__c quote = getQuoteByType('Standard');

        Test.startTest();
        try {
            CostSheetController.submitRecordForApproval(quote.Id);
            // If an approval process named 'Cost_Sheet_Approval' exists, this succeeds
        } catch (Exception e) {
            // Expected if no approval process is configured in test context
            System.assert(
                e.getMessage().containsIgnoreCase('approval') || e.getMessage().containsIgnoreCase('Error'),
                'Should throw approval-related error: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ======================================================================
    // submitRecordForApproval - null recordId triggers exception
    // ======================================================================
    @isTest
    static void testSubmitRecordForApprovalNullId() {
        Test.startTest();
        try {
            CostSheetController.submitRecordForApproval(null);
            System.assert(false, 'Should have thrown an exception for null Id');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }

    // ======================================================================
    // Result wrapper defaults
    // ======================================================================
    @isTest
    static void testResultWrapperDefaults() {
        Test.startTest();
        CostSheetController.Result res = new CostSheetController.Result();
        Test.stopTest();

        System.assertEquals(false, res.isSuccess, 'Default isSuccess should be false');
        System.assertEquals('', res.errorMessage, 'Default errorMessage should be empty string');
    }

    // ======================================================================
    // databox wrapper - verify all AuraEnabled fields accessible
    // ======================================================================
    @isTest
    static void testDataboxWrapper() {
        Test.startTest();
        CostSheetController.databox db = new CostSheetController.databox();
        Test.stopTest();

        System.assertEquals(null, db.payList, 'payList default is null');
        System.assertEquals(null, db.MasterpayList, 'MasterpayList default is null');
        System.assertEquals(null, db.grandTotal, 'grandTotal default is null');
        System.assertEquals(null, db.paymentSum, 'paymentSum default is null');
        System.assertEquals(null, db.RecivedAmountTotal, 'RecivedAmountTotal default is null');
        System.assertEquals(null, db.totalPercent, 'totalPercent default is null');
        System.assertEquals(null, db.RecivedAmount, 'RecivedAmount default is null');
        System.assertEquals(null, db.objectName, 'objectName default is null');
        System.assertEquals(null, db.projectName, 'projectName default is null');
        System.assertEquals(null, db.flatNumber, 'flatNumber default is null');
        System.assertEquals(null, db.RecivedPercent, 'RecivedPercent default is null');
        System.assertEquals(null, db.ScheduledAmount, 'ScheduledAmount default is null');
        System.assertEquals(null, db.TotalOutStandingDueAmount, 'TotalOutStandingDueAmount default is null');
        System.assertEquals(null, db.TotalPaidAmount, 'TotalPaidAmount default is null');
    }

    // ======================================================================
    // PlotWrapper
    // ======================================================================
    @isTest
    static void testPlotWrapper() {
        Test.startTest();
        CostSheetController.PlotWrapper pw = new CostSheetController.PlotWrapper();
        Test.stopTest();

        System.assertEquals(null, pw.plot, 'plot default is null');
        System.assertEquals(null, pw.blockedPrice, 'blockedPrice default is null');
    }
}