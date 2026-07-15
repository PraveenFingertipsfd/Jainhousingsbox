public class DemandRaisedSave {
    
    @AuraEnabled
    public static Demand_Raised__c getDemandRaised(id recordId){
        Demand_Raised__c demand = [SELECT             Total_Amount_till_Current_Milestone__c, 
                                   Total_Paid_Till__c, 
                                   Previous_pendings__c,
                                   Interest_Delay_Till_Previous_Milestone__c, 
                                   Total_Interest_Paid__c,
                                   Current_Demand_amount__c,
                                   Intrest_Amount__c,
                                   Grand_Total__c,
                                   Grand_Total_In_Words__c,
                                   Current_Milestone__c,
                                   Milestone_Completed_Date__c,
                                   Milestone_Number__c,
                                   Due_Date__c,
                                   Current_Milestone_Percentage__c,
                                   Total_Percentage_till_Current_Milestone__c,
                                   TDS_Amount__c,
                                   Booking__c,
                                   Project_Company__c,
                                   Total_Flat_Cost__c,
                                   Finance_User__c,
                                   Demand_Email_Content__c,
                                   Demand_Content_Ids__c,
                                   Demanded_Date__c 
                                   FROM Demand_Raised__c WHERE id =: recordId LIMIT 1];
        return demand;
    }
    @AuraEnabled
    public static String ResendRaiseDemand(list<Id> recordIds){
        if(recordIds.size() > 0){
            try {
                GenerateDocumnetController.sendEmailGenerateDemand(recordIds);
                List<Demand_Raised__c> recordsToUpdate = [SELECT Id, Demand_Email_Send__c FROM Demand_Raised__c WHERE Id IN :recordIds];
                for (Demand_Raised__c record : recordsToUpdate) {
                    record.Demand_Email_Send__c = true;
                }
                update recordsToUpdate;
                return 'Demand Raise records created and submitted for approval.';
            } catch (Exception e) {
                System.debug('Error during email sending: ' + e.getMessage());
                throw new AuraHandledException('Failed to resend demand. Please try again later.');
            }
        }
        return 'No records to process.';
    }
    
    
    @AuraEnabled
    public Static String RaiseDemand(List<Id> bookingIds, Map<Id,String> emailContents, map<Id,List<String>> contentIds ) {
        
        String demandRaisedReturn='';
        
        // Check if the bookingIds list is not empty
        if (bookingIds == null || bookingIds.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Booking records provided.'));
            return 'No Booking records provided';
        }
        
        List<Booking__c> bookings = [SELECT Id, Interest_Waive_Off__c,Total_Interest_Waive_Off__c,GST__c,Debit_Amount__c, Total__c, Name, Project__c, 
                                     Project1__r.Name, Property_Type_For__c, Block__c, Tower__c,Finance_User__c,Cost_Sheet__c,Cost_Sheet__r.Payment_Type__c FROM Booking__c WHERE Id IN :bookingIds];
        
        if(bookings.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Booking records found.'));
            return 'No Booking records found';
        }
        
        List<Booking__c> apartmentBookings = new List<Booking__c>();
        List<Booking__c> villaBookings = new List<Booking__c>();
        list<string> apartmentBookingIds = new list<string>();
        list<string> villaBookingIds = new list<string>();
        
        for(Booking__c book : bookings) {
            if (book.Property_Type_For__c == 'Apartments') {
                apartmentBookings.add(book);
                apartmentBookingIds.add(book.Id);
            } else if (book.Property_Type_For__c == 'Villas') {
                villaBookings.add(book);
                villaBookingIds.add(book.Id);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No "Property Type" selected for booking: ' + book.Name));
            }
        }
        
        if (!apartmentBookings.isEmpty()){
            List<Demand_Raised__c> apartmentDemands = bulkApartmentScheduleCalculations(apartmentBookings,emailContents,contentIds);
            sendDemandEmail(apartmentBookingIds,emailContents,contentIds);
            if (apartmentDemands != null && !apartmentDemands.isEmpty()) {
                demandRaisedReturn = 'Demand Raise records created and email sent Successfully.';
            }
        }
        if (!villaBookings.isEmpty()){
            List<Demand_Raised__c> villaDemands = villaScheduleCalculations(villaBookings,emailContents,contentIds);
            sendDemandEmail(villaBookingIds,emailContents,contentIds);
            if (villaDemands != null && !villaDemands.isEmpty()) {
                demandRaisedReturn = 'Demand Raise records created and email sent Successfully.';
            }
        }
        return demandRaisedReturn;
    }
    
    @AuraEnabled
    public static void sendDemandEmail(list<string> bookingIds, Map<Id, String> emailContents, Map<Id, List<String>> contentIds) {
        try {
            // Query related Booking and Buyer Email Info
            List<Booking__c> bookings = [SELECT Id, Name,Alternate_Email1__c,Email1__c FROM Booking__c WHERE Id IN :bookingIds];
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            
            // Step 2: Collect all unique ContentDocumentIds from the contentIds map
            Set<Id> allContentDocIds = new Set<Id>();
            for (List<String> docList : contentIds.values()) {
                for (String docId : docList) {
                    allContentDocIds.add(Id.valueOf(docId));
                }
            }
            
            // Step 3: Query latest ContentVersions for those ContentDocumentIds
            Map<Id, Id> contentDocIdToVersionId = new Map<Id, Id>();
            if (!allContentDocIds.isEmpty()) {
                for (ContentVersion cv : [
                    SELECT ContentDocumentId, Id
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :allContentDocIds
                    AND IsLatest = true
                ]) {
                    contentDocIdToVersionId.put(cv.ContentDocumentId, cv.Id);
                }
            }
            
            system.debug('contentIds'+contentIds);
            for (Booking__c booking : bookings) {
                List<String> recpMailIds = new List<String>();
                if (!String.isBlank(booking.Email1__c)) {
                    recpMailIds.add(booking.Email1__c);
                }
                if (!String.isBlank(booking.Alternate_Email1__c)) {
                    recpMailIds.add(booking.Alternate_Email1__c);
                }
                
                if (recpMailIds.isEmpty()) {
                    System.debug('Skipping receipt ' + booking.Id + ' — no email addresses found.');
                    continue;
                }
                
                String emailBody = emailContents.containsKey(booking.Id) ? emailContents.get(booking.Id) : 'Dear Customer, please find your demand note.';
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(recpMailIds);
                mail.setSubject('Jain Housing - Payment Due – Demand Letter Attached');
                mail.setHtmlBody(emailBody);
                
                
                
                if (contentIds.containsKey(booking.Id)) {
                    List<Id> versionIds = new List<Id>();
                    for (String docIdStr : contentIds.get(booking.Id)) {
                        Id docId = Id.valueOf(docIdStr);
                        if (contentDocIdToVersionId.containsKey(docId)) {
                            versionIds.add(contentDocIdToVersionId.get(docId));
                        }
                    }
                    if (!versionIds.isEmpty()) {
                        mail.setEntityAttachments(versionIds);
                    }
                }
                
                
                PageReference pdfPage = Page.DemandRaiseEmailTemp;
                pdfPage.getParameters().put('id', booking.Id);
                Blob pdfBlob = pdfPage.getContentAsPDF();
                
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Demand.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                
                emailsToSend.add(mail);
            }
            
            // Bulk Send
            if (!emailsToSend.isEmpty()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend, false);
                
                for (Messaging.SendEmailResult result : results) {
                    if (!result.isSuccess()) {
                        system.debug('❌ Some emails failed: ' + result.getErrors()[0].getMessage());
                    }
                }
            }
            
            //return new DemandEmailResult(true, '✅ Demand emails sent successfully.');
            
        } catch (Exception e) {
            //return new DemandEmailResult(false, '❌ Error: ' + e.getMessage());
            system.debug('❌ Error: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Demand_Raised__c> bulkApartmentScheduleCalculations(List<Booking__c> bookings, Map<Id, String> emailContents, Map<Id, List<String>> contentIds) {
        Decimal completed_StageNumber;
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        List<Booking__c> CustomBookings = new List<Booking__c>();
        List<Booking__c> StandardBookings = new List<Booking__c>();
        
        Set<Id> towerIds = new Set<Id>();
        for (Booking__c book : bookings) {
            if(book.Cost_Sheet__c != null && book.Cost_Sheet__r.Payment_Type__c == 'Standard'){
                StandardBookings.add(book);
                towerIds.add(book.Tower__c);
            }
            else if(book.Cost_Sheet__c != null && book.Cost_Sheet__r.Payment_Type__c == 'Custom'){
                CustomBookings.add(book);
            }
        }
        
        //For Bookings of Standard Payment Schedule
        if(!StandardBookings.isEmpty()){
            Map<Id, Master_Payment_Schedule__c> towerToMasterPaymentScheduleMap = new Map<Id, Master_Payment_Schedule__c>();
            
            List<Master_Payment_Schedule__c> msRecords = [SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c, Tower__c FROM Master_Payment_Schedule__c 
                                                          WHERE Status__c = 'Completed' AND Tower__c IN: towerIds ORDER BY S_No__c DESC];
            for (Master_Payment_Schedule__c msRecord : msRecords) {
                system.debug('msRecord > '+msRecord);
                if (!towerToMasterPaymentScheduleMap.containsKey(msRecord.Tower__c)) {
                    towerToMasterPaymentScheduleMap.put(msRecord.Tower__c, msRecord);
                }
            }
            
            map<id,Decimal> debitAmountMap = new map<id,Decimal>();
            map<id,Decimal> WaveOffMap = new map<id,Decimal>();
            
            for (Booking__c book : StandardBookings) {
                if (towerToMasterPaymentScheduleMap.containsKey(book.Tower__c)) {
                    completed_StageNumber = towerToMasterPaymentScheduleMap.get(book.Tower__c).S_No__c;
                }
                debitAmountMap.put(book.Id, book.Debit_Amount__c);
                WaveOffMap.put(book.Id,book.Total_Interest_Waive_Off__c);
            }
            
            List<AggregateResult> aggregateResults = [
                SELECT Booking__c, SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Amount__c) totalInterestAmount,
                SUM(AmountB__c) totalPayableAmount, SUM(Interest_Up_to_Date__c) totalInterestUplodate,
                SUM(Interest_Paid__c) totalInterestPaid, SUM(Payment_percent__c) paymentPercentageTill
                FROM Payment_Schedule__c
                WHERE Master_Payment_Schedule__r.Status__c = 'Completed' 
                AND Booking__c IN :StandardBookings AND Master_Payment_Schedule__r.S_No__c != :completed_StageNumber
                GROUP BY Booking__c
            ];
            
            // Map to store the aggregated payment schedule results
            Map<Id, AggregateResult> bookingToAggregateResultMap = new Map<Id, AggregateResult>();
            for (AggregateResult result : aggregateResults) {
                bookingToAggregateResultMap.put((Id) result.get('Booking__c'), result);
            }
            
            // Query total received amounts for all bookings
            List<AggregateResult> totalReceivedResults = [
                SELECT Booking__c, SUM(Received_Amount1__c) totalReceivedAmount,SUM(AmountB__c) totalAmountB
                FROM Payment_Schedule__c
                WHERE Booking__c IN :StandardBookings AND Master_Payment_Schedule__r.S_No__c = :completed_StageNumber
                GROUP BY Booking__c
            ];
            
            List<AggregateResult> totalReceivedAmount = [
                SELECT Booking__c, SUM(Received_Amount1__c) totalReceivedAmount
                FROM Payment_Schedule__c
                WHERE Booking__c IN :StandardBookings
                GROUP BY Booking__c
            ];
            Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
            for (AggregateResult result : totalReceivedAmount) {
                bookingToReceivedAmountMap.put((Id) result.get('Booking__c'), (Decimal) result.get('totalReceivedAmount'));
            }
            
            // Map to store total received amounts per booking
            Map<Id, Decimal> bookingToThisMSAmountMap = new Map<Id, Decimal>();
            for (AggregateResult result : totalReceivedResults) {
                bookingToThisMSAmountMap.put((Id) result.get('Booking__c'), (Decimal) result.get('totalAmountB'));
            }
            
            List<Payment_Schedule__c> paymentSchedules = [
                SELECT Booking__c,Id, Master_Payment_Schedule__r.S_No__c
                FROM Payment_Schedule__c
                WHERE Booking__c IN :StandardBookings AND Master_Payment_Schedule__r.S_No__c = :completed_StageNumber
            ];
            
            map<Id,Id> bookingtopayment = new map<Id,Id>();
            if(paymentSchedules.size() > 0){
                for(Payment_Schedule__c pay : paymentSchedules){
                    bookingtopayment.put((Id) pay.Booking__c, (Id) pay.Id);
                }
            }
            
            // Process each booking and calculate demand details
            for (Booking__c book : StandardBookings) {
                Master_Payment_Schedule__c msRecord = towerToMasterPaymentScheduleMap.get(book.Tower__c);
                if (msRecord == null) {
                    continue;
                }
                
                AggregateResult aggregateResult = bookingToAggregateResultMap.get(book.Id);
                if (aggregateResult == null) {
                    continue;
                }
                
                Decimal totalPendingAmount = (Decimal) aggregateResult.get('totalPendingAmount') != null ? (Decimal) aggregateResult.get('totalPendingAmount') : 0;
                Decimal totalInterestAmount = (Decimal) aggregateResult.get('totalInterestAmount') != null ? (Decimal) aggregateResult.get('totalInterestAmount') : 0;
                Decimal totalPayableAmount = (Decimal) aggregateResult.get('totalPayableAmount') != null ? (Decimal) aggregateResult.get('totalPayableAmount') : 0;
                Decimal totalInterestUplodateAmount = (Decimal) aggregateResult.get('totalInterestUplodate') != null ? (Decimal) aggregateResult.get('totalInterestUplodate') : 0;
                Decimal totalInterestPaid = (Decimal) aggregateResult.get('totalInterestPaid') != null ? (Decimal) aggregateResult.get('totalInterestPaid') : 0;
                Decimal milestonePaymentPercent = (Decimal) aggregateResult.get('paymentPercentageTill') != null ? (Decimal) aggregateResult.get('paymentPercentageTill') : 0;
                
                Decimal paidTotalAmount = bookingToReceivedAmountMap.get(book.Id) != null ? bookingToReceivedAmountMap.get(book.Id) : 0 ;
                if(debitAmountMap.get(book.Id) != null){
                    paidTotalAmount -= debitAmountMap.get(book.Id);
                }
                
                Decimal balanceDueTillPrevMilestoneMod = totalPayableAmount - paidTotalAmount;            
                Decimal balanceDueTillPrevMilestone = balanceDueTillPrevMilestoneMod > 0 ? balanceDueTillPrevMilestoneMod : 0;
                Decimal waivedOffInterest = WaveOffMap.containsKey(book.Id) && WaveOffMap.get(book.Id) != null ? WaveOffMap.get(book.Id) : 0;
                
                Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid - waivedOffInterest;
                
                Decimal presentDue = bookingToThisMSAmountMap.get(book.Id) != null ? bookingToThisMSAmountMap.get(book.Id) : 0;
                
                Decimal actualTotalAmountPayable;
                actualTotalAmountPayable = balanceDueTillPrevMilestoneMod + balanceInterest + presentDue;
                
                Decimal totalAmountPayable = actualTotalAmountPayable > 0 ? actualTotalAmountPayable : 0;
                
                // Convert total amount payable to words
                NumberTOWordConvertion convert = new NumberTOWordConvertion();
                String totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
                
                List<String> allFileIds = new List<String>();
                allFileIds.addAll(contentIds.get(book.Id));
                String fileIdsString = String.join(allFileIds, ',');
                
                // Create Demand_Raised__c record
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
                re.Current_Milestone__c = msRecord.Name;
                re.Milestone_Completed_Date__c = msRecord.Completed_Date__c;
                re.Milestone_Number__c = getMilestoneLabel(msRecord.S_No__c.intValue());
                re.Due_Date__c = System.Now().addDays(7);
                re.Current_Milestone_Percentage__c = msRecord.Payment_percent__c.setScale(0);
                re.Total_Percentage_till_Current_Milestone__c = milestonePaymentPercent.setScale(0) + msRecord.Payment_percent__c.setScale(0);
                re.Booking__c = book.Id;
                re.Total_Flat_Cost__c = book.Total__c;
                re.Finance_User__c = book.Finance_User__c;
                re.Demand_Email_Content__c = emailContents.get(book.Id);
                re.Demand_Content_Ids__c = fileIdsString;
                re.Demanded_Date__c = System.Now();
                re.Payment_schedule__c = bookingtopayment.get(book.Id);
                
                demands.add(re); // Add the record to the list
            }
            
            // Insert all Demand_Raised__c records into the database
            if (!demands.isEmpty()) {
                insert demands;
            }
            
            list<Payment_schedule__c> updatepaymentSchedule = [SELECT id, Master_Payment_Schedule__r.S_No__c, Is_Demanded__c, Booking__c FROM Payment_schedule__c WHERE Booking__c IN :StandardBookings AND Master_Payment_Schedule__r.S_No__c = :completed_StageNumber];
            if (!updatepaymentSchedule.isEmpty()) {
                for(Payment_schedule__c pay : updatepaymentSchedule){
                    pay.Is_Demanded__c = true;
                }
                update updatepaymentSchedule;
            }
            
        }
        else if(!CustomBookings.isEmpty()){
            
            Map<Id, Payment_Schedule__c> bookingToPaymentScheduleMap = new Map<Id, Payment_Schedule__c>();
            List<Payment_Schedule__c> bookingPaymentSchedules = [ SELECT Booking__c,Id,S_No__c FROM Payment_Schedule__c WHERE Booking__c IN :CustomBookings ORDER BY S_No__c DESC];
            for (Payment_Schedule__c psRecord : bookingPaymentSchedules) {
                if (!bookingToPaymentScheduleMap.containsKey(psRecord.Booking__c)) {
                    bookingToPaymentScheduleMap.put(psRecord.Booking__c, psRecord);
                }
            }
            
            map<id,Decimal> debitAmountMap = new map<id,Decimal>();
            map<id,Decimal> WaveOffMap = new map<id,Decimal>();
            
            for (Booking__c book : CustomBookings) {
                if (bookingToPaymentScheduleMap.containsKey(book.Id)) {
                    completed_StageNumber = bookingToPaymentScheduleMap.get(book.Id).S_No__c;
                }
                debitAmountMap.put(book.Id, book.Debit_Amount__c);
                WaveOffMap.put(book.Id,book.Total_Interest_Waive_Off__c);
            }
            
            List<AggregateResult> aggregateResults = [	
                SELECT Booking__c, SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Amount__c) totalInterestAmount,
                SUM(AmountB__c) totalPayableAmount, SUM(Interest_Up_to_Date__c) totalInterestUplodate,
                SUM(Interest_Paid__c) totalInterestPaid, SUM(Payment_percent__c) paymentPercentageTill
                FROM Payment_Schedule__c
                WHERE status__c = 'Completed' 
                AND Booking__c IN :CustomBookings AND S_No__c != :completed_StageNumber
                GROUP BY Booking__c
            ];
            
            // Map to store the aggregated payment schedule results
            Map<Id, AggregateResult> bookingToAggregateResultMap = new Map<Id, AggregateResult>();
            for (AggregateResult result : aggregateResults) {
                bookingToAggregateResultMap.put((Id) result.get('Booking__c'), result);
            }
            
            // Query total received amounts for all bookings
            List<AggregateResult> totalReceivedResults = [
                SELECT Booking__c, SUM(Received_Amount1__c) totalReceivedAmount,SUM(AmountB__c) totalAmountB
                FROM Payment_Schedule__c
                WHERE Booking__c IN :CustomBookings AND S_No__c = :completed_StageNumber
                GROUP BY Booking__c
            ];
            
            List<AggregateResult> totalReceivedAmount = [
                SELECT Booking__c, SUM(Received_Amount1__c) totalReceivedAmount
                FROM Payment_Schedule__c
                WHERE Booking__c IN :CustomBookings
                GROUP BY Booking__c
            ];
            Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
            for (AggregateResult result : totalReceivedAmount) {
                bookingToReceivedAmountMap.put((Id) result.get('Booking__c'), (Decimal) result.get('totalReceivedAmount'));
            }
            
            // Map to store total received amounts per booking
            Map<Id, Decimal> bookingToThisMSAmountMap = new Map<Id, Decimal>();
            for (AggregateResult result : totalReceivedResults) {
                bookingToThisMSAmountMap.put((Id) result.get('Booking__c'), (Decimal) result.get('totalAmountB'));
            }
            
            List<Payment_Schedule__c> paymentSchedules = [
                SELECT Booking__c,Id, Master_Payment_Schedule__r.S_No__c,Completed_Date__c,Name,Payment_percent__c
                FROM Payment_Schedule__c
                WHERE Booking__c IN :CustomBookings AND S_No__c = :completed_StageNumber
            ];
            
            map<Id,Payment_Schedule__c> bookingtopayment = new map<Id,Payment_Schedule__c>();
            if(paymentSchedules.size() > 0){
                for(Payment_Schedule__c pay : paymentSchedules){
                    bookingtopayment.put((Id) pay.Booking__c, pay);
                }
            }
            
            // Process each booking and calculate demand details
            for (Booking__c book : CustomBookings) {
                
                AggregateResult aggregateResult = bookingToAggregateResultMap.get(book.Id);
                if (aggregateResult == null) {
                    continue;
                }
                
                Decimal totalPendingAmount = (Decimal) aggregateResult.get('totalPendingAmount') != null ? (Decimal) aggregateResult.get('totalPendingAmount') : 0;
                Decimal totalInterestAmount = (Decimal) aggregateResult.get('totalInterestAmount') != null ? (Decimal) aggregateResult.get('totalInterestAmount') : 0;
                Decimal totalPayableAmount = (Decimal) aggregateResult.get('totalPayableAmount') != null ? (Decimal) aggregateResult.get('totalPayableAmount') : 0;
                Decimal totalInterestUplodateAmount = (Decimal) aggregateResult.get('totalInterestUplodate') != null ? (Decimal) aggregateResult.get('totalInterestUplodate') : 0;
                Decimal totalInterestPaid = (Decimal) aggregateResult.get('totalInterestPaid') != null ? (Decimal) aggregateResult.get('totalInterestPaid') : 0;
                Decimal milestonePaymentPercent = (Decimal) aggregateResult.get('paymentPercentageTill') != null ? (Decimal) aggregateResult.get('paymentPercentageTill') : 0;
                
                Decimal paidTotalAmount = bookingToReceivedAmountMap.get(book.Id) != null ? bookingToReceivedAmountMap.get(book.Id) : 0 ;
                if(debitAmountMap.get(book.Id) != null){
                    paidTotalAmount -= debitAmountMap.get(book.Id);
                }
                
                Decimal balanceDueTillPrevMilestoneMod = totalPayableAmount - paidTotalAmount;            
                Decimal balanceDueTillPrevMilestone = balanceDueTillPrevMilestoneMod > 0 ? balanceDueTillPrevMilestoneMod : 0;
                Decimal waivedOffInterest = WaveOffMap.containsKey(book.Id) && WaveOffMap.get(book.Id) != null ? WaveOffMap.get(book.Id) : 0;
                
                Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid - waivedOffInterest;
                
                Decimal presentDue = bookingToThisMSAmountMap.get(book.Id) != null ? bookingToThisMSAmountMap.get(book.Id) : 0;
                
                Decimal actualTotalAmountPayable;
                actualTotalAmountPayable = balanceDueTillPrevMilestoneMod + balanceInterest + presentDue;
                
                Decimal totalAmountPayable = actualTotalAmountPayable > 0 ? actualTotalAmountPayable : 0;
                
                // Convert total amount payable to words
                NumberTOWordConvertion convert = new NumberTOWordConvertion();
                String totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
                
                List<String> allFileIds = new List<String>();
                allFileIds.addAll(contentIds.get(book.Id));
                String fileIdsString = String.join(allFileIds, ',');
                
                // Create Demand_Raised__c record
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
                re.Current_Milestone__c = bookingtopayment.get(book.Id).Name;
                re.Milestone_Completed_Date__c = bookingtopayment.get(book.Id).Completed_Date__c;
                re.Milestone_Number__c = getMilestoneLabel(bookingtopayment.get(book.Id).S_No__c.intValue());
                re.Due_Date__c = System.Now().addDays(7);
                re.Current_Milestone_Percentage__c = bookingtopayment.get(book.Id).Payment_percent__c.setScale(0);
                re.Total_Percentage_till_Current_Milestone__c = milestonePaymentPercent.setScale(0) + bookingtopayment.get(book.Id).Payment_percent__c.setScale(0);
                re.Booking__c = book.Id;
                re.Total_Flat_Cost__c = book.Total__c;
                re.Finance_User__c = book.Finance_User__c;
                re.Demand_Email_Content__c = emailContents.get(book.Id);
                re.Demand_Content_Ids__c = fileIdsString;
                re.Demanded_Date__c = System.Now();
                re.Payment_schedule__c = bookingtopayment.get(book.Id).Id;
                
                demands.add(re); // Add the record to the list
            }
            
            // Insert all Demand_Raised__c records into the database
            if (!demands.isEmpty()) {
                insert demands;
            }
            
            list<Payment_schedule__c> updatepaymentSchedule = [SELECT id, Master_Payment_Schedule__r.S_No__c, Is_Demanded__c, Booking__c FROM Payment_schedule__c WHERE Booking__c IN :CustomBookings AND S_No__c = :completed_StageNumber];
            if (!updatepaymentSchedule.isEmpty()) {
                for(Payment_schedule__c pay : updatepaymentSchedule){
                    pay.Is_Demanded__c = true;
                }
                update updatepaymentSchedule;
            }
        }
        
        
        
        
        
        return demands; // Return the list of created Demand_Raised__c records
    }
    
    @AuraEnabled
    public Static List<Demand_Raised__c> villaScheduleCalculations(List<Booking__c> bookings,Map<Id,String> emailContents, map<Id,List<String>> contentIds) {
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        Map<Id, Payment_Schedule__c> bookingLatestPaymentSchedules = new Map<Id, Payment_Schedule__c>();
        Map<Id, List<Payment_Schedule__c>> groupedByBooking = new Map<Id, List<Payment_Schedule__c>>();
        Map<Id, Booking__c> bookingProjectMap = new Map<Id, Booking__c>();
        map<id,Decimal> debitAmountMap = new map<id,Decimal>();
        map<id,Decimal> WaveOffMap = new map<id,Decimal>();
        
        for (Booking__c book : bookings) {
            bookingProjectMap.put(book.Id, book);
            debitAmountMap.put(book.Id, book.Debit_Amount__c);
            WaveOffMap.put(book.Id,book.Total_Interest_Waive_Off__c);
        }
        
        List<Payment_Schedule__c> psRecords = [
            SELECT Id, S_No__c, Booking__c,Name,Payment_percent__c,Interest_Paid__c,Received_Amount1__c,Completed_Date__c,Interest_Up_to_Date__c,AmountB__c,Interest_Amount__c,Pending_Amount__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' AND Booking__c IN :bookings
        ];
        
        for (Payment_Schedule__c ps : psRecords) {
            if (!groupedByBooking.containsKey(ps.Booking__c)) {
                groupedByBooking.put(ps.Booking__c, new List<Payment_Schedule__c>());
            }
            groupedByBooking.get(ps.Booking__c).add(ps);
        }
        
        for (Id bookingId : groupedByBooking.keySet()) {
            List<Payment_Schedule__c> schedules = groupedByBooking.get(bookingId);
            Decimal highestSNo = 0;
            Payment_Schedule__c latestps;
            for (Payment_Schedule__c schedule : schedules) {
                if (schedule.S_No__c != null && schedule.S_No__c > highestSNo) {
                    highestSNo = schedule.S_No__c;
                    latestps = schedule;
                }
            }
            bookingLatestPaymentSchedules.put(bookingId, latestps);         
        }
        
        List<AggregateResult> aggregateResults = [
            SELECT Booking__c, 
            SUM(Pending_Amount__c) totalPendingAmount, 
            SUM(Interest_Amount__c) totalInterestAmount,
            SUM(AmountB__c) totalPayableAmount, 
            SUM(Interest_Up_to_Date__c) totalInterestUplodate, 
            SUM(Received_Amount1__c) totalReceivedAmount,
            SUM(Interest_Paid__c) totalInterestPaid, 
            SUM(Payment_percent__c) paymentPercentageTill
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' 
            AND Booking__c IN :bookings
            GROUP BY Booking__c
        ];
        
        Map<Id, AggregateResult> bookingToAggregateResultMap = new Map<Id, AggregateResult>();
        Map<Id, Decimal> bookingToPendingAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPayableAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestUpToDateAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestPaidMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPaymentPercentageMap = new Map<Id, Decimal>();
        
        for (AggregateResult result : aggregateResults) {
            Id bookingId = (Id) result.get('Booking__c');
            
            bookingToPendingAmountMap.put(bookingId, (Decimal) result.get('totalPendingAmount'));
            bookingToInterestAmountMap.put(bookingId, (Decimal) result.get('totalInterestAmount'));
            bookingToPayableAmountMap.put(bookingId, (Decimal) result.get('totalPayableAmount'));
            bookingToInterestUpToDateAmountMap.put(bookingId, (Decimal) result.get('totalInterestUplodate'));
            bookingToReceivedAmountMap.put(bookingId, (Decimal) result.get('totalReceivedAmount'));
            bookingToInterestPaidMap.put(bookingId, (Decimal) result.get('totalInterestPaid'));
            bookingToPaymentPercentageMap.put(bookingId, (Decimal) result.get('paymentPercentageTill'));
            
            bookingToAggregateResultMap.put(bookingId, result);
        }
        
        for (Id bookingId : bookingToPendingAmountMap.keySet()) {
            Decimal pendingAmount = bookingToPendingAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).Pending_Amount__c;
            Decimal interestAmount = bookingToInterestAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).Interest_Amount__c;
            Decimal payableAmount = bookingToPayableAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).AmountB__c;
            
            Decimal receivedAmount = bookingToReceivedAmountMap.get(bookingId);
            
            if(debitAmountMap.get(bookingId) != null){
                receivedAmount -= debitAmountMap.get(bookingId);
            }
            
            Decimal PaymentPercentage = bookingToPaymentPercentageMap.get(bookingId);
            Decimal CurrentPaymentPercentage = bookingLatestPaymentSchedules.get(bookingId).Payment_percent__c;
            Decimal totalInterestUplodateAmount = bookingToInterestUpToDateAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).Interest_Up_to_Date__c;
            Decimal totalInterestPaid = bookingToInterestPaidMap.get(bookingId);
            Decimal balanceDueTillPrevMilestoneMod = payableAmount - receivedAmount;
            Decimal balanceDueTillPrevMilestone = balanceDueTillPrevMilestoneMod > 0 ? balanceDueTillPrevMilestoneMod : 0;
            Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid - WaveOffMap.get(bookingId);
            Decimal presentDue = bookingLatestPaymentSchedules.get(bookingId).AmountB__c;
            
            Decimal gstPercentage = (bookingProjectMap.get(bookingId).GST__c  != null) ? bookingProjectMap.get(bookingId).GST__c / 100 : 0;
            Decimal amountExcludingGST = presentDue / (1 + gstPercentage);
            Decimal TDSonePercentage = amountExcludingGST * 0.01; 
            
            String currentMilestone = bookingLatestPaymentSchedules.get(bookingId).Name;
            Date currentMilestoneCompletedDate = bookingLatestPaymentSchedules.get(bookingId).Completed_Date__c;
            String currentMilestoneNumber =getMilestoneLabel(bookingLatestPaymentSchedules.get(bookingId).S_No__c.intValue());
            Decimal totalFlatCost = bookingProjectMap.get(bookingId).Total__c;
            id FinanceUser = bookingProjectMap.get(bookingId).Finance_User__c;
            Id currentMilestoneId = bookingLatestPaymentSchedules.get(bookingId).Id;
            Decimal actualTotalAmountPayable;
            if (bookingProjectMap.get(bookingId).Project__c == 'MAHENDRA AARYA') {
                actualTotalAmountPayable = (balanceDueTillPrevMilestoneMod + balanceInterest + presentDue).setScale(0);
            } else if (bookingProjectMap.get(bookingId).Project__c == 'MAHENDRA ARTO HELIX') {
                actualTotalAmountPayable = (balanceDueTillPrevMilestoneMod + balanceInterest + presentDue - TDSonePercentage).setScale(0);
            } else {
                actualTotalAmountPayable = balanceDueTillPrevMilestoneMod + balanceInterest + presentDue;
            }
            Decimal totalAmountPayable = actualTotalAmountPayable > 0 ? actualTotalAmountPayable : 0;
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            
            List<String> allFileIds = new List<String>();
            allFileIds.addAll(contentIds.get(bookingId));
            String fileIdsString = String.join(allFileIds, ',');
            
            Demand_Raised__c re = new Demand_Raised__c();
            re.Total_Amount_till_Current_Milestone__C = payableAmount;
            re.Total_Paid_Till__c = receivedAmount > 0 ? receivedAmount : 0;
            re.Previous_pendings__c = balanceDueTillPrevMilestone;
            re.Interest_Delay_Till_Previous_Milestone__c = totalInterestUplodateAmount;
            re.Total_Interest_Paid__c = totalInterestPaid;
            re.Current_Demand_amount__c = presentDue;
            re.Intrest_Amount__c = balanceInterest;
            re.Grand_Total__c = totalAmountPayable;
            re.Grand_Total_In_Words__c = totalAmountPayableInWords;
            re.Current_Milestone__c = currentMilestone;
            re.Milestone_Completed_Date__c = currentMilestoneCompletedDate;
            re.Milestone_Number__c = currentMilestoneNumber;
            re.Due_Date__c = System.Now().addDays(7);
            re.Current_Milestone_Percentage__c = CurrentPaymentPercentage;
            re.Total_Percentage_till_Current_Milestone__c = PaymentPercentage;
            re.TDS_Amount__c = TDSonePercentage;
            re.Booking__c = bookingId;
            re.Total_Flat_Cost__c = totalFlatCost;
            re.Finance_User__c = FinanceUser;
            re.Demand_Email_Content__c = emailContents.get(bookingId);
            re.Demand_Content_Ids__c = fileIdsString;
            re.Demanded_Date__c = System.Now();
            re.Payment_schedule__c = currentMilestoneId;
            demands.add(re); // Add the record to the list
        }
        
        // Insert all Demand_Raised__c records into the database
        if (!demands.isEmpty()) {
            insert demands;
        }
        list<Payment_Schedule__c> updatePS = new list<Payment_Schedule__c>();
        for (Id bookingId : bookingLatestPaymentSchedules.keySet()) {
            Payment_Schedule__c schedule = bookingLatestPaymentSchedules.get(bookingId);
            schedule.Is_Demanded__c = true;
            updatePS.add(schedule);
        }
        if(!updatePS.isEmpty()){
            update updatePS;
        }
        return demands;
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
    
    @AuraEnabled
    public static BookingWrapper getBookingRecord(Id recordId) {
        system.debug(recordId);
        Booking__c booking = [ SELECT Id, Name, Project_Company__c, Project__c, Project1__r.Name, Agreement_Cost__c, Bank__c, Total_received_Amount__c, First_Applicant_Name__c, 
                              salutation_Applicant1__c, salutation_Applicant2__c, Second_Applicant_Name__c FROM Booking__c WHERE Id = :recordId LIMIT 1 ];
        
        List<Payment_Schedule__c> psRecordList = [ SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c FROM Payment_Schedule__c 
                                                  WHERE Status__c = 'Completed' AND Booking__c = :recordId ORDER BY S_No__c DESC LIMIT 1];
        
        system.debug(psRecordList);
        Payment_Schedule__c currentMilestone = psRecordList.isEmpty() ? null : psRecordList[0];
        
        // Return the wrapper instance
        return new BookingWrapper(booking, currentMilestone);
    }
    
    public class BookingWrapper {
        @AuraEnabled
        public Booking__c booking { get; set; }
        @AuraEnabled
        public Payment_Schedule__c currentMilestone { get; set; }
        
        // Constructor
        public BookingWrapper(Booking__c booking, Payment_Schedule__c currentMilestone) {
            this.booking = booking;
            this.currentMilestone = currentMilestone;
        }
    }
    
}