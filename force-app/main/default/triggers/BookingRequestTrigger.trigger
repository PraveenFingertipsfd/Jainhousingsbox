trigger BookingRequestTrigger on Booking_Request__c (after update) {
    
    Set<Id> updatedBookingReqIds = new Set<Id>();
    Set<Id> unitIds = new Set<Id>();
    List<Plot__c> toUpdatePlot = new List<Plot__c>();
    for (Booking_Request__c req : Trigger.new) {
        Booking_Request__c oldReq = Trigger.oldMap.get(req.Id);
        if (req.Stage__c != oldReq.Stage__c && (req.Stage__c == 'Request Abandoned' || req.Stage__c == 'Request Successfully Closed')){
            updatedBookingReqIds.add(req.Id);
            if(req.Stage__c == 'Request Abandoned' && (req.Unit__c != null))
                unitIds.add(req.unit__c);
                
        }
        
    }
    if (!unitIds.isEmpty()) {
        for(Id uId : unitIds)
        {
            Plot__c p = new Plot__c();
            p.id = uId;
            p.Status__c = 'Available';
            toUpdatePlot.add(p);
        }
    }
    
    if(!toUpdatePlot.isempty())
        update toUpdatePlot;
    
    if (!updatedBookingReqIds.isEmpty()) {
        BookingRequest_Controller.cancelPendingAdvanceApprovals(updatedBookingReqIds);
    }
}