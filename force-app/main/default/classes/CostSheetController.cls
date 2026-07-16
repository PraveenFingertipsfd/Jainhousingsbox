public with sharing class CostSheetController {
    
    @AuraEnabled
    public static Plot__c getUnitDetailsFromBookingRequest(Id bookingRequestId) {
        system.debug(bookingRequestId);
        // List<Plot__c> plotList = new List<Plot__c>();
        Booking_Request__c br = [select id,Unit__c from Booking_Request__c where ID =:bookingRequestId ];
        Plot__c  plotList = [select Id, Name,Project__c,Project__r.Name,BHK_Type__c,Block1__c,Floor__c,Floor_Rise_Charge__c,Plot_Number__c,Price_Per_Sq_Ft__c,Super_built_up_area__c,Facing__c,TAXES__c,Built_up_area__c,Proportionate_Common_Area__c
                             ,UDS__c,Category__c,Premium_Status__c,Balcony_Area__c,Carpet_Area__c from Plot__c where id =: br.Unit__c ];
        
        system.debug('plotList: ' + plotList);
        return plotList;
    }
    @AuraEnabled
    public static Id insertQuote(Quote__c quoteRecord) {
        insert quoteRecord;
        return quoteRecord.Id;
    }

    public class PlotWrapper {
        @AuraEnabled public Plot__c plot;
        @AuraEnabled public Decimal blockedPrice;
    }

    @AuraEnabled(cacheable=true)
    public static PlotWrapper getUnitFromBooking(Id bookingId, String unitId) {
        Booking_Request__c br = [ SELECT Unit__c, Blocked_Price__c FROM Booking_Request__c WHERE Id = :bookingId LIMIT 1 ];

        Plot__c plot = new Plot__c();

        if (unitId != null && unitId != '') {
            plot = [
                SELECT Id, Name, Project__c, Project__r.Name, BHK_Type__c, Block1__c, Floor__c,
                    Floor_Rise_Charge__c, Plot_Number__c, Price_Per_Sq_Ft__c, Super_built_up_area__c,
                    Facing__c, TAXES__c, Built_up_area__c,
                    Proportionate_Common_Area__c, UDS__c, Category__c,
                    Premium_Status__c, Balcony_Area__c, Carpet_Area__c,
                    Corpus_Fund__c, Maintenance_Charge__c, GST_For_Other_Charges__c, GST1__c,
                    Terrace_Area__c, Total_Maintenance_Charge__c,
                	Project__r.Stilt_Parking_Charges__c,
                	Project__r.Basement_Parking_Charges__c,
                	Project__r.First_Level_Parking_Charges__c,
                	Project__r.Second_Level_Parking_Charges__c
                FROM Plot__c WHERE Id = :unitId LIMIT 1 ];
        } else {
            plot = [ SELECT Id, Name, Project__c, Project__r.Name, BHK_Type__c, Block1__c, Floor__c,
                    Floor_Rise_Charge__c, Plot_Number__c, Price_Per_Sq_Ft__c, Super_built_up_area__c,
                    Facing__c, TAXES__c, Built_up_area__c,
                    Proportionate_Common_Area__c, UDS__c, Category__c,
                    Premium_Status__c, Balcony_Area__c, Carpet_Area__c,
                    Corpus_Fund__c, Maintenance_Charge__c, GST_For_Other_Charges__c, GST1__c,
                    Terrace_Area__c, Total_Maintenance_Charge__c,
                    Project__r.Stilt_Parking_Charges__c,
                	Project__r.Basement_Parking_Charges__c,
                	Project__r.First_Level_Parking_Charges__c,
                	Project__r.Second_Level_Parking_Charges__c
                    FROM Plot__c WHERE Id = :br.Unit__c LIMIT 1 ];
        }

        PlotWrapper result = new PlotWrapper();
        result.plot = plot;
        result.blockedPrice = br.Blocked_Price__c;
        return result;
    }

    @AuraEnabled
    public static Boolean sendCostsheetEmailLink(string costSheetId){
        Quote__c cosht = [select id, Booking_Request__c from Quote__c where Id =: costSheetId];
        cosht.Email_Sent_Date_Time__c = system.now();
       
        //added by karthik 26-07
        cosht.Is_Form_Responded__c = false;
        update cosht;
        
        system.debug(costSheetId);
        if(cosht.Booking_Request__c == null){
            return false;
        }
        
        Booking_Request__c brq = [select id,IsResponded__c,Unit__c,Email__c,Mobile__c from Booking_Request__c where Id =: cosht.Booking_Request__c limit 1];
        string CusEmail = brq.Email__c;
        system.debug(CusEmail);
        if(CusEmail == null || CusEmail == ''){
            return false;
        }
        
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        string urlval = label.Org_url;
        Site mySite = [SELECT Id, Name, Subdomain, UrlPathPrefix FROM Site WHERE Name = 'Booking_Fill_Site' LIMIT 1];
        /*string  htmlBody='Dear Customer,<br/><br/>Thank you for choosing Jain Housing. We have attached a Hyperlink to fill and submit the Booking Form. <br/>To Open the Booking Form page, please click on the link below. <br/>'+
            '<a href="'+urlval+'/'+ mySite.UrlPathPrefix +'?Id='+costSheetId+'&BkReqId='+brq.Id+'">Click here to Fill for Booking Form</a><br/>'+
            'We pride ourselves on providing high-quality Constructions, and we are confident that you will be completely satisfied with the results.<br/> If you have any questions or concerns, please don\'t hesitate to contact us. We are always happy to help.<br/><br/>'+'Thank you<br/>Jain Housing';*/
        
        //semail.setSubject('Jain Housing\'s Booking Request Page');
        String htmlBody = 'Dear Customer,<br/><br/>' +
            'Greetings from Jain Housing!<br/><br/>' +
            'Thank you for choosing Jain Housing as your trusted partner in finding your dream home. We are pleased to share with you the Booking Allotment Form and the Payment Schedule form related to your flat booking.<br/><br/>' +
            'Please find the attached documents for your reference:<br/><br/>' +
            '<strong>Booking Allotment Form</strong><br/>' +
            '<strong>Payment Schedule / Cashflow Form</strong><br/><br/>' +
            'These documents contain important details regarding your flat allotment and the associated payment structure. We kindly request you to review them thoroughly and adhere. Get in touch with us in case you have any queries or require further clarification.<br/><br/>' +
            'To access and fill the Booking Form online, please click the link below:<br/><br/>' +
            '<a href="' + urlval + '/' + mySite.UrlPathPrefix + '?Id=' + costSheetId + '&BkReqId=' + brq.Id + '">Click here to Fill the Booking Form</a><br/><br/>' +
            'We look forward to assisting you throughout your home-buying journey.<br/><br/>' +
            'Warm regards,<br/>' +
            'Customer Relations Team<br/>' +
            '<strong>Jain Housing LLP.</strong>';
        semail.setSubject('Booking Allotment Form & Cash Flow Details – Jain Housing');
        semail.setToAddresses(new String[]{CusEmail});
        semail.setHtmlBody(htmlBody);
        Messaging.sendEmail(new  list<Messaging.SingleEmailMessage>{semail});

        // Send Cost Sheet WhatsApp (parallel to email)
        WhatsAppTemplates.sendTemplateToNumbers('Cost_Sheet_WhatsApp', new List<String>{ brq.Mobile__c });

        return true;
    }
    
    @AuraEnabled
    public static databox getPaymentSchedules1(String Pay, String Project){
        system.debug(Pay +'==='+Project);
        List<Master_payment_schedule__c> mpsList = [select Id,Project__C,S_No__c,Tentative_TimeLine__c,Name,Payment_Percent__c,Amount__c,Completed_Date__c,Due_Date__c,Status__c from Master_payment_schedule__c where Project__r.Id =:Project ORDER BY S_No__c ASC];
        
        databox db = new databox();
        
        List<Payment_schedule__c> schdules = new List<Payment_schedule__c>();
        List<Master_payment_schedule__c> Master;
        string paymentType;
        
        if(Pay =='Standard'){
            system.debug('Pay : '+ Pay);
            system.debug('Project : '+ Project);
            
            Master=[select id,Project__C,S_No__c,Name,Include_Interest__c,Tentative_TimeLine__c,Payment_Percent__c,Completed_Date__c,Due_Date__c,Status__c from Master_payment_schedule__c where  Project__r.Id =:Project ORDER BY S_No__c ASC];
            system.debug('Master : '+ Master);
            //system.debug(Master[0]);
            
            for(Master_payment_schedule__c mps : Master){
                system.debug('Inside Master Payment For Loop');
                Payment_schedule__c ps = new Payment_schedule__c();
                ps.Master_Payment_Schedule__c = mps.Id;
                ps.Payment_percent__c = mps.Payment_Percent__c;
                ps.Name = mps.Name;
                ps.status__c=mps.Status__c;
                ps.S_No__c = mps.S_No__c;
                ps.Tentative_TimeLine__c = mps.Tentative_TimeLine__c;
                ps.Include_Interest__c = mps.Include_Interest__c;
                //ps.Amount__c = (db.grandTotal * mps.Payment_Percent__c)/100;
                
                system.debug(ps.Amount__c);
                //ps.Amount__c = ps.Amount__c.setScale(2);
                
                schdules.add(ps);
            }
            //db.MasterpayList = Master;
            db.payList = schdules;
            db.paymentSum = 0.00;
            db.totalPercent = 0;  
            db.RecivedAmount=0;
            db.RecivedAmountTotal=0;
            db.RecivedPercent=0;
            db.scheduledAmount=0;
            system.debug('inside');
        }
        else{
            db.payList = schdules;
            db.paymentSum = 0.00;
            db.totalPercent = 0;
            db.RecivedAmount=0;
            db.RecivedAmountTotal=0;
            db.RecivedPercent=0;
            db.scheduledAmount=0;
        }
        if(schdules.size()>0 && Pay=='Custom'){
            
            for(Payment_schedule__c ps : schdules){
                //system.debug(ps.Amount1__c);
                db.paymentSum=0.00;
                //db.paymentSum += ps.Amount1__c;
                if(ps.Received_Amount__c ==null){
                    ps.Received_Amount__c=0;
                }
                if(ps.Recived_Per__c ==null){
                    ps.Recived_Per__c=0;
                }
                db.RecivedAmountTotal +=ps.Received_Amount__c;
                system.debug('ps.Payment_percent__c'+ps.Payment_percent__c);
                system.debug('db.totalPercent'+db.totalPercent);
                
                db.totalPercent += ps.Payment_percent__c;
                system.debug('db.totalPercent'+db.totalPercent);
                
                //db.RecivedAmount +=ps.Received_Amount__c;
                
                
            }
        }
        if(db.payList.size()==0){
            db.payList = null;
        }
        system.debug(db.paymentSum); 
        system.debug(db); 
        
        return db;
        // return mpsList;
    }
    
    //added by karthik 2409
    @AuraEnabled
    public static databox getPaymentSchedules(String Pay, String Project){
        system.debug(Pay +' === ' + Project);
        
        databox db = new databox();
        List<Payment_schedule__c> schedules = new List<Payment_schedule__c>();
        
        // Fetch from Master Payment Schedule always
        List<Master_payment_schedule__c> masterList = [
            SELECT Id, Project__c, S_No__c, Name, Include_Interest__c, Tentative_TimeLine__c,
            Payment_Percent__c, Completed_Date__c, Due_Date__c, Status__c
            FROM Master_payment_schedule__c
            WHERE Project__r.Id = :Project
            ORDER BY S_No__c ASC
        ];
        
        for (Master_payment_schedule__c mps : masterList) {
            Payment_schedule__c ps = new Payment_schedule__c();
            ps.Master_Payment_Schedule__c = mps.Id;
            ps.Payment_percent__c = mps.Payment_Percent__c;
            ps.Payment_Due_Date__c = mps.Due_Date__c;
            ps.Name = mps.Name;
            ps.status__c = mps.Status__c;
            ps.S_No__c = mps.S_No__c;
            ps.Tentative_TimeLine__c = mps.Tentative_TimeLine__c;
            ps.Include_Interest__c = mps.Include_Interest__c;
          
            schedules.add(ps);
        }
        
        db.payList = schedules;
        db.paymentSum = 0.00;
        db.totalPercent = 0;  
        db.RecivedAmount = 0;
        db.RecivedAmountTotal = 0;
        db.RecivedPercent = 0;
        db.scheduledAmount = 0;
        
        system.debug('Final DB: ' + db);
        return db;
    }
    
    public class databox{
        @AuraEnabled 
        public List<Payment_schedule__c> payList;
        @AuraEnabled
        public List<Master_payment_schedule__c> MasterpayList;
        @AuraEnabled
        public Decimal grandTotal;
        @AuraEnabled
        public Decimal paymentSum;
        @AuraEnabled
        public Decimal RecivedAmountTotal;
        @AuraEnabled
        public Decimal totalPercent;
        @AuraEnabled
        public Decimal RecivedAmount;
        @AuraEnabled
        public string objectName;
        @AuraEnabled
        public string projectName;
        @AuraEnabled
        public string flatNumber;
        @AuraEnabled
        public string blockName;
        @AuraEnabled
        public Decimal RecivedPercent;
        @AuraEnabled
        public Decimal ScheduledAmount;
        @AuraEnabled
        public Decimal TotalOutStandingDueAmount;
        @AuraEnabled
        public Decimal TotalPaidAmount;
    }
    
    @AuraEnabled
    public static void insertSchedules1(List<Payment_schedule__c> payList, decimal gt,string quoteid){
        String sObjName = Id.valueOf(quoteid).getSObjectType().getDescribe().getName();
        List<Payment_schedule__c> schduleList = new List<Payment_schedule__c>();
        list<booking__c>blist=new list<booking__C>();
        List<Quote__c> quo = [Select id,name,Payment_Type__c from Quote__c where id=:quoteid];
        if(quo[0].Payment_Type__c=='Standard')
        {
            for(Payment_schedule__c pay : payList){
                Payment_schedule__c ps = new Payment_schedule__c();
                ps.Name = pay.Name;
                ps.Payment_Percent__c = pay.Payment_Percent__c;
                ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
                ps.Amount__c = pay.Amount__c;
                ps.Master_Payment_Schedule__c = pay.Master_Payment_Schedule__c;
                ps.Include_Interest__c = pay.Include_Interest__c;
                ps.S_No__c = pay.S_No__c;
                if(pay.status__c == 'Completed')
                	ps.status__c = pay.status__c;
                ps.Cost_Sheet__c = quoteid;
                schduleList.add(ps);
            }
        }else if(quo[0].Payment_Type__c=='Custom'){
            Integer sno = 1;
            for(Payment_schedule__c pay : payList)
            {
                system.debug(pay);
                Payment_schedule__c ps = new Payment_schedule__c();
                //ps = pay;
                ps.Name = pay.Name;
                ps.Payment_Percent__c = pay.Payment_Percent__c;
                if(pay.status__c == 'Completed')
                	ps.status__c = pay.status__c;
                ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
                //ps.Completed_Date__c = pay.Completed_Date__c;
                ps.Amount__c = pay.Amount__c;
                ps.Cost_Sheet__c = quoteid;
                ps.S_No__c = sno; 
                sno++;
                schduleList.add(ps);
            }
        }
        system.debug( 'schduleList :'+ schduleList);
        upsert schduleList;
        if(quo[0].Payment_Type__c=='Standard'){
          //  PaymentScheduleMerger1.handleRelatedPaymentSchedules(quo);
        }
        system.debug('success');
    }
    
    //added by karthik 30-09
    @AuraEnabled
    public static void insertSchedules(List<Payment_schedule__c> payList, Decimal gt, String quoteid) {
        List<Payment_schedule__c> toUpsert = new List<Payment_schedule__c>();
        Quote__c q = [SELECT Id, Payment_Type__c FROM Quote__c WHERE Id = :quoteid LIMIT 1];
        
        if (q.Payment_Type__c == 'Standard') {
            for (Payment_schedule__c pay : payList) {
                Payment_schedule__c ps = new Payment_schedule__c();
                ps.Name = pay.Name;
                ps.Payment_Percent__c = pay.Payment_Percent__c;
                ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
                ps.Amount__c = pay.Amount__c;
                ps.Master_Payment_Schedule__c = pay.Master_Payment_Schedule__c;
                ps.Include_Interest__c = pay.Include_Interest__c;
                ps.S_No__c = pay.S_No__c;               // preserve sequence
                if (pay.status__c == 'Completed') ps.status__c = pay.status__c;
                ps.Cost_Sheet__c = quoteid;
                ps.Is_Custom__c = false;               // Standard rows are never custom
                toUpsert.add(ps);
            }
        } else { // Custom
            for (Payment_schedule__c pay : payList) {
                Payment_schedule__c ps = new Payment_schedule__c();
                ps.Name = pay.Name;
                ps.Payment_Percent__c = pay.Payment_Percent__c;
                if (pay.status__c == 'Completed') ps.status__c = pay.status__c;
                ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
                ps.Amount__c = pay.Amount__c;
                ps.Cost_Sheet__c = quoteid;
                
                // Preserve incoming sequence; if null (new rows), push them to the end later in LWC
                ps.S_No__c = pay.S_No__c;
                
                if(!pay.Is_Custom__c)
                    ps.Master_Payment_Schedule__c = pay.Master_Payment_Schedule__c;
                
                // Persist customization flag from LWC comparison
                ps.Is_Custom__c = pay.Is_Custom__c;
                
                toUpsert.add(ps);
            }
        }
        
        upsert toUpsert;
        System.debug('Inserted/Updated schedules: ' + toUpsert);
    }

    
    @AuraEnabled
    public static void submitRecordForApproval(String recordId) {
        /* Check if record is already in approval
        String currentStatus = getApprovalStatus(recordId);
        
        if (currentStatus == 'Pending') {
            throw new AuraHandledException('This record is already in approval process.');
        }*/
        
        // Specify your approval process name
        String approvalProcessName = 'Cost_Sheet_Approval';
        
        // Create approval request
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(recordId);
        req.setProcessDefinitionNameOrId(approvalProcessName);
        req.setComments('Please check the Discount price and Additional Parking Requisition');
        //req.setComments(currentStatus == 'Rejected' ? 'Resubmitted for approval' : 'Submitted for approval');
        
        try {
            Approval.ProcessResult result = Approval.process(req);
            if (!result.isSuccess()) {
                throw new AuraHandledException('Approval submission failed: ' + result.getErrors()[0].getMessage());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting for approval: ' + e.getMessage());
        }
    }
    
    /*
    @AuraEnabled
    public static String getApprovalStatus(String recordId) {
        List<ProcessInstance> processes = [
            SELECT Id, Status, (SELECT Id, StepStatus FROM Steps ORDER BY CreatedDate DESC LIMIT 1)
            FROM ProcessInstance 
            WHERE TargetObjectId = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (processes.isEmpty()) {
            return 'Not Submitted';
        }
        
        ProcessInstance latest = processes[0];
        
        // Check if there are steps (might be just started)
        if (latest.Steps.isEmpty()) {
            return 'Pending';
        }
        
        ProcessInstanceStep latestStep = latest.Steps[0];
        
        if (latestStep.StepStatus == 'Approved' && latest.Status == 'Approved') {
            return 'Approved';
        } else if (latestStep.StepStatus == 'Rejected') {
            return 'Rejected';
        } else {
            return 'Pending';
        }
    }*/
    
    @AuraEnabled //abandon cost sheet component
    public static Result abandonCostSheet(String recordId) {
        Result result = new Result();
        try {
            // Check if record is in approval process
            ProcessInstanceWorkitem[] workItems = [
                SELECT Id FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :recordId
                LIMIT 1
            ];
            
            // If in approval process, recall it
            if (!workItems.isEmpty()) {
                Approval.ProcessWorkitemRequest recallRequest = new Approval.ProcessWorkitemRequest();
                recallRequest.setAction('Removed');
                recallRequest.setWorkitemId(workItems[0].Id);
                Approval.process(recallRequest);
            }
            
            // Update the Quote record
            Quote__c quote = new Quote__c(
                Id = recordId,
                Status__c = 'Abandoned',
                Cost_Sheet_Abandoned_Date__c = System.now()
            );
            update quote;
            
            result.isSuccess = true;
        } catch (Exception e) {
            result.isSuccess = false;
            result.errorMessage = e.getMessage();
        }
        return result;
    }
    
    public class Result {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        
        public Result() {
            isSuccess = false;
            errorMessage = '';
        }
    }
    
}