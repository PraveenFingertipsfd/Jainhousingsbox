({
    doInit : function(component, event, helper) {
        helper.loadCustomerData(component);
        helper.checkApprovalStatus(component);
    },

    close : function(component) {
        $A.get("e.force:closeQuickAction").fire();
    },

    submitForApproval1 : function(component, event, helper) {
        helper.submitApproval1(component,event,helper);
    },

    // Preview handlers
    previewNDC : function(component) {
        component.set("v.previewUrl", '/apex/NDC?id=' + component.get("v.recordId"));
        component.set("v.showPreview", true);
    },

    previewPossession : function(component) {
        component.set("v.previewUrl", '/apex/PossessionLetter?id=' + component.get("v.recordId"));
        component.set("v.showPreview", true);
    },

    closePreview : function(component) {
        component.set("v.showPreview", false);
    }
})