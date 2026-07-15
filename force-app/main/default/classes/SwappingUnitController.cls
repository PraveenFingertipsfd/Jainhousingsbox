public class SwappingUnitController {
   /* @AuraEnabled
    public static List<Plot__c> getPlots(string recId){
        system.debug('recId:' + recId);
        list<Booking__c>clist=[select id ,Project__c,Plot__c from Booking__c where id =:recId ];
        Plot__c pl = [select id,name,Block__c from Plot__c where id =: clist[0].Plot__c];
        string project=clist[0].Project__c;
        system.debug(project);
        List<Plot__c>plotList=new List<Plot__c>();
        
        string obj='Plot__c';
        plotList = [select Id,Name,Project__c,Covered_Park_Parking__c,Basic_Price1__c,Premium_Charge__c,Floor_Rise__c,Price_Per_Sq_Ft__c,Super_built_up_area__c from Plot__c where Block__c =: pl.Block__c and Status__c = 'Available'];
       
        system.debug('recId:' + plotList);
        return plotList;
    }*/
    
    @AuraEnabled
    public static Booking__c getBooking(string recId){
        Booking__c booking = [select id ,Project__c,Project1__c,Plot__c,Plot__r.Name,Swap_Extra_Covered_Parking_Charges__c,Swap_Floor__c,Swap_Floor_Rise__c,Swap_Funding_Type__c,Swap_GST__c,Swap_Other_Charges__c,Swap_Price_Per_Sq_Ft__c,Swap_Super_Built_Up_Area__c,Swap_TAXES__c,Swap_Block__c,Swap_Covered_Park_Parking__c,Swap_Extra_Covered_Parking_Slots__c,Swap_Mode_of_Payment__c,Swap_Solar_Charges__c,Swap_Tower__c,Swap_Unit__c,Swap_Unit_Status__c from Booking__c where id =:recId Limit 1];
		return booking;
    }
    @AuraEnabled
    public static Plot__c getUnit(string unitId){
        Plot__c pl = [select id,Covered_Park_Parking__c,Other_Charges__c,Premium_Charge__c,Floor_Rise__c,Price_Per_Sq_Ft__c,Floor__c,Block__c,Tower__c,name from Plot__c where id =: unitId Limit 1];
    	return pl;
    }
    
    @AuraEnabled
    public static String saveOppPlot(Booking__c oppPlot, Id prevBooking){
        Booking__c book = [select id,SLead__c,name,Sale_Agreement_Completed__c,First_Disbursement_Received__c from Booking__c where Id =: prevBooking];
        system.debug('oppPlot:' + oppPlot);
        try{
            oppPlot.Id = prevBooking;
            oppPlot.SLead__c = book.SLead__c;
            update oppPlot;
            
            system.debug('-------'+ oppPlot.Id);
            if(book.Sale_Agreement_Completed__c == false){
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments('Requesting For Swapping');
                req1.setObjectId(book.Id);
                req1.setSubmitterId(userInfo.getUserId()); 
                req1.setProcessDefinitionNameOrId('Request_Swap_Unit_Before_Registration');
                req1.setSkipEntryCriteria(true);
                Approval.ProcessResult result = Approval.process(req1);
            }
            return oppPlot.id;
        }
        catch(DmlException ex){
            system.debug(ex.getMessage());
            return 'notc';
        }
    }
    
    @AuraEnabled
    public static List<String> getPaymentTypePicklistValues() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Payment_Type__c.getDescribe();
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        return paymentTypeValues;
    }
    
    @AuraEnabled
    public static List<Master_payment_schedule__c> getPaymentSchedules(String Pay, String Project){
        List<Master_payment_schedule__c> mpsList = [select Id,Project__C,S_No__c,Name,Payment_Percent__c,Amount__c,Completed_Date__c,Due_Date__c,Status__c from Master_payment_schedule__c where Project__r.Name =:Project ORDER BY S_No__c ASC];
        /*databox db = new databox();
        
        List<Payment_schedule__c> schdules = new List<Payment_schedule__c>();
        List<Master_payment_schedule__c> Master;
        string paymentType;
        if(Pay =='Standard'){
            system.debug('Pay : '+ Pay);
            system.debug('Project : '+ Project);
            Master=[select id,Project__C,S_No__c,Name,Payment_Percent__c,Completed_Date__c,Due_Date__c,Status__c from Master_payment_schedule__c where Project__r.Name =:Project ORDER BY S_No__c ASC];
            system.debug('Master : '+ Master);
            for(Master_payment_schedule__c mps : Master){
                system.debug('Inside Master Payment For Loop');
                Payment_schedule__c ps = new Payment_schedule__c();
                ps.Master_Payment_Schedule__c = mps.Id;
                ps.Payment_percent__c = mps.Payment_Percent__c;
                ps.Name = mps.Name;
                ps.S_No__c = mps.S_No__c;
                system.debug(ps.Amount__c);
                schdules.add(ps); 
            }
            db.payList = schdules;
            db.paymentSum = 0.00;
            db.totalPercent = 0;  
            db.RecivedAmount=0;
            db.RecivedAmountTotal=0;
            db.RecivedPercent=0;
            db.scheduledAmount=0;
            system.debug('inside');
        }
        else 
        {
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
                system.debug(ps.Amount1__c);
                db.paymentSum=0.00;
                db.paymentSum += ps.Amount1__c;
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
                
            }
        }
        if(db.payList.size()==0){
            db.payList = null;
        }
        system.debug(db.paymentSum); 
        system.debug(db); 
        
        // return db;*/
        return mpsList;
    }
    
    @AuraEnabled
    public static void insertSchedules(List<Payment_schedule__c> payList,string quoteid){
        system.debug('payList:' + payList[0].Payment_Percent__c);
        system.debug( payList);
        System.debug('quoteid : '+ quoteid);
        String sObjName = Id.valueOf(quoteid).getSObjectType().getDescribe().getName();
        System.debug('sObjName : '+ sObjName);
        List<Payment_schedule__c> schduleList = new List<Payment_schedule__c>();
        list<booking__c>blist=new list<booking__C>();
        List<Booking__c> quo = [Select id,name,Payment_Type__c from Booking__c where id=:quoteid];
        if(quo[0].Payment_Type__c=='Standard')
        {
            
            for(Payment_schedule__c pay : payList){
                Payment_schedule__c ps = new Payment_schedule__c();
                
                ps.Name = pay.Name;
                ps.Payment_Percent__c = pay.Payment_Percent__c;
                ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
                ps.Amount__c = pay.Amount__c;
                ps.Master_Payment_Schedule__c = pay.Master_Payment_Schedule__c;
                ps.S_No__c = pay.S_No__c;
                ps.Booking__c = quoteid;
                schduleList.add(ps);
                system.debug('ddbshbhvfhv');
            }
            
        }else if(quo[0].Payment_Type__c=='Custom'){
            for(Payment_schedule__c pay : payList)
            {
                system.debug(pay);
                
                Payment_schedule__c ps = new Payment_schedule__c();
                ps = pay;
                //ps.quote__c = quoteid;
                
                schduleList.add(ps);
            }
        }
        system.debug( 'schduleList :'+ schduleList);
        upsert schduleList;
        if(quo[0].Payment_Type__c=='Standard'){
            //PaymentScheduleMerger1.handleRelatedPaymentSchedulesBooking(quo);
        }
        system.debug('success');
    }
    
   /* @AuraEnabled
    public static databox QuoteCreate(String Leadid,String Quoteid)
    {
        databox db = new databox();
        String sObjName = Id.valueOf(Quoteid).getSObjectType().getDescribe().getName();
        db.objectName = sObjName;
        List<Payment_schedule__c> schdules;
        string paymentType;
        schdules = [SELECT Id,Name,Payment_percent__c,Recived_Per__c,Amount__c,S_No__c,status__c,Booking__c,Quote__c,Quote__r.Grand_Total__c,Quote__r.project__c,Quote__r.unit__r.Name,Received_Amount__c,Amount1__c FROM Payment_schedule__c WHERE Quote__c =:Quoteid  ORDER BY S_No__c ASC];
        Quote__c qt = [SELECT Id,Grand_Total__c,project__c,Payment_Type__c,unit__r.Name FROM Quote__c WHERE Id=:Quoteid LIMIT 1];
        db.grandTotal = qt.Grand_Total__c;
        db.projectName = qt.project__c;
        paymentType = qt.Payment_Type__c;
        db.flatNumber =qt.unit__r.Name;
        return db;
    }*/
    
    
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
        public Decimal RecivedPercent;
        @AuraEnabled
        public Decimal ScheduledAmount;
        @AuraEnabled
        public Decimal TotalOutStandingDueAmount;
        @AuraEnabled
        public Decimal TotalPaidAmount;
    }
    
    
}