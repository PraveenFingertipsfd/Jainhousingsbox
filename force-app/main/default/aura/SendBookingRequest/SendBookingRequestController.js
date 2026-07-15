({
    doInit : function(component, event, helper) {
        var action = component.get("c.check_IsPSA");
        action.setParams({ recordId : component.get('v.recordId')});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result =response.getReturnValue();
                component.set('v.IsPSAUnit',result);
                //alert('isPSA > '+ result);
            }else{
                alert('Error while loading the Component');
            }
        });
        $A.enqueueAction(action)
        
    },
    
    dosave : function(component, event, helper) {
        var email = component.get('v.Email');
        var bkPrice = component.get('v.BlockedPrice');
        
        if(email == '' || email == undefined){
            helper.showToast('Error!', 'Please enter a valid Email Address' ,'error');
            return;
        }
        
        var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            helper.showToast('Error!', 'Please enter a valid Email Address', 'error');
            return;
        }
        
        if(component.get('v.IsPSAUnit') && (bkPrice == '' || bkPrice == undefined)){
            helper.showToast('Error!', 'Please enter Blocked Price' ,'error');
            return;
        }
        
        var action = component.get("c.send_Booking_Request");
        action.setParams({
            recordId : component.get('v.recordId'),
            EmailId : component.get('v.Email'),
            BlockedPrice : component.get('v.BlockedPrice'),
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result =response.getReturnValue();
                if(result =='Success'){
                    helper.showToast('Success!','Booking Request send successfully','success');
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                }
                else{
                    helper.showToast('Error!', result,'error');
                    $A.get("e.force:closeQuickAction").fire();
                }
            }else{
                helper.showToast('Error!','Something Went wrong','error');
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action)
    },
    
    doCancel: function (component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    },
    
})