({
    doInit : function(component, event, helper) {
        var selectedRecords = component.get('v.selectedRecords');
        var filteredRecords = selectedRecords.filter(function(record) {
            return record.Pending_Amount__c > 0;
        });
        component.set('v.recordsToDisplay',filteredRecords);
    },
    handleSubmit: function(component, event, helper) {
        
        var selectedACIds = [];
        var emailContentMap = component.get("v.emailContentMap") || {};
        var checkboxes = component.find("acCheckbox");
        checkboxes = Array.isArray(checkboxes) ? checkboxes : [checkboxes];
        checkboxes.forEach(function(checkbox) {
            if (checkbox.get("v.checked")) { 
                var additionalCRecord = checkbox.get("v.value");
                selectedACIds.push(additionalCRecord.Id);
            }
        });
        
        component.set("v.selectedRecordIds", selectedACIds);
        
         var action = component.get("c.RaiseManualACDemand");
        action.setParams({
            "recordIds": selectedACIds,
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState(); // Get the response state
            
            if (state === 'SUCCESS') {
                var res_string = response.getReturnValue();
                component.set("v.showPopup",false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'success',
                    "title": 'Success',
                    "message": 'Demand Raised For Selected Additional Charges',
                    "duration": 10000
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
                component.set('v.showPoup',false);
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
    Close: function(component, event, helper) {
        component.set('v.showPoup',false);
    }
})