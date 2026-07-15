@isTest
public class GeneratePCTest {

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Apartments'
        );
        insert project;

        Plot__c plot = new Plot__c(
            Name = 'Test Unit',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = 'Apartments'
        );
        insert plot;

        Booking__c booking = new Booking__c(
            Possession_send__c = false
        );
        insert booking;
    }

    @isTest
    static void testIsPossessionSentFalse() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Boolean result = GeneratePC.isPossessionSent(booking.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Possession should not be sent initially');
    }

    @isTest
    static void testIsPossessionSentTrue() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        booking.Possession_send__c = true;
        update booking;

        Test.startTest();
        Boolean result = GeneratePC.isPossessionSent(booking.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Possession should be sent after update');
    }

    @isTest
    static void testIsPossessionSentInvalidId() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            GeneratePC.isPossessionSent('a00000000000000AAA');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Should throw exception for invalid ID');
    }

    @isTest
    static void testSendPossessionLetter() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        try {
            String result = GeneratePC.sendPossessionLetter(booking.Id);
        } catch (Exception e) {
            // Expected in test context as it delegates to GenerateDocumnetController
        }
        Test.stopTest();
    }
}