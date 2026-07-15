@isTest
public class BookingApprovalControllerTest {

    // Helper method to get all valid picklist values for Stage__c...
    private static List<String> getValidStageValues() {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.DescribeSObjectResult bookingDescribe = schemaMap.get('Booking__c').getDescribe();
        List<Schema.PicklistEntry> picklistEntries = bookingDescribe.fields.getMap()
            .get('Stage__c').getDescribe().getPicklistValues();

        List<String> values = new List<String>();
        for (Schema.PicklistEntry pe : picklistEntries) {
            values.add(pe.getValue());
        }
        return values;
    }

    @isTest
    static void testShouldShowCancellationCharge_PositiveStages() {
        List<String> stages = getValidStageValues();
        String mdStage = null;
        for (String s : stages) {
            if (s == 'Registration' || s == 'Sale Agreement Execution Completed') {
                mdStage = s;
                break;
            }
        }
        System.assertNotEquals(null, mdStage, 'MD stage must exist in picklist');

        Booking__c booking = new Booking__c(Stage__c = mdStage);
        insert booking;

        Boolean result = BookingApprovalController.shouldShowCancellationCharge(booking.Id);
        System.assertEquals(true, result, 'Should return true for MD stage');
    }

    @isTest
    static void testShouldShowCancellationCharge_NonMDStage() {
        List<String> stages = getValidStageValues();
        String nonMdStage = null;
        for (String s : stages) {
            if (s != 'Registration' && s != 'Sale Agreement Execution Completed') {
                nonMdStage = s;
                break;
            }
        }
        System.assertNotEquals(null, nonMdStage, 'Non-MD stage must exist');

        Booking__c booking = new Booking__c(Stage__c = nonMdStage);
        insert booking;

        Boolean result = BookingApprovalController.shouldShowCancellationCharge(booking.Id);
        System.assertEquals(false, result, 'Should return false for non-MD stage');
    }

    @isTest
    static void testSubmitApproval_MDStage_WithCharge() {
        List<String> stages = getValidStageValues();
        String mdStage = null;
        for (String s : stages) {
            if (s == 'Registration' || s == 'Sale Agreement Execution Completed') {
                mdStage = s;
                break;
            }
        }
        System.assertNotEquals(null, mdStage, 'MD stage must exist');

        Booking__c booking = new Booking__c(Stage__c = mdStage);
        insert booking;

        Test.startTest();
        BookingApprovalController.submitApproval(booking.Id, 'MD Approval', 500);
        Test.stopTest();

        Booking__c updatedBooking = [SELECT Cancellation_Charges__c FROM Booking__c WHERE Id = :booking.Id];
        System.assertEquals(500, updatedBooking.Cancellation_Charges__c, 'Cancellation charge should be updated');
    }

    @isTest
    static void testSubmitApproval_NonMDStage_ChargeIgnored() {
        List<String> stages = getValidStageValues();
        String nonMdStage = null;
        for (String s : stages) {
            if (s != 'Registration' && s != 'Sale Agreement Execution Completed') {
                nonMdStage = s;
                break;
            }
        }
        System.assertNotEquals(null, nonMdStage, 'Non-MD stage must exist');

        Booking__c booking = new Booking__c(Stage__c = nonMdStage);
        insert booking;

        Test.startTest();
        BookingApprovalController.submitApproval(booking.Id, 'Non-MD Stage Approval', 1000);
        Test.stopTest();

        Booking__c updatedBooking = [SELECT Cancellation_Charges__c FROM Booking__c WHERE Id = :booking.Id];
        System.assertEquals(null, updatedBooking.Cancellation_Charges__c, 'Cancellation charge should be cleared for non-MD stage');
    }

    @isTest
    static void testSubmitApproval_MDStage_MissingCharge_Exception() {
        List<String> stages = getValidStageValues();
        String mdStage = null;
        for (String s : stages) {
            if (s == 'Registration' || s == 'Sale Agreement Execution Completed') {
                mdStage = s;
                break;
            }
        }
        System.assertNotEquals(null, mdStage, 'MD stage must exist');
    
        Booking__c booking = new Booking__c(Stage__c = mdStage);
        insert booking;
    
        Boolean exceptionThrown = false;
    
        Test.startTest();
        try {
            BookingApprovalController.submitApproval(booking.Id, 'Missing charge test', null);
        } catch (AuraHandledException e) {
            exceptionThrown = true; // Only check that exception was thrown
        }
        Test.stopTest();
    
        System.assertEquals(true, exceptionThrown, 'Expected AuraHandledException to be thrown');
    }

}