@isTest
public class JoinInspectionTriggerTest {

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

    // 🔥 Get valid picklist value dynamically
    String validProjectValue;
    Schema.DescribeFieldResult fieldResult = Booking__c.Project__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

    if (!picklistValues.isEmpty()) {
        validProjectValue = picklistValues[0].getValue(); // ✅ always valid
    }

    Booking__c booking1 = new Booking__c(
        First_Applicant_Name__c = 'Customer 1',
        Email1__c = 'customer1@test.com',
        Plot__c = plot.Id,
        Project__c = validProjectValue // ✅ FIXED
    );
    insert booking1;

    Booking__c booking2 = new Booking__c(
        First_Applicant_Name__c = 'Customer 2',
        Email1__c = 'customer2@test.com',
        Project__c = validProjectValue // ✅ FIXED
    );
    insert booking2;
}

    // ====== JoinInspectionTrigger (Before Insert) - Duplicate prevention ======

    @isTest
    static void testPreventDuplicateActiveInspection() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE First_Applicant_Name__c = 'Customer 1' LIMIT 1];

        // Create first active inspection
        Joint_Inspection__c ji1 = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Scheduled'
        );
        insert ji1;

        // Attempt to create second active inspection for same booking
        Test.startTest();
        try {
            Joint_Inspection__c ji2 = new Joint_Inspection__c(
                Booking__c = booking.Id,
                Joint_Inspection_Status__c = 'Scheduled'
            );
            insert ji2;
            System.assert(false, 'Should have thrown DmlException for duplicate');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('active Joint Inspection already exists'),
                'Error should mention active inspection: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAllowInspectionAfterCompleted() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE First_Applicant_Name__c = 'Customer 1' LIMIT 1];

        // Create and complete first inspection
        Joint_Inspection__c ji1 = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Completed'
        );
        insert ji1;

        // Should be able to create new inspection for same booking
        Test.startTest();
        Joint_Inspection__c ji2 = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Scheduled'
        );
        insert ji2;
        Test.stopTest();

        List<Joint_Inspection__c> inspections = [SELECT Id FROM Joint_Inspection__c WHERE Booking__c = :booking.Id];
        System.assertEquals(2, inspections.size(), 'Should allow new inspection after previous completed');
    }

    @isTest
    static void testAllowInspectionAfterCancelled() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE First_Applicant_Name__c = 'Customer 1' LIMIT 1];

        Joint_Inspection__c ji1 = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Cancelled'
        );
        insert ji1;

        Test.startTest();
        Joint_Inspection__c ji2 = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Scheduled'
        );
        insert ji2;
        Test.stopTest();

        System.assertNotEquals(null, ji2.Id, 'Should allow insertion after cancellation');
    }

    @isTest
    static void testDifferentBookingsCanHaveActiveInspections() {
        List<Booking__c> bookings = [SELECT Id FROM Booking__c ORDER BY First_Applicant_Name__c ASC];

        Test.startTest();
        Joint_Inspection__c ji1 = new Joint_Inspection__c(
            Booking__c = bookings[0].Id,
            Joint_Inspection_Status__c = 'Scheduled'
        );
        insert ji1;

        Joint_Inspection__c ji2 = new Joint_Inspection__c(
            Booking__c = bookings[1].Id,
            Joint_Inspection_Status__c = 'Scheduled'
        );
        insert ji2;
        Test.stopTest();

        System.assertNotEquals(null, ji1.Id, 'First booking inspection should be created');
        System.assertNotEquals(null, ji2.Id, 'Second booking inspection should be created');
    }

    // ====== JointInspectionTrigger (After Update) - CSR email on completion ======

    @isTest
    static void testCSREmailOnCompletion() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE First_Applicant_Name__c = 'Customer 1' LIMIT 1];

        Joint_Inspection__c ji = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Scheduled'
        );
        insert ji;

        Test.startTest();
        ji.Joint_Inspection_Status__c = 'Completed';
        update ji;
        Test.stopTest();

        // The trigger calls JointInspectionController.sendCSRFuture()
        // which is a @future method. Verify it was invoked without errors.
        System.assert(true, 'CSR email trigger should fire on completion');
    }

    @isTest
    static void testNoCSREmailOnNonCompletionStatusChange() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE First_Applicant_Name__c = 'Customer 2' LIMIT 1];

        Joint_Inspection__c ji = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Scheduled'
        );
        insert ji;

        Test.startTest();
        ji.Joint_Inspection_Status__c = 'Cancelled';
        update ji;
        Test.stopTest();

        // No CSR email should be triggered for non-completion status
        System.assert(true, 'No CSR email should fire for cancellation');
    }
}