({

    loadObjectOptions: function (component) {
        var approvalRecords = component.get("v.approvalRecords") || [];
        var objectSet = new Set();
        
        // Collect unique object labels
        approvalRecords.forEach(function (record) {
            objectSet.add(record.ObjectType);
        });
        
        // Convert Set to Array and sort alphabetically
        var sortedObjects = Array.from(objectSet).sort();
        
        // Build picklist options with "All Objects" on top
        var options = [{ label: 'All', value: 'All' }];
        
        sortedObjects.forEach(function (label) {
            options.push({ label: label, value: label });
        });
        
        component.set("v.objectOptions", options);
    },
    
    loadApprovalRecords: function (component) {
        component.set("v.isLoading", true);
        
        var action = component.get("c.getPendingApprovals");
        
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var records = result.records || [];
                var total = result.totalPending || 0;
                
                records.forEach(function(record) {
                    record.selected = false;
                });
                
                component.set("v.approvalRecords", records);
                component.set("v.totalPending", total);
                
                // Dynamically load picklist options based on returned records
                this.loadObjectOptions(component);
                
                // Default: Show all records initially
                this.filterRecords(component);
                
            } else {
                this.showToast('Error', 'Failed to load approval records', 'error');
            }
            component.set("v.isLoading", false);
        });
        
        $A.enqueueAction(action);
    },
  
    filterRecords: function (component) {
        var selectedObject = component.get("v.selectedObject");
        var allRecords = component.get("v.approvalRecords");
        
        // Filter based on selected object
        var filteredRecords =
            selectedObject === 'All'
        ? allRecords
        : allRecords.filter(function (record) {
            return record.ObjectType === selectedObject;
        });
        
        // 🔹 Reset selection when switching object type
        filteredRecords.forEach(function (record) {
            record.selected = false;
        });
        
        component.set("v.filteredRecords", filteredRecords);
        component.set("v.selectAll", false);
    	component.set("v.selectedRecords", []); // clear selected list
        
        var total = filteredRecords.length;
        
        // Dynamic label for total pending
        if (selectedObject === 'All') {
            component.set("v.totalPendingLabel", 'Total Pending: ' + total);
        } else {
            component.set(
                "v.totalPendingLabel",
                'Total Pending in ' + selectedObject + ': ' + total
            );
        }
    },

    handleSelectAll: function (component, event) {
        var isSelected = event.getSource().get("v.checked");
        component.set("v.selectAll", isSelected);
        
        var filteredRecords = component.get("v.filteredRecords");
        filteredRecords.forEach(function (record) {
            record.selected = isSelected;
        });
        
        component.set("v.filteredRecords", filteredRecords);
        this.updateSelectedRecords(component);
        
        // ✅ Hide/Show action column dynamically
        component.set("v.hideActionColumn", isSelected);
    },
    
    handleRecordSelection: function (component, event) {
        var recordId = event.getSource().get("v.value");
        var isSelected = event.getSource().get("v.checked");
        
        var filteredRecords = component.get("v.filteredRecords");
        var anySelected = false;
        var allSelected = true;
        
        
        filteredRecords.forEach(function (record) {
            if (record.Id === recordId) {
                record.selected = isSelected;
            }
            if (record.selected) {
                anySelected = true; // ✅ At least one checkbox is checked
            } else {
                allSelected = false;
            }
            /*
            if (!record.selected) {
                allSelected = false;
            }*/
        });
        
        component.set("v.filteredRecords", filteredRecords);
        component.set("v.selectAll", allSelected);
        this.updateSelectedRecords(component);
        
        // ✅ If all selected → hide, else show
        component.set("v.hideActionColumn", anySelected);
    },

    updateSelectedRecords: function (component) {
        var filteredRecords = component.get("v.filteredRecords");
        var selectedRecords = filteredRecords
            .filter(function (record) {
                return record.selected;
            })
            .map(function (record) {
                return record.Id;
            });

        component.set("v.selectedRecords", selectedRecords);
    },

    processApprovals1: function (component, action, recordIds, comments) {
        let actionCall = component.get("c.processBulkApproval");
        actionCall.setParams({
            recordIds: recordIds,
            action: action,
            comments: comments
        });
        
        actionCall.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                //alert(action + " successful!");
                this.showToast("Success", action + " successful!", "success");
                
                // ✅ If we are in detailed view, close it automatically
                if (component.get("v.showDetailedView")) {
                    component.set("v.showDetailedView", false);
                    component.set("v.costSheetDetails", {});
                    component.set("v.paymentSchedules", []);
                }
                
                // 🔹 Reset selections & header checkbox
                component.set("v.selectAll", false);
                component.set("v.selectedRecords", []);
                let records = component.get("v.approvalRecords") || [];
                records.forEach(function (r) { r.selected = false; });
                component.set("v.approvalRecords", records);
                
                // ✅ Always clear comments after success
                component.set("v.comments", "");
                component.set("v.hideActionColumn",false);
                
                this.loadApprovalRecords(component);
            } else {
                //alert("Error: " + response.getError()[0].message);
                this.showToast("Error", message, "error");
            }
        });
        $A.enqueueAction(actionCall);
    },
    
    processApprovals: function (component, action, recordIds, comments) {
        let cancellationCharges = component.get("v.cancellationCharges");
        let modalInfo = component.get("v.modalInfo");
        let isMD = component.get("v.isMD");
        
        // Create approval request
        let actionCall = component.get("c.processBulkApproval");
        actionCall.setParams({
            recordIds: recordIds,
            action: action,
            comments: comments
        });
        
        actionCall.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                // If successful and needs to update cancellation charges
                if (modalInfo.approvalProcessName === 'Cancellation Approval' && isMD && cancellationCharges) {
                    // Update booking with cancellation charges - fire and forget
                    let updateAction = component.get("c.updateCancellationCharges");
                    updateAction.setParams({
                        recordId: recordIds[0],
                        cancellationCharges: parseFloat(cancellationCharges)
                    });
                    $A.enqueueAction(updateAction);
                }
                
                this.showToast("Success", action + " successful!", "success");
                
                // Reset UI (existing code)
                if (component.get("v.showDetailedView")) {
                    component.set("v.showDetailedView", false);
                    component.set("v.costSheetDetails", {});
                    component.set("v.paymentSchedules", []);
                }
                
                component.set("v.selectAll", false);
                component.set("v.selectedRecords", []);
                let records = component.get("v.approvalRecords") || [];
                records.forEach(function (r) { r.selected = false; });
                component.set("v.approvalRecords", records);
                component.set("v.comments", "");
                component.set("v.hideActionColumn",false);
                component.set("v.cancellationCharges", 0); // Reset charges field
                
                this.loadApprovalRecords(component);
            } else {
                this.showToast("Error", "Approval process failed", "error");
            }
        });
        $A.enqueueAction(actionCall);
    },
    
    getSelectedRecordIds: function (component) {
        let records = component.get("v.filteredRecords") || [];
        return records.filter(r => r.selected).map(r => r.Id);
    },

    showToast: function (title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            type: type,
            mode: 'dismissible'
        });
        toastEvent.fire();
    },
    
    // NEW: Get modal information before showing the modal
    getModalInfo: function(component, recordIds, action) {
        let targetRecordId = recordIds[0]; // Check first record for bulk actions
        let actionCall = component.get("c.getApprovalModalInfo");
        actionCall.setParams({ recordId: targetRecordId });
        
        actionCall.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                component.set("v.modalInfo", result);
                // Now open the modal with the fetched info
                component.set("v.selectedAction", action);
                component.set("v.selectedRecordIds", recordIds);
                component.set("v.showCommentModal", true);
            } else {
                // If fails, open modal normally without extra fields
                component.set("v.selectedAction", action);
                component.set("v.selectedRecordIds", recordIds);
                component.set("v.showCommentModal", true);
            }
        });
        $A.enqueueAction(actionCall);
    },
    
    // NEW: Process approvals with cancellation charges for MD users
    processApprovalsWithCharges: function (component, action, recordIds, comments, cancellationCharges) {
        // First update the cancellation charges
        let updateAction = component.get("c.updateCancellationCharges");
        updateAction.setParams({
            recordId: recordIds[0], // Assuming first record in bulk selection
            cancellationCharges: parseFloat(cancellationCharges) || 0
        });
        
        updateAction.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                // After successfully saving charges, process the approval
                this.processApprovals(component, action, recordIds, comments);
            } else {
                this.showToast("Error", "Failed to update cancellation charges", "error");
                // Re-open modal if charges update fails
                component.set("v.showCommentModal", true);
            }
        });
        $A.enqueueAction(updateAction);
    },
    
    // NEW: Load Cost Sheet Details
    loadCostSheetDetails: function(component, recordId) {
        component.set("v.isLoading", true);
        
        var action = component.get("c.getCostSheetDetails");
        action.setParams({
            recordId: recordId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.costSheetDetails", result.quoteDetails);
                component.set("v.paymentSchedules", result.paymentSchedules);
                component.set("v.showDetailedView", true);
            } else {
                this.showToast('Error', 'Failed to load cost sheet details', 'error');
            }
            component.set("v.isLoading", false);
        });
        
        $A.enqueueAction(action);
    },
    
    loadBookingDetails: function(component, recordId) {
        component.set("v.isLoading", true);
        const action = component.get("c.getBookingDetails");
        action.setParams({ recordId: recordId });
        
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const result = response.getReturnValue();
                component.set("v.bookingDetails", result.bookingInfo);
                component.set("v.costSheetDetails", result.costSheetDetails);
                component.set("v.paymentSchedules", result.paymentSchedules);
                
                // ✅ Enable booking view flag
                component.set("v.isBookingView", true);
            } else {
                this.showToast("Error", "Failed to fetch booking details", "error");
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    }

});