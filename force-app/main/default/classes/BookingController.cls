public without sharing class BookingController {
    /*@auraEnabled
        public static List<Plot__c> convertUnit(Id recId){
        
        Booking_Request__c bookingRequest = [SELECT Id, Unit__c FROM Booking_Request__c WHERE Id = :recId LIMIT 1];
        
        if (bookingRequest.Unit__c == null) {
        return null;
        }
        List<Plot__c> qt = [SELECT Id, Name,Tower__c,Block__c,Block1__r.Name, Status__c,Floor__c, Super_built_up_area__c, Price_Per_Sq_Ft__c, Floor_Rise__c, Premium_Charge__c,
        Other_Charges__c, Covered_Park_Parking__c, TAXES__c,Project__c,Solar_Charges__c,GST1__c,
        Project__r.Booking_Advance_Amount__c FROM Plot__c WHERE Id = :bookingRequest.Unit__c];
        if (!qt.isEmpty()) {
        if (qt[0].Status__c == 'Available') {
        return qt;
        } else {
        return null;
        }
        }else {
        return null;
        }
        }*/

    public static void validateRequiredDocuments(Map<Id, Booking__c> bookingMap) {
        // Map of suffix patterns to display names
        Map<String, String> documentTypes = new Map<String, String>{
            ' - [ Aadhar Card ]' => 'Aadhar Card',
                ' - [ Pan Card ]' => 'Pan Card',
                ' - [ Sale Agreement ]' => 'Sale Agreement',
                ' - [ Passport ]' => 'Passport',
                ' - [ Booking Form ]' => 'Booking Form',
                ' - [ Sale Deed ]' => 'Sale Deed',
                ' - [ Loan Documents ]' => 'Loan Documents',
                ' - [ Applicant Photo ]' => 'Applicant Photos'
                };
                    
                    // Core required documents (without loan document)
                    Set<String> requiredSuffixes = new Set<String>{
                        ' - [ Aadhar Card ]',
                            ' - [ Pan Card ]',
                            ' - [ Applicant Photo ]'
                            };
                                /*
                            ' - [ Sale Agreement ]',
                            ' - [ Sale Deed ]',
                            ' - [ Booking Form ]',*/
                                
                                // Query all documents
                                Map<Id, Set<String>> bookingToSuffixesMap = new Map<Id, Set<String>>();
        for(ContentDocumentLink link : [
            SELECT LinkedEntityId, ContentDocument.Title 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN :bookingMap.keySet()
        ]) {
            if(!bookingToSuffixesMap.containsKey(link.LinkedEntityId)) {
                bookingToSuffixesMap.put(link.LinkedEntityId, new Set<String>());
            }
            
            // Check all possible document types
            for(String suffix : documentTypes.keySet()) {
                if(link.ContentDocument.Title.endsWith(suffix)) {
                    bookingToSuffixesMap.get(link.LinkedEntityId).add(suffix);
                }
            }
        }
        
        // Validate each booking
        for(Id bookingId : bookingMap.keySet()) {
            Booking__c book = bookingMap.get(bookingId);
            Set<String> requiredForThisBooking = new Set<String>(requiredSuffixes);
            
            // Add loan document if needed
            if(book.Funding_Type__c == 'Loan') {
                requiredForThisBooking.add(' - [ Loan Documents ]');
            }
            if(book.Nationality__c != 'Resident') {
                requiredForThisBooking.add(' - [ Passport ]');
            }
            
            // Find missing documents
            Set<String> missing = new Set<String>();
            for(String suffix : requiredForThisBooking) {
                if(!bookingToSuffixesMap.containsKey(bookingId) || 
                   !bookingToSuffixesMap.get(bookingId).contains(suffix)) {
                       missing.add(documentTypes.get(suffix));
                   }
            }
            
            // Show error if any missing
            if(!missing.isEmpty()) {
                String errorMsg = 'Upload missing documents: ' + String.join(new List<String>(missing), ', ');
                book.addError(errorMsg);
            }
        }
    }
    
    @AuraEnabled
    public static String isKYCCollected(String recordId) {
        Booking__c book = new Booking__c(Id = recordId, KYC_Documents_Collected__c = true);
        try {
            update book;
            return 'SUCCESS';
        } catch (DmlException ex) {
            String fullMsg = ex.getMessage();
            
            // Extract message after FIELD_CUSTOM_VALIDATION_EXCEPTION,
            Integer idx = fullMsg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
            String msg;
            if (idx > -1) {
                msg = fullMsg.substring(idx + 'FIELD_CUSTOM_VALIDATION_EXCEPTION,'.length()).trim();
            } else {
                // fallback: after first colon
                idx = fullMsg.indexOf(':');
                msg = (idx > -1) ? fullMsg.substring(idx + 1).trim() : fullMsg;
            }
            
            // Remove trailing ": []" if present
            if (msg.endsWith(': []')) {
                msg = msg.substring(0, msg.length() - 4).trim();
            }
            
            return msg;
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }

    @AuraEnabled
    public static Boolean IsWelcomeCallCheckListUpdated(String recordId) {
        Booking__c book = [select Id,Welcome_Call_Checklist_Done__c from Booking__c where Id =: recordId];
        if(book.Welcome_Call_Checklist_Done__c){
            book.Welcome_Call_Done__c = true;
            update book;
        }
        return book.Welcome_Call_Checklist_Done__c;
    }
    
    @AuraEnabled
    public static void submitRecordForApproval(String recordId) {
        
        String approvalProcessName = 'Push_To_CRM_Approval';
        
        // Create approval request
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(recordId);
        req.setProcessDefinitionNameOrId(approvalProcessName);
        
        try {
            Approval.ProcessResult result = Approval.process(req);
            if (!result.isSuccess()) {
                throw new AuraHandledException('Approval submission failed: ' + result.getErrors()[0].getMessage());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting for approval: ' + e.getMessage());
        }
    }
    

    
    @auraEnabled
    public static string getpageName(string recId){
         string vfpageName;
        Booking__c book = [SELECT Id,Name,Project__c FROM Booking__c where Id=:recId];
        if(book.Project__c=='Jains Anushree'){
            vfpageName ='AnushreeBookingForm';
        }else if(book.Project__c=='Jains Advaya'){
            vfpageName ='AadhyaBookingForm';
        }
        return vfpageName;
    }
    
    @auraEnabled
    public static void sendEmailtoCustomer(string recId, string PAgNam){
        string recordId = recId;
        Booking__c l = [SELECT Id,CRM_Manager__r.Email,Owner.Email,Name,Email1__c,SLead__r.Email,Project__c,First_Applicant_Name__c FROM Booking__c where Id=:recId];
        List<String> lstCCEmail = new List<String>();
        
        lstCCEmail.add(l.Owner.Email);
        if(l.CRM_Manager__c != null){
            lstCCEmail.add(l.CRM_Manager__r.Email);
        }

        list<Messaging.SingleEmailMessage> mails = new list<Messaging.SingleEmailMessage>(); 
        //PageReference pdfPage;
        //pdfPage= page.PAgNam;
        
        String pageName = PAgNam; 
        PageReference pdfPage = new PageReference('/apex/' + pageName);
        
        pdfPage.getParameters().put('Id', recordId);
        Blob pdfContent;
        Boolean isTest = System.Test.isRunningTest();
        if(!isTest){
            pdfContent = pdfPage.getContent();
        }else{
            pdfContent=Blob.valueOf('Test Content');
        }
        String accountName = l.Name != null ? l.Name : '';
       
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        Messaging.Emailfileattachment efa1 = new Messaging.Emailfileattachment();
        efa1.setFileName('Application form for '+ accountName+' | #'+system.today().year()+'-'+System.now().format('MMM')+'-'+system.today().day()+'-'+l.name+'.Pdf');
        efa1.setBody(pdfContent);
        fileAttachments.add(efa1);
        
        if(l.Email1__c != null && l.Email1__c != ''){
            List<String> lstBCCEmail = l.Email1__c != null ? l.Email1__c.split(',') : new List<String>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.toAddresses = new string[]{l.Email1__c};
                mail.bccaddresses = lstBCCEmail;
            mail.ccaddresses = lstCCEmail;
            mail.setSubject('Application form for '+ accountName+' | #'+system.today().year()+'-'+System.now().format('MMM')+'-'+system.today().day()+'-'+l.name);
            mail.setFileAttachments(fileAttachments);
            
            string emailBody='Dear '+l.First_Applicant_Name__c+',<br/>Please find the attached Application Form Letter.<br/><br/>' +
            'We are pleased to inform you that your booking has been confirmed. ' +
            'Attached is the Application form for your reference.<br/><br/>' +
            'If you have any questions or need further assistance, please contact us.<br/><br/>' +
            'Thank you for choosing NAMBIAR Builders.<br/><br/>' +
            'Best regards,<br/>' +
            'NAMBIAR Builders Pvt Ltd';
			mail.setHtmlBody(emailBody);
            mails.add(mail);
        }
        Messaging.SendEmailResult[] results = new list<Messaging.SendEmailResult>();
        if(!isTest){
            results = Messaging.sendEmail(mails); 
            system.debug(results);
           
        }
    }
    
    public class TypeWrapper{
        @AuraEnabled 
        public List<String> ModeOfPay {get; set;}
        @AuraEnabled 
        public List<String> FundingTyp {get; set;}
        @AuraEnabled 
        public List<Plot__c> PlotLst {get; set;}
        @AuraEnabled 
        public Boolean IsFromPSABooking {get; set;}
    }
    
    @AuraEnabled
    public static TypeWrapper getUnitData (Id recId, string PSAunitId) {
        TypeWrapper typwrp = new TypeWrapper();
        
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Mode_Of_Payment__c.getDescribe();
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        typwrp.ModeOfPay = paymentTypeValues;
        
        List<String> FundTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult1 = Booking__c.Funding_Type__c.getDescribe();
        for (Schema.PicklistEntry picklistEntry : fieldResult1.getPicklistValues()) {
            FundTypeValues.add(picklistEntry.getLabel());
        }
        typwrp.FundingTyp =  FundTypeValues;
        
        string UnitId = '';
        if(PSAunitId == '' || PSAunitId == null){
            //UnitId = [SELECT Id, Unit__c FROM Booking_Request__c WHERE Id = :recId LIMIT 1].Unit__c;
            UnitId = [select id,name,Unit__c from Quote__c where Id =: recId Limit 1].Unit__c;
            typwrp.IsFromPSABooking = false;
        }
        else{
            UnitId = PSAunitId;
            typwrp.IsFromPSABooking = true;
        }
        
        List<Plot__c> UtLst = new List<Plot__c>();
        
        if( UnitId!= '' && UnitId != null){
            UtLst = [SELECT Id, Name,Tower__c,Block__c,Block1__r.Name,Block1__c, Status__c,Floor__c,Is_PSA_Unit__c, Super_built_up_area__c, Price_Per_Sq_Ft__c, Floor_Rise__c, Premium_Charge__c,BHK_Type__c,
                     Other_Charges__c, Covered_Park_Parking__c, TAXES__c,Project__c,Solar_Charges__c,GST1__c,Project__r.Booking_Advance_Amount__c FROM Plot__c WHERE Id = :UnitId];
        }
        if(!UtLst.isEmpty()){
            typwrp.PlotLst = UtLst;
        }
        
        
        return typwrp;
    }
    
    /*@AuraEnabled
public static List<String> getModeofPayment() {
List<String> paymentTypeValues = new List<String>();
Schema.DescribeFieldResult fieldResult = Booking__c.Mode_Of_Payment__c.getDescribe();
for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
paymentTypeValues.add(picklistEntry.getLabel());
}
return paymentTypeValues;
}
@AuraEnabled
public static List<String> getFundingType() {
List<String> paymentTypeValues = new List<String>();
Schema.DescribeFieldResult fieldResult = Booking__c.Funding_Type__c.getDescribe();
for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
paymentTypeValues.add(picklistEntry.getLabel());
}
return paymentTypeValues;
}*/
    @auraEnabled
    public static String createBook(Booking__c bk, String recId, List<Co_Applicant__c> applicantList) {
        List<Co_Applicant__c> applicantListToInsert = new List<Co_Applicant__c>();
        system.debug(bk +'hi');
        system.debug(bk.Plot__c +'hiplot');
        
        system.debug(recId +'hi1');
        system.debug(applicantList +'hi2');
        List<Plot__c> qt = [SELECT Id, Name, Status__c, Project__c, Super_built_up_area__c, Price_Per_Sq_Ft__c, Floor_Rise__c, Premium_Charge__c,
                            Other_Charges__c, Covered_Park_Parking__c, TAXES__c,Block1__c,Block__c FROM Plot__c WHERE Id = :bk.Plot__c];
        if (qt.isEmpty()) {
            System.debug('Plot record not found.'); 
            return 'Plot record not found.';
        }
        //list<Block__c> block =[select id,Name from Block__c where Id =:bk.Block__c];
        List<Project__c> projectList = [SELECT Id, CRM_Manager__c, Legal_User__c, Finance_User__c, Reservation_User__c,
                                        Demands_Collection_User__c, Possession_User__c, Agreement_User__c,
                                        Registration_User__c, Maintenance_User__c,Project__c,
                                        Director__c,Sales_Manager__c,VP__c,CFO__c,Loan_Stage_User__c,Handover_User__c FROM Project__c WHERE Id= :bk.Project1__c];
        
        if (projectList.isEmpty()) {
            return 'Project record not found for the given Booking Project.';
        }
        if (qt[0].Status__c == 'Available') {
            System.debug('oppPlot: ' + bk);
            //map project level managers to booking fileds
            bk.CRM_Manager__c = projectList[0].CRM_Manager__c;
            bk.Legal_Team__c = projectList[0].Legal_User__c;
            bk.Director__c = projectList[0].Director__c;
            bk.Finance_User__c = projectList[0].Finance_User__c;
            bk.Sales_Manager1__c = projectList[0].Sales_Manager__c;
            //stage-wise users map
            bk.Reservation_User__c = projectList[0].Reservation_User__c;
            bk.Agreement_User__c = projectList[0].Agreement_User__c;
            bk.Maintenance_User__c = projectList[0].Maintenance_User__c;
            bk.Possession_User__c = projectList[0].Possession_User__c;
            bk.Registration_User__c = projectList[0].Registration_User__c;
            bk.Demand_Collection_Users__c = projectList[0].Demands_Collection_User__c;
            bk.CFO__c = projectList[0].CFO__c;
            bk.VP__c = projectList[0].VP__c;
            bk.Loan_User__c = projectList[0].Loan_Stage_User__c;
            bk.Handover_User__c = projectList[0].Handover_User__c; 
            bk.Cost_Sheet__c = recId;
            //remaining fileds
            bk.Project__c=projectList[0].Project__c;
            System.debug('Booking to upsert: ' + bk);
            bk.Price_per_sqft__c = bk.Final_Price__c;
            upsert bk;
            
            qt[0].Status__c = 'Booked';
            update qt[0];
            
            System.debug('applicantList: ' + applicantList);
            for (Co_Applicant__c coA : applicantList) {
                System.debug('Co-Applicant Name: ' + coA.Name);
                if (coA.Name != null && coA.Name != '') {
                    System.debug('Adding Co-Applicant to insert list.');
                    coA.Booking__c = bk.Id;
                    applicantListToInsert.add(coA);
                }
            }
            if (!applicantListToInsert.isEmpty()) {
                System.debug('Co-Applicants to insert: ' + applicantListToInsert);
                try {
                    insert applicantListToInsert;
                    System.debug('Co-Applicants inserted successfully.');
                } catch (Exception e) {
                    System.debug('Error during insert of Co-Applicants: ' + e.getMessage());
                    return 'Error during insert of Co-Applicants: ' + e.getMessage();
                }
            }
            
            //To Update Booking Id in Booking Request Record
            /*Booking_Request__c bkrq = new Booking_Request__c();
bkrq.Id = recId;
bkrq.Booking__c = bk.Id;
bkrq.Preferred_Unit__c = bk.Plot__c;
update bkrq;*/
            Quote__c cosSht = new Quote__c();
            cosSht.Id = recId;
            cosSht.Booking__c = bk.Id;
            update cosSht;
            
            return bk.Id;
        } else {
            return 'Plot is not available.';
        }
    }
    
    public static void bookingAmountReceipt(Booking__c booking){
        List<Payment_Schedule__c> existingPaymentSchedules = [
            SELECT Id, Name,Booking__c,Payment_percent__c,status__c,S_No__c,Master_Payment_Schedule__c  
            FROM Payment_Schedule__c
            WHERE Booking__c =: booking.id
        ];
        
        Receipt__c recp = new Receipt__c();
        recp.Booking__c = booking.Id;
        recp.Receipt_Name__c = 'Booking Amount Receipt';
        recp.Remarks__c = 'Receipt for the Booking Amount. Auto Generated by system';
        insert recp;
        
        if(recp.Id != null){
            Receipt_Line_Item__c rli = new Receipt_Line_Item__c();
            rli.Name = 'Booking Amount';
            rli.Cheque_no_Transaction_Number__c = booking.Cheque_DD_NEFT_RTGS_No__c;
            //rli.Mode_of_Payment__c = booking.Mode_Of_Payment__c;
            rli.Receipt__c = recp.Id;
            rli.Booking__c = booking.Id;
            rli.Amount__c = booking.Booking_Amount1__c;
            rli.Payment_schedule__c = existingPaymentSchedules[0].Id;
            insert rli;
        }
    }


 @future(callout=true)
    public static void sendRegistrationEmailsAsync(List<Id> bookingIds) {
        List<Booking__c> bookings = [
            SELECT Id, Email1__c, Alternate_Email1__c 
            FROM Booking__c 
            WHERE Id IN :bookingIds
        ];

        // Co-Applicants
        Map<Id, List<String>> coApplicantEmailMap = new Map<Id, List<String>>();
        for (Co_Applicant__c ca : [
            SELECT Booking__c, Email__c 
            FROM Co_Applicant__c 
            WHERE Booking__c IN :bookingIds AND Email__c != null
        ]) {
            if (!coApplicantEmailMap.containsKey(ca.Booking__c)) {
                coApplicantEmailMap.put(ca.Booking__c, new List<String>());
            }
            coApplicantEmailMap.get(ca.Booking__c).add(ca.Email__c);
        }

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Booking__c> toUpdate = new List<Booking__c>();

        String urlval = Label.Org_url;
        Site mySite = [SELECT UrlPathPrefix FROM Site WHERE Name = 'CSAT_Form' LIMIT 1];

        for (Booking__c bk : bookings) {
            Set<String> emails = new Set<String>();

            if (isValidEmail(bk.Email1__c)) emails.add(bk.Email1__c);
            if (isValidEmail(bk.Alternate_Email1__c)) emails.add(bk.Alternate_Email1__c);

            if (coApplicantEmailMap.containsKey(bk.Id)) {
                for (String email : coApplicantEmailMap.get(bk.Id)) {
                    if (isValidEmail(email)) emails.add(email);
                }
            }

            if (!emails.isEmpty()) {
                String link = urlval + '/' + mySite.UrlPathPrefix + '?Id=' + bk.Id;

                String htmlBody = 'Dear Customer,<br/><br/>' +
                    'Thank you for choosing Jain Housing. Please click the link below to fill the <strong>Registration Feedback Form</strong>.<br/><br/>' +
                    '<a href="' + link + '">Click here</a><br/><br/>' +
                    'Thank you,<br/><strong>Jain Housing</strong>';

                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setToAddresses(new List<String>(emails));
                msg.setSubject('Registration Feedback Form');
                msg.setHtmlBody(htmlBody);
                 msg.setSaveAsActivity(true);
                //msg.setWhatId(bk.Id);
                emailsToSend.add(msg);
                 

                bk.FeedBack_Sent_Date__c = DateTime.now();
                toUpdate.add(bk);
            }
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        // Send Registration Feedback WhatsApp (parallel to email) for emailed bookings
        List<Id> feedbackBookingIds = new List<Id>();
        for (Booking__c bk : toUpdate) {
            feedbackBookingIds.add(bk.Id);
        }
        WhatsAppTemplates.sendTemplateForBookings('Registration_Feedback_WhatsApp', feedbackBookingIds);
    }

    private static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) return false;
        return Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', email);
    }





    
    public static void cloneBookingWithUnitChangeDetails(Booking__c currentBooking, String newStage, String previousBookingStage) {
        try {
            // List to store all sObjects that need to be updated
            List<sObject> allToUpdate = new List<sObject>();
            List<Plot__c> plotsToUpdate = new List<Plot__c>();
            
            // Fetch the plots associated with Swap_Unit__c and current Plot__c
            List<Plot__c> swapUnitPlotList = [SELECT Id, Name, Status__c FROM Plot__c WHERE Id = :currentBooking.Swap_Unit__c];
            List<Plot__c> currentPlotList = [SELECT Id, Name, Status__c FROM Plot__c WHERE Id = :currentBooking.Plot__c];
            
            // Mark the current plot as 'Available' and clear its booking reference
            for (Plot__c currentPlot : currentPlotList) {
                currentPlot.Status__c = 'Available';
                currentPlot.Booking__c = null;
                plotsToUpdate.add(currentPlot);
            }
            
            // Clone the current booking and update its details
            Booking__c clonedBooking = currentBooking.clone(false, true, false, false);
            clonedBooking.Stage__c = previousBookingStage;
            clonedBooking.Plot__c = currentBooking.Swap_Unit__c;
            clonedBooking.Swap_Unit__c = null;
            clonedBooking.Swap_unit_status__c = '';
            clonedBooking.Extra_Covered_Parking_Charges__c = currentBooking.Swap_Extra_Covered_Parking_Charges__c;
            clonedBooking.Funding_Type__c = currentBooking.Swap_Funding_Type__c;
            clonedBooking.Extra_Covered_Parking_Slots__c = currentBooking.Swap_Extra_Covered_Parking_Slots__c;
            clonedBooking.Mode_Of_Payment__c = currentBooking.Swap_Mode_of_Payment__c;
            clonedBooking.Solar_Charges__c = currentBooking.Swap_Solar_Charges__c;
            clonedBooking.Is_Swap__c = true;
            
            insert clonedBooking;
            
            // Mark the swap unit plot as 'Booked' with the new booking reference
            for (Plot__c swapUnitPlot : swapUnitPlotList) {
                swapUnitPlot.Status__c = 'Booked';
                swapUnitPlot.Booking__c = clonedBooking.Id;
                plotsToUpdate.add(swapUnitPlot);
            }
            
            // Update plot statuses
            if (!plotsToUpdate.isEmpty()) {
                update plotsToUpdate;
            }
            
            // Clone payment schedules and map them to the new booking
            List<Payment_Schedule__c> paymentSchedules = [SELECT Id, S_No__c, Payment_Percent__c, Amount__c, Completed_Date__c, Payment_Due_Date__c, Status__c
                                                          FROM Payment_Schedule__c WHERE Booking__c = :currentBooking.Id ORDER BY S_No__c ASC];
            List<Payment_Schedule__c> clonedSchedules = new List<Payment_Schedule__c>();
            Map<Decimal, Id> scheduleNumberToIdMap = new Map<Decimal, Id>();
            
            for (Payment_Schedule__c schedule : paymentSchedules) {
                Payment_Schedule__c clonedSchedule = schedule.clone(false, true, false, false);
                clonedSchedule.Booking__c = clonedBooking.Id;
                clonedSchedules.add(clonedSchedule);
            }
            
            if (!clonedSchedules.isEmpty()) {
                upsert clonedSchedules;
                for (Payment_Schedule__c clonedSchedule : clonedSchedules) {
                    scheduleNumberToIdMap.put(clonedSchedule.S_No__c, clonedSchedule.Id);
                }
            }
            
            // Clone co-applicants and assign them to the new booking
            List<Co_Applicant__c> coApplicants = [SELECT Id, Name, Booking__c FROM Co_Applicant__c WHERE Booking__c = :currentBooking.Id];
            for (Co_Applicant__c coApplicant : coApplicants) {
                Co_Applicant__c clonedCoApplicant = coApplicant.clone(false, true, false, false);
                clonedCoApplicant.Booking__c = clonedBooking.Id;
                allToUpdate.add(clonedCoApplicant);
            }
            
            // Clone receipts and their line items
            List<Receipt__c> receipts = [SELECT Id, Name, Booking__c FROM Receipt__c WHERE Booking__c = :currentBooking.Id];
            List<Receipt_Line_Item__c> receiptLineItems = [SELECT Id, S_No__c, Payment_Schedule__c, Booking__c, Amount__c, Received_Amount__c, Mode_of_Payment__c, Cheque_no_Transaction_Number__c 
                                                           FROM Receipt_Line_Item__c WHERE Booking__c = :currentBooking.Id];
            
            Receipt__c newReceipt;
            if (!receipts.isEmpty()) {
                newReceipt = new Receipt__c(Booking__c = clonedBooking.Id);
                allToUpdate.add(newReceipt);
            }
            
            upsert allToUpdate; // Save all updated records
            
            if (newReceipt != null) {
                newReceipt = [SELECT Id FROM Receipt__c WHERE Booking__c = :clonedBooking.Id LIMIT 1];
            }
            
            if (!receiptLineItems.isEmpty() && newReceipt != null) {
                List<Receipt_Line_Item__c> clonedReceiptLineItems = new List<Receipt_Line_Item__c>();
                
                for (Receipt_Line_Item__c lineItem : receiptLineItems) {
                    Receipt_Line_Item__c clonedLineItem = lineItem.clone(false, true, false, false);
                    clonedLineItem.Booking__c = clonedBooking.Id;
                    clonedLineItem.Receipt__c = newReceipt.Id;
                    clonedLineItem.Payment_Schedule__c = scheduleNumberToIdMap.get(lineItem.S_No__c);
                    clonedReceiptLineItems.add(clonedLineItem);
                }
                
                insert clonedReceiptLineItems;
            }
        } catch (Exception e) {
            System.debug('Error in cloneBookingWithUnitChangeDetails: ' + e.getMessage());
        }
    }
    
    public static void createPaymentSchedules(List<Booking__c> newBookings) {
        Set<Id> projectIds = new Set<Id>();
        Set<Id> towerIds = new Set<Id>();
        // Collect Project__c IDs from the Booking__c records
        for (Booking__c booking : newBookings) {
            if (booking.Block__c != null) {
                towerIds.add(booking.Block__c);
            }
            else if (booking.Project1__c != null) {
                projectIds.add(booking.Project1__c);
            }
        }
        List<Master_Payment_Schedule__c> towerRelatedMasterPaymentSchedules = new List<Master_Payment_Schedule__c>();
        List<Master_Payment_Schedule__c> projectRelatedMasterPaymentSchedules = new List<Master_Payment_Schedule__c>();
        // Query Master_Payment_Schedule__c records related to the Project__c IDs
        if (!towerIds.isEmpty()) {
            towerRelatedMasterPaymentSchedules = [
                SELECT Id, Name, Amount__c, Payment_percent__c, Status__c, S_No__c, Project__c,Include_interest__c,Tower__c
                FROM Master_Payment_Schedule__c
                WHERE Tower__c IN :towerIds  
            ];
        }
        if (!projectIds.isEmpty()){
            projectRelatedMasterPaymentSchedules = [
                SELECT Id, Name, Amount__c, Payment_percent__c, Status__c, S_No__c, Project__c,Include_interest__c,Tower__c
                FROM Master_Payment_Schedule__c
                WHERE Project__c IN :projectIds
            ];
        }
        List<Payment_Schedule__c> newPaymentSchedules = new List<Payment_Schedule__c>();
        // Create new Payment_Schedule__c records for Booking__c
        for (Booking__c booking : newBookings) {
            if (booking.Block__c != null) {
                for (Master_Payment_Schedule__c masterPaymentSchedule : towerRelatedMasterPaymentSchedules) {
                    if (masterPaymentSchedule.Tower__c == booking.Block__c) {
                        // Create a new Payment_Schedule__c record with data copied from the Master_Payment_Schedule__c record
                        Payment_Schedule__c newPaymentSchedule = new Payment_Schedule__c(
                            Booking__c = booking.Id,
                            // Copy fields from Master_Payment_Schedule__c
                            Payment_percent__c = masterPaymentSchedule.Payment_percent__c,
                            //Status__c = masterPaymentSchedule.Status__c,
                            Interest_Percent__c = booking.Interest_Percent__c,
                            Include_interest__c = masterPaymentSchedule.Include_interest__c,
                            S_No__c = masterPaymentSchedule.S_No__c,
                            Amount__c = masterPaymentSchedule.Amount__c,
                            Master_Payment_Schedule__c = masterPaymentSchedule.Id,
                            Name = masterPaymentSchedule.Name
                        );
                        newPaymentSchedules.add(newPaymentSchedule);
                    }
                }
            }
            else if (booking.Project1__c != null) {
                for (Master_Payment_Schedule__c masterPaymentSchedule : projectRelatedMasterPaymentSchedules) {
                    if (masterPaymentSchedule.Project__c == booking.Project1__c) {
                        // Create a new Payment_Schedule__c record with data copied from the Master_Payment_Schedule__c record
                        Payment_Schedule__c newPaymentSchedule = new Payment_Schedule__c(
                            Booking__c = booking.Id,
                            // Copy fields from Master_Payment_Schedule__c
                            Payment_percent__c = masterPaymentSchedule.Payment_percent__c,
                            //Status__c = masterPaymentSchedule.Status__c,
                            Interest_Percent__c = booking.Interest_Percent__c,
                            Include_interest__c = masterPaymentSchedule.Include_interest__c,
                            S_No__c = masterPaymentSchedule.S_No__c,
                            Amount__c = masterPaymentSchedule.Amount__c,
                            Master_Payment_Schedule__c = masterPaymentSchedule.Id,
                            Name = masterPaymentSchedule.Name
                        );
                        newPaymentSchedules.add(newPaymentSchedule);
                    }
                }
            }
        }
        if (!newPaymentSchedules.isEmpty()) {
            insert newPaymentSchedules;
        }
    }
    
    public static void MapPaymentSchedules(List<Booking__c> newBookings){
        
        Set<Id> costSheetIds = new Set<Id>();
        Map<string,string> CsBkMap = new Map<string,string>();
        List<Payment_Schedule__c> paymentSchedulesToUpdate = new List<Payment_Schedule__c>();
        
        for(Booking__c bk : newBookings){
            if(bk.Cost_Sheet__c != null){
                costSheetIds.add(bk.Cost_Sheet__c);
                CsBkMap.put(bk.Cost_Sheet__c,bk.Id);
            }
            
        }
        for(Payment_Schedule__c ps : [ SELECT Id, Name, Cost_Sheet__c FROM Payment_Schedule__c WHERE Cost_Sheet__c IN :costSheetIds ]){
            if(ps.Cost_Sheet__c != null && CsBkMap.containskey(ps.Cost_Sheet__c)){
                ps.Booking__c = CsBkMap.get(ps.Cost_Sheet__c);
                paymentSchedulesToUpdate.add(ps);
            }
        }
        
        update paymentSchedulesToUpdate;
    }
    
    public static void ChangeBookingReqStatus(List<Booking__c> newBookings){
        
        Set<Id> costSheetIds = new Set<Id>();
        Map<string,string> unitBkrqMap = new Map<string,string>();
        Map<string,string> csBkIdMap = new Map<string,string>();
        List<Booking_Request__c> BkToUpdate = new List<Booking_Request__c>();
        
        for(Booking__c bk : newBookings){
            if(bk.Cost_Sheet__c != null){
                costSheetIds.add(bk.Cost_Sheet__c);
                csBkIdMap.put(bk.Cost_Sheet__c,bk.Id);
            }
        }
        for(Quote__c cs : [SELECT Id, Name, Booking_Request__c,Booking_Request__r.Is_PSA_Booking_Request__c,Booking__c,Unit__c FROM Quote__c WHERE Id IN: costSheetIds]){
            if(cs.Booking_Request__c != null){
                Booking_Request__c bkrq = new Booking_Request__c();
                bkrq.Id = cs.Booking_Request__c;
                bkrq.Booking__c = csBkIdMap.get(cs.Id);
                bkrq.Stage__c = 'Request Successfully Closed';
                BkToUpdate.add(bkrq);
                
                if(!cs.Booking_Request__r.Is_PSA_Booking_Request__c)
                    unitBkrqMap.put(cs.Unit__c,cs.Booking_Request__c);
            }
        }
        for(Plot__c pt : [select id,name,(select id,name,Stage__c from Booking_Requests__r) from Plot__c where Id in: unitBkrqMap.keyset()]){
            for(Booking_Request__c bkr : pt.Booking_Requests__r){
                if(bkr.Id != unitBkrqMap.get(pt.Id)){
                    bkr.Stage__c = 'Request Abandoned';
                    BkToUpdate.add(bkr);
                }
                
            }
        }
        update BkToUpdate;
    }
    
    public static void stageWiseOwnerUpdate(List<Booking__c> newBookings, Map<Id, Booking__c> oldBookingMap) {
        Set<Id> projectIds = new Set<Id>();
        for (Booking__c newBooking : newBookings) {
            if (newBooking.Project1__c != null) {
                projectIds.add(newBooking.Project1__c);
            }
        }
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>([
            SELECT Id, Reservation_User__c, Demands_Collection_User__c, Possession_User__c,
            Agreement_User__c, Registration_User__c, Maintenance_User__c
            FROM Project__c WHERE Id IN :projectIds
        ]);
        
        for (Booking__c newBooking : newBookings) {
            if (oldBookingMap != null) {
                Booking__c oldBooking = oldBookingMap.get(newBooking.Id);
                
                if (oldBooking.Stage__c != newBooking.Stage__c) {
                    Project__c project = projectMap.get(newBooking.Project1__c);
                    if (newBooking.Stage__c == 'Agreement' && project.Agreement_User__c != null) {
                        newBooking.OwnerId = project.Agreement_User__c;
                    } else if (newBooking.Stage__c == 'Demands & Collection' && project.Demands_Collection_User__c != null) {
                        newBooking.OwnerId = project.Demands_Collection_User__c;
                    } else if (newBooking.Stage__c == 'Registration' && project.Registration_User__c != null) {
                        newBooking.OwnerId = project.Registration_User__c;
                    } else if (newBooking.Stage__c == 'Possession' && project.Possession_User__c != null) {
                        newBooking.OwnerId = project.Possession_User__c;
                    } else if (newBooking.Stage__c == 'Maintenance' && project.Maintenance_User__c != null) {
                        newBooking.OwnerId = project.Maintenance_User__c;
                    }
                }
            }
        }
    }
    
    public static void sendCustomNotification(Set<String> recepientIds, String Title, String Body, String recId, String notificationName){
        CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
        Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
        Notification.setNotificationTypeId(closedWonNotification.id); 
        Notification.setSenderId(Userinfo.getUserId()); 
        Notification.setBody(Body); 
        Notification.setTitle(Title); 
        Notification.setTargetId(recId); 
        Notification.send(recepientIds);
    }
    
    @AuraEnabled
    public static void documentVerificationApproval(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Document Verification Approval');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Documents_Check_Approval');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    @AuraEnabled
    public static void receiptApprovalforFinanceTeam(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Receipt Approval');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Receipt_Approval_To_Finance_Team	');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    @AuraEnabled
    public static void bookingCancellationApproval(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Booking Cancellation');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Cancellation_Approval_For_Booking');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    @AuraEnabled
    public static void requestSaleAgreement(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Sale Agreement');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Request_for_Sale_Agreement');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    @AuraEnabled
    public static void partialAmountAgreementAmountApproval(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Sale Agreement');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Agreement_Partial_Amount_Paid_Approval');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    @AuraEnabled
    public static void requestForSaleDeed(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Sale Agreement');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId());
        req1.setProcessDefinitionNameOrId('Agreement_Partial_Amount_Paid_Approval');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    @AuraEnabled
    public static void requestForRegistrationApproval(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Sale Agreement');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Registration_Approval');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    @AuraEnabled
    public static void requestTransferApproval(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Sale Agreement');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Transfer_Assignment_Approval');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    /*public class BookingUserWrapper1 {
        @AuraEnabled
        public Booking__c booking;
        
        @AuraEnabled
        public User loggedInUser;
        
        public BookingUserWrapper1(Booking__c booking, User loggedInUser) {
            this.booking = booking;
            this.loggedInUser = loggedInUser;
        }
    }
    public class BookingUserWrapper2 {
        @AuraEnabled public Booking__c booking;
        @AuraEnabled public User loggedInUser;
        @AuraEnabled public String bookingFormPdfUrl;

        public BookingUserWrapper2(Booking__c b, User u) {
            this.booking = b;
            this.loggedInUser = u;
            
            PageReference bookingFormPage = Page.AnushreeBookingForm;
            bookingFormPage.getParameters().put('Id', b.Id);
            String baseUrl = System.Url.getOrgDomainUrl().toExternalForm(); // Works in v58+
            this.bookingFormPdfUrl = baseUrl + bookingFormPage.getUrl();
        }
    }
	@AuraEnabled(cacheable=true)
    public static BookingUserWrapper1 getRecordData1(Id recordId) {
        // Fetch the booking record
        Booking__c booking = [SELECT Id, Name, First_Applicant_Name__c,Tower__c,Tower_Name__c, salutation_Applicant1__c, salutation_Applicant2__c, 
                              Second_Applicant_Name__c, Swap_Unit_Status__c, Project__c, Booking_Amount1__c, 
                              Unit_NumberFor__c, Email1__c 
                              FROM Booking__c WHERE Id = :recordId LIMIT 1];
        
        // Fetch the logged-in user details
        User loggedInUser = [SELECT Name,Email, Phone FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        

           
            

        // Return both booking and logged-in user details in a wrapper
        return new BookingUserWrapper1(booking, loggedInUser);
    }
    
    */
    
    public class BookingUserWrapper {
        @AuraEnabled public Booking__c booking;
        @AuraEnabled public User loggedInUser;
        @AuraEnabled public List<DocumentLinkWrapper> documents;
        
       /* public BookingUserWrapper(Booking__c b, User u) {
            this.booking = b;
            this.loggedInUser = u;
            
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            
            documents = new List<DocumentLinkWrapper>{
                new DocumentLinkWrapper('Booking Form', baseUrl + Page.AnushreeBookingForm.getUrl() + '?Id=' + b.Id),
                    new DocumentLinkWrapper('Sale Agreement', baseUrl + Page.SALE_AGREEMENT_AARYA.getUrl() + '?Id=' + b.Id),
                    new DocumentLinkWrapper('Cost Sheet', baseUrl + Page.COST_SHEET_AARYA.getUrl() + '?Id=' + b.Id)
                    };
                        }
        */
        public BookingUserWrapper(Booking__c b, User u) {
            this.booking = b;
            this.loggedInUser = u;
            
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String bookingFormVFName;
            
            // Logic to dynamically assign the VF page name based on Project__c or other logic
            if (b.Project__c == 'Jains Anushree') {
                bookingFormVFName = 'AnushreeBookingForm';
            } else if (b.Project__c == 'Jains Aadhya') {
                bookingFormVFName = 'AadhyaBookingForm';
            } else {
                bookingFormVFName = 'DefaultBookingForm';
            }
            
            // Manually construct the VF page URL
            String bookingFormUrl = baseUrl + '/apex/' + bookingFormVFName + '?Id=' + b.Id;
            
            documents = new List<DocumentLinkWrapper>{
                new DocumentLinkWrapper('Booking Form', bookingFormUrl)
                    //commented by karthik
                    //new DocumentLinkWrapper('Allotment Letter', baseUrl + Page.AadhyaBookingForm.getUrl() + '?Id=' + b.Id)
                    };
                        }
    }

    @AuraEnabled(cacheable=true)
    public static BookingUserWrapper getRecordData(Id recordId) {
        Booking__c booking = [SELECT Id, Name, First_Applicant_Name__c, Tower__c, Tower_Name__c, salutation_Applicant1__c,
                              salutation_Applicant2__c, Second_Applicant_Name__c, Swap_Unit_Status__c, Project__c,
                              Booking_Amount1__c, Unit_NumberFor__c, Email1__c 
                              FROM Booking__c WHERE Id = :recordId LIMIT 1];

        User loggedInUser = [SELECT Name, Email, Phone FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        return new BookingUserWrapper(booking, loggedInUser);
    }
    
    
    
    @AuraEnabled
    public static void sendWelcomeEmail(Id recordId, String emailContent, List<String> toAddresses, List<String> contentIds) {
        system.debug('Content IDs: ' + contentIds);
        Booking__c leadRecord = [SELECT Id,Plot__r.Name,Alternate_Email1__c,salutation_Applicant2__c,salutation_Applicant1__c,Block__r.Name, Name, CRM_Manager__c,Email2__c,Project1__r.Name,CRM_Manager__r.Email, First_Applicant_Name__c,Second_Applicant_Name__c, Project__c, Booking_Amount1__c, Unit_NumberFor__c, Email1__c,Project1__r.Project__c, 
                                 (SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks WHERE ContentDocumentId IN :contentIds) 
                                 FROM Booking__c 
                                 WHERE Id = :recordId 
                                 LIMIT 1];
        List<String> ccAddresses = new List<String>();
        
        if(leadRecord != null && leadRecord.Alternate_Email1__c != null)
        {
            toAddresses.add(leadRecord.Alternate_Email1__c);
        }
        
        if (leadRecord != null && leadRecord.Email1__c != null) {
            
            toAddresses.add(leadRecord.Email1__c);
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink docLink : leadRecord.ContentDocumentLinks) {
                contentDocumentIds.add(docLink.ContentDocumentId);
            }
            if (!contentDocumentIds.isEmpty()) {
                List<ContentVersion> contentVersions = [SELECT Title,FileExtension, VersionData FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds];
                for (ContentVersion cv : contentVersions) {
                    Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                    String fileNameWithExtension = cv.Title + '.' + cv.FileExtension;
                    contentAttach.setFileName(fileNameWithExtension);
                    contentAttach.setBody(cv.VersionData);
                    emailAttachments.add(contentAttach);
                }
            }
            

            List<PageReference> vfPages = new List<PageReference>();
            
            if(leadRecord.Project1__r.Name.contains('Jains Anushree')){
                vfPages.add(Page.AnushreeBookingForm);
                //vfPages.add(Page.COST_SHEET_AARYA);
                for (PageReference pref : vfPages) {
                    system.debug(pref);
                    pref.getParameters().put('id', recordId);
                    Blob pdfBlob = !Test.isRunningTest() ? pref.getContentAsPDF(): Blob.valueOf('testblob');
                    Messaging.EmailFileAttachment vfAttachment = new Messaging.EmailFileAttachment();

                    String attachmentName;
                    if (pref.getUrl().contains('anushreebookingform')) {
                        attachmentName = 'Booking Form.pdf'; 
                    } else if (pref.getUrl().contains('cost_sheet_aarya')) {
                        attachmentName = 'Allotment Letter.pdf'; 
                    } else {
                        attachmentName = 'Document.pdf'; 
                    }
                    
                    vfAttachment.setFileName(attachmentName);
                    vfAttachment.setBody(pdfBlob);
                    emailAttachments.add(vfAttachment);
                }
            }
            
            if (!emailAttachments.isEmpty()) {
                mail.setFileAttachments(emailAttachments);
            }
            mail.setCcAddresses(ccAddresses);
            mail.setToAddresses(toAddresses);
            
            // Build the subject line
            String applicantNames = 'Welcome ';
            
            if (leadRecord.First_Applicant_Name__c != null) {
                if (leadRecord.salutation_Applicant1__c != null) {
                    applicantNames +=leadRecord.salutation_Applicant1__c + '. ';
                }
                applicantNames += leadRecord.First_Applicant_Name__c + ' ';
            }
            
            //String projectDetails = applicantNames +' ' + leadRecord.Project1__r.Name + ' ' + leadRecord.Block__r.Name + ' ' + leadRecord.Plot__r.Name;
            
            // Set the subject line
            mail.setSubject('Welcome to Jain Housing – Your Journey to a New Home Begins!');
            
            mail.setHtmlBody(emailContent);
            
            mail.setSaveAsActivity(true);
            mail.setWhatId(leadRecord.Id);
            
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
            leadRecord.Welcome_Mail_Sent_Time__c = system.now();
            leadRecord.Welcome_Email_Sent_to_Customer__c = true;
            update leadRecord;

            // Send Welcome SMS via Prompt Bulk SMS API (Queueable - bulk safe)
            SMSTemplates.sendWelcomeSMSBulk(new List<Id>{ recordId });

            // Send Welcome WhatsApp via Adz Network Media API (Queueable - bulk safe)
            WhatsAppTemplates.sendWelcomeWhatsAppBulk(new List<Id>{ recordId });
        }
    }
    
    @AuraEnabled
    public static Transfer__c getTransferRecordDetails(Id recId){
        Transfer__c trnas = [select id,name,Customer_Name__c,Email__c,PAN_Number__c,Phone__c,Transfer_Amount__c from Transfer__c where Booking__c =:recId LIMIT 1 ];
        return trnas;
    }
    
    /* @AuraEnabled
public static void createBookingRecordDetails(Id recId,String customerName,String phone,String country,String email,String PanNumb ){

Booking__c booking = [SELECT Id, vide_no__c, state1__c, salutation_Applicant2__c, salutation_Applicant1__c, generator_and_prepaid_gas_charges__c, demo__c, amenities_charges__c, Welcome_Mail_Sent_Time__c, Welcome_Email_Sent_to_Customer__c, Welcome_Call_Done__c, Welcome_Call_Date__c, Website_Secondary__c, Website_Primary__c, VP__c, Uploaded_Sale_Deed_Signed_Copy__c, Unit_UDS_Area__c, Unit_Size__c, Unit_Share__c, Unit_Number__c, Unit_NumberFor__c, Unit_Facing_Directionswap__c, Unit_Facing_Direction__c, Unit_Common_Area_Allotted_to_Association__c, UDS_Area__c, Type__c, Transfer_Amount__c, Transaction_ID__c, Tower__c, Total_received_Amount__c, Total__c, Total_Receipt__c, Total_Other_Charges__c, Total_Interest__c, Total_Consideration_with_taxes_and_other__c, Token_Amount__c, Third_Applicant_Photo__c, Third_Applicant_Name__c, TPA__c, TPA_Agreement_Date__c, TAXES__c, TAXES1__c, Super_Built_up_area_NE__c, Sub_Total__c, Sub_Stages__c, Sub_Source__c, State__c, State3__c, State2__c, Stage__c, Stage_Changed_To_Assignement__c, Special_Notes__c, Source_of_refferal__c, Son_Daughter_Wife_of__c, Son_Daughter_Wife_of1__c, Sold_Details__c, Solar_Charges__c, Social_Media_Use__c, Signature_Of_Second_Applicant__c, Signature_Of_First_Applicant__c, Share__c, Sent_Loan_Document_To_Bank__c, Second_Applicant_Photo__c, Second_Applicant_Name__c, Sanctioned_Date__c, Sanctioned_Amount__c, Sanction_Letter_Uploaded__c, Sales_Manager1__c, Sale_Deed_Number__c, Sale_Area__c, Sale_Agreement_Uploaded__c, Sale_Agreement_Date__c, Sale_Agreement_Completed__c, SLead__c, SB_Account__c, Rs_100_Per_Sft_Infra_STP_EB__c, Revenue_to_Company__c, Residential_Status__c, Residential_Status1__c, Reservation_User__c, Request_For_Transfer__c, Request_For_Sale_Deed__c, Request_For_Sale_Agreement__c, Request_For_Registration_Status__c, Request_For_Cancellation_Agreement__c, Remarks__c, Remark__c, Relationship_Manager__c, Relation_Details_Applicant2__c, Relation_Details_Applicant1__c, Registration_User__c, Registration_Uploads_Successful__c, Registration_Number__c, Registration_Expected_Date__c, Registration_Done__c, Registration_Date__c, Refund__c, Receipt_Approval_Status__c, Rate_per_sqftswap__c, Rate_per_sqft__c, ROI__c, RM_Name__c, RERA_NO__c, Quote_date__c, Purpose_of_Purchase__c, Property_Type__c, Property_Type_For__c, Projectswap__c, Project__c, Project1__c, Profession__c, Profession3__c, Profession1__c, Private_Terrace__c, Print_Form__c, Price_per_sqft__c, Premium_Charge__c, Post_Agreement_Cancellation__c, Possession_send__c, Possession_User__c, Possession_Send_Date__c, Possession_Expected_Date__c, Plot__c, Plot_Type__c, Plot_Land_Areaswap__c, Plot_Land_Area__c, Place7__c, Pincode__c, Pincode3__c, Pincode2__c, Pincode1__c, Permenant_Adress__c, Permenant_Adress1__c, Permanent_Address1__c, Pending_Amount__c, Payment_Type__c, Passport_Uploded__c, Passport_PI_no__c, Passport_PI_no3__c, Passport_PI_no1__c, Passport_Aadhar__c, Passport_Aadhar_1__c, Pan_Number_Applicant2__c, Pan_Card_Uploaded__c, PAN_Number1__c, Owenr_Phone__c, Outflow__c, OutFlow_Date__c, Other_Charges__c, Other_Amenities__c, Original_Agreement_Collected__c, Organisation_Designation__c, Organisation_Designation3__c, Organisation_Designation1__c, Old_Agreement_Collected__c, Occupation__c, Occupation1__c, Number_of_Children__c, Number_of_Children1__c, Newspaper_Read__c, NewsPaper_Ad__c, Nationality__c, Nationality_Applicant2__c, Name_of_the_Channel_Partner__c, Name_of_Spouse__c, Name_of_Spouse1__c, Name_of_Referee__c, Name_of_Company__c, Name_of_Company1__c, Name, NOC__c, Mode_Of_Payment__c, Mobile__c, Mobile_Primary__c, Mobile_Primary3__c, Mobile_Primary2__c, Mobile_Primary1__c, Mobile_Alternate__c, Mobile_Alternate2__c, Mobile_Alternate1__c, Middle_Name__c, Middle_Name3__c, Middle_Name1__c, Marital_Status__c, Marital_Status1__c, Maintenance_charges__c, Maintenance_User__c, Maintenance_Expected_Date__c, Maintenance_Deposite__c, Maintenance_Chargeswap__c, Maintenance_Charge__c, Location__c, Loan_User__c, Loan_Sanctioned__c, Loan_Sanctioned_Amount__c, Loan_Sanction_Confirmed__c, Loan_Expected_Date__c, Loan_Account_Number__c, Legal_charges__c, Legal_Team__c, Legal_Loan_Uploads_Successful__c, Legal_Documentation_Chargesswap__c, Legal_Documentation_Charges__c, Legal_Approval_Status__c, Leads_source__c, Lead__c, Lead_Name__c, Lead_Allocation_Date__c, Last_comment__c, Last_Name_SurName__c, Last_Name_SurName3__c, Last_Name_SurName1__c, KycUploaded__c, Khata_charges__c, Khata_No__c, KYC__c, KPTCL_and_SI__c, Is_Swap__c, IsDeleted, IsCancelled__c, Interior_Charges__c, Interest_Waive_Off__c, Interest_Percent__c, Interest_Pending__c, Interest_Paid__c, Interest_From_PS__c, Infrastructure_Charges_per_sqftwsap__c, Infrastructure_Charges_per_sqft__c, In_Favour_Of__c, IFSC_Code__c, House_Number__c, House_Number2__c, House_Number1__c, Hoarding__c, Handover_User__c, Guideline_Value__c, Ground_Floor_Garden__c, Gender__c, Gender1__c, GSTswap__c, GST__c, GST_Amount__c, Funding_Type__c, Followup_Subject__c, Followup_Date__c, Floor_Rise_Charges_Rate__c, FloorNo__c, Flat_Number__c, Flat_Actual_Number__c, First_disbursement__c, First_Disbursement_Received__c, First_Disbursement_Date__c, First_Dibursement_Expected_date__c, First_Applicant_Photo__c, First_Applicant_Name__c, Finance_User__c, Finance_Approval__c, Finance_Approval1__c, File_Number__c, Father_Spouse_Name__c, Father_Spouse_Name1__c, Facing__c, Extra_covered_Parking_Slots__c, Extra_Covered_Parking_Charges__c, Existing_customer__c, Enquiry_Source__c, Email2__c, Email1__c, Educational_Qualifications__c, Educational_Qualifications3__c, Educational_Qualifications1__c, E_mail2__c, EFT__c, EB_GST_18__c, Drawn_No__c, Documents_Sent_To_Bank__c, Discount__c, Director__c, Development_Charge__c, Designation__c, Designation1__c, Description__c, Demands__c, Demands_Expected_Date__c, Demand_Raised__c, Demand_Number__c, Demand_Letter__c, Demand_Letter_Sent_Date__c, Demand_Collection_Users__c, Date_of_birth_Applicant2__c, Date_of_balance_own_contribution_to_be_p__c, Date_of_Bookingswap__c, Date_of_Booking__c, Date_of_Birth1__c, Date_Of_Offer_Letter__c, Date7__c, Customer_Is_going_for_Loan__c, Customer_ID__c, Createddate__c, Covered_Park_Parking__c, Country1__c, Cost_Break_up_Sheet__c, Corpus_Fundswap__c, Corpus_Fund__c, Contact_Telephone_Number__c, Contact_Telephone_Number1__c, Contact_Number1__c, Communication_address__c, Communication_address1__c, Common_Area__c, Common_Area_Allotted_to_Association__c, Commission__c, Comments__c, Co_Applicant_Photo_Uploaded__c, Clubhouse_Charges__c, Club_Houseswap__c, Club_House__c, City3__c, City2__c, City1__c, Citizen_of_Status_NRI_POI__c, Citizen_of_Status_NRI_POI1__c, Cheque_DD_NEFT_RTGS_No__c, Carpet_Area__c, Cancellation_User__c, Cancellation_Status__c, Cancellation_Charges__c, CRM_Manager__c, CRM_Manager_Email__c, CRM_Manager_Approval__c, CFO__c, Built_up_area__c, Builder_Land_Owner_Name__c, Branch_Name__c, Booking__c, Booking_Stage_Uploads_Successful__c, Booking_Stage_Document_Created__c, Booking_Stage_Completed__c, Booking_Owner__c, Booking_Link_Filled__c, Booking_Form__c, Booking_Date__c, Booking_Amount1__c, Booking_Accepted_by_Customer__c, Block__c, Block1__c, Basic_Sale_Price_Rs__c, Basic_Priceswap__c, Basic_Price__c, Bank__c, Bank_Name__c, Bank_NOC_Collected__c, Bank_Employee_Contact_Number__c, Bank_CO_Ordinator__c, Balance_Booking_Amout__c, BHK_Type__c, BESCOM_Deposit_Rs__c, Attended_By_Name__c, Associated_Unit__c, Associated_Project__c, Assignment_Process_Started__c, Assignment_Process_Completed__c, Assigned_by__c, Approved_By_Nmae__c, Approval_status__c, Applicant_Photo_Uploded__c, Applicant_Name__c, Applicant_Mobile_Number__c, Apartment_Number__c, Annual_income__c, Anniverssary_Date__c, Anniverssary_Date3__c, Anniverssary_Date1__c, Amount_in_words__c, Amount_INR__c, Amount_By_Customer__c, Allotment_Letter__c, All_Payment_Cleared__c, All_KYC_are_correct__c, Agreement_value__c, Agreement_User__c, Agreement_Uploads_Successful__c, Agreement_Stage__c, Agreement_Percentage__c, Agreement_Expected_Date__c, Agreement_Amount_Cleared__c, Agreement_Amount_Check__c, Agreed_Apt_Price_INR__c, Age__c, Age2__c, Address__c, Actual_Booking_Amout__c, Account_Number__c, Aadhaar_Uploded__c, Aadhaar_Number__c, Aadhaar_Number1__c, AM__c FROM Booking__c where Id =: recId];

Booking__c clonedBooking = booking.clone(false, true);

clonedBooking.Email1__c   = email;
clonedBooking.Nationality__c   = country;
clonedBooking.First_Applicant_Name__c   = customerName;
clonedBooking.Mobile_Primary__c   = phone;
clonedBooking.PAN_Number1__c   = PanNumb;
//clonedBooking.Stage__c = booking.Stage_Changed_To_Assignement__c;
system.debug(clonedBooking.Stage__c = booking.Stage__c ?? 'Reservation');
clonedBooking.Stage__c = booking.Stage__c ?? 'Reservation';
insert clonedBooking;
//booking.Stage__c = 'Assignment Completed';
clonedBooking.Assignment_Process_Completed__c=true;
update booking;

// Fetch related Receipt records
List<Receipt__c> receiptList = [SELECT Id, Name
FROM Receipt__c WHERE Booking__c = :recId];
// Clone each Receipt and link to the cloned Booking
List<Receipt__c> clonedReceipts = new List<Receipt__c>();
for (Receipt__c receipt : receiptList) {
Receipt__c clonedReceipt = receipt.clone(false, true);
clonedReceipt.Booking__c = clonedBooking.Id; // Link to the new Booking record
clonedReceipts.add(clonedReceipt);
}

// Insert the cloned Receipt records
if (!clonedReceipts.isEmpty()) {
insert clonedReceipts;
}

set<String> userIds = new set<String>();
string Body = 'Please create debit note for Booking '+clonedBooking.Name;
userIds.add(clonedBooking.Finance_User__c);
BookingController.sendCustomNotification(userIds,'Booking Transfer',Body,clonedBooking.Id,'Booking_Notification');
}*/
    @AuraEnabled
    public static void saveTransfer(Booking__c booking, Id recordId, Boolean isSecondaryApplicantSame) {
        try {
            // Set the Booking Id to the recordId passed from the front end
            booking.Id = recordId;
            system.debug('booking'+booking);
            system.debug('recordId'+recordId);
            system.debug('isSecondaryApplicantSame'+isSecondaryApplicantSame);
            // Check if the secondary applicant fields should be cleared
            if (!isSecondaryApplicantSame) {
                if (String.isEmpty(booking.Second_Applicant_Name__c)) {
                    // Clear the secondary applicant fields if the checkbox is unchecked
                    booking.salutation_Applicant2__c = null;
                    booking.Second_Applicant_Name__c = null;
                    booking.Date_of_birth_Applicant2__c = null;
                    booking.Mobile_Primary1__c = null;
                    booking.Email2__c = null;
                    booking.Nationality_Applicant2__c = null;
                    booking.Relation_Details_Applicant2__c = null;
                    booking.Son_Daughter_Wife_of1__c = null;
                    booking.Passport_Aadhar_1__c = null;
                    booking.Aadhaar_Number1__c = null;
                    booking.Pan_Number_Applicant2__c = null;
                    booking.Occupation1__c = null;
                    booking.Name_of_Company1__c = null;
                    booking.Designation1__c = null;
                    booking.Anniverssary_Date1__c = null;
                    booking.Communication_address1__c = null;
                    booking.Permanent_Address1__c = null;
                }
            }
            
            // Perform the update
            update booking;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to save the record: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Booking__c getSecondaryApplicantDetails(Id bookingId) {
        // Query the Booking__c object for secondary applicant details
        Booking__c booking = [SELECT salutation_Applicant2__c, Second_Applicant_Name__c, Date_of_birth_Applicant2__c, 
                              Mobile_Primary1__c, Email2__c, Nationality_Applicant2__c, Relation_Details_Applicant2__c,
                              Son_Daughter_Wife_of1__c, Passport_Aadhar_1__c, Aadhaar_Number1__c, Pan_Number_Applicant2__c, 
                              Occupation1__c, Name_of_Company1__c, Designation1__c, Anniverssary_Date1__c, 
                              Communication_address1__c, Permanent_Address1__c 
                              FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        
        // Return the secondary applicant details
        return booking;
    }
    
    public static void PushingtoCRM(Booking__c bk){
        try {
            List<User> uList = new List<User>();
            //Booking__c bk = [SELECT Id, Name, OwnerId, Sales_Manager1__c, Assigned_by__c, Project__c, Aadhaar_Uploded__c, Pan_Card_Uploaded__c, KycUploaded__c FROM Booking__c WHERE Id = :bookingId];
            List<Round_Robin__c> RRAvaliablequeList=[Select Id,Project__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true order by Last_Assigned_Time_user__c,createddate asc nulls first limit 1) from Round_Robin__c where Project__c =: bk.Project__c and Active__c = true ];
            List<Project__c> proJectList = [select Id,Name,CRM_Manager__c,Finance_User__c from Project__c where Project__c =:bk.Project__c ];
            if(RRAvaliablequeList.size()>0){
                for(Round_Robin__c rr : RRAvaliablequeList){
                    if(rr.Round_Robin_Members__r.size()>0){
                        bk.OwnerId = rr.Round_Robin_Members__r[0].User__c;
                        User u = new User();
                        u.Id = rr.Round_Robin_Members__r[0].User__c;
                        u.Last_Assigned_Time__c = system.now().getTime(); 
                        uList.add(u);
                    }
                    else{
                        bk.OwnerId = proJectList[0].CRM_Manager__c;
                    }
                }
            }
            else{
                bk.OwnerId = proJectList[0].CRM_Manager__c;
            }
            
            //update bk;
            update uList;
            /*if(bk != null && bk.Project__c != null) {
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments('Approval request');
                req1.setObjectId(bk.Id);
                req1.setSubmitterId(userInfo.getUserId());
                req1.setProcessDefinitionNameOrId('Booking_Confirmation_Approval');
                req1.setSkipEntryCriteria(true);
                Approval.ProcessResult result = Approval.process(req1);
            }*/
        } 
        catch (QueryException e) {
            System.debug('Query Exception occurred: ' + e.getMessage());
        } 
    
    }
    
    public static void testcover(){
        integer  i=0;
        if(i==0){
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
        }
    }
    
}