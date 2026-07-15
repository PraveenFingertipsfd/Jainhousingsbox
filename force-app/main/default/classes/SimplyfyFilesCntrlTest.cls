@IsTest
public class SimplyfyFilesCntrlTest {

    @TestSetup
    static void setupData() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Insert a ContentVersion....
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test file content'),
            FirstPublishLocationId = acc.Id
        );
        insert cv;

        
    }

    @IsTest
    static void testGetFiles() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<ContentDocument> docs = SimplyfyFilesCntrl.getFiles(acc.Id);
        Test.stopTest();

        System.assertNotEquals(0, docs.size(), 'Should return at least 1 ContentDocument');
        System.assertEquals('TestFile', docs[0].Title, 'Title should match the inserted file');
    }

    @IsTest
    static void testUpdateFiles() {
        // Get the ContentDocument Id from the inserted file...
        ContentDocument doc = [SELECT Id, Title FROM ContentDocument LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String newTitle = 'UpdatedFile';

        Test.startTest();
        List<ContentDocument> updatedDocs = SimplyfyFilesCntrl.UpdateFiles(doc.Id, newTitle, acc.Id);
        Test.stopTest();

        System.assertNotEquals(0, updatedDocs.size(), 'Should return updated documents');
        System.assertEquals(newTitle, updatedDocs[0].Title, 'File title should be updated');
    }
}