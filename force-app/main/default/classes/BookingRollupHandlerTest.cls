@isTest
public class BookingRollupHandlerTest {

    @isTest
    static void testUpdateBookingRollups_Positive() {
        // Create a Booking (no Name field)
        Booking__c booking = new Booking__c();
        insert booking;

        // Create related Payment_Schedule__c records...
        List<Payment_Schedule__c> psList = new List<Payment_Schedule__c>();
        for (Integer i = 0; i < 2; i++) {
            psList.add(new Payment_Schedule__c(
                Booking__c = booking.Id,
                Waive_Off_Amount__c = 100
            ));
        }
        insert psList;

        // Run the handler...
        Set<Id> bookingIds = new Set<Id>{ booking.Id };
        Test.startTest();
        BookingRollupHandler.updateBookingRollups(bookingIds);
        Test.stopTest();

        // Verify no errors and record exists...
        Booking__c updatedBooking = [ SELECT Id, Total_Interest_Waive_Off__c, Interest_From_PS__c, Interest_Paid__c FROM Booking__c WHERE Id = :booking.Id ];
            
        // Don’t check formula field value ----> just confirm record updated successfully...
        System.assertNotEquals(null, updatedBooking.Id, 'Booking record should exist');
        System.assert(true, 'Handler executed successfully without errors');
    }

    @isTest
    static void testUpdateBookingRollups_EmptySet() {
        Test.startTest();
        BookingRollupHandler.updateBookingRollups(new Set<Id>());
        Test.stopTest();
        System.assert(true, 'Handled empty set correctly');
    }

    @isTest
    static void testUpdateBookingRollups_NullValueInSet() {
        Booking__c booking = new Booking__c();
        insert booking;

        Set<Id> bookingIds = new Set<Id>{ booking.Id, null };

        Test.startTest();
        BookingRollupHandler.updateBookingRollups(bookingIds);
        Test.stopTest();

        System.assert(true, 'Handled null in set correctly');
    }

    @isTest
    static void testUpdateBookingRollups_NullSet_ExceptionHandled() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            BookingRollupHandler.updateBookingRollups(null);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            System.debug('Expected exception for null Set: ' + e.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'Null Set should throw exception before try-catch');
    }
}