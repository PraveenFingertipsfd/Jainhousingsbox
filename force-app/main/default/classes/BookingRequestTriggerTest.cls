@isTest
public class BookingRequestTriggerTest {

    @TestSetup
    static void setupData() {
        Project__c proj = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Plots'
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Test Plot',
            Plot_Number__c = 'TP-001',
            Status__c = 'Booked',
            Project__c = proj.Id,
            Project_Type__c = 'Plots'
        );
        insert plot;

        Booking_Request__c bookingReq = new Booking_Request__c(
            Unit__c = plot.Id,
            Email__c = 'brtrigger@test.com',
            IsResponded__c = false,
            Stage__c = 'Waiting for Response'
        );
        insert bookingReq;
    }

    @isTest
    static void testUpdate_Abandoned_PlotBecomesAvailable() {
        Booking_Request__c req = [SELECT Id, Unit__c, Stage__c FROM Booking_Request__c LIMIT 1];

        Test.startTest();
        req.Stage__c = 'Request Abandoned';
        try {
            update req;
        } catch (Exception e) {
            // Approval process cancellation may fail if process does not exist in sandbox
            System.debug('Expected exception during approval cancellation: ' + e.getMessage());
        }
        Test.stopTest();

        Plot__c updatedPlot = [SELECT Id, Status__c FROM Plot__c WHERE Id = :req.Unit__c];
        System.assertEquals('Available', updatedPlot.Status__c,
            'Plot status should be set to Available when booking request is abandoned');

        Booking_Request__c updatedReq = [SELECT Id, Stage__c FROM Booking_Request__c WHERE Id = :req.Id];
        System.assertEquals('Request Abandoned', updatedReq.Stage__c,
            'Stage should remain Request Abandoned');
    }

    @isTest
    static void testUpdate_SuccessfullyClosed() {
        Booking_Request__c req = [SELECT Id, Unit__c, Stage__c FROM Booking_Request__c LIMIT 1];
        Id plotId = req.Unit__c;

        Test.startTest();
        req.Stage__c = 'Request Successfully Closed';
        try {
            update req;
        } catch (Exception e) {
            // Approval process cancellation may fail if process does not exist in sandbox
            System.debug('Expected exception during approval cancellation: ' + e.getMessage());
        }
        Test.stopTest();

        Plot__c plot = [SELECT Id, Status__c FROM Plot__c WHERE Id = :plotId];
        System.assertNotEquals('Available', plot.Status__c,
            'Plot status should NOT change to Available for Successfully Closed stage');

        Booking_Request__c updatedReq = [SELECT Id, Stage__c FROM Booking_Request__c WHERE Id = :req.Id];
        System.assertEquals('Request Successfully Closed', updatedReq.Stage__c,
            'Stage should be Request Successfully Closed');
    }

    @isTest
    static void testUpdate_NoStageChange() {
        Booking_Request__c req = [SELECT Id, Unit__c, Stage__c, Email__c FROM Booking_Request__c LIMIT 1];
        Id plotId = req.Unit__c;

        // Query plot status before
        Plot__c plotBefore = [SELECT Id, Status__c FROM Plot__c WHERE Id = :plotId];
        String statusBefore = plotBefore.Status__c;

        Test.startTest();
        // Update a non-stage field - stage stays the same
        req.Email__c = 'updated@test.com';
        update req;
        Test.stopTest();

        Plot__c plotAfter = [SELECT Id, Status__c FROM Plot__c WHERE Id = :plotId];
        System.assertEquals(statusBefore, plotAfter.Status__c,
            'Plot status should not change when Stage is not updated');
    }
}