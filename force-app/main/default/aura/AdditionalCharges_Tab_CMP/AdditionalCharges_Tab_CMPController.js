({
    doInit: function(component, event, helper) {
        component.set("v.showSpinner", true);
        component.set('v.baseURL',window.location.origin);
        helper.getAdditionalCharges(component);
    },
    
    handleClickDemand: function(component, event, helper) {
        var selectedRecords = [];
        var checkboxes = component.find("checkboxAC");
        
        checkboxes = Array.isArray(checkboxes) ? checkboxes : [checkboxes];
        checkboxes.forEach(function(checkbox) {
            if (checkbox.get("v.checked")) { 
                var checkboxVal = checkbox.get("v.value");
                var checkboxId = checkbox.get("v.name");                        
                selectedRecords.push(checkbox.get("v.value"));
            }
        });
        if(selectedRecords.length > 0){
        component.set("v.selectedRecordIds",selectedRecords);
        component.set('v.showDemandPopup',true);
        }else{
            helper.showToast(component, 'Error', 'Please select at least one additional charge to raise demand.', 'error');
        }
    },
    toggleCheckbox: function (component, event, helper) {
        console.log('selected:val '+ JSON.stringify(event.target)); 
    },
    handleClickReceipt: function(component, event, helper) {
        
        var selectedRecords = [];
        var checkboxes = component.find("checkboxAC");
        
        checkboxes = Array.isArray(checkboxes) ? checkboxes : [checkboxes];
        checkboxes.forEach(function(checkbox) {
            if (checkbox.get("v.checked")) { 
                var checkboxVal = checkbox.get("v.value");
                var checkboxId = checkbox.get("v.name");                        
                selectedRecords.push(checkbox.get("v.value"));
            }
        });
        if(selectedRecords.length > 0){
            component.set("v.showSpinner", true);
            component.set("v.selectedRecordIds",selectedRecords);
            component.set('v.showReceiptPopup',true);
        }else{
            helper.showToast(component, 'Error', 'Please select at least one additional charge to create receipt.', 'error');
        }
    },
    handleRefresh: function(component, event, helper) {
        component.set("v.showSpinner", true);
        helper.getAdditionalCharges(component);
        $A.get('e.force:refreshView').fire();
    },
    toggleSelectAll: function (component, event, helper) {
        const allChecked = event.getSource().get("v.checked");
        console.log('allChecked'+allChecked);
        component.set("v.allChecked", allChecked);
        
        const checkboxes = component.get("v.additionalCharges");
        
        checkboxes.forEach(function (checkbox) {
            if (checkbox.Status_Dynamic__c === 'Paid' || checkbox.Approval_Status__c !='Approved') {
                checkbox.checked = false;
            }else {
                checkbox.checked = allChecked;
            }
        });
        
        component.set("v.additionalCharges", checkboxes);
    },
    toggleCheckbox: function (component, event, helper) {
        const index = event.getSource().get("v.name");
        const checkboxes = component.get("v.additionalCharges");
        
        checkboxes[index].checked = event.getSource().get("v.checked");
        
        component.set("v.additionalCharges", checkboxes);
        
        const allChecked = checkboxes.every(checkbox => {
            return (checkbox.Status_Dynamic__c === 'Paid' || checkbox.Approval_Status__c !='Approved') || checkbox.checked;
        });
        
        component.set("v.allChecked", allChecked);
    },
})