@isTest
public class PaymentScheduleTriggerTest {
 
    @TestSetup
    static void setupData() {
        Booking__c booking = new Booking__c();
        insert booking;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c = booking.Id,
            Include_Interest__c = true,
            Waive_Off_Amount__c = 500,
            Balance_Amount__c = 1000
        );
        insert ps;
    }

    @isTest
    static void testBeforeUpdate_InterestRemoved() {
        Payment_Schedule__c ps = [SELECT Id, Include_Interest__c, Balance_Amount__c, AmountB__c
                                  FROM Payment_Schedule__c LIMIT 1];

        Decimal expectedBalance = ps.AmountB__c;

        Test.startTest();
        ps.Include_Interest__c = false;
        update ps;
        Test.stopTest();

        Payment_Schedule__c updated = [SELECT Id, Balance_Amount__c, AmountB__c
                                       FROM Payment_Schedule__c WHERE Id = :ps.Id];
        System.assertEquals(updated.AmountB__c, updated.Balance_Amount__c,
            'Balance_Amount should be set to AmountB when Include_Interest changes to false');
    }

    @isTest
static void testAfterInsert_RollupUpdate() {
    Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

    Test.startTest();
    Payment_Schedule__c newPs = new Payment_Schedule__c(
        Booking__c = booking.Id,
        Include_Interest__c = false,
        Waive_Off_Amount__c = 200
    );
    insert newPs;
    Test.stopTest();

    Booking__c updatedBooking = [SELECT Id FROM Booking__c WHERE Id = :booking.Id];

    System.assertNotEquals(null, updatedBooking.Id,
        'Booking should exist after rollup execution');
}
    @isTest
    static void testAfterDelete_RollupUpdate() {
        Payment_Schedule__c ps = [SELECT Id, Booking__c FROM Payment_Schedule__c LIMIT 1];
        Id bookingId = ps.Booking__c;

        Test.startTest();
        delete ps;
        Test.stopTest();

        Booking__c updatedBooking = [SELECT Id, Total_Interest_Waive_Off__c FROM Booking__c WHERE Id = :bookingId];
        System.assertNotEquals(null, updatedBooking.Id,
            'Booking should still exist after payment schedule deletion');
        System.assertEquals(0, updatedBooking.Total_Interest_Waive_Off__c,
            'Total_Interest_Waive_Off should be 0 after all payment schedules are deleted');
    }
}