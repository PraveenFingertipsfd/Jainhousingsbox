({
    doInit: function(component, event, helper) {
        helper.initializeStatus(component);
    },
    
    handleStatusChange: function(component, event, helper) {
        var selectedStatus = component.get("v.selectedStatus");
    },
    
    handleCancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
    handleToast: function(component, event, helper) {
        if (component.get("v.showToast")) {
            helper.showToast(
                component.get("v.toastTitle"),
                component.get("v.toastMessage"),
                component.get("v.toastType")
            );
            component.set("v.showToast", false);
        }
    },
    
    handleUpdateStatus: function(component, event, helper) {
      
        helper.updateInspectionStatus(component);
    }
    
    
})