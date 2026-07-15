({
    handleConfirm : function(component, event, helper) {
        component.set("v.isProcessing", true);
        component.set("v.errorMessage", "");
        
        // Call server-side controller
        var action = component.get("c.abandonCostSheet");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isProcessing", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if (result.isSuccess) {
                    helper.showToast("Success", "Cost Sheet abandoned successfully", "success");
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                } else {
                    component.set("v.errorMessage", result.errorMessage);
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set("v.errorMessage", errors[0].message);
                } else {
                    component.set("v.errorMessage", "An unknown error occurred.");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})