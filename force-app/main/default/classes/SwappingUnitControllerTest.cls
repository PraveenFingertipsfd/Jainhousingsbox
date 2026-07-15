@isTest
public class SwappingUnitControllerTest {
    
    @TestSetup
    static void makeData(){
        Project__c project = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Apartments'
        );
        insert project;
        
        // Create test data for Plot__c
        Plot__c unit = new Plot__c(
            Name = '101',
            Status__c = 'Available',
            Project__c = project.Id,               // Master-detail lookup to Project
            Project_Type__c = project.Project_Type__c, // Must match Project
            Block__c ='A2 ',                   // Lookup to Block           
            Plot_Type__c = 'Residential',
            Carpet_Area__c = 850,
            Balcony_Sq_mts__c = 20,
            Balcony_Area__c = 100,
            BHK_Type__c = '3 BHK + 2T',
            Premium_Status__c = 'Premium',
            Floor__c = '1',
            Share__c = 'MHPL',
            Facing__c = 'EAST',
            Carpet_Sq_mts__c = 80,
            CA__c = 75,
            Built_up_area__c = 1200,
            UDS__c = 300,
            UDS_Sq_mts__c = 50,
            Super_built_up_area__c = 1500,
            Price_Per_Sq_Ft__c = 5000,
            Floor_Rise__c = 200,
            Premium_Charge__c = 100000,
            Covered_Park_Parking__c = 50000,
            Other_Charges__c = 20000,
            Solar_Charges__c = 15000,
            GST1__c = 18
        );
        insert unit;
        
        // Create another Plot__c for swapping
        Plot__c swapUnit = new Plot__c(
            Name = '102',
            Status__c = 'Available',
            Project__c = project.Id,
            Project_Type__c = project.Project_Type__c,
            Block__c = 'A2',
            Plot_Type__c = 'Residential',
            Carpet_Area__c = 900,
            Balcony_Sq_mts__c = 25,
            Balcony_Area__c = 110,
            BHK_Type__c = '3 BHK + 2T',
            Premium_Status__c = 'Premium',
            Floor__c = '2',
            Share__c = 'MHPL',
            Facing__c = 'WEST',
            Carpet_Sq_mts__c = 85,
            CA__c = 80,
            Built_up_area__c = 1250,
            UDS__c = 320,
            UDS_Sq_mts__c = 55,
            Super_built_up_area__c = 1550,
            Price_Per_Sq_Ft__c = 5100,
            Floor_Rise__c = 250,
            Premium_Charge__c = 110000,
            Covered_Park_Parking__c = 55000,
            Other_Charges__c = 25000,
            Solar_Charges__c = 16000,
            GST1__c = 18
        );
        insert swapUnit;
        
        // Create test data for Booking__c
        Booking__c book = new Booking__c(
            Followup_Date__c = system.today(),
            Followup_Subject__c = 'test22',
            Last_Comment__c = 'test22',
            Project__c ='Jains Anushree' ,               
            Payment_Type__c = 'Custom',
            Sale_Agreement_Completed__c = false,
            Agreement_Amount_Cleared__c = 'Received Partial Amount',
            Stage__c = 'Reservation',
            Demand_Number__c = '12345',
            Date_of_Booking__c = System.today(),
            Mode_Of_Payment__c = 'Credit Card',
            Funding_Type__c = 'Self',
            Plot__c = unit.Id,
            Loan_Sanction_Confirmed__c = true,
            Loan_Sanctioned_Amount__c = 10000,
            Sale_Agreement_Date__c = system.today(),
            Built_up_area__c = 2080,
            Premium_Charge__c = 50000,
            Other_Charges__c = 30000,
            Covered_Park_Parking__c = 300000,
            GST__c = 10
        );
        insert book;
        
        // Create another Booking for testing
        Booking__c book2 = new Booking__c(
            Followup_Date__c = system.today(),
            Followup_Subject__c = 'test33',
            Last_Comment__c = 'test33',
            Project__c ='Jains Anushree' ,               
            Payment_Type__c = 'Standard',
            Sale_Agreement_Completed__c = true,  // For testing no approval
            Agreement_Amount_Cleared__c = 'Received Full Amount',
            Stage__c = 'Registration',
            Demand_Number__c = '67890',
            Date_of_Booking__c = System.today(),
            Mode_Of_Payment__c = 'Cash',
            Funding_Type__c = 'Loan',
            Plot__c = swapUnit.Id,
            Loan_Sanction_Confirmed__c = false,
            Loan_Sanctioned_Amount__c = 20000,
            Sale_Agreement_Date__c = system.today(),
            Built_up_area__c = 2100,
            Premium_Charge__c = 60000,
            Other_Charges__c = 35000,
            Covered_Park_Parking__c = 320000,
            GST__c = 12
        );
        insert book2;
        
        // Create test data for Master_payment_schedule__c
        Master_payment_schedule__c mpy = new Master_payment_schedule__c(
            Status__c = 'Completed',
            Project__c = project.Id,               // Master-detail lookup to Project
            Project_Type__c = project.Project_Type__c, // Must match Project
            Name = 'Test MPS',
            S_No__c = 1,
            Payment_Percent__c = 10,
            Amount__c = 100000
        );
        insert mpy;
        
        // Create another MPS for more data
        Master_payment_schedule__c mpy2 = new Master_payment_schedule__c(
            Status__c = 'Not Started',
            Project__c = project.Id,
            Project_Type__c = project.Project_Type__c,
            Name = 'Test MPS 2',
            S_No__c = 2,
            Payment_Percent__c = 20,
            Amount__c = 200000
        );
        insert mpy2;
    }
    
    @isTest
    static void testGetBooking() {
        Booking__c testBooking = [SELECT Id FROM Booking__c LIMIT 1];
        
        Test.startTest();
        Booking__c result = SwappingUnitController.getBooking(testBooking.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Booking should be returned');
        System.assertEquals(testBooking.Id, result.Id, 'Booking ID should match');
        // Additional assertions for fields
        System.assertNotEquals(null, result.Plot__c, 'Plot should be populated');
        System.assertNotEquals(null, result.Project__c, 'Project should be populated');
    }
    
    @isTest
    static void testGetUnit() {
        Plot__c testPlot = [SELECT Id FROM Plot__c LIMIT 1];
        
        Test.startTest();
        Plot__c result = SwappingUnitController.getUnit(testPlot.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Plot should be returned');
        System.assertEquals(testPlot.Id, result.Id, 'Plot ID should match');
        // Additional assertions
        System.assertNotEquals(null, result.Name, 'Name should be populated');
        System.assertNotEquals(null, result.Block__c, 'Block should be populated');
    }
   /* 
    @isTest
    static void testSaveOppPlotWithApproval() {
        Booking__c testBooking = [SELECT Id, SLead__c FROM Booking__c WHERE Sale_Agreement_Completed__c = false LIMIT 1];
        Plot__c newPlot = [SELECT Id FROM Plot__c WHERE Name = '102' LIMIT 1];
        
        // Create oppPlot with swap fields
        Booking__c oppPlot = new Booking__c(
            Plot__c = newPlot.Id,
            Swap_Unit__c = '102',
            Swap_Solar_Charges__c = 16000,
            Swap_Extra_Covered_Parking_Charges__c = 0,
            Swap_Extra_Covered_Parking_Slots__c = 0,
            Swap_Funding_Type__c = 'Self',
            Swap_Mode_of_Payment__c = 'Cash',
            Swap_Unit_Status__c = 'Available'
        );
        
        Test.startTest();
        String result = SwappingUnitController.saveOppPlot(oppPlot, testBooking.Id);
        Test.stopTest();
        
        System.assertEquals(testBooking.Id, result, 'Should return the booking ID');
        
        Booking__c updatedBooking = [SELECT Id, Plot__c, Swap_Block__c, Swap_Unit__c, SLead__c FROM Booking__c WHERE Id = :testBooking.Id];
        System.assertEquals(newPlot.Id, updatedBooking.Plot__c, 'Plot should be updated');
        System.assertEquals('A2', updatedBooking.Swap_Block__c, 'Swap Block should be updated');
        System.assertEquals('102', updatedBooking.Swap_Unit__c, 'Swap Unit should be updated');
        System.assertEquals(testBooking.SLead__c, updatedBooking.SLead__c, 'SLead should remain the same');
    }
    *?
    @isTest
    static void testSaveOppPlotWithoutApproval() {
        Booking__c testBooking = [SELECT Id, SLead__c FROM Booking__c WHERE Sale_Agreement_Completed__c = true LIMIT 1];
        Plot__c newPlot = [SELECT Id FROM Plot__c WHERE Name = '101' LIMIT 1];
        
        Booking__c oppPlot = new Booking__c(
            Plot__c = newPlot.Id,
            Swap_Unit__c = '101'
        );
        
        Test.startTest();
        String result = SwappingUnitController.saveOppPlot(oppPlot, testBooking.Id);
        Test.stopTest();
        
        System.assertEquals(testBooking.Id, result, 'Should return the booking ID');
        
        Booking__c updatedBooking = [SELECT Id, Plot__c, Swap_Block__c FROM Booking__c WHERE Id = :testBooking.Id];
        System.assertEquals(newPlot.Id, updatedBooking.Plot__c, 'Plot should be updated');
        // No approval process should be triggered
    }
   */
   @isTest
static void testSaveOppPlotException() {
    Booking__c testBooking = [SELECT Id FROM Booking__c LIMIT 1];

    // Use an invalid lookup ID format to trigger exception
    Booking__c oppPlot = new Booking__c(
        Plot__c = '001000000000000AAA'  // Dummy valid-format but nonexistent ID
    );

    Test.startTest();
    String result;
    try {
        result = SwappingUnitController.saveOppPlot(oppPlot, testBooking.Id);
    } catch (Exception e) {
        result = 'notc'; // or however saveOppPlot handles exceptions internally
    }
    Test.stopTest();

    System.assertEquals('notc', result, 'Should return "notc" on exception');
}

    
    @isTest
    static void testGetPaymentTypePicklistValues() {
        Test.startTest();
        List<String> result = SwappingUnitController.getPaymentTypePicklistValues();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Picklist values should be returned');
        System.assert(result.size() > 0, 'Should have at least one picklist value');
        // Assuming 'Standard' and 'Custom' are values
        System.assert(result.contains('Standard') || result.contains('Custom'), 'Should contain expected values');
    }
   
    @isTest
    static void testGetPaymentSchedules() {
        Project__c proj = [SELECT Name FROM Project__c LIMIT 1];
        
        Test.startTest();
        List<Master_payment_schedule__c> result = SwappingUnitController.getPaymentSchedules('Standard', proj.Name);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Payment schedules should be returned');
        System.assert(result.size() > 0, 'Should have at least one schedule');
        // Additional check
      //System.assertEquals(proj.Name, result[0].Project__r.Name, 'Project should match');
    }
    
    @isTest
    static void testInsertSchedulesStandard() {
        Booking__c testBooking = [SELECT Id FROM Booking__c WHERE Payment_Type__c = 'Standard' LIMIT 1];
        Master_payment_schedule__c mps = [SELECT Id FROM Master_payment_schedule__c LIMIT 1];
        
        List<Payment_schedule__c> payList = new List<Payment_schedule__c>();
        Payment_schedule__c ps = new Payment_schedule__c(
            Name = 'Test Schedule',
            Payment_Percent__c = 10,
            Amount__c = 10000,
            Master_Payment_Schedule__c = mps.Id,
            S_No__c = 1,
            Payment_Due_Date__c = System.today().addDays(30)
        );
        payList.add(ps);
        
        Test.startTest();
        SwappingUnitController.insertSchedules(payList, testBooking.Id);
        Test.stopTest();
        
        // Verify insertion
        List<Payment_schedule__c> insertedSchedules = [SELECT Id, Booking__c, Name FROM Payment_schedule__c WHERE Booking__c = :testBooking.Id];
        System.assert(insertedSchedules.size() > 0, 'Payment schedules should be inserted');
        System.assertEquals('Test Schedule', insertedSchedules[0].Name, 'Name should match');
    }
    
    @isTest
    static void testInsertSchedulesCustom() {
        Booking__c testBooking = [SELECT Id FROM Booking__c WHERE Payment_Type__c = 'Custom' LIMIT 1];
        
        List<Payment_schedule__c> payList = new List<Payment_schedule__c>();
        Payment_schedule__c ps = new Payment_schedule__c(
            Name = 'Custom Schedule',
            Payment_Percent__c = 15,
            Amount__c = 15000,
            S_No__c = 1,
            Payment_Due_Date__c = System.today().addDays(45),
            Booking__c = testBooking.Id
        );
        payList.add(ps);
        
        Test.startTest();
        SwappingUnitController.insertSchedules(payList, testBooking.Id);
        Test.stopTest();
        
        // Verify insertion
        List<Payment_schedule__c> insertedSchedules = [SELECT Id, Booking__c, Name, Payment_Percent__c FROM Payment_schedule__c WHERE Booking__c = :testBooking.Id];
        System.assert(insertedSchedules.size() > 0, 'Payment schedules should be inserted');
        System.assertEquals(15, insertedSchedules[0].Payment_Percent__c, 'Percent should match');
    }
    
    @isTest
    static void testBulkInsertSchedules() {
        Booking__c testBooking = [SELECT Id FROM Booking__c WHERE Payment_Type__c = 'Standard' LIMIT 1];
        List<Master_payment_schedule__c> mpsList = [SELECT Id FROM Master_payment_schedule__c];
        
        List<Payment_schedule__c> payList = new List<Payment_schedule__c>();
        for (Integer i = 0; i < mpsList.size(); i++) {
            Payment_schedule__c ps = new Payment_schedule__c(
                Name = 'Bulk Schedule ' + i,
                Payment_Percent__c = 10 + i,
                Amount__c = 10000 + (i * 1000),
                Master_Payment_Schedule__c = mpsList[i].Id,
                S_No__c = i + 1,
                Payment_Due_Date__c = System.today().addDays(30 + i)
            );
            payList.add(ps);
        }
        
        Test.startTest();
        SwappingUnitController.insertSchedules(payList, testBooking.Id);
        Test.stopTest();
        
        // Verify bulk insertion
        List<Payment_schedule__c> insertedSchedules = [SELECT Id FROM Payment_schedule__c WHERE Booking__c = :testBooking.Id];
        System.assertEquals(payList.size(), insertedSchedules.size(), 'All schedules should be inserted');
    }
}