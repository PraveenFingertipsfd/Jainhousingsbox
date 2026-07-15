@isTest
public class TestNewProjectBoard {

    // 🔹 Helper method for Project Type
    private static String getValidProjectType() {
        for (Schema.PicklistEntry val : Project__c.Project_Type__c.getDescribe().getPicklistValues()) {
            if (val.isActive()) {
                return val.getValue();
            }
        }
        return null;
    }

    // 🔹 Helper method for Booking Stage
    private static String getValidStage() {
        for (Schema.PicklistEntry val : Booking__c.Stage__c.getDescribe().getPicklistValues()) {
            if (val.isActive() && val.getValue() != 'Cancellation') {
                return val.getValue();
            }
        }
        return null;
    }

    @isTest
    static void testGetProjects() {

        Project__c proj = new Project__c(
            Name = 'Test Project',
            Project_Address__c = '123 Main St',
            Project_Type__c = getValidProjectType()
        );
        insert proj;

        Test.startTest();
        List<Project__c> records = NewProjectBoardControllerClass.getProjects();
        Test.stopTest();

        System.assert(records.size() > 0);
        System.assertEquals('Test Project', records[0].Name);
    }

    @isTest
    static void testGetPlots() {

        Project__c proj = new Project__c(
            Name = 'Test Project',
            Project_Type__c = getValidProjectType()
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Test Plot',
            Project__c = proj.Id,
            Project_Type__c = proj.Project_Type__c,
            Status__c = 'Available',
            Plot_Number__c = 'PN-101',
            Property_Type__c = 'Villa',
            Plot_Type__c = 'Regular'
        );
        insert plot;

        Test.startTest();
        List<Plot__c> results = NewProjectBoardControllerClass.getPlots(proj.Id);
        Test.stopTest();

        System.assert(results.size() > 0);
        System.assertEquals('Test Plot', results[0].Name);
    }

    @isTest
    static void testGetPlots_NoPlots() {

        Project__c proj = new Project__c(
            Name = 'Empty Project',
            Project_Type__c = getValidProjectType()
        );
        insert proj;

        Test.startTest();
        List<Plot__c> results = NewProjectBoardControllerClass.getPlots(proj.Id);
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(0, results.size());
    }

    @isTest
    static void testGetProjects_MultipleProjects() {

        List<Project__c> projects = new List<Project__c>{
            new Project__c(
                Name = 'Project Alpha',
                Project_Address__c = '100 Alpha St',
                Project_Type__c = getValidProjectType()
            ),
            new Project__c(
                Name = 'Project Beta',
                Project_Address__c = '200 Beta St',
                Project_Type__c = getValidProjectType()
            ),
            new Project__c(
                Name = 'Project Gamma',
                Project_Address__c = '300 Gamma St',
                Project_Type__c = getValidProjectType()
            )
        };
        insert projects;

        Test.startTest();
        List<Project__c> results = NewProjectBoardControllerClass.getProjects();
        Test.stopTest();

        System.assert(results.size() >= 3);

        Set<String> names = new Set<String>();
        for (Project__c p : results) {
            names.add(p.Name);
        }

        System.assert(names.contains('Project Alpha'));
        System.assert(names.contains('Project Beta'));
        System.assert(names.contains('Project Gamma'));
    }

    @isTest
    static void testGetPlots_WithBooking() {

        Project__c proj = new Project__c(
            Name = 'Booking Test Project',
            Project_Type__c = getValidProjectType()
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Plot With Booking',
            Project__c = proj.Id,
            Project_Type__c = proj.Project_Type__c,
            Status__c = 'Booked',
            Plot_Number__c = 'PN-200',
            Property_Type__c = 'Villa',
            Plot_Type__c = 'Regular'
        );
        insert plot;

        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'John Doe',
            Plot__c = plot.Id,
            Stage__c = getValidStage(),
            Project1__c = proj.Id
        );
        insert booking;

        Test.startTest();
        List<Plot__c> results = NewProjectBoardControllerClass.getPlots(proj.Id);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Plot With Booking', results[0].Name);

        System.assertNotEquals(null, results[0].Bookings__r);
        System.assertEquals(1, results[0].Bookings__r.size());
        System.assertEquals('John Doe', results[0].Bookings__r[0].First_Applicant_Name__c);
    }
}