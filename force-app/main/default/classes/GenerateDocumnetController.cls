public without sharing class GenerateDocumnetController {
    @AuraEnabled
    public static Booking__c getBookingRecord(Id recordId) {
        Booking__c booking = [SELECT Id,Project_Company__c, Project__c,Project1__r.Name, Agreement_Cost__c,Bank__c, Total_received_Amount__c,First_Applicant_Name__c,salutation_Applicant1__c, salutation_Applicant2__c, 
                              Second_Applicant_Name__c
                              FROM Booking__c 
                              WHERE Id = :recordId 
                              LIMIT 1];
        //if (booking.Agreement_Cost__c <= booking.Total_received_Amount__c) {
        //system.debug(booking.Name);
        return booking;
        //} else {
        //return null;
        //}
    }
    
    
    @AuraEnabled
    public static Booking__c getBookingDetailsform(String bookingId) {
        // Query the booking record with the Project field
        return [SELECT Id, Name, Project__c FROM Booking__c WHERE Id = :bookingId limit 1];
    }
    
    @AuraEnabled
    public static Booking__c getBookingRecordViaReciept(Id recordId) {
        Receipt__c receipt = [SELECT Id, Booking__c FROM Receipt__c WHERE id = :recordId LIMIT 1];
        Booking__c booking = [SELECT Id,Project_Company__c, Project__c,Project1__r.Name, Agreement_Cost__c,Bank__c, Total_received_Amount__c,First_Applicant_Name__c
                              FROM Booking__c 
                              WHERE Id = :receipt.Booking__c 
                              LIMIT 1];
        //if (booking.Agreement_Cost__c <= booking.Total_received_Amount__c) {
        //system.debug(booking.Name);
        return booking;
        //} else {
        //return null;
        //}
    }
    @AuraEnabled
    public static String sendEmailGenerateReceipt(Id receiptId) {
        String returnMessage;
        try {
            // Retrieve the Receipt record
            Receipt__c receipt = [SELECT Id, Booking__c, CreatedBy.Email FROM Receipt__c WHERE Id = :receiptId LIMIT 1];
            
            if (receipt == null || receipt.Booking__c == null) {
                return 'Receipt or associated Booking record not found.';
            }
            
            // Retrieve the related Booking record
            Booking__c booking = [SELECT Id, Email1__c,Project__c, Alternate_Email1__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :receipt.Booking__c LIMIT 1];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                List<String> lstCCEmail = new List<String>();
                
                // Retrieve co-applicants associated with the Booking
                List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c,Alternate_Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
                    
                PageReference receiptPage;
                //if(booking.Project__c == 'Aarya')
                receiptPage = Page.ERP_Receipt;
                // else if(booking.Project__c == 'Arto Helix'){
                //  receiptPage = Page.RECEIPT_HELIX;
                //}
                // Generate the PDF for the receipt
                receiptPage.getParameters().put('id', receiptId);
                Blob pdfBlob = !Test.isRunningTest() ? receiptPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Alternate_Email1__c != null) {
                    sendTo.add(booking.Alternate_Email1__c);
                }
                
                // Include Co-Applicant emails
                for (Co_Applicant__c ca : coApps) {
                    if (ca.Email__c != null) {
                        sendTo.add(ca.Email__c);
                    }
                    if(ca.Alternate_Email__c != null){
                        sendTo.add(ca.Alternate_Email__c);
                    }
                }

                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }

                String body = 'Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>' +
                    'Thank you for your payment. Please find the attached receipt for your reference and records.<br/><br/>' +
                    'We truly appreciate your continued cooperation. Every step forward brings us closer to handing over a home that meets your expectations and brings lasting satisfaction.<br/><br/>' +
                    'If you have any questions regarding this payment or require further assistance, please don’t hesitate to reach out. Our team is always here to support you.<br/><br/>' +
                    'Thank you once again for your trust. We look forward to serving you every step of the way.<br/><br/>' +
                    'Warm regards,<br/>' +
                    '<strong>Team Jain Housing</strong>';
                email.setToAddresses(sendTo);
                email.setSubject('Payment Receipt – Thank You');
                email.setHtmlBody(body);
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Receipt.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                
                email.setSaveAsActivity(true);
                email.setWhatId(receipt.Id);
                
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
     
    @AuraEnabled
    public static String sendEmailGenerateAdvancePaymentReceipt(Id receiptId) {
        String returnMessage;
        try {
            // Retrieve the Advance Payment record with necessary fields
            Advance_Payment__c advancePayment = [SELECT Id,Booking_Request__c,Booking_Request__r.Email__c,Booking_Request__r.Customer_Name__c
                								FROM Advance_Payment__c WHERE Id = :receiptId LIMIT 1];
    
            if (advancePayment == null || advancePayment.Booking_Request__c == null) {
                return 'Advance Payment or associated Booking Request not found.';
            }

            // Set the receipt page (PDF Visualforce page)
            PageReference receiptPage = Page.ERP_AdvancePayment;
            receiptPage.getParameters().put('id', receiptId);
            Blob pdfBlob = !Test.isRunningTest() ? receiptPage.getContentAsPDF() : Blob.valueOf('testblob');
            
            // Prepare email message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            // Set To address
            List<String> sendTo = new List<String>();
            sendTo.add(advancePayment.Booking_Request__r.Email__c);    
            
            String htmlbody = 'Dear ' + advancePayment.Booking_Request__r.Customer_Name__c + ',<br/><br/>' +
                    'Thank you for your payment. Please find the attached receipt for your reference and records.<br/><br/>' +
                    'We truly appreciate your continued cooperation. Every step forward brings us closer to handing over a home that meets your expectations and brings lasting satisfaction.<br/><br/>' +
                    'If you have any questions regarding this payment or require further assistance, please don’t hesitate to reach out. Our team is always here to support you.<br/><br/>' +
                    'Thank you once again for your trust. We look forward to serving you every step of the way.<br/><br/>' +
                    'Warm regards,<br/>' +
                    '<strong>Team Jain Housing</strong>';
            
            // Set email subject and body
            email.setToAddresses(sendTo);
            email.setSubject('Payment Receipt – Thank You');
            email.setHtmlBody(htmlbody);
            
            // Add PDF attachment
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Receipt.pdf');
            attachment.setBody(pdfBlob);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            
            email.setSaveAsActivity(true);
            email.setWhatId(advancePayment.Id);
            
            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            returnMessage = 'Email sent successfully';
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        
        return returnMessage;
    }
        
    @AuraEnabled
    public static String sendEmailGenerateConsent(Id recId) {
        String returnMessage;
        try {
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id,Project__c, Email1__c, Email2__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve co-applicants associated with the Booking
            List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the CONSENT LETTER
                PageReference vfPage;
                if(booking.Project__c == 'Aarya')
                    vfPage = Page.CONSENT_LETTER_AARYA;
                else if(booking.Project__c == 'Arto Helix'){
                    vfPage = Page.CONSENT_LETTER_ARTO_HELIX;
                }
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = receiptPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                // Include Co-Applicant emails
                if (coApps.size() > 0) {
                    for (Co_Applicant__c ca : coApps) {
                        if (ca.Email__c != null) {
                            sendTo.add(ca.Email__c);
                        }
                    }
                }
                
                // Set Org-Wide Email Address
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }
                lstCCEmail.add('Crmlead@mahendrahomes.com');
                if (lstCCEmail.size() > 0) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('Consent Letter');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached consent letter for your Booking.<br/><br/>Thank you.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('ConsentLetter.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    
    
    //added by karthik 13/06
    private static Boolean isInApprovalProcess(String recordId) {
        List<ProcessInstance> instances = [SELECT Id, Status FROM ProcessInstance WHERE TargetObjectId = :recordId AND Status = 'Pending'];                                     
        return !instances.isEmpty();
    }
    
    @AuraEnabled 
    public static String submitForApproval(String recordId) {
        try {
            // Check if already in approval process
            if (isInApprovalProcess(recordId)) {
                return 'This record is already in the approval process';
            }
            
            // Submit for approval
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitting NDC for approval');
            req.setProcessDefinitionNameOrId('NDC_Approval_Process');
            req.setObjectId(recordId);
            req.setSubmitterId(userInfo.getUserId());
            Approval.ProcessResult result = Approval.process(req);
            
            /* Update status to Pending
update new Booking__c(
Id = recordId,
NDC_Approval_Status__c = 'Pending'
);*/
            
            return 'SUCCESS';
        } catch (Exception e) {
            return e.getMessage();
        }
    }
    
    @AuraEnabled
    public static Boolean getApprovalStatus(String recordId) {
        try {
            Boolean isDisabled = false;
            Booking__c booking = [SELECT Id, NDC_Approval_Status__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
            if(booking.NDC_Approval_Status__c == 'Submitted for approval' || booking.NDC_Approval_Status__c == 'Approved'){
                isDisabled = true;
            }
            return isDisabled;
        } catch (Exception e) {
            return false;
        }
    }
    
    @future(callout=true)
    public static void sendApprovalEmailsFuture(List<Id> recordIds) {
        /*for (Id recordId : recordIds) {
            sendEmailGenerateNDC(recordId);
        }*/
        for (Id recordId : recordIds) {
            sendEmailNDCAndPossession(recordId,'');
        }
        
    }
    
    @AuraEnabled 
    public static String sendEmailGenerateNDC(Id recId){
        String returnMessage;
        try {
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id,Project__c, Email1__c, Email2__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            //List<String> lstCCEmail = new List<String>();
            
            // Retrieve Org Wide Email Address
            //List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            // Generate the comment link
            String baseUrl = 'https://jainhousing--sbox1.sandbox.my.salesforce-sites.com/NDC';
            String commentLink = baseUrl + '/ndcCustomerResponse?id=' + booking.Id;
            
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the Cost Sheet
                PageReference vfPage;
                vfPage = Page.NDC;
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = vfPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');   
                
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                
                /*Set Org-Wide Email Address
if (owea.size() > 0) {
email.setOrgWideEmailAddressId(owea[0].Id);
}*/
                String body = 'Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>' +
                    'Please find the attached NDC for your Booking.<br/><br/>' +
                    'To submit your comment, please <a href="' + commentLink + '">click here</a>.<br/><br/>' +
                    'Thank you.';
                email.setToAddresses(sendTo);
                email.setSubject('No Due Certificate');
                email.setHtmlBody(body);
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('No Due Certificate.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    
    @AuraEnabled
    public static String sendEmailGeneratePossessionLetter(Id recId){
        String returnMessage;
        try {
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id,Project__c, Email1__c, Email2__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve Org Wide Email Address
            List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the Cost Sheet
                PageReference vfPage;
                vfPage = Page.NDC;
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = vfPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');   
                
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                
                
                // Set Org-Wide Email Address
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
                
                // Include CC addresses
                // lstCCEmail.add(booking.Owner.Email);
                // if (booking.CRM_Manager__c != null) {
                //    lstCCEmail.add(booking.CRM_Manager__r.Email);
                // }
                // lstCCEmail.add('Crmlead@mahendrahomes.com');
                //if (lstCCEmail.size() > 0) {
                //    email.setCcAddresses(lstCCEmail);
                // }
                
                email.setToAddresses(sendTo);
                email.setSubject('NDC');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached NDC for your Booking.<br/><br/>Thank you.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('NDC.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    
    @AuraEnabled
    public static String sendEmailGenerateCostSheet(Id recId) {
        String returnMessage;
        try {
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id,Project__c, Email1__c, Email2__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve co-applicants associated with the Booking
            List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the Cost Sheet
                PageReference vfPage;
                if(booking.Project__c == 'Aarya')
                    vfPage = Page.COST_SHEET_AARYA;
                else if(booking.Project__c == 'Arto Helix'){
                    vfPage = Page.COST_SHEET_HELIX;
                }
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = vfPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                // Include Co-Applicant emails
                if (coApps.size() > 0) {
                    for (Co_Applicant__c ca : coApps) {
                        if (ca.Email__c != null) {
                            sendTo.add(ca.Email__c);
                        }
                    }
                }
                
                // Set Org-Wide Email Address
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }
                lstCCEmail.add('Crmlead@mahendrahomes.com');
                if (lstCCEmail.size() > 0) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('Cost Sheet');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached Cost Sheet for your Booking.<br/><br/>Thank you.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('CostSheet.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    
    @AuraEnabled
    public static String sendEmailGenerateSA1(Id recId) {
        String returnMessage;
        try {
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id,Email1__c,Second_Applicant_Name__c,Plot__r.Name,salutation_Applicant2__c,salutation_Applicant1__c,Block__r.Name,Project1__r.Name, Email2__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve co-applicants associated with the Booking
            List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            //List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the Sale Agreement
                PageReference vfPage;
                if(booking.Project1__r.Name == 'Jains Anushree')
                    vfPage = Page.AnushreeAgreementForSale;
                else if(booking.Project1__r.Name == 'Arto Helix'){
                    vfPage = Page.SALE_AGREEMENT_HELIX;
                }
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = vfPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                // Include Co-Applicant emails
                if (coApps.size() > 0) {
                    for (Co_Applicant__c ca : coApps) {
                        if (ca.Email__c != null) {
                            sendTo.add(ca.Email__c);
                        }
                    }
                }
                
                /* Set Org-Wide Email Address
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }*/
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }
                //lstCCEmail.add('Crmlead@mahendrahomes.com');
                if (lstCCEmail.size() > 0) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                //Call For Agreement - Mahendra Aarya. Adhatrao Mohan, Aarya B 810)
                //
                String applicantNames = 'Call For Agreement - ';
                String projectShort = '';
                if (booking.Project1__r.Name != null) {
                    
                    //applicantNames += booking.Project1__r.Name + '. ';
                    if(booking.Project1__r.Name == 'Jains Anushree'){
                        projectShort += 'Jains Anushree';
                    }
                    if(booking.Project1__r.Name == 'MAHENDRA AARYA'){
                        projectShort += 'Aarya';
                    }
                }
                /*
                if (booking.First_Applicant_Name__c != null) {
                    if (booking.salutation_Applicant1__c != null) {
                        applicantNames +=booking.salutation_Applicant1__c + '. ';
                    }
                    applicantNames += booking.First_Applicant_Name__c + ' ';
                }
                if (booking.Second_Applicant_Name__c != null) {
                    applicantNames += '& ';
                    if (booking.salutation_Applicant2__c != null) {
                        applicantNames += booking.salutation_Applicant2__c + '. ';
                    }
                    applicantNames += booking.Second_Applicant_Name__c + ',';
                }*/
                /*
                if(booking.Block__r.Name != null){
                    projectShort += ' '+booking.Block__r.Name;
                }*/
                if(booking.Plot__r.Name != null){
                    projectShort += ' Unit '+booking.Plot__r.Name;
                }
                
                String projectDetails = applicantNames +' '+ projectShort;
                
                
                // Set the subject line
                email.setSubject(projectDetails);
                
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached Sale Agreement for your Booking.<br/><br/>Thank you.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('SaleAgreement.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    
    @AuraEnabled
    public static String sendEmailGenerateSA(Id recId) {
        String returnMessage;
        try {
            Booking__c booking = [SELECT Id, Email1__c, Second_Applicant_Name__c, Plot__r.Name, salutation_Applicant2__c, salutation_Applicant1__c,
                                  Block__r.Name, Project1__r.Name,Alternate_Email1__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                PageReference vfPage;
                if (booking.Project1__r.Name == 'Jains Anushree')
                    vfPage = Page.AnushreeAgreementForSale;
                else if (booking.Project1__r.Name == 'Arto Helix')
                    vfPage = Page.SALE_AGREEMENT_HELIX;
                
                vfPage.getParameters().put('id', recId);
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>{ booking.Email1__c };
                    if (booking.Alternate_Email1__c != null) sendTo.add(booking.Alternate_Email1__c);
                
                for (Co_Applicant__c ca : coApps) {
                    if (ca.Email__c != null) {
                        sendTo.add(ca.Email__c);
                    }
                }
                
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }
                if (!lstCCEmail.isEmpty()) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                
                // Subject Line
                String subjectText = 'Draft Sale Agreement – Jain Housing';
                /*if (booking.Project1__r.Name != null) {
                    subjectText += booking.Project1__r.Name;
                }
                if (booking.Plot__r.Name != null) {
                    subjectText += ' Unit ' + booking.Plot__r.Name;
                }*/
                email.setSubject(subjectText);
                
                // HTML Body
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
                
                email.setHtmlBody(htmlBody);
                
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('SaleAgreement.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }

    
    @AuraEnabled
    public static String sendEmailGenerateAAR(Id recId) {
        String returnMessage;
        try {
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id,Project__c, Email1__c, Email2__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve co-applicants associated with the Booking
            List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the Agreement Amount Request
                PageReference vfPage;
                if(booking.Project__c == 'Aarya')
                    vfPage = Page.AGREEMENT_AMOUNT_REQUEST_AARYA;
                else if(booking.Project__c == 'Arto Helix'){
                    vfPage = Page.AGREEMENT_AMOUNT_REQUEST_HELIX;
                }
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = vfPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                // Include Co-Applicant emails
                if (coApps.size() > 0) {
                    for (Co_Applicant__c ca : coApps) {
                        if (ca.Email__c != null) {
                            sendTo.add(ca.Email__c);
                        }
                    }
                }
                
                // Set Org-Wide Email Address
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }
                lstCCEmail.add('Crmlead@mahendrahomes.com');
                if (lstCCEmail.size() > 0) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('Agreement Amount Request');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached Agreement Amount request for your Booking.<br/><br/>Thank you.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('AgreementAmountRequest.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);                
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    @AuraEnabled
    public static String sendEmailGenerateCarParking(Id recId) {
        String returnMessage;
        try {
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id,Project__c, Email1__c, Email2__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve co-applicants associated with the Booking
            List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the car parking allotment
                PageReference vfPage = Page.CAR_PARKING;
                
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = vfPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                // Include Co-Applicant emails
                if (coApps.size() > 0) {
                    for (Co_Applicant__c ca : coApps) {
                        if (ca.Email__c != null) {
                            sendTo.add(ca.Email__c);
                        }
                    }
                }
                
                // Set Org-Wide Email Address
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }
                lstCCEmail.add('Crmlead@mahendrahomes.com');
                if (lstCCEmail.size() > 0) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('Car Parking Allotment');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached car parking allotment letter for your Booking.<br/><br/>Thank you.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('CarParking.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    @AuraEnabled
    public static String sendEmailGeneratePC(Id recId) {
        String returnMessage;
        try {
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id, Project__c, Email1__c, Email2__c,Possession_Send_Date__c,Possession_send__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve co-applicants associated with the Booking
            List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the Possession Letter
                PageReference vfPage = Page.POSSESSION_LETTER;
                
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = vfPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                // Include Co-Applicant emails
                if (coApps.size() > 0) {
                    for (Co_Applicant__c ca : coApps) {
                        if (ca.Email__c != null) {
                            sendTo.add(ca.Email__c);
                        }
                    }
                }
                
                // Set Org-Wide Email Address
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }
                lstCCEmail.add('Crmlead@mahendrahomes.com');
                if (lstCCEmail.size() > 0) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('Possession Letter');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached Possession Letter for your flat.<br/><br/>Thank you.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('PossessionLetter.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                // Update the Booking record
                booking.Possession_send__c = true;
                booking.Possession_Send_Date__c = Datetime.now();
                update booking;
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    @AuraEnabled
    public static String sendEmailGenerateAdditionalCharges(Id recId) {
        String returnMessage;
        try {
            
            Additional_Charges__c Additional_Charges = [SELECT Id, Booking__c FROM Additional_Charges__c WHERE Id = :recId LIMIT 1];
            
            if (Additional_Charges == null || Additional_Charges.Booking__c == null) {
                return 'Additional Charges or associated Booking record not found.';
            }
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id, Project__c, Email1__c, Email2__c,Possession_Send_Date__c,Possession_send__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :Additional_Charges.Booking__c LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve co-applicants associated with the Booking
            List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the Additional Charges
                PageReference vfPage = Page.AdditionalCharges;
                
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = vfPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                // Include Co-Applicant emails
                if (coApps.size() > 0) {
                    for (Co_Applicant__c ca : coApps) {
                        if (ca.Email__c != null) {
                            sendTo.add(ca.Email__c);
                        }
                    }
                }
                
                // Set Org-Wide Email Address
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }
                lstCCEmail.add('Crmlead@mahendrahomes.com');
                if (lstCCEmail.size() > 0) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('Additional Charges');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached receipt for the Additional_Charges. If you have any questions, feel free to contact us..<br/><br/>Thank you.<br/><br/>Mahendra Builders Pvt. Ltd.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('AdditionalCharges.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);              
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    
    public static void sendJointInspectionEmail(List<id> Ids){
        
    }
    
    
    
    
    
    
    
    @AuraEnabled
    public static String sendEmailGenerateNOC(Id recId) {
        String returnMessage;
        try {
            
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id, Project__c, Email1__c,Bank__c, Email2__c,Possession_Send_Date__c,Possession_send__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve co-applicants associated with the Booking
            List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the Additional Charges
                PageReference vfPage;
                
                if(booking.Bank__c == 'SBI')
                    vfPage = Page.SBI_BUILDER_NOC;
                else if(booking.Bank__c == 'HDFC'){
                    vfPage = Page.HDFC_NOC;
                }
                
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = vfPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                // Include Co-Applicant emails
                if (coApps.size() > 0) {
                    for (Co_Applicant__c ca : coApps) {
                        if (ca.Email__c != null) {
                            sendTo.add(ca.Email__c);
                        }
                    }
                }
                
                // Set Org-Wide Email Address
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }
                lstCCEmail.add('Crmlead@mahendrahomes.com');
                if (lstCCEmail.size() > 0) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('NOC Document');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached NOC Document for your booking. If you have any questions, feel free to contact us..<br/><br/>Thank you.<br/><br/>Mahendra Builders Pvt. Ltd.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('NOC_Document.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    @AuraEnabled
    public static String sendEmailGenerateTPA(Id recId) {
        String returnMessage;
        try {
            
            // Retrieve the Booking record
            Booking__c booking = [SELECT Id, Project__c, Email1__c,Bank__c, Email2__c,Possession_Send_Date__c,Possession_send__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, CRM_Manager__c, CRM_Manager__r.Email 
                                  FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve co-applicants associated with the Booking
            List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (booking != null && !String.isBlank(booking.Email1__c)) {
                // Generate the PDF for the Additional Charges
                PageReference vfPage;
                
                if(booking.Bank__c == 'SBI')
                    vfPage = Page.SBI_TPA;
                else if(booking.Bank__c == 'HDFC'){
                    vfPage = Page.TPA_NOC;
                }
                
                vfPage.getParameters().put('id', recId);
                //Blob pdfBlob = vfPage.getContentAsPDF();
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email1__c);
                if (booking.Email1__c != null) {
                    sendTo.add(booking.Email1__c);
                }
                if (booking.Email2__c != null) {
                    sendTo.add(booking.Email2__c);
                }
                // Include Co-Applicant emails
                if (coApps.size() > 0) {
                    for (Co_Applicant__c ca : coApps) {
                        if (ca.Email__c != null) {
                            sendTo.add(ca.Email__c);
                        }
                    }
                }
                
                // Set Org-Wide Email Address
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (booking.CRM_Manager__c != null) {
                    lstCCEmail.add(booking.CRM_Manager__r.Email);
                }
                lstCCEmail.add('Crmlead@mahendrahomes.com');
                if (lstCCEmail.size() > 0) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('TPA Document');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached TPA Document for your booking. If you have any questions, feel free to contact us..<br/><br/>Thank you.<br/><br/>Mahendra Builders Pvt. Ltd.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('TPA_Document.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    
    @InvocableMethod
    public static void sendEmailGenerateDemand(List<Id> recIds) {
        try {
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            // Fetch the Demand_Raised__c records for the given recIds
            List<Demand_Raised__c> demandRecords = [
                SELECT Id, Demand_Email_Content__c,Current_Milestone__c,Project__c,CreatedBy.Email, Demand_Content_Ids__c,Booking__r.Block__r.Name, Booking__r.Email1__c, Booking__r.Email2__c, 
                Booking__r.Owner.Email, Booking__r.CRM_Manager__r.Email, Booking__r.Project__c,Booking__r.Total__c, 
                (SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks WHERE LinkedEntityId IN :recIds)
                FROM Demand_Raised__c 
                WHERE Id IN :recIds
            ];
            
            if (demandRecords.isEmpty()) {
                throw new AuraHandledException('No Demand Raised records found for the given IDs.');
            }
            
            Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'CRM_User_Group' LIMIT 1].Id;
            
            List<GroupMember> groupMembers = [
                SELECT UserOrGroupId 
                FROM GroupMember 
                WHERE GroupId = :groupId
            ];
            
            List<String> ccAddresses = new List<String>();
            
            // Iterate over group members and add their emails to the CC list
            for (GroupMember gm : groupMembers) {
                User u = [SELECT Email FROM User WHERE Id = :gm.UserOrGroupId];
                if (u.Email != null) {
                    ccAddresses.add(u.Email);
                }
            }
            
            
            for (Demand_Raised__c demand : demandRecords) {
                // Convert comma-separated string of content IDs to Set<Id>
                List<String> contentDocumentIds = new List<String>();
                if (!String.isBlank(demand.Demand_Content_Ids__c)) {
                    contentDocumentIds.addAll(demand.Demand_Content_Ids__c.split(','));
                }
                
                List<String> lstCCEmail = new List<String>();
                Booking__c booking = demand.Booking__r;

                if (booking == null || String.isBlank(booking.Email1__c)) {
                    throw new AuraHandledException('Cannot send demand letter: Booking has no email address (Email1). Please update the Booking record.');
                }
                if (booking != null && !String.isBlank(booking.Email1__c)) {
                    // Generate the PDF for the Agreement Amount Request
                    PageReference vfPage;
                    if (booking.Project__c == 'Aarya') {
                        vfPage = Page.DEMAND_LETTER_SEND_AARYA;
                    } else if (booking.Project__c == 'Arto Helix') {
                        vfPage = Page.DEMAND_LETTER_SEND_HELIX;
                    } else {
                        vfPage = Page.DEMAND_LETTER_SEND_AARYA;
                    }
                    vfPage.getParameters().put('id', demand.Id);
                    Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                    
                    // Prepare email details
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    List<String> sendTo = new List<String>();
                    sendTo.add(booking.Email1__c);
                    if (booking.Email2__c != null) {
                        sendTo.add(booking.Email2__c);
                    }
                    
                    // Include CRM Manager email in CC
                    lstCCEmail.add(booking.Owner.Email);
                    if (booking.CRM_Manager__r != null && booking.CRM_Manager__r.Email != null) {
                        //lstCCEmail.add(booking.CRM_Manager__r.Email);
                    }
                    //lstCCEmail.add('Crmlead@mahendrahomes.com');
                    
                    List<String> validccEmails = new List<String>();
                    List<String> combinedCCAddresses = new List<String>();
                    //combinedCCAddresses.addAll(ccAddresses);
                    combinedCCAddresses.addAll(lstCCEmail);
                    validccEmails = validateEmails(combinedCCAddresses);
                    
                    
                    if (!validccEmails.isEmpty()) {
                        email.setCcAddresses(validccEmails);
                    }
                    email.setToAddresses(sendTo);
                    email.setSubject('Demand Note for Completion of '+demand.Current_Milestone__c +' In '+demand.Project__c+' '+demand.Booking__r.Block__r.Name);
                    email.setHtmlBody(demand.Demand_Email_Content__c);
                    
                    // Retrieve Content Versions for attachments
                    List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                    if (!contentDocumentIds.isEmpty()) {
                        List<ContentVersion> contentVersions = [
                            SELECT Title, FileExtension, VersionData 
                            FROM ContentVersion 
                            WHERE ContentDocumentId IN :contentDocumentIds
                        ];
                        
                        for (ContentVersion cv : contentVersions) {
                            Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                            contentAttach.setFileName(cv.Title + '.' + cv.FileExtension);
                            contentAttach.setBody(cv.VersionData);
                            emailAttachments.add(contentAttach);
                        }
                    }
                    
                    // Attach the Demand PDF
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName('Demand.pdf');
                    attachment.setBody(pdfBlob);
                    emailAttachments.add(attachment);
                    
                    if (!emailAttachments.isEmpty()) {
                        email.setFileAttachments(emailAttachments);
                    }
                    if(!Test.isRunningTest()){
                        String CreatedEmail = demand.CreatedBy.Email;
                        list<OrgWideEmailAddress> orgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :CreatedEmail LIMIT 1];
                        if (orgWideEmail.size() > 0) {
                            email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
                        }
                    }
                    email.setSaveAsActivity(true);
                    email.setWhatId(demand.Id);
                    // Send the email
                    emails.add(email);
                } 
                if (!emails.isEmpty()) {
                    Messaging.sendEmail(emails);
                }
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            throw e;
        }
    }
    public static List<String> validateEmails(List<String> emailAddresses) {
        List<String> validEmails = new List<String>();
        for (String email : emailAddresses) {
            if (email != null && Pattern.matches('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$', email)) {
                validEmails.add(email);
            }
        }
        return validEmails;
    }   
    
    @AuraEnabled
    public static String sendEmailNDCAndPossession(Id recordId, String emailBody) {
        try {
            Booking__c booking = [SELECT Id, Email1__c,Alternate_Email1__c, First_Applicant_Name__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
            
            if(String.isBlank(booking.Email1__c)) {
                return 'Customer email not available';
            }
            
            if(emailBody == ''){
                emailBody = '<p>Dear <strong>' + booking.First_Applicant_Name__c + '</strong>,</p><br/>' +
                    '<p>Greetings from Jain Housing!</p>' +
                    '<p>We are delighted to inform you that all formalities and payments for your flat have been successfully completed. ' +
                    'As part of the final handover process, please find the following documents attached for your records:</p>' +
                    '<strong><ul><li>No Due Certificate</li><li>Possession Letter</li></ul></strong>' +
                    '<p>On behalf of the entire team at Jain Housing, I would like to thank you sincerely for placing your trust in us. ' +
                    'We wish you and your loved ones a joyful, peaceful, and prosperous life in your new home. ' +
                    'May it bring you happiness and wonderful memories for years to come.</p>' +
                    '<p>Should you need any further assistance, please feel free to reach out to us at any time—we’re always here to help.</p><br/>' +
                    '<p>Warm regards,<br/>Customer Relationship Manager<br/><strong>Jain Housing</strong></p>';
            }
            
            // Generate PDFs
            PageReference ndcPage = Page.NDC;
            ndcPage.getParameters().put('id', recordId);
            Blob ndcPdf = !Test.isRunningTest() ? ndcPage.getContentAsPDF() : Blob.valueOf('testblob');
            
            PageReference possPage = Page.PossessionLetter;
            possPage.getParameters().put('id', recordId);
            Blob possPdf = !Test.isRunningTest() ? possPage.getContentAsPDF() : Blob.valueOf('testblob');
            
            // Email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{booking.Email1__c,booking.Alternate_Email1__c});
            mail.setSubject('NDC and Possession Letter - Jain Housing');
            mail.setHtmlBody(emailBody);
            
            // Attachments
            Messaging.EmailFileAttachment attach1 = new Messaging.EmailFileAttachment();
            attach1.setFileName('NoDueCertificate.pdf');
            attach1.setBody(ndcPdf);
            
            Messaging.EmailFileAttachment attach2 = new Messaging.EmailFileAttachment();
            attach2.setFileName('PossessionLetter.pdf');
            attach2.setBody(possPdf);
            
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {attach1, attach2});
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
            
            return 'SUCCESS';
        } catch(Exception e) {
            return e.getMessage();
        }
    }
    
    //cancellation agreement mail added by karthik 30-07
    @future(callout=true)
    public static void sendCancellationEmailsFuture(Set<Id> bookingIds) {
        List<Booking__c> bookings = [SELECT Id, Name, Email1__c,Alternate_Email1__c, Owner.Email, Owner.Name FROM Booking__c WHERE Id IN :bookingIds];
        for (Booking__c booking : bookings) {
            if (String.isNotBlank(booking.Email1__c)) {
                sendCancellationEmailWithPDF(booking);
            }
        }
    }
    
    private static void sendCancellationEmailWithPDF(Booking__c booking) {
        try {
            // Collect all email addresses (avoid nulls/duplicates)
            Set<String> emailAddresses = new Set<String>();
            if (String.isNotBlank(booking.Email1__c)) {
                emailAddresses.add(booking.Email1__c);
            }
            if (String.isNotBlank(booking.Alternate_Email1__c)) {
                emailAddresses.add(booking.Alternate_Email1__c);
            }

            // If no email addresses, skip
            if (emailAddresses.isEmpty()) {
                return;
            }

            // Generate PDF from VF page
            PageReference pdfPage = Page.CancellationAgreementAnusree; 
            pdfPage.getParameters().put('id', booking.Id);
            Blob pdfBlob = !Test.isRunningTest() ? pdfPage.getContentAsPDF() : Blob.valueOf('testblob');

            // Create email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>(emailAddresses));
            mail.setSubject('Booking Cancellation Agreement');
            mail.setPlainTextBody(
                'Dear Customer, \n\n' +
                'Your booking has been cancelled. Please find the attached Cancellation Agreement.\n\nRegards,\nTeam'
            );

            // Attach PDF
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setFileName('Cancellation_Agreement.pdf');
            attach.setBody(pdfBlob);
            attach.setContentType('application/pdf');

            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });

            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        } catch (Exception ex) {
            System.debug('Error sending cancellation email: ' + ex.getMessage());
        }
    }

}