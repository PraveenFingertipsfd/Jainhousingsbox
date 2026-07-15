trigger TicketTrigger on Tickets__c (before insert,after insert,after update, after delete, after undelete,Before Update) {
    
    if(trigger.isBefore && trigger.isinsert)
    {
        user u = [SELECT Id,Name,Profile.Name FROM user WHERE Id=:userinfo.getUserId()];
        
        Map<String, Id> ticketTypeToExecutiveMap = new Map<String, Id>();
        Map<String, Id> ticketTypeToManagerMap = new Map<String, Id>();
        Map<String, Id> ticketTypeToDepartmentMap = new Map<String, Id>();
        Map<String,Double> TATMap= new Map<String,Double>();
        
        
        for (Departments__c department : [SELECT id, Ticket_Type__c, Executive__c,TAT__c,Manager__c FROM Departments__c]) {
            ticketTypeToExecutiveMap.put(department.Ticket_Type__c, department.Executive__c);
            ticketTypeToManagerMap.put(department.Ticket_Type__c, department.Manager__c);
            ticketTypeToDepartmentMap.put(department.Ticket_Type__c, department.id);
            TATMap.put(department.Ticket_Type__c, department.TAT__c);
        }
        
        
        
        
        for (Tickets__c ticket : Trigger.new) {
            if (ticket.Ticket_Type__c != null) {
                Id executiveId = ticketTypeToExecutiveMap.get(ticket.Ticket_Type__c);
                Double tat=TATMap.get(ticket.Ticket_Type__c);
                if (executiveId != null) {
                    ticket.Assigned_To__c = executiveId;
                    ticket.Expected_Closing_Hour__c=tat;
                    ticket.OwnerId=executiveId;
                    ticket.Expected_Closing_Time__c=System.now().addHours(tat.intValue());
                    ticket.Ticket_Created_Date__c=system.now();
                    ticket.Departments__c=ticketTypeToDepartmentMap.get(ticket.Ticket_Type__c);
                    ticket.Manager__c= ticketTypeToManagerMap.get(ticket.Ticket_Type__c);
                }
            }
        }
        
    }
    if(trigger.isUpdate && Trigger.isBefore){        
        for(Tickets__c tc:trigger.New){
            if(tc.Approval_Status__c=='Approved'&& Trigger.oldMap.get(tc.Id).Approval_Status__c != 'Approved'){
                tc.Expected_Closing_Time__c=tc.Updated_Closing_Time__c;
                
            }
        }
        
        
    }
    
    if(Trigger.isBefore && Trigger.isInsert){
        
        // for checking the ticket with email
        Set<String> emailAddresses = new Set<String>();
        Map<String, Id> LastticketToMap = new Map<String, Id>();
        
        
        for (Tickets__c newTicket : Trigger.new) {
            emailAddresses.add(newTicket.Email__c);
        }
        
        Map<String, Tickets__c> existingTickets = new Map<String, Tickets__c>();
        
        for (Tickets__c existingTicket : [SELECT Id, Email__c, Ticket__c,Ticket_Type__c FROM Tickets__c WHERE Email__c IN :emailAddresses ORDER BY CreatedDate ASC]) {
            existingTickets.put(existingTicket.Email__c + existingTicket.Ticket_Type__c, existingTicket);
            LastticketToMap.put(existingTicket.Email__c + existingTicket.Ticket_Type__c, existingTicket.id);
            
        }
        
        
        for (Tickets__c newTicket : Trigger.new) {
            String emailAndTicketType = newTicket.Email__c + newTicket.Ticket_Type__c;
            
            if (existingTickets.containsKey(emailAndTicketType)) {
                
                newTicket.Ticket__c = 'Re Opened';
                newTicket.Last_Ticket__c=LastticketToMap.get(emailAndTicketType);
            } else {
                
                newTicket.Ticket__c = 'Fresh';
            }
        }
    }
    
    
    
    /* update the email notifications to the customer based on the ticket status */
    if(trigger.isinsert && Trigger.isAfter){  
        for (Tickets__c ticket : Trigger.new) {
            if (ticket.Ticket_Status__c == 'New') {
                system.debug('inside ticket messages');
                String emailMessage = 'Dear '+ticket.Customer_Name__c+',<br/>This is to keep you informed that we have received your ticket related to construction etc.. and your ticket id is '+ticket.Name+' is been acknowledged and it will be assigned to one of our executives shortly, we will keep you notified once our team starts working on your ticket.';
                TicketController.sendTicketEmail(ticket.Id, emailMessage, new List<Messaging.EmailFileAttachment>());
            }
        }
    }
    if(trigger.isUpdate && Trigger.isAfter){ 
        
        for (Tickets__c ticket : Trigger.new) {
            Tickets__c oldTicket = Trigger.oldMap.get(ticket.Id);
            if (ticket.Ticket_Status__c != oldTicket.Ticket_Status__c || ticket.Final_Approval_Status__c != oldTicket.Final_Approval_Status__c) {
                String emailMessage = '';
                if (ticket.Ticket_Status__c == 'Assigned') {
                    emailMessage = 'Dear '+ticket.Customer_Name__c+',<br/> This is to keep you informed that we have received your ticket related to construction etc. and your ticket id is '+ticket.Name+' is been assigned to our executive and they are working on the ticket, we will keep you notified about the progress of your ticket raised.';
                }else if (ticket.Ticket_Status__c == 'Escalated') {
                    emailMessage = 'Dear '+ticket.Customer_Name__c+',<br/>The ticket id '+ticket.Name+' related to construction…. And our executive is working on it and it’s been escalated to the concerned department head and we expect the ticket to be closed shortly with the work  completed and shall keep you informed about it.';
                }
                else if (ticket.Ticket_Status__c =='Closed' && ticket.Final_Approval_Status__c =='Approved') {
                    emailMessage = 'Dear '+ticket.Customer_Name__c+'<br/> The ticket id '+ticket.Name+' which was issued on '+ticket.Ticket_Created_Date__c+' for the construction / technical issue has been completed by our team and same has been closed by sharing the images to you, to re open the ticket or if you feel the ticket is not completed as per your requirements, kindly raise another ticket and we will work on it and ensure good services.';
                    system.debug('emailMessagesdfghjk'+emailMessage);
                }
                else if (ticket.Ticket_Status__c =='Closed' && ticket.Final_Approval_Status__c =='Rejected') {
                    if (oldTicket.Ticket_Status__c != 'Escalated' && oldTicket.Ticket_Status__c != 'Closed') {
                        // Update Ticket Status to 'Escalated'
                        List<Tickets__c> Ticks = [SELECT Id, Name, Ticket_Status__c FROM Tickets__c WHERE Id IN :trigger.new];
                        for (Tickets__c a : Ticks) {
                            a.Ticket_Status__c = 'Escalated';
                            //system.debug('emailMessagesdfghjk'+emailMessage);
                        }
                        Update Ticks;
                        
                        Continue;
                    }
                }
                
                if (!String.isEmpty(emailMessage)) {
                    List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                    
                    List<ContentDocumentLink> contentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :ticket.Id AND LinkedEntity.Type = 'Tickets__c'];
                    
                    for (ContentDocumentLink link : contentLinks) {
                        ContentVersion contentVersion = [SELECT Title, VersionData, FileExtension FROM ContentVersion WHERE ContentDocumentId = :link.ContentDocumentId LIMIT 1];
                        system.debug('contevtserdfg');
                        Messaging.EmailFileAttachment docAttach = new Messaging.EmailFileAttachment();
                        docAttach.setFileName(contentVersion.Title + '.' + contentVersion.FileExtension);
                        docAttach.setBody(contentVersion.VersionData);
                        system.debug('edffghhyjnjk');
                        if (contentVersion.FileExtension.equalsIgnoreCase('pdf')) {
                            docAttach.setContentType('application/pdf');
                        } else if (contentVersion.FileExtension.equalsIgnoreCase('docx')) {
                            docAttach.setContentType('application/vnd.openxmlformats-officedocument.wordprocessingml.document');
                        } else if (contentVersion.FileExtension.equalsIgnoreCase('jpeg') || contentVersion.FileExtension.equalsIgnoreCase('jpg')) {
                            docAttach.setContentType('image/jpeg');
                        } else if (contentVersion.FileExtension.equalsIgnoreCase('png')) {
                            docAttach.setContentType('image/png');
                        }
                        emailAttachments.add(docAttach);
                    }
                    TicketController.sendTicketEmail(ticket.Id, emailMessage, emailAttachments);
                }
            } 
        }
    } 
    
}