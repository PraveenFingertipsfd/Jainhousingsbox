trigger BlockTrigger on Block__c (before insert,before update,after insert, after update, after delete, after undelete) {
    
   /* if(Trigger.isAfter && Trigger.isUpdate) {
        Set<Id> newset = new Set<Id>();
        list <Payment_schedule__c> updatelist = new list <Payment_schedule__c>();
        for (Block__c block : Trigger.new) {
            if(block.Intrest_Percentage__c != null && block.Intrest_Percentage__c != Trigger.oldmap.get(block.Id).Intrest_Percentage__c)
                
            {
                newset.add(block.Id);
            }
        }
        List<Payment_schedule__c> lstpayment = [ SELECT Id, Name, Amount__c,Booking__c, Balance_Amount__c,Payment_percent__c,Booking__r.Block__r.Intrest_Percentage__c, Interest_Up_to_Date__c,Include_Interest__c,Interest_Amount__c,Interest_Percent__c  
                                                FROM Payment_Schedule__c
                                                WHERE Booking__r.Tower__c IN :newset];
        for (Payment_Schedule__c extps : lstpayment) {
            Payment_schedule__c ps = new Payment_schedule__c();
            ps.id = extps.id;
            ps.Interest_Percent__c = extps.Booking__r.Block__r.Intrest_Percentage__c;
            updatelist.add(ps);
        }
        if(!updatelist.isEmpty()){
            update updatelist;
            
        }
    }*/
    
}