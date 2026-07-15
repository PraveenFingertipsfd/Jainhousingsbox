@IsTest
public class CallRouteControllerTest {

    @TestSetup
    static void setupData() {
        // Create a User with phone...
        User u = new User(
            Username = 'testuser1_' + System.currentTimeMillis() + '@example.com', // [ unique username ]
            LastName = 'Test',
            Email = 'testuser1@example.com',
            Alias = 'tuser1',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            Phone = '9998887777'
        );
        insert u;
        
        // Create Booking with Mobile_Primary1__c matching the user phone....
        Booking__c b = new Booking__c(
            Mobile_Primary1__c = '9998887777',
            OwnerId = u.Id
        );
        insert b;
        
        // Create Booking with no matching number
        Booking__c b2 = new Booking__c(
            Mobile_Primary1__c = '1234567890'
        );
        insert b2;
    }

    @IsTest
    static void testBookingFoundWithOwnerPhone() {
        // Simulate page parameters...
        PageReference dummyPage = new PageReference('/apex/dummy');
        Test.setCurrentPage(dummyPage);
        ApexPages.currentPage().getParameters().put('fromnumber', '9998887777');
        ApexPages.currentPage().getParameters().put('landingNumber', '0001112222');
        
        
        Test.startTest();
        CallRouteController.callConnecting();
        Test.stopTest();
        
        
        System.assertNotEquals(null, CallRouteController.calloutResponse);
        System.assert(CallRouteController.calloutResponse.contains('phone'));
        System.assert(CallRouteController.calloutResponse.contains('bookingUrl'));
    }

    @IsTest
    static void testBookingNotFound() {
        // Simulate page parameters with number that doesn't match...
        PageReference dummyPage = new PageReference('/apex/dummy');
        Test.setCurrentPage(dummyPage);
        ApexPages.currentPage().getParameters().put('fromnumber', '5554443333');
        
        
        Test.startTest();
        CallRouteController.callConnecting();
        Test.stopTest();
        
        
        System.assert(CallRouteController.calloutResponse.contains('NO_BOOKING'));
        System.assert(CallRouteController.calloutResponse.contains('phone'));
    }

    @IsTest
    static void testBookingFoundOwnerPhoneBlank() {
        // Create a user without phone....
        User u2 = new User(
            Username = 'testuser2_' + System.currentTimeMillis() + '@example.com', // [unique username]
            LastName = 'Test2',
            Email = 'testuser2@example.com',
            Alias = 'tuser2',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u2;
        
        Booking__c b3 = new Booking__c(
            Mobile_Primary1__c = '7776665555',
            OwnerId = u2.Id
        );
        insert b3;
        
        // Simulate page parameters...
        PageReference dummyPage = new PageReference('/apex/dummy');
        Test.setCurrentPage(dummyPage);
        ApexPages.currentPage().getParameters().put('fromnumber', '7776665555');
        
        Test.startTest();
        CallRouteController.callConnecting();
        Test.stopTest();
        
        
        System.assert(CallRouteController.calloutResponse.contains(Label.NewCallRouteNumber));
    }

    @IsTest
    static void testExceptionHandling() {
        // Pass null parameters to trigger exception safely (simulate)...
        PageReference dummyPage = new PageReference('/apex/dummy');
        Test.setCurrentPage(dummyPage);
        
        // Manipulate so query throws an exception (invalid field) - optional
        Test.startTest();
        try {
            CallRouteController.callConnecting();
        } catch (Exception e) {
            // should not throw, already handled
        }
        Test.stopTest();
        
        System.assert(CallRouteController.calloutResponse.contains('phone') || 
                      CallRouteController.calloutResponse.contains('NO_BOOKING') ||
                      CallRouteController.calloutResponse.contains('error'));
    }
}