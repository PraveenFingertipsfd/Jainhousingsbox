@isTest
public class customReportControllerTest {

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments',
            Project__c = 'Jains Anushree'
        );
        insert project;

        Block__c block = new Block__c(
            Name = 'Tower A',
            Project__c = project.Id
        );
        insert block;

        Plot__c plot = new Plot__c(
            Name = 'Unit 101',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = 'Apartments'
        );
        insert plot;

        // Total__c, Pending_Amount__c, Total_received_Amount__c are formula/rollup - do not set
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Test Customer',
            Project__c = 'Jains Anushree',
            Project1__c = project.Id,
            Plot__c = plot.Id
        );
        insert booking;

        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Name = 'Milestone 1',
            S_No__c = 1,
            Project__c = project.Id,
			Project_Type__c = 'Apartments',
            Use_for_report__c = true
        );
        insert mps;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c = booking.Id,
            S_No__c = 1,
            Master_Payment_Schedule__c = mps.Id,
            Is_Demanded__c = true
        );
        insert ps;
    }

    @isTest
    static void testConstructor() {
        Test.startTest();
        customReportController controller = new customReportController();
        Test.stopTest();

        System.assertEquals(false, controller.isExport, 'Export should be false initially');
        System.assertNotEquals(null, controller.projectOptions, 'Project options should be populated');
        System.assert(controller.projectOptions.size() > 1, 'Should have at least default + 1 project option');
    }

    @isTest
    static void testPopulateProjectOptions() {
        customReportController controller = new customReportController();

        Test.startTest();
        controller.populateProjectOptions();
        Test.stopTest();

        System.assertNotEquals(null, controller.projectOptions, 'Options should not be null');
        System.assert(controller.projectOptions.size() >= 2, 'Should have default option plus projects');
    }

    @isTest
    static void testGetTowers() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        customReportController controller = new customReportController();
        controller.selectedProjectId = project.Id;

        Test.startTest();
        controller.getTowers();
        Test.stopTest();

        System.assertNotEquals(null, controller.towerOptions, 'Tower options should not be null');
        System.assert(controller.towerOptions.size() >= 2, 'Should have default option plus towers');
    }

    @isTest
    static void testFilterByProjectOnly() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        customReportController controller = new customReportController();
        controller.selectedProjectId = project.Id;
        controller.selectedTowerId = '';

        Test.startTest();
        controller.filterByProject();
        Test.stopTest();

        System.assertNotEquals(null, controller.dataList, 'Data list should not be null');
        System.assertNotEquals(0, controller.dataList.size(), 'Should have booking data');
        System.assertNotEquals(null, controller.paymentScheduleHeaders, 'Payment headers should be set');
    }

    @isTest
    static void testFilterByProjectAndTower() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Block__c block = [SELECT Id FROM Block__c LIMIT 1];
        customReportController controller = new customReportController();
        controller.selectedProjectId = project.Id;
        controller.selectedTowerId = block.Id;

        Test.startTest();
        controller.filterByProject();
        Test.stopTest();

        System.assertNotEquals(null, controller.dataList, 'Data list should not be null');
    }

    @isTest
    static void testFilterByProjectNoSelection() {
        customReportController controller = new customReportController();
        controller.selectedProjectId = '';
        controller.selectedTowerId = '';

        Test.startTest();
        controller.filterByProject();
        Test.stopTest();

        System.assertNotEquals(null, controller.filterMessage, 'Filter message should be shown');
    }

    @isTest
    static void testGetExport() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        customReportController controller = new customReportController();
        controller.selectedProjectId = project.Id;
        controller.selectedTowerId = '';

        Test.startTest();
        PageReference result = controller.getExport();
        Test.stopTest();

        System.assertEquals(true, controller.isExport, 'Export flag should be true');
        System.assertEquals(null, result, 'Should return null PageReference');
    }

    @isTest
    static void testGetCodeCoveragse() {
        customReportController controller = new customReportController();

        Test.startTest();
        PageReference result = controller.getCodeCoveragse();
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null');
    }

    @isTest
    static void testPaymentScheduleWrapper() {
        Test.startTest();
        customReportController.PaymentScheduleWrapper wrapper = new customReportController.PaymentScheduleWrapper();
        wrapper.paymentScheduleName = 'Milestone 1';
        wrapper.paymentScheduleSNo = 1;
        wrapper.amountReceived = 100000;
        wrapper.balanceAmount = 50000;
        Test.stopTest();

        System.assertEquals('Milestone 1', wrapper.paymentScheduleName);
        System.assertEquals(1, wrapper.paymentScheduleSNo);
    }

    @isTest
    static void testPaymentScheduleWrapper123() {
        Test.startTest();
        customReportController.PaymentScheduleWrapper123 wrapper = new customReportController.PaymentScheduleWrapper123(1);
        Test.stopTest();

        System.assertEquals(1, wrapper.paymentScheduleName);
        System.assertEquals(0, wrapper.totalDemandAmount);
        System.assertEquals(0, wrapper.pendingAmount);
        System.assertEquals(0, wrapper.receivedAmount);
    }

    @isTest
    static void testDataWrapper() {
        Test.startTest();
        customReportController.DataWrapper wrapper = new customReportController.DataWrapper();
        wrapper.serialNumber = 1;
        wrapper.paymentSchedules = new List<Payment_Schedule__c>();
        Test.stopTest();

        System.assertEquals(1, wrapper.serialNumber);
        System.assertNotEquals(null, wrapper.paymentSchedules);
    }
}