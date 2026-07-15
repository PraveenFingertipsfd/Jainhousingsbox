public with sharing class JointInspectionController {
    @AuraEnabled
    public static String createJointInspection(String recordId) {
        try {
           // Get Booking with Project and Site Engineer info
            List<Booking__c> bookings = [SELECT Id, Name, Plot__c,Email1__c,Alternate_Email1__c,Plot__r.QA_Given__c,Project1__c,Project1__r.Site_Engineer__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
                						 
             if (bookings.isEmpty()) {
                 return 'ERROR: Booking record not found';
                //throw new IllegalArgumentException('Booking record not found');
            }           
                       
            Booking__c booking = bookings[0];       
            
            // Validate QA is given
            if (booking.Plot__r == null || booking.Plot__r.QA_Given__c != true) {
                return 'TOAST: QA not done for this unit';
            }
               
            // Validate Project exists
            if (booking.Project1__c == null) {
                return 'ERROR: Booking is not associated with a Project';
                //throw new IllegalArgumentException('Booking is not associated with a Project');
            }
            
            // Validate Site Engineer exists
            if (booking.Project1__r.Site_Engineer__c == null) {
                return 'ERROR: Project is missing Site Engineer assignment';
                //throw new IllegalArgumentException('Project is missing Site Engineer assignment');
            }
            
            // Check for existing Joint Inspections
            List<Joint_Inspection__c> existingInspections = [SELECT Id, Joint_Inspection_Status__c FROM Joint_Inspection__c  WHERE Booking__c = :booking.Id];
            
            // Filter out completed or cancelled inspections
            List<Joint_Inspection__c> activeInspections = new List<Joint_Inspection__c>();
            for (Joint_Inspection__c ji : existingInspections) {
                if (ji.Joint_Inspection_Status__c != 'Completed' && ji.Joint_Inspection_Status__c != 'Cancelled') {
                    activeInspections.add(ji);
                }
            }
            
            if (!activeInspections.isEmpty()) {
                return 'TOAST: An active Joint Inspection already exists for this booking';
                //throw new IllegalArgumentException('An active Joint Inspection already exists for this booking');
            }
            

            // Create new Joint Inspection record - modified by karthik 29-07
            Joint_Inspection__c ji = new Joint_Inspection__c(Booking__c = booking.Id, Site_Engineer__c = booking.Project1__r.Site_Engineer__c,Invite_Sent_Date_Time__c = System.now());
            
            insert ji;
            System.debug('Created record with ID: ' + ji.Id);
            
            // Collect emails - primary + alternate (if available)
            List<String> emailList = new List<String>();
            if (String.isNotBlank(booking.Email1__c)) {
                emailList.add(booking.Email1__c);
            }
            if (String.isNotBlank(booking.Alternate_Email1__c)) {
                emailList.add(booking.Alternate_Email1__c);
            }
            
            // Send invite to each email
            for (String emailAddress : emailList) {
                sendJointInspectionInvite(ji.Id, emailAddress);
            }

            
            return ji.Id;
        } catch(Exception e) {
            throw new AuraHandledException('Error creating Joint Inspection: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static Map<String, Object> jointInspectionDetails(String jointInspectionId) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            // First get the Joint Inspection record with its Booking reference
            Joint_Inspection__c inspection = [SELECT Id, Booking__c, Booking__r.Plot__c,Booking__r.Plot__r.Name, Booking__r.Email1__c, 
                                              Booking__r.Alternate_Email1__c FROM Joint_Inspection__c WHERE Id = :jointInspectionId LIMIT 1];
                                              
                                              
                                              
            
            if (inspection == null || inspection.Booking__c == null) {
                throw new AuraHandledException('No related Booking found for this Joint Inspection');
            }
            
            String unitName = '';
            if (inspection.Booking__r.Plot__r != null) {
                unitName = inspection.Booking__r.Plot__r.Name;
            }
            
            // Populate email options
            List<String> emailOptions = new List<String>();
            if (String.isNotBlank(inspection.Booking__r.Email1__c)) {
                emailOptions.add(inspection.Booking__r.Email1__c);
            }
            if (String.isNotBlank(inspection.Booking__r.Alternate_Email1__c)) {
                emailOptions.add(inspection.Booking__r.Alternate_Email1__c);
            }
            
            result.put('unitName', unitName);
            result.put('emailOptions', emailOptions);
            //result.put('bookingId', inspection.Booking__c); // Store the booking ID for later use
            result.put('inspectionId',inspection.Id);
        } catch(Exception e) {
            throw new AuraHandledException('Error getting booking details: ' + e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled
    public static void sendJointInspectionInvite(String inspectionId, String emailAddress) {
        try {
            // Validate email
            if (!Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', emailAddress)) {
                throw new IllegalArgumentException('Invalid email address format');
            }
            
            // Get inspection details with related booking and plot info
            Joint_Inspection__c inspection = [SELECT Id, Name, Booking__r.Plot__r.Name, Booking__r.First_Applicant_Name__c,Booking__r.Project1__r.Name, Booking__r.Email1__c,Booking__r.Alternate_Email1__c
                                              FROM Joint_Inspection__c WHERE Id = :inspectionId LIMIT 1];
            
            if (inspection == null) {
                throw new AuraHandledException('Inspection record not found');
            }
            
            // Generate the scheduling link
            String baseUrl = 'https://jainhousing--sbox1.sandbox.my.salesforce-sites.com/jointInspection';
            String schedulingLink = baseUrl + '/JointInspectionScheduling?id=' + inspection.Id;
            
            /* HTML Email Body
            String htmlBody = '<!DOCTYPE html><html><body style="font-family:Arial,sans-serif;">' +
                '<p>Dear ' + inspection.Booking__r.First_Applicant_Name__c  + ',</p>' +
                '<p>Please schedule your joint inspection for Unit - <strong>' + inspection.Booking__r.Plot__r.Name + '</strong> by clicking the button below:</p>' +
                '<p><a href="' + schedulingLink + '" style="background:#0070d2;color:white;padding:10px 20px;text-decoration:none;border-radius:4px;">Schedule Now</a></p>' +
                '<p>This link will expire in 7 days.</p>' +
                '<p>Best regards,<br/>Jain Housing Team</p>' +
                '</body></html>';
*/
             
            String htmlbody = 'Dear ' + inspection.Booking__r.First_Applicant_Name__c + ',<br/><br/>' +
                
                'Greetings from <strong>Jain Housing!</strong><br/><br/>' +
                
                'We are delighted to inform you that your flat is now ready for handover. ' +
                'As part of our customer handover process, we request you to kindly schedule a joint inspection of your flat along with our site engineer. ' +
                'This step ensures that everything meets your expectations before you take possession.<br/><br/>' +
                
                // Center-aligned button
                '<div style="text-align:center; margin: 20px 0;">' +
                '<a href="' + schedulingLink + '" ' +
                'style="background:#0070d2;color:white;padding:12px 24px;text-decoration:none;border-radius:4px;font-weight:bold;display:inline-block;">' +
                'Click here to Schedule Now</a>' +
                '</div>' +
                
                'Once you are satisfied with the condition of your home, you will be asked to sign the <strong>Customer Satisfaction Report (CSR)</strong> ' +
                'as a confirmation of satisfactory handover.<br/><br/>' +
                
                'If you observe any snags during the inspection, we request you to share the snag points with us. ' +
                'Our team will address them within <strong>15 working days</strong>, depending on the nature and complexity of the work.<br/><br/>' +
                
                'We also request you to kindly be prepared to release the final handover payments as part of the possession formalities. ' +
                'This will allow us to process your <strong>No Due Certificate</strong> and complete the final documentation smoothly.<br/><br/>' +
                
                'Please note that the <strong>CP and sanitary fittings, as well as the final coat of paint</strong>, ' +
                'will be carried out <strong>only after 100% payment is received and the No Due Certificate is issued</strong>. ' +
                'We appreciate your understanding and cooperation in this regard.<br/><br/>' +
                
                'To proceed, please schedule your joint inspection appointment through the <strong>Customer Portal/Mobile app</strong>, ' +
                'where you can choose a convenient date and time from the options given.<br/><br/>' +
                
                'If you need any assistance in accessing the portal or booking your appointment, our CRM Executive will be happy to help.<br/><br/>' +
                
                'Thank you once again for choosing <strong>Jain Housing</strong>. ' +
                'We truly value your trust in us and look forward to welcoming you to your new home. ' +
                'Wishing you and your family a happy and prosperous life ahead!<br/><br/>' +
                
                'Warm regards,<br/>' +
                '<strong>Team Jain Housing</strong><br/>';

            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{emailAddress});
            email.setSubject('Your Flat is Ready for Handover – Invitation for Joint Inspection');
            email.setHtmlBody(htmlbody);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
            // Update inspection with sent timestamp
            inspection.Invite_Sent_Date_Time__c = DateTime.now();
            update inspection;
        
            
        } catch(Exception e) {
            throw new AuraHandledException('Error sending invitation: ' + e.getMessage());
        }
    }
    
    /*
    @AuraEnabled //for updae
    public static InspectionDetails getInspectionDetails(String recordId) {
        InspectionDetails details = new InspectionDetails();
        
        try {
            // Query the Joint Inspection record and related unit information
            Joint_Inspection__c inspection = [
                SELECT Id, Name, Joint_Inspection_Status__c,Booking__r.Plot__r.Name
                FROM Joint_Inspection__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            details.inspectionId = inspection.Id;
            details.currentStatus = inspection.Joint_Inspection_Status__c;
            details.unitName = inspection.Booking__r.Plot__r.Name;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving inspection details: ' + e.getMessage());
        }
        
        return details;
    }
    
    @AuraEnabled
    public static void updateInspectionStatus(
        String inspectionId, 
        String newStatus, 
        String comments,
        String rescheduledReason,
        String rescheduledDatetime,
        String cancelledReason,
        String cancelledDatetime
    ) {
        try {
            Joint_Inspection__c inspection = new Joint_Inspection__c(Id = inspectionId);
            inspection.Joint_Inspection_Status__c = newStatus;
            
            // Handle different status transitions
            if (newStatus == 'Completed') {
                inspection.Comments__c = comments;
                inspection.Joint_Inspection_Completed_Date__c = System.now();
            } 
            else if (newStatus == 'Re-Scheduled') {
                inspection.Rescheduled_Reason__c = rescheduledReason;
                inspection.Rescheduled_Date__c = (DateTime)JSON.deserialize(rescheduledDatetime, DateTime.class);
                inspection.Joint_Inspection_Date__c = null; // Clear original inspection date
            } 
            else if (newStatus == 'Cancelled') {
                inspection.Cancelled_Reason__c = cancelledReason;
                inspection.Cancelled_Date__c = (DateTime)JSON.deserialize(cancelledDatetime, DateTime.class);
            }
            
            update inspection;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating inspection status: ' + e.getMessage());
        }
    }
    
    // Wrapper class to return inspection details
    public class InspectionDetails {
        @AuraEnabled public String inspectionId { get; set; }
        @AuraEnabled public String currentStatus { get; set; }
        @AuraEnabled public String unitName { get; set; }
    }*/
     @AuraEnabled //for update jins status component
    public static InspectionDetails getInspectionDetails(String recordId) {
        InspectionDetails details = new InspectionDetails();
        
        try {
            // Query the Joint Inspection record and related unit information
            Joint_Inspection__c inspection = [
                SELECT Id, Name, Joint_Inspection_Status__c, Booking__r.Plot__r.Name
                FROM Joint_Inspection__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            details.inspectionId = inspection.Id;
            details.currentStatus = inspection.Joint_Inspection_Status__c;
            details.unitName = inspection.Booking__r.Plot__r.Name;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving inspection details: ' + e.getMessage());
        }
        
        return details;
    }

    @AuraEnabled
    public static void updateInspectionStatus(String inspectionId,String newStatus,String comments,String rescheduledReason,String rescheduledDatetime,String cancelledReason,String cancelledDatetime){  
        try {
            Joint_Inspection__c inspection = new Joint_Inspection__c(Id = inspectionId);
            inspection.Joint_Inspection_Status__c = newStatus;
            
            // Handle different status transitions
            if (newStatus == 'Completed') {
                inspection.Comments__c = comments;
                inspection.Joint_Inspection_Completed_Date__c = System.now();
            } 
            else if (newStatus == 'Re-Scheduled') {
                inspection.Rescheduled_Reason__c = rescheduledReason;
                inspection.Rescheduled_Date__c = (DateTime)JSON.deserialize(rescheduledDatetime, DateTime.class);
                inspection.Joint_Inspection_Date__c = null; // Clear original inspection date
            } 
            else if (newStatus == 'Cancelled') {
                inspection.Cancelled_Reason__c = cancelledReason;
                inspection.Cancelled_Date__c = System.now();
            }
            
            update inspection;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating inspection status: ' + e.getMessage());
        }
    }
    
    // Wrapper class to return inspection details
    public class InspectionDetails {
        @AuraEnabled public String inspectionId { get; set; }
        @AuraEnabled public String currentStatus { get; set; }
        @AuraEnabled public String unitName { get; set; }
    }
    
    //----- till above status component
    
    
    //this is for csr
    @AuraEnabled
    public static Map<String, Object> jointInspectionDetails1(String jointInspectionId) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            // First get the Joint Inspection record with its Booking reference
            Joint_Inspection__c inspection = [SELECT Id, Booking__c, Booking__r.Plot__c,Booking__r.Plot__r.Name, Booking__r.Email1__c, 
                                              Booking__r.Alternate_Email1__c FROM Joint_Inspection__c WHERE Id = :jointInspectionId LIMIT 1];
                                              
                                              
                                              
            
            if (inspection == null || inspection.Booking__c == null) {
                throw new AuraHandledException('No related Booking found for this Joint Inspection');
            }
            
            String unitName = '';
            if (inspection.Booking__r.Plot__r != null) {
                unitName = inspection.Booking__r.Plot__r.Name;
            }
            
            // Populate email options
            List<String> emailOptions = new List<String>();
            if (String.isNotBlank(inspection.Booking__r.Email1__c)) {
                emailOptions.add(inspection.Booking__r.Email1__c);
            }
            if (String.isNotBlank(inspection.Booking__r.Alternate_Email1__c)) {
                emailOptions.add(inspection.Booking__r.Alternate_Email1__c);
            }
            
            result.put('unitName', unitName);
            result.put('emailOptions', emailOptions);
            //result.put('bookingId', inspection.Booking__c); // Store the booking ID for later use
            result.put('inspectionId',inspection.Id);
        } catch(Exception e) {
            throw new AuraHandledException('Error getting booking details: ' + e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled
    public static void sendCSR(String inspectionId, String emailAddress) {
        try {
            // Validate email
            if (!Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', emailAddress)) {
                throw new IllegalArgumentException('Invalid email address format');
            }
            
            // Get inspection details with related booking and plot info
            Joint_Inspection__c inspection = [SELECT Id, Name, Booking__r.Plot__r.Name, Booking__r.First_Applicant_Name__c,Booking__r.Project1__r.Name, Booking__r.Email1__c
                                              FROM Joint_Inspection__c WHERE Id = :inspectionId LIMIT 1];
            
            if (inspection == null) {
                throw new AuraHandledException('Inspection record not found');
            }
            
            
            
            // HTML Email Body
            String htmlBody1 = '<!DOCTYPE html><html><body style="font-family:Arial,sans-serif;">' +
                '<p>Dear ' + inspection.Booking__r.First_Applicant_Name__c  + ',</p>' +
                '<p>Please click the link to submit the Customer Satisfactory Report</p>' +
                '<p>Best regards,<br/>Jain Housing Team</p>' +
                '</body></html>';
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            string urlval = label.Org_url;
            Site mySite = [SELECT Id, Name, Subdomain, UrlPathPrefix FROM Site WHERE Name = 'CSR_Form' LIMIT 1];
            String htmlBody = 'Dear Customer,<br/><br/>' +
                'Thank you for choosing Jain Housing. We have provided a secure hyperlink for you to fill out and submit the <strong>Customer Satisfactory Form</strong>.<br/><br/>' +
                'To access the form, please click the link below:<br/>' +
                '<a href="' + urlval + '/' + mySite.UrlPathPrefix + '?Id=' + inspection.id + '">Click here to fill the Customer Satisfactory Form</a><br/><br/>' +
                'We are committed to delivering high-quality construction and customer service. Your feedback is very important to us.<br/><br/>' +
                'If you have any questions or need assistance, please don\'t hesitate to contact us.<br/><br/>' +
                'Thank you,<br/>' +
                '<strong>Jain Housing</strong>';
            email.setToAddresses(new List<String>{emailAddress});
            email.setSubject('Customer Satisfactory Form');
            email.setHtmlBody(htmlBody);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
            inspection.CSR_Sent_Date__c = DateTime.now();
            update inspection;

        } catch(Exception e) {
            throw new AuraHandledException('Error sending invitation: ' + e.getMessage());
        }
    }
    
    
    
    @future
    public static void sendCSRFuture(List<Id> inspectionIds) {
        List<Joint_Inspection__c> inspections = [
            SELECT Id, Booking__r.Email1__c, Booking__c 
            FROM Joint_Inspection__c 
            WHERE Id IN :inspectionIds
        ];
        
        for (Joint_Inspection__c ji : inspections) {
            if (ji.Booking__r.Email1__c != null) {
                sendCSRInternal(ji.Id, ji.Booking__r.Email1__c);
            }
        }
    }

    private static void sendCSRInternal(Id inspectionId, String emailAddress) {
        try {
            // validating email
            if (!isValidEmail(emailAddress)) return;

            Joint_Inspection__c inspection = [
                SELECT Id, Booking__r.Plot__r.Name, Booking__r.First_Applicant_Name__c,
                       Booking__r.Project1__r.Name, Booking__r.Email1__c, Booking__c
                FROM Joint_Inspection__c WHERE Id = :inspectionId LIMIT 1
            ];

            List<String> emailList = new List<String>{ emailAddress };

            for (Co_Applicant__c ca : [
                SELECT Email__c FROM Co_Applicant__c 
                WHERE Booking__c = :inspection.Booking__c AND Email__c != null
            ]) {
                if (isValidEmail(ca.Email__c) && !emailList.contains(ca.Email__c)) {
                    emailList.add(ca.Email__c);
                }
            }

            String urlval = Label.Org_url;
            Site mySite = [SELECT UrlPathPrefix FROM Site WHERE Name = 'CSR_Form' LIMIT 1];

            String htmlBody = 'Dear Customer,<br/><br/>' +
                'Thank you for choosing Jain Housing. We have provided a secure hyperlink for you to fill out and submit the <strong>Customer Satisfactory Form</strong>.<br/><br/>' +
                'To access the form, please click the link below:<br/>' +
                '<a href="' + urlval + '/' + mySite.UrlPathPrefix + '?Id=' + inspection.Id + '">Click here to fill the Customer Satisfactory Form</a><br/><br/>' +
                'Thank you,<br/><strong>Jain Housing</strong>';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(emailList);
            email.setSubject('Customer Satisfactory Form');
            email.setHtmlBody(htmlBody);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });

            inspection.CSR_Sent_Date__c = DateTime.now();
            update inspection;

        } catch (Exception e) {
            System.debug('CSR email error: ' + e.getMessage());
        }
    }

    private static Boolean isValidEmail(String email) {
        return Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', email);
    }
    
    
    
    
}