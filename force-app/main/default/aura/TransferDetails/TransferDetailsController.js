({
    doInit : function(component, event, helper) {
        /*var action=component.get("c.getTransferRecordDetails");  
        action.setParams({'recId':  component.get('v.recordId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var tranferRec = response.getReturnValue();
                component.set('v.trnasferRecord',tranferRec);
            }
        });
        $A.enqueueAction(action);*/
    },
    closeModel: function(component, event, helper) {
        
        $A.get('e.force:closeQuickAction').fire();
        $A.get('e.force:refreshView').fire();
    },
    handleCheckboxChange: function(component, event, helper) {
        // Get the checkbox value
        let isChecked = event.getSource().get("v.checked");
        component.set('v.isSecondary', isChecked);
        console.log('isChecked: ' + isChecked);
        
        // If checkbox is checked, call Apex to fetch secondary applicant details
        if (isChecked) {
            let action = component.get("c.getSecondaryApplicantDetails");
            let bookingId = component.get("v.recordId");
            
            // Pass the bookingId to Apex
            action.setParams({ bookingId: bookingId });
            
            // Set up the callback
            action.setCallback(this, function(response) {
                let state = response.getState();
                console.log('Response State: ' + state);
                
                if (state === "SUCCESS") {
                    let existingBooking = component.get("v.Booking");
                    let secondaryApplicantDetails = response.getReturnValue();
                    
                    if (secondaryApplicantDetails) {
                        console.log('secondaryApplicantDetails: ' + JSON.stringify(secondaryApplicantDetails));
                        
                        // Only update the fields if the secondaryApplicantDetails contains non-null/defined values
                        existingBooking.salutation_Applicant2__c = secondaryApplicantDetails.salutation_Applicant2__c || existingBooking.salutation_Applicant2__c;
                        existingBooking.Second_Applicant_Name__c = secondaryApplicantDetails.Second_Applicant_Name__c || existingBooking.Second_Applicant_Name__c;
                        existingBooking.Date_of_birth_Applicant2__c = secondaryApplicantDetails.Date_of_birth_Applicant2__c || existingBooking.Date_of_birth_Applicant2__c;
                        existingBooking.Mobile_Primary1__c = secondaryApplicantDetails.Mobile_Primary1__c || existingBooking.Mobile_Primary1__c;
                        existingBooking.Email2__c = secondaryApplicantDetails.Email2__c || existingBooking.Email2__c;
                        existingBooking.Nationality_Applicant2__c = secondaryApplicantDetails.Nationality_Applicant2__c || existingBooking.Nationality_Applicant2__c;
                        existingBooking.Relation_Details_Applicant2__c = secondaryApplicantDetails.Relation_Details_Applicant2__c || existingBooking.Relation_Details_Applicant2__c;
                        existingBooking.Son_Daughter_Wife_of1__c = secondaryApplicantDetails.Son_Daughter_Wife_of1__c || existingBooking.Son_Daughter_Wife_of1__c;
                        existingBooking.Passport_Aadhar_1__c = secondaryApplicantDetails.Passport_Aadhar_1__c || existingBooking.Passport_Aadhar_1__c;
                        existingBooking.Aadhaar_Number1__c = secondaryApplicantDetails.Aadhaar_Number1__c || existingBooking.Aadhaar_Number1__c;
                        existingBooking.Pan_Number_Applicant2__c = secondaryApplicantDetails.Pan_Number_Applicant2__c || existingBooking.Pan_Number_Applicant2__c;
                        existingBooking.Occupation1__c = secondaryApplicantDetails.Occupation1__c || existingBooking.Occupation1__c;
                        existingBooking.Name_of_Company1__c = secondaryApplicantDetails.Name_of_Company1__c || existingBooking.Name_of_Company1__c;
                        existingBooking.Designation1__c = secondaryApplicantDetails.Designation1__c || existingBooking.Designation1__c;
                        existingBooking.Anniverssary_Date1__c = secondaryApplicantDetails.Anniverssary_Date1__c || existingBooking.Anniverssary_Date1__c;
                        existingBooking.Communication_address1__c = secondaryApplicantDetails.Communication_address1__c || existingBooking.Communication_address1__c;
                        existingBooking.Permanent_Address1__c = secondaryApplicantDetails.Permanent_Address1__c || existingBooking.Permanent_Address1__c;
                        
                        // Set the updated Booking object back to the component
                        component.set("v.Booking", existingBooking);
                    } else {
                        console.error('No secondary applicant details returned from Apex.');
                    }
                } else if (state === "ERROR") {
                    let errors = response.getError();
                    console.error('Error: ', errors);
                }
            });
            
            // Enqueue the action
            $A.enqueueAction(action);
        } else {
            console.log('isUnchecked');
            let existingBooking = component.get("v.Booking");
            
            // If checkbox is unchecked, clear secondary applicant fields
            existingBooking.salutation_Applicant2__c = null;
            existingBooking.Second_Applicant_Name__c = null;
            existingBooking.Date_of_birth_Applicant2__c = '';
            existingBooking.Mobile_Primary1__c = '';
            existingBooking.Email2__c = '';
            existingBooking.Nationality_Applicant2__c = '';
            existingBooking.Relation_Details_Applicant2__c = '';
            existingBooking.Son_Daughter_Wife_of1__c = '';
            existingBooking.Passport_Aadhar_1__c = '';
            existingBooking.Aadhaar_Number1__c = '';
            existingBooking.Pan_Number_Applicant2__c = '';
            existingBooking.Occupation1__c = '';
            existingBooking.Name_of_Company1__c = '';
            existingBooking.Designation1__c = '';
            existingBooking.Anniverssary_Date1__c = '';
            existingBooking.Communication_address1__c = '';
            existingBooking.Permanent_Address1__c = '';
            
            // Set the updated Booking object back with cleared secondary fields
            component.set("v.Booking", existingBooking);
        }
    },
    
    saveData : function(component, event, helper) {
        let isAllValid = component.find('field').reduce(function(isValidSoFar, inputCmp){
            inputCmp.showHelpMessageIfInvalid();
            return isValidSoFar && inputCmp.checkValidity();
        },true);
        console.log('saveData1 ');
        if(isAllValid == true){
            console.log('saveData2 ');
            // Get the field values
            let booking = component.get("v.Booking");
            console.log('saveData2 ');
            let bookingid = component.get("v.recordId");
            console.log('saveData2 ');
            let secondaryvalue = component.get('v.isSecondary');
            console.log('saveData2 ');
            // Call the Apex controller method to save the data
            let action = component.get("c.saveTransfer");
            action.setParams({ booking: booking, recordId: bookingid,isSecondaryApplicantSame:secondaryvalue});
            
            // Set up the callback
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === "SUCCESS") {
                    console.log('saveData3 ');
                    // If save was successful, set isSaved to true to hide the form                    
                    // Show success toast
                    helper.showToast("Success", "Transfer details successfully saved.", "success");
                    
                    $A.get('e.force:closeQuickAction').fire();
                    $A.get('e.force:refreshView').fire();
                } else {
                    // Handle error and show error toast
                    let errors = response.getError();
                    let message = "Unknown error"; // Default error message
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        message = errors[0].message;
                    }
                    helper.showToast("Error", message, "error");
                    console.error(errors);
                }
            });
            
            // Enqueue the action to call the Apex controller
            $A.enqueueAction(action);
        }else{
            helper.showToast("Error", 'Please fill all the required fields', "error");
        }
    },
})