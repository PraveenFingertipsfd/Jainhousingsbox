({
    doInit : function(component, event, helper) {
        let baseUrl = window.location.origin;
        let recordId = component.get("v.recordId");
        let url = baseUrl + '/apex/NDC?Id=' + recordId;
        component.set("v.vfPageUrl", url);
        
        // Check current approval status
        helper.checkApprovalStatus(component);
        
    },
    
    sendApproval: function(component, event, helper) {
        component.set("v.isApprovalSubmitted", true);
        
        var action = component.get("c.submitForApproval");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                
                if (result === 'SUCCESS') {
                    component.set("v.isApprovalSubmitted", true);
                    //component.set("v.approvalStatus", "Submitted for approval");
                    helper.handleSuccess(component, event, "No Due Certificate Sent for Approval");
                } else {
                    component.set("v.isApprovalSubmitted", false);
                    helper.handleError(result);
                }
            } else {
                component.set("v.isApprovalSubmitted", false);
                helper.handleError(response.getError());
            }
        });
        
        $A.enqueueAction(action);
        //$A.get("e.force:closeQuickAction").fire();
        //$A.get('e.force:refreshView').fire();
    },
    
    
    close : function(component, event, helper) {
        event.stopPropagation();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
    
    /*
     send: function(component, event, helper) {
        // Call the Apex method 'sendEmailGenerateNDC'
        var action = component.get("c.sendEmailGenerateNDC");
        
        // Set the parameter for the Apex method - receiptId is passed from the component
        action.setParams({"recId": component.get("v.recordId")});
        
        // Set the callback function to handle the response from Apex
        action.setCallback(this, function(response) {
            var state = response.getState(); // Get the response state
            
            if (state === 'SUCCESS') {
                // Retrieve the return value from the Apex method
                var res_string = response.getReturnValue();
                
                // Stop the event propagation
                event.stopPropagation();
                
                // Close the quick action panel
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                // Determine the toast type based on the response
                var type = res_string === 'Email sent successfully' ? 'success' : 'error';
                
                // Show toast notification
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": type,
                    "title": type,
                    "message": res_string,
                    "duration": 10000
                });
                toastEvent.fire();
                
                // Refresh the view to reflect changes
                $A.get('e.force:refreshView').fire();
            } else if (state === 'ERROR') {
                // Handle error case
                console.log('Failed to send email: ', response.getError());
            }
        });
        
        // Enqueue the action to call the Apex method
        $A.enqueueAction(action);
    },*/
    
    
       
    
})