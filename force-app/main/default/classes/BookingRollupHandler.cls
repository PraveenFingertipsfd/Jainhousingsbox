public class BookingRollupHandler {
    public static void updateBookingRollups(Set<Id> bookingIds) {
        bookingIds.remove(null);
        
        try{
            Map<Id, AggregateResult> bookingAggMap = new Map<Id, AggregateResult>(
                [SELECT Booking__c,
                 SUM(Waive_Off_Amount__c) Total_Interest_Waive_Off,
                 SUM(Interest_A__c) 	Interest_From_PS,
                 SUM(Interest_Paid__c) Interest_Paid
                 FROM Payment_Schedule__c
                 WHERE Booking__c IN :bookingIds
                 GROUP BY Booking__c]
            );
            
            List<Booking__c> bookingsToUpdate = new List<Booking__c>();
            
            for (Id bookingId : bookingIds) {
                AggregateResult agg = bookingAggMap.get(bookingId);
                Booking__c book = new Booking__c(Id = bookingId);
                
                book.Total_Interest_Waive_Off__c = (agg != null && agg.get('Total_Interest_Waive_Off') != null) ? (Decimal)agg.get('Total_Interest_Waive_Off') : 0;
                book.Interest_From_PS__c = (agg != null && agg.get('Interest_From_PS') != null) ? (Decimal)agg.get('Interest_From_PS') : 0;
                book.Interest_Paid__c = (agg != null && agg.get('Interest_Paid') != null) ? (Integer)agg.get('Interest_Paid') : 0;
                
                bookingsToUpdate.add(book);
            }
            
            if (!bookingsToUpdate.isEmpty()) {
                update bookingsToUpdate;
            }
        }
        catch(exception exe){
            
        }
    }
}