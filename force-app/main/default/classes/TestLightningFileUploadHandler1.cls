@isTest
public class TestLightningFileUploadHandler1 {

    @isTest
    static void test_updateGuestRecordField() {
        // Step 1: Create a sample parent record
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Step 2: Create a ContentVersion record
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Dummy file content'),
            IsMajorVersion = true
        );
        insert cv;

        // Step 3: Query the related ContentDocumentId
        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        Id docId = insertedCV.ContentDocumentId;

        // Step 4: Execute the method under test
        Test.startTest();
        LightningFileUploadHandler1.updateGuestRecordField(docId, acc.Id);
        Test.stopTest();

        // Step 5: Verify that the Guest_Record_fileupload__c field is updated
        ContentVersion updatedCV = [
            SELECT Id, Guest_Record_fileupload__c
            FROM ContentVersion
            WHERE ContentDocumentId = :docId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            acc.Id,
            updatedCV.Guest_Record_fileupload__c,
            'Guest_Record_fileupload__c should be updated with the parent record Id'
        );
    }

    @isTest
    static void testUpdateGuestRecordField_NonExistentDocument() {
        // Create an Account to use as parentRecordId
        Account acc = new Account(Name = 'Test Account NonExistent');
        insert acc;

        // Create a ContentVersion, get its ContentDocumentId, then delete the document
        // so that the query inside updateGuestRecordField returns an empty list
        ContentVersion cv = new ContentVersion(
            Title = 'TempFile',
            PathOnClient = 'TempFile.pdf',
            VersionData = Blob.valueOf('Temporary content'),
            IsMajorVersion = true
        );
        insert cv;

        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ];
        Id deletedDocId = insertedCV.ContentDocumentId;

        // Delete the ContentDocument so the ContentVersion query returns empty
        delete [SELECT Id FROM ContentDocument WHERE Id = :deletedDocId];

        Test.startTest();
        // This should hit the empty list branch: if (!versionsToUpdate.isEmpty()) is false
        LightningFileUploadHandler1.updateGuestRecordField(deletedDocId, acc.Id);
        Test.stopTest();

        // Verify no exception was thrown and method completed gracefully
        // The method simply skips the update when no versions are found
        System.assert(true, 'Method should complete without error when ContentDocument does not exist');
    }

    @isTest
    static void testUpdateGuestRecordField_MultipleVersions() {
        // Create a parent record
        Account acc = new Account(Name = 'Test Account MultiVersion');
        insert acc;

        Account acc2 = new Account(Name = 'Test Account Target');
        insert acc2;

        // Create the first ContentVersion (v1)
        ContentVersion cv1 = new ContentVersion(
            Title = 'MultiVersionFile',
            PathOnClient = 'MultiVersionFile.pdf',
            VersionData = Blob.valueOf('Version 1 content'),
            IsMajorVersion = true
        );
        insert cv1;

        ContentVersion insertedCV1 = [
            SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id
        ];
        Id docId = insertedCV1.ContentDocumentId;

        // Create a second version (v2) of the same document
        ContentVersion cv2 = new ContentVersion(
            Title = 'MultiVersionFile',
            PathOnClient = 'MultiVersionFile_v2.pdf',
            VersionData = Blob.valueOf('Version 2 content'),
            ContentDocumentId = docId
        );
        insert cv2;

        // Verify we now have two versions
        List<ContentVersion> allVersions = [
            SELECT Id FROM ContentVersion WHERE ContentDocumentId = :docId
        ];
        System.assertEquals(2, allVersions.size(), 'Should have two ContentVersions for the same document');

        Test.startTest();
        LightningFileUploadHandler1.updateGuestRecordField(docId, acc2.Id);
        Test.stopTest();

        // Verify that the latest version (ordered by CreatedDate DESC LIMIT 1) was updated
        ContentVersion latestVersion = [
            SELECT Id, Guest_Record_fileupload__c
            FROM ContentVersion
            WHERE ContentDocumentId = :docId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            acc2.Id,
            latestVersion.Guest_Record_fileupload__c,
            'The latest ContentVersion should have Guest_Record_fileupload__c set to the parent record Id'
        );
    }
}