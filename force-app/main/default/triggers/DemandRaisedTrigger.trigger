trigger DemandRaisedTrigger on Demand_Raised__c (after update,after insert) {
    
    if(Trigger.IsUpdate && Trigger.IsAfter){
        Set<String> recipientIds = new Set<String>();
        system.debug('Called Demand Raised Trigger');
        for (Demand_Raised__c demand : Trigger.new) {
            recipientIds.add(demand.CreatedById);
            
            // Send the notification
            String title = 'Demand Raise '+demand.Demand_Approval_Status__c;
            String body = 'This is to notify that Booking (' + demand.Booking_Name__c + '), has a demand raise update. ' +
                'The demand raise '+demand.Name +' has been ' + demand.Demand_Approval_Status__c + 
                ' by the Finance Team. Please review the details.';
            String notificationName = 'Demand_Raise_Notification';
            
            // Call the sendCustomNotification method
            ReceiptController.sendCustomNotification(
                recipientIds,
                title,
                body,
                demand.Id,
                notificationName
            );
            
        }
    }
    // Collect recipient IDs and notification details
    Set<String> recipientIds = new Set<String>();
    system.debug('Called Demand Raised Trigger');
    for (Demand_Raised__c demand : Trigger.new) {
        /* Demand_Raised__c oldDemand = Trigger.oldMap.get(demand.Id);
        // Check if Demand_Approval_Status__c has changed and is now "Approved" or "Rejected"
        if (demand.Demand_Approval_Status__c != oldDemand.Demand_Approval_Status__c &&
        (demand.Demand_Approval_Status__c == 'Approved' || demand.Demand_Approval_Status__c == 'Rejected')) {
        }*/
        // Add the record's creator to the recipient list
        recipientIds.add(demand.CreatedById);
        
        // Send the notification
        String title = 'Demand Raise '+demand.Demand_Approval_Status__c;
        String body = 'This is to notify that Booking (' + demand.Booking_Name__c + '), has a demand raise update. ' +
            'The demand raise '+demand.Name +' has been ' + demand.Demand_Approval_Status__c + 
            ' by the Finance Team. Please review the details.';
        String notificationName = 'Demand_Raise_Notification';
        
        // Call the sendCustomNotification method
        ReceiptController.sendCustomNotification( recipientIds, title,  body,    demand.Id, notificationName  );
        
    }
}