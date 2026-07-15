trigger PaymentScheduleTrigger on Payment_schedule__c (before insert,before update,after insert, after update, after delete, after undelete) {
    
    Set<Id> quoteIds = new Set<Id>();
    if (Trigger.isBefore && Trigger.isUpdate) {
        List<Payment_schedule__c> payList = new List<Payment_schedule__c>();
        for (Payment_schedule__c payment : Trigger.new) {
            if((payment.Include_Interest__c != Trigger.oldMap.get(payment.id).Include_Interest__c) && payment.Include_Interest__c == false){
                payment.Balance_Amount__c = payment.AmountB__c;
            }
            //added by hk 25-08
            if(payment.Pending_Amount__c != Trigger.oldMap.get(payment.id).Pending_Amount__c && (payment.Pending_Amount__c <= 0))
            {
                payment.status__c = 'Completed';
            }
        }
    }
    
    
    //For updating Rollup summary Fields from Payment Schedule
    Set<Id> bookingIds = new Set<Id>();
    if (Trigger.isafter) {
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            for (Payment_Schedule__c ps : Trigger.new) {
                if (ps.Booking__c != null)
                    bookingIds.add(ps.Booking__c);
            }
        }
        if (Trigger.isDelete) {
            for (Payment_Schedule__c ps : Trigger.old) {
                if (ps.Booking__c != null)
                    bookingIds.add(ps.Booking__c);
            }
        }
        
        if (!bookingIds.isEmpty())
            system.debug(bookingIds);
            BookingRollupHandler.updateBookingRollups(bookingIds);
    }
}