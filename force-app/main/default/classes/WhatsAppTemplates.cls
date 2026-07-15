public class WhatsAppTemplates {

    // Send Welcome WhatsApp for a single booking
    public static void sendWelcomeWhatsApp(Id bookingId) {
        sendWelcomeWhatsAppBulk(new List<Id>{ bookingId });
    }

    // Send Welcome WhatsApp for multiple bookings (bulk-safe via Queueable)
    public static void sendWelcomeWhatsAppBulk(List<Id> bookingIds) {
        if (bookingIds == null || bookingIds.isEmpty()) return;
        System.enqueueJob(new SendWelcomeWhatsAppQueueable(bookingIds));
    }

    // Build template parameter values from booking data
    public static List<String> buildWelcomeParams(Booking__c booking) {
        List<String> params = new List<String>();
        params.add(String.isNotBlank(booking.First_Applicant_Name__c)
            ? booking.First_Applicant_Name__c : 'Customer');
        return params;
    }

    // Get WhatsApp template name from Custom Metadata
    public static String getTemplateName(String metadataName) {
        return SMSTemplates.getTemplateId(metadataName);
    }
}