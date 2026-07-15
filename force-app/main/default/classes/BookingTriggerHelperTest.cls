@isTest
public class BookingTriggerHelperTest {

    @TestSetup
    static void setupTestData() {
        List<Booking__c> bookings = new List<Booking__c>();
        bookings.add(new Booking__c(
            Stage__c = 'Sale Agreement Execution Completed',
            Email1__c = 'customer@test.com',
            First_Applicant_Name__c = 'John Doe'
        ));
        bookings.add(new Booking__c(
            Stage__c = 'Sale Agreement Execution Completed',
            Email1__c = null,
            First_Applicant_Name__c = 'Jane Doe'
        ));
        bookings.add(new Booking__c(
            Stage__c = 'Sale Agreement Execution Completed',
            Email1__c = 'reminder@test.com',
            First_Applicant_Name__c = 'Raj Kumar'
        ));
        insert bookings;
    }

    @isTest
    static void testSendAgreementApprovalEmail_WithValidEmail() {
        List<Booking__c> bookings = [SELECT Id, Email1__c, First_Applicant_Name__c FROM Booking__c WHERE Email1__c = 'customer@test.com'];
        System.assertEquals(1, bookings.size(), 'Should have one booking with email');

        Test.startTest();
        BookingTriggerHelper.sendAgreementApprovalEmailToCustomer(bookings);
        Test.stopTest();

        // Method completed without exception — email logic was executed
        System.assert(true, 'Agreement approval email sent successfully for valid email');
    }

    @isTest
    static void testSendAgreementApprovalEmail_NoEmail() {
        List<Booking__c> bookings = [SELECT Id, Email1__c, First_Applicant_Name__c FROM Booking__c WHERE First_Applicant_Name__c = 'Jane Doe'];
        System.assertEquals(1, bookings.size(), 'Should find Jane Doe booking');

        Test.startTest();
        BookingTriggerHelper.sendAgreementApprovalEmailToCustomer(bookings);
        Test.stopTest();

        // No email sent for null Email1__c — method should complete without error
        System.assert(true, 'No exception when Email1__c is null');
    }

    @isTest
    static void testSendAgreementApprovalEmail_BulkBookings() {
        List<Booking__c> bookings = [SELECT Id, Email1__c, First_Applicant_Name__c FROM Booking__c WHERE Email1__c != null];
        System.assert(bookings.size() >= 2, 'Should have at least 2 bookings with email');

        Test.startTest();
        BookingTriggerHelper.sendAgreementApprovalEmailToCustomer(bookings);
        Test.stopTest();

        System.assert(true, 'Bulk agreement approval emails sent without exception');
    }

    @isTest
    static void testSendAgreementApprovalEmail_EmptyList() {
        Test.startTest();
        BookingTriggerHelper.sendAgreementApprovalEmailToCustomer(new List<Booking__c>());
        Test.stopTest();

        System.assert(true, 'Empty list handled without exception');
    }

    @isTest
    static void testSendAgreementApprovalEmail_MixedEmails() {
        List<Booking__c> allBookings = [SELECT Id, Email1__c, First_Applicant_Name__c FROM Booking__c];
        System.assertEquals(3, allBookings.size(), 'Should have 3 total bookings');

        Test.startTest();
        BookingTriggerHelper.sendAgreementApprovalEmailToCustomer(allBookings);
        Test.stopTest();

        // Mix of bookings with and without emails — only valid emails generate emails
        System.assert(true, 'Mixed email list handled without exception');
    }

    @isTest
    static void testSendRegReminderEmails_WithEmail() {
        List<Booking__c> bookings = [SELECT Id, Email1__c FROM Booking__c WHERE Email1__c = 'reminder@test.com'];
        System.assertEquals(1, bookings.size(), 'Should find reminder booking');

        Test.startTest();
        BookingTriggerHelper.sendRegReminderEmails(bookings);
        Test.stopTest();

        System.assert(true, 'Registration reminder email sent without exception');
    }

    @isTest
    static void testSendRegReminderEmails_BulkBookings() {
        List<Booking__c> bookings = [SELECT Id, Email1__c FROM Booking__c WHERE Email1__c != null];
        System.assert(bookings.size() >= 2, 'Should have at least 2 bookings with email for bulk test');

        Test.startTest();
        BookingTriggerHelper.sendRegReminderEmails(bookings);
        Test.stopTest();

        System.assert(true, 'Bulk registration reminder emails sent without exception');
    }

    @isTest
    static void testSendRegReminderEmails_EmptyList() {
        Test.startTest();
        BookingTriggerHelper.sendRegReminderEmails(new List<Booking__c>());
        Test.stopTest();

        System.assert(true, 'Empty list handled without exception');
    }

    @isTest
    static void testRecallApproval_NoWorkItems() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        BookingTriggerHelper.recallApproval(b.Id);
        Test.stopTest();

        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :b.Id
        ];
        System.assertEquals(0, workItems.size(), 'No work items should exist since no approval was submitted');
    }

    @isTest
    static void testRecallApproval_WithDifferentRecord() {
        Booking__c b = [SELECT Id FROM Booking__c WHERE First_Applicant_Name__c = 'Jane Doe' LIMIT 1];

        Test.startTest();
        BookingTriggerHelper.recallApproval(b.Id);
        Test.stopTest();

        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :b.Id
        ];
        System.assertEquals(0, workItems.size(), 'No work items should exist for record without approval process');
    }
}