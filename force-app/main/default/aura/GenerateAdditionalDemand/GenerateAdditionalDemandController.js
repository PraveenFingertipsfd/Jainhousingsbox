({
    doInit: function(component, event, helper) {
        let baseUrl = window.location.origin;
        var action = component.get("c.getACRecord");
        var recordIdAC = component.get("v.recordId");
        
        action.setParams({ recordId: recordIdAC });
        
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                let additionalChargeval = response.getReturnValue();
                component.set("v.bookingRecord", additionalChargeval);
                
                let url = '';
                if (additionalChargeval && additionalChargeval.Project_Company__c) {
                    if (additionalChargeval.Project_Company__c === 'MAHENDRA HOMES PVT LTD') {
                        url = baseUrl + '/apex/DEMAND_LETTER_AC_AARYA?Id=' + encodeURIComponent(recordIdAC) + '#view=fitH';
                    } else if (additionalChargeval.Project_Company__c === 'MAHENDRA ARTO LLP') {
                        url = baseUrl + '/apex/DEMAND_LETTER_AC_HELIX?Id=' + encodeURIComponent(recordIdAC) + '#view=fitH';
                    } else {
                        url = baseUrl + '/apex/AdditionalDemandRaiseVfp?Id=' + encodeURIComponent(recordIdAC) + '#view=fitH';
                    }
                } else {
                    url = baseUrl + '/apex/AdditionalDemandRaiseVfp?Id=' + encodeURIComponent(recordIdAC) + '#view=fitH';
                }
                component.set("v.vfPageUrl", url);
            } else {
                console.error('Error in server call: ', response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
    
    send: function(component, event, helper) {
        
        var action = component.get("c.RaiseManualACDemand");
        var recordList = [];
        recordList.push(component.get("v.recordId"));
        action.setParams({"recordIds": recordList});
        
        action.setCallback(this, function(response) {
            var state = response.getState(); // Get the response state
            
            if (state === 'SUCCESS') {
                
                var res_string = response.getReturnValue();
                event.stopPropagation();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var type = res_string === 'Email sent successfully' ? 'success' : 'error';
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": type,
                    "title": type,
                    "message": res_string,
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