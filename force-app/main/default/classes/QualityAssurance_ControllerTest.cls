@isTest
public class QualityAssurance_ControllerTest {

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(
            Name = 'Test Project',
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
    }

    @isTest
    static void testConfirmQualityAssurance() {
        Plot__c plot = [SELECT Id, QA_Given__c FROM Plot__c LIMIT 1];
        System.assertEquals(false, plot.QA_Given__c, 'QA should not be given initially');

        Test.startTest();
        QualityAssurance_Controller.confirmQualityAssurance(plot.Id);
        Test.stopTest();

        Plot__c updatedPlot = [SELECT Id, QA_Given__c, QA_Given_Date__c FROM Plot__c WHERE Id = :plot.Id];
        System.assertEquals(true, updatedPlot.QA_Given__c, 'QA should be marked as given');
        System.assertNotEquals(null, updatedPlot.QA_Given_Date__c, 'QA date should be set');
    }

    @isTest
    static void testConfirmQualityAssuranceInvalidId() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            QualityAssurance_Controller.confirmQualityAssurance('001000000000000AAA');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Should throw exception for invalid ID');
    }
}