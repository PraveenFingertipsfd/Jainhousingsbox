@isTest
public class MasterPaymentScheduleTriggerTest {

    @testSetup
    static void setupData() {

        // 🔥 Get valid picklist value dynamically
        String validProjectValue;
        Schema.DescribeFieldResult fieldResult = Booking__c.Project__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        if (!picklistValues.isEmpty()) {
            validProjectValue = picklistValues[0].getValue();
        }

        // Create Project (Name must match picklist for trigger logic)
        Project__c project = new Project__c(
            Name = validProjectValue,
            Project_Type__c = 'Apartments'
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

        // Create Booking (FIXED picklist issue)
        Booking__c booking = new Booking__c(
            Project__c = validProjectValue,
            Plot__c = plot.Id
        );
        insert booking;

        // Create Master Payment Schedules
        Master_Payment_Schedule__c mps1 = new Master_Payment_Schedule__c(
            Name = 'Milestone 1',
            S_No__c = 1,
            Project__c = project.Id,
            Project_Type__c = 'Apartments',
            Status__c = 'Not Started',
            Due_Date__c = Date.today().addDays(30),
            Include_Interest__c = false
        );
        insert mps1;

        Master_Payment_Schedule__c mps2 = new Master_Payment_Schedule__c(
            Name = 'Milestone 2',
            S_No__c = 2,
            Project__c = project.Id,
            Project_Type__c = 'Apartments',
            Status__c = 'Not Started',
            Due_Date__c = Date.today().addDays(60),
            Include_Interest__c = false
        );
        insert mps2;

        // Create Payment Schedules
        insert new Payment_Schedule__c(
            Booking__c = booking.Id,
            Master_Payment_Schedule__c = mps1.Id,
            S_No__c = 1,
            Status__c = 'Not Started'
        );

        insert new Payment_Schedule__c(
            Booking__c = booking.Id,
            Master_Payment_Schedule__c = mps2.Id,
            S_No__c = 2,
            Status__c = 'Not Started'
        );
    }

    // ================= STATUS CHANGE =================
    @isTest
    static void testStatusChangeToCompleted() {

        Master_Payment_Schedule__c mps = 
            [SELECT Id FROM Master_Payment_Schedule__c WHERE S_No__c = 1 LIMIT 1];

        Test.startTest();
        mps.Status__c = 'Completed';
        update mps;
        Test.stopTest();

        List<Payment_Schedule__c> schedules = [
            SELECT Status__c, Payment_Due_Date__c
            FROM Payment_Schedule__c
            WHERE Master_Payment_Schedule__c = :mps.Id
        ];

        for (Payment_Schedule__c ps : schedules) {
            System.assertEquals('Completed', ps.Status__c);
            System.assertNotEquals(null, ps.Payment_Due_Date__c);
        }
    }

    // ================= INCLUDE INTEREST =================
    @isTest
    static void testIncludeInterestChange() {

        Master_Payment_Schedule__c mps = 
            [SELECT Id FROM Master_Payment_Schedule__c WHERE S_No__c = 1 LIMIT 1];

        Test.startTest();
        mps.Include_Interest__c = true;
        update mps;
        Test.stopTest();

        List<Payment_Schedule__c> schedules = [
            SELECT Include_Interest__c
            FROM Payment_Schedule__c
            WHERE Master_Payment_Schedule__c = :mps.Id
        ];

        for (Payment_Schedule__c ps : schedules) {
            System.assertEquals(true, ps.Include_Interest__c);
        }
    }

    // ================= BULK UPDATE =================
    @isTest
    static void testBulkStatusUpdate() {

        List<Master_Payment_Schedule__c> mpsList = 
            [SELECT Id FROM Master_Payment_Schedule__c];

        Test.startTest();
        for (Master_Payment_Schedule__c mps : mpsList) {
            mps.Status__c = 'Completed';
        }
        update mpsList;
        Test.stopTest();

        List<Payment_Schedule__c> schedules = 
            [SELECT Status__c FROM Payment_Schedule__c];

        for (Payment_Schedule__c ps : schedules) {
            System.assertEquals('Completed', ps.Status__c);
        }
    }

    @isTest
static void testNoStatusChange() {

    Master_Payment_Schedule__c mps = 
        [SELECT Id, Name FROM Master_Payment_Schedule__c WHERE S_No__c = 1 LIMIT 1];

    Test.startTest();
    mps.Name = 'Updated Name';
    update mps;
    Test.stopTest();

    List<Payment_Schedule__c> schedules = [
        SELECT Status__c
        FROM Payment_Schedule__c
        WHERE Master_Payment_Schedule__c = :mps.Id
    ];

    for (Payment_Schedule__c ps : schedules) {
        System.assertEquals('Not Started', ps.Status__c);
    }
}
}