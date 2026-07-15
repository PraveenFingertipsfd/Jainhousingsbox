({
    getPicklistValues: function(component) {
        var action = component.get("c.getPicklistValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var picklistValues = response.getReturnValue();
                component.set("v.banks", picklistValues.banks);
            }
        });
        $A.enqueueAction(action);
    },
    
    getCostSheetdetail : function(component, event, helper) {
        var Bk = component.get("v.Booking");
        
        var action = component.get("c.GetCostSheet");
        action.setParams({  recordId : component.get("v.recordId"),
                          BkreqId : component.get("v.BkReqId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var records =response.getReturnValue();
                component.set('v.costSheet',records.CSRec);
                component.set('v.paymentScheduleList',records.PaySchLst);
                component.set('v.BookingReq',records.BkRqRec);
                component.set('v.IsResponded',records.IsFormResponded);
                
                component.set('v.Booking.First_Applicant_Name__c',records.BkRqRec.Customer_Name__c);
                component.set('v.Booking.Mobile_Primary1__c',records.BkRqRec.Mobile__c);
                component.set('v.Booking.Email1__c',records.BkRqRec.Email__c);
                component.set('v.Booking.PAN_Number1__c',records.BkRqRec.PAN_Number__c);
                component.set('v.Booking.Aadhaar_Number1__c',records.BkRqRec.Aadhaar_Number__c);
                
                component.set('v.Booking.Project1__c',records.CSRec.Project__c);
                component.set('v.Booking.Block__c',records.CSRec.Unit__r.Block1__c);
                component.set('v.Booking.Plot__c',records.CSRec.Unit__c);
                
            }
        });
        $A.enqueueAction(action);
    },
    
    saveRejectionData: function(component, event, helper) {
        component.set("v.spinner", true); 
        var CosSheet = component.get('v.costSheet');
        CosSheet.Customer_Comments__c = component.get('v.CusComments');
        CosSheet.Is_Form_Responded__c = true;
        CosSheet.Approval_Status__c = 'Customer Rejected';  
        
        var action = component.get("c.InsertRejectionCS");
        action.setParams({ CosSht : CosSheet });
        action.setCallback(this, function(response) {
            var state = response.getState();  
            if (state === "SUCCESS") {
                component.set('v.costSheet',CosSheet);
            }
            component.set("v.spinner", false);
            
        });
        $A.enqueueAction(action);
        
    },
    
    validationSave: function(component, event, helper) {
        let booking = component.get("v.Booking");
        
        function isEmpty(val){
            return val === null || val === undefined || val === '';
        }
        
        // Helper to show alert and exit early
        function fail(msg) {
            alert(msg);
            return false;
        }
        
        
        if (isEmpty(booking.Address_for_Registration__c)) return fail("Address for Registration is required.");
        if (isEmpty(booking.Funding_Type__c)) return fail("Funding Type is required.");
        /*if (booking.Funding_Type__c === 'Loan') {
            if (isEmpty(booking.Bank__c)) return fail("Bank Name is required for Loan funding.");
            if (isEmpty(booking.Applied_to_any_Bank__c)) return fail("Loan application status is required.");
        }*/
        
        // Always required fields
        if (isEmpty(booking.salutation_Applicant1__c)) return fail("Salutation is required.");
        if (isEmpty(booking.First_Applicant_Name__c)) return fail("Applicant Name is required.");
        if (isEmpty(booking.Gender__c)) return fail("Gender is required.");
        //if (isEmpty(booking.Date_of_Birth1__c)) return fail("Date of Birth is required.");
        if (isEmpty(booking.Date_of_Birth1__c) || (new Date().getFullYear() - new Date(booking.Date_of_Birth1__c).getFullYear() < 18)) return fail("Date of Birth is required and applicant must be at least 18 years old.");
        if (isEmpty(booking.Relation_Details_Applicant1__c)) return fail("Relation Type is required.");
        if (isEmpty(booking.Son_Daughter_Wife_of1__c) || !/^[a-zA-Z .]+$/.test(booking.Son_Daughter_Wife_of1__c.trim())) return fail("Son/Daughter/Wife of is required.");
        if (isEmpty(booking.Aadhaar_Number1__c) || !/^\d{12}$/.test(booking.Aadhaar_Number1__c)) return fail("Aadhaar must be 12 digits.");
        if (isEmpty(booking.PAN_Number1__c) || !/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(booking.PAN_Number1__c.toUpperCase())) return fail("PAN must be in format ABCDE1234F.");
        if (isEmpty(booking.Nationality__c)) return fail("Nationality is required.");
        if (booking.Nationality__c !== 'Resident' && (isEmpty(booking.Passport_Aadhar_1__c) || !/^[a-zA-Z0-9]{8}$/.test(booking.Passport_Aadhar_1__c))) return fail("Passport Number is required for Non-Residents");
        if (isEmpty(booking.Marital_Status__c)) return fail("Marital Status is required.");
        if (booking.Marital_Status__c === 'Married' && isEmpty(booking.Anniverssary_Date__c)) return fail("Anniversary Date is required for Married applicants.");
        if (isEmpty(booking.Mobile_Primary1__c) || !/^\d{10}$/.test(booking.Mobile_Primary1__c)) return fail("Mobile Number must be 10 digits.");
        if (!isEmpty(booking.Mobile_Alternate1__c) && !/^\d{10}$/.test(booking.Mobile_Alternate1__c)) return fail("Alternate Mobile must be 10 digits.");
        if (isEmpty(booking.Email1__c) && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(booking.Email1__c)) return fail("Email is required.");
        if (!isEmpty(booking.Alternate_Email1__c) && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(booking.Alternate_Email1__c)) return fail("Alternate Email is invalid.");
        if (isEmpty(booking.Profession1__c)) return fail("Profession is required.");
        if (booking.Profession1__c === 'Other' && isEmpty(booking.Other_Profession1__c)) return fail("Please specify your profession.");
        if (booking.Profession1__c === 'Salaried' && isEmpty(booking.Name_of_Company1__c)) return fail("Company Name is required.");
        if (booking.Profession1__c === 'Salaried' && isEmpty(booking.Designation1__c)) return fail("Job Designation is required.");
        if (booking.Profession1__c === 'Salaried' && isEmpty(booking.Company_Address__c)) return fail("Company Address is required.");
        if (isEmpty(booking.Communication_address1__c)) return fail("Correspondence Address is required.");
        if (isEmpty(booking.Permanent_Address1__c)) return fail("Permanent Address is required.");
        
        
        console.log("✅ All validations passed. Proceeding to save...");
        
        return true;
    },
    
    validateCoApplicants: function(component, event, helper) {
        let coApplicants = component.get("v.coApplicants");
        
        function isEmpty(val) {
            return val === null || val === undefined || val === '';
        }
        
        function fail(msg) {
            alert(msg);
            return false;
        }
        
        for (let i = 0; i < coApplicants.length; i++) {
            let co = coApplicants[i];
            let age = co.Date_of_Birth__c ? new Date().getFullYear() - new Date(co.Date_of_Birth__c).getFullYear() : null;
            
            if (isEmpty(co.Salutation__c)) return fail(`Salutation is required for Co-Applicant ${i + 1}`);
            if (isEmpty(co.Name)) return fail(`Name is required for Co-Applicant ${i + 1}`);
            if (isEmpty(co.Gender__c)) return fail(`Gender is required for Co-Applicant ${i + 1}`);
            if (isEmpty(co.Date_of_Birth__c) || age < 18) return fail(`DOB is required and must be 18+ for Co-Applicant ${i + 1}`);
            if (isEmpty(co.Relalation_Details__c)) return fail(`Relation Type is required for Co-Applicant ${i + 1}`);
            if (isEmpty(co.W_o_S_o_C_o_c__c) || !/^[a-zA-Z .]+$/.test(co.W_o_S_o_C_o_c__c.trim())) return fail(`Son/Daughter/Wife of is required for Co-Applicant ${i + 1}`);
            if (isEmpty(co.Aadhar_Number__c) || !/^\d{12}$/.test(co.Aadhar_Number__c)) return fail(`Valid Aadhaar Number - 12 digits is required for Co-Applicant ${i + 1}`);
            if (isEmpty(co.PAN_Number__c) || !/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(co.PAN_Number__c.toUpperCase())) return fail(`Valid PAN - ABCDE1234F is required for Co-Applicant ${i + 1}`);
            if (isEmpty(co.Country__c)) return fail(`Nationality is required for Co-Applicant ${i + 1}`);
            if (co.Country__c !== 'Resident' && (isEmpty(co.Passport_Aadhar_number__c) || !/^[a-zA-Z0-9]{8}$/.test(co.Passport_Aadhar_number__c))) {
                return fail(`Passport Number - 8 alphanumeric chars is required for Non-Resident Co-Applicant ${i + 1}`);
            }
            if (isEmpty(co.Marital_Status__c)) return fail(`Marital Status is required for Co-Applicant ${i + 1}`);
            if (co.Marital_Status__c === 'Married' && isEmpty(co.Anniverssary_Date__c)) return fail(`Anniversary Date is required for Married Co-Applicant ${i + 1}`);
            if (isEmpty(co.Contact_Number__c) || !/^\d{10}$/.test(co.Contact_Number__c)) return fail(`Valid Mobile Number - 10 digits is required for Co-Applicant ${i + 1}`);
            if (isEmpty(co.Email__c) || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(co.Email__c)) return fail(`Valid Email is required for Co-Applicant ${i + 1}`);
            if (!isEmpty(co.Alternate_Mobile__c) && !/^\d{10}$/.test(co.Alternate_Mobile__c)) return fail(`Alternate Mobile must be 10 digits for Co-Applicant ${i + 1}`);
            if (!isEmpty(co.Alternate_Email__c) && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(co.Alternate_Email__c)) return fail(`Alternate Email is invalid for Co-Applicant ${i + 1}`);
            if (isEmpty(co.Occupation__c)) return fail(`Profession is required for Co-Applicant ${i + 1}`);
            if (co.Occupation__c === 'Other' && isEmpty(co.Other_Profession__c)) return fail(`Profession details are required for 'Other' in Co-Applicant ${i + 1}`);
            if (co.Occupation__c === 'Salaried' && isEmpty(co.Name_of_Company__c)) return fail(`Company Name is required for Co-Applicant ${i + 1}`);
            if (co.Occupation__c === 'Salaried' && isEmpty(co.Designation__c)) return fail(`Desination are required in Co-Applicant ${i + 1}`);
            if (co.Occupation__c === 'Salaried' &&  isEmpty(co.Company_Address__c)) return fail(`Company Address is required for Co-Applicant ${i + 1}`);
            if (isEmpty(co.Address__c)) return fail(`Correspondence Address is required for Co-Applicant ${i + 1}`);
            if (isEmpty(co.Permenent_Address__c)) return fail(`Permanent Address is required for Co-Applicant ${i + 1}`);
            
        }
        
        console.log("✅ All Co-Applicants validated.");
        return true;
    },
    
    saveSubmissionDataval1: function(component, signatureData) {
        
        component.set("v.spinner", true); 
        
        var BkRec = component.get('v.Booking');
        var CosSheet = component.get('v.costSheet');
        var coApplicants = component.get('v.coApplicants');
        
        CosSheet.Customer_Comments__c = component.get('v.CusComments');
        CosSheet.Is_Form_Responded__c = true;
        CosSheet.Approval_Status__c = 'Customer Approved';  
        
        var action = component.get("c.InsertSubmissionCSwithSign");
        action.setParams({ CosSht : CosSheet,
                          Booking: BkRec,
                          coApplicants: coApplicants,
                          signatureData: signatureData});
        action.setCallback(this, function(response) {
            var state = response.getState();  
            if (state === "SUCCESS") {
                component.set('v.costSheet',CosSheet);
            }
            component.set("v.spinner", false);
            
        });
        $A.enqueueAction(action);
        
    },
    
     saveSubmissionDataval2: function(component, signatureData) {
        
        component.set("v.spinner", true); 
        
        var BkRec = component.get('v.Booking');
        var CosSheet = component.get('v.costSheet');
        var coApplicants = component.get('v.coApplicants');
        
        CosSheet.Customer_Comments__c = component.get('v.CusComments');
        CosSheet.Is_Form_Responded__c = true;
        CosSheet.Approval_Status__c = 'Customer Approved';  
        
        var fileData = component._fileData || {}; // ✅ Get the base64 file data
        
        var action = component.get("c.InsertSubmissionCSwithSignAndFiles");
        action.setParams({ CosSht : CosSheet,
                          Booking: BkRec,
                          coApplicants: coApplicants,
                          signatureData: signatureData,
                          //files: component.get('v.selectedFiles')});
                          uploadedFilesMap: fileData });   // ✅ Pass this to Apex
    
        action.setCallback(this, function(response) {
            var state = response.getState();  
            if (state === "SUCCESS") {
                component.set('v.costSheet',CosSheet);
            }
            component.set("v.spinner", false);
            
        });
        $A.enqueueAction(action);
        
    },
    
    saveSubmissionDataval: function(component, signatureData) {
        component.set("v.spinner", true);
        
        var BkRec = component.get('v.Booking');
        var CosSheet = component.get('v.costSheet');
        var coApplicants = component.get('v.coApplicants');
        
        CosSheet.Customer_Comments__c = component.get('v.CusComments');
        CosSheet.Is_Form_Responded__c = true;
        CosSheet.Approval_Status__c = 'Customer Approved';  
        
        // ✅ Get file data from Aura attribute
        var fileData = component.get("v.fileDataMap") || {};
        
        console.log("🧾 Final file data before submit:", fileData);
        
        var action = component.get("c.InsertSubmissionCSwithSignAndFiles");
        action.setParams({
            CosSht: CosSheet,
            Booking: BkRec,
            coApplicants: coApplicants,
            signatureData: signatureData,
            uploadedFilesMap: fileData
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.costSheet', CosSheet);
            } else {
                console.error("⚠️ Error:", response.getError());
            }
            component.set("v.spinner", false);
        });
        $A.enqueueAction(action);
    },

    validateKYCDocuments1: function(component) {
        var isValid = true;
        var selectedFiles = component.get("v.selectedFiles");
        var fileDataMap = component.get("v.fileDataMap");
        var nationality = component.get("v.Booking.Nationality__c");
        
        if(!selectedFiles.primaryAadhaar || !fileDataMap.primaryAadhaar) {
            alert("Aadhaar Card is required");
            isValid = false;
        }
        else if(!selectedFiles.primaryPAN || !fileDataMap.primaryPAN) {
            alert("PAN Card is required");
            isValid = false;
        }
            else if(!selectedFiles.primaryPhoto || !fileDataMap.primaryPhoto) {
                alert("Applicant Photo is required");
                isValid = false;
            }
                else if(nationality && nationality != 'Resident' && 
                        (!selectedFiles.primaryPassport || !fileDataMap.primaryPassport)) {
                    alert("Passport is required for non-Resident applicants");
                    isValid = false;
                }
        
        return isValid;
    },
    
    validateKYCDocuments: function(component) {
        var selectedFiles = component.get("v.selectedFiles");
        var fileDataMap = component.get("v.fileDataMap");
        var nationality = component.get("v.Booking.Nationality__c");
        
        if(!selectedFiles.primaryAadhaar || !fileDataMap.primaryAadhaar) {
            alert("Aadhaar Card is required");
            return false;
        }
        
        if(!selectedFiles.primaryPAN || !fileDataMap.primaryPAN) {
            alert("PAN Card is required");
            return false;
        }
        
        if(!selectedFiles.primaryPhoto || !fileDataMap.primaryPhoto) {
            alert("Applicant Photo is required");
            return false;
        }
        
        if(nationality && nationality != 'Resident' && 
           (!selectedFiles.primaryPassport || !fileDataMap.primaryPassport)) {
            alert("Passport is required for non-Resident applicants");
            return false;
        }
        
        return true;
    },

    
    showToast : function(message,type){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
    
    getFileIds: function(fileArray) {
        return fileArray ? fileArray.map(f => f.documentId) : [];
    }
    
    
})