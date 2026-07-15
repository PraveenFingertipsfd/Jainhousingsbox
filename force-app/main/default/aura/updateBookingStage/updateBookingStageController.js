({
    doInit: function (component, event, helper) {
        var action = component.get("c.getupdatedStage");
        action.setParams({ recordId: component.get("v.recordId") });
        action.setCallback(this, function (res) {
            if (res.getState() === "SUCCESS") {
                var result = res.getReturnValue();
                component.set("v.currentStage", result.StageName);
                
                // Process Sale Agreement files
                if (result.SaleAgreementFiles) {
                    result.SaleAgreementFiles.forEach(element => 
                        console.log(element.SystemModstamp = new Date(element.SystemModstamp).toLocaleDateString('en-GB')));
                    component.set("v.SaleAgreement", result.SaleAgreementFiles);
                }
                
                // Process Sale Deed files
                if (result.SaleDeedFiles) {
                    result.SaleDeedFiles.forEach(element => 
                        console.log(element.SystemModstamp = new Date(element.SystemModstamp).toLocaleDateString('en-GB')));
                    component.set("v.SaleDeed", result.SaleDeedFiles);
                }
                
                // Set initial file upload status
                helper.checkFileUploadStatus(component);
                
                /*
                result.SaleAgreementFiles.forEach(element => console.log(element.SystemModstamp=new Date(element.SystemModstamp).toLocaleDateString('en-GB')));
                component.set("v.SaleAgreement",result.SaleAgreementFiles); 
                
                if (result.SaleAgreementFiles && result.SaleAgreementFiles.length > 0) {
                    component.set("v.fileUploaded", true);
                } else {
                    component.set("v.fileUploaded", false);
                }*/
            }
        });
        $A.enqueueAction(action);
    },
    
    doInit1: function (component, event, helper) {
        var action = component.get("c.getStage");
        action.setParams({ recordId: component.get("v.recordId") });
        action.setCallback(this, function (res) {
            if (res.getState() === "SUCCESS") {
                component.set("v.currentStage", res.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    
    handleStageChange: function(component, event, helper) {
        try {
            // 1. Get the newly selected stage value
            var selectedStage = event.getSource().get("v.value");
            
            // 2. Update current stage in component state
            component.set("v.currentStage", selectedStage);
            
            // 3. Clear all previous error messages
            component.set("v.errorMessage", "");
            
            // 4. Reset file upload status if NOT changing to 'Sale Agreement Execution Completed'
            if (selectedStage !== 'Sale Agreement Execution Completed' && selectedStage !== 'Registration Completed') {
                component.set("v.fileUploaded", false);
                component.set("v.fileUploadError", "");
                
                // Debug log
                console.log('Reset file upload status for stage:', selectedStage);
            }
            
            // 5. Additional debug logging
            console.log('Stage changed to:', selectedStage, 
                        'File upload status:', component.get("v.fileUploaded"));
            
        } catch (e) {
            // 6. Comprehensive error handling
            console.error('Error in handleStageChange:', e);
            
            // 7. User-friendly error feedback
            component.set("v.errorMessage", "Failed to change stage. Please try again.");
            
            // 8. Log to Salesforce monitoring if available
            if (window.console && window.console.error) {
                window.console.error('Stage Change Error:', e.stack);
            }
        }
    },

    /* working code 
    handleStageChange: function (component, event, helper) {
        var selectedStage = event.getSource().get("v.value");
        component.set("v.currentStage", selectedStage);
        component.set("v.errorMessage", "");
        
        // Reset file upload status if stage changes
        if (newStage !== 'Sale Agreement Execution Completed') {
            component.set("v.fileUploaded", false);
            component.set("v.fileUploadError", "");
        }
    }, */
    
/*
    handleSubmit: function (component, event, helper) {
        component.set("v.isProcessing", true);
        var stage = component.get("v.currentStage");

        if (stage === "Agreement") {
            event.preventDefault(); // stop default submit

            // Get form fields
            var fields = event.getParam("fields");
            if (!fields.Sale_Agreement_Date__c) {
                component.set("v.isProcessing", false);
                component.set("v.errorMessage", "Sale Agreement Date is required.");
                return;
            }

            // Validate 10% Collected
            var action = component.get("c.checkTenPercentCollected");
            action.setParams({ recordId: component.get("v.recordId") });
            action.setCallback(this, function (res) {
                if (res.getState() === "SUCCESS") {
                    var isCollected = res.getReturnValue();
                    if (isCollected) {
                        fields.Stage__c = "Agreement";
                        fields.Sale_Agreement_Status__c = "Approved";
                        component.find("editForm").submit(fields);
                    } else {
                        component.set("v.isProcessing", false);
                        helper.showToast("Error", "10% amount not collected", "error");
                    }
                } else {
                    component.set("v.isProcessing", false);
                    helper.showToast("Error", "Server error", "error");
                }
            });
            $A.enqueueAction(action);
        }
    },*/
    
    /* working one 
    handleSubmit: function (component, event, helper) {
        component.set("v.isProcessing", true);
        var stage = component.get("v.currentStage");
        
        console.log('handleSubmit called, stage:', stage);
        
        if (stage === "Agreement") {
            event.preventDefault();
            var fields = event.getParam("fields");
            
             console.log('Fields on submit:', fields);
            
            if (!fields.Sale_Agreement_Date__c) {
                component.set("v.isProcessing", false);
                component.set("v.errorMessage", "Sale Agreement Date is required.");
                console.warn("Sale Agreement Date missing");
                return;
            }
            
            component.set("v.saleAgreementDate", fields.Sale_Agreement_Date__c);

            console.log('saleAgreementDate', fields.Sale_Agreement_Date__c);
            
            var action = component.get("c.checkTenPercentCollected");
            action.setParams({ recordId: component.get("v.recordId") });
            action.setCallback(this, function (res) {
                console.log("checkTenPercentCollected response:", res.getState());
                if (res.getState() === "SUCCESS") {
                    var isCollected = res.getReturnValue();
                    console.log("isCollected:", isCollected);
                    if (isCollected) {
                        fields.Stage__c = "Agreement";
                        fields.Sale_Agreement_Status__c = "Approved";
                        component.find("editForm").submit(fields);
                    } else {
                        component.set("v.isProcessing", false);
                        component.set("v.showApprovalModal", true); // Show approval modal instead of toast
                    }
                } else {
                    component.set("v.isProcessing", false);
                    helper.showToast("Error", "Server error", "error");
                    console.error("Apex call failed:", res.getError());
                }
            });
            $A.enqueueAction(action);
        }
    }, */
    
    uploadFinished : function(component, event, helper) { 
        var sectionName=event.getSource().get('v.name');   
        var filesData=event.getParam("files");
        var fileIdArray=[];
        for(var i=0;i<filesData.length;i++)
        {	
            fileIdArray.push(filesData[i].documentId);
        }
        helper.UpdateDocument(component, event,helper,fileIdArray,sectionName);
       /* for(var i=0;i<10;i++){
            helper.getUploadedFiles(component, event,i); 
        }*/
         
        // Refresh both document lists after upload
        helper.getUploadedFiles(component, event, 'Sale Agreement');
        helper.getUploadedFiles(component, event, 'Sale Deed');
        
        helper.showToast('Success','Files have been uploaded successfully!','success');
    },
    
    
    /*handleSubmit: function(component, event, helper) {
        component.set("v.isProcessing", true);
        var stage = component.get("v.currentStage");
        var fields = event.getParam("fields");
        
        // Reset errors
        component.set("v.errorMessage", "");
        component.set("v.fileUploadError", "");
        
        console.log('Submission initiated for stage:', stage);
        
        // Prevent default form submission
        event.preventDefault();
        
        // VALIDATION LOGIC
        // 1. For "Agreement" stage (existing logic)
        if (stage === "Agreement") {
            if (!fields.Sale_Agreement_Date__c) {
                component.set("v.isProcessing", false);
                component.set("v.errorMessage", "Sale Agreement Date is required.");
                return;
            }
            
            component.set("v.saleAgreementDate", fields.Sale_Agreement_Date__c);
            
            // Check 10% payment collection
            var action = component.get("c.checkTenPercentCollected");
            action.setParams({ recordId: component.get("v.recordId") });
            action.setCallback(this, function(res) {
                if (res.getState() === "SUCCESS") {
                    if (res.getReturnValue()) {
                        fields.Stage__c = "Agreement";
                        fields.Sale_Agreement_Status__c = "Approved";
                        component.find("editForm").submit(fields);
                    } else {
                        component.set("v.isProcessing", false);
                        component.set("v.showApprovalModal", true);
                        component.set("v.approvalType", "Agreement"); // Track which approval we're handling
                    }
                } else {
                    component.set("v.isProcessing", false);
                    helper.showToast("Error", "Failed to check payment status", "error");
                }
            });
            $A.enqueueAction(action);
        } 
        
        // 2. For "Registration" stage (new validation)
        else if (stage === "Registration") {
            if (!fields.Registration_Date__c) {
                component.set("v.isProcessing", false);
                component.set("v.errorMessage", "Registration Date is required.");
                return;
            }
            
            component.set("v.registrationDate", fields.Registration_Date__c);
            
            // Check 90% payment collection
            var action = component.get("c.checkNinetyPercentCollected");
            action.setParams({ recordId: component.get("v.recordId") });
            action.setCallback(this, function(res) {
                if (res.getState() === "SUCCESS") {
                    if (res.getReturnValue()) {
                        fields.Stage__c = "Registration";
                        fields.Registration_Approval_Status__c = "Approved";
                        component.find("editForm").submit(fields);
                    } else {
                        component.set("v.isProcessing", false);
                        component.set("v.showApprovalModal", true);
                        component.set("v.approvalType", "Registration"); // Track which approval we're handling
                    }
                } else {
                    component.set("v.isProcessing", false);
                    helper.showToast("Error", "Failed to check payment status", "error");
                }
            });
            $A.enqueueAction(action);
        }
        
        // 3. For "Sale Agreement Execution Completed" stage (new validation)
        else if (stage === "Sale Agreement Execution Completed") {
            if (!component.get("v.fileUploaded")) {
                component.set("v.isProcessing", false);
                helper.showToast(
                    "Error", 
                    "Please upload the Sale Agreement document before updating the stage", 
                    "Error"
                );
                //component.set("v.fileUploadError", "Please upload the Sale Agreement document before proceeding.");
                return;
            }
            fields.Stage__c = stage;
            component.find("editForm").submit(fields);
        } 
        
        // 4. For all other stages
            else {
                fields.Stage__c = stage;
                component.find("editForm").submit(fields);
            }
    },*/
    
    handleSubmit: function(component, event, helper) {
        component.set("v.isProcessing", true);
        var stage = component.get("v.currentStage");
        var fields = event.getParam("fields");
        
        // Reset errors
        component.set("v.errorMessage", "");
        component.set("v.fileUploadError", "");
        
        event.preventDefault();
        
        // added by karthik 26/07
        var today = new Date();
        today.setHours(0, 0, 0, 0); // ignore time for comparison
        
        // Agreement stage validation
        if (stage === "Agreement") {
            
            /*
            if (!fields.Sale_Agreement_Date__c) {
                component.set("v.isProcessing", false);
                helper.showToast("Error", "Sale Agreement Date is required.", "error");
                return;
            }
            
            // Past date validation
            var saleDate = new Date(fields.Sale_Agreement_Date__c);
            if (saleDate < today) {
                component.set("v.isProcessing", false);
                helper.showToast("Error", "Sale Agreement Date cannot be in the past.", "error");
                return;
            }
            */
            component.set("v.saleAgreementDate", fields.Sale_Agreement_Date__c);
            helper.checkPaymentAndSubmit(component, fields, 'Agreement', 10);
        } 
        // Registration stage validation
        else if (stage === "Registration") {
            /*
            if (!fields.Registration_Date__c) {
                component.set("v.isProcessing", false);
                helper.showToast("Error", "Registration Date is required.", "error");
                return;
            }
            
            // Past date validation
            var regDate = new Date(fields.Registration_Date__c);
            if (regDate < today) {
                component.set("v.isProcessing", false);
                helper.showToast("Error", "Registration Date cannot be in the past.", "error");
                return;
            }
			*/
            
            component.set("v.registrationDate", fields.Registration_Date__c);
            helper.checkPaymentAndSubmit(component, fields, 'Registration', 90);
        }
        // Sale Agreement Execution Completed validation
            else if (stage === "Sale Agreement Execution Completed") {
                if (!fields.Sale_Agreement_Date__c) {
                    component.set("v.isProcessing", false);
                    helper.showToast("Error", "Sale Agreement Date is required.", "error");
                    return;
                }
                
                // Past date validation
                var saleDate = new Date(fields.Sale_Agreement_Date__c);
                if (saleDate < today) {
                    component.set("v.isProcessing", false);
                    helper.showToast("Error", "Sale Agreement Date cannot be in the past.", "error");
                    return;
                }
                var saleAgreementDocs = component.get("v.SaleAgreement");
                if (!saleAgreementDocs || saleAgreementDocs.length === 0) {
                    component.set("v.isProcessing", false);
                    helper.showToast(
                        "Error", 
                        "Please upload the Sale Agreement document before updating the stage", 
                        "error"
                    );
                    return;
                }
                fields.Stage__c = stage;
                component.find("editForm").submit(fields);
            }
        // Registration Completed validation
                else if (stage === "Registration Completed") {
                    if (!fields.Registration_Date__c) {
                        component.set("v.isProcessing", false);
                        helper.showToast("Error", "Registration Date is required.", "error");
                        return;
                    }
                    
                    // Past date validation
                    var regDate2 = new Date(fields.Registration_Date__c);
                    if (regDate2 < today) {
                        component.set("v.isProcessing", false);
                        helper.showToast("Error", "Registration Date cannot be in the past.", "error");
                        return;
                    }
                    
                    if (!fields.Document_Number__c) {
                        component.set("v.isProcessing", false);
                        helper.showToast("Error", "Document Number is required.", "error");
                        return;
                    }
                    
                    var saleDeedDocs = component.get("v.SaleDeed");
                    if (!saleDeedDocs || saleDeedDocs.length === 0) {
                        component.set("v.isProcessing", false);
                        helper.showToast(
                            "Error", 
                            "Please upload the Sale Deed document before updating the stage", 
                            "error"
                        );
                        return;
                    }
                    
                    fields.Stage__c = stage;
                    component.find("editForm").submit(fields);
                } 
        // All other stages
                    else {
                        fields.Stage__c = stage;
                        component.find("editForm").submit(fields);
                    }
    },
    
    handleFileUpload: function(component, event, helper) {
        // Called when photoUploadComponent2 completes upload
        component.set("v.fileUploaded", true);
        component.set("v.fileUploadError", "");
        console.log("File upload confirmed");
    },


    handleSuccess: function(component, event, helper) {
        component.set("v.isProcessing", false);
        
        // Close the modal first
        component.set("v.showModal", false);
         $A.get("e.force:closeQuickAction").fire();
        
        // Then show the toast
        helper.showToast(component, "Success", "Booking stage updated successfully", "success");
        $A.get("e.force:refreshView").fire();
        
        // Refresh the view after a slight delay to ensure toast is visible
        setTimeout(function() {
            $A.get('e.force:refreshView').fire();
        }, 1000);
    },

    handleError: function (component, event, helper) {
        component.set("v.isProcessing", false);
        var error = event.getParam("error");
        helper.showToast("Error", error.message || "Unknown error", "error");
    },

    handleCancel: function (component) {
        component.set("v.showModal", false);          
                // Close the modal
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
    },
     
    /*
    handleSendApproval: function(component, event, helper) {
        component.set("v.isProcessing", true);
        component.set("v.showApprovalModal", false);
        
        var action = component.get("c.submitForApproval");
        action.setParams({ 
            recordId: component.get("v.recordId"),
            saleAgreementDate: component.get("v.saleAgreementDate")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isProcessing", false);
            if (response.getState() === "SUCCESS") {
                helper.showToast("Success", "Approval submitted successfully", "success");
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else {
                helper.showToast("Error", "Failed to submit approval", "error");
            }
        });
        $A.enqueueAction(action);
    },*/
    
    handleSendApproval: function(component, event, helper) {
        component.set("v.isProcessing", true);
        component.set("v.showApprovalModal", false);
        //alert(component.get("v.registrationDate"));
    	//alert(component.get("v.recordId"));
        var actionName = component.get("v.approvalType") === "Registration" ? "c.submitRegistrationForApproval" : "c.submitForApproval";
        
        var dateVal = component.get("v.approvalType") === "Registration" ? component.get("v.registrationDate") : component.get("v.saleAgreementDate");
        
        var action = component.get(actionName);
        action.setParams({ 
            recordId: component.get("v.recordId"),
            dateField: dateVal   });
    
        
        
        action.setCallback(this, function(response) {
            component.set("v.isProcessing", false);
            if (response.getState() === "SUCCESS") {
                helper.showToast("Success", "Approval submitted successfully", "success");
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else {
                helper.showToast("Error", "Failed to submit approval", "error");
            }
        });
        $A.enqueueAction(action);
    },
    
    handleApprovalCancel: function(component, event, helper) {
        component.set("v.showApprovalModal", false);
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
    },
    
    
});