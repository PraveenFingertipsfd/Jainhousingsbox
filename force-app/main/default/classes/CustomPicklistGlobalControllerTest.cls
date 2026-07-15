@isTest
public class CustomPicklistGlobalControllerTest {

    @isTest
    static void testFindPicklistOptions_ValidField() {
        // Use a standard SObject and picklist field
        // Example: ---- Opportunity.StageName -----
        String objectApi = 'Opportunity';
        String fieldApi = 'StageName';

        Test.startTest();
        List<CustomPicklistGlobalController.picklistWrapper> results =
            CustomPicklistGlobalController.findPicklistOptions(objectApi, fieldApi);
        Test.stopTest();

        // Verify returned data...
        System.assertNotEquals(0, results.size(), 'Picklist values should not be empty');
        System.assertNotEquals(null, results[0].pickListLabel, 'Label should not be null');
        System.assertNotEquals(null, results[0].pickListValue, 'Value should not be null');
    }

    @isTest
    static void testFindPicklistOptions_InvalidObject() {
        Boolean exceptionThrown = false;
        try {
            // Invalid object API name...
            CustomPicklistGlobalController.findPicklistOptions('InvalidObject__c', 'SomeField__c');
        } catch (Exception e) {
            exceptionThrown = true;
            System.debug('Expected exception (Invalid Object): ' + e.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'Exception should be thrown for invalid object');
    }

    @isTest
    static void testFindPicklistOptions_InvalidField() {
        Boolean exceptionThrown = false;
        try {
            // Valid object but invalid field...
            CustomPicklistGlobalController.findPicklistOptions('Account', 'InvalidField__c');
        } catch (Exception e) {
            exceptionThrown = true;
            System.debug('Expected exception (Invalid Field): ' + e.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'Exception should be thrown for invalid field');
    }
}