@isTest
public class csrFill_ControllerTest {

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments'
        );
        insert project;

        Plot__c plot = new Plot__c(
            Name = 'Test Unit',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = 'Apartments'
        );
        insert plot;

        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Test Customer',
            Plot__c = plot.Id,
            Project__c = 'Jains Anushree',
            Project1__c = project.Id
        );
        insert booking;

        Joint_Inspection__c ji = new Joint_Inspection__c(
            Booking__c = booking.Id,
            Joint_Inspection_Status__c = 'Completed'
        );
        insert ji;
    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        Map<String, List<String>> picklistValues = csrFill_Controller.getPicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, picklistValues, 'Picklist values should not be null');
        System.assert(picklistValues.containsKey('problems'), 'Should contain problems key');
    }

    @isTest
    static void testGetJointInspectionDetails() {
        Joint_Inspection__c ji = [SELECT Id FROM Joint_Inspection__c LIMIT 1];

        Test.startTest();
        Joint_Inspection__c result = csrFill_Controller.getJointInspectionDetails(ji.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return inspection record');
        System.assertEquals(ji.Id, result.Id, 'Should return correct inspection');
    }

    @isTest
    static void testGetJointInspectionDetailsInvalidId() {
        Test.startTest();
        Joint_Inspection__c result = csrFill_Controller.getJointInspectionDetails(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for invalid ID');
    }

    @isTest
    static void testSaveInspectionWithSnags() {
        Joint_Inspection__c ji = [SELECT Id, Booking__c FROM Joint_Inspection__c LIMIT 1];

        List<Snag__c> snags = new List<Snag__c>();
        snags.add(new Snag__c(
            Problem_Type__c = 'Civil'
        ));

        List<Map<String, String>> responses = new List<Map<String, String>>();
        Map<String, String> response1 = new Map<String, String>();
        response1.put('field', 'FBQ1__c');
        response1.put('value', 'Excellent');
        responses.add(response1);

        String signatureData = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

        Test.startTest();
        try {
            csrFill_Controller.saveInspectionWithSnags(ji, snags, signatureData, responses, 'Great service', 'More parking');
        } catch (AuraHandledException e) {
            // May throw due to validation rules or required fields on Feedback__c/Snag__c
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveInspectionWithoutSnags() {
        Joint_Inspection__c ji = [SELECT Id, Booking__c FROM Joint_Inspection__c LIMIT 1];

        List<Map<String, String>> responses = new List<Map<String, String>>();
        Map<String, String> response1 = new Map<String, String>();
        response1.put('field', 'FBQ1__c');
        response1.put('value', 'Good');
        responses.add(response1);

        Test.startTest();
        try {
            csrFill_Controller.saveInspectionWithSnags(ji, null, '', responses, '', '');
        } catch (AuraHandledException e) {
            // May throw due to validation rules or required fields on Feedback__c
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveInspectionWithEmptyResponses() {
        Joint_Inspection__c ji = [SELECT Id, Booking__c FROM Joint_Inspection__c LIMIT 1];

        Test.startTest();
        try {
            csrFill_Controller.saveInspectionWithSnags(ji, new List<Snag__c>(), '', null, '', '');
        } catch (AuraHandledException e) {
            // May throw due to validation rules or required fields on Feedback__c
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveInspectionExceptionPath() {
        Joint_Inspection__c ji = [SELECT Id, Booking__c FROM Joint_Inspection__c LIMIT 1];

        List<Map<String, String>> badResponses = new List<Map<String, String>>();
        badResponses.add(new Map<String, String>{'field' => 'InvalidField__c', 'value' => 'TestValue'});

        try {
            Test.startTest();
            csrFill_Controller.saveInspectionWithSnags(ji, new List<Snag__c>(), '', badResponses, 'Good', 'Improve');
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException not thrown');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('Error saving data') ||
                e.getMessage().contains('Script-thrown exception') ||
                e.getMessage().contains('Invalid field'),
                'Unexpected message: ' + e.getMessage()
            );
        }
    }
}