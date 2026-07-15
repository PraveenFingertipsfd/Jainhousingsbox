public without sharing class CSAT_Controller {
 
    @AuraEnabled
    public static Map<String, Object> BookingDetails(String bookingId) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            
            Booking__c bk = [SELECT Id,Email1__c,Alternate_Email1__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
            
            if (bk == null ) {
                throw new AuraHandledException('No  Booking found ');
            }
            
            // Populate email options
            List<String> emailOptions = new List<String>();
            if (String.isNotBlank(bk.Email1__c)) {
                emailOptions.add(bk.Email1__c);
            }
            if (String.isNotBlank(bk.Alternate_Email1__c)) {
                emailOptions.add(bk.Alternate_Email1__c);
            }
            
            
            result.put('emailOptions', emailOptions);
            //result.put('bookingId', inspection.Booking__c); // Store the booking ID for later use
            result.put('bookingId',bk.Id);
        } catch(Exception e) {
            throw new AuraHandledException('Error getting booking details: ' + e.getMessage());
        }
        return result;
    }
    
    
    @AuraEnabled
    public static void sendRFB(String bookingId, String emailAddress) {
        try {
            // Validate email
            if (!Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', emailAddress)) {
                throw new IllegalArgumentException('Invalid email address format');
            }
            
            Booking__c bk = [SELECT Id,Email1__c,FeedBack_Sent_Date__c,Alternate_Email1__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
            
            if (bk == null) {
                throw new AuraHandledException('booking record not found');
            }
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            string urlval = label.Org_url;
            Site mySite = [SELECT Id, Name, Subdomain, UrlPathPrefix FROM Site WHERE Name = 'CSAT_Form' LIMIT 1];
            String htmlBody = 'Dear Customer,<br/><br/>' +
                'Thank you for choosing Jain Housing. We have provided a secure hyperlink for you to fill out and submit the <strong>Registration Feedback Form</strong>.<br/><br/>' +
                'To access the form, please click the link below:<br/>' +
                '<a href="' + urlval + '/' + mySite.UrlPathPrefix + '?Id=' + bk.id + '">Click here to fill the Registration Feedback Form</a><br/><br/>' +
                'We are committed to delivering high-quality construction and customer service. Your feedback is very important to us.<br/><br/>' +
                'If you have any questions or need assistance, please don\'t hesitate to contact us.<br/><br/>' +
                'Thank you,<br/>' +
                '<strong>Jain Housing</strong>';
            email.setToAddresses(new List<String>{emailAddress});
            email.setSubject('Registration Feedback Form');
            email.setHtmlBody(htmlBody);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
			
            bk.FeedBack_Sent_Date__c = DateTime.now();
            update bk;
			

        } catch(Exception e) {
            throw new AuraHandledException('Error sending invitation: ' + e.getMessage());
        }
    }
    
    //csat
    @AuraEnabled
    public static Booking__c getBookingDetails(Id recId) {
        try {
            List<Booking__c> bkList = [SELECT Id,Is_FB_Responded__c,Owner.Name,Name,First_Applicant_Name__c,Project__c,Plot__r.Name,Booking_Date__c,Registration_Date__c FROM Booking__c WHERE Id = :recId LIMIT 1];
           
            if (!bkList.isEmpty()) {
                return bkList[0];
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        return null;
    }
    
    @AuraEnabled
    public static void saveFeedback(Id bookingId, List<Map<String, String>> responses, String signatureData,String desiredImprovements,String encouragementFactors) {
        try {
            // 1. Update Booking record
            Booking__c booking = new Booking__c(
                Id = bookingId,
                Is_FB_Responded__c = true
                
            );
            update booking;
            
            DateTime dt = [select FeedBack_Sent_Date__c from Booking__c where id =: bookingId].FeedBack_Sent_Date__c;
            
            // 2. Create Feedback record
            Feedback__c feedback = new Feedback__c();
            feedback.Booking__c = bookingId;
            feedback.FBQ20__c = encouragementFactors;
            feedback.FBQ19__c = desiredImprovements;
            feedback.FeedBack_Responded_Date__c = DateTime.now();
            feedback.FeedBack_Sent_Date__c = dt;
            
            // Set all feedback fields from responses
            for (Map<String, String> response : responses) {
                String field = response.get('field');
                String value = response.get('value');
                
                if (field != null && value != null) {
                    feedback.put(field, value);
                }
            }
            
            insert feedback;
            
            
            
            // 3. Create Attachment for signature
            if (String.isNotBlank(signatureData)) {
                // Extract base64 part from data URL
                String base64Data = signatureData.substring(signatureData.indexOf(',') + 1);
                
                Attachment signatureAttachment = new Attachment();
                signatureAttachment.Name = 'CustomerSignature.png';
                signatureAttachment.Body = EncodingUtil.base64Decode(base64Data);
                signatureAttachment.ParentId = feedback.Id;
                signatureAttachment.ContentType = 'image/png';
                
                insert signatureAttachment;
            }
            
        } catch(Exception e) {
            throw new AuraHandledException('Error saving feedback: ' + e.getMessage());
        }
    }
    
    
    
}