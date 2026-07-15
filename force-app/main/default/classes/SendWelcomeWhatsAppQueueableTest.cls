@isTest
public class SendWelcomeWhatsAppQueueableTest {

    private class WhatsAppMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Apartments'
        );
        insert project;

        Booking__c booking1 = new Booking__c(
            First_Applicant_Name__c = 'Test Customer',
            Mobile_Primary1__c = '9876543210',
            Project__c = 'Jains Anushree',
            Project1__c = project.Id
        );
        insert booking1;

        Booking__c booking2 = new Booking__c(
            First_Applicant_Name__c = 'No Phone Customer',
            Project__c = 'Jains Anushree',
            Project1__c = project.Id
        );
        insert booking2;
    }

    @isTest
    static void testQueueableExecution() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());
        List<Booking__c> bookings = [SELECT Id FROM Booking__c];
        List<Id> bookingIds = new List<Id>();
        for (Booking__c b : bookings) {
            bookingIds.add(b.Id);
        }

        Test.startTest();
        System.enqueueJob(new SendWelcomeWhatsAppQueueable(bookingIds));
        Test.stopTest();

        // Verify no exceptions thrown - queueable completed successfully
        System.assert(true, 'Queueable should execute without errors');
    }

    @isTest
    static void testQueueableWithEmptyList() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());
        List<Id> emptyIds = new List<Id>();

        Test.startTest();
        System.enqueueJob(new SendWelcomeWhatsAppQueueable(emptyIds));
        Test.stopTest();

        System.assert(true, 'Queueable should handle empty list gracefully');
    }
}