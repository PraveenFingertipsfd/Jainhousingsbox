({
    showToast: function(component, title, message, type) {
        var notifLib = component.find("notifLib");
        notifLib.showToast({
            "variant": type,
            "title": title,
            "message": message
        });
    },
    saveRecords: function (component, updatedRecords) {

        var action = component.get("c.saveAdditionalChargeReceipts"); // Apex method name
        action.setParams({
            receiptRecords: updatedRecords
        });
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('Records saved successfully');
                $A.get("e.force:showToast").setParams({
                    title: "Success",
                    message: "Records saved successfully!",
                    type: "success"
                }).fire();
                component.set('v.showPoup',false);
                $A.get('e.force:refreshView').fire();
                component.set("v.showSpinner", false);
            } else if (state === "ERROR") {
                component.set("v.showSpinner", false);
                console.error('Error saving records:', response.getError());
                $A.get("e.force:showToast").setParams({
                    title: "Error",
                    message: "Failed to save records. Please try again.",
                    type: "error"
                }).fire();
            }
        });
        
        $A.enqueueAction(action);
    }
})