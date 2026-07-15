public class GeneratePC {
    @AuraEnabled
    public static Boolean isPossessionSent(Id bookingId) {
        try {
            // Query the Booking record
            Booking__c booking = [SELECT Possession_send__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
            // Return the value of Possession_send__c
            return booking.Possession_send__c;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving booking possession status: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static String sendPossessionLetter(Id recId) {
       return GenerateDocumnetController.sendEmailGeneratePC(recId);
    }
}