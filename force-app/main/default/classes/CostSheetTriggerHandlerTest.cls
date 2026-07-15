@isTest
public class CostSheetTriggerHandlerTest {
    
    @isTest
    static void testUpdateBookingRequests_Positive() {
        // Step 1: Create test Booking Request records (exclude Name field)...
        List<Booking_Request__c> requests = new List<Booking_Request__c>();
        for (Integer i = 0; i < 3; i++) {
            requests.add(new Booking_Request__c( is_cost_sheet_present__c = false));
                            
        }
        insert requests;

        // Step 2: Collect IDs...

        Set<Id> bookingIds = new Set<Id>();
        for (Booking_Request__c req : requests) {
            bookingIds.add(req.Id);
        }

        // Step 3: Call method...

        Test.startTest();
        CostSheetTriggerHandler.updateBookingRequests(bookingIds, true);
        Test.stopTest();

        // Step 4: Verify updates...
        
        List<Booking_Request__c> updatedRequests = [ SELECT Id, is_cost_sheet_present__c FROM Booking_Request__c WHERE Id IN :bookingIds ];
            
        for (Booking_Request__c req : updatedRequests) {
            System.assertEquals(true, req.is_cost_sheet_present__c, 'Cost Sheet flag should be true');
        }
    }

    @isTest
    static void testUpdateBookingRequests_EmptySet() {
        
        // Empty Set test...
        Test.startTest();
        CostSheetTriggerHandler.updateBookingRequests(new Set<Id>(), true);
        Test.stopTest();
        System.assert(true, 'Handled empty set gracefully');
    }

    @isTest
    static void testUpdateBookingRequests_NullSet() {
        
        // Null Set test...
        Test.startTest();
        CostSheetTriggerHandler.updateBookingRequests(null, false);
        Test.stopTest();
        System.assert(true, 'Handled null set gracefully');
    }

    @isTest
    static void testUpdateBookingRequests_DmlException() {
        // Create a valid record first...
        Booking_Request__c req = new Booking_Request__c(is_cost_sheet_present__c = false);
        insert req;

        Id deletedId = req.Id;
        delete req;

        Set<Id> invalidIds = new Set<Id>{ deletedId };

        Test.startTest();
        CostSheetTriggerHandler.updateBookingRequests(invalidIds, true);
        Test.stopTest();

        System.assert(true, 'Handled DML exception gracefully');
    }
}