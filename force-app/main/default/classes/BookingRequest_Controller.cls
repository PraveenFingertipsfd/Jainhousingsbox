public without sharing class BookingRequest_Controller {
    @AuraEnabled
    public static string send_Booking_Request(string recordId, string EmailId, Integer BlockedPrice){
        
        try{
            Booking_Request__c bk = new Booking_Request__c();
            bk.Unit__c = recordId;
            bk.Email__c = EmailId;
            bk.Blocked_Price__c = BlockedPrice;
            bk.Email_Sent_Date_Time__c = system.now();
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
            
            /*string  htmlBody='Dear Customer,<br/><br/>Thank you for choosing Jain Housing. We have attached a Hyperlink to fill and submit a booking request. <br/>To Open the Booking requisition page, please click on the link below. <br/>'+
                '<a href="'+urlval+'/'+ mySite.UrlPathPrefix +'?Id='+recordId+'&BkReqId='+bk.Id+'">Click here to request for Booking</a><br/>'+
                'We pride ourselves on providing high-quality Constructions, and we are confident that you will be completely satisfied with the results.<br/> If you have any questions or concerns, please don\'t hesitate to contact us. We are always happy to help.<br/><br/>'+'Thank you<br/>Jain Housing';*/
            String htmlBody = 'Dear Customer,<br/><br/>' +
                'Thank you for choosing Jain Housing to purchase your dream home. We are truly delighted to be part of this important milestone in your life.<br/><br/>' +
                'With over three decades of trusted experience in South India, Jain Housing is committed to delivering quality homes and exceptional service. It is our privilege to assist you on this exciting journey.<br/><br/>' +
                'To continue with the booking, please click the link below to fill in your basic details and make the booking advance:<br/><br/>' +
                '<a href="' + urlval + '/' + mySite.UrlPathPrefix + '?Id=' + recordId + '&BkReqId=' + bk.Id + '">Click here to proceed with the booking</a><br/><br/>' +
                'If you have any questions or need assistance, feel free to reach out to our Sales Team.<br/><br/>' +
                'Warm regards,<br/>' +
                'Sales Team<br/>' +
                '<strong>Team Jain Housing</strong>';

            string email = EmailId;
            //semail.setSubject('Jain Housing\'s Booking Request Page');
            semail.setSubject('Welcome to Jain Housing – Let\'s Get Started on Your Dream Home!');
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
    
    
    public class UnitWrapper{
        @AuraEnabled 
        public Plot__c UnitRec {get; set;}
        @AuraEnabled 
        public Boolean IsFormResponded {get; set;}
        @AuraEnabled 
        public String BkrqStatus {get; set;}
    }
    
    @AuraEnabled
    public static UnitWrapper GetUnitDetails(string recordId, string BkreqId){
        UnitWrapper utwrp = new UnitWrapper();
        Booking_Request__c bkrq = [select id,IsResponded__c,Stage__c from Booking_Request__c where Id =: BkreqId limit 1];
        Plot__c pt = [select id,name,Plot_Number__c,Project__c,Project__r.Name,Status__c,Block1__c,Block1__r.Name,BHK_Type__c,Floor__c,Facing__c,Is_PSA_Unit__c,Super_built_up_area__c,Price_Per_Sq_Ft__c,Basic_Sale_Price_Rs__c,Total__c from Plot__c where id =: recordId];
        
        if(pt != null)
            utwrp.UnitRec = pt;
        if(bkrq != null){
            utwrp.IsFormResponded = bkrq.IsResponded__c;
            utwrp.BkrqStatus = bkrq.Stage__c;
        }
        return  utwrp;
    }
    
    @AuraEnabled
    public static Boolean check_IsPSA(string recordId){
        string UnitName = [select id,name from Plot__c where Id =: recordId limit 1].Name;
        return UnitName != null && UnitName.containsIgnoreCase('PSA');
    }
    
    @AuraEnabled
    public static Boolean check_EmailExists(string recordId){
        Booking_Request__c brq = [select id,IsResponded__c,Unit__c,Email__c,Email_Sent_Date_Time__c from Booking_Request__c where Id =: recordId limit 1];
        brq.Email_Sent_Date_Time__c = system.now();
        update brq;
        
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
        
        // Get Payment Mode picklist values
        List<String> paymentModes = new List<String>();
        Schema.DescribeFieldResult paymentModeField = Advance_Payment__c.Mode_of_Payment__c.getDescribe();
        for (Schema.PicklistEntry entry : paymentModeField.getPicklistValues()) {
            paymentModes.add(entry.getValue());
        }
        picklistValues.put('paymentModes', paymentModes);
        
        // Get Bank picklist values
        List<String> banks = new List<String>();
        Schema.DescribeFieldResult bankField = Advance_Payment__c.Bank__c.getDescribe();
        for (Schema.PicklistEntry entry : bankField.getPicklistValues()) {
            banks.add(entry.getValue());
        }
        picklistValues.put('banks', banks);
        
        return picklistValues;
    }
    
    @AuraEnabled
    public static void InsertBookingReq(Booking_Request__c BookingReqt, Advance_Payment__c payment){
        
        system.debug('BookingReqt >> '+ BookingReqt);
        system.debug('payment >> '+ payment);
        
        BookingReqt.Customer_Responded_Date__c = system.now();
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
    
	 
    @AuraEnabled
    public static AbandonResult abandonBookingRequest(String bookingRequestId) {
        AbandonResult result = new AbandonResult();
        result.isSuccess = false;
        Set<Id> bookingRequestIds = new Set<Id>{bookingRequestId};
        
        try {
            // Check if user has permission to update records
            if (!Schema.sObjectType.Booking_Request__c.isUpdateable() || 
                !Schema.sObjectType.Quote__c.isUpdateable()) {
                result.errorMessage = 'You do not have permission to update records.';
                return result;
            }
            
            // Query the booking request first
            Booking_Request__c br = [
                SELECT Id, Stage__c ,Request_Abandoned_Date__c
                FROM Booking_Request__c 
                WHERE Id = :bookingRequestId 
                LIMIT 1
            ];
            
            // Then query related cost sheets (quotes)
            List<Quote__c> relatedQuotes = new List<Quote__c>();
            
            if (Schema.sObjectType.Quote__c.fields.Booking_Request__c.isAccessible()) {
                relatedQuotes = [
                    SELECT Id, Status__c,Cost_Sheet_Abandoned_Date__c 
                    FROM Quote__c 
                    WHERE Booking_Request__c IN :bookingRequestIds
                ];
            }
            
            // Update booking request stage
            br.Stage__c = 'Request Abandoned';
            br.Request_Abandoned_Date__c = system.now();
            
            // Prepare quotes to update
            List<Quote__c> quotesToUpdate = new List<Quote__c>();
            for (Quote__c quote : relatedQuotes) {
                quote.Status__c = 'Abandoned';
                quote.Cost_Sheet_Abandoned_Date__c = system.now();
                quotesToUpdate.add(quote);
            }
            
            // Start transaction
            Savepoint sp = Database.setSavepoint();
            
            try {
                // Update booking request
                update br;
                
                // Update related quotes if they exist
                if (!quotesToUpdate.isEmpty()) {
                    update quotesToUpdate;
                }
                
                // Cancel any pending approval processes for these quotes
                if (!relatedQuotes.isEmpty()) {
                    cancelPendingApprovals(relatedQuotes, 'Cancelled due to abandonment of booking request');
                }
                
                result.isSuccess = true;
            } catch (Exception e) {
                // Rollback on error
                Database.rollback(sp);
                result.errorMessage = 'Error updating records: ' + e.getMessage();
            }
            
        } catch (Exception e) {
            result.errorMessage = 'Error: ' + e.getMessage();
        }
        
        return result;
    }
    
    // Reusable method to cancel pending approvals (based on your reference code)
    private static void cancelPendingApprovals(List<Quote__c> quotes, String comment) {
        Set<Id> quoteIds = new Set<Id>();
        for (Quote__c quote : quotes) {
            quoteIds.add(quote.Id);
        }
        
        // Fetch process instances (approval processes) for these quotes
        List<ProcessInstance> processInstances = [
            SELECT Id, TargetObjectId 
            FROM ProcessInstance 
            WHERE TargetObjectId IN :quoteIds AND Status = 'Pending'
        ];
 
        if (processInstances.isEmpty()) return;

        // Fetch the work items (steps) of those approval processes
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id, ProcessInstanceId, ActorId 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstanceId IN :processInstances
        ];

        // Cancel each approval request by removing the step
        List<Approval.ProcessWorkitemRequest> approvalRequests = new List<Approval.ProcessWorkitemRequest>();
        for (ProcessInstanceWorkitem item : workItems) {
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
            pwr.setAction('Removed'); // Removes the approval step
            pwr.setWorkitemId(item.Id);
            pwr.setComments(comment);
            approvalRequests.add(pwr);
        }
        
        if (!approvalRequests.isEmpty()) {
            try {
                List<Approval.ProcessResult> results = Approval.process(approvalRequests);
            } catch (Exception e) {
                System.debug('Error cancelling approvals: ' + e.getMessage());
            }
        }
    }
    
    public class AbandonResult {
        @AuraEnabled public Boolean isSuccess {get; set;}
        @AuraEnabled public String errorMessage {get; set;}
    }
    
}