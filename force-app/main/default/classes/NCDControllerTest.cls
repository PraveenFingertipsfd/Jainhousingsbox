@IsTest
public class NCDControllerTest {

    @TestSetup
    static void setupData() {
        // Create a Booking record with Flat_Number
        Booking__c booking = new Booking__c(
            Flat_Number__c = 101
        );
        insert booking;

        // Create related Parking records to test slot/type/level aggregation
        List<Parking__c> parkings = new List<Parking__c>{
            new Parking__c(Booking__c = booking.Id, Slot_Number__c = 1, Parking_Type__c = 'Car', Level__c = 'Stilt'),
            new Parking__c(Booking__c = booking.Id, Slot_Number__c = 2, Parking_Type__c = 'Bike', Level__c = 'Basement')
        };
        insert parkings;
    }

    @IsTest
    static void testNCDControllerWithParkingRecords() {
        // Tests constructor with parking records to cover the for-loop and set aggregation
        Booking__c booking = [SELECT Id, Flat_Number__c FROM Booking__c WHERE Flat_Number__c = 101 LIMIT 1];

        ApexPages.StandardController sc = new ApexPages.StandardController(booking);

        Test.startTest();
        NCDController controller = new NCDController(sc);
        Test.stopTest();

        // Verify bookingId is set correctly
        System.assertEquals(booking.Id, controller.bookingId, 'Booking Id should match');

        // Verify flat number
        System.assertEquals(101, controller.flatNo, 'Flat number should be 101');

        // Verify parking information is populated (order may vary due to Set)
        System.assert(controller.slots.contains('1'), 'Slots should contain 1');
        System.assert(controller.slots.contains('2'), 'Slots should contain 2');
        System.assert(controller.pTypes.contains('Car'), 'Parking types should contain Car');
        System.assert(controller.pTypes.contains('Bike'), 'Parking types should contain Bike');
        System.assert(controller.levels.contains('Stilt'), 'Levels should contain Stilt');
        System.assert(controller.levels.contains('Basement'), 'Levels should contain Basement');
    }

    @IsTest
    static void testGetFloorWithSuffix() {
        // Test the static method independently with multiple values
        System.assertEquals('1st', NCDController.getFloorWithSuffix('1'));
        System.assertEquals('2nd', NCDController.getFloorWithSuffix('2'));
        System.assertEquals('3rd', NCDController.getFloorWithSuffix('3'));
        System.assertEquals('4th', NCDController.getFloorWithSuffix('4'));
        System.assertEquals('11th', NCDController.getFloorWithSuffix('11'));
        System.assertEquals('12th', NCDController.getFloorWithSuffix('12'));
        System.assertEquals('13th', NCDController.getFloorWithSuffix('13'));
        System.assertEquals('21st', NCDController.getFloorWithSuffix('21'));
    }

    @IsTest
    static void testGetFloorWithSuffixNull() {
        // Tests the null check branch
        String result = NCDController.getFloorWithSuffix(null);
        System.assertEquals(null, result, 'Null floor should return null');
    }

    @IsTest
    static void testGetFloorWithSuffixAdditionalValues() {
        // Cover more suffix branches
        System.assertEquals('22nd', NCDController.getFloorWithSuffix('22'));
        System.assertEquals('23rd', NCDController.getFloorWithSuffix('23'));
        System.assertEquals('31st', NCDController.getFloorWithSuffix('31'));
        System.assertEquals('5th', NCDController.getFloorWithSuffix('5'));
        System.assertEquals('10th', NCDController.getFloorWithSuffix('10'));
        System.assertEquals('14th', NCDController.getFloorWithSuffix('14'));
    }

    @IsTest
    static void testControllerWithNoParking() {
        // Create a Booking record without Parking records
        Booking__c booking = new Booking__c(
            Flat_Number__c = 102
        );
        insert booking;

        ApexPages.StandardController sc = new ApexPages.StandardController(booking);

        Test.startTest();
        NCDController controller = new NCDController(sc);
        Test.stopTest();

        // Parking-related fields should be empty
        System.assertEquals('', controller.slots, 'Slots should be empty');
        System.assertEquals('', controller.pTypes, 'Parking types should be empty');
        System.assertEquals('', controller.levels, 'Levels should be empty');
    }

    @IsTest
    static void testControllerWithNullFlatNumber() {
        // Tests the null Flat_Number__c branch
        Booking__c booking = new Booking__c();
        insert booking;

        ApexPages.StandardController sc = new ApexPages.StandardController(booking);

        Test.startTest();
        NCDController controller = new NCDController(sc);
        Test.stopTest();

        System.assertEquals(null, controller.flatNo, 'Flat number should be null when not set');
    }

    @IsTest
    static void testControllerWithParkingNullFields() {
        // Tests parking records with null Slot_Number, Parking_Type, Level
        Booking__c booking = new Booking__c(
            Flat_Number__c = 103
        );
        insert booking;

        Parking__c parkingNulls = new Parking__c(
            Booking__c = booking.Id,
            Slot_Number__c = null,
            Parking_Type__c = null,
            Level__c = null
        );
        insert parkingNulls;

        ApexPages.StandardController sc = new ApexPages.StandardController(booking);

        Test.startTest();
        NCDController controller = new NCDController(sc);
        Test.stopTest();

        // All should be empty since all parking fields are null
        System.assertEquals('', controller.slots, 'Slots should be empty with null parking data');
        System.assertEquals('', controller.pTypes, 'Parking types should be empty with null parking data');
        System.assertEquals('', controller.levels, 'Levels should be empty with null parking data');
    }
}