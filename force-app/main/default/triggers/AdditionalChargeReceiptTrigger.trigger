trigger AdditionalChargeReceiptTrigger on Additional_Charge_Receipt__c (before insert,after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        Set<Id> additionalChargeIds = new Set<Id>();
        
        // Collect Additional_Charges__c IDs
        for (Additional_Charge_Receipt__c receipt : Trigger.new) {
            if (receipt.Additional_Charges__c != null) {
                additionalChargeIds.add(receipt.Additional_Charges__c);
            }
        }
        
        // Fetch related Additional_Charges__c records with Booking__c and Booking__r.Finance_User__c
        Map<Id, Additional_Charges__c> additionalChargesMap = new Map<Id, Additional_Charges__c>(
            [SELECT Id, Booking__c, Booking__r.Finance_User__c 
             FROM Additional_Charges__c 
             WHERE Id IN :additionalChargeIds]
        );
        
        // Update the fields on Additional_Charge_Receipt__c records
        for (Additional_Charge_Receipt__c receipt : Trigger.new) {
            Additional_Charges__c additionalCharge = additionalChargesMap.get(receipt.Additional_Charges__c);
            if (additionalCharge != null) {
                receipt.Booking__c = additionalCharge.Booking__c;
                receipt.Approval_Status__c = 'Pending';
                
                // Only update Finance_User__c if it exists
                if (additionalCharge.Booking__r != null && additionalCharge.Booking__r.Finance_User__c != null) {
                    receipt.Finance_User__c = additionalCharge.Booking__r.Finance_User__c;
                }
            }
        }
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
            list<Additional_Charge_Receipt__c> approvedReciepts = new list<Additional_Charge_Receipt__c>();
            list<Additional_Charge_Receipt__c> rejectedReciepts = new list<Additional_Charge_Receipt__c>();
            for (Additional_Charge_Receipt__c rcp : Trigger.new) {
                // Check if the Approval status has changed
                if (rcp.Approval_status__c != Trigger.oldMap.get(rcp.Id).Approval_status__c && (rcp.Approval_status__c == 'Approved' || rcp.Approval_status__c == 'Rejected')) {
                    // Define the message body and title based on approval status
                    String body;
                    String title;
                    
                    if (rcp.Approval_status__c == 'Approved') {
                        approvedReciepts.add(rcp);
                    } else if (rcp.Approval_status__c == 'Rejected') {
                        rejectedReciepts.add(rcp);
                    }
                }
            }
            String title='';
            if(!approvedReciepts.isEmpty()){
                title = 'Additional Charge Receipt Approved';
                AdditionalChargeReceiptsController.sendNotificationsFromAdditionalChangeReciept(title,approvedReciepts);
            }
            if(!rejectedReciepts.isEmpty()){
                title = 'Additional Charge Receipt Rejected';
                AdditionalChargeReceiptsController.sendNotificationsFromAdditionalChangeReciept(title,rejectedReciepts);
            }
        }
}