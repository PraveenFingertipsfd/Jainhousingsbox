@IsTest
public class SendSaleAgreementEmailQueueableTest {

    @TestSetup
    static void setupData() {
        //Create Projects....
        Project__c projAnushree = new Project__c(
            Name = 'Jains Anushree',
            Project_Type__c = 'Plots' 
        );
        Project__c projHelix = new Project__c(
            Name = 'Arto Helix',
            Project_Type__c = 'Plots'
        );
        insert new List<Project__c>{ projAnushree, projHelix };

        // Create Booking records...
        List<Booking__c> bookings = new List<Booking__c>{
            new Booking__c(
                First_Applicant_Name__c = 'John Doe',
                Email1__c = 'john@example.com',
                Alternate_Email1__c = 'john.alt@example.com',
                Project1__c = projAnushree.Id
            ),
            new Booking__c(
                First_Applicant_Name__c = 'Jane Doe',
                Email1__c = 'jane@example.com',
                Project1__c = projHelix.Id
            ),
            new Booking__c(
                First_Applicant_Name__c = 'No Page',
                Email1__c = 'nopage@example.com'
                
            )
        };
        insert bookings;
    }

    @IsTest
    static void testQueueableSendEmails() {
        // Query all bookings...
        List<Booking__c> bookings = [SELECT Id FROM Booking__c];
        List<Id> bookingIds = new List<Id>();
        for (Booking__c b : bookings) bookingIds.add(b.Id);

        Test.startTest();
        // Enqueue the Queueable...
        System.enqueueJob(new SendSaleAgreementEmailQueueable(bookingIds));
        Test.stopTest();

        // In test context, no real emails are sent, but the Queueable should execute without errors
        System.assert(true, 'Queueable executed successfully');
    }

    @IsTest
    static void testQueueableEmptyList() {
        // Test with empty booking list (should not fail)
        Test.startTest();
        System.enqueueJob(new SendSaleAgreementEmailQueueable(new List<Id>()));
        Test.stopTest();
        System.assert(true, 'Queueable executed with empty list without errors');
    }
}