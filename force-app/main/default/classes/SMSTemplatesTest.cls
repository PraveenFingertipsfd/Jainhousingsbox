@isTest
public class SMSTemplatesTest {

    private class SMSMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('123456789');
            return res;
        }
    }

    @isTest
    static void testSendWelcomeSMS() {
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
        SMSTemplates.sendWelcomeSMS(booking.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendWelcomeSMSBulk() {
        Test.setMock(HttpCalloutMock.class, new SMSMock());

        Project__c proj = new Project__c(Name = 'Test Project', Project_Type__c = 'Apartments');
        insert proj;

        Block__c block = new Block__c(Name = 'Block A', Project__c = proj.Id);
        insert block;

        Plot__c plot1 = new Plot__c(Name = 'Unit 101', Project__c = proj.Id, Project_Type__c = 'Apartments');
        Plot__c plot2 = new Plot__c(Name = 'Unit 102', Project__c = proj.Id, Project_Type__c = 'Apartments');
        insert new List<Plot__c>{ plot1, plot2 };

        List<Booking__c> bookings = new List<Booking__c>{
            new Booking__c(
                First_Applicant_Name__c = 'Customer A',
                Mobile_Primary1__c = '9876543210',
                Email1__c = 'a@example.com',
                Project1__c = proj.Id,
                Plot__c = plot1.Id,
                Block__c = block.Id
            ),
            new Booking__c(
                First_Applicant_Name__c = 'Customer B',
                Mobile_Primary1__c = '9876543211',
                Email1__c = 'b@example.com',
                Project1__c = proj.Id,
                Plot__c = plot2.Id,
                Block__c = block.Id
            )
        };
        insert bookings;

        List<Id> ids = new List<Id>();
        for (Booking__c b : bookings) {
            ids.add(b.Id);
        }

        Test.startTest();
        SMSTemplates.sendWelcomeSMSBulk(ids);
        Test.stopTest();
    }

    @isTest
    static void testSendWelcomeSMSBulkEmptyList() {
        Test.startTest();
        SMSTemplates.sendWelcomeSMSBulk(new List<Id>());
        SMSTemplates.sendWelcomeSMSBulk(null);
        Test.stopTest();
    }

    @isTest
    static void testGetTemplateId() {
        // SMS_Template__mdt records are accessible in tests
        String templateId = SMSTemplates.getTemplateId('Welcome_SMS');
        // May be null if metadata not deployed in test context, but method should not throw
        System.debug('Template ID: ' + templateId);
    }

    @isTest
    static void testGetTemplateIdNotFound() {
        String templateId = SMSTemplates.getTemplateId('NonExistent_Template');
        System.assertEquals(null, templateId);
    }

    @isTest
    static void testBuildWelcomeMessage() {
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'John Doe'
        );
        String msg = SMSTemplates.buildWelcomeMessage(booking);
        System.assert(msg.contains('Rs.9999'));
        System.assert(msg.contains('Jains Aura Phase 2'));
    }
}