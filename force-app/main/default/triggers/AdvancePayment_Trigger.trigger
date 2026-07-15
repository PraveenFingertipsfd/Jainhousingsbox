trigger AdvancePayment_Trigger on Advance_Payment__c (before update,after update) {
    if(trigger.isbefore && trigger.isupdate){
        List<Booking_Request__c> BkLst = new List<Booking_Request__c>();
        set<string> BkIds = new set<string>();
        Map<string,decimal> bkAmtMap = new Map<string,decimal>();
        for(Advance_Payment__c Apay : trigger.new){
            if(Apay.Booking_Request__c !=null){
                BkIds.add(Apay.Booking_Request__c);
            }
        }
        
        for(Booking_Request__c bkrq : [select id,name,Amount_Received__c from Booking_Request__c where Id =: BkIds]){
            bkAmtMap.put(bkrq.Id,bkrq.Amount_Received__c);
        }
        for(Advance_Payment__c Apay : trigger.new){
            if(Apay.Approval_Status__c  != trigger.oldmap.get(Apay.Id).Approval_Status__c && Apay.Approval_Status__c == 'Approved'){
                if(Apay.Amount__c != null && Apay.Amount__c > 0 && Apay.Booking_Request__c!=null){
                    decimal bkamt = 0;
                    if(bkAmtMap.containskey(Apay.Booking_Request__c)){
                        bkamt = bkAmtMap.get(Apay.Booking_Request__c) != null ? bkAmtMap.get(Apay.Booking_Request__c) : 0;
                    }
                    Booking_Request__c bk = new Booking_Request__c();
                    bk.Id = Apay.Booking_Request__c;
                    bk.Amount_Received__c = bkamt + Apay.Amount__c;
                    BkLst.add(bk);
                }
            }
        }
        if (!BkLst.isEmpty()) {
            update BkLst;
        }
    }
    
    // ===== AFTER UPDATE =====
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Id> approvedReceiptIds = new List<Id>();
        
        for (Advance_Payment__c Apay : Trigger.new) {
            Advance_Payment__c oldApay = Trigger.oldMap.get(Apay.Id);
            
            if (Apay.Approval_Status__c != oldApay.Approval_Status__c &&
                Apay.Approval_Status__c == 'Approved') {
                    approvedReceiptIds.add(Apay.Id);
                }
        }
        
        if (!approvedReceiptIds.isEmpty()) {
            // Call the method to send emails
            ERP_AdvancePaymentController.sendAdvancePaymentReceiptEmailsFromTrigger(approvedReceiptIds);
        }
    }
}