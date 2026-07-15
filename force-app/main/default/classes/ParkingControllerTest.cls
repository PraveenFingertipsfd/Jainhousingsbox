@isTest
public class ParkingControllerTest {

    @testSetup
    static void setup() {
        Project__c project = new Project__c(Name = 'Test Project', Project_Type__c = 'Villas', Active__c = true);
        insert project;

        Block__c block = new Block__c(Name = 'Test Block');
        insert block;

        Plot__c unit = new Plot__c(
            Name = '101',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = project.Project_Type__c,
            Block__c = 'A2',
            Plot_Type__c = 'Residential'
        );
        insert unit;

        Booking__c booking = new Booking__c(
            Project__c = 'Jains Anushree',
            Project1__c = project.Id,
            Block__c = block.Id,
            Plot__c = unit.Id
        );
        insert booking;

        // Create parking slots: slot 1 assigned to the booking, slots 2 and 3 available
        List<Parking__c> parkingList = new List<Parking__c>{
            new Parking__c(
                Slot_Number__c = 1,
                Parking_Type__c = 'Bike',
                Unit__c = unit.Id,
                Booking__c = booking.Id,
                Status__c = 'Sold',
                Project__c = project.Id,
                Level__c = 'Stilt',
                Tower__c = block.Id,
                Is_Swapped__c = false
            ),
            new Parking__c(
                Slot_Number__c = 2,
                Parking_Type__c = 'Car',
                Unit__c = null,
                Booking__c = null,
                Status__c = 'Available',
                Project__c = project.Id,
                Level__c = 'Basement',
                Tower__c = block.Id,
                Is_Swapped__c = false
            ),
            new Parking__c(
                Slot_Number__c = 3,
                Parking_Type__c = 'Bike',
                Unit__c = null,
                Booking__c = null,
                Status__c = 'Available',
                Project__c = project.Id,
                Level__c = 'Stilt',
                Tower__c = block.Id,
                Is_Swapped__c = false
            )
        };
        insert parkingList;
    }

    // ---- getAllDetails ----

    @isTest
    static void testGetAllDetails_ReturnsBookingAndParkings() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        ParkingController.BookingWrapper wrapper = ParkingController.getAllDetails(booking.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
        System.assertNotEquals(null, wrapper.booking, 'Booking should be populated');
        System.assertEquals(booking.Id, wrapper.booking.Id, 'Booking ID should match');
        // ExistingParking should contain the parking linked to this booking (slot 1)
        System.assertNotEquals(null, wrapper.ExistingParking, 'ExistingParking should not be null');
        System.assert(wrapper.ExistingParking.size() >= 1, 'Should have at least 1 existing parking');
        for (Parking__c ep : wrapper.ExistingParking) {
            System.assertEquals(booking.Id, ep.Booking__c, 'Existing parking should belong to this booking');
        }
    }

    @isTest
    static void testGetAllDetails_VerifiesExistingParkingDetails() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        ParkingController.BookingWrapper wrapper = ParkingController.getAllDetails(booking.Id);
        Test.stopTest();

        // Verify the existing parking has the expected slot number
        Boolean foundSlot1 = false;
        for (Parking__c ep : wrapper.ExistingParking) {
            if (ep.Slot_Number__c == 1) {
                foundSlot1 = true;
                System.assertEquals('Sold', ep.Status__c, 'Slot 1 should have Sold status');
            }
        }
        System.assert(foundSlot1, 'Should find slot 1 in existing parkings');
    }

    // ---- saveParkings: new slots only ----

    @isTest
    static void testSaveParkings_NewSlotsOnly() {
        Booking__c booking = [SELECT Id, Project1__c, Plot__c FROM Booking__c LIMIT 1];
        Block__c block = [SELECT Id FROM Block__c LIMIT 1];

        Parking__c newSlot = new Parking__c(
            Slot_Number__c = 10,
            Parking_Type__c = 'Bike',
            Booking__c = booking.Id,
            Unit__c = booking.Plot__c,
            Status__c = 'Sold',
            Level__c = 'Stilt',
            Project__c = booking.Project1__c,
            Tower__c = block.Id
        );

        Test.startTest();
        ParkingController.saveParkings(booking.Id, new List<Parking__c>{newSlot}, new List<Parking__c>());
        Test.stopTest();

        Parking__c inserted = [SELECT Id, Slot_Number__c, Booking__c, Status__c, Parking_Type__c
                                FROM Parking__c WHERE Slot_Number__c = 10 LIMIT 1];
        System.assertNotEquals(null, inserted, 'New parking slot should be inserted');
        System.assertEquals(booking.Id, inserted.Booking__c, 'Booking should be assigned');
        System.assertEquals('Sold', inserted.Status__c, 'Status should be Sold');
        System.assertEquals('Bike', inserted.Parking_Type__c, 'Parking type should be Bike');
    }

    // ---- saveParkings: swap logic ----

    @isTest
    static void testSaveParkings_SwapLogic() {
        Booking__c booking = [SELECT Id, Plot__c FROM Booking__c LIMIT 1];

        // Slot 1 is currently assigned to booking (Sold), slot 2 is Available
        Parking__c assignedSlot = [SELECT Id, Slot_Number__c, Booking__c, Unit__c, Status__c
                                    FROM Parking__c WHERE Slot_Number__c = 1 LIMIT 1];
        Parking__c availableSlot = [SELECT Id, Slot_Number__c, Status__c
                                     FROM Parking__c WHERE Slot_Number__c = 2 LIMIT 1];

        // Build the swapped slot: the old assigned slot points to the new target via Swapped_Slot__c
        Parking__c swapRecord = new Parking__c(
            Id = assignedSlot.Id,
            Swapped_Slot__c = availableSlot.Id,
            Booking__c = booking.Id,
            Unit__c = booking.Plot__c,
            Is_Swapped__c = false,
            Status__c = 'Available'
        );

        Test.startTest();
        ParkingController.saveParkings(booking.Id, new List<Parking__c>(), new List<Parking__c>{swapRecord});
        Test.stopTest();

        // After swap: the new slot (availableSlot) should now be assigned to the booking
        Parking__c newSlotAfterSwap = [SELECT Id, Booking__c, Unit__c, Status__c, Is_Swapped__c,
                                        Swapped_Slot__c, Swapped_Slot_Number__c
                                        FROM Parking__c WHERE Id = :availableSlot.Id];
        System.assertEquals(booking.Id, newSlotAfterSwap.Booking__c, 'New slot should be assigned to the booking');
        System.assertEquals(booking.Plot__c, newSlotAfterSwap.Unit__c, 'New slot Unit should match booking plot');
        System.assertEquals('Sold', newSlotAfterSwap.Status__c, 'New slot should be Sold');
        System.assertEquals(true, newSlotAfterSwap.Is_Swapped__c, 'New slot should be marked as swapped');
        System.assertEquals(assignedSlot.Id, newSlotAfterSwap.Swapped_Slot__c, 'Swapped_Slot should reference old slot');
        System.assertEquals(null, newSlotAfterSwap.Swapped_Slot_Number__c, 'Swapped_Slot_Number should be null');

        // After swap: the old slot should be released
        Parking__c oldSlotAfterSwap = [SELECT Id, Booking__c, Unit__c, Status__c, Is_Swapped__c,
                                        Swapped_Slot__c, Swapped_Slot_Number__c
                                        FROM Parking__c WHERE Id = :assignedSlot.Id];
        System.assertEquals(null, oldSlotAfterSwap.Booking__c, 'Old slot should have no booking');
        System.assertEquals(null, oldSlotAfterSwap.Unit__c, 'Old slot should have no unit');
        System.assertEquals('Available', oldSlotAfterSwap.Status__c, 'Old slot should be Available');
        System.assertEquals(false, oldSlotAfterSwap.Is_Swapped__c, 'Old slot should not be marked swapped');
        System.assertEquals(null, oldSlotAfterSwap.Swapped_Slot__c, 'Old slot Swapped_Slot should be null');
        System.assertEquals(null, oldSlotAfterSwap.Swapped_Slot_Number__c, 'Old slot Swapped_Slot_Number should be null');
    }

    // ---- saveParkings: new slots + swap together ----

    @isTest
    static void testSaveParkings_NewSlotsAndSwapTogether() {
        Booking__c booking = [SELECT Id, Project1__c, Plot__c FROM Booking__c LIMIT 1];
        Block__c block = [SELECT Id FROM Block__c LIMIT 1];

        // New slot
        Parking__c newSlot = new Parking__c(
            Slot_Number__c = 20,
            Parking_Type__c = 'Car',
            Booking__c = booking.Id,
            Unit__c = booking.Plot__c,
            Status__c = 'Sold',
            Level__c = 'Basement',
            Project__c = booking.Project1__c,
            Tower__c = block.Id
        );

        // Swap: move slot 1 to slot 3
        Parking__c slot1 = [SELECT Id, Booking__c, Unit__c FROM Parking__c WHERE Slot_Number__c = 1 LIMIT 1];
        Parking__c slot3 = [SELECT Id FROM Parking__c WHERE Slot_Number__c = 3 LIMIT 1];

        Parking__c swapRecord = new Parking__c(
            Id = slot1.Id,
            Swapped_Slot__c = slot3.Id,
            Booking__c = booking.Id,
            Unit__c = booking.Plot__c,
            Is_Swapped__c = false,
            Status__c = 'Available'
        );

        Test.startTest();
        ParkingController.saveParkings(
            booking.Id,
            new List<Parking__c>{newSlot},
            new List<Parking__c>{swapRecord}
        );
        Test.stopTest();

        // Verify new slot inserted
        Parking__c insertedNew = [SELECT Id, Slot_Number__c, Status__c
                                   FROM Parking__c WHERE Slot_Number__c = 20 LIMIT 1];
        System.assertNotEquals(null, insertedNew, 'New slot 20 should be inserted');
        System.assertEquals('Sold', insertedNew.Status__c, 'New slot should be Sold');

        // Verify swap: slot 3 now assigned, slot 1 released
        Parking__c slot3After = [SELECT Id, Booking__c, Status__c, Is_Swapped__c
                                  FROM Parking__c WHERE Id = :slot3.Id];
        System.assertEquals(booking.Id, slot3After.Booking__c, 'Slot 3 should now be assigned to booking');
        System.assertEquals('Sold', slot3After.Status__c, 'Slot 3 should be Sold');
        System.assertEquals(true, slot3After.Is_Swapped__c, 'Slot 3 should be marked swapped');

        Parking__c slot1After = [SELECT Id, Booking__c, Status__c, Is_Swapped__c
                                  FROM Parking__c WHERE Id = :slot1.Id];
        System.assertEquals(null, slot1After.Booking__c, 'Slot 1 should be released');
        System.assertEquals('Available', slot1After.Status__c, 'Slot 1 should be Available');
        System.assertEquals(false, slot1After.Is_Swapped__c, 'Slot 1 should not be swapped');
    }

    // ---- saveParkings: empty lists ----

    @isTest
    static void testSaveParkings_EmptyLists_NoError() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        ParkingController.saveParkings(booking.Id, new List<Parking__c>(), new List<Parking__c>());
        Test.stopTest();

        // No exception should be thrown; parking records should remain unchanged
        List<Parking__c> allParkings = [SELECT Id FROM Parking__c];
        System.assertEquals(3, allParkings.size(), 'All 3 original parking records should still exist');
    }

    // ---- saveParkings: upsert (update existing) ----

    @isTest
    static void testSaveParkings_UpsertExistingSlot() {
        Booking__c booking = [SELECT Id, Plot__c FROM Booking__c LIMIT 1];
        Parking__c existingSlot = [SELECT Id, Slot_Number__c, Status__c, Parking_Type__c
                                    FROM Parking__c WHERE Slot_Number__c = 2 LIMIT 1];

        // Update the existing available slot to assign to booking
        existingSlot.Booking__c = booking.Id;
        existingSlot.Unit__c = booking.Plot__c;
        existingSlot.Status__c = 'Sold';

        Test.startTest();
        ParkingController.saveParkings(booking.Id, new List<Parking__c>{existingSlot}, new List<Parking__c>());
        Test.stopTest();

        Parking__c updated = [SELECT Id, Booking__c, Status__c FROM Parking__c WHERE Id = :existingSlot.Id];
        System.assertEquals(booking.Id, updated.Booking__c, 'Slot should now be assigned to booking');
        System.assertEquals('Sold', updated.Status__c, 'Status should be updated to Sold');
    }

    // ---- BookingWrapper inner class ----

    @isTest
    static void testBookingWrapperProperties() {
        ParkingController.BookingWrapper wrapper = new ParkingController.BookingWrapper();

        // Verify default null values
        System.assertEquals(null, wrapper.booking, 'Booking should default to null');
        System.assertEquals(null, wrapper.ExistingParking, 'ExistingParking should default to null');
        System.assertEquals(null, wrapper.AllParking, 'AllParking should default to null');

        // Assign values and verify
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        List<Parking__c> parkings = [SELECT Id FROM Parking__c];

        wrapper.booking = booking;
        wrapper.ExistingParking = parkings;
        wrapper.AllParking = parkings;

        System.assertEquals(booking.Id, wrapper.booking.Id, 'Booking should match assigned value');
        System.assertEquals(parkings.size(), wrapper.ExistingParking.size(), 'ExistingParking size should match');
        System.assertEquals(parkings.size(), wrapper.AllParking.size(), 'AllParking size should match');
    }
}