trigger CostSheetTrigger on Quote__c (before update, after insert, after update, after delete, after undelete) {
    
    // ========== BEFORE UPDATE LOGIC (Existing Functionality) ==========
    if (Trigger.isBefore && Trigger.isUpdate) {
        Map<string,string> csBkrqMap = new Map<string,string>();
        
        for(Quote__c cs : trigger.new){
            // Discount validation logic
            if(cs.Discount_Price__c != trigger.oldmap.get(cs.Id).Discount_Price__c && cs.Price_Per_Sq_Ft__c != null){
                if(cs.Discount_Price__c > cs.Price_Per_Sq_Ft__c){
                    cs.Discount_Price__c.addError('Discount Price can\'t be greater than Price per Sqft');
                }
                else{
                    cs.Final_Price_Per_Sq_ft__c = cs.Price_Per_Sq_Ft__c - cs.Discount_Price__c;
                }
            }
            
            // For Sending Booking Form to Customer
            if(cs.Approval_Status__c != trigger.oldmap.get(cs.Id).Approval_Status__c && 
               cs.Approval_Status__c == 'Management Approved' && 
               cs.Booking_Request__c != null){
                   
                   // Reset the form flag when sending link again - added by karthik 26-07
                   cs.Is_Form_Responded__c = false;
                   
                   cs.Email_Sent_Date_Time__c = system.now();
                   csBkrqMap.put(cs.Id,cs.Booking_Request__c);
               }
        }
        
        // Send emails if needed
        if(!csBkrqMap.Isempty()){
            Map<Id,Booking_Request__c> bkrqMap = new Map<Id,Booking_Request__c>([select Id,Email__c from Booking_Request__c where Id in : csBkrqMap.values()]);
            
            list<Messaging.SingleEmailMessage> message= new  list<Messaging.SingleEmailMessage>();
            
            for(string CosSheetId : csBkrqMap.keyset()){
                string CusEmail;
                if(bkrqMap.containsKey(csBkrqMap.get(CosSheetId))){
                    CusEmail = bkrqMap.get(csBkrqMap.get(CosSheetId)).Email__c;
                }
                
                Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
                string urlval = label.Org_url;
                Site mySite = [SELECT Id, Name, Subdomain, UrlPathPrefix FROM Site WHERE Name = 'Booking_Fill_Site' LIMIT 1];
                /*string  htmlBody='Dear Customer,<br/><br/>Thank you for choosing Jain Housing. We have attached a Hyperlink to fill and submit the Booking Form. <br/>To Open the Booking Form page, please click on the link below. <br/>'+
                    '<a href="'+urlval+'/'+ mySite.UrlPathPrefix +'?Id='+CosSheetId+'&BkReqId='+csBkrqMap.get(CosSheetId)+'">Click here to Fill for Booking Form</a><br/>'+
                    'We pride ourselves on providing high-quality Constructions, and we are confident that you will be completely satisfied with the results.<br/> If you have any questions or concerns, please don\'t hesitate to contact us. We are always happy to help.<br/><br/>'+'Thank you<br/>Jain Housing';*/
                //semail.setSubject('Jain Housing\'s Booking Request Page');
                String htmlBody = 'Dear Customer,<br/><br/>' +
                    'Greetings from Jain Housing!<br/><br/>' +
                    'Thank you for choosing Jain Housing as your trusted partner in finding your dream home. We are pleased to share with you the Booking Allotment Form and the Payment Schedule form related to your flat booking.<br/><br/>' +
                    'Please find the attached documents for your reference:<br/><br/>' +
                    '<strong>Booking Allotment Form</strong><br/>' +
                    '<strong>Payment Schedule / Cashflow Form</strong><br/><br/>' +
                    'These documents contain important details regarding your flat allotment and the associated payment structure. We kindly request you to review them thoroughly and adhere. Get in touch with us in case you have any queries or require further clarification.<br/><br/>' +
                    'To access and fill the Booking Form online, please click the link below:<br/><br/>' +
                    '<a href="' + urlval + '/' + mySite.UrlPathPrefix + '?Id=' + CosSheetId + '&BkReqId=' + csBkrqMap.get(CosSheetId) + '">Click here to Fill the Booking Form</a><br/><br/>' +
                    'We look forward to assisting you throughout your home-buying journey.<br/><br/>' +
                    'Warm regards,<br/>' +
                    'Customer Relations Team<br/>' +
                    '<strong>Jain Housing LLP.</strong>';
                semail.setSubject('Booking Allotment Form & Cash Flow Details – Jain Housing');
                semail.setToAddresses(new String[]{CusEmail});
                semail.setHtmlBody(htmlBody);
                message.add(semail);
            }
            Messaging.sendEmail(message);
        }
    }
    
    // ========== AFTER EVENTS LOGIC (New Functionality) ==========
    if (Trigger.isAfter) {
        // Handle after insert and after undelete - set checkbox based on stage
        if (Trigger.isInsert || Trigger.isUndelete) {
            Set<Id> bookingRequestIds = new Set<Id>();
            
            // Collect all related Booking Request IDs
            for (Quote__c costSheet : Trigger.new) {
                if (costSheet.Booking_Request__c != null && costSheet.Status__c != 'Abandoned') {
                    bookingRequestIds.add(costSheet.Booking_Request__c);
                }
            }
            
            if (!bookingRequestIds.isEmpty()) {
                CostSheetTriggerHandler.updateBookingRequests(bookingRequestIds, true);
            }
        }
        
        // Handle after update - check if stage changed to/from Abandoned
        if (Trigger.isUpdate) {
            Set<Id> bookingRequestIdsToTrue = new Set<Id>();
            Set<Id> bookingRequestIdsToFalse = new Set<Id>();
            
            for (Quote__c costSheet : Trigger.new) {
                Quote__c oldCostSheet = Trigger.oldMap.get(costSheet.Id);
                
                // Check if stage changed
                if (costSheet.Booking_Request__c != null && 
                    costSheet.Status__c != oldCostSheet.Status__c) {
                        
                        // Changed from Abandoned to something else
                        if (oldCostSheet.Status__c == 'Abandoned' && costSheet.Status__c != 'Abandoned') {
                            bookingRequestIdsToTrue.add(costSheet.Booking_Request__c);
                        }
                        // Changed to Abandoned
                        else if (costSheet.Status__c == 'Abandoned') {
                            bookingRequestIdsToFalse.add(costSheet.Booking_Request__c);
                        }
                    }
            }
            
            if (!bookingRequestIdsToTrue.isEmpty()) {
                CostSheetTriggerHandler.updateBookingRequests(bookingRequestIdsToTrue, true);
            }
            if (!bookingRequestIdsToFalse.isEmpty()) {
                CostSheetTriggerHandler.updateBookingRequests(bookingRequestIdsToFalse, false);
            }
        }
        
        // Handle after delete - set checkbox to false if no other active Cost Sheets exist
        if (Trigger.isDelete) {
            Set<Id> bookingRequestIds = new Set<Id>();
            
            // Collect all related Booking Request IDs from deleted non-abandoned quotes
            for (Quote__c costSheet : Trigger.old) {
                if (costSheet.Booking_Request__c != null && costSheet.Status__c != 'Abandoned') {
                    bookingRequestIds.add(costSheet.Booking_Request__c);
                }
            }
            
            if (!bookingRequestIds.isEmpty()) {
                // Check remaining active quotes for these booking requests
                Map<Id, Integer> activeQuoteCountMap = new Map<Id, Integer>();
                for (AggregateResult ar : [
                    SELECT Booking_Request__c, COUNT(Id) quoteCount
                    FROM Quote__c
                    WHERE Booking_Request__c IN :bookingRequestIds
                    AND Status__c != 'Abandoned'
                    GROUP BY Booking_Request__c
                ]) {
                    activeQuoteCountMap.put((Id)ar.get('Booking_Request__c'), (Integer)ar.get('quoteCount'));
                }
                
                // Identify booking requests with no active quotes remaining
                Set<Id> requestsToUpdateIds = new Set<Id>();
                for (Id reqId : bookingRequestIds) {
                    Integer count = activeQuoteCountMap.get(reqId);
                    if (count == null || count == 0) {
                        requestsToUpdateIds.add(reqId);
                    }
                }
                
                // Use handler method to update
                if (!requestsToUpdateIds.isEmpty()) {
                    CostSheetTriggerHandler.updateBookingRequests(requestsToUpdateIds, false);
                }
            }
        }
    }
}