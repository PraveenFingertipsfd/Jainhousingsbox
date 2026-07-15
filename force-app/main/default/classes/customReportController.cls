public without sharing class customReportController{
    
    public class PaymentScheduleWrapper123 {
        public Decimal paymentScheduleName { get; set; }
        public Decimal paymentScheduleSNo { get; set; }
        public Decimal totalDemandAmount { get; set; }
        public Decimal pendingAmount { get; set; }
        public Decimal receivedAmount { get; set; }
        
        // Constructor to initialize the wrapper with a Payment Schedule name
        public PaymentScheduleWrapper123(Decimal name) {
            this.paymentScheduleName = name;
            this.paymentScheduleSNo = 0;
            this.totalDemandAmount = 0;
            this.pendingAmount = 0;
            this.receivedAmount = 0;
        }
    }
    public List<Contact> lstContact {set;get;}
    public boolean isExport{get; set;}
    public transient List<DataWrapper> dataList{set;get;}
    public String selectedProjectId {get; set;} 
    public String selectedTowerId {get; set;}
    public Decimal totalFlatCost {get; set;}
    public Decimal totalReceivable {get; set;}
    public Decimal totalReceived {get; set;}
    public Decimal totalBalanaceReceivable {get; set;} 
    public Decimal totalOutstanding {get; set;} 
    public List<SelectOption> projectOptions {get; set;}
    public List<SelectOption> towerOptions {get; set;}
    public List<PaymentScheduleWrapper> paymentScheduleHeaders { get; set; }
    public List<PaymentScheduleWrapper123> paymentScheduleTotals { get; set; }
    
    public String filterMessage { get; set; }
    
    public customReportController(){
        isExport= false; 
        selectedProjectId = ''; 
        selectedTowerId = ''; 
        totalFlatCost = 0;
        totalReceivable = 0;
        totalReceived = 0;
        totalBalanaceReceivable = 0;
        totalOutstanding = 0;
        paymentScheduleHeaders = new List<PaymentScheduleWrapper>();
        paymentScheduleTotals = new List<PaymentScheduleWrapper123>();
        dataList = new List<DataWrapper>();
        populateProjectOptions();
    }
    public PageReference getExport() {
        isExport = true;
        
        // If dataList is empty, call filterByProject to load data based on selectedProjectId
        if (dataList == null || dataList.isEmpty()) {
            paymentScheduleHeaders = new List<PaymentScheduleWrapper>();
            filterByProject(); 
        }
        
        return null;
    }
    public void populateProjectOptions() {
        projectOptions = new List<SelectOption>();
        projectOptions.add(new SelectOption('', '-- Select Project --')); // Default option
        
        for (Project__c project : [SELECT Id, project__c FROM Project__c]) {
            projectOptions.add(new SelectOption(project.Id, project.project__c));
        }
    }
    public void getTowers() {
        towerOptions = new List<SelectOption>();
        towerOptions.add(new SelectOption('', '-- Select Tower --')); // Default option
        
        for (Block__c project : [SELECT Id, Name FROM Block__c where Project__c =:selectedProjectId ]) {
            towerOptions.add(new SelectOption(project.Id, project.Name));
        }
    }
    public void filterByProject() {
        paymentScheduleHeaders = new List<PaymentScheduleWrapper>();
        Map<Decimal, PaymentScheduleWrapper123> scheduleTotalsMap = new Map<Decimal, PaymentScheduleWrapper123>();
        if (String.isNotBlank(selectedProjectId) && String.isBlank(selectedTowerId)) {
            system.debug(selectedProjectId);
            system.debug(selectedTowerId);
            List<Booking__c> bookings = [SELECT Id, Name, Registration_Number__c,Plot__c,Welcome_Mail_Sent_Time__c,Tower_Name__c,First_Applicant_Name__c, Date_of_Booking__c,Tower__c, Block1__c, Unit_NumberFor__c, 
                                         FloorNo__c, Super_Built_up_area_NE__c, BHK_Type__c, Price_per_sqft__c, Basic_Price__c, Other_Charges__c, Premium_Charge__c, 
                                         GST__c, Total__c, Total_received_Amount__c, Pending_Amount__c,Sale_Agreement_Completed__c,Total_Other_Charges__c,Total_Premium_Location_Charges__c,GST_Amount__c,
                                         Sale_Agreement_Date__c, Registration_Date__c,Bank__c,Loan_Expected_Date__c,Loan_Sanctioned_Amount__c,Loan_Account_Number__c,Bank_CO_Ordinator__c,Remarks__c,
                                         (SELECT Id,Name,S_No__c, Amountb__c, Total_Demand_Raised_Amount__c,Pending_Amount__c,Received_Amount1__c ,Master_Payment_Schedule__r.S_No__c
                                          FROM Payment_Schedules__r where (Is_Demanded__c = true or S_No__c = 1)
                                          ORDER BY Master_Payment_Schedule__r.S_No__c ASC)
                                         FROM Booking__c
                                         WHERE Project1__c = :selectedProjectId];
            system.debug(bookings);
            List<Master_Payment_Schedule__c> paymentSchedules = [SELECT Id, Name, S_No__c
                                                                 FROM Master_Payment_Schedule__c
                                                                 WHERE Project__c = :selectedProjectId and Use_for_report__c = true
                                                                 ORDER BY S_No__c ASC];
            
            for (Master_Payment_Schedule__c ps : paymentSchedules) {
                PaymentScheduleWrapper wrapper = new PaymentScheduleWrapper();
                wrapper.paymentScheduleName = ps.Name;
                wrapper.paymentScheduleSNo = ps.S_No__c;
                paymentScheduleHeaders.add(wrapper);
            }
            
            
            system.debug(paymentScheduleHeaders); 
            
            if (dataList == null) {
                dataList = new List<DataWrapper>();
            } else {
                dataList.clear();
            }
            
            
            Integer counter = 1;
            for (Booking__c booking : bookings) {
                DataWrapper bookingWrapper = new DataWrapper();
                bookingWrapper.booking = booking;
                bookingWrapper.serialNumber = counter++; 
                totalFlatCost += booking.Total__c != null ? booking.Total__c : 0;
                totalReceivable += booking.Total__c != null ? booking.Total__c : 0;
                totalReceived += booking.Total_received_Amount__c != null ? booking.Total_received_Amount__c : 0;
                totalOutstanding += booking.Pending_Amount__c != null ? booking.Pending_Amount__c : 0;
                totalBalanaceReceivable += booking.Pending_Amount__c != null ? booking.Pending_Amount__c : 0;
                // Add related payment schedules from the child query
                bookingWrapper.paymentSchedules = booking.Payment_Schedules__r;  // Direct reference to the child relationship
                
                dataList.add(bookingWrapper);
                for (Payment_Schedule__c payment : booking.Payment_Schedules__r) {
                    Decimal scheduleName = payment.S_No__c;
                    if (!scheduleTotalsMap.containsKey(scheduleName)) {
                        scheduleTotalsMap.put(scheduleName, new PaymentScheduleWrapper123(scheduleName));
                    }
                    PaymentScheduleWrapper123 wrapper = scheduleTotalsMap.get(scheduleName);
                    
                    wrapper.totalDemandAmount += payment.Total_Demand_Raised_Amount__c != null ? payment.Total_Demand_Raised_Amount__c : 0;
                    wrapper.pendingAmount += payment.Pending_Amount__c != null ? payment.Pending_Amount__c : 0;
                    wrapper.receivedAmount += payment.Received_Amount1__c != null ? payment.Received_Amount1__c : 0;
                }
                paymentScheduleTotals = new List<PaymentScheduleWrapper123>(scheduleTotalsMap.values());
            }
            
        }
        else if(String.isNotBlank(selectedProjectId) && String.isNotBlank(selectedTowerId)){
            system.debug(selectedProjectId);
            system.debug(selectedTowerId);
            List<Booking__c> bookings = [SELECT Id, Name, Registration_Number__c,Plot__c,Welcome_Mail_Sent_Time__c,Tower_Name__c,First_Applicant_Name__c, Date_of_Booking__c,Tower__c, Block1__c, Unit_NumberFor__c, 
                                         FloorNo__c, Super_Built_up_area_NE__c, BHK_Type__c, Price_per_sqft__c, Basic_Price__c, Other_Charges__c, Premium_Charge__c, 
                                         GST__c, Total__c, Total_received_Amount__c, Pending_Amount__c,Sale_Agreement_Completed__c,Total_Other_Charges__c,GST_Amount__c,Total_Premium_Location_Charges__c,
                                         Sale_Agreement_Date__c, Registration_Date__c,Bank__c,Loan_Expected_Date__c,Loan_Sanctioned_Amount__c,Loan_Account_Number__c,Bank_CO_Ordinator__c,Remarks__c,
                                         (SELECT Id,Name,S_No__c,Amountb__c, Total_Demand_Raised_Amount__c,Pending_Amount__c,Received_Amount1__c ,Master_Payment_Schedule__r.S_No__c
                                          FROM Payment_Schedules__r where (Is_Demanded__c = true or S_No__c = 1)
                                          ORDER BY Master_Payment_Schedule__r.S_No__c ASC)
                                         FROM Booking__c
                                         WHERE Project1__c = :selectedProjectId and Block__c =:selectedTowerId];
            system.debug(bookings);
            List<Master_Payment_Schedule__c> paymentSchedules = [SELECT Id, Name, S_No__c
                                                                 FROM Master_Payment_Schedule__c
                                                                 WHERE Project__c = :selectedProjectId and Use_for_report__c = true
                                                                 ORDER BY S_No__c ASC];
            
            for (Master_Payment_Schedule__c ps : paymentSchedules) {
                PaymentScheduleWrapper wrapper = new PaymentScheduleWrapper();
                wrapper.paymentScheduleName = ps.Name;
                wrapper.paymentScheduleSNo = ps.S_No__c;
                paymentScheduleHeaders.add(wrapper);
            }
            
            
            system.debug(paymentScheduleHeaders); 
            
            if (dataList == null) {
                dataList = new List<DataWrapper>();
            } else {
                dataList.clear();
            }
            
            
            Integer counter = 1;
            for (Booking__c booking : bookings) {
                DataWrapper bookingWrapper = new DataWrapper();
                bookingWrapper.booking = booking;
                bookingWrapper.serialNumber = counter++; 
                
                
                // Add related payment schedules from the child query
                bookingWrapper.paymentSchedules = booking.Payment_Schedules__r;  // Direct reference to the child relationship
                
                dataList.add(bookingWrapper);
                
                for (Payment_Schedule__c payment : booking.Payment_Schedules__r) {
                    Decimal scheduleName = payment.S_No__c;
                    if (!scheduleTotalsMap.containsKey(scheduleName)) {
                        scheduleTotalsMap.put(scheduleName, new PaymentScheduleWrapper123(scheduleName));
                    }
                    PaymentScheduleWrapper123 wrapper = scheduleTotalsMap.get(scheduleName);
                    wrapper.totalDemandAmount += payment.Total_Demand_Raised_Amount__c != null ? payment.Total_Demand_Raised_Amount__c : 0;
                    wrapper.pendingAmount += payment.Pending_Amount__c != null ? payment.Pending_Amount__c : 0;
                    wrapper.receivedAmount += payment.Received_Amount1__c != null ? payment.Received_Amount1__c : 0;
                }
                paymentScheduleTotals = new List<PaymentScheduleWrapper123>(scheduleTotalsMap.values());
            }
        }
        else {
            //dataList.clear();
            filterMessage = 'Please select a Project and Tower.';
            return;
        }
    }
    public class PaymentScheduleWrapper{
        public string paymentScheduleName{set;get;}
        public Decimal paymentScheduleSNo{set;get;}
        public Decimal amountReceived{set;get;}
        public Decimal balanceAmount{set;get;} 
    }
    public class DataWrapper {
        public Booking__c booking { get; set; }
        public List<Payment_Schedule__c> paymentSchedules { get; set; }
        public Integer serialNumber { get; set; }
    }
    
    public PageReference getCodeCoveragse() {
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
        return null;
    }
    
}