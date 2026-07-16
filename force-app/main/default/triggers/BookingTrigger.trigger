trigger BookingTrigger on Booking__c (before insert, before update, after update,after insert){
    if(label.BookingTriggerActive == 'True'){
        if (Trigger.isBefore) {
            if(Trigger.isInsert){
                Set<Id> projectIds = new Set<Id>();
                Set<Id> costSheetIds = new Set<Id>();
                string UnitId = '';
                for (Booking__c newBooking : Trigger.new) {
                    if (newBooking.Project1__c != null) 
                        projectIds.add(newBooking.Project1__c);
                    if(newBooking.Plot__c != null)
                        UnitId = newBooking.Plot__c;
                    newBooking.Booking_Date__c = Date.today();
                }
                Map<Id, Project__c> projectMap = new Map<Id, Project__c>([ SELECT Id, Project__c, CRM_Manager__c, Sales_Manager__c, Finance_User__c, Legal_User__c FROM Project__c WHERE Id IN :projectIds ]);
                for (Booking__c newBooking : Trigger.new) {
                    if(newBooking.Project1__c != null && projectMap.containskey(newBooking.Project1__c)){
                        Project__c prj = projectMap.get(newBooking.Project1__c);
                        newBooking.Sales_Manager1__c = prj.Sales_Manager__c;
                        newBooking.CRM_Manager__c = prj.CRM_Manager__c;
                        newBooking.Finance_User__c = prj.Finance_User__c;
                        newBooking.Legal_Team__c = prj.Legal_User__c;
                        newBooking.Project__c = prj.Project__c;
                    }
                }
                
                if(UnitId != ''){
                    Plot__c pt = new Plot__c(Id = UnitId, Status__c = 'Booked');
                    update pt;
                }
            }
            if(Trigger.isUpdate){
                //document validation added by karthik
                Map<Id, Booking__c> bookingsNeedingValidation = new Map<Id, Booking__c>();
                
                for (Booking__c newBooking : Trigger.new) {
                    
                    
                    Booking__c oldBooking = Trigger.oldMap.get(newBooking.Id);
                    
                    if (oldBooking.Stage__c == 'Reservation' && newBooking.Is_10_Collected__c == true && newBooking.Stage__c != 'Agreement'){
                        newBooking.Stage__c = 'Agreement';
                        newBooking.Sale_Agreement_Status__c = 'Approved';
                    }
                    
                    if (oldBooking.Stage__c == 'Demands & Collection' && newBooking.Is_90_Collected__c == true && newBooking.Stage__c != 'Registration'){
                        newBooking.Stage__c = 'Registration';
                        newBooking.Registration_Approval_Status__c = 'Approved';
                    }
                    
                    // Check for KYC_Documents_Collected__c being set to true
                    if(newBooking.KYC_Documents_Collected__c != Trigger.oldMap.get(newBooking.Id).KYC_Documents_Collected__c && newBooking.KYC_Documents_Collected__c == true) {           
                        bookingsNeedingValidation.put(newBooking.Id, newBooking);
                    }
                    
                    if (newBooking.Approval_status__c != trigger.oldmap.get(newBooking.Id).Approval_status__c && newBooking.Approval_status__c == 'Approved') {
                        BookingController.PushingtoCRM(newBooking);
                    }
                    
                    if(newBooking.Stage__c == 'Sale Agreement Execution Completed'){
                        newBooking.Stage__c = 'Demands & Collection';
                    }
                    
                }
                
                // Validate documents if needed
                if(!bookingsNeedingValidation.isEmpty()) {
                    BookingController.validateRequiredDocuments(bookingsNeedingValidation);
                }
            }
        }
        if(trigger.isAfter){
            if(trigger.isInsert){
                BookingController.MapPaymentSchedules(Trigger.new);
                BookingController.ChangeBookingReqStatus(Trigger.new);
            }
            if(trigger.isupdate){
                List<Booking__c> swapUnit = new List<Booking__c>();
                List<Booking__c> OldUnitDetials = new List<Booking__c>();
                set<Id> plotIds = new set<Id>();
                
                
                //sending feed back form
                List<Id> sendEmailList = new List<Id>();
                for(Booking__c bk:Trigger.new){
                    Booking__c oldBk = Trigger.oldMap.get(bk.Id);
                    //Checking the current and the previous stage
                    if(bk.Stage__c == 'Registration Completed' && oldBk.Stage__c != 'Registration Completed'){
                        if(bk.Email1__c !=null){
                            sendEmailList.add(bk.Id);
                        }
                    }
                    
                    
                }
                if(!sendEmailList.isEmpty()){
                    if (!sendEmailList.isEmpty()) {
                        BookingController.sendRegistrationEmailsAsync(sendEmailList);
                    }
                }
                
                //added by karthik 11/06
                List<Booking__c> bookingsForStatusUpdate = new List<Booking__c>();
                
                //added by karthik 12/06
                Set<Id> saleAgreementToEmail = new Set<Id>();
                
                //added by karthik 13/06 collect ids to send mail for ndc 
                List<Id> approvedRecordIds = new List<Id>();
                
                //added by karthik 17/06 - home notification
                List<Booking__c> updates = new List<Booking__c>();
                
                //added by karthik 17/06 - send reminder mail for reg
                List<Booking__c> toNotifyReg = new List<Booking__c>();
                
                //added by karthik to send cancellation agreement email on cancellation stage
                Set<Id> cancelledBookingIds = new Set<Id>();
                
                
                
                List<Plot__c> plotsToUpdate = new List<Plot__c>();
                for(Booking__c booking :trigger.new){
                    
                    
                    // 10% amount Collection Logic - sale agreement stage
                    if (booking.Is_10_Collected__c && !Trigger.oldMap.get(booking.Id).Is_10_Collected__c) {
                        
                        // Capture 10% Collected Date
                        if (booking.Ten_Percent_Collected_Date__c == null) {
                            updates.add(new Booking__c(
                                Id = booking.Id,
                                Ten_Percent_Collected_Date__c = System.now()
                            ));
                        }
                    }
                    
                    // 10% amount Collection Logic - sale agreement stage
                    if (booking.Is_10_Collected__c && !Trigger.oldMap.get(booking.Id).Is_10_Collected__c && booking.Sale_Agreement_Status__c == 'Submitted for Approval'){      
                        BookingTriggerHelper.recallApproval(booking.Id);
                        bookingsForStatusUpdate.add(new Booking__c(Id = booking.Id,Sale_Agreement_Status__c = 'Approved'));              
                    }
                    
                    //added by karthik 17/06 Reg Notify
                    if (booking.Is_90_Collected__c && !Trigger.oldMap.get(booking.Id).Is_90_Collected__c && booking.Is_90_Collected_Date__c == null) {
                        updates.add(new Booking__c(Id = booking.Id,Is_90_Collected_Date__c = System.now()));     
                    }
                    
                    // 90% amount Collection Logic - registration stage
                    if (booking.Is_90_Collected__c && !Trigger.oldMap.get(booking.Id).Is_90_Collected__c && booking.Registration_Approval_Status__c == 'Submitted for Approval'){    
                        BookingTriggerHelper.recallApproval(booking.Id);
                        bookingsForStatusUpdate.add(new Booking__c(Id = booking.Id,Registration_Approval_Status__c = 'Approved'));  
                    }
                    
                    //karthik 17/06
                    if (booking.Stage__c  == 'Registration' && Trigger.oldMap.get(booking.Id).Stage__c != 'Registration') {
                        toNotifyReg.add(booking);
                    }
                    
                    //collect ids to send ndc mail
                    if (booking.NDC_Approval_Status__c == 'Approved' && Trigger.oldMap.get(booking.Id).NDC_Approval_Status__c != 'Approved') {
                        approvedRecordIds.add(booking.Id);
                        
                    
                    }
                    
                    if(booking.Sale_Agreement_Status__c == 'Approved' && Trigger.oldMap.get(booking.Id).Sale_Agreement_Status__c != 'Approved' ){
                        saleAgreementToEmail.add(booking.Id);
                    }
                    
                    /* Case 1: Stage changed from Reservation → Agreement and status is Approved
if (Trigger.oldMap.get(booking.Id).Stage__c == 'Reservation' && booking.Stage__c == 'Agreement' && booking.Sale_Agreement_Status__c == 'Approved'){
saleAgreementToEmail.add(booking);
}

// Case 2: Already in Agreement, status changed from not Approved → Approved
else if (booking.Stage__c == 'Agreement' && Trigger.oldMap.get(booking.Id).Sale_Agreement_Status__c != 'Approved' && booking.Sale_Agreement_Status__c == 'Approved'){
saleAgreementToEmail.add(booking);
}*/
                    
                    if(booking.Swap_Unit_Status__c != Trigger.oldmap.get(booking.Id).Swap_Unit_Status__c && booking.Swap_Unit_Status__c == 'Approved'){
                        set<String> userIds = new set<String>();
                        string Body = 'Swapping for '+booking.Name+' has been approved';
                        userIds.add(booking.OwnerId);
                        BookingController.sendCustomNotification(userIds,'Swapping Unit',Body,booking.Id,'Booking_Notification');
                        BookingController.cloneBookingWithUnitChangeDetails(booking,'Booking Approved',Trigger.oldmap.get(booking.Id).Stage__c);
                    }
                    if (booking.Stage__c == 'Registration' && booking.Plot__c != null) {
                        Plot__c plot = [SELECT Id, Status__c FROM Plot__c WHERE Id = :booking.Plot__c LIMIT 1];
                        plot.Status__c = 'Sold';
                        plotsToUpdate.add(plot);
                    }
                    if(booking.Stage__c !=trigger.oldmap.get(booking.Id).Stage__c && booking.Stage__c =='Cancellation' && booking.Swap_Unit_Status__c != 'Approved'){
                        // Capture cancelled date if empty - added by karthik 29-07
                        if (booking.Booking_Cancelled_Date__c == null) {
                            updates.add(new Booking__c(Id = booking.Id,Booking_Cancelled_Date__c = System.now()));      
                        }
                        
                        set<String> userIds = new set<String>();
                        string Body = 'Booking Cancelled is Approved';
                        userIds.add(booking.Finance_User__c);
                        userIds.add(booking.OwnerId);
                        BookingController.sendCustomNotification(userIds,'Booking Cancellation',Body,booking.Id,'Booking_Notification'); 
                        plotIds.add(booking.Plot__c);
                    }
                    // Collect bookings for sending email only when cancellation is approved
                    if (booking.Cancellation_Status__c == 'Approved' &&
                        trigger.oldMap.get(booking.Id).Cancellation_Status__c != 'Approved') {
                            
                            cancelledBookingIds.add(booking.Id);
                        }
                    
                    
                }
                if (!plotsToUpdate.isEmpty()) {
                    update plotsToUpdate;
                }
                if (!plotIds.isEmpty()) {
                    List <Plot__c> plotlist = [SELECT Id, Status__c FROM Plot__c WHERE Id  IN: plotIds];
                    for(Plot__c pt : plotlist){
                        pt.Status__c = 'Available';
                    }
                    update plotlist;
                    
                }
                if (!bookingsForStatusUpdate.isEmpty()) {
                    update bookingsForStatusUpdate;
                }
                
                //Send email
                if (!saleAgreementToEmail.isEmpty()) {
                    //BookingTriggerHelper.sendAgreementApprovalEmailToCustomer(saleAgreementToEmail);
                    System.enqueueJob(new SendSaleAgreementEmailQueueable(new List<Id>(saleAgreementToEmail)));
                    // Send Sale Agreement WhatsApp (parallel to email)
                    WhatsAppTemplates.sendTemplateForBookings('Sale_Agreement_WhatsApp', new List<Id>(saleAgreementToEmail));
                }
                
                
                
                //added by karthik 17/06
                if (!updates.isEmpty()) {
                    update updates;
                }
                
                if (!toNotifyReg.isEmpty()) {
                    BookingTriggerHelper.sendRegReminderEmails(toNotifyReg);
                }
                
                // Process all approved records
                if (!approvedRecordIds.isEmpty()) {
                    //GenerateDocumnetController.sendEmailNDCAndPossession(approvedRecordIds,'');
                    GenerateDocumnetController.sendApprovalEmailsFuture(approvedRecordIds); 
                }
                
                //sending cancellation agreement emails
                if (!cancelledBookingIds.isEmpty()) {
                    GenerateDocumnetController.sendCancellationEmailsFuture(cancelledBookingIds);
                }
                
            }
        }
    }
}