public class SendSaleAgreementEmailQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> bookingIds;

    public SendSaleAgreementEmailQueueable(List<Id> bookingIds) {
        this.bookingIds = bookingIds;
    }

    public void execute(QueueableContext context) {
        // Query all required fields in one go
        List<Booking__c> bookings = [SELECT Id, Name, First_Applicant_Name__c, Email1__c, Alternate_Email1__c,Project1__r.Name
            						FROM Booking__c WHERE Id IN :bookingIds];

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        for (Booking__c booking : bookings) {
            // Determine the VF page based on project
            PageReference vfPage;
            if (booking.Project1__r.Name == 'Jains Anushree') {
                vfPage = Page.AnushreeAgreementForSale;
            } else if (booking.Project1__r.Name == 'Arto Helix') {
                vfPage = Page.SALE_AGREEMENT_HELIX;
            } else {
                continue; // skip if no page is defined
            }

            vfPage.getParameters().put('id', booking.Id);

            // Generate PDF
            Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('test');

            // Build recipients list (both Email1 and Alternate_Email1__c)
            List<String> toAddresses = new List<String>();
            if (String.isNotBlank(booking.Email1__c)) {
                toAddresses.add(booking.Email1__c);
            }
            if (String.isNotBlank(booking.Alternate_Email1__c)) {
                toAddresses.add(booking.Alternate_Email1__c);
            }

            if (!toAddresses.isEmpty()) {
                // Build email body
                String htmlBody = 
                    'Dear Customer,<br/><br/>' +
                    'Good day to you!<br/><br/>' +
                    'Please find attached the draft of the Agreement for Sale for your review. We kindly request you to go through the document carefully and verify the accuracy of the <strong>Name</strong>, <strong>Age</strong>,<strong>PAN</strong>, <strong>Aadhaar</strong>, and other personal <strong>KYC</strong> details of both the applicant and co-applicant, as mentioned.<br/><br/>' +
                    'We request you to sign the agreement within <strong>3 days</strong> from the date of this email. You may choose one of the following options:<br/>' +
                    '<ul>' +
                    '<li>Visit our office and sign the agreement in person, by coordinating with your Customer Relationship Executive</li>' +
                    '<li>Alternatively, we will be happy to arrange for one of our representatives to visit you and get the agreement signed at your preferred location (based on the proximity and availability of the representative)</li>' +
                    '</ul>' +
                    'If you have any questions or need further clarification, please do not hesitate to contact your Customer Relationship Executive.<br/><br/>' +
                    'We look forward to your prompt response and continued cooperation.<br/><br/>' +
                    'Warm regards,<br/>' +
                    '<strong>Customer Relations Team</strong><br/>' +
                    '<strong>Jain Housing</strong>';

                // Create email message
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(toAddresses);
                mail.setSubject('Draft Sale Agreement – Jain Housing');
                mail.setHTMLBody(htmlBody);

                // Add PDF attachment
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('SaleAgreement.pdf');
                attachment.setBody(pdfBlob);
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

                mails.add(mail);
            }
        }

        // Send all emails in one call (governor-safe)
        if (!mails.isEmpty()) {
            Messaging.sendEmail(mails, false);
        }
    }
}