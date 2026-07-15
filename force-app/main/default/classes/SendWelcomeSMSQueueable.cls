public class SendWelcomeSMSQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> bookingIds;

    public SendWelcomeSMSQueueable(List<Id> bookingIds) {
        this.bookingIds = bookingIds;
    }

    public void execute(QueueableContext context) {
        String templateId = SMSTemplates.getTemplateId('Welcome_SMS');
        if (String.isBlank(templateId)) return;

        List<Booking__c> bookings = [
            SELECT Id, First_Applicant_Name__c, Mobile_Primary1__c, Project1__r.Name
            FROM Booking__c WHERE Id IN :bookingIds
        ];

        for (Booking__c booking : bookings) {
            if (String.isBlank(booking.Mobile_Primary1__c)) continue;

            String message = SMSTemplates.buildWelcomeMessage(booking);
            String messageId = BulkSMSService.sendSMS(
                booking.Mobile_Primary1__c,   // From Booking record
                message,                       // DLT template text
                templateId                     // From SMS_Template__mdt
            );
        }
    }
}