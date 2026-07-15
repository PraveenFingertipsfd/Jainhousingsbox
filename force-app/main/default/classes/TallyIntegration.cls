@RestResource(urlMapping='/api/bookings')
global with sharing class TallyIntegration {

    @HttpGet
    global static List<BookingWrapper> getBookings() {
        RestRequest req = RestContext.request;
        Map<String, String> params = req.params;

        // Filters
        String projectName = params.get('project');
        String towerName   = params.get('tower');
        String unitName    = params.get('unit');

        if (projectName != null && projectName == 'null') { projectName = ''; }
        if (towerName != null && towerName == 'null')     { towerName = ''; }
        if (unitName != null && unitName == 'null')       { unitName = ''; }

        Date startDate = params.containsKey('startDate') ? Date.valueOf(params.get('startDate')) : null;
        Date endDate   = params.containsKey('endDate') ? Date.valueOf(params.get('endDate')) : null;

        // Pagination
        Integer limitSize  = params.containsKey('limit') ? Integer.valueOf(params.get('limit')) : 100;
        Integer offsetSize = params.containsKey('offset') ? Integer.valueOf(params.get('offset')) : 0;

        String baseQuery = 'SELECT Id, Name, Project__c, Unit__c, Unit__r.Name, Unit__r.Block1__c, Unit__r.Block1__r.Name, ' +
            'Mobile__c, Customer_Name__c, Email__c, PAN_Number__c, Aadhaar_Number__c, ' +
            'Customer_Comments__c, Booking__c, Stage__c, ' +
            'Email_Sent_Date_Time__c, Customer_Responded_Date__c, ' +
            '(SELECT Id, Name, Mode_of_Payment__c, Bank__c, Cheque_no_Transaction_Number__c, Amount__c, Approval_Status__c, Receipt_Date__c ' +
            ' FROM Advance_Payments__r WHERE Approval_Status__c = \'Approved\') ' +
            'FROM Booking_Request__c ' +
            'WHERE Stage__c IN (\'Cost Sheet Preparation\', \'Request Successfully Closed\')';

        List<String> filters = new List<String>();
        if (!String.isBlank(projectName)) filters.add('Project__c = \'' + String.escapeSingleQuotes(projectName) + '\'');
        if (!String.isBlank(towerName))   filters.add('Unit__r.Block1__r.Name = \'' + String.escapeSingleQuotes(towerName) + '\'');
        if (!String.isBlank(unitName))    filters.add('Unit__r.Name = \'' + String.escapeSingleQuotes(unitName) + '\'');

        if (!filters.isEmpty()) {
            baseQuery += ' AND ' + String.join(filters, ' AND ');
        }

        baseQuery += ' ORDER BY Customer_Responded_Date__c DESC LIMIT ' + limitSize + ' OFFSET ' + offsetSize;

        List<Booking_Request__c> bookingReqs = Database.query(baseQuery);

        Set<Id> BkrqIds = new Set<Id>();
        for (Booking_Request__c brq : bookingReqs) {
            BkrqIds.add(brq.Id);
        }

        Map<Id,Booking__c> BookingRec = new Map<Id,Booking__c>([select id,name,Stage__c,Booking_Date__c,OwnerId,Owner.Name,Project1__c,Project1__r.Name,Total__c,
                                                                Total_received_Amount__c,Pending_Amount__c,Plot__c,Plot__r.Name,Tower_Name__c,Project__c,FloorNo__c,
                                                                Flat_Actual_Number__c,Unit_BHK_Type__c,Carpet_Area__c,Balcony_Area__c,Unit_UDS_Area__c,Proportionate_Common_Area__c,
                                                                Super_Built_up_area_NE__c,Open_Terrace_Area__c,salutation_Applicant1__c,First_Applicant_Name__c,Gender__c,
                                                                Date_of_Birth1__c,Relation_Details_Applicant1__c,Son_Daughter_Wife_of1__c,Aadhaar_Number1__c,PAN_Number1__c,
                                                                Nationality__c,Passport_Aadhar_1__c,Marital_Status__c,Anniverssary_Date__c,Mobile_Primary1__c,Mobile_Alternate1__c,
                                                                Email1__c,Alternate_Email1__c,Profession1__c,Other_Profession1__c,Name_of_Company1__c,Designation1__c,Company_Address__c,
                                                                Communication_address1__c,Permanent_Address1__c,Funding_Type__c,Applied_to_any_Bank__c,Bank__c,Welcome_Call_Date__c,
                                                                Sale_Agreement_Date__c,Registration_Date__c,Cancellation_Charges__c,Cancellation_Status__c,Finance_User__c,Finance_User__r.Name,
                                                                CRM_Manager__c,CRM_Manager__r.Name,Sales_Manager1__c,Sales_Manager1__r.Name,
                                                                (select id,name,Salutation__c,Gender__c,Date_of_Birth__c,Relalation_Details__c,W_o_S_o_C_o_c__c,Aadhar_Number__c,PAN_Number__c,
                                                                 Country__c,Passport_Aadhar_number__c,Marital_Status__c,Anniverssary_Date__c,Contact_Number__c,Alternate_Mobile__c,Email__c,
                                                                 Alternate_Email__c,Occupation__c,Other_Profession__c,Name_of_Company__c,Designation__c,Company_Address__c,Address__c,
                                                                 Permenent_Address__c from Co_Applicant__r)
                                                                from Booking__c where Cost_Sheet__c != null and Cost_Sheet__r.Booking_Request__c in: BkrqIds]);

        List<BookingWrapper> responseList = new List<BookingWrapper>();
        for (Booking_Request__c b : bookingReqs) {

            BookingWrapper wrapper = new BookingWrapper();
            wrapper.BookingRequest = new BookingReqResponse();
            wrapper.BookingRequest.bookingReqId   = b.Id;
            wrapper.BookingRequest.bookingReqName = b.Name;
            wrapper.BookingRequest.project        = b.Project__c;
            wrapper.BookingRequest.tower          = b.Unit__r.Block1__c != null ? b.Unit__r.Block1__r.Name : null;
            wrapper.BookingRequest.unit           = b.Unit__c != null ? b.Unit__r.Name : null;
            wrapper.BookingRequest.customer       = b.Customer_Name__c;
            wrapper.BookingRequest.mobile         = b.Mobile__c;
            wrapper.BookingRequest.email          = b.Email__c;
            wrapper.BookingRequest.aadharNumber   = b.Aadhaar_Number__c;
            wrapper.BookingRequest.panNumber      = b.PAN_Number__c;
            wrapper.BookingRequest.customerRemarks= b.Customer_Comments__c;
            wrapper.BookingRequest.bookingDate    = b.Customer_Responded_Date__c!=null ? b.Customer_Responded_Date__c.date(): null;

            if (b.Booking__c != null) {
                if (b.Stage__c == 'Cost Sheet Preparation' && !b.Advance_Payments__r.Isempty()) {
                    // Advance-payment-only stage: no Booking detail yet (mirrors original gating)
                }
                else {
                    if (BookingRec.containsKey(b.Booking__c)) {

                        Booking__c bkrec = BookingRec.get(b.Booking__c);

                        BookingResponse br = new BookingResponse();
                        br.bookingId      = bkrec.Id;
                        br.bookingName    = bkrec.Name;
                        br.stage          = bkrec.Stage__c;
                        br.bookingDate    = bkrec.Booking_Date__c;
                        br.ownerId        = bkrec.OwnerId;
                        br.ownerName      = bkrec.Owner != null ? bkrec.Owner.Name : null;
                        br.projectId      = bkrec.Project1__c;
                        br.projectName    = bkrec.Project1__r != null ? bkrec.Project1__r.Name : null;
                        br.totalAmount    = bkrec.Total__c;
                        br.totalReceivedAmount = bkrec.Total_received_Amount__c;
                        br.pendingAmount  = bkrec.Pending_Amount__c;
                        br.plotId         = bkrec.Plot__c;
                        br.plotName       = bkrec.Plot__r != null ? bkrec.Plot__r.Name : null;
                        br.towerName      = bkrec.Tower_Name__c;
                        br.projectCode    = bkrec.Project__c;
                        br.floorNo        = bkrec.FloorNo__c;
                        br.flatActualNumber = bkrec.Flat_Actual_Number__c;
                        br.unitBhkType    = bkrec.Unit_BHK_Type__c;
                        br.carpetArea     = bkrec.Carpet_Area__c;
                        br.balconyArea    = bkrec.Balcony_Area__c;
                        br.udsArea        = bkrec.Unit_UDS_Area__c;
                        br.proportionateCommonArea = bkrec.Proportionate_Common_Area__c;
                        br.superBuiltUpArea = bkrec.Super_Built_up_area_NE__c;
                        br.openTerraceArea = bkrec.Open_Terrace_Area__c;

                        // Primary applicant fields
                        br.salutationApplicant1 = bkrec.salutation_Applicant1__c;
                        br.firstApplicantName   = bkrec.First_Applicant_Name__c;
                        br.genderApplicant1     = bkrec.Gender__c;
                        br.dobApplicant1        = bkrec.Date_of_Birth1__c;
                        br.relationDetailsApplicant1 = bkrec.Relation_Details_Applicant1__c;
                        br.sonDaughterWifeOf1   = bkrec.Son_Daughter_Wife_of1__c;
                        br.aadhaarApplicant1    = bkrec.Aadhaar_Number1__c;
                        br.panApplicant1        = bkrec.PAN_Number1__c;
                        br.nationalityApplicant1 = bkrec.Nationality__c;
                        br.passportAadharApplicant1 = bkrec.Passport_Aadhar_1__c;
                        br.maritalStatusApplicant1 = bkrec.Marital_Status__c;
                        br.anniversaryDateApplicant1 = bkrec.Anniverssary_Date__c;
                        br.mobilePrimary1       = bkrec.Mobile_Primary1__c;
                        br.mobileAlternate1     = bkrec.Mobile_Alternate1__c;
                        br.email1               = bkrec.Email1__c;
                        br.alternateEmail1      = bkrec.Alternate_Email1__c;
                        br.profession1          = bkrec.Profession1__c;
                        br.otherProfession1     = bkrec.Other_Profession1__c;
                        br.companyName1         = bkrec.Name_of_Company1__c;
                        br.designation1         = bkrec.Designation1__c;
                        br.companyAddress1      = bkrec.Company_Address__c;
                        br.communicationAddress1 = bkrec.Communication_address1__c;
                        br.permanentAddress1    = bkrec.Permanent_Address1__c;

                        // Finance/Booking info
                        br.fundingType          = bkrec.Funding_Type__c;
                        br.appliedToAnyBank     = bkrec.Applied_to_any_Bank__c;
                        br.bank                 = bkrec.Bank__c;
                        br.welcomeCallDate      = bkrec.Welcome_Call_Date__c != null ? bkrec.Welcome_Call_Date__c.date(): null;
                        br.saleAgreementDate    = bkrec.Sale_Agreement_Date__c;
                        br.registrationDate     = bkrec.Registration_Date__c;
                        br.cancellationCharges  = bkrec.Cancellation_Charges__c;
                        br.cancellationStatus   = bkrec.Cancellation_Status__c;

                        // Users
                        br.financeUserId        = bkrec.Finance_User__c;
                        br.financeUserName      = bkrec.Finance_User__r != null ? bkrec.Finance_User__r.Name : null;
                        br.crmManagerId         = bkrec.CRM_Manager__c;
                        br.crmManagerName       = bkrec.CRM_Manager__r != null ? bkrec.CRM_Manager__r.Name : null;
                        br.salesManager1Id      = bkrec.Sales_Manager1__c;
                        br.salesManager1Name    = bkrec.Sales_Manager1__r != null ? bkrec.Sales_Manager1__r.Name : null;
                        wrapper.BookingRequest.Bookings = br;

                        // Co-Applicants
                        wrapper.BookingRequest.CoApplicants = new List<CoApplicantResponse>();
                        for (Co_Applicant__c c : bkrec.Co_Applicant__r) {
                            CoApplicantResponse ca = new CoApplicantResponse();
                            ca.coApplicantId    = c.Id;
                            ca.coApplicantName  = c.Name;
                            ca.salutation       = c.Salutation__c;
                            ca.gender           = c.Gender__c;
                            ca.dob              = c.Date_of_Birth__c;
                            ca.relationDetails  = c.Relalation_Details__c;
                            ca.woSoCo           = c.W_o_S_o_C_o_c__c;
                            ca.aadhaarNumber    = c.Aadhar_Number__c;
                            ca.panNumber        = c.PAN_Number__c;
                            ca.country          = c.Country__c;
                            ca.passportAadhar   = c.Passport_Aadhar_number__c;
                            ca.maritalStatus    = c.Marital_Status__c;
                            ca.anniversaryDate  = c.Anniverssary_Date__c;
                            ca.contactNumber    = c.Contact_Number__c;
                            ca.alternateMobile  = c.Alternate_Mobile__c;
                            ca.email            = c.Email__c;
                            ca.alternateEmail   = c.Alternate_Email__c;
                            ca.occupation       = c.Occupation__c;
                            ca.otherProfession  = c.Other_Profession__c;
                            ca.companyName      = c.Name_of_Company__c;
                            ca.designation      = c.Designation__c;
                            ca.companyAddress   = c.Company_Address__c;
                            ca.communicationAddress = c.Address__c;
                            ca.permanentAddress = c.Permenent_Address__c;
                            wrapper.BookingRequest.CoApplicants.add(ca);
                        }
                    }
                }
            }

            responseList.add(wrapper);
        }

        return responseList;
    }

    // --- Wrappers (shared across all Tally pull endpoints) ---
    global class BookingWrapper {
        public BookingReqResponse BookingRequest;
    }

    global class BookingReqResponse {
        public Id bookingReqId;
        public String bookingReqName;
        public String project;
        public String tower;
        public String unit;
        public String customer;
        public String mobile;
        public String email;
        public String aadharNumber;
        public String panNumber;
        public String customerRemarks;
        public Date bookingDate;
        public BookingResponse Bookings;
        public List<CoApplicantResponse> CoApplicants;
        public List<ReceiptResponse> Receipts;
        public List<AdditionalChargeResponse> AdditionalCharges;
        public List<DemandResponse> Demands;
        public List<PaymentScheduleResponse> Schedules;
    }

    global class BookingResponse {
        public Id bookingId;
        public String bookingName;
        public String stage;
        public Date bookingDate;
        public Id ownerId;
        public String ownerName;
        public Id projectId;
        public String projectName;
        public Decimal totalAmount;
        public Decimal totalReceivedAmount;
        public Decimal pendingAmount;
        public Id plotId;
        public String plotName;
        public String towerName;
        public String projectCode; // Project__c
        public String floorNo;
        public String flatActualNumber;
        public String unitBhkType;
        public Decimal carpetArea;
        public Decimal balconyArea;
        public Decimal udsArea;
        public Decimal proportionateCommonArea;
        public Decimal superBuiltUpArea;
        public Decimal openTerraceArea;

        // Primary Applicant fields
        public String salutationApplicant1;
        public String firstApplicantName;
        public String genderApplicant1;
        public Date dobApplicant1;
        public String relationDetailsApplicant1;
        public String sonDaughterWifeOf1;
        public String aadhaarApplicant1;
        public String panApplicant1;
        public String nationalityApplicant1;
        public String passportAadharApplicant1;
        public String maritalStatusApplicant1;
        public Date anniversaryDateApplicant1;
        public String mobilePrimary1;
        public String mobileAlternate1;
        public String email1;
        public String alternateEmail1;
        public String profession1;
        public String otherProfession1;
        public String companyName1;
        public String designation1;
        public String companyAddress1;
        public String communicationAddress1;
        public String permanentAddress1;

        // Booking / Finance Info
        public String fundingType;
        public String appliedToAnyBank;
        public String bank;
        public Date welcomeCallDate;
        public Date saleAgreementDate;
        public Date registrationDate;
        public Decimal cancellationCharges;
        public String cancellationStatus;

        // Users
        public Id financeUserId;
        public String financeUserName;
        public Id crmManagerId;
        public String crmManagerName;
        public Id salesManager1Id;
        public String salesManager1Name;
    }

    global class CoApplicantResponse {
        public Id coApplicantId;
        public String coApplicantName;
        public String salutation;
        public String gender;
        public Date dob;
        public String relationDetails;
        public String woSoCo;
        public String aadhaarNumber;
        public String panNumber;
        public String country;
        public String passportAadhar;
        public String maritalStatus;
        public Date anniversaryDate;
        public String contactNumber;
        public String alternateMobile;
        public String email;
        public String alternateEmail;
        public String occupation;
        public String otherProfession;
        public String companyName;
        public String designation;
        public String companyAddress;
        public String communicationAddress;
        public String permanentAddress;
    }

    global class ReceiptResponse {
        public Id receiptId;
        public String receiptName;
        public String receiptStatus;
        public Date receiptDate;
        public Decimal receiptAmount;
        public String receiptRemark;
        public String receiptPaymentFrom;
        public String receiptMOP;
        public String receiptChequeTransactionNo;
        public String receiptPaymmentReceivedBank;
    }

    global class PaymentScheduleResponse {
        public String scheduleId;
        public String scheduleName;
        public Decimal scheduleNo;
        public Date paymentDueDate;
        public Decimal paymentPercent;
        public Decimal interestPercent;
        public Decimal totalAmount;
        public Decimal pendingAmount;
    }

    global class DemandResponse {
        public Id demandId;
        public String demandName;
        public String currentMilestone;
        public String milestoneNumber;
        public Date milestoneCompletedDate;
        public Date demandedDate;
        public Date dueDate;
        public Decimal currentMilestonePercentage;
        public Decimal totalPercentageTillCurrentMilestone;
        public Id paymentScheduleId;
        public String paymentScheduleName;
        public Decimal currentDemandAmount;
        public Decimal totalPaidTill;
        public Decimal totalFlatCost;
        public Decimal totalAmountTillCurrentMilestone;
        public Decimal previousPendings;
        public Decimal grandTotal;
        public String grandTotalInWords;
    }

    global class AdditionalChargeResponse {
        public Id additionalChargeId;
        public String additionalChargeName;
        public String approvalStatus;
        public Decimal amount;
        public String statusDynamic;
        public Date demandedDate;
        public Boolean isDemanded;
        public Decimal totalAdditionalCharge;
        public Decimal totalReceivedAmount;
        public String additionalChargeType;
        public Decimal pendingAmount;
        public String description;
    }
}