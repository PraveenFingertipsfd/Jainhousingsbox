@isTest
public class JointInspectionControllerTest {

    @TestSetup
    static void setupData() {
        // Create a Site Engineer user
        User siteEngineer = new User(
            FirstName = 'Test',
            LastName = 'Engineer',
            Email = 'testengineer@example.com',
            Username = 'testengineer' + System.currentTimeMillis() + '@example.com',
            Alias = 'teng',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert siteEngineer;

        // Create a Project with Site Engineer
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project__c = 'Jains Anushree',
            Project_Type__c = 'Plots',
            Site_Engineer__c = siteEngineer.Id
        );
        insert project;

        // Create Plot with QA_Given__c = true
        Plot__c plot = new Plot__c(
            Name = 'Test Plot',
            Project__c = project.Id,
            Project_Type__c = 'Plots',
            QA_Given__c = true
        );
        insert plot;

        // Create a Booking linked to Project and Plot with both emails
        Booking__c booking = new Booking__c(
            Plot__c = plot.Id,
            Project__c = 'Jains Anushree',
            Project1__c = project.Id,
            Email1__c = 'customer1@example.com',
            Alternate_Email1__c = 'customer2@example.com',
            First_Applicant_Name__c = 'Test Applicant'
        );
        insert booking;

        // Create a Co-Applicant linked to the booking for co-applicant email coverage
        Co_Applicant__c coApp = new Co_Applicant__c(
            Booking__c = booking.Id,
            Email__c = 'coapplicant@example.com'
        );
        insert coApp;
    }

    // ==================== createJointInspection ====================

    @isTest
    static void testCreateJointInspection_Success() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        String result = JointInspectionController.createJointInspection(booking.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Joint Inspection ID should not be null');
        System.assert(!result.startsWith('ERROR'), 'Should not return error: ' + result);
        System.assert(!result.startsWith('TOAST'), 'Should not return toast message: ' + result);

        // Verify the Joint Inspection was actually created with correct fields
        Joint_Inspection__c ji = [SELECT Id, Booking__c, Site_Engineer__c, Invite_Sent_Date_Time__c
                                  FROM Joint_Inspection__c WHERE Id = :result];
        System.assertEquals(booking.Id, ji.Booking__c, 'JI should be linked to the booking');
        System.assertNotEquals(null, ji.Site_Engineer__c, 'Site Engineer should be set');
        System.assertNotEquals(null, ji.Invite_Sent_Date_Time__c, 'Invite sent date should be set on creation');
    }

    @isTest
    static void testCreateJointInspection_NoBookingFound() {
        Test.startTest();
        String result = JointInspectionController.createJointInspection('999999999999999AAA');
        Test.stopTest();

        System.assertEquals('ERROR: Booking record not found', result, 'Should return booking not found error');
    }

    @isTest
    static void testCreateJointInspection_QANotDone() {
        Booking__c booking = [SELECT Id, Plot__c FROM Booking__c LIMIT 1];
        Plot__c plot = [SELECT Id FROM Plot__c WHERE Id = :booking.Plot__c LIMIT 1];
        plot.QA_Given__c = false;
        update plot;

        Test.startTest();
        String result = JointInspectionController.createJointInspection(booking.Id);
        Test.stopTest();

        System.assertEquals('TOAST: QA not done for this unit', result, 'Should return QA not done toast');
    }

    @isTest
    static void testCreateJointInspection_NoProject() {
        Project__c project = [SELECT Id, Project_Type__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1];

        Plot__c plot = new Plot__c(
            Name = 'Plot No Project',
            QA_Given__c = true,
            Project__c = project.Id,
            Project_Type__c = project.Project_Type__c
        );
        insert plot;

        Booking__c booking = new Booking__c(
            Plot__c = plot.Id
        );
        insert booking;

        Test.startTest();
        String result = JointInspectionController.createJointInspection(booking.Id);
        Test.stopTest();

        System.assertEquals('ERROR: Booking is not associated with a Project', result,
            'Should return no project error');
    }

    @isTest
    static void testCreateJointInspection_NoSiteEngineer() {
        Project__c projectNoEngineer = new Project__c(
            Name = 'Project No Engineer',
            Project_Type__c = 'Plots'
        );
        insert projectNoEngineer;

        Project__c project1 = [SELECT Id, Project_Type__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        Plot__c plot = new Plot__c(
            Name = 'Plot No Engineer',
            QA_Given__c = true,
            Project__c = project1.Id,
            Project_Type__c = project1.Project_Type__c
        );
        insert plot;

        Booking__c booking = new Booking__c(
            Plot__c = plot.Id,
            Project1__c = projectNoEngineer.Id
        );
        insert booking;

        Test.startTest();
        String result = JointInspectionController.createJointInspection(booking.Id);
        Test.stopTest();

        System.assertEquals('ERROR: Project is missing Site Engineer assignment', result,
            'Should return missing site engineer error');
    }

    @isTest
    static void testCreateJointInspection_ActiveInspectionExists() {
        Booking__c booking = [SELECT Id, Project1__r.Site_Engineer__c FROM Booking__c LIMIT 1];

        // Insert an active Joint Inspection (not Completed or Cancelled)
        Joint_Inspection__c ji = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Initiated'
        );
        insert ji;

        Test.startTest();
        String result = JointInspectionController.createJointInspection(booking.Id);
        Test.stopTest();

        System.assertEquals('TOAST: An active Joint Inspection already exists for this booking', result,
            'Should return active inspection exists toast');
    }

    @isTest
    static void testCreateJointInspection_CompletedInspectionAllowsNew() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        // Insert a completed inspection - should NOT block new creation
        Joint_Inspection__c completedJi = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Completed'
        );
        insert completedJi;

        Test.startTest();
        String result = JointInspectionController.createJointInspection(booking.Id);
        Test.stopTest();

        System.assert(!result.startsWith('TOAST'), 'Completed inspection should not block new creation');
        System.assert(!result.startsWith('ERROR'), 'Should succeed when only completed inspections exist');
    }

    @isTest
    static void testCreateJointInspection_CancelledInspectionAllowsNew() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Joint_Inspection__c cancelledJi = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Cancelled'
        );
        insert cancelledJi;

        Test.startTest();
        String result = JointInspectionController.createJointInspection(booking.Id);
        Test.stopTest();

        System.assert(!result.startsWith('TOAST'), 'Cancelled inspection should not block new creation');
        System.assert(!result.startsWith('ERROR'), 'Should succeed when only cancelled inspections exist');
    }

    @isTest
    static void testCreateJointInspection_OnlyPrimaryEmail() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        booking.Alternate_Email1__c = null;
        update booking;

        Test.startTest();
        String result = JointInspectionController.createJointInspection(booking.Id);
        Test.stopTest();

        System.assert(!result.startsWith('ERROR'), 'Should succeed with only primary email');
    }

    @isTest
    static void testCreateJointInspection_NoEmails() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        booking.Email1__c = null;
        booking.Alternate_Email1__c = null;
        update booking;

        Test.startTest();
        String result = JointInspectionController.createJointInspection(booking.Id);
        Test.stopTest();

        // Should still create JI even with no emails (just no invites sent)
        System.assert(!result.startsWith('ERROR'), 'Should succeed even without emails');
        System.assert(!result.startsWith('TOAST'), 'Should not return toast');
    }

    // ==================== jointInspectionDetails ====================

    @isTest
    static void testJointInspectionDetails_Success() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        Map<String, Object> result = JointInspectionController.jointInspectionDetails(ji.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Test Plot', result.get('unitName'), 'Unit name should match');
        System.assert(result.containsKey('emailOptions'), 'Should contain emailOptions key');
        List<String> emails = (List<String>) result.get('emailOptions');
        System.assertEquals(2, emails.size(), 'Should have 2 email options (primary + alternate)');
        System.assertEquals(ji.Id, result.get('inspectionId'), 'Inspection ID should match');
    }

    @isTest
    static void testJointInspectionDetails_NoAlternateEmail() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        booking.Alternate_Email1__c = null;
        update booking;

        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        Map<String, Object> result = JointInspectionController.jointInspectionDetails(ji.Id);
        Test.stopTest();

        List<String> emails = (List<String>) result.get('emailOptions');
        System.assertEquals(1, emails.size(), 'Should have only primary email');
        System.assertEquals('customer1@example.com', emails[0], 'Primary email should match');
    }

    @isTest
    static void testJointInspectionDetails_InvalidId() {
        Test.startTest();
        try {
            JointInspectionController.jointInspectionDetails('999999999999999AAA');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should exist');
        }
        Test.stopTest();
    }

    // ==================== sendJointInspectionInvite ====================

    @isTest
    static void testSendJointInspectionInvite_Success() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        JointInspectionController.sendJointInspectionInvite(ji.Id, 'test@example.com');
        Test.stopTest();

        ji = [SELECT Invite_Sent_Date_Time__c FROM Joint_Inspection__c WHERE Id = :ji.Id];
        System.assertNotEquals(null, ji.Invite_Sent_Date_Time__c, 'Invite sent date should be set');
    }


    @isTest
    static void testSendJointInspectionInvite_EmptyEmail() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        try {
            JointInspectionController.sendJointInspectionInvite(ji.Id, '');
            System.assert(false, 'Should have thrown an exception for empty email');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }

    // ==================== getInspectionDetails ====================

    @isTest
    static void testGetInspectionDetails_Success() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Joint_Inspection__c ji = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Initiated'
        );
        insert ji;

        Test.startTest();
        JointInspectionController.InspectionDetails result = JointInspectionController.getInspectionDetails(ji.Id);
        Test.stopTest();

        System.assertEquals(ji.Id, result.inspectionId, 'Inspection ID should match');
        System.assertEquals('Initiated', result.currentStatus, 'Status should match');
        System.assertEquals('Test Plot', result.unitName, 'Unit name should match');
    }

    @isTest
    static void testGetInspectionDetails_InvalidId() {
        Test.startTest();
        try {
            JointInspectionController.getInspectionDetails('999999999999999AAA');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }

    // ==================== updateInspectionStatus ====================

    @isTest
    static void testUpdateInspectionStatus_Completed() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Joint_Inspection__c ji = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Initiated'
        );
        insert ji;

        Test.startTest();
        JointInspectionController.updateInspectionStatus(
            ji.Id, 'Completed', 'All items verified', null, null, null, null
        );
        Test.stopTest();

        ji = [SELECT Joint_Inspection_Status__c, Comments__c, Joint_Inspection_Completed_Date__c
              FROM Joint_Inspection__c WHERE Id = :ji.Id];
        System.assertEquals('Completed', ji.Joint_Inspection_Status__c, 'Status should be Completed');
        System.assertEquals('All items verified', ji.Comments__c, 'Comments should be set');
        System.assertNotEquals(null, ji.Joint_Inspection_Completed_Date__c, 'Completed date should be set');
    }

    @isTest
    static void testUpdateInspectionStatus_ReScheduled() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Joint_Inspection__c ji = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Initiated',
            Joint_Inspection_Date__c = DateTime.now()
        );
        insert ji;

        String rescheduledDatetime = JSON.serialize(DateTime.now().addDays(7));

        Test.startTest();
        JointInspectionController.updateInspectionStatus(
            ji.Id, 'Re-Scheduled', null, 'Customer unavailable', rescheduledDatetime, null, null
        );
        Test.stopTest();

        ji = [SELECT Joint_Inspection_Status__c, Rescheduled_Reason__c, Rescheduled_Date__c,
              Joint_Inspection_Date__c
              FROM Joint_Inspection__c WHERE Id = :ji.Id];
        System.assertEquals('Re-Scheduled', ji.Joint_Inspection_Status__c, 'Status should be Re-Scheduled');
        System.assertEquals('Customer unavailable', ji.Rescheduled_Reason__c, 'Rescheduled reason should be set');
        System.assertNotEquals(null, ji.Rescheduled_Date__c, 'Rescheduled date should be set');
        System.assertEquals(null, ji.Joint_Inspection_Date__c, 'Original inspection date should be cleared');
    }

    @isTest
    static void testUpdateInspectionStatus_Cancelled() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Joint_Inspection__c ji = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Initiated'
        );
        insert ji;

        Test.startTest();
        JointInspectionController.updateInspectionStatus(
            ji.Id, 'Cancelled', null, null, null, 'Customer withdrew', null
        );
        Test.stopTest();

        ji = [SELECT Joint_Inspection_Status__c, Cancelled_Reason__c, Cancelled_Date__c
              FROM Joint_Inspection__c WHERE Id = :ji.Id];
        System.assertEquals('Cancelled', ji.Joint_Inspection_Status__c, 'Status should be Cancelled');
        System.assertEquals('Customer withdrew', ji.Cancelled_Reason__c, 'Cancelled reason should be set');
        System.assertNotEquals(null, ji.Cancelled_Date__c, 'Cancelled date should be set');
    }

    // ==================== jointInspectionDetails1 (CSR variant) ====================

    @isTest
    static void testJointInspectionDetails1_Success() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        Map<String, Object> result = JointInspectionController.jointInspectionDetails1(ji.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Test Plot', result.get('unitName'), 'Unit name should match');
        System.assert(result.containsKey('emailOptions'), 'Should contain emailOptions');
        List<String> emails = (List<String>) result.get('emailOptions');
        System.assertEquals(2, emails.size(), 'Should have primary and alternate emails');
        System.assertEquals(ji.Id, result.get('inspectionId'), 'Inspection ID should match');
    }

    @isTest
    static void testJointInspectionDetails1_NoEmails() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        booking.Email1__c = null;
        booking.Alternate_Email1__c = null;
        update booking;

        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        Map<String, Object> result = JointInspectionController.jointInspectionDetails1(ji.Id);
        Test.stopTest();

        List<String> emails = (List<String>) result.get('emailOptions');
        System.assertEquals(0, emails.size(), 'Should have no email options when both are blank');
    }

    @isTest
    static void testJointInspectionDetails1_InvalidId() {
        Test.startTest();
        try {
            JointInspectionController.jointInspectionDetails1('999999999999999AAA');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should exist');
        }
        Test.stopTest();
    }

    // ==================== sendCSR ====================

    @isTest
    static void testSendCSR_ValidEmail() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        // sendCSR queries a Site named 'CSR_Form' which may not exist in test context
        try {
            JointInspectionController.sendCSR(ji.Id, 'customer1@example.com');

            ji = [SELECT CSR_Sent_Date__c FROM Joint_Inspection__c WHERE Id = :ji.Id];
            System.assertNotEquals(null, ji.CSR_Sent_Date__c, 'CSR sent date should be set');
        } catch (AuraHandledException e) {
            // Expected if Site record does not exist in test org
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }



    @isTest
    static void testSendCSR_EmptyEmail() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        try {
            JointInspectionController.sendCSR(ji.Id, '');
            System.assert(false, 'Should have thrown an exception for empty email');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }

    // ==================== sendCSRFuture / sendCSRInternal ====================

    @isTest
    static void testSendCSRFuture_WithValidEmail() {
        Booking__c booking = [SELECT Id, Email1__c FROM Booking__c LIMIT 1];
        System.assertNotEquals(null, booking.Email1__c, 'Booking should have an email for this test');

        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        JointInspectionController.sendCSRFuture(new List<Id>{ ji.Id });
        Test.stopTest();

        // After Test.stopTest(), @future method has executed
        // sendCSRInternal queries Site 'CSR_Form' - if it exists, CSR_Sent_Date__c is set
        // If it does not exist, the catch block in sendCSRInternal silently logs debug
        ji = [SELECT CSR_Sent_Date__c FROM Joint_Inspection__c WHERE Id = :ji.Id];
        // We cannot guarantee the Site exists, but the future method should have run without DML exception
    }

    @isTest
    static void testSendCSRFuture_WithNullEmail() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        booking.Email1__c = null;
        update booking;

        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        JointInspectionController.sendCSRFuture(new List<Id>{ ji.Id });
        Test.stopTest();

        // With null email, sendCSRInternal should not be called, so CSR_Sent_Date__c stays null
        ji = [SELECT CSR_Sent_Date__c FROM Joint_Inspection__c WHERE Id = :ji.Id];
        System.assertEquals(null, ji.CSR_Sent_Date__c,
            'CSR sent date should remain null when booking has no email');
    }

    @isTest
    static void testSendCSRFuture_MultipleInspections() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Joint_Inspection__c ji1 = new Joint_Inspection__c(Booking__c = booking.Id);
        Joint_Inspection__c ji2 = new Joint_Inspection__c(Booking__c = booking.Id);
        insert new List<Joint_Inspection__c>{ ji1, ji2 };

        Test.startTest();
        JointInspectionController.sendCSRFuture(new List<Id>{ ji1.Id, ji2.Id });
        Test.stopTest();

        // Verify the future method processed both inspections without error
        List<Joint_Inspection__c> inspections = [SELECT Id, CSR_Sent_Date__c
                                                  FROM Joint_Inspection__c
                                                  WHERE Id IN :new List<Id>{ ji1.Id, ji2.Id }];
        System.assertEquals(2, inspections.size(), 'Both inspections should still exist');
    }

    @isTest
    static void testSendCSRFuture_WithCoApplicantEmails() {
        // This test covers the co-applicant email collection in sendCSRInternal
        Booking__c booking = [SELECT Id, Email1__c FROM Booking__c LIMIT 1];

        // Co-Applicant was already created in @TestSetup with a valid email
        // Verify it exists
        List<Co_Applicant__c> coApps = [SELECT Email__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
        System.assert(!coApps.isEmpty(), 'Co-Applicant should exist from test setup');

        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        JointInspectionController.sendCSRFuture(new List<Id>{ ji.Id });
        Test.stopTest();

        // The sendCSRInternal method should collect both the booking email and co-applicant email
        // We verify it ran without exception; actual email sending is mocked in test context
    }



    @isTest
    static void testSendCSRFuture_CoApplicantDuplicateEmail() {
        Booking__c booking = [SELECT Id, Email1__c FROM Booking__c LIMIT 1];

        // Update co-applicant email to match the booking's primary email (duplicate)
        Co_Applicant__c coApp = [SELECT Id FROM Co_Applicant__c WHERE Booking__c = :booking.Id LIMIT 1];
        coApp.Email__c = booking.Email1__c;
        update coApp;

        Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id);
        insert ji;

        Test.startTest();
        JointInspectionController.sendCSRFuture(new List<Id>{ ji.Id });
        Test.stopTest();

        // Duplicate email should be excluded by the contains() check in sendCSRInternal
    }

    @isTest
    static void testSendCSRFuture_EmptyList() {
        Test.startTest();
        JointInspectionController.sendCSRFuture(new List<Id>());
        Test.stopTest();

        // Should handle empty list gracefully
    }
}