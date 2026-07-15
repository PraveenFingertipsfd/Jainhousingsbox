public class AdditionalChargeReceiptsController {
    
    @AuraEnabled
    public static Additional_Charge_Receipt__c getACRecieptRecord(Id recordId){
        return [SELECT Id,Project_Company__c FROM Additional_Charge_Receipt__c WHERE Id = :recordId Limit 1];
    }
    
    @AuraEnabled
    public static void RaiseManualACReciept(List<Id> recordIds) {
        if (recordIds != null && !recordIds.isEmpty()) {
            try {
                sendBulkReceiptEmails(recordIds);
            } catch (Exception e) {
                System.debug('Error in RaiseManualACDemand: ' + e.getMessage());
                throw new AuraHandledException('An error occurred while processing the demand emails: ' + e.getMessage());
            }
        } else {
            throw new AuraHandledException('No record IDs provided for raising demand.');
        }
    }
    
    @InvocableMethod
    public static void sendBulkReceiptEmails(List<Id> receiptIds) {
        
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'CRM_User_Group' LIMIT 1].Id;
        
        List<GroupMember> groupMembers = [
            SELECT UserOrGroupId 
            FROM GroupMember 
            WHERE GroupId = :groupId
        ];
        
        List<String> ccCRMAddresses = new List<String>();
        
        // Add group members' emails to the CC list
        for (GroupMember gm : groupMembers) {
            User u = [SELECT Email FROM User WHERE Id = :gm.UserOrGroupId];
            if (u.Email != null) {
                ccCRMAddresses.add(u.Email);
            }
        }
        ccCRMAddresses.add('Crmlead@mahendrahomes.com');
        
        // Query required fields from Additional_Charge_Receipt__c
        List<Additional_Charge_Receipt__c> receipts = [
            SELECT Amount_Received__c, Transaction_Id__c, Receipt_Date__c, Payment_Method__c, 
            Payer_Bank_Details__c, Bank_Name__c, Remarks__c, Additional_Charges__c, 
            Booking__r.salutation_Applicant1__c, Booking__r.First_Applicant_Name__c,
            Booking__r.Second_Applicant_Name__c, Booking__r.salutation_Applicant2__c,
            Booking__r.Project1__r.Name, Booking__r.Project_Company__c,
            Booking__r.Email1__c, Booking__r.Email2__c,Booking__r.Project__c,
            Booking__r.Owner.Email, Booking__r.CRM_Manager__r.Email,CreatedBy.Email,
            (SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks)
            FROM Additional_Charge_Receipt__c
            WHERE Id IN :receiptIds
        ];
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Iterate over records and construct email content
        for (Additional_Charge_Receipt__c receipt : receipts) {
            
            List<String> lstCCEmail = new List<String>();
            List<String> sendTo = new List<String>();
            
            sendTo.add(receipt.Booking__r.Email1__c);
            if (receipt.Booking__r.Email2__c != null) {
                sendTo.add(receipt.Booking__r.Email2__c);
            }
            
            // Include CRM Manager email in CC
            lstCCEmail.add(receipt.Booking__r.Owner.Email);
            if (receipt.Booking__r.CRM_Manager__r != null && 
                receipt.Booking__r.CRM_Manager__r.Email != null) {
                    lstCCEmail.add(receipt.Booking__r.CRM_Manager__r.Email);
                }
            
            String applicantNames = '';
            if (receipt.Booking__r.salutation_Applicant1__c != null && 
                receipt.Booking__r.First_Applicant_Name__c != null) {
                    applicantNames = receipt.Booking__r.salutation_Applicant1__c + ' ' + receipt.Booking__r.First_Applicant_Name__c;
                }
            
            String secondApplicantName = '';
            if (receipt.Booking__r.Second_Applicant_Name__c != null && 
                receipt.Booking__r.Second_Applicant_Name__c.trim() != '') {
                    secondApplicantName = receipt.Booking__r.salutation_Applicant2__c + ' ' + receipt.Booking__r.Second_Applicant_Name__c;
                }
            
            if (!String.isEmpty(secondApplicantName)) {
                applicantNames += ' and ' + secondApplicantName;
            }
            
            String projectName = receipt.Booking__r.Project1__r.Name != null 
                ? receipt.Booking__r.Project1__r.Name 
                : '';
            
            String receiptEmailContent = '<div style="color: black;"><strong>Dear ' + applicantNames + ',</strong></div><br/>' +
                '<div><strong>Greetings from Mahendra Homes!!!</strong><br/><br/>' +
                'We are pleased to confirm receipt of your payment.<br/>' +
                'Thank you for your prompt payment. If you have any further questions, please feel free to contact us.<br/><br/>' +
                'Best regards,<br/>';
            
            if (receipt.Booking__r.Project_Company__c == 'MAHENDRA HOMES PVT LTD') {
                receiptEmailContent += '<strong>Mahendra Homes Pvt Ltd</strong></div>';
            } else if (receipt.Booking__r.Project_Company__c == 'MAHENDRA ARTO LLP') {
                receiptEmailContent += '<strong>Mahendra Arto LLP</strong></div>';
            }
            
            List<String> combinedCCAddresses = new List<String>();
            combinedCCAddresses.addAll(ccCRMAddresses);
            combinedCCAddresses.addAll(lstCCEmail);
            
            List<String> validCCEmails = GenerateDocumnetController.validateEmails(combinedCCAddresses);
            
            PageReference vfPage;
            if (receipt.Booking__r.Project__c == 'Aarya') {
                vfPage = Page.RECEIPT_AC_AARYA;
            } else if (receipt.Booking__r.Project__c == 'Arto Helix') {
                vfPage = Page.RECEIPT_AC_HELIX;
            }
            
            vfPage.getParameters().put('id', receipt.Id);
            Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(sendTo);
            if (!validCCEmails.isEmpty()) {
                email.setCcAddresses(validCCEmails);
            }
            list<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            for (ContentDocumentLink link : receipt.ContentDocumentLinks) {
                ContentVersion version = [SELECT Title, FileExtension, VersionData 
                                          FROM ContentVersion 
                                          WHERE ContentDocumentId = :link.ContentDocumentId 
                                          ORDER BY CreatedDate DESC LIMIT 1];
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(version.Title + '.' + version.FileExtension);
                attachment.setBody(version.VersionData);
                attachments.add(attachment);
            }
            
            Messaging.EmailFileAttachment attachmentDoc = new Messaging.EmailFileAttachment();
            attachmentDoc.setFileName('Additional Charge Receipt.pdf');
            attachmentDoc.setBody(pdfBlob);
            attachments.add(attachmentDoc);
            
            if (!attachments.isEmpty()) {
                email.setFileAttachments(attachments);
            }
            if(!Test.isRunningTest()){
                String CreatedEmail = receipt.CreatedBy.Email;
                list<OrgWideEmailAddress> orgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :CreatedEmail LIMIT 1];
                if (orgWideEmail.size() > 0) {
                    email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
                }
            }
            email.setSubject('Payment Receipt Confirmation for ' + projectName);
            email.setHtmlBody(receiptEmailContent);
            email.setSaveAsActivity(true);
            email.setWhatId(receipt.Id);
            
            emails.add(email);
        }
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    public static void sendNotificationsFromAdditionalChangeReciept(String title, List<Additional_Charge_Receipt__c> adChargeRec) {
        
        for (Additional_Charge_Receipt__c adc : adChargeRec) {
            String body = '';
            Set<String> userIds = new Set<String>();
            userIds.add(adc.CreatedById);
            if(title == 'Additional Charge Receipt Approved'){
                body = 'This is to notify that Booking ' + adc.Booking_Name__c + 
                    ', The additional charge receipt ' + adc.Name + ' is Approved by the Finance Team';
            }
            if(title == 'Additional Charge Receipt Rejected'){
                body = 'This is to notify that Booking ' + adc.Booking_Name__c + 
                    ', The additional charge receipt ' + adc.Name + ' is Rejected by the Finance Team';
            }
            ReceiptController.sendCustomNotification(userIds, title, body, adc.Id, 'Receipt_Notification');
        }
    }
}