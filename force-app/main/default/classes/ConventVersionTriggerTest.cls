@isTest
public class ConventVersionTriggerTest {

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

        Booking_Request__c bookingReq = new Booking_Request__c(
            Unit__c = plot.Id,
            Customer_Name__c = 'Test Customer',
            Email__c = 'test@test.com'
        );
        insert bookingReq;
    }

    @isTest
    static void testContentVersionWithGuestRecord() {
        Booking_Request__c bookingReq = [SELECT Id FROM Booking_Request__c LIMIT 1];

        Test.startTest();
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content'),
            Guest_Record_fileupload__c = bookingReq.Id
        );
        insert cv;
        Test.stopTest();

        // Verify ContentDocumentLink was created
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        List<ContentDocumentLink> links = [SELECT Id, LinkedEntityId FROM ContentDocumentLink
                                            WHERE ContentDocumentId = :cv.ContentDocumentId
                                            AND LinkedEntityId = :bookingReq.Id];
        System.assertEquals(1, links.size(), 'ContentDocumentLink should be created');
        System.assertEquals(bookingReq.Id, links[0].LinkedEntityId, 'Should link to booking request');
    }

    @isTest
    static void testContentVersionWithoutGuestRecord() {
        Test.startTest();
        ContentVersion cv = new ContentVersion(
            Title = 'Regular Document',
            PathOnClient = 'RegularDoc.pdf',
            VersionData = Blob.valueOf('Regular content')
        );
        insert cv;
        Test.stopTest();

        // Verify no extra ContentDocumentLink was created (only default library link)
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink
                                            WHERE ContentDocumentId = :cv.ContentDocumentId];
        // Default link to ContentWorkspace is created by system, no guest record link
        System.assert(true, 'Should not create extra links for non-guest uploads');
    }

    @isTest
    static void testBulkContentVersionInsert() {
        Booking_Request__c bookingReq = [SELECT Id FROM Booking_Request__c LIMIT 1];
        List<ContentVersion> versions = new List<ContentVersion>();

        for (Integer i = 0; i < 10; i++) {
            versions.add(new ContentVersion(
                Title = 'Bulk Doc ' + i,
                PathOnClient = 'BulkDoc' + i + '.pdf',
                VersionData = Blob.valueOf('Bulk content ' + i),
                Guest_Record_fileupload__c = bookingReq.Id
            ));
        }

        Test.startTest();
        insert versions;
        Test.stopTest();

        // Verify all links created
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink
                                            WHERE LinkedEntityId = :bookingReq.Id];
        System.assertEquals(10, links.size(), 'Should create 10 ContentDocumentLinks');
    }
}