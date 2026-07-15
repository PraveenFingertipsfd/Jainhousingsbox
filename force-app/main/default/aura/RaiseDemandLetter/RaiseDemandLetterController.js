({
    doInit : function(component, event, helper) {
        let baseUrl = window.location.origin;
        var action = component.get("c.getBookingRecord");
        action.setParams({recordId :component.get("v.recordId") });     
        action.setCallback(this,function(a){    
            let state = a.getState();
            if (state === "SUCCESS") {
                component.set("v.bookingRecord",a.getReturnValue());
                
                let results = a.getReturnValue();
                let bookingval = results.booking;
                let milestone = results.currentMilestone;
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
                const projectName = bookingval.Project1__r && bookingval.Project1__r.Name ? bookingval.Project1__r.Name : 'your project';
                
                
                /*var olddefaultEmailContent = '<div style="color: black;"><strong>Dear ' + bookingval.First_Applicant_Name__c + ',</strong></div><br/>'+
                    '<div><strong>Greetings from Jain House !!!</strong><br/><br/>' +
                    'We are pleased to inform you that the <strong>'+milestone.Name+'</strong> for <strong>'+ projectName+'</strong> has been successfully completed as '+
                    'per scheduled. In accordance with the agreed-upon schedule. Kindly ensure that the payment is made'+
                    'within the stipulated timeframe of 7 days to avoid any delay in subsequent construction activities.<br/><br/>' +
                    'If you have any questions or need further assistance, please do not hesitate to contact us.<br/><br/>' +
                    'Thank you for choosing <strong>Jain House</strong>.<br/><br/>' +
                    'Best regards<br/>';*/
                
                var defaultEmailContent = '<div style="color: black;"><strong>Dear ' + applicantNames + ',</strong></div><br/>' +
                    '<strong>Greetings from Jain Housing!</strong> <br/>'+
                    'Please find attached the <strong>demand letter</strong> for the payment due, as per the payment schedule agreed upon during the booking of your flat. We kindly request you to make the payment as per the specified due date to ensure a smooth progression of work. <br/>'+
                    'All relevant details, including the payment amount and bank information, are provided in the attachment for your reference. <br/>'+
                    'We appreciate your continued cooperation and timely support. <br/>'+
                    'Should you have any questions or require assistance, please feel free to reach out to your assigned <strong>CRM Executive</strong>—we’re here to help. <br/>'+
                    'Thank you once again for choosing Jain Housing. <br/>'+
                    'Warm regards,<br/>'+
                    'CRM team<br/>'+
                    'Jain Housing ';
                
                url = baseUrl+'/apex/DemandRaiseEmailTemp?Id='+component.get("v.recordId");
                
                component.set("v.emailContent", defaultEmailContent);
                component.set("v.vfPageUrl", url);
            } else {
                console.error("Error fetching data: ", a.getError());
            }
        });
        $A.enqueueAction(action);
    },
    send: function(component, event, helper) {
        var recId = component.get("v.recordId");
        var contentDocumentIds = component.get('v.filesIDS'); // This is the list of file IDs
        var contentHTML = component.get('v.emailContent'); // This is the email content
        var recordIdsList = component.get("v.recordIdsList") || [];
        var emailContentMap = component.get("v.emailContentMap") || {};
        var contentDocumentIdsMap = component.get("v.contentDocumentIdsMap") || {};
        
        recordIdsList.push(recId);
        
        emailContentMap[recId] = contentHTML;
        contentDocumentIdsMap[recId] = contentDocumentIds;
        
        component.set("v.recordIdsList", recordIdsList);
        component.set("v.emailContentMap", emailContentMap);
        component.set("v.contentDocumentIdsMap", contentDocumentIdsMap);
        
        // Set the parameter for the Apex method - receiptId is passed from the component
        var action = component.get("c.RaiseDemand");
        action.setParams({
            "bookingIds": recordIdsList,
            "emailContents": emailContentMap,
            "contentIds": contentDocumentIdsMap
        });
        
        // Set the callback function to handle the response from Apex
        action.setCallback(this, function(response) {
            var state = response.getState(); 
            if (state === 'SUCCESS') {
                console.log('here sucess');
                var res_string = response.getReturnValue();
                
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                var type = res_string === 'Demand Raise records created and email sent Successfully.' ? 'success' : 'error';
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": type,
                    "title": type.charAt(0).toUpperCase() + type.slice(1), // Capitalize title
                    "message": res_string,
                    "duration": 10000
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
                
            } else if (state === 'ERROR') {
                console.log('here Error');
                var errors = response.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    console.log('Error message: ' + errors[0].message);
                }else {
                    console.log('Unknown error');
                }
            }
        });
        
        // Enqueue the action to call the Apex method
        $A.enqueueAction(action);
    },
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        getFiles.push(...files);
        component.set('v.filesIDS',getFiles);
        
        var afercomit = component.get('v.filesIDS');
    },
    close : function(component, event, helper) {
        event.stopPropagation();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
        component.set('v.visible',false);
    },
})