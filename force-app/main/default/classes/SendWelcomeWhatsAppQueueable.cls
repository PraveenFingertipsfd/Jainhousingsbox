public class SendWelcomeWhatsAppQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> bookingIds;

    public SendWelcomeWhatsAppQueueable(List<Id> bookingIds) {
        this.bookingIds = bookingIds;
    }

    public void execute(QueueableContext context) {
        String templateName = WhatsAppTemplates.getTemplateName('Welcome_WhatsApp');
        if (String.isBlank(templateName)) {
            System.debug('SendWelcomeWhatsAppQueueable: No Welcome_WhatsApp template found');
            return;
        }

        List<Booking__c> bookings = [
            SELECT Id, First_Applicant_Name__c, Mobile_Primary1__c, Project1__r.Name
            FROM Booking__c WHERE Id IN :bookingIds
        ];

        for (Booking__c booking : bookings) {
            if (String.isBlank(booking.Mobile_Primary1__c)) continue;

            List<String> params = WhatsAppTemplates.buildWelcomeParams(booking);

            String result = WhatsAppService.sendTemplateMessage(
                booking.Mobile_Primary1__c,
                templateName,
                params
            );

            if (result != null) {
                System.debug('WhatsApp sent for booking ' + booking.Id);
            } else {
                System.debug('WhatsApp failed for booking ' + booking.Id);
            }
        }
    }
}