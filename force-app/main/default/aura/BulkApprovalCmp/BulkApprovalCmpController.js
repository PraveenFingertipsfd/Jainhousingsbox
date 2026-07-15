({
    doInit1: function (component, event, helper) {
        helper.loadObjectOptions(component);
        helper.loadApprovalRecords(component);
    },
    
    doInit: function (component, event, helper) {
        // Step 1: Fetch current user profile name from Apex
        var action = component.get("c.getCurrentUserProfile");
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
               
                var profileName = response.getReturnValue();
                component.set("v.currentUserProfile", profileName);              
               
                var mdProfile = $A.get("$Label.c.Md_Profile");                
                
                component.set("v.isMD", profileName === mdProfile);
                
                helper.loadObjectOptions(component);
                helper.loadApprovalRecords(component);
            } else {
                console.error("Error fetching current user profile:", response.getError());
                // Even if error, load approvals normally
                helper.loadObjectOptions(component);
                helper.loadApprovalRecords(component);
            }
        });
        $A.enqueueAction(action);
    },

    handleObjectChange: function (component, event, helper) {
        helper.filterRecords(component);
    },

    handleSelectAll: function (component, event, helper) {
        helper.handleSelectAll(component, event);
    },

    handleRecordSelection: function (component, event, helper) {
        helper.handleRecordSelection(component, event);
    },
    
    // ✅ Bulk Approve Button (Header)
    handleApprove1: function (component, event, helper) {
        let selected = helper.getSelectedRecordIds(component);
        if (selected.length === 0) {
            //alert('Please select at least one record');
            helper.showToast("Warning", "Please select at least one record", "warning");
            return;
        }
        component.set("v.selectedAction", "Approve");
        component.set("v.selectedRecordIds", selected);
        component.set("v.showCommentModal", true);
    },

    // ✅ Bulk Reject Button (Header)
    handleReject1: function (component, event, helper) {
        let selected = helper.getSelectedRecordIds(component);
        if (selected.length === 0) {
            //alert('Please select at least one record');
            helper.showToast("Warning", "Please select at least one record", "warning");
            return;
        }
        component.set("v.selectedAction", "Reject");
        component.set("v.selectedRecordIds", selected);
        component.set("v.showCommentModal", true);
    },

    // ✅ Single Approve Button in Action Column
    handleSingleApprove1: function (component, event, helper) {
        const recordId = event.getSource().get("v.value");
        component.set("v.selectedAction", "Approve");
        component.set("v.selectedRecordIds", [recordId]);
        component.set("v.showCommentModal", true);
    },

    // ✅ Single Reject Button in Action Column
    handleSingleReject1: function (component, event, helper) {
        const recordId = event.getSource().get("v.value");
        component.set("v.selectedAction", "Reject");
        component.set("v.selectedRecordIds", [recordId]);
        component.set("v.showCommentModal", true);
    },
    
    // ✅ Close Modal
    handleModalClose1: function (component, event, helper) {
        component.set("v.showCommentModal", false);
        component.set("v.comments", "");
    },
    
    handleApprove: function (component, event, helper) {
        let selected = helper.getSelectedRecordIds(component);
        if (selected.length === 0) {
            helper.showToast("Warning", "Please select at least one record", "warning");
            return;
        }
        helper.getModalInfo(component, selected, "Approve");
    },
    
    handleReject: function (component, event, helper) {
        let selected = helper.getSelectedRecordIds(component);
        if (selected.length === 0) {
            helper.showToast("Warning", "Please select at least one record", "warning");
            return;
        }
        helper.getModalInfo(component, selected, "Reject");
    },
    
    handleSingleApprove: function (component, event, helper) {
        const recordId = event.getSource().get("v.value");
        helper.getModalInfo(component, [recordId], "Approve");
    },
    
    handleSingleReject: function (component, event, helper) {
        const recordId = event.getSource().get("v.value");
        helper.getModalInfo(component, [recordId], "Reject");
    },
    
    // Update handleModalClose to reset the new fields
    handleModalClose: function (component, event, helper) {
        component.set("v.showCommentModal", false);
        component.set("v.comments", "");
        component.set("v.cancellationCharges", 0); // Reset charges
        component.set("v.modalInfo", {}); // Reset modal info
    },
    
    

    // ✅ Submit Button Inside Modal
    handleModalSubmit1: function (component, event, helper) {
        const action = component.get("v.selectedAction");
        const comments = component.get("v.comments");
        const selectedIds = component.get("v.selectedRecordIds");

        // 🔹 Validate comments only for reject
        if (action === "Reject" && (!comments || comments.trim() === "")) {
            //alert("Comments are required for rejection!");
            helper.showToast("Error", "Comments are required for rejection!", "error");
            return;
        }

        component.set("v.showCommentModal", false);
        helper.processApprovals(component, action, selectedIds, comments);
    },
    
    handleModalSubmit: function (component, event, helper) {
        const action = component.get("v.selectedAction");
        const comments = component.get("v.comments");
        const selectedIds = component.get("v.selectedRecordIds");
        const modalInfo = component.get("v.modalInfo");
        const cancellationCharges = component.get("v.cancellationCharges");
        const isMD = component.get("v.isMD");
        
        // 🔹 Validate comments only for reject
        if (action === "Reject" && (!comments || comments.trim() === "")) {
            helper.showToast("Error", "Comments are required for rejection!", "error");
            return;
        }
        
        component.set("v.showCommentModal", false);
        
        // NEW LOGIC: If it's a Cancellation Approval and user is MD, process with charges
        if (modalInfo.approvalProcessName === 'Cancellation Approval' && isMD) {
            helper.processApprovalsWithCharges(component, action, selectedIds, comments, cancellationCharges);
        } else {
            // Original logic for all other cases
            helper.processApprovals(component, action, selectedIds, comments);
        }
    },

    handleViewDetails: function(component, event, helper) {
        const recordId = event.getSource().get("v.value");
        
        // ✅ Get filtered records
        let filteredRecords = component.get("v.filteredRecords") || [];
        let selectedRecords = [];
        let objectType = null;
        
        // ✅ Mark only clicked record as selected & get its ObjectType
        filteredRecords.forEach(function(rec) {
            if (rec.Id === recordId) {
                rec.selected = true; // Auto-select this record ✅
                objectType = rec.ObjectType; // Get the type of record (Cost Sheet / Booking)
            } else {
                rec.selected = false; // Unselect others
            }
            
            if (rec.selected) {
                selectedRecords.push(rec.Id);
            }
        });
        
        // ✅ Update component attributes
        component.set("v.filteredRecords", filteredRecords);
        component.set("v.selectedRecords", selectedRecords);
        component.set("v.selectAll", selectedRecords.length === filteredRecords.length);
        
        // ✅ Show action column by default in list view
        component.set("v.hideActionColumn", false);
        
        // ✅ Reset view flags
        component.set("v.isBookingView", false);
        component.set("v.isCostSheetView", false);
        component.set("v.showDetailedView", true);
        
        // ✅ Load data based on type
        if (objectType === "Booking") {
            component.set("v.isBookingView", true);
            helper.loadBookingDetails(component, recordId);
        } else {
            component.set("v.isCostSheetView", true);
            helper.loadCostSheetDetails(component, recordId);
        }
    },

    
    // NEW: Handle Back to List
    handleBackToList: function(component, event, helper) {
        component.set("v.showDetailedView", false);
        component.set("v.costSheetDetails", {});
        component.set("v.paymentSchedules", []);
        
        // ✅ Reset selected checkboxes
        let filteredRecords = component.get("v.filteredRecords") || [];
        filteredRecords.forEach(function(rec) {
            rec.selected = false;
        });
        
        // ✅ Reset component attributes
        component.set("v.filteredRecords", filteredRecords);
        component.set("v.selectedRecords", []);
        component.set("v.selectAll", false);
        component.set("v.hideActionColumn", false);
    }
    
});