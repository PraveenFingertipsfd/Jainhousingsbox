({
    openModal : function(component, event, helper) {
        component.set("v.showModal", true);
    },

    closeModal : function(component, event, helper) {
        component.set("v.showModal", false);
    }
})