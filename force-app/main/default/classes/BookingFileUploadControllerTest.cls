@IsTest
public class BookingFileUploadControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create Project
        Project__c pr = new Project__c();
        pr.Name = 'Jains Anushree';
        pr.Project_Type__c = 'Apartments';
        insert pr;

        // Create Block
        Block__c blk = new Block__c();
        blk.Name = 'A';
        blk.Project__c = pr.Id;
        insert blk;

        // Create Plot
        Plot__c pl = new Plot__c();
        pl.Name = '101';
        pl.Status__c = 'Available';
        pl.Project__c = pr.Id;
		pl.Project_Type__c = pr.Project_Type__c;
        pl.Block__c = 'A4';
        pl.Plot_Type__c = 'Residential';
        pl.Block1__c = blk.Id;
        pl.Carpet_Area__c = 850;
        pl.Balcony_Sq_mts__c = 20;
        pl.Balcony_Area__c = 100;
        pl.BHK_Type__c = '3 BHK + 2T';
        pl.Premium_Status__c = 'Premium';
        pl.Floor__c = '1';
        pl.Share__c = 'MHPL';
        pl.Facing__c = 'EAST';
        pl.Carpet_Sq_mts__c = 80;
        pl.CA__c = 75;
        pl.Built_up_area__c = 1200;
        pl.UDS__c = 300;
        pl.UDS_Sq_mts__c = 50;
        pl.Super_built_up_area__c = 1500;
        pl.Price_Per_Sq_Ft__c = 5000;
        pl.Floor_Rise__c = 200;
        pl.Premium_Charge__c = 100000;
        pl.Covered_Park_Parking__c = 50000;
        pl.Other_Charges__c = 20000;
        pl.Solar_Charges__c = 15000;
        pl.GST1__c = 18;
        insert pl;

        // Create Booking
        Booking__c booking = new Booking__c();
        booking.Followup_Date__c = System.today();
        booking.Followup_Subject__c = 'test22';
        booking.Last_Comment__c = 'test22';
        booking.Project__c = 'Jains Anushree';
        booking.Payment_Type__c = 'Custom';
        booking.Sale_Agreement_Completed__c = false;
        booking.Sub_Stages__c = 'Submitted For Approval';
        booking.Demand_Number__c = '12345';
        booking.Property_Type__c = 'Appartment';
        booking.Project1__c = pr.Id;
        booking.Date_of_Booking__c = System.today();
        booking.Mode_Of_Payment__c = 'Credit Card';
        booking.Funding_Type__c = 'Self';
        booking.Plot__c = pl.Id;
        insert booking;

        // Create ContentVersion with a title matching the suffix pattern
        ContentVersion cv1 = new ContentVersion(
            Title = 'Test Document - [ Sale Deed ]',
            PathOnClient = 'TestDocument.txt',
            VersionData = Blob.valueOf('Test content for sale deed'),
            IsMajorVersion = true
        );
        insert cv1;

        Id contentDocId1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id LIMIT 1].ContentDocumentId;

        // Link document to booking
        ContentDocumentLink cdl1 = new ContentDocumentLink(
            LinkedEntityId = booking.Id,
            ContentDocumentId = contentDocId1,
            ShareType = 'V'
        );
        insert cdl1;

        // Create a second document without suffix pattern
        ContentVersion cv2 = new ContentVersion(
            Title = 'Another Document',
            PathOnClient = 'AnotherDoc.txt',
            VersionData = Blob.valueOf('Another test content'),
            IsMajorVersion = true
        );
        insert cv2;

        Id contentDocId2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id LIMIT 1].ContentDocumentId;

        ContentDocumentLink cdl2 = new ContentDocumentLink(
            LinkedEntityId = booking.Id,
            ContentDocumentId = contentDocId2,
            ShareType = 'V'
        );
        insert cdl2;
    }

    @IsTest
    static void testGetFiles_WithMatchingFilter() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        List<ContentDocument> results = BookingFileUploadController.getFiles(booking.Id, 'Sale-Deed');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 document matching the Sale Deed suffix');
        System.assert(results[0].Title.contains('Sale Deed'), 'Title should contain Sale Deed');
        System.assertNotEquals(null, results[0].Id, 'Returned document should have a valid Id');
        System.assertNotEquals(null, results[0].SystemModStamp, 'SystemModStamp should be populated');
    }

    @IsTest
    static void testGetFiles_NoMatchingFilter() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        List<ContentDocument> results = BookingFileUploadController.getFiles(booking.Id, 'Non-Existent-Filter');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return 0 documents when filter does not match');
    }

    @IsTest
    static void testGetFiles_NoDocumentsLinked() {
        // Create a booking with no documents linked
        Project__c pr = [SELECT Id FROM Project__c LIMIT 1];

        Booking__c newBooking = new Booking__c();
        newBooking.Project__c = 'Jains Anushree';
        newBooking.Payment_Type__c = 'Custom';
        newBooking.Property_Type__c = 'Appartment';
        newBooking.Project1__c = pr.Id;
        newBooking.Date_of_Booking__c = System.today();
        newBooking.Mode_Of_Payment__c = 'Credit Card';
        newBooking.Funding_Type__c = 'Self';
        insert newBooking;

        Test.startTest();
        List<ContentDocument> results = BookingFileUploadController.getFiles(newBooking.Id, 'Sale-Deed');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return 0 documents for booking with no linked files');
    }

    @IsTest
    static void testGetFiles_FilterWithMultipleHyphens() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        List<ContentDocument> results = BookingFileUploadController.getFiles(booking.Id, 'Multi-Word-Filter');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return 0 when multi-hyphen filter does not match any document');
    }

    @IsTest
    static void testDeleteFile() {
        ContentDocument contentDoc = [SELECT Id FROM ContentDocument LIMIT 1];
        Id docId = contentDoc.Id;

        Test.startTest();
        BookingFileUploadController.deleteFile(docId);
        Test.stopTest();

        List<ContentDocument> remaining = [SELECT Id FROM ContentDocument WHERE Id = :docId];
        System.assertEquals(0, remaining.size(), 'Document should be deleted after calling deleteFile');
    }

    @IsTest
    static void testDeleteFile_VerifyOtherDocsRemain() {
        List<ContentDocument> allDocs = [SELECT Id FROM ContentDocument];
        System.assert(allDocs.size() >= 2, 'Should have at least 2 documents before delete');

        Id docToDelete = allDocs[0].Id;

        Test.startTest();
        BookingFileUploadController.deleteFile(docToDelete);
        Test.stopTest();

        List<ContentDocument> remaining = [SELECT Id FROM ContentDocument];
        System.assertEquals(allDocs.size() - 1, remaining.size(), 'Only the targeted document should be deleted');
        for (ContentDocument doc : remaining) {
            System.assertNotEquals(docToDelete, doc.Id, 'Deleted doc Id should not appear in remaining list');
        }
    }

    @IsTest
    static void testUpdateDocument_AppliesSuffix() {
        ContentDocument contentDoc = [SELECT Id, Title FROM ContentDocument WHERE Title = 'Another Document' LIMIT 1];

        Test.startTest();
        BookingFileUploadController.updateDocument('Sale-Deed', new List<String>{ contentDoc.Id });
        Test.stopTest();

        ContentDocument updated = [SELECT Id, Title FROM ContentDocument WHERE Id = :contentDoc.Id LIMIT 1];
        System.assert(updated.Title.contains(' - [ Sale Deed ]'), 'Title should have the suffix applied. Actual: ' + updated.Title);
        System.assert(updated.Title.startsWith('Another Document'), 'Original title base should be preserved');
    }

    @IsTest
    static void testUpdateDocument_ReplacesExistingSuffix() {
        // Document already has a suffix from test setup
        ContentDocument contentDoc = [SELECT Id, Title FROM ContentDocument WHERE Title LIKE '%Sale Deed%' LIMIT 1];

        Test.startTest();
        BookingFileUploadController.updateDocument('New-Category', new List<String>{ contentDoc.Id });
        Test.stopTest();

        ContentDocument updated = [SELECT Id, Title FROM ContentDocument WHERE Id = :contentDoc.Id LIMIT 1];
        System.assert(updated.Title.contains(' - [ New Category ]'), 'Suffix should be replaced with New Category. Actual: ' + updated.Title);
        // Verify old suffix is removed
        Integer suffixCount = updated.Title.countMatches(' - [ ');
        System.assertEquals(1, suffixCount, 'Should only have one suffix after replacement');
        System.assert(!updated.Title.contains('Sale Deed'), 'Old suffix Sale Deed should be removed');
    }

    @IsTest
    static void testUpdateDocument_BulkUpdate() {
        List<ContentDocument> docs = [SELECT Id, Title FROM ContentDocument];
        List<String> docIds = new List<String>();
        for (ContentDocument doc : docs) {
            docIds.add(doc.Id);
        }
        System.assert(docIds.size() >= 2, 'Should have at least 2 documents for bulk test');

        Test.startTest();
        BookingFileUploadController.updateDocument('Bulk-Category', docIds);
        Test.stopTest();

        List<ContentDocument> updatedDocs = [SELECT Id, Title FROM ContentDocument WHERE Id IN :docIds];
        System.assertEquals(docIds.size(), updatedDocs.size(), 'All documents should still exist after update');
        for (ContentDocument doc : updatedDocs) {
            System.assert(doc.Title.contains(' - [ Bulk Category ]'), 'Each document should have the Bulk Category suffix. Actual: ' + doc.Title);
        }
    }

    @IsTest
    static void testUpdateDocument_EmptyList() {
        Test.startTest();
        BookingFileUploadController.updateDocument('Some-Category', new List<String>());
        Test.stopTest();

        // Verify no documents were changed
        List<ContentDocument> docs = [SELECT Id, Title FROM ContentDocument WHERE Title LIKE '%Some Category%'];
        System.assertEquals(0, docs.size(), 'No documents should be updated when empty list is provided');
    }
}