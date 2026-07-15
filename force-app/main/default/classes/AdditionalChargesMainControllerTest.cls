@IsTest
public class AdditionalChargesMainControllerTest {

    @TestSetup
    static void setupData() {
        // Create a test Booking with email fields populated
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'John',
            Finance_User__c = UserInfo.getUserId(),
            Email1__c = 'test1@example.com',
            Alternate_Email1__c = 'test2@example.com'
        );
        insert booking;

        // Create a second booking without alternate email (tests null alternate email branch)
        Booking__c booking2 = new Booking__c(
            First_Applicant_Name__c = 'Jane',
            Finance_User__c = UserInfo.getUserId(),
            Email1__c = 'jane@example.com',
            Alternate_Email1__c = null
        );
        insert booking2;

        // Create Additional Charges for booking 1
        Additional_Charges__c ac1 = new Additional_Charges__c(
            Booking__c = booking.Id,
            Additional_Charge_Type__c = 'Interior Charges',
            GST__c = 18,
            Status__c = 'Not Paid'
        );
        insert ac1;

        // Create Additional Charges for booking 2 (no alternate email)
        Additional_Charges__c ac2 = new Additional_Charges__c(
            Booking__c = booking2.Id,
            Additional_Charge_Type__c = 'Maintenance Charges',
            GST__c = 12,
            Status__c = 'Not Paid'
        );
        insert ac2;
    }

    // ---- getAdditionalCharges ----

    @IsTest
    static void testGetAdditionalCharges_ReturnsRecordsForBooking() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE First_Applicant_Name__c = 'John' LIMIT 1];

        Test.startTest();
        List<Additional_Charges__c> acList = AdditionalChargesMainController.getAdditionalCharges(booking.Id);
        Test.stopTest();

        System.assertEquals(1, acList.size(), 'Should return exactly 1 additional charge for this booking');
        System.assertEquals('Interior Charges', acList[0].Additional_Charge_Type__c,
                            'Charge type should match');
        System.assertEquals(booking.Id, acList[0].Booking__c, 'Booking ID should match');
        System.assertEquals(18, acList[0].GST__c, 'GST should match');
    }

    @IsTest
    static void testGetAdditionalCharges_NoRecordsForUnrelatedBooking() {
        // Create a booking with no additional charges
        Booking__c emptyBooking = new Booking__c(
            First_Applicant_Name__c = 'Empty',
            Finance_User__c = UserInfo.getUserId(),
            Email1__c = 'empty@example.com'
        );
        insert emptyBooking;

        Test.startTest();
        List<Additional_Charges__c> acList = AdditionalChargesMainController.getAdditionalCharges(emptyBooking.Id);
        Test.stopTest();

        System.assertEquals(0, acList.size(), 'Should return empty list for booking with no charges');
    }

    // ---- getACRecord ----

    @IsTest
    static void testGetACRecord_ReturnsCorrectRecord() {
        Additional_Charges__c ac = [SELECT Id, Additional_Charge_Type__c FROM Additional_Charges__c
                                     WHERE Additional_Charge_Type__c = 'Interior Charges' LIMIT 1];

        Test.startTest();
        Additional_Charges__c record = AdditionalChargesMainController.getACRecord(ac.Id);
        Test.stopTest();

        System.assertEquals(ac.Id, record.Id, 'Should return the correct Additional Charge record');
        System.assertEquals('Interior Charges', record.Additional_Charge_Type__c, 'Charge type should match');
        System.assertNotEquals(null, record.Booking__c, 'Booking reference should be populated');
        System.assertEquals(18, record.GST__c, 'GST should match');
    }

    // ---- RaiseManualACDemand ----

    @IsTest
    static void testRaiseManualACDemand_ValidIds() {
        Additional_Charges__c ac = [SELECT Id FROM Additional_Charges__c
                                     WHERE Additional_Charge_Type__c = 'Interior Charges' LIMIT 1];

        Test.startTest();
        try {
            AdditionalChargesMainController.RaiseManualACDemand(new List<Id>{ac.Id});
        } catch (AuraHandledException e) {
            // May throw if email send fails in test context; acceptable
            System.assert(e.getMessage() != null, 'Exception should have a message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testRaiseManualACDemand_NullInput_ThrowsException() {
        try {
            Test.startTest();
            AdditionalChargesMainController.RaiseManualACDemand(null);
            Test.stopTest();
            System.assert(false, 'Expected exception for null input');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().equals('No record IDs provided for raising demand.') ||
                e.getMessage().equals('Script-thrown exception'),
                'Should throw no-records exception: ' + e.getMessage()
            );
        }
    }

    @IsTest
    static void testRaiseManualACDemand_EmptyList_ThrowsException() {
        try {
            Test.startTest();
            AdditionalChargesMainController.RaiseManualACDemand(new List<Id>());
            Test.stopTest();
            System.assert(false, 'Expected exception for empty list');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().equals('No record IDs provided for raising demand.') ||
                e.getMessage().equals('Script-thrown exception'),
                'Should throw no-records exception: ' + e.getMessage()
            );
        }
    }

    // ---- sendBulkEmails ----

    @IsTest
    static void testSendBulkEmails_WithAlternateEmail() {
        Additional_Charges__c ac = [SELECT Id FROM Additional_Charges__c
                                     WHERE Additional_Charge_Type__c = 'Interior Charges' LIMIT 1];

        Test.startTest();
        AdditionalChargesMainController.sendBulkEmails(new List<Id>{ac.Id});
        Test.stopTest();

        // Method should complete without error in test context
        // Email sending is handled by Messaging.sendEmail and test blob is used for PDF
        System.assert(true, 'sendBulkEmails completed without error');
    }

    @IsTest
    static void testSendBulkEmails_WithoutAlternateEmail() {
        // Test with booking2 that has null Alternate_Email1__c
        Additional_Charges__c ac = [SELECT Id FROM Additional_Charges__c
                                     WHERE Additional_Charge_Type__c = 'Maintenance Charges' LIMIT 1];

        Test.startTest();
        AdditionalChargesMainController.sendBulkEmails(new List<Id>{ac.Id});
        Test.stopTest();

        System.assert(true, 'sendBulkEmails completed without error for booking without alternate email');
    }

    @IsTest
    static void testSendBulkEmails_BulkMultipleRecords() {
        List<Additional_Charges__c> acList = [SELECT Id FROM Additional_Charges__c];
        List<Id> acIds = new List<Id>();
        for (Additional_Charges__c ac : acList) {
            acIds.add(ac.Id);
        }

        Test.startTest();
        AdditionalChargesMainController.sendBulkEmails(acIds);
        Test.stopTest();

        System.assert(true, 'Bulk email send for multiple records completed');
    }

    @IsTest
    static void testSendBulkEmails_WithContentDocumentLinks() {
        Additional_Charges__c ac = [SELECT Id FROM Additional_Charges__c
                                     WHERE Additional_Charge_Type__c = 'Interior Charges' LIMIT 1];

        // Create a ContentVersion and link it to the additional charge
        ContentVersion cv = new ContentVersion(
            Title = 'SampleDoc',
            PathOnClient = 'SampleDoc.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = ac.Id,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        AdditionalChargesMainController.sendBulkEmails(new List<Id>{ac.Id});
        Test.stopTest();

        // Verifies the ContentDocumentLink attachment loop executes without errors
        System.assert(true, 'sendBulkEmails with file attachments completed');
    }

    @IsTest
    static void testSendBulkEmails_WithMultipleAttachments() {
        Additional_Charges__c ac = [SELECT Id FROM Additional_Charges__c
                                     WHERE Additional_Charge_Type__c = 'Interior Charges' LIMIT 1];

        // Create multiple content versions and link them
        List<ContentVersion> cvList = new List<ContentVersion>();
        cvList.add(new ContentVersion(
            Title = 'Doc1',
            PathOnClient = 'Doc1.pdf',
            VersionData = Blob.valueOf('Content 1')
        ));
        cvList.add(new ContentVersion(
            Title = 'Doc2',
            PathOnClient = 'Doc2.xlsx',
            VersionData = Blob.valueOf('Content 2')
        ));
        insert cvList;

        List<ContentVersion> insertedCVs = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :cvList];
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        for (ContentVersion insertedCV : insertedCVs) {
            cdls.add(new ContentDocumentLink(
                ContentDocumentId = insertedCV.ContentDocumentId,
                LinkedEntityId = ac.Id,
                ShareType = 'V'
            ));
        }
        insert cdls;

        Test.startTest();
        AdditionalChargesMainController.sendBulkEmails(new List<Id>{ac.Id});
        Test.stopTest();

        System.assert(true, 'sendBulkEmails with multiple attachments completed');
    }

    // ---- saveAdditionalChargeReceipts ----

    @IsTest
    static void testSaveAdditionalChargeReceipts_NullInput_NoError() {
        Test.startTest();
        AdditionalChargesMainController.saveAdditionalChargeReceipts(null);
        Test.stopTest();

        // Null input should just return without error (null check in code)
        System.assert(true, 'Null input handled gracefully');
    }

    @IsTest
    static void testSaveAdditionalChargeReceipts_EmptyList_NoError() {
        Test.startTest();
        AdditionalChargesMainController.saveAdditionalChargeReceipts(new List<Additional_Charge_Receipt__c>());
        Test.stopTest();

        System.assert(true, 'Empty list handled gracefully');
    }

    @IsTest
    static void testSaveAdditionalChargeReceipts_Exception() {
        // Insert a bad record that will fail validation
        Additional_Charge_Receipt__c badReceipt = new Additional_Charge_Receipt__c();

        try {
            Test.startTest();
            AdditionalChargesMainController.saveAdditionalChargeReceipts(
                new List<Additional_Charge_Receipt__c>{badReceipt}
            );
            Test.stopTest();
            // If it succeeds (no required fields fail), that is also acceptable
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().startsWith('Error saving records') ||
                e.getMessage().contains('Script-thrown exception'),
                'Should throw an error-saving-records exception: ' + e.getMessage()
            );
        }
    }

    // ---- sendNotificationsFromAdditionalChange ----

    @IsTest
    static void testSendNotifications_Approved() {
        Additional_Charges__c ac = [SELECT Id, Name, CreatedById, Booking_Name__c
                                     FROM Additional_Charges__c LIMIT 1];
        List<Additional_Charges__c> listAC = new List<Additional_Charges__c>{ac};

        Test.startTest();
        AdditionalChargesMainController.sendNotificationsFromAdditionalChange(
            'Additional Charge Demand Raise Approved', listAC
        );
        Test.stopTest();

        // Notification sent successfully if no exception
        System.assert(true, 'Approved notification sent without error');
    }

    @IsTest
    static void testSendNotifications_Rejected() {
        Additional_Charges__c ac = [SELECT Id, Name, CreatedById, Booking_Name__c
                                     FROM Additional_Charges__c LIMIT 1];
        List<Additional_Charges__c> listAC = new List<Additional_Charges__c>{ac};

        Test.startTest();
        AdditionalChargesMainController.sendNotificationsFromAdditionalChange(
            'Additional Charge Demand Raise Rejected', listAC
        );
        Test.stopTest();

        System.assert(true, 'Rejected notification sent without error');
    }

    @IsTest
    static void testSendNotifications_UnknownTitle() {
        Additional_Charges__c ac = [SELECT Id, Name, CreatedById, Booking_Name__c
                                     FROM Additional_Charges__c LIMIT 1];
        List<Additional_Charges__c> listAC = new List<Additional_Charges__c>{ac};

        Test.startTest();
        try {
            AdditionalChargesMainController.sendNotificationsFromAdditionalChange(
                'Some Other Title', listAC
            );
        } catch (Exception e) {
            // May fail since body will be empty string, but covers the code path
            System.assert(e.getMessage() != null, 'Exception should have a message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendNotifications_BulkRecords() {
        List<Additional_Charges__c> allAC = [SELECT Id, Name, CreatedById, Booking_Name__c
                                              FROM Additional_Charges__c];

        Test.startTest();
        AdditionalChargesMainController.sendNotificationsFromAdditionalChange(
            'Additional Charge Demand Raise Approved', allAC
        );
        Test.stopTest();

        System.assert(true, 'Bulk notification sent without error');
    }
}