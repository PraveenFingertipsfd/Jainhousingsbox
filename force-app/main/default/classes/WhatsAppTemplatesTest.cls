@isTest
public class WhatsAppTemplatesTest {

    private class WAMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"messages":[{"id":"wamid.123456"}]}');
            return res;
        }
    }

    @isTest
    static void testSendWelcomeWhatsApp() {
        Test.setMock(HttpCalloutMock.class, new WAMock());

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
        WhatsAppTemplates.sendWelcomeWhatsApp(booking.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendWelcomeWhatsAppBulk() {
        Test.setMock(HttpCalloutMock.class, new WAMock());

        Project__c proj = new Project__c(Name = 'Test Project', Project_Type__c = 'Apartments');
        insert proj;

        Block__c block = new Block__c(Name = 'Block A', Project__c = proj.Id);
        insert block;

        Plot__c plot1 = new Plot__c(Name = 'Unit 101', Project__c = proj.Id, Project_Type__c = 'Apartments');
        Plot__c plot2 = new Plot__c(Name = 'Unit 102', Project__c = proj.Id, Project_Type__c = 'Apartments');
        insert new List<Plot__c>{ plot1, plot2 };

        List<Booking__c> bookings = new List<Booking__c>{
            new Booking__c(First_Applicant_Name__c = 'Customer A', Mobile_Primary1__c = '9876543210',
                Email1__c = 'a@test.com', Project1__c = proj.Id, Plot__c = plot1.Id, Block__c = block.Id),
            new Booking__c(First_Applicant_Name__c = 'Customer B', Mobile_Primary1__c = '9876543211',
                Email1__c = 'b@test.com', Project1__c = proj.Id, Plot__c = plot2.Id, Block__c = block.Id)
        };
        insert bookings;

        List<Id> ids = new List<Id>();
        for (Booking__c b : bookings) ids.add(b.Id);

        Test.startTest();
        WhatsAppTemplates.sendWelcomeWhatsAppBulk(ids);
        Test.stopTest();
    }

    @isTest
    static void testSendWelcomeWhatsAppBulkEmpty() {
        Test.startTest();
        WhatsAppTemplates.sendWelcomeWhatsAppBulk(new List<Id>());
        WhatsAppTemplates.sendWelcomeWhatsAppBulk(null);
        Test.stopTest();
    }

    @isTest
    static void testBuildWelcomeParams() {
        Booking__c booking = new Booking__c(First_Applicant_Name__c = 'John Doe');
        List<String> params = WhatsAppTemplates.buildWelcomeParams(booking);
        System.assertEquals(1, params.size());
        System.assertEquals('John Doe', params[0]);
    }

    @isTest
    static void testBuildWelcomeParamsNoName() {
        Booking__c booking = new Booking__c();
        List<String> params = WhatsAppTemplates.buildWelcomeParams(booking);
        System.assertEquals('Customer', params[0]);
    }
}