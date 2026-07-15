@isTest
public class BookingRequest_ControllerTest {

    //Utility method to create Project record (required for Plot)
    private static Project__c createProject() {
        Project__c proj = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Plots'
        );
        insert proj;
        return proj;
    }

    //Utility: Create Plot record with required lookup
    private static Plot__c createPlotRecord() {
        Project__c proj = createProject(); // Ensure Project__c exists
        Plot__c plt = new Plot__c(
            Name = 'Test Plot',
            Plot_Number__c = 'P-101',
            Status__c = 'Available',
            Project__c = proj.Id ,
            Project_Type__c = 'Plots'
        );
        insert plt;
        return plt;
    }

    //Utility: Create Booking Request record
    private static Booking_Request__c createBookingRequest(Id unitId) {
        Booking_Request__c brq = new Booking_Request__c(
            Unit__c = unitId,
            Email__c = 'test@test.com',
            IsResponded__c = false,
            Stage__c = 'Waiting for Response'
        );
        insert brq;
        return brq;
    }

    @isTest
    static void test_sendBookingRequest() {
        Plot__c plt = createPlotRecord();

        Test.startTest();
        String result = BookingRequest_Controller.send_Booking_Request(
            plt.Id,
            'customer@example.com',
            500000
        );
        Test.stopTest();

        System.assertEquals('Success', result);
        Plot__c updatedPlot = [SELECT Status__c FROM Plot__c WHERE Id = :plt.Id];
        System.assertEquals('Blocked', updatedPlot.Status__c);
    }

    @isTest
    static void test_GetUnitDetails() {
        Plot__c plt = createPlotRecord();
        Booking_Request__c brq = createBookingRequest(plt.Id);

        Test.startTest();
        BookingRequest_Controller.UnitWrapper result = BookingRequest_Controller.GetUnitDetails(plt.Id, brq.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.UnitRec);
        System.assertEquals(brq.IsResponded__c, result.IsFormResponded);
    }

    

    @isTest
    static void test_checkEmailExists() {
        Plot__c plt = createPlotRecord();
        Booking_Request__c brq = createBookingRequest(plt.Id);

        Test.startTest();
        Boolean emailExists = BookingRequest_Controller.check_EmailExists(brq.Id);
        Test.stopTest();

        System.assert(emailExists);
    }

    @isTest
    static void test_createAdvancePayment() {
        Advance_Payment__c adv = new Advance_Payment__c(
           
            Mode_of_Payment__c = 'Cash'
        );

        Test.startTest();
        Id paymentId = BookingRequest_Controller.createAdvancePayment(adv);
        Test.stopTest();

        System.assertNotEquals(null, paymentId);
    }

    @isTest
    static void test_getPicklistValues() {
        Test.startTest();
        Map<String, List<String>> values = BookingRequest_Controller.getPicklistValues();
        Test.stopTest();

        System.assert(values.containsKey('paymentModes'));
        System.assert(values.containsKey('banks'));
    }

    @isTest
    static void test_InsertBookingReq() {
        Plot__c plt = createPlotRecord();
        Booking_Request__c brq = createBookingRequest(plt.Id);
        Advance_Payment__c adv = new Advance_Payment__c(
            
            Mode_of_Payment__c = 'Cash'
        );

        Test.startTest();
        BookingRequest_Controller.InsertBookingReq(brq, adv);
        Test.stopTest();

        System.assertNotEquals(null, brq.Id);
    }

    @isTest
    static void test_abandonBookingRequest() {
        Plot__c plt = createPlotRecord();
        Booking_Request__c brq = createBookingRequest(plt.Id);

        Quote__c qt = new Quote__c(
            
            Booking_Request__c = brq.Id
            
        );
        insert qt;

        Test.startTest();
        BookingRequest_Controller.AbandonResult result = BookingRequest_Controller.abandonBookingRequest(brq.Id);
        Test.stopTest();

        System.assert(result.isSuccess);
    }
}