({
    doInit : function(component, event, helper) {
        var action = component.get("c.getBookingRecord");
        action.setParams({recordId :component.get("v.recordId") });
        action.setCallback(this,function(response){
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                component.set("v.bookingRecord",result.booking);
                component.set("v.currentMilestone",result.currentMilestone);
            } else {
                console.error("Error fetching data: ", response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    handleClick : function(component, event, helper) {
        component.set("v.showPopup",true);
    }
})