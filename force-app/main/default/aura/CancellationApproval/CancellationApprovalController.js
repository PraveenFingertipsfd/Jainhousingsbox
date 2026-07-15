({
	doInit : function(component, event, helper) {	
	},
    SaveMethod : function(component, event, helper) {
        if(component.get('v.CancellationReason') != null && component.get('v.CancellationDiscription') != null)
        {
        //alert(cancelType);
        var action=component.get("c.sendCancellationApproval");
        action.setParams({'recId':  component.get('v.recordId'),
                          'cancelType': '',
                          'CanlRes' : component.get('v.CancellationReason'),
                          'CanlDis' : component.get('v.CancellationDiscription')
                         })
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS" ){ 
                var db = response.getReturnValue();
                if(db == true){
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Success',
                        "title": 'Success!',
                        "message":'Cancellation request successfully sent for approval',
                        "duration":10000
                    });
                    toastEvent.fire();
                }
                else{
                    alert('Some Error has occured');
                }
                
            }
            else{
                alert('Some Error has occured');
            }
        });
        $A.enqueueAction(action); 
    }
        else{
             var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'Please fill Cancellation Reason and Discription',
                        "duration":10000
                    });
                    toastEvent.fire();
        }
    },
     closeModel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:closeQuickAction').fire();
        $A.get('e.force:refreshView').fire();
    },
})