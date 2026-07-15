({
    
    getPicklistValues: function(component) {
        var action = component.get("c.getPicklistValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var picklistValues = response.getReturnValue();
                //console.log('Picklist values:', picklistValues); // Debug log
                component.set("v.problems", picklistValues.problems);
            }
        });
        $A.enqueueAction(action);
    },
    
    /*
    loadJointInspectionDetails: function(component, event, helper) {
        component.set("v.spinner", true);
        //alert(component.get("v.recordId"));
        const action = component.get("c.getJointInspectionDetails");
        action.setParams({ recId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            component.set("v.spinner", false);
            const state = response.getState();
            if (state === "SUCCESS") {
                const result = response.getReturnValue();
                if (result != null) {
                    component.set("v.jointInspection", result);
                    component.set("v.IsResponded", result.Is_CSR_Responded__c || false);
                } else {
                    console.error('No inspection data returned');
                    alert('No inspection details found for this ID');
                }
            } else if (state === "ERROR") {
                const errors = response.getError();
                if (errors && errors.length > 0) {
                    console.error('Error message:', errors[0].message);
                    alert('Error: ' + errors[0].message);
                } else {
                    console.error('Unknown error');
                    alert('An unknown error occurred');
                }
            }
        });
        
        $A.enqueueAction(action);
    },*/
    
    loadJointInspectionDetails: function(component, event, helper) {
        component.set("v.spinner", true);
        const action = component.get("c.getJointInspectionDetails");
        action.setParams({ recId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            component.set("v.spinner", false);
            const state = response.getState();
            if (state === "SUCCESS") {
                const result = response.getReturnValue();
                if (result != null) {
                    component.set("v.jointInspection", result);
                    const isResponded = result.Is_CSR_Responded__c || false;
                    component.set("v.IsResponded", isResponded);
                    
                    // Clear form fields if already responded
                    if (isResponded) {
                        component.set("v.snags", []);
                        component.set("v.isChecked", false);
                        component.set("v.CusComments", "");
                    }
                } else {
                    console.error('No inspection data returned');
                }
            } else if (state === "ERROR") {
                const errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
    },
    
    validateStep1: function(component) {
        let allAnswered = true;
        let sections = [
            { name: "Main Questions", list: component.get("v.feedbackQuestions") },
            { name: "Yes/No Questions", list: component.get("v.feedbackQuestions1") },
            { name: "Booking Source", list: component.get("v.feedbackQuestions2") }
        ];
        let missing = [];

        sections.forEach(section => {
            section.list.forEach(q => {
                if (!q.value) {
                    allAnswered = false;
                    missing.push(`➤ ${section.name}: ${q.label}`);
                }
            });
        });

        const encouragementFactors = component.get("v.encouragementFactors");
        const desiredImprovements = component.get("v.desiredImprovements");

        if (!encouragementFactors || encouragementFactors.trim() === '' ||
            !desiredImprovements || desiredImprovements.trim() === '') {
            allAnswered = false;
            missing.push("➤ Additional feedback questions are mandatory");
        }

        if (!allAnswered) {
            alert("Please complete all required fields before continuing:\n\n" + missing.join("\n"));
        }

        return allAnswered;
    },
    
    validateAndSubmit: function(component) {
        // Validate comments
        const comments = component.get("v.CusComments");
        if (!comments || comments.trim() === '') {
            alert('Please enter comments');
            return;
        }
        
        // Validate snags if toggle is enabled
        const isChecked = component.get("v.isChecked");
        const snags = component.get("v.snags");
        
        if (isChecked) {
            if (snags.length === 0) {
                alert('Please add at least one snag when issues are present');
                return;
            }
            
            for (let i = 0; i < snags.length; i++) {
                if (!snags[i].Problem_Type__c) {
                    alert(`Please select Problem Type for Snag ${i + 1}`);
                    return;
                }
                if (!snags[i].Problem_Description__c || snags[i].Problem_Description__c.trim() === '') {
                    alert(`Please enter Problem Description for Snag ${i + 1}`);
                    return;
                }
            }
        }
        
        // Validate signature
        const signatureCmp = component.find("signaturePad");
        if (!signatureCmp || !signatureCmp.isSigned()) {
            alert('Signature is required');
            return;
        }
        
        // All validations passed - proceed with submission
        this.saveData(component, signatureCmp.getSignatureData());
    },
    
    saveData: function(component, signatureData) {
        component.set("v.spinner", true);
        
        const jointInspection = {
            'sobjectType': 'Joint_Inspection__c',
            'Id': component.get("v.recordId"),
            'Customer_Comments__c': component.get("v.CusComments"),
            //'Is_Form_Responded__c': true,
            //'Approval_Status__c': 'Customer Approved',
            'CSR_Responded_Date__c': new Date().toISOString(),
            'Is_CSR_Responded__c': true  // Make sure this is set
        };
        
        let responses = [];
        ["feedbackQuestions", "feedbackQuestions1", "feedbackQuestions2"].forEach(section => {
            const questions = component.get(`v.${section}`);
        questions.forEach(q => {responses.push({field: q.field,value: q.value});});	
		});
        
        const action = component.get("c.saveInspectionWithSnags");
        action.setParams({
            inspection: jointInspection,
            snags: component.get("v.isChecked") ? component.get("v.snags") : [], // Only pass snags if toggle was on
            signatureData: signatureData,
            responses: responses,
            encouragementFactors: component.get("v.encouragementFactors"),
            desiredImprovements: component.get("v.desiredImprovements")
        });
        
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                // Clear form state
                component.set("v.IsResponded", true);
                component.set("v.isChecked", false);
                component.set("v.snags", []);
                component.set("v.CusComments", "");
            } else if (state === "ERROR") {
                const errors = response.getError();
                console.error(errors);
            }
            component.set("v.spinner", false);
        });
        
        $A.enqueueAction(action);
    }    
    
    /*
    saveData: function(component, signatureData) {
        component.set("v.spinner", true);
        
        const jointInspection = {
            'sobjectType': 'Joint_Inspection__c',
            'Id': component.get("v.recordId"),
            //'Customer_Comments__c': component.get("v.CusComments"),
            'Is_CSR_Responded__c': true
            //'Approval_Status__c': 'Customer Approved'
        };
        
        const action = component.get("c.saveInspectionWithSnags");
        action.setParams({
            inspection: jointInspection,
            snags: component.get("v.snags"),
            signatureData: signatureData
        });
        
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.IsResponded", true);
            } else if (state === "ERROR") {
                const errors = response.getError();
                //alert('Error saving data: ' + (errors[0]?.message || 'Unknown error'));
                console.error(errors);
            }
            component.set("v.spinner", false);
        });
        
        $A.enqueueAction(action);
    }*/
})