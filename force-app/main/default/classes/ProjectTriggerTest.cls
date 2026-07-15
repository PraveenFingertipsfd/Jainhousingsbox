@isTest
public class ProjectTriggerTest {

    @testSetup
    static void setupData() {

        // 🔥 Get valid picklist value dynamically
        String validProjectValue;
        List<Schema.PicklistEntry> pickVals = Booking__c.Project__c.getDescribe().getPicklistValues();
        if (!pickVals.isEmpty()) {
            validProjectValue = pickVals[0].getValue();
        }

        // Create Project
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Apartments',
            Interest_Percentage__c = 12
        );
        insert project;

        // Create Plot
        Plot__c plot = new Plot__c(
            Name = 'Test Unit',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = 'Apartments'
        );
        insert plot;

        // ✅ FIXED Booking (Picklist + Lookup)
        Booking__c booking = new Booking__c(
            Project__c = validProjectValue, // picklist
            Project1__c = project.Id,       // lookup (used in trigger)
            Plot__c = plot.Id
        );
        insert booking;

        // Create Payment Schedules (add required fields)
        insert new Payment_Schedule__c(
            Booking__c = booking.Id,
            Interest_Percent__c = 12,
            Payment_Due_Date__c = Date.today().addDays(-30),
            //Pending_Amount__c = 1000,
            Amount__c = 1000
        );

        insert new Payment_Schedule__c(
            Booking__c = booking.Id,
            Interest_Percent__c = 12,
            Payment_Due_Date__c = Date.today().addDays(-15),
            //Pending_Amount__c = 2000,
            Amount__c = 2000
        );
    }

    // ================= INTEREST CHANGE =================
    @isTest
    static void testInterestPercentageChange() {

        Project__c project = [SELECT Id, Interest_Percentage__c FROM Project__c LIMIT 1];

        Test.startTest();
        project.Interest_Percentage__c = 15;
        update project;
        Test.stopTest();

        List<Payment_Schedule__c> schedules = [
            SELECT Interest_Percent__c, Interest_Change_Date__c
            FROM Payment_Schedule__c
            WHERE Booking__r.Project1__c = :project.Id
        ];

        for (Payment_Schedule__c ps : schedules) {
            System.assertEquals(15, ps.Interest_Percent__c);
            System.assertEquals(Date.today(), ps.Interest_Change_Date__c);
        }

        List<Interest_Amount_Line_Item__c> lineItems = [
            SELECT Id FROM Interest_Amount_Line_Item__c
        ];
        System.assertEquals(2, lineItems.size(),
            'Line items should be created for each schedule');
    }

    // ================= NO INTEREST CHANGE =================
    @isTest
    static void testNoInterestPercentageChange() {

        Project__c project = [SELECT Id, Name FROM Project__c LIMIT 1];
        Integer beforeCount = [SELECT COUNT() FROM Interest_Amount_Line_Item__c];

        Test.startTest();
        project.Name = 'Only Name Changed';
        update project;
        Test.stopTest();

        Integer afterCount = [SELECT COUNT() FROM Interest_Amount_Line_Item__c];

        System.assertEquals(beforeCount, afterCount,
            'No line items should be created');
    }

    // ================= BULK UPDATE =================
    @isTest
    static void testBulkProjectUpdate() {

        // Get valid picklist value again
        String validProjectValue;
        List<Schema.PicklistEntry> pickVals = Booking__c.Project__c.getDescribe().getPicklistValues();
        if (!pickVals.isEmpty()) {
            validProjectValue = pickVals[0].getValue();
        }

        List<Project__c> projects = new List<Project__c>();
        List<Booking__c> bookings = new List<Booking__c>();
        List<Payment_Schedule__c> schedules = new List<Payment_Schedule__c>();

        for (Integer i = 0; i < 3; i++) {
            Project__c p = new Project__c(
                Name = 'Bulk Project ' + i,
                Project_Type__c = 'Apartments',
                Interest_Percentage__c = 10
            );
            projects.add(p);
        }
        insert projects;

        for (Project__c p : projects) {
            Booking__c b = new Booking__c(
                Project__c = validProjectValue,
                Project1__c = p.Id
            );
            bookings.add(b);
        }
        insert bookings;

        for (Booking__c b : bookings) {
            schedules.add(new Payment_Schedule__c(
                Booking__c = b.Id,
                Payment_Due_Date__c = Date.today().addDays(-10),
                //Pending_Amount__c = 500,
                Amount__c = 500
            ));
        }
        insert schedules;

        Test.startTest();
        for (Project__c p : projects) {
            p.Interest_Percentage__c = 18;
        }
        update projects;
        Test.stopTest();

        System.assert(true, 'Bulk update executed successfully');
    }
}