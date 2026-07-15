public class convertValueToWords {
    public Id bookingId;
    public string totalPendingInIndia{get;set;}
    public string totalPendingWords{get;set;}
    public string totalCostInString{get;set;}
    public string loanAmountInString{get;set;}
    public string loanAmountInWords{get;set;}
    public string tillDateReceived{get;set;}
    public string TotalCostAmountInWords{get;set;}
    public string BookingAmount{get;set;}
    public string projectSpecification {get;set;}
    public String totlreceivedinIndian {get;set;}
    public String totlbasicPriceinIndian {get;set;}
    public String totltaxinIndian {get;set;}
    
    public List<paySchWrapper> payList {get;set;}
    public List<recWrapper> recpList {get;set;}
    public class paySchWrapper{
        public string Name{get;set;}
        public Decimal Payment_percent{get;set;}
        public boolean isConstruction{get;set;}
        public boolean isSale{get;set;}
        public string amount{get;set;}
        public Decimal S_No{get;set;}
    }
    
    public class recWrapper{
        public string checkNo{get;set;}
        public Date repDate{get;set;}
        public String amountInWords{get;set;}
        public string BankName{get;set;}
        public string branchName{get;set;}
    }
    
    public convertValueToWords(ApexPages.StandardController stdController) {
        bookingId = (Id)stdController.getId();
        Booking__c bk = [select id,name,Basic_Price__c,Total_received_Amount__c,Pending_Amount__c,Sanctioned_Amount__c,Total_Consideration_with_taxes_and_other__c from Booking__c where id =: bookingId];
        
        List<Receipt__c> repList = [Select Id,Check_Transaction_Nmber__c,Receipt_date__c,Total_Received_Amount__c,Bank_Name__c from Receipt__c where Booking__c=:bk.Id order by  Receipt_date__c asc];
        List<paySchWrapper> samp = new List<paySchWrapper>();
        List<Payment_Schedule__c> payListStan = [select id,name,S_No__c,Payment_Percent__c,AmountB__c,Amount__c from Payment_Schedule__c where Booking__c =:bk.id ];
        for(Payment_Schedule__c ps : payListStan){
            paySchWrapper pw = new paySchWrapper();
            pw.Name = ps.Name;
            pw.Payment_percent = ps.Payment_Percent__c;
            pw.amount = ps.AmountB__c.setScale(2).format();
            pw.S_No = ps.S_No__c;
            samp.add(pw);
        }
        
		payList =  samp;  
        
        List<recWrapper> repLitsItems = new List<recWrapper>();
        for(Receipt__c ps : repList){
            recWrapper pw = new recWrapper();
            pw.checkNo = ps.Check_Transaction_Nmber__c;
            pw.repDate = ps.Receipt_date__c;
            pw.amountInWords = ps.Total_Received_Amount__c.setScale(2).format();
            pw.BankName = ps.Bank_Name__c;
            repLitsItems.add(pw);
        }
        
        recpList = repLitsItems;
        
        totalCostInString = bk.Total_Consideration_with_taxes_and_other__c.setScale(2).format();
        totlreceivedinIndian = bk.Total_received_Amount__c.setScale(2).format();
        totalPendingInIndia = bk.Pending_Amount__c.setScale(2).format();
        NumberTOWordConvertion nwcObj = new NumberTOWordConvertion();
        if(bk.Sanctioned_Amount__c != null){
            loanAmountInString = bk.Sanctioned_Amount__c.setScale(2).format();
            loanAmountInWords = nwcObj.getNumberTOWordConvertion(bk.Sanctioned_Amount__c);
        }
        if(bk.Basic_Price__c != null){
            totlbasicPriceinIndian = bk.Basic_Price__c.setScale(2).format();
        }
        TotalCostAmountInWords = nwcObj.getNumberTOWordConvertion(bk.Total_Consideration_with_taxes_and_other__c);
        //BookingAmount = nwcObj.getNumberTOWordConvertion(bk.Booking_Amount__c);
        totalPendingWords = nwcObj.getNumberTOWordConvertion(bk.Pending_Amount__c);
        tillDateReceived = nwcObj.getNumberTOWordConvertion(bk.Total_received_Amount__c);
    }

}