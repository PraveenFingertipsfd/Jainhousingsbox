public class TicketController {
    public static void sendTicketEmail(String ticketId, String emailMessage, List<Messaging.EmailFileAttachment> emailAttachments) {
        Tickets__c ticket = [SELECT Id,Customer_Name__c,Departments__c,Project_Name__c,Email__c,Contact_Number__c,Approval_Status__c,Ticket_Type__c,Manager__c,Assigned_To__c,Closed_Date__c,Ticket_Created_Date__c,Comment__c,Last_Ticket__c FROM Tickets__c WHERE Id = :ticketId LIMIT 1];
        
        if (ticket != null && !String.isEmpty(ticket.Email__c)) {
            OrgWideEmailAddress orgWideEmail = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress];

            if (orgWideEmail != null && !String.isEmpty(ticket.Email__c)) {
                system.debug('inside ticket messages controler');
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ticket.Email__c});
                email.setSubject('Ticket Status Update');
                email.setHtmlBody(emailMessage);
                
                email.setUseSignature(false);
                email.setOptOutPolicy('FILTER');
                //email.setSuppressApexCallout(false);
                email.setTreatBodiesAsTemplate(false);
                email.setEmailPriority('Normal');
                
                system.debug('org email'+orgWideEmail.Id);
                email.setOrgWideEmailAddressId(orgWideEmail.Id);
                
                
                email.setFileAttachments(emailAttachments); 
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});

            } else {
                System.debug('Org-wide email address not found');
            }
        }
    }
}