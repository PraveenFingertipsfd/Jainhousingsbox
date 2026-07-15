({
    
    closeModel: function(component, event, helper) {
        
        $A.get("e.force:closeQuickAction").fire();
        /*
         var homeEvt = $A.get("e.force:navigateToObjectHome");
        homeEvt.setParams({
            "scope": "Booking__c"
        });
        homeEvt.fire();*/
        $A.get('e.force:closeQuickAction').fire();
        $A.get('e.force:refreshView').fire();
        
    },
   sendRequest : function(component, event, helper) {
    var action = component.get("c.requestSaleAgreement");  
    action.setParams({'recId': component.get('v.recordId') });
    
    action.setCallback(this, function(response) {
        var state = response.getState();
        
        if (state === "SUCCESS") { 
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "message": "The request for the sale agreement has been sent.",
                "type": "success"
            });
            toastEvent.fire();
            
            $A.get('e.force:refreshView').fire();
            $A.get("e.force:closeQuickAction").fire();
            
        } else if (state === "ERROR") {
            var errors = response.getError();
            var message = "This record is currently in an approval process / An error occurred while sending the request.";
            
            if (errors && errors[0] && errors[0].message) {
                message = errors[0].message;
            }
            
            var errorToastEvent = $A.get("e.force:showToast");
            errorToastEvent.setParams({
                "title": "Error",
                "message": message,
                "type": "error"
            });
            errorToastEvent.fire();
        }
    });
    
    $A.enqueueAction(action);
}

})