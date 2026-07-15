({
    doInit: function(component, event, helper) {
        component.set("v.showModal", true);
    },
    /*
    handleConfirm: function(component, event, helper) {
        component.set("v.isProcessing", true);
        component.set("v.errorMessage", "");
        
        let action = component.get("c.createJointInspection");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isProcessing", false);
            let state = response.getState();
            
            if (state === "SUCCESS") {
                let newRecordId = response.getReturnValue();
                
                // Show success message
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Joint Inspection created successfully.",
                    "type": "success",
                    "duration": 2000
                });
                toastEvent.fire();
                
                // Close the modal
                $A.get("e.force:closeQuickAction").fire();
                
                // Then navigate to the new record
                setTimeout(function() {
                    let navEvent = $A.get("e.force:navigateToSObject");
                    navEvent.setParams({
                        "recordId": newRecordId,
                        "slideDevName": "detail"
                    });
                    navEvent.fire();
                }, 300); // Small delay to ensure modal closes
                
                
            } else if (state === "ERROR") {
                let errors = response.getError();
                let errorMessage = "Error creating Joint Inspection";
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = errors[0].message.split(':').pop().trim();
                }
                component.set("v.errorMessage", errorMessage);
            }
        });
        
        $A.enqueueAction(action);
    },*/
    
    handleConfirm: function(component, event, helper) {
        component.set("v.isProcessing", true);
        component.set("v.errorMessage", "");
        
        let action = component.get("c.createJointInspection");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isProcessing", false);
            let state = response.getState();
            
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                
                // Check if the response is an error message
                if (result.startsWith('ERROR:')) {
                    component.set("v.errorMessage", result.substring(6).trim());
                } 
                // Check if the response is a toast message
                else if (result.startsWith('TOAST:')) {
                    let toastMessage = result.substring(6).trim();
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Info",
                        "message": toastMessage,
                        "type": "info",
                        "duration": 3000
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    
                    // Refresh the view after closing
                    $A.get('e.force:refreshView').fire();
                }
                // Otherwise it's a success case
                    else {
                        let newRecordId = result;
                        
                        // Show success message
                        let toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "Joint Inspection created successfully.",
                            "type": "success",
                            "duration": 2000
                        });
                        toastEvent.fire();
                        
                        // Close the modal
                        $A.get("e.force:closeQuickAction").fire();
                        
                        // Refresh the view first
                        $A.get('e.force:refreshView').fire();
                        
                        // Then navigate to the new record
                        setTimeout(function() {
                            let navEvent = $A.get("e.force:navigateToSObject");
                            navEvent.setParams({
                                "recordId": newRecordId,
                                "slideDevName": "detail"
                            });
                            navEvent.fire();
                        }, 300);
                    }
            } else if (state === "ERROR") {
                let errors = response.getError();
                let errorMessage = "Error creating Joint Inspection";
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = errors[0].message.split(':').pop().trim();
                }
                component.set("v.errorMessage", errorMessage);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    /*
    handleCancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }*/
    
    handleCancel: function(component, event, helper) {
        // If the component is opened as a Quick Action (standalone)
        if ($A.get("e.force:closeQuickAction")) {
            try {
                $A.get("e.force:closeQuickAction").fire();
            } catch(e) {
                // Do nothing if it's not a Quick Action
            }
        }
        
        // Fire the event so parent can close modal (if used inside parent)
        var closeEvent = component.getEvent("closeModalEvent");
        if (closeEvent) {
            closeEvent.fire();
        }
    }

})