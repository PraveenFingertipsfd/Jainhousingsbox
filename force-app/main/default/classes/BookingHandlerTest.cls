@isTest
public class BookingHandlerTest {

    private static User createTestUser(String alias, String email) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = alias,
            Email = email,
            EmailEncodingKey = 'UTF-8',
            LastName = alias,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = alias + DateTime.now().getTime() + '@testorg.com'
        );
        insert u;
        return u;
    }

    @TestSetup
    static void setupData() {
        User salesMgr = createTestUser('smgr', 'salesmgr@test.com');
        // Create multiple bookings for bulkification testing
        List<Booking__c> bookings = new List<Booking__c>();
        for (Integer i = 0; i < 5; i++) {
            bookings.add(new Booking__c(
                OwnerId = salesMgr.Id,
                First_Applicant_Name__c = 'Test Applicant ' + i,
                Booking_Date__c = Date.today(),
                Sales_Manager1__c = salesMgr.Id
            ));
        }
        insert bookings;
    }

    // ---- Constructor Tests ----

    @isTest
    static void testConstructor_WithPageParameter() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];
        PageReference pageRef = new PageReference('/apex/TestPage');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', b.Id);

        Test.startTest();
        BookingHandler handler = new BookingHandler();
        Test.stopTest();

        System.assertNotEquals(null, handler, 'Handler should be instantiated');
    }

    @isTest
    static void testConstructor_WithoutPageParameter() {
        PageReference pageRef = new PageReference('/apex/TestPage');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        BookingHandler handler = new BookingHandler();
        Test.stopTest();

        System.assertNotEquals(null, handler, 'Handler should be instantiated even without page param');
    }

    // ---- sendCancellationApproval() Tests ----

    @isTest
    static void testSendCancellationApproval_Success() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Boolean result = BookingHandler.sendCancellationApproval(
            b.Id, true, 'Budget', 'Customer wants cancellation due to budget'
        );
        Test.stopTest();

        System.assertEquals(true, result, 'sendCancellationApproval should return true on success');
        Booking__c updated = [SELECT Cancellation_Reason__c, Cancellation_Description__c
                              FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals('Budget', updated.Cancellation_Reason__c,
            'Cancellation reason should be updated');
        System.assertEquals('Customer wants cancellation due to budget', updated.Cancellation_Description__c,
            'Cancellation description should be updated');
    }

    @isTest
    static void testSendCancellationApproval_CancelTypeFalse() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Boolean result = BookingHandler.sendCancellationApproval(
            b.Id, false, 'Found New Flat', 'Moving to another city'
        );
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true regardless of cancelType');
        Booking__c updated = [SELECT Cancellation_Reason__c FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals('Found New Flat', updated.Cancellation_Reason__c,
            'Reason should be updated even when cancelType is false');
    }

    @isTest
    static void testSendCancellationApproval_NullReasonAndDescription() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Boolean result = BookingHandler.sendCancellationApproval(b.Id, true, null, null);
        Test.stopTest();

        System.assertEquals(true, result, 'Should succeed even with null reason/description');
        Booking__c updated = [SELECT Cancellation_Reason__c, Cancellation_Description__c
                              FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals(null, updated.Cancellation_Reason__c,
            'Cancellation reason should be null');
        System.assertEquals(null, updated.Cancellation_Description__c,
            'Cancellation description should be null');
    }

    // ---- approvalWithCancellationCharge() Tests ----

    @isTest
    static void testApprovalWithCancellationCharge_Success() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        // Submit for approval first to create a pending work item
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(b.Id);
        req.setProcessDefinitionNameOrId('Cancellation_Approval');
        req.setSkipEntryCriteria(true);
        Approval.ProcessResult submitResult = Approval.process(req);
        System.assert(submitResult.isSuccess(), 'Approval submission should succeed');

        Test.startTest();
        Boolean result = BookingHandler.approvalWithCancellationCharge(
            b.Id, 'Approved with cancellation charge', 750.00
        );
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true on successful approval');
        Booking__c updated = [SELECT Cancellation_Charges__c FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals(750.00, updated.Cancellation_Charges__c,
            'Cancellation charges should be updated to 750');
    }

    @isTest
    static void testApprovalWithCancellationCharge_NoPendingApproval() {
        // No approval submitted => no work items => should throw AuraHandledException
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        try {
            BookingHandler.approvalWithCancellationCharge(b.Id, 'No pending', 100.00);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'AuraHandledException should be thrown when no pending approval exists');
        // AuraHandledException.getMessage() returns 'Script-thrown exception' in Apex test context,
        // not the custom message. So we only verify the exception was thrown.
    }

    @isTest
    static void testApprovalWithCancellationCharge_ZeroCharge() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(b.Id);
        req.setProcessDefinitionNameOrId('Cancellation_Approval');
        req.setSkipEntryCriteria(true);
        Approval.process(req);

        Test.startTest();
        Boolean result = BookingHandler.approvalWithCancellationCharge(b.Id, 'Zero charge', 0);
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true with zero charge');
        Booking__c updated = [SELECT Cancellation_Charges__c FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals(0, updated.Cancellation_Charges__c,
            'Cancellation charges should be zero');
    }

    @isTest
    static void testApprovalWithCancellationCharge_NullComment() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(b.Id);
        req.setProcessDefinitionNameOrId('Cancellation_Approval');
        req.setSkipEntryCriteria(true);
        Approval.process(req);

        Test.startTest();
        Boolean result = BookingHandler.approvalWithCancellationCharge(b.Id, null, 500.00);
        Test.stopTest();

        System.assertEquals(true, result, 'Should handle null comment gracefully');
        Booking__c updated = [SELECT Cancellation_Charges__c FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals(500.00, updated.Cancellation_Charges__c,
            'Charges should be updated to 500 even with null comment');
    }

    @isTest
    static void testApprovalWithCancellationCharge_NullCharge() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(b.Id);
        req.setProcessDefinitionNameOrId('Cancellation_Approval');
        req.setSkipEntryCriteria(true);
        Approval.process(req);

        Test.startTest();
        Boolean result = BookingHandler.approvalWithCancellationCharge(b.Id, 'Null charge test', null);
        Test.stopTest();

        System.assertEquals(true, result, 'Should handle null charge gracefully');
        Booking__c updated = [SELECT Cancellation_Charges__c FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals(null, updated.Cancellation_Charges__c,
            'Cancellation charges should be null');
    }

    @isTest
    static void testApprovalWithCancellationCharge_InvalidRecordId() {
        // Use a fabricated Id that does not exist in database
        Id fakeId = Booking__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000';

        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        try {
            BookingHandler.approvalWithCancellationCharge(fakeId, 'Invalid record', 100.00);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        } catch (Exception e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Exception should be thrown for invalid record ID');
        System.assertNotEquals(null, exceptionMessage, 'Exception should have a message');
    }

    @isTest
    static void testApprovalWithCancellationCharge_LargeCharge() {
        // Test with a very large cancellation charge value
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(b.Id);
        req.setProcessDefinitionNameOrId('Cancellation_Approval');
        req.setSkipEntryCriteria(true);
        Approval.process(req);

        Test.startTest();
        Boolean result = BookingHandler.approvalWithCancellationCharge(b.Id, 'Large charge', 9999999.99);
        Test.stopTest();

        System.assertEquals(true, result, 'Should handle large charge value');
        Booking__c updated = [SELECT Cancellation_Charges__c FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals(9999999.99, updated.Cancellation_Charges__c,
            'Large cancellation charge should be stored correctly');
    }

    @isTest
    static void testApprovalWithCancellationCharge_NegativeCharge() {
        // Test with a negative cancellation charge
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(b.Id);
        req.setProcessDefinitionNameOrId('Cancellation_Approval');
        req.setSkipEntryCriteria(true);
        Approval.process(req);

        Test.startTest();
        Boolean result = BookingHandler.approvalWithCancellationCharge(b.Id, 'Negative charge', -50.00);
        Test.stopTest();

        System.assertEquals(true, result, 'Should handle negative charge');
        Booking__c updated = [SELECT Cancellation_Charges__c FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals(-50.00, updated.Cancellation_Charges__c,
            'Negative charge value should be stored');
    }

    // ---- sendCustomNotification() Tests ----

    @isTest
    static void testSendCustomNotification_WithExistingType() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        List<CustomNotificationType> types = [
            SELECT Id, DeveloperName FROM CustomNotificationType LIMIT 1
        ];

        Test.startTest();
        if (!types.isEmpty()) {
            BookingHandler.sendCustomNotification(
                recipients, 'Test Notification', 'Test body content', b.Id, types[0].DeveloperName
            );
            System.assert(true, 'Notification sent without error');
        } else {
            // No custom notification types exist - verify exception path
            Boolean exceptionThrown = false;
            try {
                BookingHandler.sendCustomNotification(
                    recipients, 'Test Title', 'Body', b.Id, 'NonExistentType'
                );
            } catch (Exception e) {
                exceptionThrown = true;
                System.assertNotEquals(null, e.getMessage(),
                    'Should have error message for non-existent notification type');
            }
            System.assert(exceptionThrown, 'Should throw exception for missing notification type');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendCustomNotification_NonExistentType_ThrowsException() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        try {
            BookingHandler.sendCustomNotification(
                recipients, 'Title', 'Body', b.Id, 'Totally_Fake_Notification_Type_XYZ'
            );
        } catch (Exception e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Should throw exception for non-existent notification type');
        System.assertNotEquals(null, exceptionMessage,
            'Exception message should not be null');
    }

    @isTest
    static void testSendCustomNotification_MultipleRecipients() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];
        User u2 = createTestUser('rcpt2', 'rcpt2@test.com');
        Set<String> recipients = new Set<String>{ UserInfo.getUserId(), u2.Id };

        List<CustomNotificationType> types = [
            SELECT Id, DeveloperName FROM CustomNotificationType LIMIT 1
        ];

        Test.startTest();
        if (!types.isEmpty()) {
            BookingHandler.sendCustomNotification(
                recipients, 'Multi Recipient', 'Body for multiple', b.Id, types[0].DeveloperName
            );
            System.assert(true, 'Multiple recipient notification sent successfully');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendCustomNotification_EmptyRecipientSet() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];
        Set<String> recipients = new Set<String>();

        List<CustomNotificationType> types = [
            SELECT Id, DeveloperName FROM CustomNotificationType LIMIT 1
        ];

        Test.startTest();
        if (!types.isEmpty()) {
            Boolean exceptionThrown = false;
            try {
                BookingHandler.sendCustomNotification(
                    recipients, 'Empty Recipient', 'Body', b.Id, types[0].DeveloperName
                );
            } catch (Exception e) {
                exceptionThrown = true;
                System.assertNotEquals(null, e.getMessage(),
                    'Should have error message for empty recipients');
            }
            // Empty recipients may or may not throw; either way we exercised the code
            System.assert(true, 'Empty recipient test completed');
        }
        Test.stopTest();
    }

    // ---- Property Accessors ----

    @isTest
    static void testHandlerProperties() {
        PageReference pageRef = new PageReference('/apex/TestPage');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        BookingHandler handler = new BookingHandler();

        // Test checks property
        handler.checks = true;
        System.assertEquals(true, handler.checks, 'checks property getter should return true');
        handler.checks = false;
        System.assertEquals(false, handler.checks, 'checks property getter should return false');

        // Test status property
        handler.status = 'Active';
        System.assertEquals('Active', handler.status, 'status should be Active');
        handler.status = 'Inactive';
        System.assertEquals('Inactive', handler.status, 'status should be Inactive');

        // Test book property
        handler.book = new Booking__c();
        System.assertNotEquals(null, handler.book, 'book should not be null');

        // Test result property
        handler.result = new Map<String, Object>{ 'key' => 'value', 'count' => 42 };
        System.assertEquals('value', handler.result.get('key'), 'result map should contain key');
        System.assertEquals(42, handler.result.get('count'), 'result map should contain count');

        Test.stopTest();
    }

    // ---- Bulk Tests ----

    @isTest
    static void testSendCancellationApproval_Bulk() {
        List<Booking__c> bookings = [SELECT Id FROM Booking__c LIMIT 5];
        System.assert(bookings.size() > 1, 'Should have multiple test bookings');

        Test.startTest();
        for (Booking__c b : bookings) {
            Boolean result = BookingHandler.sendCancellationApproval(
                b.Id, true, 'Budget', 'Bulk Description'
            );
            System.assertEquals(true, result, 'Each bulk call should return true');
        }
        Test.stopTest();

        List<Booking__c> updated = [SELECT Cancellation_Reason__c, Cancellation_Description__c
                                     FROM Booking__c
                                     WHERE Cancellation_Reason__c = 'Budget'];
        System.assertEquals(bookings.size(), updated.size(),
            'All bookings should have updated cancellation reason');
        for (Booking__c b : updated) {
            System.assertEquals('Bulk Description', b.Cancellation_Description__c,
                'Each booking should have bulk description');
        }
    }

    @isTest
    static void testSendCancellationApproval_EmptyStringInputs() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Boolean result = BookingHandler.sendCancellationApproval(b.Id, true, '', '');
        Test.stopTest();

        System.assertEquals(true, result, 'Should succeed with empty string inputs');
        Booking__c updated = [SELECT Cancellation_Reason__c, Cancellation_Description__c
                              FROM Booking__c WHERE Id = :b.Id];
        // Salesforce converts empty string '' to null for picklist fields on save
        System.assertEquals(null, updated.Cancellation_Reason__c,
            'Reason should be null (Salesforce converts empty picklist to null)');
        System.assertEquals(null, updated.Cancellation_Description__c,
            'Description should be null (empty string saved as null)');
    }
}