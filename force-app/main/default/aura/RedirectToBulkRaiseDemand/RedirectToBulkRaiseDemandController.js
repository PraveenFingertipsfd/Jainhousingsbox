({
    doInit: function (component, event, helper) {
        var action=component.get("c.getBlocks");  
        action.setParams({'recId':  component.get('v.recordId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var plots = response.getReturnValue();
                component.set("v.plots",plots);
                
                var evt = $A.get("e.force:navigateToComponent");
                evt.setParams({
                    componentDef : "c:BulkRaiseDemand", 
                    componentAttributes: {
                        recordId : component.get("v.recordId"),
                        sObjectName : component.get("v.sObjectName"),
                        isStandard : true
                    }
                });
                evt.fire();
                
            }
        });
        $A.enqueueAction(action);
        
    },
	selectStandCus : function(component, event, helper) {
        var standCusType = component.get('v.standCustType');
        if(standCusType == 'Tower'){
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
                componentDef : "c:BulkRaiseDemand", 
                componentAttributes: {
                    recordId : component.get("v.recordId"),
                    sObjectName : component.get("v.sObjectName"),
                    isStandard : true
                }
            });
            evt.fire();
        }
        if(standCusType == 'Project'){
            var action = component.get("c.getBookingRecordsWithProject");
            action.setParams({ "masterPaymentScheduleId": component.get('v.recordId')});
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.bookingRecords", response.getReturnValue());
                    var evt = $A.get("e.force:navigateToComponent");
                    evt.setParams({
                        componentDef : "c:BulkRaiseDemand", 
                        componentAttributes: {
                            recordId : component.get("v.recordId"),
                            sObjectName : component.get("v.sObjectName"),
                            isStandard : true,
                            bookingRecords : component.get("v.bookingRecords")
                        }
                    });
                    evt.fire();
                } else {
                    console.error("Error fetching Booking records");
                }
            });
            
            $A.enqueueAction(action);
        }
    }

})