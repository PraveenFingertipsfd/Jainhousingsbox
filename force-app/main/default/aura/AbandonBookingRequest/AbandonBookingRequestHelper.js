({
    closeModal: function(component) {
        component.set("v.showModal", false);
        $A.get("e.force:closeQuickAction").fire();
    },
    
    abandonBookingRequest: function(component) {
        component.set("v.isProcessing", true);
        component.set("v.errorMessage", "");
        
        let recordId = component.get("v.recordId");
        
        let action = component.get("c.abandonBookingRequest");
        action.setParams({
            "bookingRequestId": recordId
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isProcessing", false);
            let state = response.getState();
            
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                if (result.isSuccess) {
                    // Show success message and close modal
                    this.showToast("Success", "Booking request abandoned successfully", "success");
                    this.closeModal(component);
                    // Refresh the view
                    $A.get("e.force:refreshView").fire();
                } else {
                    component.set("v.errorMessage", result.errorMessage);
                }
            } else if (state === "ERROR") {
                let errors = response.getError();
                let errorMessage = "Unknown error";
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                }
                component.set("v.errorMessage", errorMessage);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    showToast: function(title, message, type) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})