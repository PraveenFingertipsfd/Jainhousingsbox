@isTest
public class convertValueToWordsTest {

    @testSetup
    static void setupData() {
        Booking__c booking = new Booking__c(
            Sanctioned_Amount__c = 20000
        );
        insert booking;

        Receipt__c receipt = new Receipt__c(
            Booking__c = booking.Id,
            Check_Transaction_Nmber__c = 'CHK1234',
            Receipt_date__c = Date.today()
        );
        insert receipt;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c = booking.Id,
            S_No__c = 1,
            Payment_Percent__c = 25,
            //AmountB__c = 30000,
            Amount__c = 30000
        );
        insert ps;
    }

    @isTest
    static void testConstructorWithData() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(b);
        ApexPages.currentPage().getParameters().put('id', b.Id);

        Test.startTest();
        convertValueToWords ctrl = new convertValueToWords(stdCtrl);
        Test.stopTest();

        System.assertNotEquals(null, ctrl.loanAmountInWords, 'loanAmountInWords should not be null');
        System.assert(ctrl.payList.size() > 0, 'Payment list should have records');
        System.assert(ctrl.recpList.size() > 0, 'Receipt list should have records');
        System.assertNotEquals(null, ctrl.TotalCostAmountInWords, 'Word conversion should not be null');
    }

    @isTest
    static void testConstructorWithoutSanctionedAmount() {
        Booking__c b = new Booking__c();
        insert b;

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(b);
        ApexPages.currentPage().getParameters().put('id', b.Id);

        Test.startTest();
        convertValueToWords ctrl = new convertValueToWords(stdCtrl);
        Test.stopTest();

        System.assertNotEquals(null, ctrl.totalPendingWords, 'Pending words should not be null');
        System.assertNotEquals(null, ctrl.tillDateReceived, 'Till date received words should not be null');
    }

    @isTest
    static void testEmptyListsScenario() {
        Booking__c b = new Booking__c();
        insert b;

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(b);
        ApexPages.currentPage().getParameters().put('id', b.Id);

        Test.startTest();
        convertValueToWords ctrl = new convertValueToWords(stdCtrl);
        Test.stopTest();

        System.assertEquals(0, ctrl.recpList.size(), 'Empty receipt list handled correctly');
        System.assertEquals(0, ctrl.payList.size(), 'Empty payment list handled correctly');
    }
}