@isTest
public class BulkSMSServiceTest {

    // Mock for successful SMS send
    private class SMSSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('123456789');
            return res;
        }
    }

    // Mock for SMS error response
    private class SMSErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('103');
            return res;
        }
    }

    @isTest
    static void testSendSMSSuccess() {
        Test.setMock(HttpCalloutMock.class, new SMSSuccessMock());

        Test.startTest();
        String messageId = BulkSMSService.sendSMS('9876543210', 'Test message', 'TEMPLATE123');
        Test.stopTest();

        System.assertNotEquals(null, messageId, 'Message ID should not be null for successful send');
        System.assertEquals('123456789', messageId);
    }

    @isTest
    static void testSendSMSWithAllParams() {
        Test.setMock(HttpCalloutMock.class, new SMSSuccessMock());

        Test.startTest();
        String messageId = BulkSMSService.sendSMS('9876543210', 'Test message', 'TEMPLATE123', 'JAINHS', '2');
        Test.stopTest();

        System.assertNotEquals(null, messageId);
    }

    @isTest
    static void testSendSMSError() {
        Test.setMock(HttpCalloutMock.class, new SMSErrorMock());

        Test.startTest();
        String messageId = BulkSMSService.sendSMS('9876543210', 'Test message', 'TEMPLATE123');
        Test.stopTest();

        System.assertEquals(null, messageId, 'Message ID should be null for error response');
    }

    @isTest
    static void testSendSMSBlankParams() {
        Test.startTest();
        String result1 = BulkSMSService.sendSMS('', 'Test', 'TEMPLATE123');
        String result2 = BulkSMSService.sendSMS('9876543210', '', 'TEMPLATE123');
        String result3 = BulkSMSService.sendSMS('9876543210', 'Test', '');
        Test.stopTest();

        System.assertEquals(null, result1);
        System.assertEquals(null, result2);
        System.assertEquals(null, result3);
    }

    @isTest
    static void testPhoneNumberCleaning() {
        Test.setMock(HttpCalloutMock.class, new SMSSuccessMock());

        Test.startTest();
        String result1 = BulkSMSService.sendSMS('+91 9876543210', 'Test', 'TEMPLATE123');
        String result2 = BulkSMSService.sendSMS('919876543210', 'Test', 'TEMPLATE123');
        String result3 = BulkSMSService.sendSMS('987-654-3210', 'Test', 'TEMPLATE123');
        Test.stopTest();

        System.assertNotEquals(null, result1);
        System.assertNotEquals(null, result2);
        System.assertNotEquals(null, result3);
    }
}