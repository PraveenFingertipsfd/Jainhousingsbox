@isTest
public class TestSwappingUnitController {

    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User financeUser = new User(
            Username = 'swapfin-' + System.currentTimeMillis() + '@test.com',
            Email = 'swapfin@test.com',
            LastName = 'SwapFinance',
            Alias = 'sfin',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert financeUser;

        Project__c proj = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments',
            Finance_User__c = financeUser.Id
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Test Plot',
            Block__c = 'A2',
            Project__c = proj.Id,
            Project_Type__c = 'Apartments',
            Floor__c = '1',
            Price_Per_Sq_Ft__c = 2000,
            Floor_Rise__c = 100,
            Premium_Charge__c = 50
        );
        insert plot;

        Booking__c booking = new Booking__c(
            Project__c = 'Jains Anushree',
            Project1__c = proj.Id,
            Plot__c = plot.Id,
            Payment_Type__c = 'Standard',
            Sale_Agreement_Completed__c = false,
            First_Disbursement_Received__c = false
        );
        insert booking;

        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Name = 'Test Master Schedule',
            Project__c = proj.Id,
            Project_Type__c = 'Apartments',
            S_No__c = 1,
            Payment_Percent__c = 10,
            Amount__c = 1000
        );
        insert mps;
    }

    // -------------------- Test getBooking --------------------
    @isTest
    static void test_getBooking() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Booking__c result = SwappingUnitController.getBooking(booking.Id);
        Test.stopTest();

        System.assertEquals(booking.Id, result.Id, 'Booking should be fetched correctly');
    }

    // -------------------- Test getUnit --------------------
    @isTest
    static void test_getUnit() {
        Plot__c plot = [SELECT Id FROM Plot__c LIMIT 1];

        Test.startTest();
        Plot__c result = SwappingUnitController.getUnit(plot.Id);
        Test.stopTest();

        System.assertEquals(plot.Id, result.Id, 'Plot should be fetched correctly');
    }

    // -------------------- Test saveOppPlot --------------------
    @isTest
    static void test_saveOppPlot() {
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company'
        );
        insert testLead;

        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        booking.SLead__c = testLead.Id;
        update booking;

        Booking__c oppBooking = new Booking__c(
            Id = booking.Id,
            Swap_Unit__c = 'B-202'
        );

        Test.startTest();
        String resultId = SwappingUnitController.saveOppPlot(oppBooking, booking.Id);
        Test.stopTest();

        System.assertEquals(booking.Id, resultId, 'Returned Id should match booking Id');
    }

    // -------------------- Test getPaymentTypePicklistValues --------------------
    @isTest
    static void test_getPaymentTypePicklistValues() {
        Test.startTest();
        List<String> picklistValues = SwappingUnitController.getPaymentTypePicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, picklistValues, 'Picklist values should not be null');
    }

    // -------------------- Test getPaymentSchedules --------------------
    @isTest
    static void test_getPaymentSchedules() {
        Project__c proj = [SELECT Id, Name FROM Project__c LIMIT 1];

        Test.startTest();
        List<Master_Payment_Schedule__c> schedules = SwappingUnitController.getPaymentSchedules('Standard', proj.Name);
        Test.stopTest();

        System.assert(schedules.size() > 0, 'Should fetch Master Payment Schedule records');
    }

    // -------------------- Test insertSchedules --------------------
    @isTest
    static void test_insertSchedules() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Payment_Schedule__c pay1 = new Payment_Schedule__c(
            Name = 'Test Payment 1',
            Payment_Percent__c = 10,
            Amount__c = 5000,
            Payment_Due_Date__c = Date.today(),
            S_No__c = 1,
            Booking__c = booking.Id
        );

        List<Payment_Schedule__c> payList = new List<Payment_Schedule__c>{ pay1 };

        Test.startTest();
        SwappingUnitController.insertSchedules(payList, booking.Id);
        Test.stopTest();

        List<Payment_Schedule__c> inserted = [
            SELECT Id FROM Payment_Schedule__c WHERE Booking__c = :booking.Id
        ];
        System.assert(inserted.size() > 0, 'Payment schedules should be inserted successfully');
    }
}