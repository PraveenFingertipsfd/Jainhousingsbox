({
    confirmQualityAssurance : function(component) {
        let recordId = component.get("v.recordId");
        let action = component.get("c.confirmQualityAssurance");
        
        action.setParams({
            "recordId": recordId
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isProcessing", false);
            
            let state = response.getState();
            if (state === "SUCCESS") {
                // Close the modal and refresh the view if needed
                this.closeAction(component);
                
                // Show success toast
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Quality Assurance confirmed successfully.",
                    "type": "success"
                });
                toastEvent.fire();
                
                // Close the quick action if needed
                $A.get("e.force:closeQuickAction").fire();
                
                // Refresh the view if needed
                $A.get('e.force:refreshView').fire();
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
    
    closeAction : function(component) {
        component.set("v.showModal", false);
        // Close the quick action if needed
        $A.get("e.force:closeQuickAction").fire();
    }
})