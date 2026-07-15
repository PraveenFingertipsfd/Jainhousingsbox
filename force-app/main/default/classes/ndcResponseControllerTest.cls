@IsTest
public class ndcResponseControllerTest {

    @TestSetup
    static void setup() {
        // Create bookings without setting Name...
        Booking__c b1 = new Booking__c(Is_NDC_Responded__c = false);
        insert b1;

        Booking__c b2 = new Booking__c(Is_NDC_Responded__c = true);
        insert b2;
    }

    @IsTest
    static void testSubmitNewResponse() {
        Booking__c booking = [SELECT Id, Is_NDC_Responded__c FROM Booking__c WHERE Is_NDC_Responded__c = false LIMIT 1];

        // Set page parameters....
        Test.setCurrentPageReference(new PageReference('/apex/dummyPage?id=' + booking.Id));

        ndcResponseController controller = new ndcResponseController();
        controller.comment = 'This is a test response';

        Test.startTest();
        controller.submit();
        Test.stopTest();

        // Reload booking...
        booking = [SELECT ndc_Response__c, Is_NDC_Responded__c FROM Booking__c WHERE Id = :booking.Id];
        System.assertEquals('This is a test response', booking.ndc_Response__c);
        System.assertEquals(true, booking.Is_NDC_Responded__c);
        System.assertEquals(true, controller.getIsSubmitted());
        System.assertEquals(true, controller.getAlreadySubmitted());
    }

    @IsTest
    static void testSubmitAlreadyResponded() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE Is_NDC_Responded__c = true LIMIT 1];

        Test.setCurrentPageReference(new PageReference('/apex/dummyPage?id=' + booking.Id));

        ndcResponseController controller = new ndcResponseController();
        controller.comment = 'Another response';

        Test.startTest();
        controller.submit();
        Test.stopTest();

        System.assertEquals(true, controller.getIsSubmitted());
        System.assertEquals(true, controller.getAlreadySubmitted());

        // Ensure comment was NOT updated....
        Booking__c refreshed = [SELECT ndc_Response__c FROM Booking__c WHERE Id = :booking.Id];
        System.assertEquals(null, refreshed.ndc_Response__c);
    }

    @IsTest
    static void testSubmitWithNullComment() {
        Booking__c booking = [SELECT Id FROM Booking__c WHERE Is_NDC_Responded__c = false LIMIT 1];

        Test.setCurrentPageReference(new PageReference('/apex/dummyPage?id=' + booking.Id));

        ndcResponseController controller = new ndcResponseController();
        controller.comment = null;

        Test.startTest();
        controller.submit();
        Test.stopTest();

        // Ensure flags are not set..
        System.assertEquals(false, controller.getIsSubmitted());
        System.assertEquals(false, controller.getAlreadySubmitted());
    }

    @IsTest
    static void testSubmitWithNullBookingId() {
        Test.setCurrentPageReference(new PageReference('/apex/dummyPage'));

        ndcResponseController controller = new ndcResponseController();
        controller.comment = 'Test comment';

        Test.startTest();
        controller.submit();
        Test.stopTest();

        System.assertEquals(false, controller.getIsSubmitted());
        System.assertEquals(false, controller.getAlreadySubmitted());
    }
}