({
    checkApprovalStatus: function(component) {
        var action = component.get("c.getApprovalStatus");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            if (response.getState() === 'SUCCESS') {
                var result = response.getReturnValue();
                //component.set("v.approvalStatus", status);
                component.set("v.isApprovalSubmitted",result);
            }
        });
        $A.enqueueAction(action);
    },
    
    handleSuccess: function(component, event, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "success",
            "title": "Success",
            "message": message,
            "duration": 10000
        });
        toastEvent.fire();
        
        $A.get('e.force:refreshView').fire();
        
        // Close the modal after delay
        setTimeout(function() {
            event.stopPropagation();
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
        }, 1500);
    },
    
    handleError: function(error) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "error",
            "title": "Error",
            "message": typeof error === 'string' ? error : 
                     (error[0] && error[0].message) || 'Unknown error',
            "duration": 10000
        });
        toastEvent.fire();
    }
})