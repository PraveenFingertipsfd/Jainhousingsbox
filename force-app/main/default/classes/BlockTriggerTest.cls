@isTest
public class BlockTriggerTest {

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Apartments'
        );
        insert project;
    }

    @isTest
    static void testBlockInsert() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        Block__c block = new Block__c(
            Name = 'Tower A',
            Project__c = project.Id
        );
        insert block;
        Test.stopTest();

        Block__c insertedBlock = [SELECT Id, Name FROM Block__c WHERE Id = :block.Id];
        System.assertEquals('Tower A', insertedBlock.Name, 'Block should be inserted');
    }

    @isTest
    static void testBlockUpdate() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Block__c block = new Block__c(
            Name = 'Tower B',
            Project__c = project.Id
        );
        insert block;

        Test.startTest();
        block.Name = 'Tower B Updated';
        update block;
        Test.stopTest();

        Block__c updatedBlock = [SELECT Id, Name FROM Block__c WHERE Id = :block.Id];
        System.assertEquals('Tower B Updated', updatedBlock.Name, 'Block name should be updated');
    }

    @isTest
    static void testBlockDelete() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Block__c block = new Block__c(
            Name = 'Tower C',
            Project__c = project.Id
        );
        insert block;
        Id blockId = block.Id;

        Test.startTest();
        delete block;
        Test.stopTest();

        List<Block__c> deletedBlocks = [SELECT Id FROM Block__c WHERE Id = :blockId];
        System.assertEquals(0, deletedBlocks.size(), 'Block should be deleted');
    }

    @isTest
    static void testBulkBlockInsert() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        List<Block__c> blocks = new List<Block__c>();
        for (Integer i = 0; i < 200; i++) {
            blocks.add(new Block__c(
                Name = 'Tower ' + i,
                Project__c = project.Id
            ));
        }

        Test.startTest();
        insert blocks;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Block__c WHERE Project__c = :project.Id];
        System.assertEquals(200, count, 'All 200 blocks should be inserted');
    }
}