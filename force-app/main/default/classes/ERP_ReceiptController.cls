public class ERP_ReceiptController {
    public Id receiptId {get; set;}
    public Receipt__c receipt {get; set;}
    public String dateFormatted {get; set;} 
    public String amountInWords {get; set;} 
    
    public ERP_ReceiptController(ApexPages.StandardController stdcontroller){
        receiptId = stdcontroller.getId();
        receipt= [Select Id, Name,Receipt_date__c, Check_Transaction_Nmber__c,Payment_Received_Bank__c,Total_Received_Amount__c,Amount_By_Customer__c,Booking__r.Flat_Number__c, Booking__r.Plot__r.Name, Booking__r.salutation_Applicant1__c, Booking__r.First_Applicant_Name__c,Booking__r.Plot__r.Super_built_up_area__c, Booking__r.Project1__r.Name,Booking__r.Plot__r.Plot_Number__c
                  From Receipt__c 
                  Where Id =: receiptId];
        //formatting todays date
       dateFormatted = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)).format('dd-MMM-yyyy');
        
        // converting amount to words
        NumberTOWordConvertion c = new NumberTOWordConvertion();
        
        if(receipt.Amount_By_Customer__c!= null){
        amountInWords = c.getNumberTOWordConvertion(receipt.Amount_By_Customer__c);
            }
        
        
    }
    
    @future(callout=true)
    public static void sendReceiptEmailsFromTrigger(List<Id> receiptIds) {
        // Query receipts and booking emails
        List<Receipt__c> receipts = [SELECT Id,Name,Booking__r.First_Applicant_Name__c,Booking__r.Email1__c,Booking__r.Alternate_Email1__c FROM Receipt__c WHERE Id IN :receiptIds];
     
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Receipt__c> receiptsToUpdate = new List<Receipt__c>();

        for (Receipt__c receipt : receipts) {
            // Collect valid emails
            List<String> toEmails = new List<String>();

            if (!String.isBlank(receipt.Booking__r.Email1__c)) {
                toEmails.add(receipt.Booking__r.Email1__c);
            }
            if (!String.isBlank(receipt.Booking__r.Alternate_Email1__c)) {
                toEmails.add(receipt.Booking__r.Alternate_Email1__c);
            }

            if (toEmails.isEmpty()) {
                System.debug('Skipping receipt ' + receipt.Id + ' — no email addresses found.');
                continue;
            }

            try {
                // Generate PDF from VF page
                PageReference pdfPage = Page.ERP_Receipt;
                pdfPage.getParameters().put('id', receipt.Id);
                Blob pdfBlob = !Test.isRunningTest() ? pdfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                String body = 'Dear ' + receipt.Booking__r.First_Applicant_Name__c + ',<br/><br/>' +
                    'Thank you for your payment. Please find the attached receipt for your reference and records.<br/><br/>' +
                    'We truly appreciate your continued cooperation. Every step forward brings us closer to handing over a home that meets your expectations and brings lasting satisfaction.<br/><br/>' +
                    'If you have any questions regarding this payment or require further assistance, please don’t hesitate to reach out. Our team is always here to support you.<br/><br/>' +
                    'Thank you once again for your trust. We look forward to serving you every step of the way.<br/><br/>' +
                    'Warm regards,<br/>' +
                    '<strong>Team Jain Housing</strong>';

                // Setup email
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toEmails);
                email.setSubject('Payment Receipt – Thank You');
                email.setHtmlBody(body);

                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Receipt.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

                emailsToSend.add(email);

                // Flag as sent
                receiptsToUpdate.add(new Receipt__c(Id = receipt.Id, Email_Sent__c = true));
            } catch (Exception e) {
                System.debug('Failed to send receipt for ' + receipt.Id + ': ' + e.getMessage());
            }
        }

        // Send all emails in bulk
        if (!emailsToSend.isEmpty()) {
            
            Messaging.sendEmail(emailsToSend);
            
        }

        // Update sent flag
        if (!receiptsToUpdate.isEmpty()) {
            update receiptsToUpdate;
        }
    }


}