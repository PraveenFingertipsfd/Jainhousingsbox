@RestResource(urlMapping='/api/paymentschedules')
global with sharing class TallyPaymentSchedulePull {

    @HttpGet
    global static List<TallyIntegration.BookingWrapper> getPaymentSchedules() {
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

        Map<Id,Booking__c> BookingRec = new Map<Id,Booking__c>([select id,name,
                                                                (select id,name,Master_Payment_Schedule__c,S_No__c,status__c,AmountB__c,Payment_percent__c,Pending_Amount__c,Received_Amount1__c,
                                                                 Interest_Percent__c,Payment_Due_Date__c,Include_Interest__c from Payment_schedules__r)
                                                                from Booking__c where Cost_Sheet__c != null and Cost_Sheet__r.Booking_Request__c in: BkrqIds]);

        List<TallyIntegration.BookingWrapper> responseList = new List<TallyIntegration.BookingWrapper>();
        for (Booking_Request__c b : bookingReqs) {

            TallyIntegration.BookingWrapper wrapper = new TallyIntegration.BookingWrapper();
            wrapper.BookingRequest = new TallyIntegration.BookingReqResponse();
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
                    // Advance-payment-only stage: no schedules yet (mirrors original gating)
                }
                else {
                    if (BookingRec.containsKey(b.Booking__c)) {
                        Booking__c bkrec = BookingRec.get(b.Booking__c);

                        wrapper.BookingRequest.Schedules = new List<TallyIntegration.PaymentScheduleResponse>();
                        for (Payment_schedule__c r : bkrec.Payment_schedules__r) {
                            TallyIntegration.PaymentScheduleResponse rr = new TallyIntegration.PaymentScheduleResponse();
                            rr.scheduleId     = r.Id;
                            rr.scheduleName   = r.Name;
                            rr.scheduleNo = r.S_No__c;
                            rr.paymentDueDate   = r.Payment_Due_Date__c;
                            rr.paymentPercent = r.Payment_percent__c;
                            rr.interestPercent = r.Interest_Percent__c;
                            rr.totalAmount = r.AmountB__c;
                            rr.pendingAmount = r.Pending_Amount__c;
                            wrapper.BookingRequest.Schedules.add(rr);
                        }
                    }
                }
            }

            responseList.add(wrapper);
        }

        return responseList;
    }
}