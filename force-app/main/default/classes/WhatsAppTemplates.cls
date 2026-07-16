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

    // ---------------------------------------------------------------------
    // Generic reusable senders (used by the booking-lifecycle triggers)
    // ---------------------------------------------------------------------

    // Send a template (no placeholders) to a raw list of phone numbers.
    public static void sendTemplateToNumbers(String templateDevName, List<String> phoneNumbers) {
        if (String.isBlank(templateDevName) || phoneNumbers == null) return;

        List<String> cleaned = new List<String>();
        Set<String> seen = new Set<String>();
        for (String phone : phoneNumbers) {
            if (String.isBlank(phone) || seen.contains(phone)) continue;
            seen.add(phone);
            cleaned.add(phone);
        }
        if (cleaned.isEmpty()) return;

        System.enqueueJob(new SendWhatsAppQueueable(templateDevName, cleaned));
    }

    // Resolve customer mobiles from Booking records, then send the template.
    public static void sendTemplateForBookings(String templateDevName, List<Id> bookingIds) {
        if (String.isBlank(templateDevName) || bookingIds == null || bookingIds.isEmpty()) return;

        List<String> phones = new List<String>();
        for (Booking__c b : [
            SELECT Mobile_Primary1__c FROM Booking__c WHERE Id IN :bookingIds
        ]) {
            if (String.isNotBlank(b.Mobile_Primary1__c)) {
                phones.add(b.Mobile_Primary1__c);
            }
        }
        sendTemplateToNumbers(templateDevName, phones);
    }
}