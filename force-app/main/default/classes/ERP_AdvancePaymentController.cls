public class ERP_AdvancePaymentController {
    public Id recId {get; set;}
      public String dateFormatted {get; set;}
    public String amountInWords {get; set;}
    public  Advance_Payment__c advancePayment {get; set;}

    public ERP_AdvancePaymentController(ApexPages.StandardController stdcontroller){
        recId = stdcontroller.getId();
        advancePayment = [select Id, Name, Mode_of_Payment__c,Cheque_no_Transaction_Number__c,Receipt_Date__c, Bank__c,Amount__c, Booking_Request__r.Unit__r.Name,Booking_Request__r.Unit__r.Plot_Number__c,Booking_Request__r.Unit__r.Super_built_up_area__c,Booking_Request__r.Customer_Name__c,Booking_Request__r.Project__c
                          From
                          Advance_Payment__c
                          Where Id=: recId
                         ];
         //formatting todays date
       dateFormatted = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)).format('dd-MMM-yyyy');

        // converting amount to words
        NumberTOWordConvertion c = new NumberTOWordConvertion();

        if(advancePayment.Amount__c!= null){
        amountInWords = c.getNumberTOWordConvertion(advancePayment.Amount__c);
            }

    }

    @future(callout=true)
    public static void sendAdvancePaymentReceiptEmailsFromTrigger(List<Id> advancePaymentIds) {
        // Query advance payments and associated booking request emails
        List<Advance_Payment__c> advancePayments = [SELECT Id, Name, Amount__c,Booking_Request__r.Customer_Name__c,Booking_Request__r.Email__c
            										FROM Advance_Payment__c WHERE Id IN :advancePaymentIds];

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Advance_Payment__c> paymentsToUpdate = new List<Advance_Payment__c>();

        for (Advance_Payment__c ap : advancePayments) {
            // Collect valid emails
            List<String> toEmails = new List<String>();

            if (!String.isBlank(ap.Booking_Request__r.Email__c)) {
                toEmails.add(ap.Booking_Request__r.Email__c);
            }

            if (toEmails.isEmpty()) {
                System.debug('Skipping Advance Payment ' + ap.Id + ' — no email addresses found.');
                continue;
            }

            try {
                // Generate PDF from VF page
                PageReference pdfPage = Page.ERP_AdvancePayment;
                pdfPage.getParameters().put('id', ap.Id);
                Blob pdfBlob = !Test.isRunningTest() ? pdfPage.getContentAsPDF() : Blob.valueOf('testblob');


                // Email body
                String body = 'Dear ' + ap.Booking_Request__r.Customer_Name__c + ',<br/><br/>' +
                    'Thank you for your payment. Please find the attached receipt for your reference and records.<br/><br/>' +
                    'We truly appreciate your continued cooperation. Every step forward brings us closer to handing over a home that meets your expectations and brings lasting satisfaction.<br/><br/>' +
                    'If you have any questions regarding this payment or require further assistance, please don\'t hesitate to reach out. Our team is always here to support you.<br/><br/>' +
                    'Thank you once again for your trust. We look forward to serving you every step of the way.<br/><br/>' +
                    'Warm regards,<br/>' +
                    '<strong>Team Jain Housing</strong>';

                // Setup email
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toEmails);
                email.setSubject('Payment Receipt - Thank You');
                email.setHtmlBody(body);

                // Attach PDF
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Receipt.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

                emailsToSend.add(email);

                // Optionally flag as email sent (if you have a field for it)
                paymentsToUpdate.add(new Advance_Payment__c(Id = ap.Id, Email_Sent__c = true));
            } catch (Exception e) {
                System.debug('Failed to send advance payment receipt for ' + ap.Id + ': ' + e.getMessage());
            }
        }

        // Send all emails in bulk
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }

        // Optionally update flag if you have it
        if (!paymentsToUpdate.isEmpty()) {
            update paymentsToUpdate;
        }
    }

}