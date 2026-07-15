({
    doInit : function(component, event, helper) {
        // Optional init logic
    },

    SaveMethod : function(component, event, helper) {
        var comment = component.get('v.CancellationComment');
        var charge = component.get('v.CancellationCharge');

        // Validation
        if (!comment || charge === null || charge === undefined) {
            var toastEvent = $A.get("e.force:showToast");
            if (toastEvent) {
                toastEvent.setParams({
                    "type": 'error',
                    "title": 'Error!',
                    "message": 'Please fill in both Comment and Cancellation Charge.',
                    "duration": 10000
                });
                toastEvent.fire();
            } else {
                alert('Please fill in both Comment and Cancellation Charge.');
            }
            return; 
        }

        // Apex call
        var action = component.get("c.approvalWithCancellationCharge");
        action.setParams({
            recId: component.get('v.recordId'),
            comment: comment,
            charge: charge
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                var result = response.getReturnValue();
                if (result === true) {
                    var closeAction = $A.get("e.force:closeQuickAction");
                    var refreshAction = $A.get("e.force:refreshView");
                    if (closeAction) closeAction.fire();
                    if (refreshAction) refreshAction.fire();

                    var toastEvent = $A.get("e.force:showToast");
                    if (toastEvent) {
                        toastEvent.setParams({
                            "type": 'success',
                            "title": 'Success!',
                            "message": 'Approval successfully submitted with comment and charge.',
                            "duration": 10000
                        });
                        toastEvent.fire();
                    } else {
                        alert('Approval successfully submitted with comment and charge.');
                    }
                } else {
                    alert('Some error occurred in processing.');
                }
            } else {
                alert('Some error occurred in Apex call.');
            }
        });

        $A.enqueueAction(action); 
    },

    closeModel: function(component, event, helper) {
        let closeAction = $A.get("e.force:closeQuickAction");
        let refreshAction = $A.get("e.force:refreshView");

        if (closeAction) closeAction.fire();
        if (refreshAction) refreshAction.fire();
    }
})