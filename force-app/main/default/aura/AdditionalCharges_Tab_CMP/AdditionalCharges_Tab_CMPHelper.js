({
    getAdditionalCharges: function (component) {
        var bookingId = component.get("v.recordId");
        
        var action = component.get("c.getAdditionalCharges");
        
        // Set the parameter for the Apex method
        action.setParams({
            bookingId: bookingId
        });
        
        // Handle the response from the Apex method
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var charges = response.getReturnValue();
                
                // Add the 'checked' field to each charge record
                charges.forEach(function (charge) {
                    charge.checked = false; // Default value, you can adjust as needed
                });
                
                console.log(charges);
                component.set("v.additionalCharges", charges);
                component.set("v.showSpinner", false);
            } else {
                component.set("v.showSpinner", false);
                console.log("Error: " + response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
    showToast: function(component, title, message, type) {
        var notifLib = component.find("notifLib");
        notifLib.showToast({
            "variant": type,
            "title": title,
            "message": message
        });
    }
})