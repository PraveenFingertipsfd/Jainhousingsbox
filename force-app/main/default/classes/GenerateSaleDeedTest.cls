@isTest
public class GenerateSaleDeedTest {

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments'
        );
        insert project;

        Booking__c booking = new Booking__c(
            Project__c = 'Jains Anushree',
            Project1__c = project.Id
        );
        insert booking;
    }

    @isTest
    static void testGenerateSaleDeed() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Blob result = GenerateSaleDeed.generateSaleDeed(booking.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'PDF blob should not be null');
        // In test context, returns Blob.valueOf('testblob')
        System.assertEquals('testblob', result.toString(), 'Should return test blob in test context');
    }
}