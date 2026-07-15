({
    doInit: function(component, event, helper) {
        let baseUrl = window.location.origin;
        var action = component.get("c.getACRecieptRecord");
        var recordIdAC = component.get("v.recordId");
        
        action.setParams({ recordId: recordIdAC });
        
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                let additionalChargeval = response.getReturnValue();
                component.set("v.dditionalChargeRecord", additionalChargeval);
                
                let url = ''; // Default to empty URL
                if (additionalChargeval && additionalChargeval.Project_Company__c) {
                    if (additionalChargeval.Project_Company__c === 'MAHENDRA HOMES PVT LTD') {
                        url = baseUrl + '/apex/RECEIPT_AC_AARYA?Id=' + encodeURIComponent(recordIdAC) + '#view=fitH';
                    } else if (additionalChargeval.Project_Company__c === 'MAHENDRA ARTO LLP') {
                        url = baseUrl + '/apex/RECEIPT_AC_HELIX?Id=' + encodeURIComponent(recordIdAC) + '#view=fitH';
                    }
                }
                component.set("v.vfPageUrl", url);
            } else {
                console.error('Error in server call: ', response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
    
    send: function(component, event, helper) {
        
        var action = component.get("c.RaiseManualACReciept");
        var recordList = [];
        recordList.push(component.get("v.recordId"));
        action.setParams({"recordIds": recordList});
        
        action.setCallback(this, function(response) {
            var state = response.getState(); // Get the response state
            
            if (state === 'SUCCESS') {
                
                event.stopPropagation();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'success',
                    "title": 'Success',
                    "message": 'Email sent successfully',
                    "duration": 10000
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
                
            } else if (state === 'ERROR') {
                console.log('Failed to send email: ', response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
    close : function(component, event, helper) {
        event.stopPropagation();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
})