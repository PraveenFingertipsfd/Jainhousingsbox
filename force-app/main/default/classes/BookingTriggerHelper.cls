public class BookingTriggerHelper {
    
    public static void recallApproval(Id recordId) {
        List<ProcessInstanceWorkitem> workItems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :recordId LIMIT 1];

        if (!workItems.isEmpty()) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setAction('Removed');
            req.setWorkitemId(workItems[0].Id);
            Approval.process(req);
        }
    }
    
    public static void sendAgreementApprovalEmailToCustomer(List<Booking__c> bookings) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        
        
        for (Booking__c booking : bookings) {
            if (String.isNotBlank(booking.Email1__c)) {
                
                String htmlBody = '<!DOCTYPE html><html><body style="font-family:Arial,sans-serif;">' +
                '<p>Dear ' + booking.First_Applicant_Name__c  + ',</p>' +
                '<p>Sale Agreement has been attached please go through it to check if everything is correct.</p>' +
                '<p>Best regards,<br/>Jain Housing Team</p>' +
                '</body></html>';
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { booking.Email1__c });
                mail.setSubject('Draft Sale Agreement – Jain Housing');
                mail.setHTMLBody(htmlBody);
                //mail.setPlainTextBody('Dear Customer, your sale agreement for booking ' + booking.Name + ' has been attached below, Go through it if any changes to be done contact us.');
                mails.add(mail);
            }
        }
        
        if (!mails.isEmpty()) {
            Messaging.sendEmail(mails, false);
        }
    }
    
    public static void sendRegReminderEmails(List<Booking__c> bookings) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Booking__c b : bookings) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { b.Email1__c });
            mail.setSubject('Registration Preparation');
            mail.setPlainTextBody('Dear Customer,\n\nPlease be ready for the Registration process.\n\nThank you,\nTeam');
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }
}