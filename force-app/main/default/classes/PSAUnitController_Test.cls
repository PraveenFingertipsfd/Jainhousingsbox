@isTest
public class PSAUnitController_Test {

    @isTest
    static void testFetchRecords() {

        // Step 1️⃣: Create a Project record with Project_Type__c = 'Plot'
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Plots',    // important for lookup filter
            Active__c = true
            
        );
        insert project;

        // Step 2️⃣: Create Plot record (Unit) with SAME Project_Type__c = 'Plot'
        Plot__c plotRec = new Plot__c(
            Name = 'Plot 101',
            Project__c = project.Id,
            Project_Type__c = 'Plots',   // must match parent Project value
            Status__c = 'Available',
            Is_PSA_Unit__c = false
        );
        insert plotRec;

        // Step 3️⃣: Create Booking Request linked to the Plot
        Booking_Request__c bookingReq = new Booking_Request__c(
            //Name = 'Test Booking Request',
            Unit__c = plotRec.Id,
            Blocked_Price__c = 250000
        );
        insert bookingReq;

        // Step 4️⃣: Run the controller method
        Test.startTest();
        PSAUnitController.DataWrapper result = PSAUnitController.fetchRecords(bookingReq.Id);
        Test.stopTest();

        // Step 5️⃣: Validate results
        System.assertNotEquals(null, result, 'DataWrapper result should not be null');
        System.assertEquals(250000, result.BlockedPrice, 'Blocked Price should match');
        System.assert(result.PlotLst.size() > 0, 'There should be available plots');
    }
}