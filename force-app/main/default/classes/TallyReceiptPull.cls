@RestResource(urlMapping='/api/receipts')
global with sharing class TallyReceiptPull {

    @HttpGet
    global static List<TallyIntegration.BookingWrapper> getReceipts() {
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
                                                                (select id,name,Receipt_date__c,Approval_status__c,Payment_Received_Bank__c,Amount_received__c,Total_Received_Amount__c,
                                                                 Amount_By_Customer__c,Interest_Paid_Amount__c,Mode_of_payment__c,Remarks__c,Payment_From__c,Check_Transaction_Nmber__c,Payment_Location__c,
                                                                 Finance_User__c,Finance_User__r.Name from Receipt__r)
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
                    wrapper.BookingRequest.Receipts = new List<TallyIntegration.ReceiptResponse>();
                    for (Advance_Payment__c r : b.Advance_Payments__r) {
                        TallyIntegration.ReceiptResponse rr = new TallyIntegration.ReceiptResponse();
                        rr.receiptId     = r.Id;
                        rr.receiptName   = r.Name;
                        rr.receiptStatus = r.Approval_status__c;
                        rr.receiptDate   = r.Receipt_Date__c;
                        rr.receiptAmount = r.Amount__c;
                        rr.receiptRemark = 'Advance Payment';
                        rr.receiptPaymentFrom = 'Customer';
                        rr.receiptMOP = r.Mode_of_Payment__c;
                        rr.receiptChequeTransactionNo = r.Cheque_no_Transaction_Number__c;
                        rr.receiptPaymmentReceivedBank = r.Bank__c;
                        wrapper.BookingRequest.Receipts.add(rr);
                    }
                }
                else {
                    if (BookingRec.containsKey(b.Booking__c)) {
                        Booking__c bkrec = BookingRec.get(b.Booking__c);

                        wrapper.BookingRequest.Receipts = new List<TallyIntegration.ReceiptResponse>();
                        for (Receipt__c r : bkrec.Receipt__r) {
                            TallyIntegration.ReceiptResponse rr = new TallyIntegration.ReceiptResponse();
                            rr.receiptId     = r.Id;
                            rr.receiptName   = r.Name;
                            rr.receiptStatus = r.Approval_status__c;
                            rr.receiptDate = r.Receipt_date__c != null ? r.Receipt_date__c : null;
                            rr.receiptAmount = r.Amount_received__c;
                            rr.receiptRemark = r.Remarks__c;
                            rr.receiptPaymentFrom = r.Payment_From__c;
                            rr.receiptMOP = r.Mode_of_payment__c;
                            rr.receiptChequeTransactionNo = r.Check_Transaction_Nmber__c;
                            rr.receiptPaymmentReceivedBank = r.Payment_Received_Bank__c;
                            wrapper.BookingRequest.Receipts.add(rr);
                        }
                    }
                }
            }

            responseList.add(wrapper);
        }

        return responseList;
    }
}