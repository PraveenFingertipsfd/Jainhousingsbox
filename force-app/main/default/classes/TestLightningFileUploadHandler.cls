@isTest
public class TestLightningFileUploadHandler {

    @isTest
    static void test_getFiles_and_deleteFile() {
        // Step 1: Create a sample Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Step 2: Create a ContentVersion (auto-creates a ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Dummy data'),
            IsMajorVersion = true
        );
        insert cv;

        // Step 3: Retrieve related ContentDocumentId
        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        Id docId = insertedCV.ContentDocumentId;

        // Step 4: Link document to Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = acc.Id,
            ContentDocumentId = docId,
            ShareType = 'V'
        );
        insert cdl;

        // Step 5: Prepare Id list
        List<String> IdsList = new List<String>{String.valueOf(docId)};

        // Step 6: Run all test logic between one start/stop block
        Test.startTest();

        // Call getFiles()
        List<ContentDocument> files = LightningFileUploadHandler.getFiles(acc.Id, IdsList);
        System.assertEquals(1, files.size(), 'Should return one ContentDocument');
        System.assertEquals('TestFile', files[0].Title, 'Title should match the inserted document');

        // Call deleteFile()
        LightningFileUploadHandler.deleteFile(docId);

        Test.stopTest();

        // Step 7: Verify deletion
        Integer countAfterDelete = [SELECT COUNT() FROM ContentDocument WHERE Id = :docId];
        System.assertEquals(0, countAfterDelete, 'ContentDocument should be deleted');
    }

    @isTest
    static void testGetFiles_EmptyList() {
        // Create a sample Account to use as recordId
        Account acc = new Account(Name = 'Test Account Empty');
        insert acc;

        List<String> emptyIdsList = new List<String>();

        Test.startTest();
        List<ContentDocument> files = LightningFileUploadHandler.getFiles(acc.Id, emptyIdsList);
        Test.stopTest();

        System.assertNotEquals(null, files, 'Result should not be null');
        System.assertEquals(0, files.size(), 'Should return zero ContentDocuments for an empty IdsList');
    }

    @isTest
    static void testGetFiles_NoMatchingDocuments() {
        // Create a sample Account to use as recordId
        Account acc = new Account(Name = 'Test Account NoMatch');
        insert acc;

        // Create a ContentVersion so we have a valid ContentDocument, but do NOT pass its Id
        ContentVersion cv = new ContentVersion(
            Title = 'UnrelatedFile',
            PathOnClient = 'UnrelatedFile.pdf',
            VersionData = Blob.valueOf('Unrelated data'),
            IsMajorVersion = true
        );
        insert cv;

        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ];

        // Link to account so the query inside getFiles finds links
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = acc.Id,
            ContentDocumentId = insertedCV.ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;

        // Pass a completely different, fabricated-but-valid-format Id list that won't match
        // Use an Id from a different ContentDocument that does not exist
        // We create a second doc and delete it to get a non-matching but formerly valid Id
        ContentVersion cv2 = new ContentVersion(
            Title = 'ToBeDeleted',
            PathOnClient = 'ToBeDeleted.pdf',
            VersionData = Blob.valueOf('Delete me'),
            IsMajorVersion = true
        );
        insert cv2;

        ContentVersion insertedCV2 = [
            SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id
        ];
        Id deletedDocId = insertedCV2.ContentDocumentId;
        delete [SELECT Id FROM ContentDocument WHERE Id = :deletedDocId];

        List<String> nonMatchingIdsList = new List<String>{ String.valueOf(deletedDocId) };

        Test.startTest();
        List<ContentDocument> files = LightningFileUploadHandler.getFiles(acc.Id, nonMatchingIdsList);
        Test.stopTest();

        System.assertEquals(0, files.size(), 'Should return zero ContentDocuments when IdsList has no matching documents');
    }

    @isTest
    static void testDeleteFile_Separate() {
        // Create a ContentVersion (auto-creates a ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'FileToDelete',
            PathOnClient = 'FileToDelete.pdf',
            VersionData = Blob.valueOf('Delete this file'),
            IsMajorVersion = true
        );
        insert cv;

        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ];
        Id docId = insertedCV.ContentDocumentId;

        // Verify the document exists before deletion
        Integer countBefore = [SELECT COUNT() FROM ContentDocument WHERE Id = :docId];
        System.assertEquals(1, countBefore, 'ContentDocument should exist before deletion');

        Test.startTest();
        LightningFileUploadHandler.deleteFile(docId);
        Test.stopTest();

        Integer countAfter = [SELECT COUNT() FROM ContentDocument WHERE Id = :docId];
        System.assertEquals(0, countAfter, 'ContentDocument should be deleted after calling deleteFile');
    }
}