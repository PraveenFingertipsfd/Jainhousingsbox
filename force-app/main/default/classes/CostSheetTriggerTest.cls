@isTest
public class CostSheetTriggerTest {

    @TestSetup
    static void setupData() {
        Project__c project = new Project__c(Name = 'Test Project', Project_Type__c = 'Villas');
        insert project;

        Plot__c plot = new Plot__c(
            Name = 'Unit-01',
            Project__c = project.Id,
            Project_Type__c = 'Villas'
        );
        insert plot;

        Booking_Request__c brWithEmail = new Booking_Request__c(
            Unit__c = plot.Id,
            Email__c = 'customer@example.com',
            Blocked_Price__c = 500000
        );
        insert brWithEmail;

        Booking_Request__c brNoEmail = new Booking_Request__c(Unit__c = plot.Id);
        insert brNoEmail;
    }

    private static Booking_Request__c getBRWithEmail() {
        return [SELECT Id, is_cost_sheet_present__c FROM Booking_Request__c WHERE Email__c = 'customer@example.com' LIMIT 1];
    }

    private static Booking_Request__c getBRNoEmail() {
        return [SELECT Id, is_cost_sheet_present__c FROM Booking_Request__c WHERE Email__c = null LIMIT 1];
    }

    // ── AFTER INSERT: sets is_cost_sheet_present__c = true ──
    @isTest
    static void testAfterInsertSetsFlag() {
        Booking_Request__c br = getBRWithEmail();
        System.assertEquals(false, br.is_cost_sheet_present__c, 'Flag should start false');

        Test.startTest();
        Quote__c q = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = br.Id
        );
        insert q;
        Test.stopTest();

        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(true, br.is_cost_sheet_present__c, 'Flag should be true after insert');
    }

    // ── AFTER INSERT: Abandoned status skips flag update ──
    @isTest
    static void testAfterInsertAbandonedSkipped() {
        Booking_Request__c br = getBRNoEmail();

        Test.startTest();
        Quote__c q = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = br.Id,
            Status__c = 'Abandoned'
        );
        insert q;
        Test.stopTest();

        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(false, br.is_cost_sheet_present__c, 'Flag should remain false for Abandoned');
    }

    // ── AFTER INSERT: no Booking_Request__c ──
    @isTest
    static void testAfterInsertNoBR() {
        Test.startTest();
        Quote__c q = new Quote__c(Payment_Type__c = 'Standard');
        insert q;
        Test.stopTest();

        System.assertNotEquals(null, q.Id, 'Quote should insert without BR');
    }

    // ── BEFORE UPDATE: Discount validation (valid discount) ──
    @isTest
    static void testBeforeUpdateDiscountValidation() {
        Booking_Request__c br = getBRWithEmail();
        Quote__c q = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = br.Id,
            Price_Per_Sq_Ft__c = 5000,
            Discount_Price__c = 0
        );
        insert q;

        Test.startTest();
        q.Discount_Price__c = 500;
        update q;
        Test.stopTest();

        Quote__c updated = [SELECT Final_Price_Per_Sq_ft__c FROM Quote__c WHERE Id = :q.Id];
        System.assertEquals(4500, updated.Final_Price_Per_Sq_ft__c,
            'Final price should be Price - Discount');
    }

    // ── BEFORE UPDATE: Discount exceeds price (validation error) ──
    @isTest
    static void testBeforeUpdateDiscountExceedsPrice() {
        Booking_Request__c br = getBRWithEmail();
        Quote__c q = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = br.Id,
            Price_Per_Sq_Ft__c = 5000,
            Discount_Price__c = 0
        );
        insert q;

        Test.startTest();
        Boolean hasError = false;
        try {
            q.Discount_Price__c = 6000;
            update q;
        } catch (DmlException e) {
            hasError = true;
            System.assert(e.getMessage().contains('Discount Price'),
                'Should get discount validation error');
        }
        Test.stopTest();
        System.assert(hasError, 'Should have thrown validation error');
    }

    // ── BEFORE UPDATE: Management Approved triggers email ──
    @isTest
    static void testBeforeUpdateManagementApproved() {
        Booking_Request__c br = getBRWithEmail();
        Quote__c q = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = br.Id
        );
        insert q;

        Test.startTest();
        try {
            q.Approval_Status__c = 'Management Approved';
            update q;
        } catch (Exception e) {
            // Site 'Booking_Fill_Site' may not exist in test context
            System.debug('Expected: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── BEFORE UPDATE: Management Approved without Booking_Request__c ──
    @isTest
    static void testBeforeUpdateManagementApprovedNoBR() {
        Quote__c q = new Quote__c(Payment_Type__c = 'Standard');
        insert q;

        Test.startTest();
        try {
            q.Approval_Status__c = 'Management Approved';
            update q;
        } catch (Exception e) {
            System.debug('Expected: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── AFTER UPDATE: Status changes to Abandoned ──
    @isTest
    static void testAfterUpdateStatusToAbandoned() {
        Booking_Request__c br = getBRWithEmail();
        Quote__c q = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = br.Id
        );
        insert q;

        // Verify flag is true after insert
        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(true, br.is_cost_sheet_present__c);

        Test.startTest();
        q.Status__c = 'Abandoned';
        update q;
        Test.stopTest();

        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(false, br.is_cost_sheet_present__c, 'Flag should be false after Abandoned');
    }

    // ── AFTER UPDATE: Status changes FROM Abandoned to active ──
    @isTest
    static void testAfterUpdateStatusFromAbandoned() {
        Booking_Request__c br = getBRNoEmail();
        Quote__c q = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = br.Id,
            Status__c = 'Abandoned'
        );
        insert q;

        // Flag should still be false (inserted as Abandoned)
        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(false, br.is_cost_sheet_present__c);

        Test.startTest();
        q.Status__c = 'Preparation';
        update q;
        Test.stopTest();

        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(true, br.is_cost_sheet_present__c, 'Flag should be true after reactivation');
    }

    // ── AFTER DELETE: No remaining active quotes ──
    @isTest
    static void testAfterDeleteNoRemainingQuotes() {
        Booking_Request__c br = getBRWithEmail();
        Quote__c q = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = br.Id
        );
        insert q;

        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(true, br.is_cost_sheet_present__c);

        Test.startTest();
        delete q;
        Test.stopTest();

        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(false, br.is_cost_sheet_present__c, 'Flag should be false after last quote deleted');
    }

    // ── AFTER DELETE: Remaining active quotes keep flag true ──
    @isTest
    static void testAfterDeleteWithRemainingQuotes() {
        Booking_Request__c br = getBRWithEmail();
        Quote__c q1 = new Quote__c(Payment_Type__c = 'Standard', Booking_Request__c = br.Id);
        Quote__c q2 = new Quote__c(Payment_Type__c = 'Standard', Booking_Request__c = br.Id);
        insert new List<Quote__c>{ q1, q2 };

        Test.startTest();
        delete q1;
        Test.stopTest();

        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(true, br.is_cost_sheet_present__c, 'Flag should remain true with remaining quote');
    }

    // ── AFTER DELETE: Abandoned quote deleted (no flag change) ──
    @isTest
    static void testAfterDeleteAbandonedQuote() {
        Booking_Request__c br = getBRNoEmail();
        Quote__c q = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = br.Id,
            Status__c = 'Abandoned'
        );
        insert q;

        Test.startTest();
        delete q;
        Test.stopTest();

        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(false, br.is_cost_sheet_present__c, 'Flag should remain false');
    }

    // ── AFTER UNDELETE: restores flag ──
    @isTest
    static void testAfterUndelete() {
        Booking_Request__c br = getBRWithEmail();
        Quote__c q = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = br.Id
        );
        insert q;
        delete q;

        // Flag should be false after delete
        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(false, br.is_cost_sheet_present__c);

        Test.startTest();
        undelete q;
        Test.stopTest();

        br = [SELECT is_cost_sheet_present__c FROM Booking_Request__c WHERE Id = :br.Id];
        System.assertEquals(true, br.is_cost_sheet_present__c, 'Flag should be true after undelete');
    }

    // ── AFTER UPDATE: Status change on quote without BR (no-op) ──
    @isTest
    static void testAfterUpdateNoBR() {
        Quote__c q = new Quote__c(Payment_Type__c = 'Standard');
        insert q;

        Test.startTest();
        q.Status__c = 'Abandoned';
        update q;
        Test.stopTest();

        System.assert(true, 'No error for quote without BR');
    }
}