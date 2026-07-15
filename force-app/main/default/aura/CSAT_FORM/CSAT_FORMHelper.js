({
    loadBookingDetails: function(component, event, helper) {
        
        component.set("v.spinner", true);
        const action = component.get("c.getBookingDetails");
        action.setParams({ recId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            component.set("v.spinner", false);
            const state = response.getState();
            if (state === "SUCCESS") {
                const result = response.getReturnValue();
                if (result != null) {   
                    component.set("v.booking", result);
					component.set("v.IsResponded", result.Is_FB_Responded__c || false);
                } else {
                    console.error('No booking data returned');
                }
            } else if (state === "ERROR") {
                const errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
    },
    
    /*
    validateAndSubmit: function(component) {
        
        
        // Validate all radio buttons
        let allQuestionsAnswered = true;
        let missingQuestions = [];
        
        // Check feedbackQuestions (ratingOptions)
        let feedbackQuestions = component.get("v.feedbackQuestions");
        feedbackQuestions.forEach((question, index) => {
            if (!question.value) {
            allQuestionsAnswered = false;
            missingQuestions.push(question.label);
        }
                                  });
        
        // Check feedbackQuestions1 (ratingOptions1)
        let feedbackQuestions1 = component.get("v.feedbackQuestions1");
        feedbackQuestions1.forEach((question, index) => {
            if (!question.value) {
            allQuestionsAnswered = false;
            missingQuestions.push(question.label);
        }
                                   });
        
        // Check feedbackQuestions2 (ratingOptions2)
        let feedbackQuestions2 = component.get("v.feedbackQuestions2");
        feedbackQuestions2.forEach((question, index) => {
            if (!question.value) {
            allQuestionsAnswered = false;
            missingQuestions.push(question.label);
        }
                                   });
        
        if (!allQuestionsAnswered) {
            alert('Please answer all questions. Missing answers for: ' + missingQuestions.join(', '));
            return;
        }
        
        
        
        // Validate signature
        const signatureCmp = component.find("signaturePad");
        if (!signatureCmp || !signatureCmp.isSigned()) {
            alert('Signature is required');
            return;
        }
        
        // All validations passed - proceed with submission
        this.saveData(component, signatureCmp.getSignatureData());
    },*/
    
    validateAndSubmit: function(component) {
        // Validate all radio buttons
        let allQuestionsAnswered = true;
        let missingSections = {
            "Main Questions": [],
            "Yes/No Questions": [],
            "Booking Source": []
        };
        
        // Check feedbackQuestions (Main Questions)
        let feedbackQuestions = component.get("v.feedbackQuestions");
        feedbackQuestions.forEach((question, index) => {
            if (!question.value) {
            allQuestionsAnswered = false;
            missingSections["Main Questions"].push((index + 1) + ". " + question.label);
        }
                                  });
        
        // Check feedbackQuestions1 (Yes/No Questions)
        let feedbackQuestions1 = component.get("v.feedbackQuestions1");
        feedbackQuestions1.forEach((question, index) => {
            if (!question.value) {
            allQuestionsAnswered = false;
            missingSections["Yes/No Questions"].push((index + 1) + ". " + question.label);
        }
                                   });
        
        // Check feedbackQuestions2 (Booking Source)
        let feedbackQuestions2 = component.get("v.feedbackQuestions2");
        feedbackQuestions2.forEach((question, index) => {
            if (!question.value) {
            allQuestionsAnswered = false;
            missingSections["Booking Source"].push((index + 1) + ". " + question.label);
        }
                                   });
        
        if (!allQuestionsAnswered) {
            // Create formatted alert message
            let alertMessage = "Please answer all questions. Missing answers in:\n\n";
            
            // Add sections with missing answers
            for (let section in missingSections) {
                if (missingSections[section].length > 0) {
                    alertMessage += "➤ " + section + ":\n";
                    alertMessage += "   - " + missingSections[section].join("\n   - ") + "\n\n";
                }
            }
            
            alertMessage += "Please complete all questions before submitting.";
            alert(alertMessage);
            return;
        }
        
        // Validate new fields (optional - remove if not required)
        const encouragementFactors = component.get("v.encouragementFactors");
        const desiredImprovements = component.get("v.desiredImprovements");
        
        if ((!encouragementFactors || encouragementFactors.trim() === '') || 
            (!desiredImprovements || desiredImprovements.trim() === '')) {
            alert('Please provide responses for both additional feedback questions');
            return;
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
        
        // Prepare all responses
        let allResponses = [];
        
        // Add feedbackQuestions responses
        let feedbackQuestions = component.get("v.feedbackQuestions");
        feedbackQuestions.forEach(question => {
            allResponses.push({
                field: question.field,
                value: question.value
            });
        });
        
        // Add feedbackQuestions1 responses
        let feedbackQuestions1 = component.get("v.feedbackQuestions1");
        feedbackQuestions1.forEach(question => {
            allResponses.push({
                field: question.field,
                value: question.value
            });
        });
        
        // Add feedbackQuestions2 responses
        let feedbackQuestions2 = component.get("v.feedbackQuestions2");
        feedbackQuestions2.forEach(question => {
            allResponses.push({
                field: question.field,
                value: question.value
            });
        });
        
        const action = component.get("c.saveFeedback");
        action.setParams({
            bookingId: component.get("v.recordId"),
            responses: allResponses,
            signatureData: signatureData,
            encouragementFactors: component.get("v.encouragementFactors"),
            desiredImprovements: component.get("v.desiredImprovements")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.spinner", false);
            const state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.IsResponded", true);
            } else if (state === "ERROR") {
                const errors = response.getError();
                let errorMessage = 'Unknown error';
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                }
                alert('Error saving feedback: ' + errorMessage);
            }
        });
        
        $A.enqueueAction(action);


        
        /*
        const booking = {
            'sobjectType': 'Booking__c',
            'Id': component.get("v.recordId"),
            //'Customer_Comments__c': component.get("v.CusComments"),
            //'CSR_Responded_Date__c': new Date().toISOString(),
            //'Is_CSR_Responded__c': true
        };
        
        const action = component.get("c.saveBookingWithSignature");
        action.setParams({
            booking: booking,
            signatureData: signatureData
        });
        
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.IsResponded", true);
            } else if (state === "ERROR") {
                const errors = response.getError();
                console.error(errors);
            }
            component.set("v.spinner", false);
        });
        
        $A.enqueueAction(action);
        
        */
    }    
})