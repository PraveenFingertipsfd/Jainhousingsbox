({
    doInit : function(component, event, helper) {
        let baseUrl = window.location.origin;
        var action = component.get("c.getBookingRecord");
        var bookingRecordId = component.get("v.recordId");
        action.setParams({recordId :component.get("v.recordId") });     
        action.setCallback(this,function(a){           
            component.set("v.bookingRecord",a.getReturnValue());
            let bookingval = a.getReturnValue();
            let url;
            if(bookingval.Project__c == 'Aarya'){
                url = baseUrl+'/apex/CONSENT_LETTER_AARYA?Id=' + bookingRecordId + '#view=fitH';
            }else if(bookingval.Project__c == 'Arto Helix'){
                url = baseUrl+'/apex/CONSENT_LETTER_ARTO_HELIX?Id=' + bookingRecordId + '#view=fitH';
            }
            
            component.set("v.vfPageUrl", url);
        });
        $A.enqueueAction(action);
    },
      send: function(component, event, helper) {
        // Call the Apex method 'sendEmailGenerateConsent'
        var action = component.get("c.sendEmailGenerateConsent");
        
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
    },
    close : function(component, event, helper) {
        event.stopPropagation();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
})