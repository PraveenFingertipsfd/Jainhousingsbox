public class PaymentScheduleCustomSelectController {
    @AuraEnabled
    public static List<Payment_schedule__c> getPaymentSchedules(Id bookingId) {
        return [ SELECT Id, Name, status__c,S_No__c, Pending_Amount__c FROM Payment_schedule__c WHERE Booking__c = :bookingId ORDER BY S_No__c asc ];
    }
    @AuraEnabled
    public static String raiseDemand(id milestoneId, String demandEmailContent, list<id> documentIds){
        Payment_Schedule__c psRecord = [ SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c, Booking__r.Property_Type_For__c, Booking__r.Tower__c, Booking__c, Master_Payment_Schedule__r.S_No__c, Master_Payment_Schedule__c FROM Payment_Schedule__c WHERE Id = :milestoneId ];
        Booking__c book = [SELECT Id,Interest_Waive_Off__c,Total_Interest_Waive_Off__c,GST__c,Debit_Amount__c,Total__c,Finance_User__c, Name, Project__c,Project1__r.Name, Property_Type_For__c, Block__c, Tower__c FROM Booking__c WHERE Id = :psRecord.Booking__c];
        
        String result = '';    
        if (psRecord.Booking__r.Property_Type_For__c == 'Apartments') {
            result = apartmentScheduleCalculations(milestoneId,psRecord.Master_Payment_Schedule__c,book, demandEmailContent, documentIds);
            return result;
        }else if (psRecord.Booking__r.Property_Type_For__c == 'Villas')  {
            result = villaScheduleCalculations(milestoneId, book, demandEmailContent, documentIds);
            return result;
        }else{
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No "Property Type" selected for this booking.'));
            return '';
        }
    }
    public static String apartmentScheduleCalculations(Id milestoneId,Id masterId,Booking__c book, String emailContent,list<id> documentIds) {
        String totalAmountPayableInWords = '';
        Decimal totalAmountPayable =0;
        Decimal paidTillPrevMilestone =0;
        String currentCompletedStage = '';
        date demandDueDate;
        Decimal currentMilestonePaymentPercent = 0;
        String currentMilestoneNumber = '';
        date currentCompletedStageDate;
        Decimal totAmtDueTillPrevMilestone = 0;
        Decimal interestPaidTillPrevious = 0;
        Decimal interestDelayTillPrevious = 0;
        Decimal balanceDueTillPrevMilestone = 0;
        Decimal milestonePaymentPercentTill = 0;
        Decimal presentDue = 0;
        Decimal TDSonePercentage = 0;
        Decimal balanceInterest = 0;
        
        list<Master_Payment_Schedule__c> msRecordList = [ SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c FROM Master_Payment_Schedule__c WHERE Id =:masterId Limit 1 ];
        
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
           return 'ERROR: No milestone completed for the booking';
        }
        
        Master_Payment_Schedule__c msRecord = msRecordList[0]; 
        
        if (msRecord != null) {
            currentCompletedStage = msRecord.Name;
            currentCompletedStageDate = msRecord.Completed_Date__c;
            demandDueDate = System.today().addDays(15);
            currentMilestonePaymentPercent = msRecord.Payment_percent__c != null ? msRecord.Payment_percent__c.setScale(0) : 0;
            
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
                AND Master_Payment_Schedule__r.S_No__c < :msRecord.S_No__c 
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
                SELECT SUM(AmountB__c) totalAmountB,SUM(Payment_percent__c) paymentPercentageTill
                FROM Payment_Schedule__c
                WHERE Master_Payment_Schedule__r.S_No__c = :msRecord.S_No__c
                AND Booking__c = :book.Id
            ];
            Decimal presentDueAmount = 0;
            if (presentDueResult != null && presentDueResult.get('totalAmountB') != null) {
                presentDueAmount = (Decimal) presentDueResult.get('totalAmountB');
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
                balanceDueTillPrevMilestone = balanceDueTillPrevMilestoneMod;
            }
            milestonePaymentPercentTill = milestonePaymentPercentResult.setScale(0);
            presentDue = presentDueAmount;
            
            Decimal gstPercentage = (book.GST__c != null) ? book.GST__c / 100 : 0;
            Decimal amountExcludingGST = presentDue / (1 + gstPercentage);
            TDSonePercentage = amountExcludingGST * 0.01; 
            
            balanceInterest = interestDelayTillPrevious - waveOff - interestPaidTillPrevious;
            
            double totalAmount = 0;
            
            if(book.Project1__r.Name == 'MAHENDRA AARYA'){
                totalAmount = (balanceDueTillPrevMilestoneMod + balanceInterest + presentDue).setScale(0);
            }else if(book.Project1__r.Name == 'MAHENDRA ARTO HELIX'){
                totalAmount = (balanceDueTillPrevMilestoneMod + balanceInterest + presentDue - TDSonePercentage).setScale(0) ;
            }
            
            if(totalAmount > -1){
                totalAmountPayable = totalAmount;
            }
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            if (totalAmountPayable != null && totalAmountPayable > -1) {
                totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            }
            
            String fileIdsString = String.join(documentIds, ',');
            
            Demand_Raised__c re = new Demand_Raised__c();
            re.Total_Amount_till_Current_Milestone__C = totalPayableAmount;
            re.Total_Paid_Till__c = paidTotalAmount > 0 ? paidTotalAmount : 0;
            re.Previous_pendings__c = balanceDueTillPrevMilestone;
            re.Interest_Delay_Till_Previous_Milestone__c = totalInterestUplodateAmount;
            re.Total_Interest_Paid__c = totalInterestPaid;
            re.Current_Demand_amount__c = presentDue;
            re.Intrest_Amount__c = balanceInterest;
            re.Grand_Total__c = totalAmountPayable;
            re.Grand_Total_In_Words__c = totalAmountPayableInWords;
            re.Current_Milestone__c = currentCompletedStage;
            re.Milestone_Completed_Date__c = currentCompletedStageDate;
            re.Milestone_Number__c = currentMilestoneNumber;
            re.Due_Date__c = System.Now().addDays(7);
            re.Current_Milestone_Percentage__c = currentMilestonePaymentPercent;
            re.Total_Percentage_till_Current_Milestone__c = milestonePaymentPercentTill;
            re.TDS_Amount__c = TDSonePercentage;
            re.Booking__c = Book.Id;
            re.Total_Flat_Cost__c = Book.Total__c;
            re.Finance_User__c = book.Finance_User__c;
            re.Demand_Email_Content__c = emailContent;
            re.Demand_Content_Ids__c = fileIdsString;
            re.Demanded_Date__c = System.Now();
            re.Payment_schedule__c = milestoneId;
            
            try {
                insert re;
                return 'Demand Raise records created.';
            } catch (DmlException e) {
                System.debug('Error inserting record: ' + e.getMessage());
                return 'Error: ' + e.getMessage();
            }
        }
        else{
            return 'ERROR: No milestone records';
        }
    }
    
    public static String villaScheduleCalculations(Id scheduleId,Booking__c book, String emailContent,list<id> documentIds) {
        
        String totalAmountPayableInWords = '';
        Decimal totalAmountPayable =0;
        Decimal paidTillPrevMilestone =0;
        String currentCompletedStage = '';
        date demandDueDate;
        Decimal currentMilestonePaymentPercent = 0;
        String currentMilestoneNumber = '';
        date currentCompletedStageDate;
        Decimal totAmtDueTillPrevMilestone = 0;
        Decimal interestPaidTillPrevious = 0;
        Decimal interestDelayTillPrevious = 0;
        Decimal balanceDueTillPrevMilestone = 0;
        Decimal milestonePaymentPercentTill = 0;
        Decimal presentDue = 0;
        Decimal TDSonePercentage = 0;
        Decimal balanceInterest = 0;

        
        List<Payment_Schedule__c> psRecordList = [
            SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c
            FROM Payment_Schedule__c
            WHERE Id = :scheduleId
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
            return 'ERROR: No milestone completed for the booking.';
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
                AND S_No__c < :psRecord.S_No__c 
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
            TDSonePercentage = amountExcludingGST * 0.01; 
            
            balanceInterest = interestDelayTillPrevious - interestPaidTillPrevious;
            if (presentDueResult != null && presentDueResult.get('paymentPercentageTill') != null) {
                milestonePaymentPercent = milestonePaymentPercent + (Decimal) presentDueResult.get('paymentPercentageTill');
            }
            if (book.Interest_Waive_Off__c != null) {
                waveOff = book.Interest_Waive_Off__c;
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
            
            double totalAmount = (balanceDueTillPrevMilestoneMod + (interestDelayTillPrevious - interestPaidTillPrevious) + presentDue).setScale(0);
            
            if(totalAmount > -1){
                totalAmountPayable = totalAmount;
            }
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            
            if (totalAmountPayable != null && totalAmountPayable > -1) {
                totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            }
           String fileIdsString = String.join(documentIds, ',');
            
            Demand_Raised__c re = new Demand_Raised__c();
            re.Total_Amount_till_Current_Milestone__C = totalPayableAmount;
            re.Total_Paid_Till__c = paidTotalAmount > 0 ? paidTotalAmount : 0;
            re.Previous_pendings__c = balanceDueTillPrevMilestone;
            re.Interest_Delay_Till_Previous_Milestone__c = totalInterestUplodateAmount;
            re.Total_Interest_Paid__c = totalInterestPaid;
            re.Current_Demand_amount__c = presentDue;
            re.Intrest_Amount__c = balanceInterest;
            re.Grand_Total__c = totalAmountPayable;
            re.Grand_Total_In_Words__c = totalAmountPayableInWords;
            re.Current_Milestone__c = currentCompletedStage;
            re.Milestone_Completed_Date__c = currentCompletedStageDate;
            re.Milestone_Number__c = currentMilestoneNumber;
            re.Due_Date__c = System.Now().addDays(7);
            re.Current_Milestone_Percentage__c = currentMilestonePaymentPercent;
            re.Total_Percentage_till_Current_Milestone__c = milestonePaymentPercentTill;
            re.TDS_Amount__c = TDSonePercentage;
            re.Booking__c = Book.Id;
            re.Total_Flat_Cost__c = Book.Total__c;
            re.Finance_User__c = book.Finance_User__c;
            re.Demand_Email_Content__c = emailContent;
            re.Demand_Content_Ids__c = fileIdsString;
            re.Demanded_Date__c = System.Now();
            re.Payment_schedule__c = scheduleId;
            
            try {
                insert re;
                return 'Demand Raise records created and submitted for approval.';
            } catch (DmlException e) {
                System.debug('Error inserting record: ' + e.getMessage());
                return 'Error: ' + e.getMessage();
            }
        }else{
            return 'ERROR: No milestone records';
        }
    }
    
    public static Map<Integer, String> daySuffixMap = new Map<Integer, String>{1 => 'st', 2 => 'nd', 3 => 'rd', 21 => 'st', 22 => 'nd', 23 => 'rd', 31 => 'st'};
    public static String getMilestoneLabel(Integer sNo) {
        if (sNo == null) {
            return 'Invalid milestone';
        }
        // Determine the suffix, default to 'th'
        String suffix = daySuffixMap.containsKey(sNo) ? daySuffixMap.get(sNo) : 'th';
        
        return sNo + suffix;
    }
}