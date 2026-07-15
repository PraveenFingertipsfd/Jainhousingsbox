@isTest
public class SendWelcomeSMSQueueableTest {

    private class SMSMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('123456789');
            return res;
        }
    }

    @isTest
    static void testQueueableSingleBooking() {
        Test.setMock(HttpCalloutMock.class, new SMSMock());

        Project__c proj = new Project__c(Name = 'Test Project', Project_Type__c = 'Apartments');
        insert proj;

        Block__c block = new Block__c(Name = 'Block A', Project__c = proj.Id);
        insert block;

        Plot__c plot = new Plot__c(Name = 'Unit 101', Project__c = proj.Id, Project_Type__c = 'Apartments');
        insert plot;

        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Test Customer',
            Mobile_Primary1__c = '9876543210',
            Email1__c = 'test@example.com',
            Project1__c = proj.Id,
            Plot__c = plot.Id,
            Block__c = block.Id
        );
        insert booking;

        Test.startTest();
        System.enqueueJob(new SendWelcomeSMSQueueable(new List<Id>{ booking.Id }));
        Test.stopTest();
    }

    @isTest
    static void testQueueableBulkBookings() {
        Test.setMock(HttpCalloutMock.class, new SMSMock());

        Project__c proj = new Project__c(Name = 'Test Project', Project_Type__c = 'Apartments');
        insert proj;

        Block__c block = new Block__c(Name = 'Block A', Project__c = proj.Id);
        insert block;

        Plot__c plot1 = new Plot__c(Name = 'Unit 101', Project__c = proj.Id, Project_Type__c = 'Apartments');
        Plot__c plot2 = new Plot__c(Name = 'Unit 102', Project__c = proj.Id, Project_Type__c = 'Apartments');
        Plot__c plot3 = new Plot__c(Name = 'Unit 103', Project__c = proj.Id, Project_Type__c = 'Apartments');
        insert new List<Plot__c>{ plot1, plot2, plot3 };

        List<Booking__c> bookings = new List<Booking__c>();
        bookings.add(new Booking__c(
            First_Applicant_Name__c = 'Customer A',
            Mobile_Primary1__c = '9876543210',
            Email1__c = 'a@example.com',
            Project1__c = proj.Id,
            Plot__c = plot1.Id,
            Block__c = block.Id
        ));
        bookings.add(new Booking__c(
            First_Applicant_Name__c = 'Customer B',
            Mobile_Primary1__c = '9876543211',
            Email1__c = 'b@example.com',
            Project1__c = proj.Id,
            Plot__c = plot2.Id,
            Block__c = block.Id
        ));
        bookings.add(new Booking__c(
            First_Applicant_Name__c = 'Customer C',
            Mobile_Primary1__c = '9876543212',
            Email1__c = 'c@example.com',
            Project1__c = proj.Id,
            Plot__c = plot3.Id,
            Block__c = block.Id
        ));
        insert bookings;

        List<Id> bookingIds = new List<Id>();
        for (Booking__c b : bookings) {
            bookingIds.add(b.Id);
        }

        Test.startTest();
        System.enqueueJob(new SendWelcomeSMSQueueable(bookingIds));
        Test.stopTest();
    }

    @isTest
    static void testQueueableSkipsMissingMobile() {
        Test.setMock(HttpCalloutMock.class, new SMSMock());

        Project__c proj = new Project__c(Name = 'Test Project', Project_Type__c = 'Apartments');
        insert proj;

        Block__c block = new Block__c(Name = 'Block A', Project__c = proj.Id);
        insert block;

        Plot__c plot = new Plot__c(Name = 'Unit 101', Project__c = proj.Id, Project_Type__c = 'Apartments');
        insert plot;

        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'No Phone Customer',
            Email1__c = 'nophone@example.com',
            Project1__c = proj.Id,
            Plot__c = plot.Id,
            Block__c = block.Id
        );
        insert booking;

        Test.startTest();
        System.enqueueJob(new SendWelcomeSMSQueueable(new List<Id>{ booking.Id }));
        Test.stopTest();
    }

    @isTest
    static void testQueueableEmptyList() {
        Test.setMock(HttpCalloutMock.class, new SMSMock());

        Test.startTest();
        System.enqueueJob(new SendWelcomeSMSQueueable(new List<Id>()));
        Test.stopTest();
    }
}