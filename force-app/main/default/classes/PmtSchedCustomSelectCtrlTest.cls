@isTest
public class PmtSchedCustomSelectCtrlTest {

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments'
        );
        insert project;

        Plot__c plot = new Plot__c(
            Name = 'Unit A101',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = 'Apartments'
        );
        insert plot;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User financeUser = new User(
            Username = 'finance-' + System.currentTimeMillis() + '@test.com',
            Email = 'finance@test.com',
            LastName = 'Finance',
            Alias = 'fin',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert financeUser;

        // Property_Type_For__c is a formula field - not writable
        Booking__c bookingApt = new Booking__c(
            Project__c = 'Jains Anushree',
            Project1__c = project.Id,
            GST__c = 5,
            Finance_User__c = financeUser.Id,
            Plot__c = plot.Id
        );
        insert bookingApt;

        // Master Payment Schedule for apartments
        Master_Payment_Schedule__c mps1 = new Master_Payment_Schedule__c(
            Name = 'Booking Advance',
            S_No__c = 1,
            Project__c = project.Id,
			Project_Type__c = 'Apartments',
            Payment_percent__c = 10,
            Status__c = 'Completed',
            Completed_Date__c = Date.today().addDays(-30)
        );
        insert mps1;

        Master_Payment_Schedule__c mps2 = new Master_Payment_Schedule__c(
            Name = 'Foundation',
            S_No__c = 2,
            Project__c = project.Id,
            Project_Type__c = 'Apartments',
            Payment_percent__c = 15,
            Status__c = 'Completed',
            Completed_Date__c = Date.today().addDays(-10)
        );
        insert mps2;

        // Payment schedules for booking
        // Completed_Date__c on Payment_Schedule__c is a formula field - not writable
        Payment_Schedule__c ps1 = new Payment_Schedule__c(
            Booking__c = bookingApt.Id,
            S_No__c = 1,
            Master_Payment_Schedule__c = mps1.Id,
            Payment_percent__c = 10,
            Status__c = 'Completed'
        );
        insert ps1;

        Payment_Schedule__c ps2 = new Payment_Schedule__c(
            Booking__c = bookingApt.Id,
            S_No__c = 2,
            Master_Payment_Schedule__c = mps2.Id,
            Payment_percent__c = 15
        );
        insert ps2;
    }

    @isTest
    static void testGetPaymentSchedules() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        List<Payment_Schedule__c> schedules = PaymentScheduleCustomSelectController.getPaymentSchedules(booking.Id);
        Test.stopTest();

        System.assertNotEquals(0, schedules.size(), 'Should return payment schedules');
    }

    @isTest
    static void testRaiseDemand() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Payment_Schedule__c ps = [SELECT Id, Master_Payment_Schedule__c FROM Payment_Schedule__c WHERE Booking__c = :booking.Id AND S_No__c = 2 LIMIT 1];

        Test.startTest();
        String result = PaymentScheduleCustomSelectController.raiseDemand(ps.Id, 'Test demand content', new List<Id>());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetMilestoneLabel() {
        Test.startTest();
        System.assertEquals('1st', PaymentScheduleCustomSelectController.getMilestoneLabel(1));
        System.assertEquals('2nd', PaymentScheduleCustomSelectController.getMilestoneLabel(2));
        System.assertEquals('3rd', PaymentScheduleCustomSelectController.getMilestoneLabel(3));
        System.assertEquals('4th', PaymentScheduleCustomSelectController.getMilestoneLabel(4));
        System.assertEquals('10th', PaymentScheduleCustomSelectController.getMilestoneLabel(10));
        System.assertEquals('21st', PaymentScheduleCustomSelectController.getMilestoneLabel(21));
        System.assertEquals('22nd', PaymentScheduleCustomSelectController.getMilestoneLabel(22));
        System.assertEquals('23rd', PaymentScheduleCustomSelectController.getMilestoneLabel(23));
        System.assertEquals('31st', PaymentScheduleCustomSelectController.getMilestoneLabel(31));
        System.assertEquals('Invalid milestone', PaymentScheduleCustomSelectController.getMilestoneLabel(null));
        Test.stopTest();
    }

    @isTest
    static void testRaiseDemandNoPropertyType() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Username = 'notype-' + System.currentTimeMillis() + '@test.com',
            Email = 'notype@test.com',
            LastName = 'NoType',
            Alias = 'ntyp',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        Booking__c booking = new Booking__c(
            Finance_User__c = u.Id
        );
        insert booking;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c = booking.Id,
            S_No__c = 1
        );
        insert ps;

        Test.startTest();
        String result = PaymentScheduleCustomSelectController.raiseDemand(ps.Id, '', new List<Id>());
        Test.stopTest();

        System.assertEquals('', result, 'Should return empty string for no property type');
    }

    @isTest
    static void testRaiseDemandVillas() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User finUser = new User(
            Username = 'villa-' + System.currentTimeMillis() + '@test.com',
            Email = 'villa@test.com',
            LastName = 'Villa',
            Alias = 'vil',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert finUser;

        Project__c villaProject = new Project__c(
            Name = 'Villa Project',
            Project_Type__c = 'Villas'
        );
        insert villaProject;

        Plot__c villaPlot = new Plot__c(
            Name = 'Villa V1',
            Status__c = 'Available',
            Project__c = villaProject.Id,
            Project_Type__c = 'Villas'
        );
        insert villaPlot;

        Booking__c villaBooking = new Booking__c(
            Project__c = 'Jains Anushree',
            Project1__c = villaProject.Id,
            GST__c = 5,
            Finance_User__c = finUser.Id,
            Plot__c = villaPlot.Id
        );
        insert villaBooking;

        Payment_Schedule__c vps1 = new Payment_Schedule__c(
            Booking__c = villaBooking.Id,
            S_No__c = 1,
            Payment_percent__c = 10,
            Status__c = 'Completed'
        );
        insert vps1;

        Payment_Schedule__c vps2 = new Payment_Schedule__c(
            Booking__c = villaBooking.Id,
            S_No__c = 2,
            Payment_percent__c = 15
        );
        insert vps2;

        Test.startTest();
        String result = PaymentScheduleCustomSelectController.raiseDemand(vps2.Id, 'Villa demand content', new List<Id>());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null for villas');
    }
}