({

    doInit: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.getRecordData");
        action.setParams({
            "recordId": recordId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var record = result.booking;
                console.log(JSON.stringify(record));
                console.log('Project__c'+record.Project__c);
                component.set("v.record", record);
                component.set("v.loggedInUserName", result.loggedInUser.Name);
                component.set("v.loggedInUserPhone", result.loggedInUser.Phone);
                component.set("v.loggedInUserEmail", result.loggedInUser.Email);
                //component.set("v.bookingFormPdfUrl", result.bookingFormPdfUrl);
                component.set("v.documentList", result.documents);
                
                var customerName = record.salutation_Applicant1__c+' '+record.First_Applicant_Name__c;
                
                var project = record.Project__c;
                
                /*
                var defaultEmailContent = "<div style='color: black;'><strong>Dear " + customerName;
                
                defaultEmailContent += ",</strong></div>";
                
                defaultEmailContent += "<div style='color: black;'> We are thrilled to extend a warm welcome to you as the newest member to the ever-growing<strong> Jain Housing </strong>Family. Your decision to book a<strong> Unit "+record.Unit_NumberFor__c+"</strong> "+ record.Tower_Name__c+"  at our iconic project <strong>“"+project+"” </strong>fills us with great joy, and we sincerely appreciate the trust and confidence you have placed in us. <br/><br/>" +
                    "At <strong>Jain Housing</strong>, in our decade plus journey, we are committed to delivering not just homes but a lifestyle that exceeds your expectations. Our iconic project is a testament to our dedication to creating spaces that offer comfort, luxury, and a sense of community.<br/><br/>" +
                    "As a part of this mail, please also find the following documents attached for your records and perusal.<br/><br/>" +
                    "<strong>Scanned copy of the Application for Allotment (Booking Form)</strong><br/><br/>" +
                    "If you have any questions, need assistance, or would like to discuss any aspect of your unit or the project, please do not hesitate to reach out to our dedicated customer support team.<br/><br/>" +
                    "<strong>Jain Housing's</strong> integrated team also assists its customers with home loans from any leading bank / financial institution as a one-stop solution. And as you embark on this exciting journey with us, rest assured that our team is here to support you every step of the way. We are dedicated to ensuring a seamless and enjoyable experience throughout the entire process, from booking to possession and beyond.<br/><br/>" +
                    "We work from <strong>Monday-Saturday from 10.00 AM to 6.00 PM</strong> and we are here to listen to your needs and provide solutions that meet your expectations. Once again, thank you for choosing<strong> "+project+" </strong>for your new home. We look forward to creating a harmonious and enriching living experience for you and your family.</div>"+
                    "<br/><br/><a href='https://www.youtube.com' target='_blank'>Click here to Watch YouTube</a><br/>"+
                    "<p><strong>Click above to watch our Welcome Video!</strong></p>";
                    */
                
                var defaultEmailContent = "<div style='color: black;'><strong>Dear " + customerName + ",</strong></div><br/>";

defaultEmailContent += "<div style='color: black;'>Greetings from <strong>Jain Housing</strong>!<br/><br/>" +
    "We are delighted to guide you through the exciting journey of owning your new home with us. It is both an honor and a privilege to welcome you to the Jain Housing family.<br/><br/>" +
    
    "Since our inception in 1987, Jain Housing has prioritized customer satisfaction, which has become our greatest strength. Over the years, we have had the privilege of housing over <strong>21,000+ families</strong> across South India, a testament to our unwavering commitment to our customers. We fully understand the joy and importance of owning a beautiful home, and at Jain Housing, we strive to make this process as seamless and effortless as possible. From the moment you book your apartment until the final handover, our team is dedicated to providing service of the highest quality, on par with global standards.<br/><br/>" +
    
    "This commitment to exceeding the expectations of our growing customer base has contributed to our success. To date, we have completed over <strong>200 prestigious projects</strong>, spanning over <strong>20 million square feet</strong> of excellence.<br/><br/>" +

    "<strong>Next Steps in Your Journey:</strong>" +
    "<ul style='color: black; padding-left: 20px;'>" +
        "<li><strong>Welcome Call:</strong> We will reconfirm all details mentioned in your booking application during a welcome call. If you require financial assistance through a home loan, our customer relationship management team will assist you with relevant banker contacts. Please note, while we will support you in the loan process, the responsibility for loan repayments and timely payments to us lies with you.</li>" +

        "<li><strong>Sale Agreement:</strong> Once the 10% booking advance is completed, we will initiate the Sale Agreement. Please confirm and sign the draft agreement within 3-4 business days.</li>" +

        "<li><strong>Project Updates:</strong> We will periodically update you about the project status via email. You may also contact your Customer Relationship Executive for updates.</li>" +

        "<li><strong>Registration:</strong> Once you have completed 100% of the payment for your flat, registration will be initiated. If the total cost exceeds INR 50 Lakhs, 1% TDS must be remitted and proof submitted before registration. Our team will assist with the process.</li>" +

        "<li><strong>Hand Over:</strong> Upon full payment and clearance of all dues, we will issue a No Due Certificate, Possession Letter, Car Parking Letter, and Keys.</li>" +
    "</ul><br/>" +

    "<strong>Key Contact Information:</strong>" +
    "<ul style='color: black; padding-left: 20px;'>" +
        "<li><strong>044-49494510</strong></li>" +
        "<li><strong>044-49494512</strong></li>" +
        "<li><strong>044-49494514</strong></li>" +
    "</ul>" +
    "<div style='color: black;'>(Available from 11 AM to 5 PM on all working days)</div><br/>" +

    "<strong>Our Core Values:</strong>" +
    "<ul style='color: black; padding-left: 20px;'>" +
        "<li><strong>Integrity:</strong> Commitment to honesty, transparency, and ethical business practices in all dealings.</li>" +
        "<li><strong>Innovation:</strong> Continuously seeking new and creative solutions for design, development, and technology.</li>" +
        "<li><strong>Excellence:</strong> Striving for the highest standards in every project, from design and construction to customer service.</li>" +
        "<li><strong>Accountability:</strong> Ensuring projects are completed on time and to the highest standards.</li>" +
        "<li><strong>Community Focus:</strong> Developing properties that improve communities and positively impact local economies.</li>" +
        "<li><strong>Transparency:</strong> Open and clear communication with all stakeholders, providing regular updates.</li>" +
    "</ul><br/>" +

    "<div style='color: black;'>Homeownership is a significant milestone, and we are honored to be part of this special journey with you. Thank you for choosing Jain Housing, and we look forward to delivering the home of your dreams.<br/><br/>" +
    "Best Regards,<br/>" +
    "CRM Team<br/>" +
    "<strong>Jain Housing</strong></div>";



                
                component.set("v.emailContent", defaultEmailContent);
            } else {
                console.error("Error retrieving record data");
            }
        });
        
        $A.enqueueAction(action);
    },
    
    previewDocument: function(component, event, helper) {
        const url = event.target.getAttribute('data-url');
        const name = event.target.getAttribute('data-name');
        component.set("v.activePdfUrl", url);
        component.set("v.activePdfName", name);
        component.set("v.showPdfModal", true);
    },
    
    closePdfModal: function(component, event, helper) {
        component.set("v.showPdfModal", false);
        component.set("v.activePdfUrl", null);
        component.set("v.activePdfName", null);
    },
    
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        getFiles.push(...files);
        component.set('v.filesIDS',getFiles);
        
        var afercomit = component.get('v.filesIDS');
    },
    sendEmail: function(component, event, helper) {
        component.set("v.isProcessing", true); // Start spinner & disable buttons
        
        var recList = component.get('v.recepients');
        var allFiles = component.get('v.files');
        var contentDocumentIds = component.get('v.filesIDS');
        var modifiedEmailContent = component.get("v.emailContent");
        var loggedInUserName = component.get("v.loggedInUserName");
        var loggedInUserPhone = component.get("v.loggedInUserPhone");
        var loggedInUserEmail = component.get("v.loggedInUserEmail");
		
        /*
        modifiedEmailContent += "<br/><div style='color: black;'>Regards,<br/><strong>" + loggedInUserName + "</strong><br/>";
        
        // Conditionally add the phone number if it exists, else add the email
        if(loggedInUserPhone) {
            modifiedEmailContent += 'Phone: ' + loggedInUserPhone;
        } else {
            modifiedEmailContent += 'Email: ' + loggedInUserEmail;
        }
        
        modifiedEmailContent += '</div>';
        */
        var record = component.get("v.record");

        var toAddresses = [];
        if(recList) {
            var recList = recList.split(',');
            recList.forEach(function(email) {
                toAddresses.push(email.trim());
            });
        }
        if (record.Email1__c) {
            toAddresses.push(record.Email1__c);
        }
        
        if (toAddresses.length === 0) {
            component.set("v.isProcessing", false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "No email address available to send the email.",
                "type": "error"
            });
            toastEvent.fire();
            return;
        }
        
        var action = component.get("c.sendWelcomeEmail");
        action.setParams({
            "recordId": component.get("v.record.Id"),
            "toAddresses": toAddresses,
            "emailContent": modifiedEmailContent,
            "contentIds": contentDocumentIds
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isProcessing", false); // Stop spinner & enable buttons
            var state = response.getState();
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Email Sent Successfully.",
                    "type": "success"
                });
                toastEvent.fire();
                
                $A.get('e.force:refreshView').fire();
                
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            } else {
                console.error("Error sending email");
            }
        });
        
        $A.enqueueAction(action);
        
    },
    Cancel: function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})