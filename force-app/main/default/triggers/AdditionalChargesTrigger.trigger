trigger AdditionalChargesTrigger on Additional_Charges__c (before insert,after insert,before update,after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        // Before Insert Logic: Populate Finance_User__c
        Set<Id> bookingIds = new Set<Id>();
        for (Additional_Charges__c charge : Trigger.new) {
            if (charge.Booking__c != null) {
                bookingIds.add(charge.Booking__c);
                charge.Show_All_FIelds__c = true;
                //charge.Approval_status__c = 'Approved';
            }
        }
        
        // Query the Finance_User__c for related Booking__c records
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>(
            [SELECT Id, Finance_User__c FROM Booking__c WHERE Id IN :bookingIds]
        );
        
        // Assign Finance_User__c to Additional_Charges__c where applicable
        for (Additional_Charges__c charge : Trigger.new) {
            if (charge.Booking__c != null && bookingMap.containsKey(charge.Booking__c)) {
                charge.Finance_User__c = bookingMap.get(charge.Booking__c).Finance_User__c;
            }
        }
        
        // Validation: Throw error if Finance_User__c is not populated
        for (Additional_Charges__c charge : Trigger.new) {
            if (charge.Finance_User__c == null) {
                charge.addError('The related Booking must have a Finance User assigned.');
            }
        }
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        // After Insert Logic: Submit for Approval
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        
        for (Additional_Charges__c charge : Trigger.new) {
            if (charge.Finance_User__c != null) {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(charge.Id); // Set the record ID
                req.setProcessDefinitionNameOrId('Additional_Charges_Approval'); // Use the name or ID of the approval process
                req.setSkipEntryCriteria(true); // Evaluate the entry criteria
                approvalRequests.add(req);
            }
        }
        
        if (!approvalRequests.isEmpty()) {
            Approval.ProcessResult[] results = Approval.process(approvalRequests);
            
            for (Approval.ProcessResult result : results) {
                if (result.isSuccess()) {
                    System.debug('Approval submitted for record: ' + result.getInstanceStatus());
                } else {
                    System.debug('Approval submission failed for record: ' + result.getInstanceStatus());
                }
            }
        }
    }
/*
    if (Trigger.isAfter && Trigger.isUpdate) {
        list<Additional_Charges__c> approvedDemands = new list<Additional_Charges__c>();
        list<Additional_Charges__c> rejectedDemands = new list<Additional_Charges__c>();
        for (Additional_Charges__c rcp : Trigger.new) {
            // Check if the Approval status has changed
            if (rcp.Approval_status__c != Trigger.oldMap.get(rcp.Id).Approval_status__c && (rcp.Approval_status__c == 'Approved' || rcp.Approval_status__c == 'Rejected')) {
                // Define the message body and title based on approval status
                String body;
                String title;
                
                if (rcp.Approval_status__c == 'Approved') {
                    approvedDemands.add(rcp);
                } else if (rcp.Approval_status__c == 'Rejected') {
                    rejectedDemands.add(rcp);
                }
            }
        }
        String title='';
        if(!approvedDemands.isEmpty()){
            title = 'Additional Charge Demand Raise Approved';
            AdditionalChargesMainController.sendNotificationsFromAdditionalChange(title,approvedDemands);
        }
        if(!rejectedDemands.isEmpty()){
            title = 'Additional Charge Demand Raise Rejected';
            AdditionalChargesMainController.sendNotificationsFromAdditionalChange(title,rejectedDemands);
        }
    }*/
    
}