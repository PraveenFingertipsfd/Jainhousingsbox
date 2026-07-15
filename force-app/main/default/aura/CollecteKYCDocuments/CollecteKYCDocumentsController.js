({
    doInit : function(component, event, helper) {
        let recordId = component.get("v.recordId");
        let action = component.get("c.isKYCCollected");
        action.setParams({ recordId: recordId });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                if (result === 'SUCCESS') {
                    helper.showToast('Success', "KYC Documents Collected Successfully & Submitted for CRM Manager's Approval", 'success');
                } else {
                    helper.showToast('Error', result, 'error');
                }
            } else {
                this.showToast('Error', 'Unknown error occurred', 'error');
            }
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        });

        $A.enqueueAction(action);
    }
})