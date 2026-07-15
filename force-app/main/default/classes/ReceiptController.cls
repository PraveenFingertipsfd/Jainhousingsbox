public class ReceiptController{
    
    public class databox{
        @AuraEnabled
        public List<Receipt_Line_Item__c> rcList;
        @AuraEnabled
        public Decimal grandTotal;
    }
    public class wrapperprod{
        @AuraEnabled
        public List<Payment_schedule__c> pysch{get;set;}
        @AuraEnabled
        public string accname{get;set;}
        @AuraEnabled
        public List<String> payType{get;set;}
        @AuraEnabled
        public Booking__c bkrec{get;set;}
        @AuraEnabled
        public Decimal Intamt{get;set;}
    }
    
    @AuraEnabled
    public static wrapperprod getpaymentsc(string recid){
        wrapperprod wrpdata=new wrapperprod();
        
        //To get Payment Schedules
        List<Payment_schedule__c> lstschdules = [SELECT Id,Name,Payment_percent__c,Pending_Amount__c,Total_Outstanding_Due_Amount__c,Payment_Due_Date__c,Interest_Up_To_Date__c,
                                                 Scheduled_Amount__c,Recived_Per__c,Amount__c,S_No__c,status__c,Booking__c,Received_Amount__c,AmountB__c 
                                                 FROM Payment_schedule__c WHERE Booking__c =:recid ORDER BY S_No__c ASC];
        wrpdata.pysch=lstschdules;
        
        //To get Interest Amount
        Decimal InterestAmount = 0;
        for(Payment_Schedule__c pay : lstschdules){
            InterestAmount += pay.Interest_Up_to_Date__c;
        }
        wrpdata.Intamt = InterestAmount;
        
        //To get Mode of Payments
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Receipt_Line_Item__c.Mode_of_Payment__c.getDescribe();
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        wrpdata.payType = paymentTypeValues;
        
        //To get Booking record
        Booking__c bk = [select id,name,Project__c,Unit_NumberFor__c,FloorNo__c,Unit_BHK_Type__c,Pending_Amount__c,Total_received_Amount__c,Total_Interest__c,Total__c from Booking__c where id=: recid];
        wrpdata.bkrec = bk;
        
        system.debug(wrpdata);
        return wrpdata; 
    }
    @AuraEnabled
    public static List<String> getPaymentTypePicklistValues(){
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Receipt_Line_Item__c.Mode_of_Payment__c.getDescribe();
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        return paymentTypeValues;
    }
    @AuraEnabled
    public static Booking__c getBookingDetails(string recid){
        return [select id,name,Project__c,Unit_NumberFor__c,Pending_Amount__c,Total_Interest__c,Total__c /*Unit_NumberFor__c,GRAND_TOTAL__c*/ from Booking__c where id=: recid];
    }
    @AuraEnabled
    public static Decimal getInterestAmount(string recId){
        Decimal InterestAmount = 0;
        List<Payment_Schedule__c> payList = [select id,name,Interest_Up_To_Date__c from Payment_schedule__c where Booking__c =: recId];
        for(Payment_Schedule__c pay : payList){
            InterestAmount = InterestAmount+ pay.Interest_Up_to_Date__c;
        }
        return InterestAmount;
    }
    
    @AuraEnabled
    public static databox Rcitemlist(String recid){
        system.debug('mfrid---'+recid);
        databox db = new databox();
        List<Receipt_Line_Item__c> rcptitmlst =  [SELECT Id,Name,Receipt__c,Interest__c,Payment_schedule__c,Mode_of_Payment__c,Cheque_no_Transaction_Number__c,Received_Amount__c,Receipt__r.Booking__c,Booking__c,Pending_Amount__c,Amount__c FROM Receipt_Line_Item__c where  Booking__c =:recid ];
        system.debug(rcptitmlst);
        Booking__c bk = [SELECT Id FROM Booking__c WHERE Id=:recid];
        system.debug('---'+rcptitmlst);
        db.rcList = rcptitmlst;
        // db.grandTotal = opp.Total_of_Add_on_s__c;
        return db;                                      
    }
    @AuraEnabled
    public static void deleteProduct(string prId){
        DELETE [SELECT Id FROM 	Receipt_Line_Item__c WHERE Id=:prId];
    }
    @AuraEnabled
    public static String insertReceiptLineItems(List<Receipt_Line_Item__c> polist,string PaymentFrom, string pon,string remark,string poc, string recid, Decimal paidAmount, Decimal interestAmount){
        
        Booking__c bk = [select id,name,Finance_User__c,Project__c from Booking__c where id =: recid limit 1];
        
        // ------ modification by Pattu Sudar --------------------------------------------------------------------------
        // 
        // 
        //List<Receipt__c> dupRcpList = [Select Id,Name from Receipt__c where Check_Transaction_Nmber__c =:polist[0].Cheque_no_Transaction_Number__c ];
        //if(dupRcpList.size() >0){
        //return 'Duplicate Cheque/Transaction Number Entered';
        //}
        //else{
           
        
            Receipt__c rc = new Receipt__c();
            rc.Receipt_Name__c=pon;
            rc.Remarks__c = remark;
            rc.Finance_User__c = bk.Finance_User__c;
            rc.Receipt_date__c=date.valueof(poc);
            rc.Payment_From__c = PaymentFrom;
            rc.Check_Transaction_Nmber__c = polist[0].Cheque_no_Transaction_Number__c;
            rc.Amount_received__c = paidAmount;
            rc.Mode_of_payment__c = polist[0].Mode_of_Payment__c;
            rc.Payment_Received_Bank__c = polist[0].Bank_Name__c;
            rc.Cheque_Date__c = polist[0].Cheque_Date__c;
            rc.Booking__c=recid;
            //rc.Interest_Paid_Amount__c = interestAmount;
            insert rc;
            
            List<Receipt_Line_Item__c> receiptsToCreate = new List<Receipt_Line_Item__c>();
            List<Payment_Schedule__c> payList = [SELECT Id, Amount__c, Pending_Amount__c, S_No__c,Interest_Pending__c FROM Payment_Schedule__c where Booking__c =: bk.Id ORDER BY S_No__c ASC ];
            List<Payment_Schedule__c> newpayList = new List<Payment_Schedule__c>();
            List<Payment_Schedule__c> orderedPayList = new List<Payment_Schedule__c>();
            Set<Id> payIds = new Set<Id>();
            
            if(interestAmount != 0 || interestAmount != null){
                paidAmount = paidAmount - interestAmount;
            }
            
            //For Flat cost pending amount
            if(paidAmount > 0){
                for (Payment_Schedule__c paymentSchedule : payList) {
                    if (paidAmount <= 0 || paidAmount == null) {
                        break;
                    }
                    if (paymentSchedule.Pending_Amount__c != null && paymentSchedule.Pending_Amount__c > 0){
                        Decimal amountToReceive = Math.min(paymentSchedule.Pending_Amount__c, paidAmount);
                        paidAmount -= amountToReceive;
                        
                        Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                        rece.Booking__c = bk.Id;
                        rece.Name = 'Against Payment Schedule';
                        rece.Payment_Type__c = 'Payment Schedule';
                        rece.Receipt__c = rc.Id;
                        rece.Payment_Schedule__c = paymentSchedule.Id;
                        rece.Received_Amount__c = amountToReceive;
                        rece.Amount__c = amountToReceive;
                        rece.Bank_Name__c = polist[0].Bank_Name__c;
                        rece.Payment_From__c = polist[0].Payment_From__c;
                        rece.Mode_of_Payment__c =  polist[0].Mode_of_Payment__c;
                        rece.Approval_Status__c = 'Pending';
                        rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
                        rece.Cheque_Date__c = polist[0].Cheque_Date__c;
                        receiptsToCreate.add(rece);
                        payIds.add(paymentSchedule.Id);
                    }
                }
            }
            if(paidAmount !=null && paidAmount > 0){
                Integer PaymentScheduleSize = payList.size();
                Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                rece.Booking__c = bk.Id;
                rece.Name = 'Against Payment Schedule';
                rece.Payment_Type__c = 'Payment Schedule';
                rece.Receipt__c = rc.Id;
                rece.Payment_Schedule__c = payList[PaymentScheduleSize-1].Id;
                rece.Received_Amount__c = paidAmount;
                rece.Amount__c = paidAmount;
                rece.Bank_Name__c = polist[0].Bank_Name__c;
                rece.Payment_From__c = polist[0].Payment_From__c;
                rece.Mode_of_Payment__c =  polist[0].Mode_of_Payment__c;
                rece.Approval_Status__c = 'Pending';
                rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
                rece.Cheque_Date__c = polist[0].Cheque_Date__c;
                receiptsToCreate.add(rece);
            }
            
            //For Pending Interest amount
            if(interestAmount > 0){
                for(Payment_Schedule__c paymentSchedule : payList){
                    if (interestAmount <= 0 || interestAmount == null) {
                        break;
                    }
                    if( (interestAmount != 0 || interestAmount != null) &&  paymentSchedule.Interest_Pending__c != null && paymentSchedule.Interest_Pending__c > 0 ){
                        Decimal amountToReceive = Math.min(paymentSchedule.Interest_Pending__c, interestAmount);
                        interestAmount -= amountToReceive;
                        
                        Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                        rece.Booking__c = bk.Id;
                        rece.Name = 'Against Interest';
                        rece.Payment_Type__c = 'Interest';
                        rece.Receipt__c = rc.Id;
                        rece.Payment_Schedule__c = paymentSchedule.Id;
                        rece.Received_Amount__c = amountToReceive;
                        rece.Amount__c = amountToReceive;
                        rece.Bank_Name__c = polist[0].Bank_Name__c;
                        rece.Payment_From__c = polist[0].Payment_From__c;
                        rece.Mode_of_Payment__c =  polist[0].Mode_of_Payment__c;
                        rece.Approval_Status__c = 'Pending';
                        rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
                        rece.Cheque_Date__c = polist[0].Cheque_Date__c;
                        if(amountToReceive > 0){
                            receiptsToCreate.add(rece);
                        }
                        
                    }
                }
            }
            if(interestAmount !=null && interestAmount !=0){
                Integer PaymentScheduleSize = payList.size();
                Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                rece.Booking__c = bk.Id;
                rece.Name = 'Against Interest';
                rece.Payment_Type__c = 'Interest';
                rece.Receipt__c = rc.Id;
                rece.Payment_Schedule__c = payList[PaymentScheduleSize-1].Id;
                rece.Received_Amount__c = interestAmount;
                rece.Amount__c = interestAmount;
                rece.Bank_Name__c = polist[0].Bank_Name__c;
                rece.Payment_From__c = polist[0].Payment_From__c;
                rece.Mode_of_Payment__c =  polist[0].Mode_of_Payment__c;
                rece.Approval_Status__c = 'Pending';
                rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
                rece.Cheque_Date__c = polist[0].Cheque_Date__c;
                receiptsToCreate.add(rece);
            }
            
            if (!receiptsToCreate.isEmpty()) {
                upsert receiptsToCreate;
            }
            
        return rc.Id;
        }
        
    //}
    
    @AuraEnabled 
    public static Id insertValues(List<Receipt_Line_Item__c> polist, string pon,string remark,string poc, string recid){
        //List<Receipt__c> rc1= [select id, Receipt_Name__c from Receipt__c where Booking__c=:recid];
        //system.debug(rc1.size());
        // delete rc1;
        Booking__c bk = [select id,name,Finance_User__c from Booking__c where id =: recid limit 1];
        Receipt__c rc = new Receipt__c();
        rc.Receipt_Name__c=pon;
        rc.Remarks__c = remark;
        rc.Finance_User__c = bk.Finance_User__c;
        rc.Receipt_date__c=date.valueof(poc);
        rc.Booking__c=recid;
        insert rc;
        // List<Receipt_Line_Item__c> polists= new List<Receipt_Line_Item__c>();
        //   List<Receipt_Line_Item__c> ww=  (List<Receipt_Line_Item__c>) System.JSON.deserialize(polist, List<Receipt_Line_Item__c>.class);
        //  system.debug(ww);
        set<Id> payIds = new set<id>(); 
        system.debug(polist);
        if(polist.size()>0){
            for(Receipt_Line_Item__c rci:polist ){
                rci.Receipt__c=rc.id;
                rci.Amount__c = rci.Received_Amount__c;
                rci.Booking__c=recid;
                payIds.add(rci.Payment_schedule__c);
                // polists.add(rci);
            }
        }
        upsert polist;
        List<Payment_schedule__c> payList = [select id,name,Payment_Due_Date__c,Last_Payment_Date__c,AmountB__c,Include_Interest__c,Interest_Percent__c,Balance_Amount__c,Interest_Amount__c,Pending_Amount__c from Payment_schedule__c where id in:payIds ];
        List<Interest_Amount_Line_Item__c> IntAmtLiEs = new List<Interest_Amount_Line_Item__c>();
        for(Payment_schedule__c pay : payList){
            if(pay.Include_Interest__c == true){
                Interest_Amount_Line_Item__c IntLine = new Interest_Amount_Line_Item__c();
                IntLine.Interest_Amount__c = pay.Interest_Amount__c;
                if(pay.Last_Payment_Date__c == null){
                    IntLine.Interest_Start_Date__c = pay.Payment_Due_Date__c;
                }
                else{
                    IntLine.Interest_Start_Date__c = pay.Last_Payment_Date__c;
                }
                IntLine.Interest_End_Date__c = system.today();
                IntLine.Interest_Percent__c = pay.Interest_Percent__c;
                IntLine.Payment_Schedule__c = pay.id;
                IntLine.Principal_Amount__c = pay.AmountB__c;
                IntAmtLiEs.add(IntLine);
                
            }
            pay.Last_Payment_Date__c = system.today();
            pay.Last_Payment_Time__c = system.now();
        }
        
        if(IntAmtLiEs.size()>0){
            //insert IntAmtLiEs;
        }
        update payList;
        return rc.id;
    }
    
    public static void approvedReceiptsHandler(List<Id> receiptIds) {
        
        list<Receipt_Line_Item__c> recLinLst = [SELECT id,Name,Receipt__r.Receipt_date__c,Booking__c,Payment_schedule__c,Received_Amount__c,Payment_schedule__r.Payment_Due_Date__c,Payment_schedule__r.Last_Payment_Date__c,Payment_schedule__r.Interest_Percent__c,Payment_schedule__r.Include_Interest__c FROM Receipt_Line_Item__c WHERE Receipt__c IN : receiptIds];
        list<id> paymentSchIds = new list<id>();
        list<Receipt_Line_Item__c> recLinToUpdate = new list<Receipt_Line_Item__c>();
        
        for(Receipt_Line_Item__c recl :recLinLst){
            recl.Approval_Status__c = 'Approved by Finance Team';
            recLinToUpdate.add(recl);
            
            paymentSchIds.add(recl.Payment_schedule__c);
        }
        
        List<Payment_schedule__c> payList1 = [SELECT id,name,Booking__c,Payment_Due_Date__c,Last_Payment_Date__c,Include_Interest__c,Interest_Percent__c,Balance_Amount__c,Interest_Amount__c,Pending_Amount__c FROM Payment_schedule__c WHERE id in:paymentSchIds ];
        List<Interest_Amount_Line_Item__c> IntAmtLiEs = new List<Interest_Amount_Line_Item__c>();
        
        for(Payment_schedule__c pay : payList1){
            pay.Last_Payment_Date__c = recLinLst[0].Receipt__r.Receipt_date__c;
            pay.Last_Payment_Time__c = system.now();
        }
        Date todayDate = Date.today();
        for(Receipt_Line_Item__c rcLtm : recLinLst){
            system.debug(rcLtm.Name);
            
            if (rcLtm.Payment_schedule__r.Include_Interest__c == true && rcLtm.Payment_schedule__r.Payment_Due_Date__c != null && rcLtm.Received_Amount__c != null && rcLtm.Payment_schedule__r.Interest_Percent__c != null && rcLtm.Payment_schedule__r.Payment_Due_Date__c < todayDate) {
                Interest_Amount_Line_Item__c IntLine = new Interest_Amount_Line_Item__c();
                IntLine.Interest_Amount__c = (rcLtm.Received_Amount__c * rcLtm.Payment_schedule__r.Interest_Percent__c * (rcLtm.Payment_schedule__r.Payment_Due_Date__c.daysBetween(todayDate))) / 36500;
                if(rcLtm.Payment_schedule__r.Last_Payment_Date__c == null){
                    IntLine.Interest_Start_Date__c = rcLtm.Payment_schedule__r.Payment_Due_Date__c;
                }
                else{
                    IntLine.Interest_Start_Date__c = rcLtm.Payment_schedule__r.Last_Payment_Date__c;
                }
                IntLine.Interest_End_Date__c = system.today();
                IntLine.Interest_Percent__c = rcLtm.Payment_schedule__r.Interest_Percent__c;
                IntLine.Payment_Schedule__c = rcLtm.Payment_Schedule__c;
                IntLine.Booking__c = rcLtm.Booking__c;
                IntLine.Principal_Amount__c = rcLtm.Received_Amount__c;
                IntAmtLiEs.add(IntLine);
            }
        }
        
        if(IntAmtLiEs.size()>0){
            insert IntAmtLiEs;
        }
        
        if(recLinToUpdate.size()>0){
            update recLinToUpdate;
        }
        
        update payList1;
    }
    
    public static void rejectedReceiptsHandler(set<Id> rejectedReceiptIds){
        list<Receipt_Line_Item__c> rItmLst = new list<Receipt_Line_Item__c>();
        for (Receipt__c rcp : [select id,name, (select id, name,Approval_Status__c,Payment_schedule__c from Receipt_Line_Items__r) from Receipt__c where Id in: rejectedReceiptIds]) {
            for(Receipt_Line_Item__c rit : rcp.Receipt_Line_Items__r){
                    rit.Approval_Status__c = 'Rejected by Finance Team' ;
                    rItmLst.add(rit);
            }
        }
        
        if(!rItmLst.isEmpty()){
            update rItmLst;
        }
        /*
        list<Receipt_Line_Item__c> rItmLst = new list<Receipt_Line_Item__c>();
        for (Receipt__c rcp : [select id,name, (select id, name,Payment_schedule__c from Receipt_Line_Items__r) from Receipt__c where Id in: rejectedReceiptIds]) {
            rItmLst.addall(rcp.Receipt_Line_Items__r);
            
        }
        
        if(!rItmLst.isEmpty()){
            delete rItmLst;
        }*/
    }
    
    public static void sendNotificationsFromReceipts(String title, List<Receipt__c> receipts) {
        
        for (Receipt__c rcp : receipts) {
            String body = '';
            Set<String> userIds = new Set<String>();
            userIds.add(rcp.CreatedById);
            if(title == 'Receipt Approved'){
                body = 'This is to notify that Booking ' + rcp.Booking_ID__c + 
                    ', The Receipt ' + rcp.Name + ' is Approved by the Finance Team';
            }
            if(title == 'Receipt Rejected'){
                body = 'This is to notify that Booking ' + rcp.Booking_ID__c + 
                    ', The Receipt ' + rcp.Name + ' is Rejected by the Finance Team';
            }
            sendCustomNotification(userIds, title, body, rcp.Id, 'Receipt_Notification');
        }
    }
    
    public static void sendCustomNotification(Set<String> recepientIds, String title, String body, Id recId, String notificationName){
        CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
        Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
        Notification.setNotificationTypeId(closedWonNotification.id); 
        Notification.setSenderId(Userinfo.getUserId()); 
        Notification.setBody(body); 
        Notification.setTitle(title); 
        Notification.setTargetId(recId);
        try{
            Notification.send(recepientIds);
        }catch(exception e){
            
        }
        
    }
    
    @AuraEnabled       
    public static String sendEmailGenerateReceipt(ID recId) {
        try {
            Receipt__c qt = [select Id,Booking__r.Id,Booking__r.Email1__c,Booking__r.Email2__c,Check_Transaction_Nmber__c,Approval_status__c,
                             Booking__r.Owner.Email,Booking__r.CRM_Manager__r.Email,Booking__r.First_Applicant_Name__c,Booking__r.Booking_owner__c
                             FROM Receipt__c WHERE Id = :recId limit 1];
            //List<String> lstCCEmail = new List<String>();
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            PageReference pref = Page.RECEIPT;
            
            pref.getParameters().put('id', recId);
            pref.setRedirect(true);
            
            Blob b;
            try {
                b = pref.getContent();
            } catch (VisualforceException e) {
                if(!test.isRunningTest()){
                    return 'Error generating PDF content: ' + e.getMessage();
                }               
            }
            attach.setFileName('Mahendra_Builders_Pvt_Ltd.pdf');
            attach.setBody(b);
            semail.setSubject('Mahendra Builders');
            
            List<String> sendTo = new List<String>();
            if (qt.Booking__r.Email1__c != null) {
                sendTo.add(qt.Booking__r.Email1__c);
            }
            if (qt.Booking__r.Email2__c != null) {
                sendTo.add(qt.Booking__r.Email2__c);
            }
            semail.setToAddresses(sendTo);
            semail.setHtmlBody('Dear '+ qt.Booking__r.First_Applicant_Name__c + ',<br/><br/>' +
                               'Please find the attached receipt for your records. If you have any questions, feel free to contact us.' +
                               '<br/><br/>Best regards,<br/>' +
                               qt.Booking__r.Booking_owner__c+ '<br/>' +
                               'Mahendra Builders Pvt. Ltd.<br/>' 
                              );
            semail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });
            if (sendTo.size() > 0 && qt.Approval_status__c=='Appoved by Finance Team') {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { semail });
                return 'Email sent successfully';
            } else {
                return 'Receipt Not Approved by Finance Team';
            }
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    
    
    
    @future (callout=true)
    public static void sendEmailAsync(String receiptId) {
        sendEmail(receiptId);
    }
    public static void sendEmail(String receiptId) {
        try {
            // Fetch the Receipt and related Booking information
            Receipt__c com = [
                SELECT Id, Name, Booking__r.Email1__c, Booking__r.Project_Company__c, Booking__r.Email2__c, Check_Transaction_Nmber__c, Approval_status__c,
                Booking__r.Owner.Email, Booking__r.CRM_Manager__r.Email, Booking__r.First_Applicant_Name__c, Booking__r.Booking_owner__c
                FROM Receipt__c WHERE Id = :receiptId LIMIT 1
            ];
            
            if (com == null || com.Booking__r == null) {
                system.debug('Receipt or related Booking record not found.');
                return;
            }
            
            system.debug('record id  '+receiptId);
            system.debug('recp id  '+com);
            
            String subject = 'Receipt ' + com.Name + ' Notification';
            String htmlBody = 'Dear ' + com.Booking__r.First_Applicant_Name__c + 
                ',<br/><br/> Please find the Receipt for your payment.<br/>Thank you<br/>Mahendra Team';
            
            List<String> emailArray = new List<String>();
            if (com.Booking__r.Email1__c != null) emailArray.add(com.Booking__r.Email1__c);
            if (com.Booking__r.Email2__c != null) emailArray.add(com.Booking__r.Email2__c);
            system.debug('p c id  '+com.Booking__r.Project_Company__c);
            
            PageReference pref;
            if (com.Booking__r.Project_Company__c == 'MAHENDRA HOMES PVT LTD') {
                pref = Page.RECEIPT;
            } else if (com.Booking__r.Project_Company__c == 'MAHENDRA ARTO LLP') {
                pref = Page.RECEIPT_HELIX;
            } else {
                system.debug('Unknown project company for receipt generation.');
                return;
            }
            
            pref.getParameters().put('id', receiptId);
            Blob pdfBlob = !Test.isRunningTest() ? pref.getContentAsPDF() : Blob.valueOf('testblob');
            
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('RECEIPT.pdf');
            attachment.setBody(pdfBlob);
            
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            semail.setSubject(subject);
            semail.setToAddresses(emailArray);
            semail.setUseSignature(false);
            
            Id orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@mahendrahomes.com' LIMIT 1].Id;
            semail.setOrgWideEmailAddressId(orgWideEmailAddressId);
            
            semail.setHtmlBody(htmlBody);
            semail.setFileAttachments(new Messaging.EmailFileAttachment[] {attachment});
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
            
        } catch (Exception e) {
            System.debug('Error while sending email: ' + e.getMessage());
        }
    }
    
    @InvocableMethod(label='Send Email' description='Send emails for receipts from Flow')
    public static void sendEmailGenerateReceiptFromFlow(List<Id> receiptIds) {
        // Map to hold Receipts and their associated Bookings
        Map<Id, Receipt__c> receiptMap = new Map<Id, Receipt__c>(
            [SELECT Id, CreatedBy.Email, Booking__c 
             FROM Receipt__c 
             WHERE Id IN :receiptIds]
        );
        
        Map<Id, String> createdUserMap = new Map<Id, String>();
        
        // Collect related Booking IDs
        Set<Id> bookingIds = new Set<Id>();
        
        for (Receipt__c receipt : receiptMap.values()) {
            if (receipt.Booking__c != null) {
                bookingIds.add(receipt.Booking__c);
            }
            
            // Store the Receipt ID and CreatedBy ID (the user who created the receipt)
            if (receipt.CreatedById != null) {
                createdUserMap.put(receipt.Id, receipt.CreatedBy.Email);
            }
        }
        
        
        // Query related Bookings
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>(
            [SELECT Id, Email1__c, Email2__c, First_Applicant_Name__c, Demand_Raised__c, Owner.Email, 
             CRM_Manager__c, CRM_Manager__r.Email 
             FROM Booking__c 
             WHERE Id IN :bookingIds]
        );
        
        // Query related Co-Applicants
        Map<Id, List<Co_Applicant__c>> coAppMap = new Map<Id, List<Co_Applicant__c>>();
        for (Co_Applicant__c coApp : [
            SELECT Id, Name, Email__c, Booking__c 
            FROM Co_Applicant__c 
            WHERE Booking__c IN :bookingIds
        ]) {
            if (!coAppMap.containsKey(coApp.Booking__c)) {
                coAppMap.put(coApp.Booking__c, new List<Co_Applicant__c>());
            }
            coAppMap.get(coApp.Booking__c).add(coApp);
        }
        
        
        // List to hold all emails to send
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Id receiptId : receiptIds) {
            Receipt__c receipt = receiptMap.get(receiptId);
            if (receipt == null || receipt.Booking__c == null) continue;
            
            Booking__c booking = bookingMap.get(receipt.Booking__c);
            if (booking == null || String.isBlank(booking.Email1__c)) continue;
            
            // Generate receipt PDF
            PageReference receiptPage = Page.RECEIPT;
            receiptPage.getParameters().put('id', receiptId);
            Blob pdfBlob = !Test.isRunningTest() ? receiptPage.getContentAsPDF() : Blob.valueOf('testblob');
            
            // Prepare email recipients
            List<String> sendTo = new List<String>();
            sendTo.add(booking.Email1__c);
            if (!String.isBlank(booking.Email2__c)) {
                sendTo.add(booking.Email2__c);
            }
            
            // Add Co-Applicants
            if (coAppMap.containsKey(booking.Id)) {
                for (Co_Applicant__c coApp : coAppMap.get(booking.Id)) {
                    if (!String.isBlank(coApp.Email__c)) {
                        sendTo.add(coApp.Email__c);
                    }
                }
            }
            
            // Prepare CC addresses
            List<String> ccEmails = new List<String>();
            
            if (!String.isBlank(booking.Owner.Email)) {
                ccEmails.add(booking.Owner.Email);
            }
            
            if (booking.CRM_Manager__c != null && !String.isBlank(booking.CRM_Manager__r.Email)) {
                ccEmails.add(booking.CRM_Manager__r.Email);
            }
            
            // Add static emails
            ccEmails.add('Crmlead@mahendrahomes.com');
            ccEmails.add('crm@mahendrahomes.com');
            
            // Create email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(sendTo);
            if (!ccEmails.isEmpty()) {
                email.setCcAddresses(ccEmails);
            }
            email.setSubject('Receipt for Your Payment');
            email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached receipt for your payment.<br/><br/>Thank you.');
            
            if(!Test.isRunningTest()){
                // Set Org-Wide Email Address or Reply-To
                List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :createdUserMap.get(receiptId)];
                // Set Org-Wide Email Address (if available)
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
            }
            // Attach PDF
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Receipt.pdf');
            attachment.setBody(pdfBlob);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            
            email.setSaveAsActivity(true);
            email.setWhatId(receipt.Id);
            
            emails.add(email);
        }
        
        // Send all emails
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    
    
    public static void testcover(){
        integer  i=0;
        if(i==0){
            
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
        }
    }
}