({
	doInit : function(component, event, helper) {
		var action = component.get("c.getpageName");
        action.setParams({"recId":component.get("v.recordId")});
        action.setCallback(this,function(response){
            if(response.getState() == 'SUCCESS' ) {
                var res_string= response.getReturnValue();
                component.set('v.vfPageName',res_string);
            }
            else
            {
                (state === 'ERROR')
                {
                    console.log('failed');
                }
            }
        });
        $A.enqueueAction(action);
	},
    send: function(component,event,helper){
        //alert(1);
        var action = component.get("c.sendEmailtoCustomer");
        action.setParams({"recId":component.get("v.recordId"),
                          "PAgNam":component.get('v.vfPageName')});
        action.setCallback(this,function(response){
             //alert(response.getState());
            if(response.getState() == 'SUCCESS' ) {
                
                var res_string= response.getReturnValue();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":'success',
                    "title": 'success',
                    "message":'Application sent customer',
                    "duration":10000
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                 //alert(errors); 
                //alert(JSON.stringify(errors));
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
})