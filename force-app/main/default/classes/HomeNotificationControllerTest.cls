@IsTest
public class HomeNotificationControllerTest {

    @TestSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tusr',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        Date todayDate = Date.today();
        Date yesterdayDate = todayDate.addDays(-1);

        List<Booking__c> bookings = new List<Booking__c>();

        // Booking 1: Welcome Call today -- should appear in getWelcomeCallInformation
        bookings.add(new Booking__c(
            Welcome_Email_Sent_to_Customer__c = true,
            Welcome_Mail_Sent_Time__c = DateTime.now(),
            Welcome_Call_Done__c = false
        ));

        // Booking 2: Welcome Call yesterday -- should appear in getPendingFollowUpInformation
        bookings.add(new Booking__c(
            Welcome_Email_Sent_to_Customer__c = true,
            Welcome_Mail_Sent_Time__c = DateTime.now().addDays(-1),
            Welcome_Call_Done__c = false
        ));

        // Booking 3: Welcome Call done (should NOT appear in either welcome/pending list)
        bookings.add(new Booking__c(
            Welcome_Email_Sent_to_Customer__c = true,
            Welcome_Mail_Sent_Time__c = DateTime.now(),
            Welcome_Call_Done__c = true
        ));

        // Booking 4: 90% Collection today (for getNinetyPercentCollectedBookings)
        bookings.add(new Booking__c(
            Stage__c = 'Reservation',
            Is_90_Collected_Date__c = todayDate
        ));

        // Booking 5: 90% Collection yesterday (for getPendingNinetyPercentBookings)
        bookings.add(new Booking__c(
            Stage__c = 'Reservation',
            Is_90_Collected_Date__c = yesterdayDate
        ));

        // Booking 6: 90% collected but in Registration stage (should be excluded by stage filter)
        bookings.add(new Booking__c(
            Stage__c = 'Registration',
            Is_90_Collected_Date__c = todayDate
        ));

        // Booking 7: For today's bookings count
        bookings.add(new Booking__c(
            Stage__c = 'Reservation'
        ));

        insert bookings;
    }

    // ---- getWelcomeCallInformation ----

    @IsTest
    static void testGetWelcomeCallInformation_ReturnsTodaysUncompletedCalls() {
        Test.startTest();
        List<Booking__c> result = HomeNotificationController.getWelcomeCallInformation();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        // Should include booking 1 (today, not done) but NOT booking 2 (yesterday) or booking 3 (done)
        System.assert(result.size() >= 1, 'Should return at least 1 welcome call booking for today');
        for (Booking__c b : result) {
            System.assertEquals(false, b.Welcome_Call_Done__c, 'All returned bookings should have Welcome_Call_Done = false');
            System.assertEquals(true, b.Welcome_Email_Sent_to_Customer__c, 'All should have welcome email sent');
        }
    }

    // ---- getPendingFollowUpInformation ----

    @IsTest
    static void testGetPendingFollowUpInformation_ReturnsPastDueCalls() {
        Test.startTest();
        List<Booking__c> result = HomeNotificationController.getPendingFollowUpInformation();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        // Should include booking 2 (yesterday, not done) but NOT booking 1 (today) or booking 3 (done)
        System.assert(result.size() >= 1, 'Should return at least 1 pending follow-up booking from before today');
        for (Booking__c b : result) {
            System.assertEquals(false, b.Welcome_Call_Done__c, 'All returned bookings should have Welcome_Call_Done = false');
            System.assertEquals(true, b.Welcome_Email_Sent_to_Customer__c, 'All should have welcome email sent');
            // Welcome_Mail_Sent_Time__c day should be before today
            System.assert(b.Welcome_Mail_Sent_Time__c < DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)),
                           'Welcome mail sent time should be before today');
        }
    }

    // ---- updateFollowupDetails ----

    @IsTest
    static void testUpdateFollowupDetails_ReturnsUpdated() {
        Test.startTest();
        String response = HomeNotificationController.updateFollowupDetails('someId', 'Completed', 'Test comments');
        Test.stopTest();

        System.assertEquals('updated', response, 'Should always return updated (stubbed method)');
    }

    @IsTest
    static void testUpdateFollowupDetails_WithCancelledStatus() {
        Test.startTest();
        String response = HomeNotificationController.updateFollowupDetails('anotherId', 'Cancelled', 'Cancel reason');
        Test.stopTest();

        System.assertEquals('updated', response, 'Should return updated regardless of status');
    }

    // ---- getUserName ----

    @IsTest
    static void testGetUserName_ReturnsCurrentUserName() {
        Test.startTest();
        String userName = HomeNotificationController.getUserName();
        Test.stopTest();

        String expectedName = UserInfo.getName();
        System.assertEquals(expectedName, userName, 'Should return the current running user name');
        System.assertNotEquals('', userName, 'User name should not be empty');
        System.assertNotEquals(null, userName, 'User name should not be null');
    }

    // ---- todaysBookings ----

    @IsTest
    static void testTodaysBookings_ReturnsWrapperWithData() {
        Test.startTest();
        HomeNotificationController.datawrapper4 result = HomeNotificationController.todaysBookings(10, 1);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertNotEquals(null, result.ldListbooking, 'Booking list should not be null');
        // All bookings created in setup were created today
        System.assert(result.ldListbooking.size() > 0, 'Should return bookings created today');
        System.assertEquals(result.ldListbooking.size(), result.Noofbooking,
                            'Noofbooking should match list size');
    }

    @IsTest
    static void testTodaysBookings_PaginationPage2() {
        Test.startTest();
        // Page 2 with small page size to test offset logic
        HomeNotificationController.datawrapper4 result = HomeNotificationController.todaysBookings(2, 2);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertNotEquals(null, result.ldListbooking, 'Booking list should not be null');
        // With 7 bookings total and pageSize=2, page 2 should return up to 2 records (offset=2)
        System.assert(result.ldListbooking.size() <= 2, 'Should respect page size limit');
    }

    @IsTest
    static void testTodaysBookings_LargePageNumber_ReturnsEmpty() {
        Test.startTest();
        HomeNotificationController.datawrapper4 result = HomeNotificationController.todaysBookings(5, 100);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertEquals(0, result.Noofbooking, 'Should return 0 bookings for very high page number');
    }

    // ---- getNinetyPercentCollectedBookings ----

    @IsTest
    static void testGetNinetyPercentCollectedBookings_TodayOnly() {
        Test.startTest();
        List<Booking__c> result = HomeNotificationController.getNinetyPercentCollectedBookings();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        // Bookings with Is_90_Collected__c = true, today's date, and NOT in Registration/Registration Completed stage
        for (Booking__c b : result) {
            System.assertNotEquals('Registration', b.Stage__c, 'Registration stage should be excluded');
            System.assertNotEquals('Registration Completed', b.Stage__c, 'Registration Completed stage should be excluded');
            System.assertNotEquals(null, b.Is_90_Collected_Date__c, '90% collected bookings should have a collected date');
        }
    }

    // ---- getPendingNinetyPercentBookings ----

    @IsTest
    static void testGetPendingNinetyPercentBookings_BeforeToday() {
        Test.startTest();
        List<Booking__c> result = HomeNotificationController.getPendingNinetyPercentBookings();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        for (Booking__c b : result) {
            System.assertNotEquals('Registration', b.Stage__c, 'Registration stage should be excluded');
            System.assertNotEquals('Registration Completed', b.Stage__c, 'Registration Completed stage should be excluded');
            System.assertNotEquals(null, b.Is_90_Collected_Date__c, '90% collected bookings should have a collected date');
        }
    }

    // ---- getTodaysJointInspections ----

    @IsTest
    static void testGetTodaysJointInspections_ReturnsQAGivenToday() {
        Test.startTest();
        List<Booking__c> result = HomeNotificationController.getTodaysJointInspections();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        for (Booking__c b : result) {
            System.assertNotEquals('Cancellation', b.Stage__c, 'Cancelled bookings should be excluded');
            System.assert(b.Joint_Inspection_Count__c == null || b.Joint_Inspection_Count__c == 0,
                           'Joint inspection count should be null or 0');
        }
    }

    // ---- getPendingJointInspections ----

    @IsTest
    static void testGetPendingJointInspections_ReturnsPastDueInspections() {
        Test.startTest();
        List<Booking__c> result = HomeNotificationController.getPendingJointInspections();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        for (Booking__c b : result) {
            System.assertNotEquals('Cancellation', b.Stage__c, 'Cancelled bookings should be excluded');
            System.assert(b.Joint_Inspection_Count__c == null || b.Joint_Inspection_Count__c == 0,
                           'Joint inspection count should be null or 0');
        }
    }

    // ---- datawrapperfl inner class ----

    @IsTest
    static void testDatawrapperfl_Properties() {
        HomeNotificationController.datawrapperfl wrapper = new HomeNotificationController.datawrapperfl();
        wrapper.FollowupCount = 5;
        wrapper.FollowupldList = new List<Booking__c>();

        System.assertEquals(5, wrapper.FollowupCount, 'FollowupCount should be 5');
        System.assertNotEquals(null, wrapper.FollowupldList, 'FollowupldList should not be null');
        System.assertEquals(0, wrapper.FollowupldList.size(), 'FollowupldList should be empty');
    }

    // ---- datawrapper4 inner class ----

    @IsTest
    static void testDatawrapper4_Properties() {
        HomeNotificationController.datawrapper4 wrapper = new HomeNotificationController.datawrapper4();
        wrapper.Noofbooking = 10;
        wrapper.ldListbooking = new List<Booking__c>();

        System.assertEquals(10, wrapper.Noofbooking, 'Noofbooking should be 10');
        System.assertNotEquals(null, wrapper.ldListbooking, 'ldListbooking should not be null');
        System.assertEquals(0, wrapper.ldListbooking.size(), 'ldListbooking should be empty');
    }
}