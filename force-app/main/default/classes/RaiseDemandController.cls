public class RaiseDemandController {
    public Decimal totAmtDueTillPrevMilestone { get; set; }
    public Decimal paidTillPrevMilestone { get; set; }
    public Decimal balanceDueTillPrevMilestone { get; set; }
    public Decimal interestDelayTillPrevious { get; set; }
    public Decimal interestPaidTillPrevious { get; set; }
    public Decimal presentDue { get; set; }
    public Decimal balanceInterest { get; set; }
    public Decimal totalAmountPayable { get; set; }
    public String totalAmountPayableInWords { get; set; }
    public String currentCompletedStage { get; set; }
    public Date currentCompletedStageDate { get; set; }
    public String currentMilestoneNumber { get; set; }
    public Date demandDueDate { get; set; }
    public Decimal currentMilestonePaymentPercent { get; set; }
    public Decimal milestonePaymentPercentTill { get; set; }
    public Decimal TDSonePercentage { get; set; }
    
    // New properties for payment breakup table
    public List<PaymentBreakup> paymentBreakups { get; set; }
    
    public class PaymentBreakup {
        public String scheduleNo { get; set; }
        public String scheduleName { get; set; }
        public Decimal totalAmount { get; set; }
        public Decimal paidAmount { get; set; }
        public Decimal pendingAmount { get; set; }
        public Boolean isCurrent { get; set; }
    }
    
    public static Map<Integer, String> daySuffixMap = new Map<Integer, String>{1 => 'st', 2 => 'nd', 3 => 'rd', 21 => 'st', 22 => 'nd', 23 => 'rd', 31 => 'st'};
        
    public RaiseDemandController(ApexPages.StandardController controller) {
        
        // Initialize payment breakups list
            paymentBreakups = new List<PaymentBreakup>();
            
            totAmtDueTillPrevMilestone =0;
            paidTillPrevMilestone =0;
            balanceDueTillPrevMilestone =0;
            interestDelayTillPrevious =0;
            presentDue =0;
            totalAmountPayable =0;
            TDSonePercentage=0;
            interestPaidTillPrevious =0;
            
            Id bookingRecordId = ApexPages.currentPage().getParameters().get('Id');
            
            if (bookingRecordId == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Booking record Id is null.'));
                return;
            }
            
            Booking__c book = [SELECT Id,Interest_Waive_Off__c,Total_Interest_Waive_Off__c,GST__c,Debit_Amount__c, Name, Project__c,Project1__r.Name, Property_Type_For__c, Block__c, Tower__c FROM Booking__c WHERE Id = :bookingRecordId];
            
            system.debug('>>>>>>>>>>>>>>>>>'+book.Property_Type_For__c);
            if (book.Property_Type_For__c == 'Apartments') {
                apartmentScheduleCalculations(book);
            }else if (book.Property_Type_For__c == 'Villas')  {
                //villaScheduleCalculations(book);
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No "Property Type" selected for this booking.'));
                return;
            }
        
            
        }
    
    private void apartmentScheduleCalculations(Booking__c book) {
        Booking__c bookRec = [Select id,name,Cost_Sheet__c,Cost_Sheet__r.Payment_Type__c from Booking__c where Id =:book.Id];
        String PaymentType =  bookRec.Cost_Sheet__r.Payment_Type__c;
        
        if(PaymentType == 'Standard'){
            list<Master_Payment_Schedule__c> msRecordList = [
                SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c
                FROM Master_Payment_Schedule__c
                WHERE Status__c = 'Completed' AND Tower__c = :book.Tower__c
                ORDER BY S_No__c DESC LIMIT 1
            ];
            if (msRecordList.isEmpty()) {
                // Handle case where no milestones are completed
                currentCompletedStage = 'No milestone completed';
                currentCompletedStageDate = null;
                demandDueDate = null;
                currentMilestonePaymentPercent = 0;
                currentMilestoneNumber = null;
                totalAmountPayableInWords = 'Zero';
                
                // Optionally, you could log or show a message
                System.debug('No milestone completed for the booking.');
                return;
            }
            
            Master_Payment_Schedule__c msRecord = msRecordList[0]; 
            
            if (msRecord != null) {
                currentCompletedStage = msRecord.Name;
                currentCompletedStageDate = msRecord.Completed_Date__c;
                demandDueDate = System.today().addDays(7);
                currentMilestonePaymentPercent = msRecord.Payment_percent__c != null ? msRecord.Payment_percent__c.setScale(0) : 0;
                
                // Get payment breakups for the table
                getPaymentBreakups(book, msRecord.S_No__c, PaymentType);
                
                Decimal stNumber = msRecord.S_No__c;
                if (stNumber != null) {
                    currentMilestoneNumber = getMilestoneLabel(stNumber.intValue());
                }
                
                AggregateResult[] aggregateResults = [
                    SELECT SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Amount__c) totalInterestAmount,
                    SUM(AmountB__c) totalPayableAmount,
                    SUM(Interest_Up_to_Date__c) totalInterestUplodate, SUM(Interest_Paid__c) totalInterestPaid,
                    SUM(Payment_percent__c) paymentPercentageTill
                    FROM Payment_Schedule__c
                    WHERE Master_Payment_Schedule__r.Status__c = 'Completed' 
                    AND Master_Payment_Schedule__r.S_No__c != :msRecord.S_No__c 
                    AND Booking__c = :book.Id
                ];
                
                system.debug('aggregateResults'+aggregateResults);
                Decimal totalPendingAmount = 0;
                Decimal totalInterestAmount = 0;
                Decimal totalPayableAmount = 0;
                Decimal totalReceivedAmount = 0;
                Decimal paidPreMilestone = 0;
                Decimal totalInterestUplodateAmount = 0;
                Decimal totalInterestPaid = 0;
                Decimal waveOff = 0;
                Decimal milestonePaymentPercent = 0;
                Decimal balanceDueTillPrevMilestoneMod = 0;
                Decimal milestonePaymentPercentResult =0;
                if (!aggregateResults.isEmpty()) {
                    totalPendingAmount = (Decimal) aggregateResults[0].get('totalPendingAmount') != null ? (Decimal) aggregateResults[0].get('totalPendingAmount') : 0;
                    totalInterestAmount = (Decimal) aggregateResults[0].get('totalInterestAmount') != null ? (Decimal) aggregateResults[0].get('totalInterestAmount') : 0;
                    totalPayableAmount = (Decimal) aggregateResults[0].get('totalPayableAmount') != null ? (Decimal) aggregateResults[0].get('totalPayableAmount') : 0;
                    totalInterestUplodateAmount = (Decimal) aggregateResults[0].get('totalInterestUplodate') != null ? (Decimal) aggregateResults[0].get('totalInterestUplodate') : 0;
                    totalInterestPaid = (Decimal) aggregateResults[0].get('totalInterestPaid') != null ? (Decimal) aggregateResults[0].get('totalInterestPaid') : 0;
                    milestonePaymentPercent = aggregateResults[0].get('paymentPercentageTill') != null ? (Decimal) aggregateResults[0].get('paymentPercentageTill') : 0;
                }
                system.debug('paidPreMilestone'+paidPreMilestone);
                totAmtDueTillPrevMilestone = totalPayableAmount;
                interestPaidTillPrevious = totalInterestPaid;
                interestDelayTillPrevious = (totalInterestUplodateAmount > 0) ? (totalInterestUplodateAmount) : totalInterestAmount;
                
                double paidTotalAmount = 0;
                AggregateResult presentDueResult = [
                    SELECT SUM(AmountB__c) TotalAmount,SUM(Payment_percent__c) paymentPercentageTill
                    FROM Payment_Schedule__c
                    WHERE Master_Payment_Schedule__r.S_No__c = :msRecord.S_No__c
                    AND Booking__c = :book.Id
                ];
                Decimal presentDueAmount = 0;
                if (presentDueResult != null && presentDueResult.get('TotalAmount') != null) {
                    presentDueAmount = (Decimal) presentDueResult.get('TotalAmount');
                }
                if (presentDueResult != null && presentDueResult.get('paymentPercentageTill') != null) {
                    milestonePaymentPercentResult = milestonePaymentPercent + currentMilestonePaymentPercent;
                }
                
                if (book.Total_Interest_Waive_Off__c != null) {
                    waveOff = book.Total_Interest_Waive_Off__c;
                }
                
                AggregateResult totalReceied = [
                    SELECT SUM(Received_Amount1__c) totalReceivedAmount
                    FROM Payment_Schedule__c
                    WHERE Booking__c = :book.Id
                ];
                
                if (totalReceied != null && totalReceied.get('totalReceivedAmount') != null) {
                    paidTotalAmount = (Decimal) totalReceied.get('totalReceivedAmount');
                }
                if (book.Debit_Amount__c != null){
                    paidTotalAmount-= book.Debit_Amount__c;
                }
                paidTillPrevMilestone =  paidTotalAmount;          
                balanceDueTillPrevMilestoneMod = totalPayableAmount - paidTotalAmount;
                if(balanceDueTillPrevMilestoneMod > 0){
                    balanceDueTillPrevMilestone = totalPayableAmount - paidTotalAmount;
                }
                //milestonePaymentPercentTill = milestonePaymentPercentResult.setScale(0);
                presentDue = presentDueAmount;
                
                Decimal gstPercentage = (book.GST__c != null) ? book.GST__c / 100 : 0;
                Decimal amountExcludingGST = presentDue / (1 + gstPercentage);
                TDSonePercentage = (amountExcludingGST * 0.01).setScale(0);
                
                balanceInterest = interestDelayTillPrevious - interestPaidTillPrevious - waveOff;
                
                double totalAmount = 0;
                totalAmount = (balanceDueTillPrevMilestoneMod + balanceInterest + presentDue).setScale(0);
                
                if(totalAmount > -1){
                    totalAmountPayable = totalAmount;
                }
                
                NumberTOWordConvertion convert = new NumberTOWordConvertion();
                if (totalAmountPayable != null && totalAmountPayable > -1) {
                    totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
                }
            }
        }
        else if(PaymentType == 'Custom'){
            
            list<Payment_schedule__c> paysRecordList = [SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c FROM Payment_schedule__c 
                                                        WHERE Status__c = 'Completed' AND Booking__c =: book.Id ORDER BY S_No__c DESC LIMIT 1];
            Payment_schedule__c msRecord = new Payment_schedule__c();
            if(!paysRecordList.isEmpty()){
                msRecord = paysRecordList[0];
            }
            if (msRecord != null) {
                system.debug('in if 192 msRecord');
                currentCompletedStage = msRecord.Name;
                currentCompletedStageDate = msRecord.Completed_Date__c;
                demandDueDate = System.today().addDays(7);
                currentMilestonePaymentPercent = msRecord.Payment_percent__c != null ? msRecord.Payment_percent__c.setScale(0) : 0;
                
                // Get payment breakups for the table
                getPaymentBreakups(book, msRecord.S_No__c, PaymentType);
                
                Decimal stNumber = msRecord.S_No__c;
                if (stNumber != null) {
                    currentMilestoneNumber = getMilestoneLabel(stNumber.intValue());
                }
                
                AggregateResult[] aggregateResults = [
                    SELECT SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Amount__c) totalInterestAmount,
                    SUM(AmountB__c) totalPayableAmount,
                    SUM(Interest_Up_to_Date__c) totalInterestUplodate, SUM(Interest_Paid__c) totalInterestPaid,
                    SUM(Payment_percent__c) paymentPercentageTill
                    FROM Payment_Schedule__c
                    WHERE Status__c = 'Completed' 
                    AND S_No__c != :msRecord.S_No__c 
                    AND Booking__c = :book.Id
                ];
                
                system.debug('aggregateResults'+aggregateResults);
                Decimal totalPendingAmount = 0;
                Decimal totalInterestAmount = 0;
                Decimal totalPayableAmount = 0;
                Decimal totalReceivedAmount = 0;
                Decimal paidPreMilestone = 0;
                Decimal totalInterestUplodateAmount = 0;
                Decimal totalInterestPaid = 0;
                Decimal waveOff = 0;
                Decimal milestonePaymentPercent = 0;
                Decimal balanceDueTillPrevMilestoneMod = 0;
                Decimal milestonePaymentPercentResult =0;
                if (!aggregateResults.isEmpty()) {
                    totalPendingAmount = (Decimal) aggregateResults[0].get('totalPendingAmount') != null ? (Decimal) aggregateResults[0].get('totalPendingAmount') : 0;
                    totalInterestAmount = (Decimal) aggregateResults[0].get('totalInterestAmount') != null ? (Decimal) aggregateResults[0].get('totalInterestAmount') : 0;
                    totalPayableAmount = (Decimal) aggregateResults[0].get('totalPayableAmount') != null ? (Decimal) aggregateResults[0].get('totalPayableAmount') : 0;
                    totalInterestUplodateAmount = (Decimal) aggregateResults[0].get('totalInterestUplodate') != null ? (Decimal) aggregateResults[0].get('totalInterestUplodate') : 0;
                    totalInterestPaid = (Decimal) aggregateResults[0].get('totalInterestPaid') != null ? (Decimal) aggregateResults[0].get('totalInterestPaid') : 0;
                    milestonePaymentPercent = aggregateResults[0].get('paymentPercentageTill') != null ? (Decimal) aggregateResults[0].get('paymentPercentageTill') : 0;
                }
                
                system.debug('paidPreMilestone'+paidPreMilestone);
                totAmtDueTillPrevMilestone = totalPayableAmount;
                interestPaidTillPrevious = totalInterestPaid;
                interestDelayTillPrevious = (totalInterestUplodateAmount > 0) ? (totalInterestUplodateAmount) : totalInterestAmount;
                
                double paidTotalAmount = 0;
                AggregateResult presentDueResult = [
                    SELECT SUM(AmountB__c) TotalAmount,SUM(Payment_percent__c) paymentPercentageTill
                    FROM Payment_Schedule__c
                    WHERE S_No__c = :msRecord.S_No__c
                    AND Booking__c = :book.Id
                ];
                Decimal presentDueAmount = 0;
                if (presentDueResult != null && presentDueResult.get('TotalAmount') != null) {
                    presentDueAmount = (Decimal) presentDueResult.get('TotalAmount');
                }
                if (presentDueResult != null && presentDueResult.get('paymentPercentageTill') != null) {
                    milestonePaymentPercentResult = milestonePaymentPercent + currentMilestonePaymentPercent;
                }
                
                if (book.Total_Interest_Waive_Off__c != null) {
                    waveOff = book.Total_Interest_Waive_Off__c;
                }
                
                AggregateResult totalReceied = [
                    SELECT SUM(Received_Amount1__c) totalReceivedAmount
                    FROM Payment_Schedule__c
                    WHERE Booking__c = :book.Id
                ];
                
                if (totalReceied != null && totalReceied.get('totalReceivedAmount') != null) {
                    paidTotalAmount = (Decimal) totalReceied.get('totalReceivedAmount');
                }
                if (book.Debit_Amount__c != null){
                    paidTotalAmount-= book.Debit_Amount__c;
                }
                paidTillPrevMilestone =  paidTotalAmount;          
                balanceDueTillPrevMilestoneMod = totalPayableAmount - paidTotalAmount;
                if(balanceDueTillPrevMilestoneMod > 0){
                    balanceDueTillPrevMilestone = totalPayableAmount - paidTotalAmount;
                }
                //milestonePaymentPercentTill = milestonePaymentPercentResult.setScale(0);
                presentDue = presentDueAmount;
                
                Decimal gstPercentage = (book.GST__c != null) ? book.GST__c / 100 : 0;
                Decimal amountExcludingGST = presentDue / (1 + gstPercentage);
                TDSonePercentage = (amountExcludingGST * 0.01).setScale(0);
                
                balanceInterest = interestDelayTillPrevious - interestPaidTillPrevious - waveOff;
                
                double totalAmount = 0;
                totalAmount = (balanceDueTillPrevMilestoneMod + balanceInterest + presentDue).setScale(0);
                
                if(totalAmount > -1){
                    totalAmountPayable = totalAmount;
                }
                
                NumberTOWordConvertion convert = new NumberTOWordConvertion();
                if (totalAmountPayable != null && totalAmountPayable > -1) {
                    totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
                }
            }
        }
        
    }
    
     private void getPaymentBreakups(Booking__c book, Decimal currentMilestoneSNo, String paymentType) {
        paymentBreakups = new List<PaymentBreakup>();
        
        List<Payment_Schedule__c> schedules = new List<Payment_Schedule__c>();
        
        if(paymentType == 'Standard') {
            schedules = [
                SELECT Id, Name, S_No__c, AmountB__c, Received_Amount1__c, Pending_Amount__c, 
                       Master_Payment_Schedule__r.Name,Master_Payment_Schedule__r.S_No__c,Master_Payment_Schedule__r.Status__c
                FROM Payment_Schedule__c
                WHERE Booking__c = :book.Id
                AND (Master_Payment_Schedule__r.Status__c = 'Completed' OR Master_Payment_Schedule__r.S_No__c = :currentMilestoneSNo)
                ORDER BY Master_Payment_Schedule__r.S_No__c
            ];
        } else if(paymentType == 'Custom') {
            schedules = [
                SELECT Id, Name, S_No__c, AmountB__c, Received_Amount1__c, Pending_Amount__c, Status__c
                FROM Payment_Schedule__c
                WHERE Booking__c = :book.Id
                AND (Status__c = 'Completed' OR S_No__c = :currentMilestoneSNo)
                ORDER BY S_No__c
            ];
        }
        
        for(Payment_Schedule__c schedule : schedules) {
            PaymentBreakup breakup = new PaymentBreakup();
            
            if(paymentType == 'Standard') {
                breakup.scheduleNo = String.valueOf(schedule.Master_Payment_Schedule__r.S_No__c);
                breakup.scheduleName = schedule.Master_Payment_Schedule__r.Name;
            } else {
                breakup.scheduleNo = String.valueOf(schedule.S_No__c);
                breakup.scheduleName = schedule.Name;
            }
            
            breakup.totalAmount = schedule.AmountB__c != null ? schedule.AmountB__c : 0;
            breakup.paidAmount = schedule.Received_Amount1__c != null ? schedule.Received_Amount1__c : 0;
            breakup.pendingAmount = schedule.Pending_Amount__c != null ? schedule.Pending_Amount__c : 0;
            breakup.isCurrent = (paymentType == 'Standard' ? 
                                schedule.Master_Payment_Schedule__r.S_No__c == currentMilestoneSNo : 
                                schedule.S_No__c == currentMilestoneSNo);
            
            paymentBreakups.add(breakup);
        }
    }
    
    /*private void villaScheduleCalculations(Booking__c book) {
List<Payment_Schedule__c> psRecordList = [
SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c
FROM Payment_Schedule__c
WHERE Status__c = 'Completed' AND Booking__c = :book.Id
ORDER BY S_No__c DESC LIMIT 1
];
if (psRecordList.isEmpty()) {
// Handle case where no milestones are completed
currentCompletedStage = 'No milestone completed';
currentCompletedStageDate = null;
demandDueDate = null;
currentMilestonePaymentPercent = 0;
currentMilestoneNumber = null;
totalAmountPayableInWords = 'Zero';

// Optionally, you could log or show a message
System.debug('No milestone completed for the booking.');
return;
}

Payment_Schedule__c psRecord = psRecordList[0]; 

if (psRecord != null) {
currentCompletedStage = psRecord.Name;
currentCompletedStageDate = psRecord.Completed_Date__c;
demandDueDate = System.today().addDays(7);
currentMilestonePaymentPercent = psRecord.Payment_percent__c != null ? psRecord.Payment_percent__c.setScale(0) : 0;

Decimal stNumber = psRecord.S_No__c;
if (stNumber != null) {
currentMilestoneNumber = getMilestoneLabel(stNumber.intValue());
}

AggregateResult[] aggregateResults = [
SELECT SUM(Pending_Amount__c) totalPendingAmount, 
SUM(Interest_Amount__c) totalInterestAmount,
SUM(AmountB__c) totalPayableAmount,
SUM(Interest_Up_to_Date__c) totalInterestUplodate, 
SUM(Interest_Paid__c) totalInterestPaid,
SUM(Payment_percent__c) paymentPercentageTill
FROM Payment_Schedule__c
WHERE Status__c = 'Completed' 
AND S_No__c != :psRecord.S_No__c 
AND Booking__c = :book.Id
];

Decimal totalPendingAmount = 0;
Decimal totalInterestAmount = 0;
Decimal totalPayableAmount = 0;
Decimal paidPreMilestone = 0;
Decimal totalInterestUplodateAmount = 0;
Decimal totalInterestPaid = 0;
Decimal waveOff = 0;
Decimal milestonePaymentPercent =0;
Decimal balanceDueTillPrevMilestoneMod = 0;
if (!aggregateResults.isEmpty()) {
totalPendingAmount = (Decimal) aggregateResults[0].get('totalPendingAmount') != null ? (Decimal) aggregateResults[0].get('totalPendingAmount') : 0;
totalInterestAmount = (Decimal) aggregateResults[0].get('totalInterestAmount') != null ? (Decimal) aggregateResults[0].get('totalInterestAmount') : 0;
totalPayableAmount = (Decimal) aggregateResults[0].get('totalPayableAmount') != null ? (Decimal) aggregateResults[0].get('totalPayableAmount') : 0;
totalInterestUplodateAmount = (Decimal) aggregateResults[0].get('totalInterestUplodate') != null ? (Decimal) aggregateResults[0].get('totalInterestUplodate') : 0;
totalInterestPaid = (Decimal) aggregateResults[0].get('totalInterestPaid') != null ? (Decimal) aggregateResults[0].get('totalInterestPaid') : 0;
milestonePaymentPercent = (Decimal) aggregateResults[0].get('paymentPercentageTill') != null ? (Decimal) aggregateResults[0].get('paymentPercentageTill') : 0;
}

totAmtDueTillPrevMilestone = totalPayableAmount;
interestPaidTillPrevious = totalInterestPaid;
interestDelayTillPrevious = (totalInterestUplodateAmount > 0) ? (totalInterestUplodateAmount) : totalInterestAmount;

double paidTotalAmount = 0;
AggregateResult presentDueResult = [
SELECT SUM(AmountB__c) totalAmountB,
SUM(Payment_percent__c) paymentPercentageTill
FROM Payment_Schedule__c
WHERE S_No__c = :psRecord.S_No__c
AND Booking__c = :book.Id
];

Decimal presentDueAmount = 0;
if (presentDueResult != null && presentDueResult.get('totalAmountB') != null) {
presentDueAmount = (Decimal) presentDueResult.get('totalAmountB');
}
presentDue = presentDueAmount;

Decimal gstPercentage = (book.GST__c != null) ? book.GST__c / 100 : 0;
Decimal amountExcludingGST = presentDue / (1 + gstPercentage);
Decimal TDSonePercentage = amountExcludingGST * 0.01; 

balanceInterest = interestDelayTillPrevious - interestPaidTillPrevious;
if (presentDueResult != null && presentDueResult.get('paymentPercentageTill') != null) {
milestonePaymentPercent = milestonePaymentPercent + (Decimal) presentDueResult.get('paymentPercentageTill');
}
if (book.Total_Interest_Waive_Off__c != null) {
waveOff = book.Total_Interest_Waive_Off__c;
}
AggregateResult totalReceied = [
SELECT SUM(Received_Amount1__c) totalReceivedAmount
FROM Payment_Schedule__c
WHERE Booking__c = :book.Id
];

if (totalReceied != null && totalReceied.get('totalReceivedAmount') != null) {
paidTotalAmount = (Decimal) totalReceied.get('totalReceivedAmount');
}
if (book.Debit_Amount__c != null){
paidTotalAmount-= book.Debit_Amount__c;
}

paidTillPrevMilestone =  paidTotalAmount;          
balanceDueTillPrevMilestoneMod = totalPayableAmount - paidTotalAmount;
if(balanceDueTillPrevMilestoneMod > 0){
balanceDueTillPrevMilestone = totalPayableAmount - paidTotalAmount;
}
milestonePaymentPercentTill = milestonePaymentPercent.setScale(0);

double totalAmount = (balanceDueTillPrevMilestoneMod + (interestDelayTillPrevious - waveOff -  interestPaidTillPrevious) + presentDue).setScale(0);

if(totalAmount > -1){
totalAmountPayable = totalAmount;
}

NumberTOWordConvertion convert = new NumberTOWordConvertion();

if (totalAmountPayable != null && totalAmountPayable > -1) {
totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
}
}
}*/
    public static String getMilestoneLabel(Integer sNo) {
        if (sNo == null) {
            return 'Invalid milestone';
        }
        // Determine the suffix, default to 'th'
        String suffix = daySuffixMap.containsKey(sNo) ? daySuffixMap.get(sNo) : 'th';
        
        return sNo + suffix;
    }
}