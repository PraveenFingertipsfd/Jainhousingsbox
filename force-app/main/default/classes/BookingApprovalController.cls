public with sharing class BookingApprovalController {
    @AuraEnabled
    public static Boolean shouldShowCancellationCharge(Id bookingId) {
        Booking__c b = [SELECT Stage__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        List<String> mdStages = new List<String>{
            'Sale Agreement Execution Completed',
            'Registration'
        };
        return mdStages.contains(b.Stage__c);
    }

    @AuraEnabled
    public static void submitApproval(Id bookingId, String comments, Decimal cancellationCharge) {
        Booking__c booking = [SELECT Id, Stage__c FROM Booking__c WHERE Id = :bookingId];

        Boolean isMDStage = shouldShowCancellationCharge(bookingId);
        if (isMDStage && cancellationCharge == null) {
            throw new AuraHandledException('Cancellation Charge is required at this stage.');
        }

        if (!isMDStage) {
            cancellationCharge = null; // reset if not needed
        }

        booking.Cancellation_Charges__c = cancellationCharge;
        update booking;

        // You can log comments here or store in related object if required
    }
}