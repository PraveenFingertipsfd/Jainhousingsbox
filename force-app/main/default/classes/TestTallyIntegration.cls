@isTest
public class TestTallyIntegration {

    @testSetup
    static void setupData() {
        // Create a test user for Finance User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User financeUser = new User(
            Alias = 'finusr',
            Email = 'financeuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Finance',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'financeuser' + DateTime.now().getTime() + '@test.com'
        );
        insert financeUser;

        // Create Project
        Project__c proj = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Plots',
            Finance_User__c = financeUser.Id
        );
        insert proj;

        // Create Tower (Block)
        Block__c block = new Block__c(Name = 'Tower A');
        insert block;

        // Create Plot (Unit)
        Plot__c unit = new Plot__c(
            Name = 'Unit 101',
            Block__c = 'A2',
            Project__c = proj.Id,
            Project_Type__c = proj.Project_Type__c
        );
        insert unit;

      User financeUser1 = [SELECT Id FROM User WHERE Email = 'financeuser@test.com' LIMIT 1];

        Booking__c booking = new Booking__c(
         Stage__c = 'Reservation',
         Project1__c = proj.Id,
         Plot__c = unit.Id,
         Finance_User__c = financeUser1.Id,
         Booking_Date__c = Date.today()
       );
      insert booking;

    Booking_Request__c bookingReq = new Booking_Request__c(
      Stage__c = 'Cost Sheet Preparation',
      Booking__c = booking.Id,
      Unit__c = unit.Id,
      Mobile__c = '9999999999',
      Customer_Name__c = 'John Doe',
      Email__c = 'john@example.com',
      Aadhaar_Number__c = '123412341234',
      PAN_Number__c = 'ABCDE1234F',
      Customer_Responded_Date__c = Date.today()
     );
     insert bookingReq;

        // Create Advance Payment (Approved)
        Advance_Payment__c advPay = new Advance_Payment__c(
            Mode_of_Payment__c = 'Cheque',
            Bank__c = 'HDFC Bank',
            Cheque_no_Transaction_Number__c = '12345',
            Amount__c = 100000,
            Approval_Status__c = 'Approved',
            Booking_Request__c = bookingReq.Id,
            Receipt_Date__c = Date.today()
        );
        insert advPay;

        // Co-Applicant
        Co_Applicant__c coapp = new Co_Applicant__c(
            Name = 'Jane Doe',
            Booking__c = booking.Id,
            Email__c = 'jane@example.com'
        );
        insert coapp;

        // Receipt
        Receipt__c receipt = new Receipt__c(
            Booking__c = booking.Id,
            Approval_status__c = 'Approved by Finance Team',
            Amount_received__c = 50000,
            Receipt_date__c = Date.today()
        );
        insert receipt;

       Additional_Charges__c addCharge = new Additional_Charges__c(
         Booking__c = booking.Id,             // booking.Id where Finance_User__c IS SET
         Approval_Status__c = 'Approved',
         Amount__c = 20000
         );
         insert addCharge;

        // Payment Schedule
        Payment_schedule__c paySch = new Payment_schedule__c(
            Booking__c = booking.Id,
            S_No__c = 1
        );
        insert paySch;

        // Demand Raised
        Demand_Raised__c demand = new Demand_Raised__c(
            Booking__c = booking.Id,
            Current_Milestone__c = 'Foundation Complete',
            Milestone_Number__c = '1',
            Current_Demand_amount__c = 100000,
            Payment_schedule__c = paySch.Id
        );
        insert demand;
    }

    @isTest
    static void testGetBookingsNoFilters() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/api/bookings';
        req.httpMethod = 'GET';
        req.addParameter('limit', '10');
        req.addParameter('offset', '0');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<TallyIntegration.BookingWrapper> result = TallyIntegration.getBookings();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Response should not be null');
        System.assert(result.size() > 0, 'Should return at least one booking wrapper');
        System.assertEquals('John Doe', result[0].BookingRequest.customer, 'Customer name should match');
    }

    @isTest
    static void testGetBookingsNullStringParams() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/api/bookings';
        req.httpMethod = 'GET';
        req.addParameter('project', 'null');
        req.addParameter('tower', 'null');
        req.addParameter('unit', 'null');
        req.addParameter('limit', '10');
        req.addParameter('offset', '0');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<TallyIntegration.BookingWrapper> result = TallyIntegration.getBookings();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Response should not be null');
    }

    @isTest
    static void testGetBookingsRequestClosedWithDetails() {
        User finUser = [SELECT Id FROM User WHERE Email = 'financeuser@test.com' LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c unit = [SELECT Id FROM Plot__c LIMIT 1];

        Booking_Request__c closedReq = new Booking_Request__c(
            Stage__c = 'Request Successfully Closed',
            Unit__c = unit.Id,
            Mobile__c = '8888888888',
            Customer_Name__c = 'Alice Smith',
            Email__c = 'alice@example.com',
            Aadhaar_Number__c = '999988887777',
            PAN_Number__c = 'ZZZZZ9999Z',
            Customer_Responded_Date__c = Date.today()
        );
        insert closedReq;

        Quote__c costSheet = new Quote__c(
            Payment_Type__c = 'Standard',
            Booking_Request__c = closedReq.Id
        );
        insert costSheet;

        Booking__c bookingClosed = new Booking__c(
            Stage__c = 'Reservation',
            Project1__c = proj.Id,
            Plot__c = unit.Id,
            Finance_User__c = finUser.Id,
            Booking_Date__c = Date.today(),
            Cost_Sheet__c = costSheet.Id
        );
        insert bookingClosed;

        closedReq.Booking__c = bookingClosed.Id;
        update closedReq;

        Co_Applicant__c coapp = new Co_Applicant__c(
            Name = 'Bob Smith',
            Booking__c = bookingClosed.Id,
            Email__c = 'bob@example.com'
        );
        insert coapp;

        Receipt__c receipt = new Receipt__c(
            Booking__c = bookingClosed.Id,
            Approval_status__c = 'Approved by Finance Team',
            Amount_received__c = 75000,
            Receipt_date__c = Date.today()
        );
        insert receipt;

        Additional_Charges__c addCharge = new Additional_Charges__c(
            Booking__c = bookingClosed.Id,
            Approval_Status__c = 'Approved',
            Amount__c = 15000
        );
        insert addCharge;

        Payment_schedule__c paySch = new Payment_schedule__c(
            Booking__c = bookingClosed.Id,
            S_No__c = 1
        );
        insert paySch;

        Demand_Raised__c demand = new Demand_Raised__c(
            Booking__c = bookingClosed.Id,
            Current_Milestone__c = 'Slab Complete',
            Milestone_Number__c = '2',
            Current_Demand_amount__c = 200000,
            Payment_schedule__c = paySch.Id
        );
        insert demand;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/api/bookings';
        req.httpMethod = 'GET';
        req.addParameter('limit', '50');
        req.addParameter('offset', '0');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<TallyIntegration.BookingWrapper> result = TallyIntegration.getBookings();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Response should not be null');
        TallyIntegration.BookingWrapper closedWrapper = null;
        for (TallyIntegration.BookingWrapper w : result) {
            if (w.BookingRequest.customer == 'Alice Smith') {
                closedWrapper = w;
                break;
            }
        }
        System.assertNotEquals(null, closedWrapper, 'Should find the closed booking request');
        System.assertNotEquals(null, closedWrapper.BookingRequest.Bookings, 'Bookings response should not be null');
        System.assertNotEquals(null, closedWrapper.BookingRequest.CoApplicants, 'CoApplicants should not be null');
        System.assertNotEquals(null, closedWrapper.BookingRequest.Receipts, 'Receipts should not be null');
        System.assertNotEquals(null, closedWrapper.BookingRequest.AdditionalCharges, 'AdditionalCharges should not be null');
        System.assertNotEquals(null, closedWrapper.BookingRequest.Schedules, 'Schedules should not be null');
        System.assertNotEquals(null, closedWrapper.BookingRequest.Demands, 'Demands should not be null');
    }

    @isTest
    static void testGetBookingsNoBookingRef() {
        Plot__c unit = [SELECT Id FROM Plot__c LIMIT 1];

        Booking_Request__c noBookingReq = new Booking_Request__c(
            Stage__c = 'Cost Sheet Preparation',
            Unit__c = unit.Id,
            Mobile__c = '7777777777',
            Customer_Name__c = 'No Booking Customer',
            Email__c = 'nobooking@example.com',
            Customer_Responded_Date__c = Date.today()
        );
        insert noBookingReq;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/api/bookings';
        req.httpMethod = 'GET';
        req.addParameter('limit', '50');
        req.addParameter('offset', '0');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<TallyIntegration.BookingWrapper> result = TallyIntegration.getBookings();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Response should not be null');
        System.assert(result.size() > 0, 'Should return results');
    }

    @isTest
    static void testGetBookingsDefaultPagination() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/api/bookings';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<TallyIntegration.BookingWrapper> result = TallyIntegration.getBookings();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Response should not be null');
    }
}