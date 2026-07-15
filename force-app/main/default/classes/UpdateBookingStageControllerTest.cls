@isTest
public class UpdateBookingStageControllerTest {

    // Utility method to create and return ContentDocumentId
    private static Id createTestFile(String title) {
        ContentVersion contentVersion = new ContentVersion(
            Title = title,
            PathOnClient = title + '.txt',
            VersionData = Blob.valueOf('Test file content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion inserted = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        return inserted.ContentDocumentId;
    }

    @isTest
    public static void testGetStage() {
        Booking__c booking = new Booking__c(Stage__c = 'Agreement');
        insert booking;
        Test.startTest();
        String stage = UpdateBookingStageController.getStage(booking.Id);
        Test.stopTest();
        System.assertEquals('Agreement', stage, 'The stage should be Agreement');
    }

    @isTest
    public static void testCheckTenPercentCollected() {
        Booking__c booking = new Booking__c();
        insert booking;
        Test.startTest();
        Boolean ten = UpdateBookingStageController.checkTenPercentCollected(booking.Id);
        Test.stopTest();
        System.assertEquals(true, ten, 'The 10% collection status should be true');
    }

  @isTest
static void testSubmitForApproval() {
    User salesManager = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

    Booking__c booking = new Booking__c(
        Stage__c = 'Registration',
        Sales_Manager1__c = salesManager.Id   // Set this field as required by approval process
    );
    insert booking;

    Test.startTest();
    UpdateBookingStageController.submitForApproval(booking.Id, '2025-12-01');
    Test.stopTest();

    booking = [SELECT Stage__c FROM Booking__c WHERE Id = :booking.Id];
    System.assertEquals('Agreement', booking.Stage__c, 'The stage should be updated to Agreement');
}


    @isTest
    public static void testCheckNinetyPercentCollected() {
        Booking__c booking = new Booking__c();
        insert booking;
        Test.startTest();
        Boolean ninety = UpdateBookingStageController.checkNinetyPercentCollected(booking.Id);
        Test.stopTest();
        System.assertEquals(true, ninety, 'The 90% collection status should be true');
    }
/*
    @isTest
    public static void testSubmitRegistrationForApproval() {
        Booking__c booking = new Booking__c(Stage__c = 'Registration');
        insert booking;
        Test.startTest();
        UpdateBookingStageController.submitRegistrationForApproval(booking.Id, '2025-12-01');
        Test.stopTest();
        booking = [SELECT Stage__c FROM Booking__c WHERE Id = :booking.Id];
        System.assertEquals('Registration', booking.Stage__c, 'The stage should be updated to Registration');
    }
*/
    @isTest
    public static void testGetFiles() {
        Booking__c booking = new Booking__c();
        insert booking;
        Id docId = createTestFile('Test Document');
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = booking.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert docLink;
        Test.startTest();
        List<ContentDocument> files = UpdateBookingStageController.getFiles(booking.Id);
        Test.stopTest();
        System.assertNotEquals(0, files.size(), 'The list of files should not be empty');
        System.assertEquals('Test Document', files[0].Title, 'The document title should match');
    }

    @isTest
    public static void testUpdateDocument() {
        Id docId = createTestFile('DocToUpdate');
        List<String> idList = new List<String>{docId};
        Test.startTest();
        UpdateBookingStageController.updateDocument('TestUpdate', idList);
        Test.stopTest();
        ContentDocument doc = [SELECT Title FROM ContentDocument WHERE Id = :docId];
        System.assert(doc.Title.contains('TestUpdate'), 'The document title should be updated with the suffix');
    }

    @isTest
    public static void testGetupdatedStage() {
        Booking__c booking = new Booking__c(Stage__c = 'Agreement');
        insert booking;
        Id saDocId = createTestFile('SA Document - [ Sale Agreement ]');
        Id sdDocId = createTestFile('SD Document - [ Sale Deed ]');
        insert new List<ContentDocumentLink>{
            new ContentDocumentLink(
                ContentDocumentId = saDocId,
                LinkedEntityId = booking.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ),
            new ContentDocumentLink(
                ContentDocumentId = sdDocId,
                LinkedEntityId = booking.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            )
        };
        Test.startTest();
        UpdateBookingStageController.initWrapper wrapper = UpdateBookingStageController.getupdatedStage(booking.Id);
        Test.stopTest();
        System.assertEquals('Agreement', wrapper.StageName, 'The stage should be Agreement');
        System.assert(wrapper.SaleAgreementFiles.size() >= 1, 'Sale Agreement files should be present');
        System.assert(wrapper.SaleDeedFiles.size() >= 1, 'Sale Deed files should be present');
    }
}