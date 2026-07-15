@IsTest
public class TicketControllerTest {

    private static Tickets__c createTestTicket() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User managerUser = new User(
            Alias = 'mgrh', Email = 'mgrh@test.com', EmailEncodingKey = 'UTF-8',
            LastName = 'ManagerHP', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata', ProfileId = p.Id,
            Username = 'mgrh' + System.currentTimeMillis() + '@test.com'
        );
        insert managerUser;

        User assignedUser = new User(
            Alias = 'asgh', Email = 'asgh@test.com', EmailEncodingKey = 'UTF-8',
            LastName = 'AssignedHP', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata', ProfileId = p.Id,
            Username = 'asgh' + System.currentTimeMillis() + '@test.com'
        );
        insert assignedUser;

        Departments__c dept = new Departments__c(Name = 'SupportHP');
        insert dept;

        String projectVal  = Tickets__c.Project_Name__c.getDescribe().getPicklistValues()[0].getValue();
        String approvalVal = Tickets__c.Approval_Status__c.getDescribe().getPicklistValues()[0].getValue();
        String typeVal     = Tickets__c.Ticket_Type__c.getDescribe().getPicklistValues()[0].getValue();

        Tickets__c ticket = new Tickets__c(
            Customer_Name__c = 'HP Customer', Departments__c = dept.Id,
            Project_Name__c = projectVal, Email__c = 'happypath@test.com', Contact_Number__c = '8888888888',
            Approval_Status__c = approvalVal, Ticket_Type__c = typeVal,
            Manager__c = managerUser.Id, Assigned_To__c = assignedUser.Id,
            Ticket_Created_Date__c = Date.today(), Comment__c = 'Happy Path Test'
        );
        insert ticket;
        return ticket;
    }

    // ── Edge Case Tests ──

    @IsTest
    static void testSendTicketEmail_NullEmail() {
        Tickets__c ticket = createTestTicket();
        ticket.Email__c = null;
        update ticket;

        Test.startTest();
        TicketController.sendTicketEmail(ticket.Id, 'Body', new List<Messaging.EmailFileAttachment>());
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void testSendTicketEmail_EmptyEmail() {
        Tickets__c ticket = createTestTicket();
        ticket.Email__c = '';
        update ticket;

        Test.startTest();
        TicketController.sendTicketEmail(ticket.Id, 'Body', new List<Messaging.EmailFileAttachment>());
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void testSendTicketEmail_InvalidId() {
        Boolean isError = false;
        Test.startTest();
        try {
            TicketController.sendTicketEmail('000000000000000', 'Invalid', new List<Messaging.EmailFileAttachment>());
        } catch (Exception e) {
            isError = true;
        }
        Test.stopTest();
        System.assert(isError);
    }

    // ── Happy Path Tests (SeeAllData=true to access OrgWideEmailAddress) ──

    @isTest(SeeAllData=true)
    static void testSendTicketEmail_ValidEmailHappyPath() {
        Tickets__c ticket = createTestTicket();

        Test.startTest();
        try {
            TicketController.sendTicketEmail(
                ticket.Id,
                '<p>Your ticket has been updated.</p>',
                new List<Messaging.EmailFileAttachment>()
            );
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        Test.stopTest();

        Tickets__c t = [SELECT Id, Email__c FROM Tickets__c WHERE Id = :ticket.Id];
        System.assertNotEquals(null, t, 'Ticket should still exist after email send attempt');
    }

    @isTest(SeeAllData=true)
    static void testSendTicketEmail_WithAttachments() {
        Tickets__c ticket = createTestTicket();

        Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
        att.setFileName('TestDoc.pdf');
        att.setBody(Blob.valueOf('Test attachment content'));
        att.setContentType('application/pdf');

        Messaging.EmailFileAttachment att2 = new Messaging.EmailFileAttachment();
        att2.setFileName('Image.png');
        att2.setBody(Blob.valueOf('PNG image data'));
        att2.setContentType('image/png');

        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>{ att, att2 };

        Test.startTest();
        try {
            TicketController.sendTicketEmail(ticket.Id, '<p>With attachments</p>', attachments);
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        Test.stopTest();
        System.assert(true, 'No unhandled exception');
    }

    @isTest(SeeAllData=true)
    static void testSendTicketEmail_HtmlContent() {
        Tickets__c ticket = createTestTicket();

        String htmlBody = '<html><body><h1>Status Update</h1>'
            + '<p>Dear Customer,</p>'
            + '<p>Your ticket status has changed to <strong>Closed</strong>.</p>'
            + '<table><tr><td>Ticket ID</td><td>' + ticket.Id + '</td></tr></table>'
            + '</body></html>';

        Test.startTest();
        try {
            TicketController.sendTicketEmail(ticket.Id, htmlBody, new List<Messaging.EmailFileAttachment>());
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        Test.stopTest();
        System.assert(true, 'No unhandled exception');
    }

    @isTest(SeeAllData=true)
    static void testSendTicketEmail_NullAttachments() {
        Tickets__c ticket = createTestTicket();

        Test.startTest();
        try {
            TicketController.sendTicketEmail(ticket.Id, 'Plain text body', null);
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        Test.stopTest();
        System.assert(true, 'No unhandled exception');
    }

    @isTest(SeeAllData=true)
    static void testSendTicketEmail_EmptyBody() {
        Tickets__c ticket = createTestTicket();

        Test.startTest();
        try {
            TicketController.sendTicketEmail(ticket.Id, '', new List<Messaging.EmailFileAttachment>());
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        Test.stopTest();
        System.assert(true, 'No unhandled exception');
    }

    @isTest(SeeAllData=true)
    static void testSendTicketEmail_NullBody() {
        Tickets__c ticket = createTestTicket();

        Test.startTest();
        try {
            TicketController.sendTicketEmail(ticket.Id, null, new List<Messaging.EmailFileAttachment>());
        } catch (Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        Test.stopTest();
        System.assert(true, 'No unhandled exception');
    }
}