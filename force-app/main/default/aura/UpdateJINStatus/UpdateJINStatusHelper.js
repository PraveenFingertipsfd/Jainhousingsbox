({
    initializeStatus: function(component) {
        var action = component.get("c.getInspectionDetails");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.unitName", result.unitName);
                component.set("v.currentStatus", result.currentStatus);
                component.set("v.inspectionId", result.inspectionId);
                
                // Set status options based on current status
                var statusOptions = [];
                if (result.currentStatus === "Initiated") {
                    statusOptions = ["Initiated", "Cancelled"];
                } else if (result.currentStatus === "Scheduled") {
                    statusOptions = ["Scheduled", "Re-Scheduled", "Completed", "Cancelled"];
                } else if (result.currentStatus === "Re-Scheduled") {
                    statusOptions = ["Re-Scheduled", "Completed", "Cancelled"];
                } else if (result.currentStatus === "Completed") {
                    statusOptions = ["Completed"];
                } else if (result.currentStatus === "Cancelled") {
                    statusOptions = ["Cancelled"];
                }
                
                component.set("v.statusOptions", statusOptions);
                component.set("v.showModal", true);
            } else {
                var errors = response.getError();
                var errorMessage = "Error initializing inspection status";
                if (errors && errors[0] && errors[0].message) {
                    errorMessage += ": " + errors[0].message;
                }
                component.set("v.errorMessage", errorMessage);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    updateInspectionStatus: function(component) {
        component.set("v.isProcessing", true);
        component.set("v.errorMessage", "");
        
        var currentStatus = component.get("v.currentStatus");
        var errorMessage = "";
        
        // Validate required fields based on status
        if (currentStatus === "Re-Scheduled") {
            if (!component.get("v.rescheduledReason") || !component.get("v.rescheduledDatetime")) {
                component.set("v.isProcessing", false);
                this.showToast("Error", "Please fill all required fields for Re-Scheduled status", "error");
                return;
            }
        } else if (currentStatus === "Cancelled") {
            if (!component.get("v.cancelledReason")) {
                component.set("v.isProcessing", false);
                this.showToast("Error", "Please provide a cancellation reason", "error");
                return;
            }
        }
        

        
        var action = component.get("c.updateInspectionStatus");
        action.setParams({
            "inspectionId": component.get("v.inspectionId"),
            "newStatus": component.get("v.currentStatus"),
            "comments": component.get("v.comments"),
            "rescheduledReason": component.get("v.rescheduledReason"),
            "rescheduledDatetime": component.get("v.rescheduledDatetime"),
            "cancelledReason": component.get("v.cancelledReason"),
            "cancelledDatetime": component.get("v.cancelledDatetime")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isProcessing", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
                $A.get("e.force:refreshView").fire();
            } else {
                var errors = response.getError();
                var errorMessage = "Error updating inspection status";
                if (errors && errors[0] && errors[0].message) {
                    errorMessage += ": " + errors[0].message;
                }
                component.set("v.errorMessage", errorMessage);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    showToast: function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})