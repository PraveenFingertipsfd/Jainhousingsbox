public without sharing class BookingFill_Controller {
    @AuraEnabled
    public static string send_Booking_Request(string recordId, string EmailId, Integer BlockedPrice){
        
        try{
            Booking_Request__c bk = new Booking_Request__c();
            bk.Unit__c = recordId;
            bk.Email__c = EmailId;
            bk.Blocked_Price__c = BlockedPrice;
            insert bk;
            
            Plot__c pt = [select id,Status__c from Plot__c where id =:recordId];
            pt.Status__c = 'Blocked';
            update pt;
            
            list<Messaging.SingleEmailMessage> message= new  list<Messaging.SingleEmailMessage>();
            
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            string urlval = label.Org_url;
            system.debug(urlval);
            Site mySite = [SELECT Id, Name, Subdomain, UrlPathPrefix FROM Site WHERE Name = 'Booking_Request_Site' LIMIT 1];
            system.debug(mySite.UrlPathPrefix);
            
            string  htmlBody='Dear Customer,<br/><br/>Thank you for choosing Jain Housing. We have attached a Hyperlink to fill and submit a booking request. <br/>To Open the Booking requisition page, please click on the link below. <br/>'+
                '<a href="'+urlval+'/'+ mySite.UrlPathPrefix +'?Id='+recordId+'&BkReqId='+bk.Id+'">Click here to request for Booking</a><br/>'+
                'We pride ourselves on providing high-quality Constructions, and we are confident that you will be completely satisfied with the results.<br/> If you have any questions or concerns, please don\'t hesitate to contact us. We are always happy to help.<br/><br/>'+'Thank you<br/>Jain Housing';
            string email = EmailId;
            semail.setSubject('Jain Housing\'s Booking Request Page');
            semail.setToAddresses(new String[]{email});
            semail.setHtmlBody(htmlBody);
            message.add(semail);  
            Messaging.sendEmail(message);
            
            return 'Success';
        }
        catch(exception e){
            System.debug('Error while sending booking request email: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
        
        
    }
    
    
    public class CSWrapper{
        @AuraEnabled 
        public Quote__c CSRec {get; set;}
        @AuraEnabled 
        public List<Payment_schedule__c> PaySchLst {get; set;}
        @AuraEnabled 
        public Booking_Request__c BkRqRec {get; set;}
        @AuraEnabled 
        public Boolean IsFormResponded {get; set;}
    }
    
    @AuraEnabled
    public static CSWrapper GetCostSheet(string recordId, string BkreqId){
        
        CSWrapper cswrp = new CSWrapper();
        //Booking_Request__c bkrq = [select id,IsResponded__c from Booking_Request__c where Id =: BkreqId limit 1];
        Quote__c cosSht = [select id,name,Customer_Comments__c,Is_Form_Responded__c,Status__c,Project__c,Project__r.Name,Unit__c,Unit__r.Name,Unit__r.Block1__c,BHK_Type__c,Balcony_Area__c,Open_Terrace_Area__c,Price_Per_Sq_Ft__c,Final_Price_Per_Sq_ft__c,Car_Parking_Type__c,Booking__c,
                           Booking_Request__c,Floor__c,Payment_Type__c,Carpet_Area__c,Super_Built_Up_Area__c,Discount_Price__c,Floor_Rise_Charge__c,Basic_Price__c,Car_Parking_Charges__c,
                           Floor_Rise_Charges__c,Other_Charges__c,Premium_Charges__c,Total_Cost__c,GST_Charges_On_Total_Cost__c,Total_Cost_Including_GST__c,Corpus_Fund__c,
                           GST_for_Corpus_Fund__c,GST_for_Maintenance_Charge__c,Maintenance_Charges__c,EB_Debris__c,Grand_Total__c from Quote__c where id =: recordId];
        
        List<Payment_schedule__c> PaySch = [select Id,name,Cost_Sheet__c,Payment_percent__c,S_No__c,AmountB__c,Received_Amount1__c from Payment_schedule__c where Cost_Sheet__c =: recordId order by S_No__c asc];
        
        Booking_Request__c Bkrq = [select id,name,Customer_Name__c,Email__c,PAN_Number__c,Aadhaar_Number__c,Mobile__c from Booking_Request__c where Id =: BkreqId];
        
        if(cosSht != null){
            cswrp.CSRec = cosSht;
            cswrp.IsFormResponded = cosSht.Is_Form_Responded__c;
        }
        if(PaySch != null){
            cswrp.PaySchLst = PaySch;
        }
        if(Bkrq != null){
            cswrp.BkRqRec = Bkrq;
        }
        
        return  cswrp;
    }
    
    @AuraEnabled
    public static Boolean check_IsPSA(string recordId){
        string UnitName = [select id,name from Plot__c where Id =: recordId limit 1].Name;
        return UnitName != null && UnitName.containsIgnoreCase('PSA');
    }
    
    @AuraEnabled
    public static Boolean check_EmailExists(string recordId){
        Booking_Request__c brq = [select id,IsResponded__c,Unit__c,Email__c from Booking_Request__c where Id =: recordId limit 1];
        string CusEmail = brq.Email__c;
        system.debug(CusEmail);
        if(CusEmail == null || CusEmail == ''){
            return false;
        }
        if(!brq.IsResponded__c){
            list<Messaging.SingleEmailMessage> message= new  list<Messaging.SingleEmailMessage>();
            
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            string urlval = label.Org_url;
            Site mySite = [SELECT Id, Name, Subdomain, UrlPathPrefix FROM Site WHERE Name = 'Booking_Request_Site' LIMIT 1];
            string  htmlBody='Dear Customer,<br/><br/>Thank you for choosing Jain Housing. We have attached a Hyperlink to fill and submit a booking request. <br/>To Open the Booking requisition page, please click on the link below. <br/>'+
                '<a href="'+urlval+'/'+ mySite.UrlPathPrefix +'?Id='+brq.Unit__c+'&BkReqId='+brq.Id+'">Click here to request for Booking</a><br/>'+
                'We pride ourselves on providing high-quality Constructions, and we are confident that you will be completely satisfied with the results.<br/> If you have any questions or concerns, please don\'t hesitate to contact us. We are always happy to help.<br/><br/>'+'Thank you<br/>Jain Housing';
            semail.setSubject('Jain Housing\'s Booking Request Page');
            semail.setToAddresses(new String[]{CusEmail});
            semail.setHtmlBody(htmlBody);
            message.add(semail);  
            Messaging.sendEmail(message);
        }
        return true;
    }
    
    @AuraEnabled
    public static Id createAdvancePayment(Advance_Payment__c payment) {
        insert payment;
        return payment.Id;
    }
    
    @AuraEnabled
    public static Map<String, List<String>> getPicklistValues() {
        Map<String, List<String>> picklistValues = new Map<String, List<String>>();
        
        // Get Bank picklist values
        List<String> banks = new List<String>();
        Schema.DescribeFieldResult bankField = Booking__c.Bank__c.getDescribe();
        for (Schema.PicklistEntry entry : bankField.getPicklistValues()) {
            banks.add(entry.getValue());
        }
        picklistValues.put('banks', banks);
        
        return picklistValues;
    }
    
    @AuraEnabled
    public static void InsertRejectionCS(Quote__c CosSht){
        system.debug('BookingReqt >> '+ CosSht);
        CosSht.Customer_Responded_Date__c = system.now();
        upsert CosSht;   
    }
    
    @AuraEnabled
    public static void  InsertSubmissionCSwithSign(Quote__c CosSht, Booking__c Booking, List<Co_Applicant__c> coApplicants, string signatureData){
        
        insert Booking;
        
        CosSht.Booking__c = Booking.Id;
        CosSht.Status__c = 'Closed Successfully';
        CosSht.Customer_Responded_Date__c = system.now();
        upsert CosSht;
        
        for (Co_Applicant__c coApp : coApplicants) {
            coApp.Booking__c = Booking.Id;
        }
        insert coApplicants;
        
        if (String.isNotBlank(signatureData)) {
            system.debug(signatureData);
            Attachment a = new Attachment();
            a.ParentId = Booking.Id;
            a.Name = 'Signature.png';
            a.Body = EncodingUtil.base64Decode(signatureData.split(',')[1]);
            a.ContentType = 'image/png';
            insert a;
        }
        
        BookingFill_Controller.CreateReceiptForAdvancePayment(CosSht.Id,Booking.Id);
        
    }
    
    @AuraEnabled
    public static void InsertSubmissionCSwithSignAndFiles1(Quote__c CosSht,Booking__c Booking,List<Co_Applicant__c> coApplicants,String signatureData,
        													Map<String, Object> uploadedFilesMap){
        try {
            System.debug('➡️ Booking ID before insert: ' + Booking.Id);
            System.debug('➡️ Signature Data Length: ' + (signatureData != null ? signatureData.length() : 0));
            System.debug('➡️ Uploaded Files Keys: ' + uploadedFilesMap.keySet());
            
            // Insert Booking
            insert Booking;
            System.debug('✅ Booking inserted with ID: ' + Booking.Id);
            
            // Link Co-Applicants to Booking
            for (Co_Applicant__c co : coApplicants) {
                co.Booking__c = Booking.Id;
            }
            if (!coApplicants.isEmpty()) {
                insert coApplicants;
                System.debug('✅ Co-Applicants inserted: ' + coApplicants.size());
            }
            
            // Update Cost Sheet (Quote__c)
            if (CosSht != null) {
                CosSht.Booking__c = Booking.Id;
                update CosSht;
                System.debug('✅ Cost Sheet updated');
            }
            
            // Save Signature as ContentVersion (if present)
            if (signatureData != null && signatureData.startsWith('data:image')) {
                String base64Data = signatureData.substringAfter(',');
                ContentVersion signature = new ContentVersion();
                signature.Title = 'Customer Signature';
                signature.PathOnClient = 'signature.png';
                signature.VersionData = EncodingUtil.base64Decode(base64Data);
                signature.FirstPublishLocationId = Booking.Id;
                insert signature;
                System.debug('✅ Signature file inserted');
            }
            
            // Save uploaded documents as ContentVersion
            if (uploadedFilesMap != null && !uploadedFilesMap.isEmpty()) {
                List<ContentVersion> contentVersions = new List<ContentVersion>();
                
                for (String key : uploadedFilesMap.keySet()) {
                    Map<String, Object> fileInfo = (Map<String, Object>) JSON.deserializeUntyped(
                        JSON.serialize(uploadedFilesMap.get(key))
                    );
                    String fileName = (String) fileInfo.get('fileName');
                    String base64 = (String) fileInfo.get('base64');
                    
                    if (String.isNotBlank(base64)) {
                        ContentVersion cv = new ContentVersion();
                        cv.Title = fileName;
                        cv.PathOnClient = fileName;
                        cv.VersionData = EncodingUtil.base64Decode(base64);
                        cv.FirstPublishLocationId = Booking.Id;
                        contentVersions.add(cv);
                        System.debug('📎 Prepared ContentVersion: ' + fileName);
                    }
                }
                
                if (!contentVersions.isEmpty()) {
                    insert contentVersions;
                    System.debug('✅ Uploaded files inserted: ' + contentVersions.size());
                }
            }
            
            System.debug('✅ Booking + Related Data saved successfully.');
            
        } catch (Exception e) {
            System.debug('❌ ERROR in InsertSubmissionCSwithSignAndFiles: ' + e.getMessage());
            throw new AuraHandledException('Submission failed: ' + e.getMessage());
        }
    }
	
    @AuraEnabled
    public static void InsertSubmissionCSwithSignAndFiles(Quote__c CosSht,Booking__c Booking,List<Co_Applicant__c> coApplicants,String signatureData,Map<String, Object> uploadedFilesMap){
        try {
            System.debug('➡️ Booking ID before insert: ' + Booking.Id);
            System.debug('➡️ Signature Data Length: ' + (signatureData != null ? signatureData.length() : 0));
            System.debug('➡️ Uploaded Files Keys: ' + uploadedFilesMap.keySet());
            
            // Insert Booking
            insert Booking;
            System.debug('✅ Booking inserted with ID: ' + Booking.Id);
            
            // Link Co-Applicants to Booking
            for (Co_Applicant__c co : coApplicants) {
                co.Booking__c = Booking.Id;
            }
            if (!coApplicants.isEmpty()) {
                insert coApplicants;
                System.debug('✅ Co-Applicants inserted: ' + coApplicants.size());
            }
            
            // Update Cost Sheet (Quote__c)
            if (CosSht != null) {
                CosSht.Booking__c = Booking.Id;
                update CosSht;
                System.debug('✅ Cost Sheet updated');
            }
            
            // --------------------
            // Save Signature
            /*--------------------
            if (signatureData != null && signatureData.startsWith('data:image')) {
                String base64Data = signatureData.substringAfter(',');
                //String signatureTitle = 'Customer Signature - [Signature]';
                
                ContentVersion signature = new ContentVersion();
                signature.Title = 'Signature'; // no extension
                signature.PathOnClient = 'signature.png'; // no extension
                signature.VersionData = EncodingUtil.base64Decode(base64Data);
                signature.FirstPublishLocationId = Booking.Id;
                insert signature;
                System.debug('✅ Signature file inserted: ' + signature.PathOnClient);
            }  --- */
            
            if (String.isNotBlank(signatureData)) {
                System.debug('📌 Received signature data: ' + signatureData);
                
                try {
                    // Extract base64 part after comma
                    String base64Data = signatureData.split(',')[1];
                    
                    Attachment a = new Attachment();
                    a.ParentId = Booking.Id;            // Link to Booking record
                    a.Name = 'Signature.png';
                    a.Body = EncodingUtil.base64Decode(base64Data);
                    a.ContentType = 'image/png';
                    
                    insert a;
                    System.debug('✅ Signature saved as Attachment: ' + a.Id);
                } catch (Exception e) {
                    System.debug('❌ Error saving signature as Attachment: ' + e.getMessage());
                    throw e;
                }
            }

            
            // --------------------
            // Save Uploaded Documents
            // --------------------
            /*
            if (uploadedFilesMap != null && !uploadedFilesMap.isEmpty()) {
                // Map to match data-id to display label
                Map<String, String> fileLabelMap = new Map<String, String>{
                    'primaryAadhaar'  => 'Aadhar Card',
                        'primaryPAN'      => 'Pan Card',
                        'primaryPassport' => 'Passport',
                        'primaryPhoto'    => 'Applicant Photo'
                        };
                            
                            List<ContentVersion> contentVersions = new List<ContentVersion>();
                
                for (String key : uploadedFilesMap.keySet()) {
                    Map<String, Object> fileInfo = (Map<String, Object>) JSON.deserializeUntyped(
                        JSON.serialize(uploadedFilesMap.get(key))
                    );
                    String fileName = (String) fileInfo.get('fileName');
                    String base64   = (String) fileInfo.get('base64');
                    
                    if (String.isNotBlank(base64)) {
                        // Extract extension
                        String fileExt = '';
                        Integer dotIndex = fileName.lastIndexOf('.');
                        if (dotIndex > -1) {
                            fileExt = fileName.substring(dotIndex); // includes dot
                        }
                        
                        // Build display title
                        String label = fileLabelMap.containsKey(key) ? fileLabelMap.get(key) : 'Uploaded File';
                        String titleName = label + ' - [ ' + label + ' ]';
                        
                        ContentVersion cv = new ContentVersion();
                        cv.Title = titleName;                  // e.g., "Aadhar Card - [Aadhar Card]"
                        cv.PathOnClient = titleName + fileExt; // e.g., "Aadhar Card - [Aadhar Card].jpg"
                        cv.VersionData = EncodingUtil.base64Decode(base64);
                        cv.FirstPublishLocationId = Booking.Id;
                        contentVersions.add(cv);
                        
                        System.debug('📎 Prepared ContentVersion: ' + cv.PathOnClient);
                    }
                }
                
                if (!contentVersions.isEmpty()) {
                    insert contentVersions;
                    System.debug('✅ Uploaded files inserted: ' + contentVersions.size());
                }
            }
*/
            
            if (uploadedFilesMap != null && !uploadedFilesMap.isEmpty()) {
                // Map to match data-id to display label
                Map<String, String> fileLabelMap = new Map<String, String>{
                    'primaryAadhaar'  => 'Aadhar Card',
                        'primaryPAN'      => 'Pan Card',
                        'primaryPassport' => 'Passport',
                        'primaryPhoto'    => 'Applicant Photo'
                        };
                            
                            List<ContentVersion> contentVersions = new List<ContentVersion>();
                
                for (String key : uploadedFilesMap.keySet()) {
                    Map<String, Object> fileInfo = (Map<String, Object>) JSON.deserializeUntyped(
                        JSON.serialize(uploadedFilesMap.get(key))
                    );
                    String fileName = (String) fileInfo.get('fileName'); // original filename with extension
                    String base64   = (String) fileInfo.get('base64');
                    
                    if (String.isNotBlank(base64)) {
                        // Extract base name & extension
                        String baseName = fileName;
                        String fileExt = '';
                        Integer dotIndex = fileName.lastIndexOf('.');
                        if (dotIndex > -1) {
                            baseName = fileName.substring(0, dotIndex); // name without extension
                            fileExt = fileName.substring(dotIndex);     // includes dot
                        }
                        
                        // Append label tag
                        String label = fileLabelMap.containsKey(key) ? fileLabelMap.get(key) : 'Uploaded File';
                        String titleName = baseName + ' - [ ' + label + ' ]';
                        
                        ContentVersion cv = new ContentVersion();
                        cv.Title = titleName;                  // e.g., "MyDoc - [Aadhar Card]"
                        cv.PathOnClient = titleName + fileExt; // e.g., "MyDoc - [Aadhar Card].jpg"
                        cv.VersionData = EncodingUtil.base64Decode(base64);
                        cv.FirstPublishLocationId = Booking.Id;
                        contentVersions.add(cv);
                        
                        System.debug('📎 Prepared ContentVersion: ' + cv.PathOnClient);
                    }
                }
                
                if (!contentVersions.isEmpty()) {
                    insert contentVersions;
                    System.debug('✅ Uploaded files inserted: ' + contentVersions.size());
                }
            }
            
            System.debug('✅ Booking + Related Data saved successfully.');
            
        } catch (Exception e) {
            System.debug('❌ ERROR in InsertSubmissionCSwithSignAndFiles: ' + e.getMessage());
            throw new AuraHandledException('Submission failed: ' + e.getMessage());
        }
    }

    
    @AuraEnabled
    public static void  CreateReceiptForAdvancePayment(string CosShtId, string BookingId){
        
        Booking__c Bk = [select id,name,Finance_User__c,(SELECT Id, Amount__c, Pending_Amount__c, S_No__c,Interest_Pending__c FROM Payment_Schedules__r ORDER BY S_No__c ASC ) from Booking__c where Id =: BookingId];
        
        Quote__c cosSht = [select id,name,Booking_Request__c from Quote__c where id =: CosShtId];
        
        if(cosSht != null && cosSht.Booking_Request__c != null){
            Booking_Request__c brq = [select id,IsResponded__c,Unit__c,Email__c,
                                      (select id,Name,Amount__c,Bank__c,Mode_of_Payment__c,Cheque_no_Transaction_Number__c,Receipt_Date__c,Cheque_Date__c,
                                       Amount_Received_Date__c,Approval_Status__c from Advance_Payments__r where Approval_Status__c = 'Approved')
                                      from Booking_Request__c where Id =: cosSht.Booking_Request__c limit 1];
            
            List<Receipt__c> RcptLst = new List<Receipt__c>();
            List<Receipt_Line_Item__c> receiptsToCreate = new List<Receipt_Line_Item__c>();
            List<Id> receiptIds = new List<Id>();
            
            if(!brq.Advance_Payments__r.isEmpty()){
                for(Advance_Payment__c Ap : brq.Advance_Payments__r){
                    Receipt__c rc = new Receipt__c();
                    rc.Remarks__c = 'Advance Payment';
                    rc.Finance_User__c = bk.Finance_User__c;
                    rc.Receipt_date__c = Ap.Receipt_Date__c;
                    rc.Payment_From__c = 'Customer';
                    rc.Check_Transaction_Nmber__c = Ap.Cheque_no_Transaction_Number__c;
                    rc.Amount_received__c = Ap.Amount__c;
                    rc.Mode_of_payment__c = Ap.Mode_of_Payment__c;
                    rc.Approval_status__c = 'Approved by Finance Team';
                    rc.Payment_Received_Bank__c = Ap.Bank__c;
                    rc.Cheque_Date__c = Ap.Cheque_Date__c;
                    rc.Booking__c = BookingId;
                    RcptLst.add(rc);
                }
            }
            insert RcptLst;
            
            for(Receipt__c Rcpt : RcptLst){
                receiptIds.add(Rcpt.Id);
                decimal paidAmount = Rcpt.Amount_received__c;
                if(paidAmount > 0 && !Bk.Payment_Schedules__r.isEmpty()){
                    for (Payment_Schedule__c paymentSchedule : Bk.Payment_Schedules__r) {
                        if (paidAmount <= 0 || paidAmount == null) {
                            break;
                        }
                        if (paymentSchedule.Pending_Amount__c != null && paymentSchedule.Pending_Amount__c > 0) {
                            Decimal amountToReceive = Math.min(paymentSchedule.Pending_Amount__c, paidAmount);
                            paidAmount -= amountToReceive;
                            
                            Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                            rece.Booking__c = bk.Id;
                            rece.Name = 'Against Payment Schedule';
                            rece.Payment_Type__c = 'Payment Schedule';
                            rece.Receipt__c = Rcpt.Id;
                            rece.Payment_Schedule__c = paymentSchedule.Id;
                            rece.Received_Amount__c = amountToReceive;
                            rece.Amount__c = amountToReceive;
                            rece.Bank_Name__c = Rcpt.Payment_Received_Bank__c;
                            rece.Payment_From__c = Rcpt.Payment_From__c;
                            rece.Mode_of_Payment__c =  Rcpt.Mode_of_payment__c;
                            rece.Approval_Status__c = 'Approved by Finance Team';
                            rece.Cheque_no_Transaction_Number__c = Rcpt.Check_Transaction_Nmber__c;
                            rece.Cheque_Date__c = Rcpt.Cheque_Date__c;
                            receiptsToCreate.add(rece);
                        }
                    }
                }
                if(paidAmount !=null && paidAmount > 0){
                    Integer PaymentScheduleSize = Bk.Payment_Schedules__r.size();
                    Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                    rece.Booking__c = bk.Id;
                    rece.Name = 'Against Payment Schedule';
                    rece.Payment_Type__c = 'Payment Schedule';
                    rece.Receipt__c = Rcpt.Id;
                    rece.Payment_Schedule__c = Bk.Payment_Schedules__r[PaymentScheduleSize-1].Id;
                    rece.Received_Amount__c = paidAmount;
                    rece.Amount__c = paidAmount;
                    rece.Bank_Name__c = Rcpt.Payment_Received_Bank__c;
                    rece.Payment_From__c = Rcpt.Payment_From__c;
                    rece.Mode_of_Payment__c =  Rcpt.Mode_of_payment__c;
                    rece.Approval_Status__c = 'Approved by Finance Team';
                    rece.Cheque_no_Transaction_Number__c = Rcpt.Check_Transaction_Nmber__c;
                    rece.Cheque_Date__c = Rcpt.Cheque_Date__c;
                    receiptsToCreate.add(rece);
                }
            }
            if (!receiptsToCreate.isEmpty()) {
                upsert receiptsToCreate;
            }
            
            ReceiptController.approvedReceiptsHandler(receiptIds);
        }
        
        
        
    }
    
    @AuraEnabled
    public static void InsertBookingReq(Booking_Request__c BookingReqt, Advance_Payment__c payment){
        
        system.debug('BookingReqt >> '+ BookingReqt);
        system.debug('payment >> '+ payment);
        
        upsert BookingReqt;
        upsert payment;
        
        Booking_Request__c rec = [select id,ownerid,name from Booking_Request__c where id =: BookingReqt.id];
        CustomNotificationType ResponseNotify;
        ResponseNotify = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Booking_Request_Responded_Notify' LIMIT 1];
        
        Messaging.CustomNotification Notification = new Messaging.CustomNotification();
        Notification.setTitle('Booking Request Update'); 
        Notification.setBody('Booking request ' + rec.Name + ' has been submitted.'); 
        Notification.setNotificationTypeId(ResponseNotify.id); 
        Notification.setSenderId(Userinfo.getUserId()); 
        Notification.setTargetId(BookingReqt.Id); 
        Notification.send(new Set<String>{ rec.OwnerId });
        /*
        Booking_Request__c bkr = new Booking_Request__c();
        bkr.Customer_Comments__c = BookingReqt.Customer_Comments__c;
        bkr.Customer_Name__c = BookingReqt.Customer_Name__c;
        bkr.Unit__c = BookingReqt.Unit__c;
        bkr.Mobile__c = BookingReqt.Mobile__c;
        bkr.Aadhaar_Number__c = BookingReqt.Aadhaar_Number__c;
        bkr.PAN_Number__c = BookingReqt.PAN_Number__c;
        insert bkr;*/
    }
    
    public static void cancelPendingAdvanceApprovals(Set<Id> bookingRequestIds) {
        // Fetch advance payments linked to those booking requests
        List<Advance_Payment__c> advancePayments = [SELECT Id FROM Advance_Payment__c WHERE Booking_Request__c IN :bookingRequestIds];
        
        if (advancePayments.isEmpty()) return;
        
        // Fetch process instances (approval processes) for these advance payments
        List<ProcessInstance> processInstances = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId IN :advancePayments AND Status = 'Pending'];
        
        if (processInstances.isEmpty()) return;
        
        // Fetch the work items (steps) of those approval processes
        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId, ActorId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId IN :processInstances];
        
        // Cancel each approval request by removing the step
        for (ProcessInstanceWorkitem item : workItems) {
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
            pwr.setAction('Reject'); // Rejects the approval step
            pwr.setWorkitemId(item.Id);
            pwr.setComments('Rejected as Booking was created'); // Adds the comment
            Approval.ProcessResult result = Approval.process(pwr);
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getTermsContent() {
        Terms_and_Conditions__mdt terms = [
            SELECT Terms__c 
            FROM Terms_and_Conditions__mdt 
            LIMIT 1
        ];
        return terms.Terms__c;
    }

    
    
}