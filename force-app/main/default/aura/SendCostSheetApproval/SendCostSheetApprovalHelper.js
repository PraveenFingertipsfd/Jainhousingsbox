({
    processApprovalSubmission : function(component) {
        let recordId = component.get("v.recordId");
        let action = component.get("c.submitRecordForApproval");

        action.setParams({ recordId: recordId });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                this.showToast('Success', 'Cost Sheet submitted for approval successfully', 'success');
            } else {
                let errorMsg = 'Failed to submit for approval';
                let errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    errorMsg += ': ' + errors[0].message;
                }
                this.showToast('Error', errorMsg, 'error');
            }

            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        });

        $A.enqueueAction(action);
        
    },

    showToast : function(title, message, type) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "duration": 8000  // duration in milliseconds (8000 = 8 seconds)
        });
        toastEvent.fire();
    }
})