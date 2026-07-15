@isTest
public class UnitPriceChangeControllerTest {

    @isTest
    static void testAllMethods() {

        //Create a Project record with Project_Type = 'Apartments'
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Apartments',
            Active__c = true
        );
        insert project;

        //Create a Block record linked to the Project
        Block__c block = new Block__c(
            Name = 'Block A',
            Project__c = project.Id
        );
        insert block;

        //Create a Plot record (Unit)
        Plot__c plotRec = new Plot__c(
            Name = 'Plot 101',
            Project__c = project.Id,
            Project_Type__c = 'Apartments', 
            Status__c = 'Available',
            BHK_Type__c = '2 BHK', 
            Block1__c = block.Id,
            Is_PSA_Unit__c = false
        );
        insert plotRec;

        Test.startTest();

        //Call all methods in the controller

        // Picklist methods
        Map<String, String> bhkTypeMap = UnitPriceChangeController.getBhkType();
        System.assertNotEquals(null, bhkTypeMap);

        Map<String, String> unitStatusMap = UnitPriceChangeController.getUnitStatus();
        System.assertNotEquals(null, unitStatusMap);

        Map<String, String> blocksMap = UnitPriceChangeController.getBlocks();
        System.assertNotEquals(null, blocksMap);

        // Get tower details
        Map<String, String> towerMap = UnitPriceChangeController.getTowers(project.Id);
        System.assertNotEquals(null, towerMap);

        // Get user list
        List<User> users = UnitPriceChangeController.getuserdetails();
        System.assertNotEquals(null, users);

        // Get plots list
        List<Plot__c> plots = UnitPriceChangeController.getcon(
            UserInfo.getUserId(),
            project.Id,
            '2 BHK',
            'Available',
            null,
            'Block A'
        );
        System.assertNotEquals(null, plots);

        // Update price
        List<Plot__c> updateList = new List<Plot__c>{ plotRec };
        List<Plot__c> updatedPlots = UnitPriceChangeController.updateOwner(updateList, 5000);
        System.assertNotEquals(null, updatedPlots);

        Test.stopTest();
    }
}