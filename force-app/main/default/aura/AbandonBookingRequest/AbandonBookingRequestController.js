({
    doInit: function(component, event, helper) {
        component.set("v.showModal", true);
    },
    
    handleCancel: function(component, event, helper) {
        // Close the modal
        helper.closeModal(component);
    },
    
    handleConfirm: function(component, event, helper) {
        // Call helper to process the abandonment
        helper.abandonBookingRequest(component);
    }
})