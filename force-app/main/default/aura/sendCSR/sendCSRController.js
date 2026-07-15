({
    doInit: function(component, event, helper) {
        // Get booking details and populate email options
        let action = component.get("c.jointInspectionDetails1");
        action.setParams({ 
            "jointInspectionId": component.get("v.recordId") 
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                component.set("v.unitName", result.unitName);
                component.set("v.emailOptions", result.emailOptions);
                //component.set("v.bookingId", result.bookingId);
                component.set("v.inspectionId", result.inspectionId);
                component.set("v.showModal", true);
            } else if (state === "ERROR") {
                console.error('Error fetching booking details', response.getError());
                component.set("v.errorMessage", "Error loading booking details. Please check if this inspection has a related booking.");
            }
        });
        $A.enqueueAction(action);
    },
    
    handleEmailChange: function(component, event, helper) {
        let selectedEmail = event.getSource().get("v.value");
        component.set("v.selectedEmail", selectedEmail);
        
        // Clear custom email if not "other" is selected
        if (selectedEmail !== 'other') {
            component.set("v.customEmail", '');
        }
    },
    
    handleSendEmail: function(component, event, helper) {
        let selectedEmail = component.get("v.selectedEmail");
        let customEmail = component.get("v.customEmail");
        //let bookingId = component.get("v.bookingId");
        let inspectionId = component.get("v.inspectionId");
        
        /*if (!bookingId) {
            component.set("v.errorMessage", "No related booking found");
            return;
        }*/
        
        // Validate email selection
        if (!selectedEmail) {
            component.set("v.errorMessage", "Please select an email option");
            return;
        }
        
        // Validate custom email if "other" is selected
        if (selectedEmail === 'other' && !customEmail) {
            component.set("v.errorMessage", "Please enter a valid email address");
            return;
        }
        
        // Determine final email address
        let emailToSend = (selectedEmail === 'other') ? customEmail : selectedEmail;
        
        component.set("v.isProcessing", true);
        component.set("v.errorMessage", "");
        
        // Call Apex method to send email
        let action = component.get("c.sendCSR");
        action.setParams({
            //"bookingId": bookingId,
            "inspectionId" : inspectionId,
            "emailAddress": emailToSend
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isProcessing", false);
            let state = response.getState();
            
            if (state === "SUCCESS") {
                // Show success message
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Invitation sent successfully",
                    "type": "success"
                });
                toastEvent.fire();
                
                $A.get("e.force:refreshView").fire();
                
                // Close the modal
                $A.get("e.force:closeQuickAction").fire();
                
                
                
                
            } else if (state === "ERROR") {
                let errors = response.getError();
                let errorMessage = "Error sending invitation";
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = errors[0].message.split(':').pop().trim();
                }
                component.set("v.errorMessage", errorMessage);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    validateEmail: function(email) {
        var re = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        return re.test(email);
    },
    
    handleCancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})