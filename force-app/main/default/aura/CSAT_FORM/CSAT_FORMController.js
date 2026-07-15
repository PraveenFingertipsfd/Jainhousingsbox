({
    doInit: function(component, event, helper) {     
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const bookingId = urlParams.get('Id');
        component.set("v.recordId", bookingId);
        helper.loadBookingDetails(component, event, helper);
        
        
    },
    
    handleSubmit: function(component, event, helper) {
        helper.validateAndSubmit(component);
    },
    
    showSpinner: function(component) {
        component.set("v.spinner", true);
    },
    
    hideSpinner: function(component) {
        component.set("v.spinner", false);
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
        } 
        else if (group === "feedbackQuestions1") {
            let questions = component.get("v.feedbackQuestions1");
            questions[parseInt(index)].value = value;
            component.set("v.feedbackQuestions1", questions);
        }
            else if (group === "feedbackQuestions2") {
                let questions = component.get("v.feedbackQuestions2");
                questions[parseInt(index)].value = value;
                component.set("v.feedbackQuestions2", questions);
            }
    }

    /*
	handleManualRatingChange: function(component, event, helper) {
        const selected = event.getSource();
        const [index, value] = selected.get("v.text").split("|");
        const group = selected.get("v.name").split("_")[1]; // Get the question group
        
        console.log(group);
        
        if (group === "feedbackQuestions") {
            let questions = component.get("v.feedbackQuestions");
            questions[parseInt(index)].value = value;
            component.set("v.feedbackQuestions", questions);
        } 
        else if (group === "feedbackQuestions1") {
            let questions = component.get("v.feedbackQuestions1");
            questions[parseInt(index)].value = value;
            component.set("v.feedbackQuestions1", questions);
        }
        else if (group === "feedbackQuestions2") {
            let questions = component.get("v.feedbackQuestions2");
            questions[parseInt(index)].value = value;
            component.set("v.feedbackQuestions2", questions);
        }
    }*/
    
    /*
    handleManualRatingChange: function(component, event, helper) {
        const selected = event.getSource();
        const [index, value] = selected.get("v.text").split("|");
        
        let questions = component.get("v.feedbackQuestions");
        questions[parseInt(index)].value = value;
        component.set("v.feedbackQuestions", questions);
        
        let questions1 = component.get("v.feedbackQuestions1");
        questions1[parseInt(index)].value = value;
        component.set("v.feedbackQuestions1", questions1);
        
        let questions2 = component.get("v.feedbackQuestions2");
        questions2[parseInt(index)].value = value;
        component.set("v.feedbackQuestions2", questions2);
    }*/
    
    
})