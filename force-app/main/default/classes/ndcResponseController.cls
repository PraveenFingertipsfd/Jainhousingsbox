public without sharing class ndcResponseController {
    public String comment { get; set; }
    public Id bookingId { get; set; }

    private Boolean isSubmitted = false;
    private Boolean isAlreadySubmitted = false;

    public Boolean getIsSubmitted() {
        return isSubmitted;
    }

    public Boolean getAlreadySubmitted() {
        return isAlreadySubmitted;
    }

    public ndcResponseController() {
        bookingId = ApexPages.currentPage().getParameters().get('id');
        checkSubmissionStatus();
    }

    private void checkSubmissionStatus() {
        if (bookingId != null) {
            Booking__c booking = [SELECT Is_NDC_Responded__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
            isAlreadySubmitted = booking.Is_NDC_Responded__c;
        }
    }

    public PageReference submit() {
        if (bookingId != null && comment != null && comment.trim() != '') {
            Booking__c booking = [SELECT Id, OwnerId, Is_NDC_Responded__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];

            // Prevent resubmission
            if (booking.Is_NDC_Responded__c) {
                isAlreadySubmitted = true;
                isSubmitted = true;
                return null;
            }

            booking.ndc_Response__c = comment;
            booking.Is_NDC_Responded__c = true;
            update booking;

            isSubmitted = true;
            isAlreadySubmitted = true;

            //sendCustomNotification(booking.Id, booking.OwnerId);
        }
        return null;
    }
/*
    public void sendCustomNotification(Id bookingId, Id ownerId) {
        try {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Customer Response Received');
            notification.setBody('Customer has responded to the NDC Form.');
            notification.setSenderId(UserInfo.getUserId());
            notification.setNotificationTypeId('NDC_Response_Notification');
            notification.setTargetId(bookingId);

            Set<String> recipients = new Set<String>{ownerId};
            notification.send(recipients);
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }*/
}