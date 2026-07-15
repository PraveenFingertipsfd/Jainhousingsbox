({
    doInit : function(component, event, helper) {
        let recordId = component.get("v.recordId");
        let action = component.get("c.IsWelcomeCallCheckListUpdated");
        action.setParams({ recordId: recordId });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                if (result) {
                    helper.showToast('Success', "Successfully Updated Welcome Call Checklist", 'success');
                } else {
                    helper.showToast('Error', "Complete all the Pending Welcome Call Checklist", 'error');
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