({
    loadCustomerData: function(component) {
        var action = component.get("c.getBookingRecord");
        action.setParams({ recordId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            if(response.getState() === 'SUCCESS') {
                var booking = response.getReturnValue();
                component.set("v.customerName", booking.First_Applicant_Name__c);

                // Default editable email body
                var body = '<p>Dear <strong>' + booking.First_Applicant_Name__c + '</strong>,</p><br/>' +
                           '<p>Greetings from Jain Housing!</p>' +
                           '<p>We are delighted to inform you that all formalities and payments for your flat have been successfully completed. ' +
                           'As part of the final handover process, please find the following documents attached for your records:</p>' +
                           '<strong><ul><li>No Due Certificate</li><li>Possession Letter</li></ul></strong>' +
                           '<p>On behalf of the entire team at Jain Housing, I would like to thank you sincerely for placing your trust in us. ' +
                           'We wish you and your loved ones a joyful, peaceful, and prosperous life in your new home. ' +
                           'May it bring you happiness and wonderful memories for years to come.</p>' +
                           '<p>Should you need any further assistance, please feel free to reach out to us at any time—we’re always here to help.</p><br/>' +
                           '<p>Warm regards,<br/>Customer Relationship Manager<br/><strong>Jain Housing</strong></p>';
                
                component.set("v.emailBody", body);
            }
        });
        $A.enqueueAction(action);
    },

    checkApprovalStatus: function(component) {
        var action = component.get("c.getApprovalStatus");
        action.setParams({ recordId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            if(response.getState() === 'SUCCESS') {
                component.set("v.isApprovalSubmitted", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    /*
    submitApproval: function(component) {
        var action = component.get("c.submitForApproval");
        action.setParams({ recordId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            console.log('STATE:', response.getState());
        console.log('RETURN:', response.getReturnValue());
            if(response.getState() === 'SUCCESS' && response.getReturnValue() === 'SUCCESS') {
                this.handleSuccess(component, "Approval Submitted Successfully");
                // Send email after approval
                this.sendEmailWithAttachments(component);
            } else {
                this.handleError(response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },*/
    
    submitApproval1: function(component,event,helper) {
        var action = component.get("c.submitForApproval");
        action.setParams({ recordId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('STATE:', state);
            
            if (state === 'SUCCESS') {
                var returnVal = response.getReturnValue();
                console.log('RETURN:', returnVal);
                if (returnVal == 'SUCCESS') {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Success',
                        "title": 'Success',
                        "message":'Approval Submitted Successfully',
                        "duration":10000
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    //helper.handleSuccess(component,event,helper, "Approval Submitted Successfully");
                    //helper.sendEmailWithAttachments(component);
                } else {
                    var toast = $A.get("e.force:showToast");
                    toast.setParams({ title: "Error", message: 'Already in approval process', type: "error" });
                    toast.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    // This is a message like "Already in approval process" or an error string from Apex
                    //helper.handleError(component,event,helper,returnVal);
                }
            } else if (state === 'ERROR') {
                var errors = response.getError();
                console.error('ERROR:', errors);
                
                if (errors && errors[0] && errors[0].message) {
                    helper.handleError(errors[0].message);
                } else {
                    helper.handleError('Unknown error occurred while submitting for approval');
                }
            } else if (state === 'INCOMPLETE') {
                this.handleError('No response from server or client is offline.');
            }
        });
        
        $A.enqueueAction(action);
    },


    sendEmailWithAttachments: function(component) {
        var action = component.get("c.sendEmailNDCAndPossession");
        action.setParams({ recordId: component.get("v.recordId"), 
                           emailBody: component.get("v.emailBody") });
        action.setCallback(this, function(response) {
            if(response.getState() === 'SUCCESS') {
                helper.handleSuccess(component, "NDC & Possession Letter sent to Customer");
            } else {
                helper.handleError(response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    handleSuccess: function(component,event,helper, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":'Success',
            "title": 'Success',
            "message":msg,
            "duration":10000
        });
        toastEvent.fire();
        $A.get("e.force:closeQuickAction").fire();
    },

    handleError: function(component,event,helper,msg) {
        var toast = $A.get("e.force:showToast");
        toast.setParams({ title: "Error", message: msg, type: "error" });
        toast.fire();
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
    }
})