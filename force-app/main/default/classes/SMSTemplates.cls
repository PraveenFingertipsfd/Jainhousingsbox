public class SMSTemplates {

    private static Map<String, String> templateIdCache;

    // Reads DLT Template IDs from SMS_Template__mdt Custom Metadata
    public static String getTemplateId(String templateName) {
        if (templateIdCache == null) {
            templateIdCache = new Map<String, String>();
            for (SMS_Template__mdt rec : [SELECT DeveloperName, Template_ID__c 
                                           FROM SMS_Template__mdt]) {
                templateIdCache.put(rec.DeveloperName, rec.Template_ID__c);
            }
        }
        String templateId = templateIdCache.get(templateName);
        if (String.isBlank(templateId)) {
            System.debug('SMSTemplates: No template found for name: ' + templateName);
        }
        return templateId;
    }

    public static void sendWelcomeSMS(Id bookingId) {
        sendWelcomeSMSBulk(new List<Id>{ bookingId });
    }

    public static void sendWelcomeSMSBulk(List<Id> bookingIds) {
        if (bookingIds == null || bookingIds.isEmpty()) return;
        System.enqueueJob(new SendWelcomeSMSQueueable(bookingIds));
    }

    // Must match DLT template exactly
    public static String buildWelcomeMessage(Booking__c booking) {
        return 'Own a Plot at Rs.9999/EMI per Month at Thirumazhisai. Launching Jains Aura Phase 2. Call: 0446184439';
    }
}