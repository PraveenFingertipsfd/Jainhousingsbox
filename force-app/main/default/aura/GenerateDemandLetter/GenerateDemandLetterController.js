({
    doInit : function(component, event, helper) {
        let baseUrl = window.location.origin;
        var action = component.get("c.getDemandRaised");
        action.setParams({recordId :component.get("v.recordId") }); 
        action.setCallback(this,function(a){ 
            var state = a.getState();
            if (state === 'SUCCESS') {
                var url = '';
                component.set("v.demandRaisedRecord",a.getReturnValue());
                var demandRaisedValue = a.getReturnValue();
                if(demandRaisedValue.Project_Company__c == 'MAHENDRA HOMES PVT LTD'){
                    url = baseUrl+'/apex/DEMAND_LETTER_SEND_AARYA?Id='+component.get("v.recordId");
                }else if(demandRaisedValue.Project_Company__c == 'MAHENDRA ARTO LLP'){
                    url = baseUrl+'/apex/DEMAND_LETTER_SEND_HELIX?Id='+component.get("v.recordId");
                }else{
                    url = baseUrl+'/apex/DEMAND_LETTER_SEND_AARYA?Id='+component.get("v.recordId");
                }
                if(demandRaisedValue.Demand_Email_Content__c && demandRaisedValue.Demand_Email_Content__c != ''){
                    component.set("v.emailContent", demandRaisedValue.Demand_Email_Content__c);
                }
                if(demandRaisedValue.Demand_Content_Ids__c != '' && demandRaisedValue.Demand_Content_Ids__c){
                    var listRaised = demandRaisedValue.Demand_Content_Ids__c.split(",").map(item => item.trim());
                    component.set("v.filesIDS", listRaised);
                }
                console.log('url'+ url);
                component.set("v.vfPageUrl", url);
            } else if (state === 'ERROR') {
                console.log('here Error');
                // Handle error case
                var errors = response.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    console.log('Error message: ' + errors[0].message);
                } else {
                    console.log('Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },
    send: function(component, event, helper){
        var action = component.get("c.ResendRaiseDemand");
        var recId = component.get("v.recordId");
        var recordIdsList = component.get("v.recordIdsList") || [];
        recordIdsList.push(recId);
        component.set("v.recordIdsList", recordIdsList);
        // Set the parameter for the Apex method - receiptId is passed from the component
        action.setParams({
            "recordIds": recordIdsList,
        });
        
        // Set the callback function to handle the response from Apex
        action.setCallback(this, function(response) {
            console.log('here 7');
            var state = response.getState(); // Get the response state
            
            if (state === 'SUCCESS') {
                console.log('here sucess');
                // Retrieve the return value from the Apex method
                var res_string = response.getReturnValue();
                
                // Close the quick action panel
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                // Determine the toast type based on the response
                var type = res_string === 'Demand Raise records created and submitted for approval.' ? 'success' : 'error';
                
                // Show toast notification
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'success',
                    "title": type.charAt(0).toUpperCase() + type.slice(1), // Capitalize title
                    "message": 'Demand Raise mail successfully resend.',
                    "duration": 10000
                });
                toastEvent.fire();
                
                // Refresh the view to reflect changes
                $A.get('e.force:refreshView').fire();
            } else if (state === 'ERROR') {
                var errors = response.getError();
                var errorMsg = 'An unknown error occurred.';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    errorMsg = errors[0].message;
                }
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error",
                    "message": errorMsg,
                    "duration": 10000
                });
                toastEvent.fire();
            }
        });

        // Enqueue the action to call the Apex method
        $A.enqueueAction(action);
    },
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        getFiles.push(...files);
        component.set('v.filesIDS',getFiles);
        
        var afercomit = component.get('v.filesIDS');
    },
    close : function(component, event, helper) {
        event.stopPropagation();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
        component.set('v.visible',false);
    },
})