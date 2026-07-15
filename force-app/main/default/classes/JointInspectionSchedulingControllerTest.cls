@IsTest
public class JointInspectionSchedulingControllerTest {

    // Utility method to create Booking & Inspection without setting Name
    private static Joint_Inspection__c createInspection(Boolean isResponded, String status, DateTime inviteDateTime) {
        // Create Booking with only required fields
        Booking__c booking = new Booking__c();
        // Add any other required fields here, except Name
        insert booking;

        Joint_Inspection__c ji = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Is_Responded__c = isResponded,
            Joint_Inspection_Status__c = status,
            Invite_Sent_Date_Time__c = inviteDateTime
            // Don't set Name if it's auto-number
        );
        insert ji;
        return ji;
    }

    @IsTest
    static void testConstructor_InvalidId() {
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', '');
        JointInspectionSchedulingController controller = new JointInspectionSchedulingController();
        Test.stopTest();

        System.assert(controller.showForm == false);
    }

    @IsTest
    static void testConstructor_ExpiredInspection() {
        DateTime pastDate = DateTime.now().addDays(-10);
        Joint_Inspection__c ji = createInspection(false, 'Scheduled', pastDate);

        ApexPages.currentPage().getParameters().put('id', ji.Id);
        Test.startTest();
        JointInspectionSchedulingController controller = new JointInspectionSchedulingController();
        Test.stopTest();

        System.assert(controller.isExpired == true);
    }

    @IsTest
    static void testConstructor_AlreadyResponded() {
        Joint_Inspection__c ji = createInspection(true, 'Scheduled', DateTime.now());

        ApexPages.currentPage().getParameters().put('id', ji.Id);
        Test.startTest();
        JointInspectionSchedulingController controller = new JointInspectionSchedulingController();
        Test.stopTest();

        System.assert(controller.alreadyResponded == true);
    }

    @IsTest
    static void testConstructor_ValidInspection() {
        Joint_Inspection__c ji = createInspection(false, 'Scheduled', DateTime.now());

        ApexPages.currentPage().getParameters().put('id', ji.Id);
        Test.startTest();
        JointInspectionSchedulingController controller = new JointInspectionSchedulingController();
        Test.stopTest();

        System.assert(controller.showForm == true);
    }

    @IsTest
    static void testValidateDateTime_PastDate() {
        Joint_Inspection__c ji = createInspection(false, 'Scheduled', DateTime.now());
        ApexPages.currentPage().getParameters().put('id', ji.Id);

        JointInspectionSchedulingController controller = new JointInspectionSchedulingController();
        controller.inspectionDate = Date.today().addDays(-1);
        controller.inspectionTime = Time.newInstance(11, 0, 0, 0);

        Test.startTest();
        controller.scheduleInspection();
        Test.stopTest();

        System.assert(controller.isDateValid == false);
    }

    
    @IsTest
    static void testValidateDateTime_OutOfHours() {
        Joint_Inspection__c ji = createInspection(false, 'Scheduled', DateTime.now());
        ApexPages.currentPage().getParameters().put('id', ji.Id);

        JointInspectionSchedulingController controller = new JointInspectionSchedulingController();
        controller.inspectionDate = Date.today().addDays(1);
        controller.inspectionTime = Time.newInstance(9, 0, 0, 0); // before 10 AM

        Test.startTest();
        controller.scheduleInspection();
        Test.stopTest();

        System.assert(controller.isTimeValid == false);
    }

    @IsTest
    static void testScheduleInspection_Success() {
        Joint_Inspection__c ji = createInspection(false, 'Scheduled', DateTime.now());
        ApexPages.currentPage().getParameters().put('id', ji.Id);

        JointInspectionSchedulingController controller = new JointInspectionSchedulingController();
        controller.inspectionDate = Date.today().addDays(1);
        controller.inspectionTime = Time.newInstance(11, 0, 0, 0);

        Test.startTest();
        controller.scheduleInspection();
        Test.stopTest();

        Joint_Inspection__c updatedJI = [SELECT Joint_Inspection_Status__c, Is_Responded__c, Joint_Inspection_Date__c
                                         FROM Joint_Inspection__c WHERE Id = :ji.Id];
        System.assertEquals('Scheduled', updatedJI.Joint_Inspection_Status__c);
        System.assertEquals(true, updatedJI.Is_Responded__c);
        System.assert(controller.isSuccess == true);
    }
}