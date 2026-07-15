({
    doInit : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString); 
        const recId = urlParams.get('Id');
        component.set("v.recordId",recId);
        
        // Initialize file storage attributes
        component.set("v.fileDataMap", {}); // For storing file data
        component.set("v.selectedFiles", {}); // For UI display of selected filenames
        
        var Bk = component.get("v.Booking");
        if (!Bk) {
            component.set("v.Booking", {
                'sobjectType': 'Booking__c',
                'Project1__c':'',
                'Block__c':'',
                'Plot__c':'',
                'Cost_Sheet__c':recId,
                'salutation_Applicant1__c': '',
                'First_Applicant_Name__c': '',
                'Gender__c': '',
                'Date_of_Birth1__c': '',
                'Marital_Status__c': '',
                'Anniverssary_Date__c': '',
                'Mobile_Primary1__c': '',
                'Email1__c': '',
                'Mobile_Alternate1__c': '',
                'Alternate_Email1__c': '',
                'PAN_Number1__c':'',
                'Aadhaar_Number1__c':'',
                'Passport_Aadhar_1__c':'',
                'Nationality__c':'',
                'Profession1__c':'',
                'Other_Profession1__c':'',
                'Communication_address1__c':'',
                'Permanent_Address1__c':'',
                'Relation_Details_Applicant1__c':'',
                'Son_Daughter_Wife_of1__c':'',
                'Name_of_Company1__c':'',
                'Designation1__c':'',
                'Company_Address__c':'',
                'Address_for_Registration__c':'',
                'Funding_Type__c':'',
                'Bank__c':'',
                'Applied_to_any_Bank__c':'',
                'Sales_Manager1__c':''
            });
        }
        
        helper.getCostSheetdetail(component,event,helper);   
        helper.getPicklistValues(component);
        
        // 🚀 New: Fetch Terms content from Apex
        var action = component.get("c.getTermsContent");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.termsContent", response.getReturnValue());
            } else {
                console.error("Failed to fetch Terms: ", response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
    clearFile: function(component, event, helper) {
        try {
            event.preventDefault();
            event.stopPropagation();
            
            // Get the file ID and input ID from button attributes
            let fileId = event.currentTarget.dataset.id;
            let inputId = event.currentTarget.dataset.input;
            
            // Clear from selectedFiles
            let selectedFiles = component.get("v.selectedFiles") || {};
            selectedFiles[fileId] = null;
            component.set("v.selectedFiles", selectedFiles);
            
            // Clear from fileDataMap
            let fileDataMap = component.get("v.fileDataMap") || {};
            fileDataMap[fileId] = null;
            component.set("v.fileDataMap", fileDataMap);
            
            // Reset the actual file input
            let fileInput = document.getElementById(inputId);
            if (fileInput) {
                fileInput.value = '';
            }
            
            console.log("Cleared file for:", fileId);
        } catch (err) {
            console.error("Error clearing file:", err);
            helper.showToast("Error clearing file", "error");
        }
    },
    
    handleNextKYC: function(component, event, helper) {
        //Validate Primary Applicant section
        if (!helper.validationSave(component, event, helper)) {
            return;
        }
        
        // Validate Co-Applicants section
        if (!helper.validateCoApplicants(component, event, helper)) {
            return;
        }
        
        // Show ONLY KYC Section (hide all others)
        component.set("v.Is_BookingFill_Section", false);  // Hide registration form
        component.set("v.Is_BookingPDF_Section", false);   // Hide cost sheet
        component.set("v.Is_KYC_Section", true);           // Show KYC section
        
        window.scrollTo({ top: 0, behavior: 'smooth' });   // Scroll to top
    },
    
    handleBackToForm : function(component, event, helper) {
        component.set("v.Is_KYC_Section", false);
        component.set("v.Is_BookingFill_Section", true);
        window.scrollTo({ top: 0, behavior: 'smooth' });
    },
    
    handleNext1: function(component, event, helper) {
        var CosSht = component.get('v.CusComments');
        if(CosSht ==''  || CosSht ==null || CosSht.trim() =='' || CosSht == undefined ){
            alert('Please Enter Comments');
            return;
        }
        component.set('v.Is_BookingFill_Section',true);
        window.scrollTo({ top: 0, behavior: 'smooth' });
    },
    
    // Agree & Continue
    handleNext: function(component, event, helper) {
        // No comment validation here
        component.set('v.Is_BookingFill_Section', true);
        window.scrollTo({ top: 0, behavior: 'smooth' });
    },
    
    openDisagreeModal : function(component, event, helper) {
        component.set("v.showInitialButtons", false);
        component.set("v.showDisagreeModal", true);
        component.set("v.showCSPS", false); // hide cost sheet & payment schedule
    },
    
    closeDisagreeModal : function(component, event, helper) {
        component.set("v.showDisagreeModal", false);
        component.set("v.showInitialButtons", true);
        component.set("v.showCSPS", true); // show cost sheet & payment schedule back
    },
    
    // Disagree → Submit
    submitDisagree : function(component, event, helper) {
        var comment = component.get("v.CusComments");
        if (!comment || comment.trim() === "") {
            alert("Please enter Comments before submitting.");
            return;
        }
        // Call your reject logic (existing method)
         helper.saveRejectionData(component, event, helper);
    },
    
    /*
    handleReject: function(component, event, helper) {
        var CosSht = component.get('v.CusComments');
        if(CosSht ==''  || CosSht ==null || CosSht.trim() =='' || CosSht == undefined ){
            alert('Please Enter Comments');
            return;
        }
         helper.saveRejectionData(component, event, helper);
       
    },*/
    
    handleBack:function(component, event, helper) {
        component.set('v.Is_BookingFill_Section',false);
        window.scrollTo({ top: 0, behavior: 'smooth' });
    },
    
    handleSubmit1 :function(component, event, helper){
        if(helper.validationSave(component, event, helper)){
            if(helper.validateCoApplicants(component, event, helper)){ 
               
                const signatureCmp = component.find("signaturePadCmp");
                if (signatureCmp && !signatureCmp.isSigned()) {
                    alert('Signature is required');
                }
                else{
                    const signatureDataUrl = signatureCmp.getSignatureData();
                    component.set("v.signatureData", signatureDataUrl);
                    helper.saveSubmissionDataval(component, signatureDataUrl);
                    
                }
                //component.set('v.Is_BookingPDF_Section',true);
            }
        }
    },
    
    handleSubmit2: function(component, event, helper) {
        /* 1. First validate form fields
        if(!helper.validationSave(component, event, helper)) {
            return;
        }*/
        
        
        /* 2. Validate co-applicants
        if(!helper.validateCoApplicants(component, event, helper)) {
            return;
        }*/
        
        // 3. Validate KYC documents (call via helper)
        if(!helper.validateKYCDocuments(component)) {
            return;
        }
        
        // Validate terms acceptance first
        if(!component.get("v.termsAccepted")) {
            helper.showToast("Please accept the Terms & Conditions", "error");
            return;
        }
        
        // 4. Check signature
        const signatureCmp = component.find("signaturePadCmp");
        if(!signatureCmp || !signatureCmp.isSigned()) {
            alert('Signature is required');
            return;
        }
        
        // All validations passed
        const signatureDataUrl = signatureCmp.getSignatureData();
        component.set("v.signatureData", signatureDataUrl);
        helper.saveSubmissionDataval(component, signatureDataUrl);
    },
    
    handleSubmit: function(component, event, helper) {
        try {
            // 1. Validate KYC documents first (most likely to fail)
            if(!helper.validateKYCDocuments(component)) {
                return; // Stop execution if validation fails
            }
            
            // 2. Validate terms acceptance
            if(!component.get("v.termsAccepted")) {
                alert("Please accept the Terms & Conditions");
                return;
            }
            
            // 3. Check signature
            const signatureCmp = component.find("signaturePadCmp");
            if(!signatureCmp || !signatureCmp.isSigned()) {
                alert("Signature Required");
                return;
            }
            
            // ✅ All validations passed - proceed with submission
            const signatureDataUrl = signatureCmp.getSignatureData();
            component.set("v.signatureData", signatureDataUrl);
            helper.saveSubmissionDataval(component, signatureDataUrl);
            
        } catch(err) {
            console.error("Submit error:", err);
            alert("An error occurred during submission");
        }
    },

    
    showTermsModal : function(component, event, helper) {
        event.preventDefault();
        event.stopPropagation();
        component.set("v.showTermsModal", true);
    },
    
    closeTermsModal : function(component, event, helper) {
        component.set("v.showTermsModal", false);
    },
    
    handleSign :function(component, event, helper){
        if(helper.validationSave(component, event, helper)){
            if(helper.validateCoApplicants(component, event, helper)){ 
                component.set('v.Is_BookingPDF_Section',true);
                
                window.setTimeout(function() {
                    let frame = component.find("vfFrame").getElement();
                    let booking = component.get("v.Booking");
                    let coApplicants = component.get("v.coApplicants");
                    
                    frame.contentWindow.postMessage({
                        bookingData: booking,
                        coApplicants: coApplicants
                    }, "*");
                }, 1500);
                
            }
        }
    },
    
    handleFileChange1 : function(component, event, helper) {
        let input = event.target;
        let auraId = input.getAttribute("data-id");
        let files = input.files;
        
        if (files.length > 0) {
            let file = files[0];
            let reader = new FileReader();
            
            reader.onload = function(e) {
                let base64 = e.target.result.split(',')[1];
                
                // Store file data
                if (!component._fileData) component._fileData = {};
                component._fileData[auraId] = {
                    fileName: file.name,
                    base64: base64
                };
                
                // Update UI with file name
                let selectedFiles = component.get("v.selectedFiles");
                selectedFiles[auraId] = file.name;
                component.set("v.selectedFiles", selectedFiles);
            };
            
            reader.readAsDataURL(file);
        }
    },
    
    handleFileChange2: function(component, event, helper) {
    try {
        // Get the file input element
        let fileInput = event.target;
        if (!fileInput) {
            console.error("File input element not found");
            return;
        }

        // Get the aura:id/data-id of the file input
        let fileId = fileInput.getAttribute("data-id");
        if (!fileId) {
            console.error("No data-id attribute found on file input");
            return;
        }

        // Get the selected files
        let files = fileInput.files;
        if (!files || files.length === 0) {
            console.log("No file selected");
            return;
        }

        let file = files[0];
        console.log("Processing file:", file.name, "for field:", fileId);

        // Read the file
        let reader = new FileReader();
        reader.onload = $A.getCallback(function(e) {
            try {
                let base64 = e.target.result.split(',')[1];
                
                // Update fileDataMap
                let fileDataMap = component.get("v.fileDataMap") || {};
                fileDataMap[fileId] = {
                    fileName: file.name,
                    base64: base64,
                    contentType: file.type
                };
                component.set("v.fileDataMap", fileDataMap);
                
                // Update selectedFiles for UI display
                let selectedFiles = component.get("v.selectedFiles") || {};
                selectedFiles[fileId] = file.name;
                component.set("v.selectedFiles", selectedFiles);
                
                console.log("Successfully stored file:", file.name);
            } catch (innerErr) {
                console.error("Error processing file:", innerErr);
                helper.showToast("Error processing file", "error");
            }
        });

        reader.onerror = $A.getCallback(function(error) {
            console.error("File reading error:", error);
            helper.showToast("Error reading file", "error");
        });

        reader.readAsDataURL(file);
    } catch (err) {
        console.error("File upload error:", err);
        helper.showToast("File upload failed", "error");
    }
},
    
    handleFileChange: function(component, event, helper) {
        try {
            // Get the file input element
            let fileInput = event.target;
            if (!fileInput) {
                console.error("File input element not found");
                return;
            }
            
            // Get the aura:id/data-id of the file input
            let fileId = fileInput.getAttribute("data-id");
            if (!fileId) {
                console.error("No data-id attribute found on file input");
                return;
            }
            
            // Get the selected files
            let files = fileInput.files;
            if (!files || files.length === 0) {
                console.log("No file selected");
                // Clear if user cancels selection
                let inputId = fileInput.id;
                if (inputId) {
                    $A.get("e.force:refreshView").fire();
                    document.getElementById(inputId).value = '';
                }
                return;
            }
            
            let file = files[0];
            console.log("Processing file:", file.name, "for field:", fileId);
            
            // Read the file
            let reader = new FileReader();
            reader.onload = $A.getCallback(function(e) {
                try {
                    let base64 = e.target.result.split(',')[1];
                    
                    // Update fileDataMap
                    let fileDataMap = component.get("v.fileDataMap") || {};
                    fileDataMap[fileId] = {
                        fileName: file.name,
                        base64: base64,
                        contentType: file.type,
                        lastModified: file.lastModified,
                        size: file.size
                    };
                    component.set("v.fileDataMap", fileDataMap);
                    
                    // Update selectedFiles for UI display
                    let selectedFiles = component.get("v.selectedFiles") || {};
                    selectedFiles[fileId] = file.name;
                    component.set("v.selectedFiles", selectedFiles);
                    
                    console.log("Successfully stored file:", file.name);
                } catch (innerErr) {
                    console.error("Error processing file:", innerErr);
                    helper.showToast("Error processing file", "error");
                }
            });
            
            reader.onerror = $A.getCallback(function(error) {
                console.error("File reading error:", error);
                helper.showToast("Error reading file", "error");
            });
            
            reader.readAsDataURL(file);
        } catch (err) {
            console.error("File upload error:", err);
            helper.showToast("File upload failed", "error");
        }
    },
    
    addCoApplicant: function(component, event, helper) {
        let coApplicants = component.get("v.coApplicants");
        
        let newCoApplicant = {
            'sobjectType': 'Co_Applicant__c',
            'Booking__c': '',
            'Salutation__c': '',
            'Name': '',
            'Contact_Number__c': '',
            'Email__c': '',
            'Country__c': '',
            'Relalation_Details__c': '',
            'W_o_S_o_C_o_c__c': '',
            'PAN_Number__c': '',
            'Aadhar_Number__c': '',
            'Passport_Aadhar_number__c': '',
            'Address__c': '',
            'Permenent_Address__c': '',
            'Date_of_Birth__c': '',
            'Anniverssary_Date__c': '',
            'Alternate_Mobile__c': '',
            'Alternate_Email__c': '',
            'Marital_Status__c': '',
            'Gender__c': '',
            'Occupation__c': '',
            'Other_Profession__c':'',
            'Name_of_Company__c':'',
            'Designation__c': '',
            'Company_Address__c':''
        };
        
        coApplicants.push(newCoApplicant);
        component.set("v.coApplicants", coApplicants);
    },

    
    removeCoApplicant: function(component, event, helper) {
        let index = parseInt(event.getSource().get("v.name"), 10);
        let coApplicants = component.get("v.coApplicants");
        coApplicants.splice(index, 1);
        component.set("v.coApplicants", coApplicants);
    },

    
    showSpinner: function(component, event, helper) {
        component.set("v.spinner", true); 
    },
    
    hideSpinner : function(component,event,helper){
        component.set("v.spinner", false);
    },
    
})