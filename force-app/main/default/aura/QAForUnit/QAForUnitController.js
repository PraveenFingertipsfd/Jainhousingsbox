({
    doInit : function(component, event, helper) {
        // Show the modal when component loads
        component.set("v.showModal", true);
    },
    
    handleConfirm : function(component, event, helper) {
        component.set("v.isProcessing", true);
        component.set("v.errorMessage", "");
        
        helper.confirmQualityAssurance(component);
    },
    
    handleCancel : function(component, event, helper) {
        // Close the modal and dismiss the action
        helper.closeAction(component);
    }
})