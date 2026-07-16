@isTest
public class SendWhatsAppQueueableTest {

    private class WASuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"code":"200","status":"SUCCESS","data":{"messageid":"wa1"}}');
            return res;
        }
    }

    private class WAErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"code":"WA002","status":"ERROR","message":"Authentication failed"}');
            return res;
        }
    }

    @isTest
    static void testSendTemplateToNumbersSuccess() {
        Test.setMock(HttpCalloutMock.class, new WASuccessMock());

        Test.startTest();
        WhatsAppTemplates.sendTemplateToNumbers('NDC_WhatsApp', new List<String>{ '9876543210', '9876543211' });
        Test.stopTest();

        List<Apex_Log__c> logs = [SELECT Status__c, Request_Type__c FROM Apex_Log__c];
        System.assertEquals(2, logs.size(), 'One log per number should be created');
        for (Apex_Log__c log : logs) {
            System.assertEquals('WhatsApp Template', log.Request_Type__c);
            System.assertEquals(ApexLogUtil.STATUS_SUCCESS, log.Status__c);
        }
    }

    @isTest
    static void testSendTemplateToNumbersError() {
        Test.setMock(HttpCalloutMock.class, new WAErrorMock());

        Test.startTest();
        WhatsAppTemplates.sendTemplateToNumbers('Cancellation_WhatsApp', new List<String>{ '9876543210' });
        Test.stopTest();

        Apex_Log__c log = [SELECT Status__c, Error_Message__c FROM Apex_Log__c LIMIT 1];
        System.assertEquals(ApexLogUtil.STATUS_ERROR, log.Status__c);
        System.assert(log.Error_Message__c.contains('WA002'), 'API error should be logged');
    }

    @isTest
    static void testDedupeAndBlankGuards() {
        Test.setMock(HttpCalloutMock.class, new WASuccessMock());

        Test.startTest();
        // duplicates + blanks collapse to a single distinct number
        WhatsAppTemplates.sendTemplateToNumbers('Demand_Letter_WhatsApp',
            new List<String>{ '9876543210', '9876543210', '', null });
        // no-op paths
        WhatsAppTemplates.sendTemplateToNumbers('Demand_Letter_WhatsApp', new List<String>());
        WhatsAppTemplates.sendTemplateToNumbers(null, new List<String>{ '9876543210' });
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Apex_Log__c], 'Only one distinct number should send');
    }

    @isTest
    static void testSendTemplateForBookings() {
        Test.setMock(HttpCalloutMock.class, new WASuccessMock());

        Project__c proj = new Project__c(Name = 'Test Project', Project_Type__c = 'Apartments');
        insert proj;

        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Test Customer',
            Mobile_Primary1__c = '9876543210',
            Project1__c = proj.Id
        );
        insert booking;

        Booking__c noPhone = new Booking__c(
            First_Applicant_Name__c = 'No Phone',
            Project1__c = proj.Id
        );
        insert noPhone;

        Test.startTest();
        WhatsAppTemplates.sendTemplateForBookings('Payment_Receipt_WhatsApp',
            new List<Id>{ booking.Id, noPhone.Id });
        // empty/blank guards
        WhatsAppTemplates.sendTemplateForBookings('Payment_Receipt_WhatsApp', new List<Id>());
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Apex_Log__c],
            'Only the booking with a mobile number should send');
    }

    @isTest
    static void testUnknownTemplateNoSend() {
        Test.setMock(HttpCalloutMock.class, new WASuccessMock());

        Test.startTest();
        // Non-existent metadata dev name -> template resolves blank -> no callout, no log
        WhatsAppTemplates.sendTemplateToNumbers('Does_Not_Exist_WhatsApp', new List<String>{ '9876543210' });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Apex_Log__c], 'Unknown template should not send');
    }
}
