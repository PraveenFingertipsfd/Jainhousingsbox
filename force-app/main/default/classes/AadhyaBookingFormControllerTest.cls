@IsTest
public class AadhyaBookingFormControllerTest {

    @TestSetup
    static void setupTestData() {
        
        User u = new User(
            Username = 'testuser_' + System.currentTimeMillis() + '@example.com',
            LastName = 'TestUser',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        // Create Booking...
        Booking__c booking = new Booking__c(
            OwnerId = u.Id,
            First_Applicant_Name__c = 'John Doe',
            Mobile_Primary1__c = '9999999999'
        );
        insert booking;

        // Create Co-Applicant...
        Co_Applicant__c coApp = new Co_Applicant__c(
            Name = 'Jane Doe',
            Booking__c = booking.Id,
            // ----> Leave relation field blank or use a safe default like "Spouse" if exists in your org
            Relalation_Details__c = '', 
            Aadhar_Number__c = '123412341234',
            PAN_Number__c = 'ABCDE1234F'
        );
        insert coApp;

        // Add dummy signature...
        Attachment att = new Attachment(
            Name = 'signature.png',
            ParentId = booking.Id,
            Body = Blob.valueOf('dummy data')
        );
        insert att;

        // Add dummy photo...
        ContentVersion cv = new ContentVersion(
            Title = '[ Applicant Photo ] Test Image',
            PathOnClient = 'photo.png',
            VersionData = Blob.valueOf('test image')
        );
        insert cv;

        Id contentDocId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id 
            LIMIT 1
        ].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = booking.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V'
        );
        insert cdl;
    }

    @IsTest
    static void testConstructorWithId() {
        Id bookingId = [SELECT Id FROM Booking__c LIMIT 1].Id;
        PageReference pg = new PageReference('/apex/dummy');
        Test.setCurrentPage(pg);
        ApexPages.currentPage().getParameters().put('id', bookingId);

        Test.startTest();
        AadhyaBookingFormController controller = new AadhyaBookingFormController();
        Test.stopTest();

        System.assertNotEquals(null, controller.booking, 'Booking should be loaded');
        System.assertNotEquals(null, controller.signatureUrl, 'Signature URL should be set');
        System.assertEquals(4, controller.coApplicants.size(), 'There should be 4 co-applicants');
        System.assertNotEquals(null, controller.applicantPhotoUrl, 'Photo URL should be set');
    }

    @IsTest
    static void testConstructorWithoutId() {
        PageReference pg = new PageReference('/apex/dummy');
        Test.setCurrentPage(pg);

        Test.startTest();
        AadhyaBookingFormController controller = new AadhyaBookingFormController();
        Test.stopTest();

        System.assertEquals(null, controller.booking.Id, 'No booking expected');
        System.assertEquals(0, controller.coApplicants.size(), 'No co-applicants expected');
    }

    @IsTest
    static void testBookingWithoutAttachment() {
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Solo Applicant',
            Mobile_Primary1__c = '8888888888'
        );
        insert booking;

        PageReference pg = new PageReference('/apex/dummy');
        Test.setCurrentPage(pg);
        ApexPages.currentPage().getParameters().put('id', booking.Id);

        Test.startTest();
        AadhyaBookingFormController controller = new AadhyaBookingFormController();
        Test.stopTest();

        System.assertEquals(4, controller.coApplicants.size(), 'Should have 4 co-applicants');
        System.assertEquals(null, controller.signatureUrl, 'Signature URL should be null');
    }
}