({
    doInit: function(component, event, helper) {      
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const inspectionId = urlParams.get('Id');
        component.set("v.recordId", inspectionId);
        helper.loadJointInspectionDetails(component, event, helper);
        helper.getPicklistValues(component, event, helper);
    },
    /*
    handleToggleChange: function(component, event, helper) {
        component.set("v.isChecked", event.target.checked);
    },*/
    gotoStep1: function(component, event, helper) {
        component.set("v.currentStep", "Step1");
    },
    
    gotoStep2: function(component, event, helper) {
        if (!helper.validateStep1(component)) return;
        component.set("v.currentStep", "Step2");
    },
    
    handleManualRatingChange: function(component, event, helper) {
        const selected = event.getSource();
        const [index, value] = selected.get("v.text").split("|");
        const fullName = selected.get("v.name");
        const group = fullName.split('_')[1];

        if (group === "feedbackQuestions") {
            let questions = component.get("v.feedbackQuestions");
            questions[parseInt(index)].value = value;
            component.set("v.feedbackQuestions", questions);
        } else if (group === "feedbackQuestions1") {
            let questions = component.get("v.feedbackQuestions1");
            questions[parseInt(index)].value = value;
            component.set("v.feedbackQuestions1", questions);
        } else if (group === "feedbackQuestions2") {
            let questions = component.get("v.feedbackQuestions2");
            questions[parseInt(index)].value = value;
            component.set("v.feedbackQuestions2", questions);
        }
    },
    

    
    handleToggleChange: function(component, event, helper) {
        const isChecked = event.target.checked;
        component.set("v.isChecked", isChecked);
        
        // Add default snag when toggled on
        if (isChecked) {
            const defaultSnag = {
                'sobjectType': 'Snag__c',
                'Joint_Inspection__c': component.get("v.recordId"),
                'Problem_Type__c': '',
                'Problem_Description__c': ''
            };
            component.set("v.snags", [defaultSnag]);
        } else {
            // Clear snags when toggled off
            component.set("v.snags", []);
        }
    },
    
    /*
    addSnag: function(component, event, helper) {
        const snags = component.get("v.snags");
        const newSnag = {
            'sobjectType': 'Snag__c',
            'Joint_Inspection__c': component.get("v.recordId"),
            'Problem_Type__c': '',
            'Problem_Description__c': ''
        };
        snags.push(newSnag);
        component.set("v.snags", snags);
    },*/
    
    addSnag: function(component, event, helper) {
        const snags = component.get("v.snags");
        const newSnag = {
            'sobjectType': 'Snag__c',
            'Joint_Inspection__c': component.get("v.recordId"),
            'Problem_Type__c': '',
            'Problem_Description__c': ''
        };
        snags.push(newSnag);
        component.set("v.snags", snags);
    },
    
    removeSnag: function(component, event, helper) {
        const index = event.getSource().get("v.name");
        const snags = component.get("v.snags");
        snags.splice(index, 1);
        component.set("v.snags", snags);
    },
    
    handleSubmit: function(component, event, helper) {
        helper.validateAndSubmit(component);
    },
    
    showSpinner: function(component) {
        component.set("v.spinner", true);
    },
    
    hideSpinner: function(component) {
        component.set("v.spinner", false);
    }
})