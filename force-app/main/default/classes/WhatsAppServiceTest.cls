@isTest
public class WhatsAppServiceTest {

    private class WASuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"code":"200","status":"SUCCESS","message":"Message Processed Successfully","data":{"messageid":"wa123456"}}');
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
    static void testSendTemplateMessageSuccess() {
        Test.setMock(HttpCalloutMock.class, new WASuccessMock());

        Test.startTest();
        String result = WhatsAppService.sendTemplateMessage(
            '9876543210', 'all_project', null
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSendTemplateWithPlaceholders() {
        Test.setMock(HttpCalloutMock.class, new WASuccessMock());

        Test.startTest();
        String result = WhatsAppService.sendTemplateMessage(
            '9876543210', 'welcome_template',
            new List<String>{'Test Customer'}
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSendTemplateMessageBlankInputs() {
        Test.startTest();
        String result1 = WhatsAppService.sendTemplateMessage('', 'template', null);
        String result2 = WhatsAppService.sendTemplateMessage('9876543210', '', null);
        Test.stopTest();

        System.assertEquals(null, result1);
        System.assertEquals(null, result2);
    }

    @isTest
    static void testSendTemplateMessageAuthError() {
        Test.setMock(HttpCalloutMock.class, new WAErrorMock());

        Test.startTest();
        String result = WhatsAppService.sendTemplateMessage(
            '9876543210', 'all_project', null
        );
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testSendTextMessage() {
        Test.setMock(HttpCalloutMock.class, new WASuccessMock());

        Test.startTest();
        String result = WhatsAppService.sendTextMessage('9876543210', 'Hello from Jain Housing');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSendTextMessageBlank() {
        Test.startTest();
        String result = WhatsAppService.sendTextMessage('', 'Hello');
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testGetErrorDescription() {
        System.assertEquals('Authentication failed', WhatsAppService.getErrorDescription('WA002'));
        System.assertEquals('Insufficient balance', WhatsAppService.getErrorDescription('WA036'));
        System.assert(WhatsAppService.getErrorDescription('WA999').contains('Unknown'));
    }
}