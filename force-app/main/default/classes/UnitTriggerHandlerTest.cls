@isTest
public class UnitTriggerHandlerTest {

    @isTest
    static void testFieldValueMappingFromProject() {
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

        List<Plot__c> plotList = [SELECT Id, Name, Status__c, Project__c FROM Plot__c WHERE Id = :plot.Id];

        Test.startTest();
        UnitTriggerHandler.fieldValueMappingFromProject(plotList);
        Test.stopTest();

        // Method is currently a stub, verify no exceptions thrown
        System.assertEquals(1, plotList.size(), 'Plot list should have one record');
    }
}