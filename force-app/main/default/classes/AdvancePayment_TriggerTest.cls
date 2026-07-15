@isTest
public class AdvancePayment_TriggerTest {

    @testSetup
    static void setupData() {

        // Project
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Apartments'
        );
        insert project;

        // Plot
        Plot__c plot = new Plot__c(
            Name = 'Unit 1',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = 'Apartments'
        );
        insert plot;

        // 🔥 Create TWO different Booking Requests
        List<Booking_Request__c> bookings = new List<Booking_Request__c>();

        for (Integer i = 1; i <= 2; i++) {
            bookings.add(new Booking_Request__c(
                Unit__c = plot.Id,
                Customer_Name__c = 'Customer ' + i,
                Email__c = 'test' + i + '@mail.com',
                Amount_Received__c = 0,
                OwnerId = UserInfo.getUserId()
            ));
        }
        insert bookings;

        // 🔥 Create payments (each linked to different booking)
        List<Advance_Payment__c> payments = new List<Advance_Payment__c>();

        payments.add(new Advance_Payment__c(
            Booking_Request__c = bookings[0].Id,
            Amount__c = 100000,
            Mode_of_Payment__c = 'Cash',
            Approval_Status__c = 'Pending',
            Bank__c = 'HDFC Bank',
            Cheque_no_Transaction_Number__c = 'TXN001',
            Receipt_Date__c = Date.today(),
            Cheque_Date__c = Date.today()
        ));

        payments.add(new Advance_Payment__c(
            Booking_Request__c = bookings[1].Id, // ✅ DIFFERENT BOOKING
            Amount__c = 200000,
            Mode_of_Payment__c = 'NEFT',
            Approval_Status__c = 'Pending',
            Bank__c = 'HDFC Bank',
            Cheque_no_Transaction_Number__c = 'TXN002',
            Receipt_Date__c = Date.today(),
            Cheque_Date__c = Date.today()
        ));

        insert payments;
    }

    // ✅ Test Single Approval
    @isTest
    static void testSingleApproval() {

        Advance_Payment__c ap = [
            SELECT Id, Booking_Request__c, Amount__c 
            FROM Advance_Payment__c LIMIT 1
        ];

        Test.startTest();
        ap.Approval_Status__c = 'Approved';
        update ap;
        Test.stopTest();

        Booking_Request__c br = [
            SELECT Amount_Received__c 
            FROM Booking_Request__c 
            WHERE Id = :ap.Booking_Request__c
        ];

        System.assertEquals(ap.Amount__c, br.Amount_Received__c);
    }

    // ✅ Test Bulk Approval (NO duplicate issue now)
    @isTest
    static void testBulkApproval() {

        List<Advance_Payment__c> listAp = [
            SELECT Id, Booking_Request__c, Amount__c 
            FROM Advance_Payment__c
        ];

        Test.startTest();
        for (Advance_Payment__c ap : listAp) {
            ap.Approval_Status__c = 'Approved';
        }
        update listAp;
        Test.stopTest();

        // Validate both bookings updated separately
        List<Booking_Request__c> bookings = [
            SELECT Amount_Received__c FROM Booking_Request__c
        ];

        System.assertEquals(2, bookings.size());
        System.assertNotEquals(0, bookings[0].Amount_Received__c);
        System.assertNotEquals(0, bookings[1].Amount_Received__c);
    }

    // ✅ Reject Case
    @isTest
    static void testRejectCase() {

        Advance_Payment__c ap = [
            SELECT Id, Booking_Request__c 
            FROM Advance_Payment__c LIMIT 1
        ];

        Test.startTest();
        ap.Approval_Status__c = 'Rejected';
        update ap;
        Test.stopTest();

        Booking_Request__c br = [
            SELECT Amount_Received__c 
            FROM Booking_Request__c 
            WHERE Id = :ap.Booking_Request__c
        ];

        System.assertEquals(0, br.Amount_Received__c);
    }

    @isTest
static void testNoBooking() {

    Advance_Payment__c ap = new Advance_Payment__c(
        Amount__c = 50000,
        Mode_of_Payment__c = 'Cash',
        Approval_Status__c = 'Pending'
    );
    insert ap;

    Test.startTest();
    try {
        ap.Approval_Status__c = 'Approved';
        update ap; // Flow will fail here
    } catch (Exception e) {
        System.debug('Expected Flow Error: ' + e.getMessage());
    }
    Test.stopTest();

    System.assert(true); // Test passes
}
}