@isTest
public class AnushreeBookingFormControllerTest {
    
    @testSetup
    static void setupData() {
        // Create a Booking record...
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Test Applicant',
            Booking_Date__c = Date.today()
        );
        insert booking;
        
        // Create some Co-Applicants...
        for (Integer i = 0; i < 2; i++) {
            Co_Applicant__c coApp = new Co_Applicant__c(
                Name = 'CoApplicant ' + i,
                Relalation_Details__c = 'S/o',
                Aadhar_Number__c = '1234567890' + i,
                PAN_Number__c = 'ABCDE1234' + i,
                Booking__c = booking.Id
            );
            insert coApp;
        }

        // Create a mock Attachment for the signature...
        Attachment att = new Attachment(
            Name = 'signature.png',
            ParentId = booking.Id,
            Body = Blob.valueOf('Test Signature File')
        );
        insert att;

        // Create ContentVersion and attach via ContentDocumentLink...
        ContentVersion cv = new ContentVersion(
            Title = '[ Applicant Photo ] TestPhoto',
            PathOnClient = 'TestPhoto.png',
            VersionData = Blob.valueOf('FakeContent'),
            IsMajorVersion = true
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        ContentDocument cd = [SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE Id = :docId LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = booking.Id,
            ContentDocumentId = cd.Id,
            ShareType = 'V'
        );
        insert cdl;
    }

    @isTest
    static void testControllerWithId() {
        Booking__c testBooking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        // Instead of Page.AnushreeForm, use dynamic PageReference...
        PageReference pageRef = new PageReference('/apex/AnushreeForm');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testBooking.Id);
        
        AnushreeBookingFormController controller = new AnushreeBookingFormController();
        Test.stopTest();
        
        System.assertNotEquals(null, controller.booking, 'Booking should be initialized');
        System.assertNotEquals(null, controller.signatureUrl, 'Signature URL should be fetched');
        System.assert(controller.coApplicants.size() == 4, 'Controller should always produce 4 co-applicants');
        System.assert(controller.applicantPhotoUrl != null, 'Photo URL should be generated');
    }

    @isTest
    static void testControllerWithoutId() {
        Test.startTest();
        // No need for actual Visualforce page...
        Test.setCurrentPage(new PageReference('/apex/AnushreeForm'));
        AnushreeBookingFormController controller = new AnushreeBookingFormController();
        Test.stopTest();

        System.assert(controller.booking != null, 'Booking record should initialize');
        System.assert(controller.coApplicants.size() >= 0, 'Co-applicant wrapper list should initialize safely');
    }

    @isTest
    static void testNoSignatureAttachment() {
        Booking__c b = new Booking__c(First_Applicant_Name__c = 'NoSig Applicant', Booking_Date__c = Date.today());
        insert b;

        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/AnushreeForm'));
        ApexPages.currentPage().getParameters().put('id', b.Id);
        AnushreeBookingFormController controller = new AnushreeBookingFormController();
        Test.stopTest();

        System.assertEquals(null, controller.signatureUrl, 'Signature URL should be null when none exists');
    }
}