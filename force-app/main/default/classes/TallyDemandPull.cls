@RestResource(urlMapping='/api/demands')
global with sharing class TallyDemandPull {

    @HttpGet
    global static List<TallyIntegration.BookingWrapper> getDemands() {
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
                                                                (select id,Name,Current_Milestone__c,Milestone_Number__c,Milestone_Completed_Date__c,Demanded_Date__c,Due_Date__c,
                                                                 Current_Milestone_Percentage__c,Total_Percentage_till_Current_Milestone__c,Payment_schedule__c,Payment_schedule__r.Name,
                                                                 Current_Demand_amount__c,Total_Paid_Till__c,Total_Flat_Cost__c,Total_Amount_till_Current_Milestone__c,
                                                                 Previous_pendings__c,Grand_Total__c,Grand_Total_In_Words__c from Demand_Raised__r)
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
                    // Advance-payment-only stage: no demands yet (mirrors original gating)
                }
                else {
                    if (BookingRec.containsKey(b.Booking__c)) {
                        Booking__c bkrec = BookingRec.get(b.Booking__c);

                        wrapper.BookingRequest.Demands = new List<TallyIntegration.DemandResponse>();
                        for (Demand_Raised__c d : bkrec.Demand_Raised__r) {
                            TallyIntegration.DemandResponse dr = new TallyIntegration.DemandResponse();
                            dr.demandId       = d.Id;
                            dr.demandName     = d.Name;
                            dr.currentMilestone = d.Current_Milestone__c;
                            dr.milestoneNumber = d.Milestone_Number__c;
                            dr.milestoneCompletedDate = d.Milestone_Completed_Date__c;
                            dr.demandedDate   = d.Demanded_Date__c!=null ? d.Demanded_Date__c.date(): null;
                            dr.dueDate        = d.Due_Date__c != null? d.Due_Date__c.date() : null;
                            dr.currentMilestonePercentage = d.Current_Milestone_Percentage__c;
                            dr.totalPercentageTillCurrentMilestone = d.Total_Percentage_till_Current_Milestone__c;
                            dr.paymentScheduleId = d.Payment_schedule__c;
                            dr.paymentScheduleName = d.Payment_schedule__r != null ? d.Payment_schedule__r.Name : null;
                            dr.currentDemandAmount = d.Current_Demand_amount__c;
                            dr.totalPaidTill   = d.Total_Paid_Till__c;
                            dr.totalFlatCost   = d.Total_Flat_Cost__c;
                            dr.totalAmountTillCurrentMilestone = d.Total_Amount_till_Current_Milestone__c;
                            dr.previousPendings= d.Previous_pendings__c;
                            dr.grandTotal      = d.Grand_Total__c;
                            dr.grandTotalInWords = d.Grand_Total_In_Words__c;
                            wrapper.BookingRequest.Demands.add(dr);
                        }
                    }
                }
            }

            responseList.add(wrapper);
        }

        return responseList;
    }
}