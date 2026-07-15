@isTest
public class UnitTriggerTest {

    @TestSetup
    static void setupData() {
        Project__c project = new Project__c(
            Name = 'Test Project UT',
            Project_Type__c = 'Apartments',
            Corpus_Fund__c = 50000,
            GST_on_Corpus_Fund__c = 18,
            Maintenance_Charge__c = 5,
            GST_on_Maintenance_Charge__c = 18,
            No_of_Maintenance_Years__c = 10,
            Premium_Charge_Per_Sq_ft__c = 200,
            EB_Debris_Charges__c = 25000
        );
        insert project;

        Plot__c unit = new Plot__c(
            Name = '101',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = 'Apartments',
            Block__c = 'A2',
            Plot_Type__c = 'Residential',
            Floor__c = '1',
            Carpet_Area__c = 850,
            Super_built_up_area__c = 1500,
            Price_Per_Sq_Ft__c = 5000,
            BHK_Type__c = '3 BHK + 2T',
            Premium_Status__c = 'Premium',
            Share__c = 'MHPL',
            Facing__c = 'EAST'
        );
        insert unit;
    }

    private static Project__c getProject() {
        return [SELECT Id, Name, Corpus_Fund__c, GST_on_Corpus_Fund__c,
                       Maintenance_Charge__c, GST_on_Maintenance_Charge__c,
                       No_of_Maintenance_Years__c, Premium_Charge_Per_Sq_ft__c
                FROM Project__c LIMIT 1];
    }

    private static Plot__c getPlot() {
        return [SELECT Id, Name, Project__c, Corpus_Fund__c, GST_on_Corpus_Fund__c,
                       Maintenance_Charge__c, GST_on_Maintenance_Charge__c,
                       Premium_Charge__c, Super_built_up_area__c, Price_Per_Sq_Ft__c,
                       Is_Premium_Unit__c, QA_Given__c
                FROM Plot__c LIMIT 1];
    }

    // ── BEFORE INSERT: Auto-generate Name from Floor + Plot_Number ──
    @isTest
    static void testBeforeInsertAutoNameGeneration() {
        Project__c project = getProject();

        Test.startTest();
        Plot__c plot = new Plot__c(
            Project__c = project.Id,
            Project_Type__c = 'Apartments',
            Floor__c = '1',
            Plot_Number__c = '5',
            Status__c = 'Available',
            Block__c = 'A2',
            Plot_Type__c = 'Residential'
        );
        insert plot;
        Test.stopTest();

        Plot__c inserted = [SELECT Name FROM Plot__c WHERE Id = :plot.Id];
        System.assertEquals('105', inserted.Name, 'Name should be auto-generated as Floor + padded PlotNumber');
    }

    // ── BEFORE INSERT: Project field mapping (Corpus, GST, Maintenance) ──
    @isTest
    static void testBeforeInsertProjectFieldMapping() {
        Project__c project = getProject();

        Test.startTest();
        Plot__c plot = new Plot__c(
            Name = 'MapTest',
            Project__c = project.Id,
            Project_Type__c = 'Apartments',
            Status__c = 'Available',
            Block__c = 'A2',
            Plot_Type__c = 'Residential',
            Super_built_up_area__c = 1000
        );
        insert plot;
        Test.stopTest();

        Plot__c inserted = [SELECT Corpus_Fund__c, GST_on_Corpus_Fund__c,
                                   Maintenance_Charge__c, GST_on_Maintenance_Charge__c
                            FROM Plot__c WHERE Id = :plot.Id];
        System.assertEquals(project.Corpus_Fund__c, inserted.Corpus_Fund__c, 'Corpus Fund should map from Project');
        System.assertEquals(project.GST_on_Corpus_Fund__c, inserted.GST_on_Corpus_Fund__c, 'GST on Corpus should map');
        System.assertNotEquals(null, inserted.Maintenance_Charge__c, 'Maintenance Charge should be calculated');
    }

    // ── BEFORE INSERT: Premium Charge calculation ──
    @isTest
    static void testBeforeInsertPremiumChargeCalc() {
        Project__c project = getProject();

        Test.startTest();
        Plot__c plot = new Plot__c(
            Name = 'PremTest',
            Project__c = project.Id,
            Project_Type__c = 'Apartments',
            Status__c = 'Available',
            Block__c = 'A2',
            Plot_Type__c = 'Residential',
            Is_Premium_Unit__c = true,
            Super_built_up_area__c = 1500
        );
        insert plot;
        Test.stopTest();

        Plot__c inserted = [SELECT Premium_Charge__c FROM Plot__c WHERE Id = :plot.Id];
        Decimal expected = project.Premium_Charge_Per_Sq_ft__c * 1500;
        System.assertEquals(expected, inserted.Premium_Charge__c, 'Premium Charge = Per Sqft * Area');
    }

    
    // ── BEFORE UPDATE: Rate Revision History on Price change ──
    @isTest
    static void testBeforeUpdateRateRevisionHistory() {
        Plot__c plot = getPlot();

        Test.startTest();
        plot.Price_Per_Sq_Ft__c = 6000;
        update plot;
        Test.stopTest();

        List<Rate_Revision_History__c> history = [
            SELECT Changed_Fields__c, Changed_Values__c
            FROM Rate_Revision_History__c WHERE Unit__c = :plot.Id
        ];
        System.assert(!history.isEmpty(), 'Rate Revision History should be created on price change');
        System.assert(history[0].Changed_Fields__c.contains('Price Per Sq Ft'),
            'Changed fields should include Price Per Sq Ft');
    }

    // ── BEFORE UPDATE: Name change tracking ──
    @isTest
    static void testBeforeUpdateNameChange() {
        Plot__c plot = getPlot();

        Test.startTest();
        plot.Name = '202';
        update plot;
        Test.stopTest();

        List<Rate_Revision_History__c> history = [
            SELECT Changed_Fields__c FROM Rate_Revision_History__c WHERE Unit__c = :plot.Id
        ];
        System.assert(!history.isEmpty(), 'Rate Revision History should be created on name change');
        System.assert(history[0].Changed_Fields__c.contains('Name'), 'Changed fields should include Name');
    }

    // ── BEFORE UPDATE: Premium recalc when Super_built_up_area changes ──
    @isTest
    static void testBeforeUpdatePremiumRecalcOnAreaChange() {
        Plot__c plot = getPlot();
        Project__c project = getProject();

        Test.startTest();
        plot.Super_built_up_area__c = 2000;
        plot.Is_Premium_Unit__c = true;
        update plot;
        Test.stopTest();

        Plot__c updated = [SELECT Premium_Charge__c, Maintenance_Charge__c FROM Plot__c WHERE Id = :plot.Id];
        Decimal expectedPremium = project.Premium_Charge_Per_Sq_ft__c * 2000;
        System.assertEquals(expectedPremium, updated.Premium_Charge__c,
            'Premium Charge should be recalculated on area change');
        System.assertNotEquals(null, updated.Maintenance_Charge__c,
            'Maintenance Charge should be recalculated');
    }

    // ── BEFORE UPDATE: Is_Premium_Unit toggle off → Premium = 0 ──
    @isTest
    static void testBeforeUpdateIsPremiumToggleOff() {
        Plot__c plot = getPlot();

        // First set to premium
        plot.Is_Premium_Unit__c = true;
        update plot;

        Test.startTest();
        plot.Is_Premium_Unit__c = false;
        update plot;
        Test.stopTest();

        Plot__c updated = [SELECT Premium_Charge__c FROM Plot__c WHERE Id = :plot.Id];
        System.assertEquals(0, updated.Premium_Charge__c, 'Premium Charge should be 0 when not premium');
    }

    // ── AFTER UPDATE: QA_Given__c changes to true (notification) ──
    @isTest
    static void testAfterUpdateQAGiven() {
        Plot__c plot = getPlot();

        Test.startTest();
        plot.QA_Given__c = true;
        update plot;
        Test.stopTest();

        // Notification type may not exist — trigger handles gracefully with try-catch + return
        System.assert(true, 'QA Given update completed without unhandled exception');
    }

    // ── BEFORE UPDATE: No field changes (no Rate Revision History created) ──
    @isTest
    static void testBeforeUpdateNoChanges() {
        Plot__c plot = getPlot();

        Test.startTest();
        // Update with same values — no field changes
        update plot;
        Test.stopTest();

        List<Rate_Revision_History__c> history = [
            SELECT Id FROM Rate_Revision_History__c WHERE Unit__c = :plot.Id
        ];
        System.assertEquals(0, history.size(), 'No history should be created when nothing changed');
    }
}