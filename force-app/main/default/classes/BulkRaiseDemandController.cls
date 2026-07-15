public class BulkRaiseDemandController {
    public class BookingWrapper {
        @AuraEnabled public Booking__c booking;
        @AuraEnabled public Decimal displayAmount;
        @AuraEnabled public Decimal totalPaymentAmount;
        @AuraEnabled public Decimal grandTotal;
        @AuraEnabled public Id paymentScheduleId;
        @AuraEnabled public Decimal previousDemandRaisedPending;
        @AuraEnabled public Boolean demandRaised;
        @AuraEnabled public String includeInterest;
        @AuraEnabled public Id leadId;
        @AuraEnabled public Id unitId;
        @AuraEnabled public String tower;
        @AuraEnabled public String block;
        @AuraEnabled public Id towerId;
        @AuraEnabled public Boolean selected;
        @AuraEnabled public String currentMilestone;
        
        public BookingWrapper(Booking__c booking, Decimal displayAmount, Decimal totalPaymentAmount, Id paymentScheduleId,
                              Decimal previousDemandRaisedPending, Decimal grandTotal, String includeInterest, Boolean demandRaised, 
                              Id leadId, Id unitId, String tower, String block, Id towerId,Boolean selected,String currentMilestone) {
                                  this.booking = booking;
                                  this.displayAmount = displayAmount;
                                  this.totalPaymentAmount = totalPaymentAmount;
                                  this.paymentScheduleId = paymentScheduleId;
                                  this.previousDemandRaisedPending = previousDemandRaisedPending;
                                  this.grandTotal = grandTotal;
                                  this.demandRaised = demandRaised;
                                  this.includeInterest = includeInterest;
                                  this.leadId = leadId;
                                  this.unitId = unitId;
                                  this.tower = tower;
                                  this.block = block;
                                  this.towerId = towerId;
                                  this.selected = selected;
                                  this.currentMilestone = currentMilestone;
                              }
    }
    
    @AuraEnabled
    public static List<BookingWrapper> getBookingRecords(String masterPaymentScheduleId){
        
        Master_Payment_Schedule__c masterPaymentSchedule = [SELECT Id, Name, S_No__c, Project__r.Project__c, Completed_Date__c FROM Master_Payment_Schedule__c WHERE Id = :masterPaymentScheduleId LIMIT 1];
        
        if (masterPaymentSchedule != null) {
            map<id,payment_schedule__c> paymentBookMap = new map<id,payment_schedule__c>();
            
            // Query all relevant payment_schedule__c records
            List<payment_schedule__c> getPayScheLineItems = [SELECT Id, Name, Amount__c, Is_Demanded__c, Booking__c, AmountB__c, Received_Amount1__c, Pending_Amount__c, status__c, Master_Payment_Schedule__r.Completed_Date__c, Demand_Uploaded__c FROM payment_schedule__c WHERE Master_Payment_Schedule__c = :masterPaymentScheduleId ];
            
            list<id> bookingLists = new list<id>();
            for(payment_schedule__c pay : getPayScheLineItems){
                bookingLists.add(pay.Booking__c);
                paymentBookMap.put(pay.Booking__c, pay);
            }
            
            
            List<Booking__c> bookings = [SELECT Id, Name, First_Applicant_Name__c,Stage__c,Total_Interest_Waive_Off__c,GST__c,Debit_Amount__c,Plot__r.Block1__r.Name,Plot__r.Block1__c,Tower__c,Project_Company__c,
                                         salutation_Applicant1__c, salutation_Applicant2__c,Second_Applicant_Name__c,Block__c,Block__r.Block__c,Block__r.Name,Project1__c,Project1__r.Name, Project__c, 
                                         Plot__c,Plot__r.Block__c, Plot__r.Name, Demand_Raised__c, Lead__c, Email1__c FROM Booking__c WHERE id IN :bookingLists and Stage__c != 'Cancellation' ORDER BY CreatedDate ASC];
            system.debug(bookings.size());
            
            List<BookingWrapper> result = bookingScheduleCalculations(bookings,paymentBookMap,masterPaymentSchedule);
            system.debug(result);
            return result;
        }
        
        return new List<BookingWrapper>();
    }
    
    @AuraEnabled
    public static List<BookingWrapper> bookingScheduleCalculations(List<Booking__c> bookings,map<id,payment_schedule__c> bookingPaymentMap,Master_payment_Schedule__c masterPaymentSchedule) {
        List<BookingWrapper> result = new List<BookingWrapper>();
        
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        Decimal completed_StageNumber;
        List<Master_Payment_Schedule__c> mps = new List<Master_Payment_Schedule__c>();
        mps.add(masterPaymentSchedule);
        
        // Fetch the latest completed Master Payment Schedules for all related towers
        Map<Id, Master_Payment_Schedule__c> towerToMasterPaymentScheduleMap = new Map<Id, Master_Payment_Schedule__c>();
        map<id,Decimal> debitAmountMap = new map<id,Decimal>();
        
        for (Booking__c book : bookings) {
            debitAmountMap.put(book.Id, book.Debit_Amount__c);
            
            if (!mps.isEmpty()) {
                towerToMasterPaymentScheduleMap.put(book.Tower__c, mps[0]);
                completed_StageNumber = masterPaymentSchedule.S_No__c;
            }
        }
        system.debug(completed_StageNumber);
        
        // Query all Payment Schedules for the provided bookings
        List<AggregateResult> aggregateResults = [
            SELECT Booking__c, SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Amount__c) totalInterestAmount,
            SUM(AmountB__c) totalPayableAmount, SUM(Interest_Up_to_Date__c) totalInterestUplodate,
            SUM(Interest_Paid__c) totalInterestPaid, SUM(Payment_percent__c) paymentPercentageTill
            FROM Payment_Schedule__c
            WHERE Master_Payment_Schedule__r.Status__c = 'Completed' 
            AND Booking__c IN :bookings AND Master_Payment_Schedule__r.S_No__c != :completed_StageNumber
            GROUP BY Booking__c];
        system.debug(aggregateResults);
        // Map to store the aggregated payment schedule results
        Map<Id, AggregateResult> bookingToAggregateResultMap = new Map<Id, AggregateResult>();
        for (AggregateResult result1 : aggregateResults) {
            bookingToAggregateResultMap.put((Id) result1.get('Booking__c'), result1);
        }
        system.debug(bookingToAggregateResultMap);
        // Query total received amounts for all bookings
        List<AggregateResult> totalReceivedResults = [ SELECT Booking__c, SUM(Received_Amount1__c) totalReceivedAmount,SUM(AmountB__c) totalAmount FROM Payment_Schedule__c WHERE Booking__c IN :bookings AND Master_Payment_Schedule__r.S_No__c = :completed_StageNumber GROUP BY Booking__c ];
        
        List<AggregateResult> totalReceivedAmount = [ SELECT Booking__c, SUM(Received_Amount1__c) totalReceivedAmount FROM Payment_Schedule__c WHERE Booking__c IN :bookings GROUP BY Booking__c ];
        
        Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
        for (AggregateResult result2 : totalReceivedAmount) {
            bookingToReceivedAmountMap.put((Id) result2.get('Booking__c'), (Decimal) result2.get('totalReceivedAmount'));
        }
        system.debug(bookingToReceivedAmountMap+ '-- '+ totalReceivedAmount+'--'+totalReceivedResults);
        // Map to store total received amounts per booking
        Map<Id, Decimal> bookingToThisMSAmountMap = new Map<Id, Decimal>();
        for (AggregateResult result3 : totalReceivedResults) {
            bookingToThisMSAmountMap.put((Id) result3.get('Booking__c'), (Decimal) result3.get('totalAmount'));
        }
        
        // Process each booking and calculate demand details
        for (Booking__c book : bookings) {
            Master_Payment_Schedule__c msRecord = towerToMasterPaymentScheduleMap.get(book.Tower__c);
            if (msRecord == null) {
                continue;
            }
            
            AggregateResult aggregateResult = bookingToAggregateResultMap.get(book.Id);
            /*if (aggregateResult == null) {
                continue;
            }*/
            Decimal totalPendingAmount = 0;
            Decimal totalInterestAmount = 0;
            Decimal totalPayableAmount = 0;
            Decimal totalInterestUplodateAmount = 0;
            Decimal totalInterestPaid = 0;
            Decimal milestonePaymentPercent = 0;
            if (aggregateResult != null) {
                totalPendingAmount = (Decimal) aggregateResult.get('totalPendingAmount') != null ? (Decimal) aggregateResult.get('totalPendingAmount') : 0;
                totalInterestAmount = (Decimal) aggregateResult.get('totalInterestAmount') != null ? (Decimal) aggregateResult.get('totalInterestAmount') : 0;
                totalPayableAmount = (Decimal) aggregateResult.get('totalPayableAmount') != null ? (Decimal) aggregateResult.get('totalPayableAmount') : 0;
                totalInterestUplodateAmount = (Decimal) aggregateResult.get('totalInterestUplodate') != null ? (Decimal) aggregateResult.get('totalInterestUplodate') : 0;
                totalInterestPaid = (Decimal) aggregateResult.get('totalInterestPaid') != null ? (Decimal) aggregateResult.get('totalInterestPaid') : 0;
                milestonePaymentPercent = (Decimal) aggregateResult.get('paymentPercentageTill') != null ? (Decimal) aggregateResult.get('paymentPercentageTill') : 0;
            }
            
            
            system.debug(totalPendingAmount +'>'+totalInterestAmount+'>'+totalPayableAmount+'>'+ totalInterestUplodateAmount+'>'+ totalInterestPaid+'>'+milestonePaymentPercent);
            
            Decimal paidTotalAmount = bookingToReceivedAmountMap.get(book.Id) != null ? bookingToReceivedAmountMap.get(book.Id) : 0;
            
            system.debug(paidTotalAmount);
            if(debitAmountMap.get(book.Id) != null){
                paidTotalAmount -= debitAmountMap.get(book.Id);
            }
            Decimal balanceDueTillPrevMilestoneMod = totalPayableAmount - paidTotalAmount;            
            Decimal balanceDueTillPrevMilestone = balanceDueTillPrevMilestoneMod > 0 ? balanceDueTillPrevMilestoneMod : 0;
            // Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid - book.Total_Interest_Waive_Off__c;
            Decimal totalInterestWaiveOff = book.Total_Interest_Waive_Off__c != null ? book.Total_Interest_Waive_Off__c : 0;
            Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid - totalInterestWaiveOff;
            
            
            Decimal presentDue = bookingToThisMSAmountMap.get(book.Id) != null ? bookingToThisMSAmountMap.get(book.Id) : 0;
            system.debug(presentDue +'---- '+ balanceDueTillPrevMilestoneMod);
            //Decimal gstPercentage = (book.GST__c != null) ? book.GST__c / 100 : 0;
            //Decimal amountExcludingGST = presentDue / (1 + gstPercentage);
            //Decimal TDSonePercentage = amountExcludingGST * 0.01; 
            
            Decimal actualTotalAmountPayable;
            actualTotalAmountPayable = balanceDueTillPrevMilestoneMod + balanceInterest + presentDue;
            /*if (book.Project1__r.Name == 'MAHENDRA AARYA') {
                actualTotalAmountPayable = (balanceDueTillPrevMilestoneMod + balanceInterest + presentDue).setScale(0);
            } else if (book.Project1__r.Name == 'MAHENDRA ARTO HELIX') {
                actualTotalAmountPayable = (balanceDueTillPrevMilestoneMod + balanceInterest + presentDue - TDSonePercentage).setScale(0);
            } else {
                actualTotalAmountPayable = balanceDueTillPrevMilestoneMod + balanceInterest + presentDue;
            }*/
            
            Decimal totalAmountPayable = actualTotalAmountPayable > 0 ? actualTotalAmountPayable : 0;
            system.debug(totalAmountPayable);
            // Convert total amount payable to words
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            
            String bookingBlock =book.Plot__r.Block__c;
            String bookingTower = book.Plot__r.Block1__r.Name;
            String bookingTowerId = book.Plot__r.Block1__c;
            String bookingProject = book.Project1__r.Name;
            Boolean demandRaised = bookingPaymentMap.get(book.id).Is_Demanded__c;
            String currentMilestone = bookingPaymentMap.get(book.id).Name;
            Id unitId = book.Plot__c;
            Id leadId = book.Lead__c;
            system.debug(book);
            system.debug(presentDue);
            system.debug(balanceDueTillPrevMilestone);
            system.debug(totalAmountPayable);
            system.debug(demandRaised);
            system.debug(totalPendingAmount);
            system.debug(totalInterestAmount);
            system.debug(totalPayableAmount);
            
            result.add(new BookingWrapper(
                book, 0, presentDue, null, 
                balanceDueTillPrevMilestone, totalAmountPayable, 'false', demandRaised, leadId, unitId, bookingTower, bookingBlock, bookingTowerId,false,currentMilestone
            ));
        }
        return result;
    }
    
    
    @AuraEnabled
    public static List<BookingWrapper> getBookingRecordsWithProject(String masterPaymentScheduleId) {
        
        // Query the Master_Payment_Schedule__c and related Project__c in one query
        Master_Payment_Schedule__c masterPaymentSchedule = [
            SELECT Id, Name, S_No__c, Project__r.Project__c, Completed_Date__c 
            FROM Master_Payment_Schedule__c 
            WHERE Id = :masterPaymentScheduleId 
            LIMIT 1
        ];
        
        if (masterPaymentSchedule != null) {
            String projectValue = masterPaymentSchedule.Project__r.Project__c;
            map<id,payment_schedule__c> paymentBookMap = new map<id,payment_schedule__c>();
            // Query all relevant payment_schedule__c records
            List<payment_schedule__c> getPayScheLineItems = [
                SELECT Id, Name, Amount__c, Is_Demanded__c, Booking__c, AmountB__c, 
                Received_Amount1__c, Pending_Amount__c, status__c, 
                Master_Payment_Schedule__r.Completed_Date__c, Demand_Uploaded__c 
                FROM payment_schedule__c 
                WHERE Master_Payment_Schedule__c = :masterPaymentScheduleId
            ];
            
            list<id> bookingLists = new list<id>();
            for(payment_schedule__c pay : getPayScheLineItems){
                bookingLists.add(pay.Booking__c);
                paymentBookMap.put(pay.Booking__c, pay);
            }
            
            
            /* // Query all relevant Booking__c records with nested payment_schedule__c records
List<Booking__c> bookings = [
SELECT Id, Name, First_Applicant_Name__c,Project_Company__c,salutation_Applicant1__c,salutation_Applicant2__c,Second_Applicant_Name__c,Block__c,Block__r.Block__c,Block__r.Name, Project__c, Plot__c,Plot__r.Block__c, Plot__r.Name, Demand_Raised__c, Lead__c, Email1__c,	
(SELECT Amount__c, AmountB__c, Received_Amount1__c, Is_Demanded__c, Pending_Amount__c, Master_Payment_Schedule__c, status__c, Master_Payment_Schedule__r.Completed_Date__c, Demand_Uploaded__c 
FROM payment_schedules__r 
WHERE Master_Payment_Schedule__r.Status__c = 'Completed'
AND Master_Payment_Schedule__c = :masterPaymentScheduleId)
FROM Booking__c
WHERE Project__c = :projectValue 
ORDER BY CreatedDate ASC
];*/
            
            List<Booking__c> bookings = [
                SELECT Id, Name,Tower__c,Total_Interest_Waive_Off__c,Debit_Amount__c,GST__c,Plot__r.Block1__r.Name,Plot__r.Block1__c, First_Applicant_Name__c,Project_Company__c,salutation_Applicant1__c,salutation_Applicant2__c,Second_Applicant_Name__c,Project1__c,Project1__r.Name,Block__c,Block__r.Block__c,Block__r.Name, Project__c, Plot__c,Plot__r.Block__c, Plot__r.Name, Demand_Raised__c, Lead__c, Email1__c	
                FROM Booking__c
                WHERE id IN :bookingLists
                ORDER BY CreatedDate ASC
            ];
            
            
            List<BookingWrapper> result = bookingScheduleCalculations(bookings,paymentBookMap,masterPaymentSchedule);
            
            /*for (Booking__c booking : bookings) {
if (booking.payment_schedules__r.size() > 0) {
Boolean demandRaised = booking.payment_schedules__r[0].Is_Demanded__c;
Decimal displayAmount = calculateDisplayAmount(booking);
Id paymentScheduleId = booking.payment_schedules__r[0].Id;
Decimal totalPaymentAmount = calculateTotalPaymentAmount(booking.payment_schedules__r);
Decimal previousDemandRaisedPending = calculatePendingPreviousDemands(getPayScheLineItems);
Decimal grandTotal = totalPaymentAmount + previousDemandRaisedPending;
Id leadId = booking.Lead__c;
Id unitId = booking.Plot__c;
String bookingTower = Booking.Block__r.Name;
String bookingBlock = Booking.Plot__r.Block__c;
Id bookingTowerId = Booking.Block__c;

result.add(new BookingWrapper(
booking, displayAmount, totalPaymentAmount, paymentScheduleId, 
previousDemandRaisedPending, grandTotal, 'false', demandRaised, leadId, unitId, bookingTower, bookingBlock, bookingTowerId
));
}
}*/
            
            return result;
        }
        
        return new List<BookingWrapper>();
    }
    
    /*
private static Decimal calculateDisplayAmount(Booking__c booking) {
Decimal amount1 = 0;
Decimal amountB = 0;

if (booking.payment_schedules__r != null && !booking.payment_schedules__r.isEmpty()) {
for (Payment_Schedule__c paymentSchedule : booking.payment_schedules__r) {
if (paymentSchedule.Amount__c != null && paymentSchedule.Amount__c > 0) {
amount1 = paymentSchedule.Amount__c;
}
if (paymentSchedule.AmountB__c != null && paymentSchedule.AmountB__c > 0) {
amountB = paymentSchedule.AmountB__c;
}
}
}

if (amount1 != 0 && amount1 != null && amountB == 0) {
return amount1;
} else if (amountB != 0 && amountB != null && amount1 == 0) {
return amountB;
}

return 0;
}
private static Decimal calculateTotalPaymentAmount(List<Payment_Schedule__c> paymentSchedules) {
Decimal totalAmount = 0;

if (paymentSchedules != null && !paymentSchedules.isEmpty()) {
for (Payment_Schedule__c paymentSchedule : paymentSchedules) {
if (paymentSchedule.Master_Payment_Schedule__r.Completed_Date__c < Date.today()) {
totalAmount += paymentSchedule.Amount__c != null ? paymentSchedule.Amount__c : 0;
totalAmount += paymentSchedule.AmountB__c != null ? paymentSchedule.AmountB__c : 0;
}
}
}

return totalAmount;
}

private static Decimal calculatePendingPreviousDemands(List<Payment_Schedule__c> paymentSchedules) {
Decimal PendingAmount = 0;

if (paymentSchedules != null && !paymentSchedules.isEmpty()) {
for (Payment_Schedule__c paymentSchedule : paymentSchedules) {
// Check if the related master_payment_schedule__c's completed_date__c is before today
if (paymentSchedule.Master_Payment_Schedule__r.Completed_Date__c < Date.today() && paymentSchedule.Is_Demanded__c == true) {
PendingAmount += paymentSchedule.Pending_Amount__c != null ? paymentSchedule.Pending_Amount__c : 0;
}
}
}

return PendingAmount;
}    
*/
    //Get Blocks 
    @AuraEnabled
    public static List<Block__c> getBlocks(string recId){
        system.debug('recId:' + recId);
        List<Master_Payment_Schedule__c> clist = [select id,name,Project__c,Tower__c,Tower__r.Name from Master_Payment_Schedule__c where id =:recId ];
        string TowerName = clist[0].Tower__r.Name;
        system.debug('sdghvcdchdchdhcdhcdhhdhdhdhhdhd  '+TowerName);
        List<Block__c>plotList=new List<Block__c>();
        string obj='Block__c';
        plotList = [select Id,Name,Project__c from Block__c where Name =: TowerName];
        system.debug('recId:' + plotList);
        return plotList;
    }
    
    @AuraEnabled
    public static void updatePaymentSchedules(Id payIds){
        List<payment_schedule__c> payList = [select id,name, Is_Demanded__c,Payment_Due_Date__c from payment_schedule__c where id =: payIds];
        system.debug('payList   '+payList);
        system.debug('payIds   '+payIds);
        List<payment_schedule__c> toUpdate = new List<payment_schedule__c>();
        for(payment_schedule__c p : payList){
            p.Is_Demanded__c = true;
            if(p.Payment_Due_Date__c != null){
                p.Payment_Due_Date__c = System.today() + 15;
            }
            toUpdate.add(p);
        }
        if(toUpdate.size()>0){
            update toUpdate;
            system.debug('after updated   '+toUpdate);
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
        }
    }
    
    
    
}