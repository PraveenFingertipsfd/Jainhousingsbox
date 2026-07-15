({
    doInit : function(component, event, helper) {
        // Immediately process approval when component loads
        helper.processApprovalSubmission(component);
    }
})