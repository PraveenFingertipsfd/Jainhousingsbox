({
    doInit: function (component, event, helper) {
        var selectedRecords = component.get('v.selectedRecords');
        let count = 0;
        let activeSections = component.get("v.activeSections") || [];
        var filteredRecords = selectedRecords.filter(function (record) {
            return record.Pending_Amount__c > 0;
        });
        
        var initializedRecords = filteredRecords.map(function (record) {
            activeSections.push('A'+count.toString());
            count+=1;
            return {
                Id: record.Id,
                Name: record.Name,
                Additional_Charge_Type__c: record.Additional_Charge_Type__c,
                Total_Additional_Charge__c: record.Total_Additional_Charge__c,
                Total_Received_Amount__c: record.Total_Received_Amount__c,
                Pending_Amount__c: record.Pending_Amount__c,
                Bank_Name__c: '',              
                Payer_Bank_Details__c: '',    
                Payment_Method__c: '',         
                Receipt_Date__c: '',           
                Transaction_Id__c: '',         
                Amount_Received__c: 0,
                Remarks__c:'',
                BalanceAmount : record.Pending_Amount__c
            };
        });
        
        component.set("v.activeSections", activeSections);
        component.set('v.recordsToDisplay', initializedRecords);
        component.set("v.showSpinner", false);
    },
    Close: function(component, event, helper) {
        component.set('v.showPoup',false);
        component.set("v.showSpinner", false);
    },        
    handleSubmit: function (component, event, helper) {
        component.set("v.showSpinner", true);
        var records = component.get("v.recordsToDisplay");
        var updatedRecords = [];
        var isValid = true;
        
        let isAllValid = component.find('field').reduce(function(isValidSoFar, inputCmp){
            inputCmp.showHelpMessageIfInvalid();
            return isValidSoFar && inputCmp.checkValidity();
        }, true);
        
        records.forEach(function (record) {
            if (
                !record.Bank_Name__c || 
                !record.Payer_Bank_Details__c || 
                !record.Payment_Method__c || 
                !record.Receipt_Date__c || 
                !record.Transaction_Id__c || 
                !record.Amount_Received__c || record.Amount_Received__c > record.Pending_Amount__c
            ) {
                isValid = false;
            } else {
                updatedRecords.push({
                    Additional_Charges__c: record.Id,
                    Remarks__c: record.Remarks__c || '',
                    Bank_Name__c: record.Bank_Name__c,
                    Payer_Bank_Details__c: record.Payer_Bank_Details__c,
                    Payment_Method__c: record.Payment_Method__c,
                    Receipt_date__c: record.Receipt_Date__c,
                    Transaction_Id__c: record.Transaction_Id__c,
                    Amount_received__c: record.Amount_Received__c
                });
            }
        });
        
        if (!isValid) {
            $A.get("e.force:showToast").setParams({
                title: "Error",
                message: "Please fill in all required fields in each record.",
                type: "error"
            }).fire();
            return;
        }
        
        helper.saveRecords(component, updatedRecords);
    },
    toggleSelectAll: function (component, event, helper) {
        
        const allChecked = event.getSource().get("v.checked");
        component.set("v.allChecked", allChecked);
        const checkboxes = component.get("v.recordsToDisplay");
        
        checkboxes.forEach(function (checkbox) {
            if (!checkbox.booking.Email1__c || checkbox.demandRaised) {
                checkbox.selected = false;
            } else {
                checkbox.selected = allChecked;
            }
        });
        
        component.set("v.recordsToDisplay", checkboxes);
    },
    toggleCheckbox: function (component, event, helper) {
        
        const index = event.getSource().get("v.name");
        const checkboxes = component.get("v.recordsToDisplay");
        
        checkboxes[index].selected = event.getSource().get("v.checked");
        
        component.set("v.recordsToDisplay", checkboxes);
        
        const allChecked = checkboxes.every(checkbox => {
            return (!checkbox.booking.Email1__c || checkbox.demandRaised) || checkbox.selected;
        });
        
        component.set("v.allChecked", allChecked);
    },
    
})