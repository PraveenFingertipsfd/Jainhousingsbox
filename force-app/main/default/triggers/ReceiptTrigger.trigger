trigger ReceiptTrigger on Receipt__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            Set<Id> repId = new Set<Id>();
            for(Receipt__c rc : Trigger.new){
                if (rc.Finance_User__c !=null && rc.Approval_status__c != 'Approved by Finance Team'){
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setComments('Receipt Submitted For Approval');
                    req.setObjectId(rc.Id);
                    Approval.ProcessResult result = Approval.process(req);
                }
            }
        }
        if(Trigger.isUpdate){
            list<Receipt__c> approvedReciepts = new list<Receipt__c>();
            list<Id> approvedRecieptIds = new list<Id>();
            list<Receipt__c> rejectedReciepts = new list<Receipt__c>();
            set<Id> rejectedRecieptIds = new set<Id>();
            for(Receipt__c rcp : Trigger.new){
                if (rcp.Approval_status__c != Trigger.oldMap.get(rcp.Id).Approval_status__c && (rcp.Approval_status__c == 'Approved by Finance Team' || rcp.Approval_status__c == 'Rejected by Finance Team')) {
                    String body;
                    String title;
                    
                    if (rcp.Approval_status__c == 'Approved by Finance Team') {
                        approvedRecieptIds.add(rcp.Id);
                        approvedReciepts.add(rcp);
                    } else if (rcp.Approval_status__c == 'Rejected by Finance Team') {
                        rejectedRecieptIds.add(rcp.Id);
                        rejectedReciepts.add(rcp);
                    }
                }
            }
            String title='';
            if(!approvedReciepts.isEmpty()){
                title = 'Receipt Approved';
                ReceiptController.approvedReceiptsHandler(approvedRecieptIds);
                ReceiptController.sendNotificationsFromReceipts(title,approvedReciepts);
                
                //added by karthik send receipt as soon as approved
                ERP_ReceiptController.sendReceiptEmailsFromTrigger(approvedRecieptIds); 
            }
            if(!rejectedReciepts.isEmpty()){
                title = 'Receipt Rejected';
                ReceiptController.rejectedReceiptsHandler(rejectedRecieptIds);
                ReceiptController.sendNotificationsFromReceipts(title,rejectedReciepts);
            }
        }
    }
}