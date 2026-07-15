public class CostSheetTriggerHandler {
    
    // Helper method to update Booking Requests
    public static void updateBookingRequests(Set<Id> bookingRequestIds, Boolean value) {
        if (bookingRequestIds == null || bookingRequestIds.isEmpty()) {
            return;
        }
        
        List<Booking_Request__c> requestsToUpdate = new List<Booking_Request__c>();
        for (Id reqId : bookingRequestIds) {
            requestsToUpdate.add(new Booking_Request__c(
                Id = reqId,
                is_cost_sheet_present__c = value
            ));
        }
        
        if (!requestsToUpdate.isEmpty()) {
            try {
                update requestsToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating Booking Requests: ' + e.getMessage());
                // Consider adding error handling logic here
            }
        }
    }
}