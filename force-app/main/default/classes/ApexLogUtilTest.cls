@isTest
public class ApexLogUtilTest {

    @isTest
    static void testLogSuccess() {
        Test.startTest();
        ApexLogUtil.logSuccess('WhatsApp Template', 'to=9876543210', '{"req":1}', '{"code":"200"}');
        System.assertEquals(1, ApexLogUtil.pending(), 'One log should be buffered');
        ApexLogUtil.flush();
        System.assertEquals(0, ApexLogUtil.pending(), 'Buffer should be cleared after flush');
        Test.stopTest();

        List<Apex_Log__c> logs = [
            SELECT Request_Type__c, Status__c, Input_Parameters__c, Request__c, Response__c, Error_Message__c
            FROM Apex_Log__c
        ];
        System.assertEquals(1, logs.size(), 'One log record should be inserted');
        System.assertEquals('WhatsApp Template', logs[0].Request_Type__c);
        System.assertEquals(ApexLogUtil.STATUS_SUCCESS, logs[0].Status__c);
        System.assertEquals('{"code":"200"}', logs[0].Response__c);
        System.assertEquals(null, logs[0].Error_Message__c);
    }

    @isTest
    static void testLogErrorExplicit() {
        Test.startTest();
        ApexLogUtil.logError('WhatsApp Template', 'to=9876543210', '{"req":1}',
            '{"code":"WA036"}', 'WA036 - Insufficient balance');
        ApexLogUtil.flush();
        Test.stopTest();

        Apex_Log__c log = [SELECT Status__c, Error_Message__c FROM Apex_Log__c LIMIT 1];
        System.assertEquals(ApexLogUtil.STATUS_ERROR, log.Status__c);
        System.assert(log.Error_Message__c.contains('WA036'), 'Error message should be captured');
    }

    @isTest
    static void testLogErrorException() {
        Test.startTest();
        try {
            Integer x = 1 / 0; // force an exception
        } catch (Exception e) {
            ApexLogUtil.logError('WhatsApp Template', 'to=9876543210', e);
        }
        ApexLogUtil.flush();
        Test.stopTest();

        Apex_Log__c log = [SELECT Status__c, Error_Message__c FROM Apex_Log__c LIMIT 1];
        System.assertEquals(ApexLogUtil.STATUS_ERROR, log.Status__c);
        System.assertNotEquals(null, log.Error_Message__c);
    }

    @isTest
    static void testTruncation() {
        // Status__c is a TextArea (255). Build a 300-char value and confirm it is truncated.
        String longStatus = 'X'.repeat(300);
        String longBody = 'Y'.repeat(140000); // exceeds LongTextArea 131072

        Test.startTest();
        ApexLogUtil.add('WhatsApp Template', longStatus, null, longBody, null, null);
        ApexLogUtil.flush();
        Test.stopTest();

        Apex_Log__c log = [SELECT Status__c, Request__c FROM Apex_Log__c LIMIT 1];
        System.assertEquals(255, log.Status__c.length(), 'TextArea should be truncated to 255');
        System.assertEquals(131072, log.Request__c.length(), 'LongTextArea should be truncated to 131072');
    }

    @isTest
    static void testFlushEmptyBuffer() {
        Test.startTest();
        ApexLogUtil.flush(); // should be a no-op, no exception
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Apex_Log__c], 'No logs should be created');
    }
}
