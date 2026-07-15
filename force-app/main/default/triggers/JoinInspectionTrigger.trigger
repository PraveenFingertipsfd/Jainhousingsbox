trigger JoinInspectionTrigger on Joint_Inspection__c (before insert) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        Set<Id> bookingIds = new Set<Id>();
        
        // Collect all Booking IDs from the trigger records
        for (Joint_Inspection__c ji : Trigger.new) {
            if (ji.Booking__c != null) {
                bookingIds.add(ji.Booking__c);
            }
        }
        
        if (!bookingIds.isEmpty()) {
            // Build query condition to exclude records being updated (only in update context)
            String query = 'SELECT Id, Booking__c, Name, Joint_Inspection_Status__c ' +
                          'FROM Joint_Inspection__c ' +
                          'WHERE Booking__c IN :bookingIds ' +
                          'AND Joint_Inspection_Status__c NOT IN (\'Completed\', \'Cancelled\')';
            
            // Only add this condition for update context
            if (Trigger.isUpdate && Trigger.oldMap != null) {
                query += ' AND Id NOT IN :Trigger.oldMap.keySet()';
            }
            
            // Query existing active inspections
            Map<Id, Joint_Inspection__c> activeInspectionsByBooking = new Map<Id, Joint_Inspection__c>();
            for (Joint_Inspection__c ji : Database.query(query)) {
                activeInspectionsByBooking.put(ji.Booking__c, ji);
            }
            
            // Validate each record in trigger
            for (Joint_Inspection__c ji : Trigger.new) {
                if (ji.Booking__c != null && activeInspectionsByBooking.containsKey(ji.Booking__c)) {
                    Joint_Inspection__c existingJI = activeInspectionsByBooking.get(ji.Booking__c);
                    
                    // Check if this record is trying to be active
                    Boolean isActive = (ji.Joint_Inspection_Status__c == null || 
                                      (ji.Joint_Inspection_Status__c != 'Completed' && 
                                       ji.Joint_Inspection_Status__c != 'Cancelled'));
                    
                    if (isActive) {
                        ji.addError('An active Joint Inspection already exists for this booking');
                    }
                }
            }
        }
    }
}