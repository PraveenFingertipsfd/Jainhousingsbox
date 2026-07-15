({
    doInit : function(component, event, helper) {
        var action = component.get("c.sendCostsheetEmailLink");
        action.setParams({ costSheetId : component.get('v.recordId')});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result =response.getReturnValue();
                //alert(result);
                if(!result){
                    helper.showToast('Error!','Please Fill Email Address','Error');
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                }
                else{
                    helper.showToast('Success!','Booking Request Mail Sent Successfully','Success');
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                }
            }else{
                alert('Error while loading the Component');
            }
        });
        $A.enqueueAction(action)
    },
    
    doCancel: function (component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    },
    
})