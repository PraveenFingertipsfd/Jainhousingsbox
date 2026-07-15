({
	doInit: function(component, event, helper) {
        let baseUrl = window.location.origin;
        component.set("v.baseUrl",baseUrl);
        //console.log('booking.Id '+booking.Id);
        let booking = component.get("v.booking");
        if (booking) {
            let action = component.get("c.getPaymentSchedules");
            action.setParams({ bookingId: booking.Id });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === "SUCCESS") {
                    //console.log('JSON'+ JSON.stringify(response.getReturnValue()));
                    component.set("v.data", response.getReturnValue());
                } else {
                    console.error("Error fetching data: ", response.getError());
                }
            });
            
            $A.enqueueAction(action);
        }
    },
    handleClosePopup : function(component, event, helper) {
		component.set("v.visible",false);
	},
    handleRadioSelection: function(component, event, helper) {
        const selectedIndex = parseInt(event.currentTarget.getAttribute('data-index'), 10);
        const selectedIndexId = event.currentTarget.getAttribute('value');
        const selectedMilestone = event.currentTarget.getAttribute('data-value');
       
        component.set("v.selectedIndexId", selectedIndexId);
        component.set("v.selectedMilestone", selectedMilestone);
        component.set("v.selectedIndex", selectedIndex);
    },
    handleGenerate: function(component, event, helper) {
        var baseUrl = component.get('v.baseUrl');
        var bookingval =  component.get('v.booking');
        var currentMilestone =  component.get('v.currentMilestone');
        var selectedIndexId =  component.get('v.selectedIndexId');
        var selectedMilestone = component.get('v.selectedMilestone');
        component.set("v.milestoneId",selectedIndexId);
        
        if(selectedIndexId){
            let url;
            var applicantNames = '';
            if (bookingval.salutation_Applicant1__c && bookingval.First_Applicant_Name__c) {
                applicantNames = bookingval.salutation_Applicant1__c + ' ' + bookingval.First_Applicant_Name__c;
            }
            var secondApplicantName = '';
            if (bookingval.Second_Applicant_Name__c && bookingval.Second_Applicant_Name__c.trim() !== '') {
                secondApplicantName = bookingval.salutation_Applicant2__c + ' ' + bookingval.Second_Applicant_Name__c;
            }
            if (secondApplicantName != '') {
                applicantNames += ' and ' + secondApplicantName;
            }
            let milestoneName = '';
            if(currentMilestone.Name){
                milestoneName = currentMilestone.Name;
            }
            let ProjectName='';
            if(bookingval.Project1__r.Name){
                ProjectName = bookingval.Project1__r.Name;
            }
            var defaultEmailContent = '<div style="color: black;"><strong>Dear ' + applicantNames + ',</strong></div><br/>'+'<div><strong>Greetings from Jain Housing!!!</strong><br/><br/>' +
                'We are pleased to inform you that the <strong>'+selectedMilestone+'</strong> for <strong>'+ ProjectName +'</strong> has been successfully completed as '+
                'per scheduled. In accordance with the agreed-upon schedule. Kindly ensure that the payment is made'+
                'within the stipulated timeframe of 7 days to avoid any delay in subsequent construction activities.<br/><br/>' +
                'If you have any questions or need further assistance, please do not hesitate to contact us.<br/><br/>' +
                'Thank you for choosing <strong>Jain Housing</strong>.<br/><br/>' +
                'Best regards,<br/>';
            if(bookingval.Project_Company__c == 'JAIN HOUSING'){
                defaultEmailContent += '<strong>Jain Housing</strong></div>'
                
                url = baseUrl + '/apex/DEMAND_LETTER_AARYA_CUSTOM?Id=' + bookingval.Id + '&PId=' + selectedIndexId;

            }
            component.set("v.emailContent", defaultEmailContent);
            component.set("v.vfPageUrl", url);
        }else{
            var toastEvent = $A.get("e.force:showToast");
            var type = 'error';
            toastEvent.setParams({
                "type": type,
                "title": type.charAt(0).toUpperCase() + type.slice(1), // Capitalize title
                "message": 'Please select a milestone',
                "duration": 10000
            });
            toastEvent.fire();
        }
        
    },
    handleCreateDemand: function(component, event, helper) {
        
        var selectedIndexId =  component.get('v.milestoneId');
        var emailContent = component.get("v.emailContent");
        var contentDocumentIds = component.get("v.filesIDS");
        if(selectedIndexId){
            let action = component.get("c.raiseDemand");
            action.setParams({
                "milestoneId": selectedIndexId,
                "demandEmailContent": emailContent,
                "documentIds": contentDocumentIds
            });
            
            // Set the callback function to handle the response from Apex
            action.setCallback(this, function(response) {
                var state = response.getState(); // Get the response state
                
                if (state === 'SUCCESS') {
                    console.log('here sucess');
                    // Retrieve the return value from the Apex method
                    var res_string = response.getReturnValue();
                    
                    // Close the quick action panel
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    
                    // Determine the toast type based on the response
                    var type = res_string === 'Demand Raise records created.' ? 'error' : 'success';
                    
                    // Show toast notification
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": type,
                        "title": type.charAt(0).toUpperCase() + type.slice(1), // Capitalize title
                        "message": res_string,
                    "duration": 10000
                });
                    toastEvent.fire();
                    
                    // Refresh the view to reflect changes
                    $A.get('e.force:refreshView').fire();
                } else if (state === 'ERROR') {
                    console.log('here Error');
                    // Handle error case
                    var errors = response.getError();
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        console.log('Error message: ' + errors[0].message);
                    } else {
                        console.log('Unknown error');
                    }
                }
                component.set("v.visible",false);
            });
            
            // Enqueue the action to call the Apex method
            $A.enqueueAction(action);
        }else{
            var toastEvent = $A.get("e.force:showToast");
            var type = 'error';
            toastEvent.setParams({
                "type": type,
                "title": type.charAt(0).toUpperCase() + type.slice(1), // Capitalize title
                "message": 'Please select a milestone',
                "duration": 10000
            });
            toastEvent.fire();
        }
    },
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        getFiles.push(...files);
        component.set('v.filesIDS',getFiles);
        
        var afercomit = component.get('v.filesIDS');
    },

})