public without sharing class BookingHandler {
public boolean checks {get;set;}
    public string status {get;set;}
    //public Document__c documt {get;set;}
    public Booking__c book {get;set;}
    private Id getid {get;set;}
    private Id docGetId {get;set;}
   // public List<PDFWrapper> Docs {get;set;}
    public Map<String, Object> result {get;set;}
    
    public BookingHandler(){
        getid = ApexPages.currentPage().getParameters().get('id');
        system.debug('getid'+getid);
    }
    @AuraEnabled
    public static boolean sendCancellationApproval(Id recId, boolean cancelType, String CanlRes, String CanlDis){
        List<Booking__c> bklist = [Select Id, Name, Cancellation_Reason__c, Cancellation_Description__c From Booking__c Where id =: recId];
        for(Booking__c bk : bklist)
        {
            bk.Cancellation_Reason__c = CanlRes;
            bk.Cancellation_Description__c = CanlDis;
        }
        Update bklist;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Cancellation request');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId());
                   req1.setProcessDefinitionNameOrId('Cancellation_Approval');

        
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
        return true;
    }
    
    
    
     /*@AuraEnabled
    public static boolean approvalWithCancellationCharge(Id recId,String comment, Decimal charge){
        system.debug('recId='+recId+' '+'comment='+ comment + charge);
        
        //Fetching the approval process
           ProcessInstance pi = [
            SELECT Id, Status
            FROM ProcessInstance
            WHERE TargetObjectId = :recId
            AND Status != 'Completed'
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        
        List<ProcessInstanceStep> steps = [
            SELECT Id, StepStatus, ProcessInstanceId
            FROM ProcessInstanceStep
            WHERE ProcessInstanceId = :pi.Id
            AND StepStatus = 'Pending'];
 
        
 
       ProcessInstanceStep currentStep = steps.get(1);
 
       
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments(comment);
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId());
        req1.setProcessDefinitionNameOrId('Cancellation_Approval');

        
        //req1.setSkipEntryCriteria(true);
        //Approval.ProcessResult result = Approval.process(req1);
        // update the status approved or reject.
        // comments upadate
        // record should be unlocked
         List<Booking__c> bklist = [Select Id, Name, Cancellation_Reason__c, Cancellation_Description__c From Booking__c Where id =: recId];
        for(Booking__c bk : bklist)
        {
            bk.Cancellation_Charges__c = charge;
           // bk.Cancellation_Description__c = CanlDis;
        }
        Update bklist;

        
        return true;
 
        
    }*/
    
    @AuraEnabled
    public static Boolean approvalWithCancellationCharge(Id recId, String comment, Decimal charge) {
        try {
            system.debug('in');
            // 1. Apply the cancellation charge (optional)
            Booking__c booking = [SELECT Id, Cancellation_Charges__c FROM Booking__c WHERE Id = :recId LIMIT 1];
            booking.Cancellation_Charges__c = charge;
            update booking;
            system.debug('in');
            // 2. Get pending approval work items
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.Status
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :recId
            ];
            system.debug('in');
            if (!workItems.isEmpty()) {
                system.debug('in');
                for (ProcessInstanceWorkitem item : workItems) {
                    System.debug('in');
                    try {
                        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                        req.setComments(comment);
                        req.setAction('Approve');
                        req.setWorkitemId(item.Id);
                        
                        Approval.ProcessResult result = Approval.process(req);
                        System.debug('in1');
                        
                        if (!result.isSuccess()) {
                            System.debug('in2');
                            throw new AuraHandledException('Approval failed: ' + result.getInstanceStatus());
                        }
                    } catch (Exception ex) {
                        System.debug('❌ Approval Exception: ' + ex.getMessage());
                        throw new AuraHandledException('Error during approval: ' + ex.getMessage());
                    }
                }

                return true;
            } else {
                system.debug('throw');
                throw new AuraHandledException('No pending approval found for this record.');
            }
        } catch (Exception ex) {
            system.debug('throw1');
            throw new AuraHandledException('Error in approval process: ' + ex.getMessage());
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
    
    
    }