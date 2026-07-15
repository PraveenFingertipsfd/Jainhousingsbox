({
    doInit: function(component, event, helper) {
        var action = component.get("c.getRecordData"); // Apex method to get the record
        action.setParams({ recordId: component.get("v.recordId") });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var record = response.getReturnValue();
                component.set("v.swapUnitStatus", record.Swap_Unit_Status__c);
            }
        });
        
        $A.enqueueAction(action);
    }
})